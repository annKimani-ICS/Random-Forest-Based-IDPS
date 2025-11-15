"""
Script to populate database with dummy alerts for analytics visualization
Uses the new specific DDoS attack types for better chart display
"""
from app.database import SessionLocal
from app.models import Model, Alert, Threshold, User, AlertStatus
from datetime import datetime, timedelta
import uuid
import random
from decimal import Decimal

def create_analytics_dummy_data():
    """Create dummy alerts optimized for analytics visualization"""
    db = SessionLocal()
    
    try:
        # Clear existing alerts
        db.query(Alert).delete()
        
        # Get current model version
        model = db.query(Model).order_by(Model.trained_at.desc()).first()
        model_version = model.version if model else "iteration4_voting_ensemble"
        
        # Specific DDoS attack types (matching the new attack identification system)
        attack_types = [
            "DDoS TCP SYN Flood",
            "DDoS TCP Flood",
            "DDoS TCP",
            "DDoS UDP Flood",
            "DDoS UDP Reflection",
            "DDoS UDP",
            "DDoS ICMP Flood",
            "DDoS ICMP",
            "DDoS Mixed Protocol",
            "DDoS"
        ]
        
        statuses = [AlertStatus.NEW, AlertStatus.ACK, AlertStatus.BLOCKED, AlertStatus.CLOSED]
        
        # Generate 50 dummy alerts over the last 7 days for better chart visualization
        alerts = []
        base_time = datetime.utcnow() - timedelta(days=7)
        
        # Create some recurring source IPs for top IPs chart
        common_ips = [
            "192.168.1.100", "192.168.1.101", "192.168.1.102",
            "10.0.0.50", "10.0.0.51", "10.0.0.52",
            "172.16.0.200", "172.16.0.201", "192.168.1.50",
            "10.0.0.100"
        ]
        
        # Attack type weights for better distribution
        attack_type_weights = [0.20, 0.15, 0.10, 0.15, 0.10, 0.10, 0.08, 0.05, 0.05, 0.02]
        
        # Status weights
        status_weights = [0.4, 0.3, 0.2, 0.1]  # NEW, ACK, BLOCKED, CLOSED
        
        for i in range(50):
            # Random time within last 7 days (distribute more evenly)
            random_hours = random.randint(0, 168)  # 7 days * 24 hours
            alert_time = base_time + timedelta(hours=random_hours)
            
            # Use common IPs 60% of the time for better top IPs visualization
            if random.random() < 0.6:
                src_ip = random.choice(common_ips)
            else:
                src_ip = f"192.168.{random.randint(1, 255)}.{random.randint(1, 255)}"
            dst_ip = f"10.0.{random.randint(1, 255)}.{random.randint(1, 255)}"
            
            # Weighted attack type selection for better distribution visualization
            attack_type = random.choices(attack_types, weights=attack_type_weights)[0]
            # Only create malicious alerts (score >= 0.5)
            score = round(random.uniform(0.5, 0.95), 4)
            
            # All alerts are malicious (system only processes malicious alerts)
            is_malicious = True
            
            # Random status (weighted)
            status = random.choices(statuses, weights=status_weights)[0]
            
            # Protocol based on attack type
            if "TCP" in attack_type:
                protocol = "TCP"
            elif "UDP" in attack_type:
                protocol = "UDP"
            elif "ICMP" in attack_type:
                protocol = "ICMP"
            else:
                protocol = random.choice(["TCP", "UDP", "ICMP"])
            
            alert = Alert(
                event_ts=alert_time,
                src_ip=src_ip,
                dst_ip=dst_ip,
                attack_type=attack_type,
                score=Decimal(str(score)),
                is_malicious=is_malicious,
                status=status,
                model_version=model_version,
                payload={
                    "packet_count": random.randint(100, 10000),
                    "bytes_transferred": random.randint(1024, 1048576),
                    "duration_seconds": random.randint(1, 3600),
                    "protocol": protocol,
                    "port": random.randint(1, 65535),
                    "packets_per_second": round(random.uniform(100, 2000), 2),
                    "bytes_per_second": round(random.uniform(1024, 1048576), 2)
                }
            )
            alerts.append(alert)
        
        # Add alerts to database
        db.add_all(alerts)
        db.commit()
        
        print(f"✅ Created {len(alerts)} dummy alerts for analytics")
        
        # Show summary
        malicious_count = sum(1 for alert in alerts if alert.is_malicious)
        print(f"   - Malicious alerts: {malicious_count}")
        print(f"   - Benign alerts: {len(alerts) - malicious_count}")
        print(f"   - Time range: Last 7 days")
        print(f"   - Model version: {model_version}")
        
        # Show attack type distribution
        print("\n📊 Attack Type Distribution:")
        attack_type_counts = {}
        for alert in alerts:
            attack_type_counts[alert.attack_type] = attack_type_counts.get(alert.attack_type, 0) + 1
        for attack_type, count in sorted(attack_type_counts.items(), key=lambda x: x[1], reverse=True):
            print(f"   - {attack_type}: {count}")
        
        # Show status distribution
        print("\n📊 Status Distribution:")
        status_counts = {}
        for alert in alerts:
            status_val = alert.status.value if hasattr(alert.status, 'value') else str(alert.status)
            status_counts[status_val] = status_counts.get(status_val, 0) + 1
        for status, count in sorted(status_counts.items(), key=lambda x: x[1], reverse=True):
            print(f"   - {status}: {count}")
        
        # Show top source IPs
        print("\n📊 Top Source IPs:")
        ip_counts = {}
        for alert in alerts:
            ip_counts[str(alert.src_ip)] = ip_counts.get(str(alert.src_ip), 0) + 1
        for ip, count in sorted(ip_counts.items(), key=lambda x: x[1], reverse=True)[:5]:
            print(f"   - {ip}: {count} alerts")
        
    except Exception as e:
        print(f"❌ Error creating alerts: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("🚀 Creating Analytics Dummy Data...\n")
    create_analytics_dummy_data()
    print("\n🎉 Analytics dummy data created successfully!")
    print("🔄 Refresh the dashboard to see the analytics charts!")

