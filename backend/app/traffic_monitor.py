"""
Live Network Traffic Monitor for IDS/IDPS
Captures network packets, extracts features, and runs them through the ML model
"""
import os
import sys
import json
import pickle
import joblib
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Optional
from collections import defaultdict
import threading
import time

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import Alert, Model

# Try to import scapy for packet capture
try:
    from scapy.all import sniff, IP, TCP, UDP, ICMP, ARP, Raw, get_if_list, get_if_addr
    SCAPY_AVAILABLE = True
except ImportError:
    SCAPY_AVAILABLE = False
    print("⚠️  Warning: scapy not installed. Install with: pip install scapy")

# Path to models directory (from backend/)
MODELS_DIR = Path(__file__).parent.parent.parent / "models"
FEATURE_SELECTION_FILE = MODELS_DIR / "feature_selection_iteration4.json"
MODEL_FILE = MODELS_DIR / "best_rf_iteration4_voting_ensemble.pkl"
SCALER_FILE = MODELS_DIR / "scaler_iteration4.pkl"
IMPUTER_FILE = MODELS_DIR / "imputer_iteration4.pkl"
LABEL_ENCODER_FILE = MODELS_DIR / "label_encoder_iteration3.pkl"

class TrafficMonitor:
    """Monitors network traffic and detects DDoS attacks"""
    
    def __init__(self, interface: Optional[str] = None, threshold: float = 0.50):
        """
        Initialize traffic monitor
        
        Args:
            interface: Network interface to monitor (None = auto-detect)
            threshold: Detection threshold (0.0-1.0)
        """
        self.threshold = threshold
        self.interface = interface or self._detect_interface()
        self.model = None
        self.scaler = None
        self.imputer = None
        self.label_encoder = None
        self.selected_features = None
        self.model_version = "iteration4_voting_ensemble"
        
        # Packet statistics (rolling window for feature extraction)
        self.packet_stats = defaultdict(lambda: {
            'packets': 0,
            'bytes': 0,
            'packets_in': 0,
            'packets_out': 0,
            'bytes_in': 0,
            'bytes_out': 0,
            'tcp_count': 0,
            'udp_count': 0,
            'icmp_count': 0,
            'start_time': None,
            'end_time': None,
            'src_ports': set(),
            'dst_ports': set(),
            'last_packet_time': None
        })
        
        # Window for aggregating packets (seconds)
        self.window_size = 5.0
        
        # Monitoring state
        self.is_monitoring = False
        self.monitor_thread = None
        
        # Load ML model and preprocessing
        self._load_model()
        
    def _detect_interface(self) -> str:
        """Auto-detect network interface"""
        if not SCAPY_AVAILABLE:
            return "eth0"  # Default
        
        interfaces = get_if_list()
        # Prefer eth0, enp0s3, or first available
        for iface in ["eth0", "enp0s3", "ens33", "wlan0"]:
            if iface in interfaces:
                return iface
        return interfaces[0] if interfaces else "eth0"
    
    def _load_model(self):
        """Load trained ML model and preprocessing objects"""
        try:
            # Load feature selection
            if FEATURE_SELECTION_FILE.exists():
                with open(FEATURE_SELECTION_FILE, 'r') as f:
                    feature_data = json.load(f)
                    self.selected_features = feature_data.get('selected_features', [])
                    print(f"✅ Loaded {len(self.selected_features)} selected features")
            
            # Load scaler
            if SCALER_FILE.exists():
                with open(SCALER_FILE, 'rb') as f:
                    self.scaler = pickle.load(f)
                    print("✅ Loaded scaler")
            
            # Load imputer
            if IMPUTER_FILE.exists():
                with open(IMPUTER_FILE, 'rb') as f:
                    self.imputer = pickle.load(f)
                    print("✅ Loaded imputer")
            
            # Load model (try joblib first, fallback to pickle)
            if MODEL_FILE.exists():
                try:
                    # Try joblib first (better compatibility)
                    self.model = joblib.load(MODEL_FILE)
                    print("✅ Loaded ML model using joblib")
                except Exception as joblib_error:
                    print(f"⚠️  Joblib load failed: {joblib_error}, trying pickle...")
                    try:
                        with open(MODEL_FILE, 'rb') as f:
                            self.model = pickle.load(f)
                        print("✅ Loaded ML model using pickle")
                    except Exception as pickle_error:
                        print(f"❌ Both joblib and pickle failed: {pickle_error}")
                        self.model = None
            else:
                print(f"⚠️  Model file not found: {MODEL_FILE}")
                print("   Using dummy predictions until model is available")
        
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            self.model = None
    
    def _extract_packet_features(self, packet_stats: Dict, window_seconds: float) -> pd.DataFrame:
        """
        Extract features from packet statistics matching CIC-DDoS2019 format
        
        This is a simplified feature extraction. In production, you'd want
        to match the exact CIC-DDoS2019 feature set more closely.
        """
        if window_seconds == 0:
            window_seconds = 1.0
        
        # Basic statistical features
        features = {
            'packet_count': packet_stats['packets'],
            'byte_count': packet_stats['bytes'],
            'packets_per_second': packet_stats['packets'] / window_seconds,
            'bytes_per_second': packet_stats['bytes'] / window_seconds,
            
            # Directional features
            'packets_in': packet_stats['packets_in'],
            'packets_out': packet_stats['packets_out'],
            'bytes_in': packet_stats['bytes_in'],
            'bytes_out': packet_stats['bytes_out'],
            
            # Protocol features
            'tcp_count': packet_stats['tcp_count'],
            'udp_count': packet_stats['udp_count'],
            'icmp_count': packet_stats['icmp_count'],
            'tcp_ratio': packet_stats['tcp_count'] / max(packet_stats['packets'], 1),
            'udp_ratio': packet_stats['udp_count'] / max(packet_stats['packets'], 1),
            
            # Port diversity
            'unique_src_ports': len(packet_stats['src_ports']),
            'unique_dst_ports': len(packet_stats['dst_ports']),
            'port_diversity': len(packet_stats['src_ports'] | packet_stats['dst_ports']),
        }
        
        # Create DataFrame with features
        # Add more features to match model expectations (simplified version)
        feature_vector = pd.DataFrame([features])
        
        # If we have selected features, use them; otherwise use all
        if self.selected_features and len(self.selected_features) > 0:
            # Fill missing features with 0
            for feat in self.selected_features:
                if feat not in feature_vector.columns:
                    feature_vector[feat] = 0.0
            feature_vector = feature_vector[self.selected_features]
        else:
            # Use default feature set (simplified)
            pass
        
        return feature_vector.values.reshape(1, -1) if len(feature_vector.values.shape) == 1 else feature_vector.values
    
    def _process_packet(self, packet):
        """Process a single packet"""
        try:
            if not IP in packet:
                return
            
            src_ip = packet[IP].src
            dst_ip = packet[IP].dst
            
            # Initialize stats for this flow if needed
            flow_key = f"{src_ip}_{dst_ip}"
            stats = self.packet_stats[flow_key]
            
            if stats['start_time'] is None:
                stats['start_time'] = datetime.now()
            stats['end_time'] = datetime.now()
            stats['last_packet_time'] = datetime.now()
            
            # Update statistics
            packet_len = len(packet)
            stats['packets'] += 1
            stats['bytes'] += packet_len
            
            # Direction (simplified - assumes monitoring interface perspective)
            # In production, you'd determine this more accurately
            if stats['packets'] % 2 == 0:  # Simplified
                stats['packets_out'] += 1
                stats['bytes_out'] += packet_len
            else:
                stats['packets_in'] += 1
                stats['bytes_in'] += packet_len
            
            # Protocol counts
            if TCP in packet:
                stats['tcp_count'] += 1
                if TCP in packet and hasattr(packet[TCP], 'sport'):
                    stats['src_ports'].add(packet[TCP].sport)
                if TCP in packet and hasattr(packet[TCP], 'dport'):
                    stats['dst_ports'].add(packet[TCP].dport)
            elif UDP in packet:
                stats['udp_count'] += 1
                if UDP in packet and hasattr(packet[UDP], 'sport'):
                    stats['src_ports'].add(packet[UDP].sport)
                if UDP in packet and hasattr(packet[UDP], 'dport'):
                    stats['dst_ports'].add(packet[UDP].dport)
            elif ICMP in packet:
                stats['icmp_count'] += 1
            
            # Check if window is complete (every 5 seconds)
            current_time = datetime.now()
            if stats['start_time']:
                elapsed = (current_time - stats['start_time']).total_seconds()
                
                if elapsed >= self.window_size:
                    # Extract features and predict
                    self._analyze_flow(flow_key, src_ip, dst_ip, stats, elapsed)
                    
                    # Reset stats for next window
                    stats = {
                        'packets': 0,
                        'bytes': 0,
                        'packets_in': 0,
                        'packets_out': 0,
                        'bytes_in': 0,
                        'bytes_out': 0,
                        'tcp_count': 0,
                        'udp_count': 0,
                        'icmp_count': 0,
                        'start_time': current_time,
                        'end_time': None,
                        'src_ports': set(),
                        'dst_ports': set(),
                        'last_packet_time': current_time
                    }
                    self.packet_stats[flow_key] = stats
        
        except Exception as e:
            # Silently ignore packet processing errors to avoid spam
            pass
    
    def _analyze_flow(self, flow_key: str, src_ip: str, dst_ip: str, stats: Dict, window_seconds: float):
        """Analyze a flow and create alert if malicious"""
        try:
            # Extract features
            feature_vector = self._extract_packet_features(stats, window_seconds)
            
            # Preprocess
            if self.imputer:
                feature_vector = self.imputer.transform(feature_vector)
            if self.scaler:
                feature_vector = self.scaler.transform(feature_vector)
            
            # Predict
            if self.model:
                # Get prediction probabilities
                if hasattr(self.model, 'predict_proba'):
                    probabilities = self.model.predict_proba(feature_vector)[0]
                    # Assuming binary classification: [benign_prob, malicious_prob]
                    # Adjust based on your model's output
                    if len(probabilities) == 2:
                        score = probabilities[1]  # Malicious probability
                    else:
                        score = probabilities.max()
                else:
                    # Fallback for models without predict_proba
                    prediction = self.model.predict(feature_vector)[0]
                    score = 0.8 if prediction == 1 else 0.2
            else:
                # Dummy detection: high packet rate suggests DDoS
                packets_per_sec = stats['packets'] / window_seconds if window_seconds > 0 else 0
                score = min(0.95, 0.3 + (packets_per_sec / 1000.0))  # Heuristic
            
            # Check threshold
            is_malicious = score >= self.threshold
            
            if is_malicious:
                # Create alert in database
                self._create_alert(src_ip, dst_ip, score, stats)
        
        except Exception as e:
            print(f"⚠️  Error analyzing flow: {e}")
    
    def _create_alert(self, src_ip: str, dst_ip: str, score: float, stats: Dict):
        """Create alert in database"""
        db: Session = SessionLocal()
        try:
            # Check for recent duplicate alert (within last minute)
            recent = db.query(Alert).filter(
                Alert.src_ip == src_ip,
                Alert.dst_ip == dst_ip,
                Alert.event_ts >= datetime.utcnow() - timedelta(minutes=1)
            ).first()
            
            if recent:
                # Update existing alert score if higher
                if score > float(recent.score):
                    recent.score = score
                    recent.is_malicious = score >= self.threshold
                    recent.event_ts = datetime.utcnow()
                    db.commit()
                return
            
            # Create new alert
            alert = Alert(
                event_ts=datetime.utcnow(),
                src_ip=src_ip,
                dst_ip=dst_ip,
                attack_type="DDoS",  # Default for this system
                score=min(1.0, max(0.0, score)),
                is_malicious=True,
                status="NEW",
                model_version=self.model_version,
                payload={
                    'packets': stats['packets'],
                    'bytes': stats['bytes'],
                    'packets_per_second': stats['packets'] / self.window_size if self.window_size > 0 else 0,
                    'protocols': {
                        'tcp': stats['tcp_count'],
                        'udp': stats['udp_count'],
                        'icmp': stats['icmp_count']
                    }
                }
            )
            
            db.add(alert)
            db.commit()
            print(f"🚨 Alert created: {src_ip} → {dst_ip} (score: {score:.3f})")
        
        except Exception as e:
            print(f"❌ Error creating alert: {e}")
            db.rollback()
        finally:
            db.close()
    
    def start_monitoring(self):
        """Start monitoring network traffic"""
        if not SCAPY_AVAILABLE:
            print("❌ Cannot start monitoring: scapy not installed")
            print("   Install with: pip install scapy")
            return False
        
        if self.is_monitoring:
            print("⚠️  Already monitoring")
            return False
        
        print(f"🔍 Starting traffic monitoring on interface: {self.interface}")
        print(f"   Threshold: {self.threshold}")
        print(f"   Window size: {self.window_size} seconds")
        print("   Press Ctrl+C to stop\n")
        
        print(f"[BACKEND] Setting is_monitoring = True")
        self.is_monitoring = True
        print(f"[BACKEND] is_monitoring is now: {self.is_monitoring}")
        
        try:
            # Start sniffing (blocking call)
            print(f"[BACKEND] Calling sniff() on interface {self.interface}...")
            sniff(
                iface=self.interface,
                prn=self._process_packet,
                store=False,
                stop_filter=lambda x: not self.is_monitoring
            )
            print(f"[BACKEND] sniff() completed")
        except KeyboardInterrupt:
            print("\n[BACKEND] 🛑 Stopping monitoring (KeyboardInterrupt)...")
            self.stop_monitoring()
        except PermissionError as e:
            print(f"[BACKEND] ❌ Permission denied - need root/sudo to capture packets: {e}")
            self.is_monitoring = False
            return False
        except OSError as e:
            print(f"[BACKEND] ❌ OSError (interface may not exist or be accessible): {e}")
            self.is_monitoring = False
            return False
        except Exception as e:
            print(f"[BACKEND] ❌ Error during monitoring: {e}")
            import traceback
            traceback.print_exc()
            self.is_monitoring = False
            return False
        
        return True
    
    def start_monitoring_async(self):
        """Start monitoring in a background thread"""
        if self.is_monitoring:
            print("[BACKEND] Already monitoring, cannot start again")
            return False
        
        def monitor_loop():
            """Background thread for monitoring"""
            try:
                print(f"[BACKEND] Starting monitoring thread for interface: {self.interface}")
                result = self.start_monitoring()
                if not result:
                    print(f"[BACKEND] Monitoring failed to start")
                else:
                    print(f"[BACKEND] Monitoring thread completed")
            except Exception as e:
                print(f"[BACKEND] ERROR in monitoring thread: {e}")
                import traceback
                traceback.print_exc()
                self.is_monitoring = False
        
        print(f"[BACKEND] Creating monitoring thread...")
        self.monitor_thread = threading.Thread(target=monitor_loop, daemon=True)
        self.monitor_thread.start()
        print(f"[BACKEND] Monitoring thread started, thread ID: {self.monitor_thread.ident}")
        
        # Give thread a moment to set is_monitoring = True
        import time
        time.sleep(0.2)  # 200ms should be enough for thread to start and set flag
        
        print(f"[BACKEND] After thread start, is_monitoring = {self.is_monitoring}")
        return True
    
    def stop_monitoring(self):
        """Stop monitoring"""
        self.is_monitoring = False
        print("✅ Monitoring stopped")

def main():
    """Main entry point for traffic monitor"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Live Network Traffic Monitor for IDS/IDPS")
    parser.add_argument("--interface", "-i", help="Network interface (default: auto-detect)")
    parser.add_argument("--threshold", "-t", type=float, default=0.50, help="Detection threshold (0.0-1.0)")
    parser.add_argument("--window", "-w", type=float, default=5.0, help="Analysis window size in seconds")
    
    args = parser.parse_args()
    
    monitor = TrafficMonitor(interface=args.interface, threshold=args.threshold)
    monitor.window_size = args.window
    
    try:
        monitor.start_monitoring()
    except KeyboardInterrupt:
        print("\n👋 Exiting...")
        monitor.stop_monitoring()

if __name__ == "__main__":
    main()

