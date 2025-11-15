"""
Simple script to clear all alerts from the database
Run this to start fresh - only malicious alerts will be created when you simulate attacks
"""
from app.database import SessionLocal
from app.models import Alert

def clear_all_alerts():
    """Clear all alerts from database"""
    db = SessionLocal()
    
    try:
        # Count alerts before deletion
        alert_count = db.query(Alert).count()
        
        if alert_count == 0:
            print("✅ Database is already empty - no alerts to clear")
            return
        
        print(f"🔍 Found {alert_count} alerts in database")
        print("🧹 Clearing all alerts...")
        
        # Delete all alerts
        db.query(Alert).delete()
        db.commit()
        
        print(f"✅ Successfully cleared {alert_count} alerts from database")
        print("   System is now ready for real attack simulation")
        print("   Only malicious alerts will be displayed in the GUI")
        
    except Exception as e:
        print(f"❌ Error clearing alerts: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("🚀 Clearing All Alerts from Database...\n")
    clear_all_alerts()
    print("\n🎉 Done! Database is clean and ready for attack simulation.")

