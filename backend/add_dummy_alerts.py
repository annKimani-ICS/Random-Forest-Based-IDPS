"""
Script to add dummy alerts to the database for testing
This will populate the alerts section in the GUI
"""
from app.database import SessionLocal
from app.models import Alert, AlertStatus
from datetime import datetime, timedelta
import random
import ipaddress

def generate_dummy_alerts():
    """Generate realistic dummy alerts for testing"""
    db = SessionLocal()
    
    try:
        # Clear existing alerts first
        db.query(Alert).delete()
        print("✅ Cleared existing alerts")
        
        # Also populate correct model metrics
        from app.models import Model
        from datetime import datetime
        import uuid
        
        print("🔄 Updating model metrics...")
        db.query(Model).delete()
        
        correct_metrics = {
            "iteration": 4,
            "model_name": "Random Forest Voting Ensemble",
            "accuracy": 0.9048,
            "precision": 0.9062,
            "recall": 0.9048,
            "f1": 0.9051,
            "auc": 0.95,
            "holdout_accuracy": 0.8974,
            "holdout_precision": 0.8984,
            "holdout_recall": 0.8974,
            "holdout_f1": 0.8976,
            "performance_consistency": 0.0076,
            "training_time_minutes": 15,
            "n_estimators": 200,
            "max_depth": 20,
            "features_used": 30,
            "data_samples": 50000,
            "description": "Random Forest Voting Ensemble - 90.48% Accuracy, 90.51% F1-Score",
            "model_type": "Voting Ensemble",
            "algorithm": "Random Forest + Voting"
        }
        
        new_model = Model(
            id=uuid.uuid4(),
            version="iteration4_voting_ensemble",
            trained_at=datetime(2024, 12, 15, 14, 30, 0),
            metrics=correct_metrics,
            notes="Primary production model - Random Forest Voting Ensemble with 90.48% accuracy and 90.51% F1-score"
        )
        db.add(new_model)
        print("✅ Added correct model metrics")
        
        # Sample attack types
        attack_types = [
            "DDoS", "Port Scan", "SQL Injection", "XSS", "Brute Force",
            "Malware", "Botnet", "Phishing", "Ransomware", "Data Exfiltration"
        ]
        
        # Sample IP addresses
        source_ips = [
            "192.168.1.100", "10.0.0.50", "172.16.0.25", "203.0.113.10",
            "198.51.100.5", "192.0.2.15", "203.0.113.45", "198.51.100.20"
        ]
        
        dest_ips = [
            "192.168.1.1", "10.0.0.1", "172.16.0.1", "203.0.113.1",
            "198.51.100.1", "192.0.2.1", "10.10.10.1", "172.20.0.1"
        ]
        
        # Generate alerts for the last 7 days
        alerts = []
        base_time = datetime.utcnow()
        
        for i in range(50):  # Generate 50 dummy alerts
            # Random time in last 7 days
            hours_ago = random.randint(0, 168)  # 0 to 168 hours (7 days)
            event_time = base_time - timedelta(hours=hours_ago)
            
            # Random attack type
            attack_type = random.choice(attack_types)
            
            # Random source and destination IPs
            src_ip = random.choice(source_ips)
            dst_ip = random.choice(dest_ips)
            
            # Random score (0.0 to 1.0)
            score = round(random.uniform(0.1, 0.99), 4)
            
            # Determine if malicious based on score
            is_malicious = score >= 0.5
            
            # Random status
            status = random.choice(list(AlertStatus))
            
            # Create alert
            alert = Alert(
                event_ts=event_time,
                src_ip=ipaddress.ip_address(src_ip),
                dst_ip=ipaddress.ip_address(dst_ip),
                attack_type=attack_type,
                score=score,
                is_malicious=is_malicious,
                status=status,
                model_version="iteration4_voting_ensemble",
                payload={
                    "protocol": random.choice(["TCP", "UDP", "ICMP"]),
                    "port": random.randint(1, 65535),
                    "packet_count": random.randint(1, 1000),
                    "bytes_transferred": random.randint(100, 1000000)
                }
            )
            alerts.append(alert)
        
        # Add alerts to database
        db.add_all(alerts)
        db.commit()
        
        print(f"✅ Added {len(alerts)} dummy alerts to database")
        print("\n📊 Alert Summary:")
        
        # Count by attack type
        attack_counts = {}
        for alert in alerts:
            attack_counts[alert.attack_type] = attack_counts.get(alert.attack_type, 0) + 1
        
        for attack_type, count in sorted(attack_counts.items()):
            print(f"   {attack_type}: {count} alerts")
        
        # Count by status
        status_counts = {}
        for alert in alerts:
            status_counts[alert.status.value] = status_counts.get(alert.status.value, 0) + 1
        
        print(f"\n📈 Status Distribution:")
        for status, count in sorted(status_counts.items()):
            print(f"   {status}: {count} alerts")
        
        # Count malicious vs benign
        malicious_count = sum(1 for alert in alerts if alert.is_malicious)
        benign_count = len(alerts) - malicious_count
        print(f"\n🎯 Classification:")
        print(f"   Malicious: {malicious_count} alerts")
        print(f"   Benign: {benign_count} alerts")
        
        print(f"\n🎉 Dummy alerts added successfully!")
        print("   Refresh the GUI to see the alerts in the dashboard")
        
    except Exception as e:
        print(f"❌ Error adding dummy alerts: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("🚀 Adding Dummy Alerts to Database...\n")
    generate_dummy_alerts()
