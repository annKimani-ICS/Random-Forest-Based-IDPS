#!/usr/bin/env python3
"""Create default Admin and Analyst users for testing."""
import sys
import os

sys.path.insert(0, os.getcwd())

from app.database import SessionLocal, engine, Base
from app.models import User, UserRole
from app.auth import hash_password
from sqlalchemy import text

def ensure_user(email, password, role):
    """Safely ensure user exists with proper error handling."""
    try:
        db = SessionLocal()
        
        # Check if user exists
        u = db.query(User).filter(User.email == email).first()
        
        if not u:
            # Create new user
            u = User(
                email=email,
                password_hash=hash_password(password),
                role=role,
                is_active=True
            )
            db.add(u)
            print(f"✅ Created {email} as {role.value}")
        else:
            # Update existing user
            u.password_hash = hash_password(password)
            u.role = role
            u.is_active = True
            print(f"✅ Updated {email} as {role.value}")
        
        db.commit()
        return True
    except Exception as e:
        print(f"❌ Error ensuring user {email}: {e}")
        if db:
            db.rollback()
        return False
    finally:
        if db:
            db.close()

def test_connection():
    """Test database connection."""
    try:
        db = SessionLocal()
        db.execute(text('SELECT 1'))
        db.close()
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def main():
    print("🔧 Creating default users...")
    print("============================\n")
    
    # Test database connection first
    if not test_connection():
        print("❌ Cannot connect to database. Please ensure PostgreSQL is running.")
        return 1
    
    # Ensure tables exist
    try:
        print("📊 Ensuring database tables exist...")
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables ready")
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return 1
    
    # Create users
    success = True
    success &= ensure_user("admin@ids-idps.com", "AdminSecure2024!", UserRole.ADMIN)
    success &= ensure_user("analyst@ids-idps.com", "AnalystSecure2024!", UserRole.ANALYST)
    
    if not success:
        print("\n❌ Failed to create users")
        return 1
    
    # Verify users
    try:
        db = SessionLocal()
        users = db.query(User).all()
        db.close()
        
        print("\n📋 Users in database:")
        for u in users:
            print(f"  - {u.email} ({u.role.value})")
    except Exception as e:
        print(f"❌ Error verifying users: {e}")
        return 1
    
    print("\n✅ All users created successfully!")
    return 0

if __name__ == "__main__":
    sys.exit(main())

