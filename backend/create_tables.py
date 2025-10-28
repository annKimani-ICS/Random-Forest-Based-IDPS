#!/usr/bin/env python3
"""
Simple script to create database tables without Alembic
This bypasses migration issues by creating tables directly
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import engine, Base
from app.models import *

def create_tables():
    """Create all database tables directly"""
    try:
        print("🔧 Creating database tables...")
        Base.metadata.create_all(bind=engine)
        print("✅ All tables created successfully!")
        
        # Verify tables were created
        from app.database import SessionLocal
        db = SessionLocal()
        try:
            user_count = db.query(User).count()
            model_count = db.query(Model).count()
            alert_count = db.query(Alert).count()
            
            print(f"\n📊 Database verification:")
            print(f"   - Users: {user_count}")
            print(f"   - Models: {model_count}")
            print(f"   - Alerts: {alert_count}")
            
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return False
    
    return True

if __name__ == "__main__":
    if create_tables():
        print("\n🎉 Database setup complete!")
        print("You can now run: python add_dummy_alerts.py")
    else:
        print("\n❌ Database setup failed!")
        sys.exit(1)
