"""
Simple script to clear all alerts from the database
Run this to start fresh - only malicious alerts will be created when you simulate attacks
"""
import sys
import os

# Add current directory to path (same as seed_data.py and other working scripts)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from app.database import SessionLocal
    from app.models import Alert
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("💡 This means the virtual environment is not activated or dependencies are missing")
    print("")
    print("   Try one of these:")
    print("   1. Activate venv: source .venv/bin/activate")
    print("   2. Or use venv python directly: .venv/bin/python3 clear_all_alerts.py")
    print("   3. Or find your venv: find ~ -name 'uvicorn' -type f 2>/dev/null")
    sys.exit(1)

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
