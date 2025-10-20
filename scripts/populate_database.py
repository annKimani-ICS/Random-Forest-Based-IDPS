"""
Script to populate database with dummy data and correct model metrics
Run this from the project root directory
"""
import sys
import os
from datetime import datetime, timedelta
import random
from decimal import Decimal

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

try:
    from app.database import SessionLocal
    from app.models import Model, Alert, Threshold, User
    import uuid
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("💡 Try running this from the backend directory instead:")
    print("   cd backend && python populate_dummy_data.py")
    sys.exit(1)

def create_dummy_alerts():
    """Create realistic dummy alerts for demonstration"""
    db = SessionLocal()
    
    try:
        # Clear existing alerts
        db.query(Alert).delete()
        
        # Get current model version
        model = db.query(Model).order_by(Model.trained_at.desc()).first()
        model_version = model.version if model else "iteration4_voting_ensemble"
        
        # Dummy alert data
        attack_types = [
            "DDoS", "Brute Force", "SQL Injection", "XSS", "Port Scan",
            "Malware", "Botnet", "Phishing", "Ransomware", "Data Exfiltration"
        ]
        
        statuses = ["NEW", "ACK", "BLOCKED", "CLOSED"]
        
        # Generate 25 dummy alerts over the last 7 days
        alerts = []
        base_time = datetime.utcnow() - timedelta(days=7)
        
        for i in range(25):
            # Random time within last 7 days
            random_hours = random.randint(0, 168)  # 7 days * 24 hours
            alert_time = base_time + timedelta(hours=random_hours)
            
            # Random IP addresses
            src_ip = f"192.168.{random.randint(1, 255)}.{random.randint(1, 255)}"
            dst_ip = f"10.0.{random.randint(1, 255)}.{random.randint(1, 255)}"
            
            # Random attack type and score
            attack_type = random.choice(attack_types)
            score = round(random.uniform(0.3, 0.95), 4)
            
            # Determine if malicious based on score
            is_malicious = score >= 0.5
            
            # Random status (weighted towards NEW and ACK)
            status_weights = [0.4, 0.3, 0.2, 0.1]  # NEW, ACK, BLOCKED, CLOSED
            status = random.choices(statuses, weights=status_weights)[0]
            
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
                    "protocol": random.choice(["TCP", "UDP", "ICMP"]),
                    "port": random.randint(1, 65535)
                }
            )
            alerts.append(alert)
        
        # Add alerts to database
        db.add_all(alerts)
        db.commit()
        
        print(f"✅ Created {len(alerts)} dummy alerts")
        
        # Show summary
        malicious_count = sum(1 for alert in alerts if alert.is_malicious)
        print(f"   - Malicious alerts: {malicious_count}")
        print(f"   - Benign alerts: {len(alerts) - malicious_count}")
        print(f"   - Time range: Last 7 days")
        print(f"   - Model version: {model_version}")
        
    except Exception as e:
        print(f"❌ Error creating alerts: {e}")
        db.rollback()
        raise
    finally:
        db.close()

def update_model_metrics():
    """Update model with correct Iteration 4 metrics"""
    db = SessionLocal()
    
    try:
        # Iteration 4 metrics - Random Forest as primary model
        iteration4_metrics = {
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
        
        # Check if iteration 4 model exists
        existing_model = db.query(Model).filter(
            Model.version == "iteration4_random_forest"
        ).first()
        
        if existing_model:
            print("✅ Updating existing Iteration 4 Random Forest model...")
            existing_model.metrics = iteration4_metrics
            existing_model.trained_at = datetime(2024, 10, 15, 12, 0, 0)
            existing_model.notes = "Primary production model - 90.44% accuracy, 90.47% F1-score (Lightweight)"
        else:
            print("✅ Creating new Iteration 4 Random Forest model entry...")
            new_model = Model(
                id=uuid.uuid4(),
                version="iteration4_random_forest",
                trained_at=datetime(2024, 10, 15, 12, 0, 0),
                metrics=iteration4_metrics,
                notes="Primary production model - 90.44% accuracy, 90.47% F1-score (Lightweight)"
            )
            db.add(new_model)
        
        db.commit()
        print("✅ Model metrics updated successfully!")
        print(f"   - Accuracy: {iteration4_metrics['accuracy']:.4f}")
        print(f"   - Precision: {iteration4_metrics['precision']:.4f}")
        print(f"   - Recall: {iteration4_metrics['recall']:.4f}")
        print(f"   - F1-Score: {iteration4_metrics['f1']:.4f}")
        print(f"   - AUC: {iteration4_metrics['auc']:.4f}")
        
    except Exception as e:
        print(f"❌ Error updating model: {e}")
        db.rollback()
        raise
    finally:
        db.close()

def ensure_threshold():
    """Ensure threshold exists"""
    db = SessionLocal()
    
    try:
        threshold = db.query(Threshold).order_by(Threshold.updated_at.desc()).first()
        
        if not threshold:
            # Get admin user
            admin_user = db.query(User).filter(User.role == "ADMIN").first()
            if not admin_user:
                print("⚠️  No admin user found, creating default threshold...")
                admin_user_id = uuid.uuid4()
            else:
                admin_user_id = admin_user.id
            
            new_threshold = Threshold(
                current_value=Decimal('0.50'),
                updated_by=admin_user_id,
                updated_at=datetime.utcnow()
            )
            db.add(new_threshold)
            db.commit()
            print("✅ Created default threshold (0.50)")
        else:
            print(f"✅ Threshold exists: {threshold.current_value}")
            
    except Exception as e:
        print(f"❌ Error with threshold: {e}")
        db.rollback()
        raise
    finally:
        db.close()

def main():
    """Main function to populate all dummy data"""
    print("🚀 Populating Database with Dummy Data...\n")
    
    # 1. Update model metrics
    print("1️⃣ Updating model metrics...")
    update_model_metrics()
    print()
    
    # 2. Ensure threshold exists
    print("2️⃣ Ensuring threshold exists...")
    ensure_threshold()
    print()
    
    # 3. Create dummy alerts
    print("3️⃣ Creating dummy alerts...")
    create_dummy_alerts()
    print()
    
    print("🎉 Database populated successfully!")
    print("\n📊 What you'll see in the GUI:")
    print("   - Model Performance: 90.48% accuracy, 90.51% F1-score")
    print("   - Alerts (24h): Recent alerts count")
    print("   - Recent Alerts table: 25 realistic dummy alerts")
    print("   - Threshold: 0.50")
    print("\n🔄 Restart the GUI to see the changes!")

if __name__ == "__main__":
    main()
