"""
Script to remove all benign alerts from the database
System only processes and displays malicious alerts
"""
from app.database import SessionLocal
from app.models import Alert

def remove_benign_alerts():
    """Remove all benign alerts from database"""
    db = SessionLocal()
    
    try:
        # Find all benign alerts
        benign_alerts = db.query(Alert).filter(Alert.is_malicious == False).all()
        benign_count = len(benign_alerts)
        
        if benign_count == 0:
            print("✅ No benign alerts found in database")
            return
        
        print(f"🔍 Found {benign_count} benign alerts to remove...")
        
        # Delete all benign alerts
        db.query(Alert).filter(Alert.is_malicious == False).delete()
        db.commit()
        
        print(f"✅ Successfully removed {benign_count} benign alerts from database")
        print("   System now only contains malicious alerts")
        
        # Verify
        remaining_benign = db.query(Alert).filter(Alert.is_malicious == False).count()
        malicious_count = db.query(Alert).filter(Alert.is_malicious == True).count()
        
        print(f"\n📊 Current Alert Status:")
        print(f"   - Malicious alerts: {malicious_count}")
        print(f"   - Benign alerts: {remaining_benign}")
        
        if remaining_benign > 0:
            print(f"⚠️  Warning: {remaining_benign} benign alerts still exist")
        else:
            print("✅ All benign alerts removed successfully!")
        
    except Exception as e:
        print(f"❌ Error removing benign alerts: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("🚀 Removing Benign Alerts from Database...\n")
    remove_benign_alerts()
    print("\n🎉 Done! System now only contains malicious alerts.")

