"""
Script to check what's currently in the database
"""
from app.database import SessionLocal
from app.models import Model, Alert
from datetime import datetime

def check_database():
    """Check current database contents"""
    db = SessionLocal()
    
    try:
        print("🔍 Checking Database Contents...\n")
        
        # Check models
        models = db.query(Model).order_by(Model.trained_at.desc()).all()
        print(f"📊 Models in database: {len(models)}")
        for i, model in enumerate(models, 1):
            print(f"\n{i}. Model Version: {model.version}")
            print(f"   Trained: {model.trained_at}")
            print(f"   Model Name: {model.metrics.get('model_name', 'N/A')}")
            print(f"   Accuracy: {model.metrics.get('accuracy', 'N/A')}")
            print(f"   Precision: {model.metrics.get('precision', 'N/A')}")
            print(f"   Recall: {model.metrics.get('recall', 'N/A')}")
            print(f"   F1-Score: {model.metrics.get('f1', 'N/A')}")
            print(f"   AUC: {model.metrics.get('auc', 'N/A')}")
            if model.notes:
                print(f"   Notes: {model.notes}")
        
        # Check alerts
        alert_count = db.query(Alert).count()
        print(f"\n🚨 Alerts in database: {alert_count}")
        
        if alert_count > 0:
            recent_alerts = db.query(Alert).order_by(Alert.event_ts.desc()).limit(5).all()
            print("\nRecent alerts:")
            for alert in recent_alerts:
                print(f"   - {alert.event_ts}: {alert.attack_type} (Score: {alert.score})")
        
        print(f"\n✅ Database check complete!")
        
    except Exception as e:
        print(f"❌ Error checking database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_database()
