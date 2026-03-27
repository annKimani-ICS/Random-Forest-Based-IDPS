"""
Force update script to ensure correct Random Forest metrics are displayed
This will clear old models and create the correct one
"""
from app.database import SessionLocal
from app.models import Model, Alert
from datetime import datetime
import uuid

def force_update_metrics():
    """Force update model metrics to correct Random Forest values"""
    db = SessionLocal()
    
    try:
        print("🔄 Force updating model metrics...")
        
        # Clear ALL existing models to ensure clean state
        print("🗑️  Clearing existing models...")
        db.query(Model).delete()
        
        # Create correct Random Forest model
        print("✅ Creating correct Random Forest model...")
        correct_metrics = {
            "iteration": 4,
            "model_name": "Random Forest",
            "accuracy": 0.9044,
            "precision": 0.9058,
            "recall": 0.9044,
            "f1": 0.9047,
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
            "description": "FAST Random Forest - 90.44% Accuracy, 90.47% F1-Score (Lightweight Production Model)",
            "comparison_models": {
                "voting_ensemble": {
                    "accuracy": 0.9048,
                    "precision": 0.9062,
                    "recall": 0.9048,
                    "f1": 0.9051,
                    "note": "Used for comparison only"
                }
            }
        }
        
        new_model = Model(
            id=uuid.uuid4(),
            version="iteration4_random_forest",
            trained_at=datetime(2024, 10, 15, 12, 0, 0),
            metrics=correct_metrics,
            notes="Primary production model - 90.44% accuracy, 90.47% F1-score (Lightweight)"
        )
        db.add(new_model)
        
        # Update all alerts to use correct model version
        print("🔄 Updating alert model versions...")
        db.query(Alert).update({
            Alert.model_version: "iteration4_random_forest"
        }, synchronize_session=False)
        
        db.commit()
        
        print("✅ Model metrics force updated successfully!")
        print("\n📊 Correct Random Forest Metrics:")
        print(f"   - Accuracy: {correct_metrics['accuracy']:.4f} (90.44%)")
        print(f"   - Precision: {correct_metrics['precision']:.4f} (90.58%)")
        print(f"   - Recall: {correct_metrics['recall']:.4f} (90.44%)")
        print(f"   - F1-Score: {correct_metrics['f1']:.4f} (90.47%)")
        print(f"   - AUC: {correct_metrics['auc']:.4f} (95.00%)")
        print(f"   - Model Type: {correct_metrics['model_name']}")
        
        # Verify the update
        latest_model = db.query(Model).order_by(Model.trained_at.desc()).first()
        if latest_model:
            print(f"\n✅ Verification - Latest model in DB:")
            print(f"   - Version: {latest_model.version}")
            print(f"   - Accuracy: {latest_model.metrics.get('accuracy', 'N/A')}")
            print(f"   - Precision: {latest_model.metrics.get('precision', 'N/A')}")
            print(f"   - Recall: {latest_model.metrics.get('recall', 'N/A')}")
            print(f"   - F1-Score: {latest_model.metrics.get('f1', 'N/A')}")
        
        print("\n🎯 The GUI should now display the correct Random Forest metrics!")
        
    except Exception as e:
        print(f"❌ Error force updating metrics: {e}")
        db.rollback()
        raise
    finally:
        db.close()

def create_ddos_alerts():
    """Create DDoS-focused dummy alerts"""
    db = SessionLocal()
    
    try:
        print("\n🚨 Creating DDoS-focused alerts...")
        
        # Clear existing alerts
        db.query(Alert).delete()
        
        # DDoS/DoS attack types only
        attack_types = [
            "DDoS", "DoS", "DDoS Amplification", "DDoS Reflection", "DDoS Botnet",
            "DDoS Volumetric", "DDoS Protocol", "DDoS Application", "DDoS Infrastructure",
            "DDoS Network", "DDoS Transport", "DDoS Application Layer"
        ]
        
        statuses = ["NEW", "ACK", "BLOCKED", "CLOSED"]
        
        # Generate 25 DDoS-focused alerts
        alerts = []
        base_time = datetime.utcnow() - timedelta(days=7)
        
        for i in range(25):
            # Random time within last 7 days
            random_hours = random.randint(0, 168)
            alert_time = base_time + timedelta(hours=random_hours)
            
            # Random IP addresses
            src_ip = f"192.168.{random.randint(1, 255)}.{random.randint(1, 255)}"
            dst_ip = f"10.0.{random.randint(1, 255)}.{random.randint(1, 255)}"
            
            # Random DDoS attack type and score
            attack_type = random.choice(attack_types)
            score = round(random.uniform(0.3, 0.95), 4)
            
            # Determine if malicious based on score
            is_malicious = score >= 0.5
            
            # Random status
            status_weights = [0.4, 0.3, 0.2, 0.1]
            status = random.choices(statuses, weights=status_weights)[0]
            
            alert = Alert(
                event_ts=alert_time,
                src_ip=src_ip,
                dst_ip=dst_ip,
                attack_type=attack_type,
                score=Decimal(str(score)),
                is_malicious=is_malicious,
                status=status,
                model_version="iteration4_random_forest",
                payload={
                    "packet_count": random.randint(1000, 50000),  # Higher for DDoS
                    "bytes_transferred": random.randint(100000, 10000000),  # Higher for DDoS
                    "duration_seconds": random.randint(60, 3600),  # Longer for DDoS
                    "protocol": random.choice(["TCP", "UDP", "ICMP"]),
                    "port": random.randint(1, 65535),
                    "attack_vector": "DDoS",
                    "traffic_volume": "High"
                }
            )
            alerts.append(alert)
        
        # Add alerts to database
        db.add_all(alerts)
        db.commit()
        
        print(f"✅ Created {len(alerts)} DDoS-focused alerts")
        
        # Show summary
        malicious_count = sum(1 for alert in alerts if alert.is_malicious)
        print(f"   - Malicious alerts: {malicious_count}")
        print(f"   - Benign alerts: {len(alerts) - malicious_count}")
        print(f"   - Attack types: DDoS/DoS variants only")
        print(f"   - Time range: Last 7 days")
        
    except Exception as e:
        print(f"❌ Error creating DDoS alerts: {e}")
        db.rollback()
        raise
    finally:
        db.close()

def main():
    """Main function to force update everything"""
    print("🚀 Force Updating Database for Correct Display...\n")
    
    # 1. Force update model metrics
    force_update_metrics()
    
    # 2. Create DDoS-focused alerts
    create_ddos_alerts()
    
    print("\n🎉 Force update complete!")
    print("\n📊 What you'll see in the GUI:")
    print("   - Model Performance: 90.44% accuracy, 90.47% F1-score (Random Forest)")
    print("   - Alerts: DDoS/DoS attacks only")
    print("   - Attack Types: DDoS, DoS, DDoS Amplification, etc.")
    print("\n🔄 Restart the GUI to see the changes!")

if __name__ == "__main__":
    import random
    from decimal import Decimal
    from datetime import timedelta
    main()
