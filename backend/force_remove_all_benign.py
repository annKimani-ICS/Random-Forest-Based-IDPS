"""
Force remove ALL benign alerts from database
This script will delete any alert with is_malicious=False or score < 0.5
"""
from app.database import SessionLocal
from app.models import Alert
from decimal import Decimal

def force_remove_all_benign():
    """Remove all benign alerts - both by flag and by score"""
    db = SessionLocal()
    
    try:
        # Find all alerts that are marked as benign
        benign_by_flag = db.query(Alert).filter(Alert.is_malicious == False).all()
        benign_by_flag_count = len(benign_by_flag)
        
        # Find all alerts with score < 0.5 (should be benign)
        benign_by_score = db.query(Alert).filter(Alert.score < Decimal('0.5')).all()
        benign_by_score_count = len(benign_by_score)
        
        # Get unique IDs to delete
        benign_ids = set()
        for alert in benign_by_flag:
            benign_ids.add(alert.id)
        for alert in benign_by_score:
            benign_ids.add(alert.id)
        
        total_to_remove = len(benign_ids)
        
        if total_to_remove == 0:
            print("✅ No benign alerts found in database")
            return
        
        print(f"🔍 Found {total_to_remove} benign alerts to remove:")
        print(f"   - Marked as benign (is_malicious=False): {benign_by_flag_count}")
        print(f"   - Score < 0.5: {benign_by_score_count}")
        
        # Delete all benign alerts
        deleted = db.query(Alert).filter(Alert.id.in_(list(benign_ids))).delete(synchronize_session=False)
        db.commit()
        
        print(f"✅ Successfully removed {deleted} benign alerts from database")
        print("   System now only contains malicious alerts")
        
        # Verify
        remaining_benign = db.query(Alert).filter(Alert.is_malicious == False).count()
        low_score = db.query(Alert).filter(Alert.score < Decimal('0.5')).count()
        malicious_count = db.query(Alert).filter(Alert.is_malicious == True).count()
        
        print(f"\n📊 Current Alert Status:")
        print(f"   - Malicious alerts: {malicious_count}")
        print(f"   - Benign alerts (by flag): {remaining_benign}")
        print(f"   - Low score alerts (< 0.5): {low_score}")
        
        if remaining_benign > 0 or low_score > 0:
            print(f"⚠️  Warning: Some benign alerts may still exist")
            print(f"   Run this script again to remove them")
        else:
            print("✅ All benign alerts removed successfully!")
        
    except Exception as e:
        print(f"❌ Error removing benign alerts: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("🚀 Force Removing ALL Benign Alerts from Database...\n")
    force_remove_all_benign()
    print("\n🎉 Done! System now only contains malicious alerts.")

