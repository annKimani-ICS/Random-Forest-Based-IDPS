"""
Debug script for traffic monitoring issues
Checks all aspects of the monitoring system
"""
import sys
from pathlib import Path
import traceback
from datetime import datetime

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent))

from app.database import SessionLocal
from app.models import Alert, Model
from app.traffic_monitor import TrafficMonitor, SCAPY_AVAILABLE

def check_scapy():
    """Check if scapy is installed and available"""
    print("=" * 60)
    print("1. Checking Scapy Installation")
    print("=" * 60)
    if SCAPY_AVAILABLE:
        print("✅ Scapy is installed")
        try:
            from scapy.all import get_if_list, get_if_addr
            interfaces = get_if_list()
            print(f"   Available interfaces: {interfaces}")
            for iface in interfaces:
                try:
                    addr = get_if_addr(iface)
                    print(f"   - {iface}: {addr}")
                except:
                    print(f"   - {iface}: (no address)")
        except Exception as e:
            print(f"⚠️  Error getting interfaces: {e}")
    else:
        print("❌ Scapy is NOT installed")
        print("   Install with: pip install scapy")
    print()

def check_model_files():
    """Check if model files exist"""
    print("=" * 60)
    print("2. Checking Model Files")
    print("=" * 60)
    models_dir = Path(__file__).parent.parent / "models"
    model_file = models_dir / "best_rf_iteration4_voting_ensemble.pkl"
    scaler_file = models_dir / "scaler_iteration4.pkl"
    imputer_file = models_dir / "imputer_iteration4.pkl"
    feature_file = models_dir / "feature_selection_iteration4.json"
    
    print(f"   Models directory: {models_dir}")
    print(f"   Models dir exists: {models_dir.exists()}")
    print(f"   Model file exists: {model_file.exists()}")
    print(f"   Scaler file exists: {scaler_file.exists()}")
    print(f"   Imputer file exists: {imputer_file.exists()}")
    print(f"   Feature selection exists: {feature_file.exists()}")
    print()

def check_database_alerts():
    """Check alerts in database"""
    print("=" * 60)
    print("3. Checking Database Alerts")
    print("=" * 60)
    db = SessionLocal()
    try:
        # Recent alerts (last hour)
        recent_alerts = db.query(Alert).filter(
            Alert.event_ts >= datetime.utcnow().replace(minute=0, second=0, microsecond=0)
        ).count()
        print(f"   Alerts in last hour: {recent_alerts}")
        
        # Recent alerts (last 10 minutes)
        from datetime import timedelta
        recent_10min = db.query(Alert).filter(
            Alert.event_ts >= datetime.utcnow() - timedelta(minutes=10)
        ).order_by(Alert.event_ts.desc()).limit(5).all()
        
        print(f"   Alerts in last 10 minutes: {len(recent_10min)}")
        for alert in recent_10min:
            print(f"   - ID {alert.id}: {alert.src_ip} → {alert.dst_ip} (score: {alert.score:.3f}, time: {alert.event_ts})")
        
        # Total alerts
        total = db.query(Alert).count()
        print(f"   Total alerts in database: {total}")
    except Exception as e:
        print(f"❌ Error checking database: {e}")
        traceback.print_exc()
    finally:
        db.close()
    print()

def test_monitor_init():
    """Test monitor initialization"""
    print("=" * 60)
    print("4. Testing Monitor Initialization")
    print("=" * 60)
    try:
        monitor = TrafficMonitor(interface=None, threshold=0.50)
        print(f"✅ Monitor initialized successfully")
        print(f"   Interface: {monitor.interface}")
        print(f"   Threshold: {monitor.threshold}")
        print(f"   Window size: {monitor.window_size}")
        print(f"   Model loaded: {monitor.model is not None}")
        print(f"   Scaler loaded: {monitor.scaler is not None}")
        print(f"   Imputer loaded: {monitor.imputer is not None}")
        print(f"   Selected features: {len(monitor.selected_features) if monitor.selected_features else 0}")
    except Exception as e:
        print(f"❌ Error initializing monitor: {e}")
        traceback.print_exc()
    print()

def test_monitor_status():
    """Test monitor status API"""
    print("=" * 60)
    print("5. Testing Monitor Status")
    print("=" * 60)
    try:
        import requests
        response = requests.get("http://localhost:8000/api/monitor/status", timeout=2)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Monitor status API works")
            print(f"   Status: {data}")
        else:
            print(f"⚠️  Monitor status API returned: {response.status_code}")
            print(f"   Response: {response.text}")
    except requests.exceptions.ConnectionError:
        print("❌ Backend is not running on localhost:8000")
        print("   Start backend with: python -m app.main")
    except Exception as e:
        print(f"⚠️  Error checking status: {e}")
    print()

def test_packet_capture():
    """Test if packet capture works (quick test)"""
    print("=" * 60)
    print("6. Testing Packet Capture (5 second test)")
    print("=" * 60)
    if not SCAPY_AVAILABLE:
        print("❌ Cannot test: scapy not installed")
        print()
        return
    
    try:
        from scapy.all import sniff, IP
        import signal
        
        packets_captured = [0]
        
        def packet_handler(packet):
            if IP in packet:
                packets_captured[0] += 1
                print(f"   📦 Captured packet: {packet[IP].src} → {packet[IP].dst}")
        
        print("   Starting 5-second packet capture test...")
        print("   (Send some traffic to see packets)")
        
        try:
            sniff(timeout=5, prn=packet_handler, store=False)
            print(f"✅ Captured {packets_captured[0]} IP packets in 5 seconds")
        except PermissionError:
            print("❌ Permission denied - need root/sudo to capture packets")
            print("   Run with: sudo python debug_traffic_monitoring.py")
        except Exception as e:
            print(f"❌ Error during capture: {e}")
            traceback.print_exc()
    except Exception as e:
        print(f"❌ Error testing capture: {e}")
        traceback.print_exc()
    print()

def main():
    """Run all diagnostic checks"""
    print("\n" + "=" * 60)
    print("TRAFFIC MONITORING DIAGNOSTIC TOOL")
    print("=" * 60 + "\n")
    
    check_scapy()
    check_model_files()
    check_database_alerts()
    test_monitor_init()
    test_monitor_status()
    
    # Only test capture if user wants
    import sys
    if "--test-capture" in sys.argv:
        test_packet_capture()
    else:
        print("=" * 60)
        print("6. Packet Capture Test (Skipped)")
        print("=" * 60)
        print("   Run with --test-capture to test packet capture")
        print("   Example: sudo python debug_traffic_monitoring.py --test-capture")
        print()
    
    print("=" * 60)
    print("DIAGNOSTIC COMPLETE")
    print("=" * 60)
    print("\nCommon Issues:")
    print("1. Backend not running → Start with: python -m app.main")
    print("2. Scapy not installed → Install with: pip install scapy")
    print("3. Permission denied → Run backend with sudo or set CAP_NET_RAW")
    print("4. Wrong interface → Check available interfaces and specify in GUI")
    print("5. No traffic → Generate traffic with hping3 or curl")
    print("6. Threshold too high → Lower threshold in GUI (0.3-0.5)")
    print("7. Window size too long → Default is 5 seconds, wait longer")
    print()

if __name__ == "__main__":
    main()


