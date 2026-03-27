#!/usr/bin/env python3
"""
Diagnostic script to troubleshoot authentication issues
Checks users, passwords, and helps fix login problems
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from app.database import SessionLocal
from app.models import User, UserRole
from app.auth import hash_password, verify_password
from sqlalchemy import text

def check_database_connection():
    """Step 1: Check database connection"""
    print("=" * 60)
    print("Step 1: Checking database connection...")
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        print("✅ Database connection successful")
        db.close()
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def list_all_users():
    """Step 2: List all users"""
    print("\n" + "=" * 60)
    print("Step 2: Listing all users in database...")
    db = SessionLocal()
    try:
        users = db.query(User).all()
        if not users:
            print("❌ No users found in database!")
            return False
        
        print(f"✅ Found {len(users)} user(s):")
        for user in users:
            print(f"   - Email: {user.email}")
            print(f"     Role: {user.role.value}")
            print(f"     Active: {user.is_active}")
            print(f"     Created: {user.created_at}")
            print(f"     Last Login: {user.last_login or 'Never'}")
            print()
        return True
    except Exception as e:
        print(f"❌ Error querying users: {e}")
        return False
    finally:
        db.close()

def check_specific_user(email):
    """Step 3: Check specific user details"""
    print("\n" + "=" * 60)
    print(f"Step 3: Checking details for user: {email}...")
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            print(f"❌ User '{email}' not found!")
            return None
        
        print(f"✅ User found:")
        print(f"   - ID: {user.id}")
        print(f"   - Email: {user.email}")
        print(f"   - Role: {user.role.value}")
        print(f"   - Active: {user.is_active}")
        print(f"   - Password hash exists: {bool(user.password_hash)}")
        print(f"   - Password hash length: {len(user.password_hash) if user.password_hash else 0}")
        print(f"   - Locked until: {user.locked_until or 'Not locked'}")
        print(f"   - Failed attempts: {user.failed_login_attempts}")
        return user
    except Exception as e:
        print(f"❌ Error: {e}")
        return None
    finally:
        db.close()

def test_password_verification(email, test_password):
    """Step 4: Test password verification"""
    print("\n" + "=" * 60)
    print(f"Step 4: Testing password verification for: {email}...")
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            print(f"❌ User not found!")
            return False
        
        if verify_password(test_password, user.password_hash):
            print("✅ Password verification successful!")
            return True
        else:
            print("❌ Password verification failed!")
            print("   The password you entered does not match the stored hash")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    finally:
        db.close()

def reset_user_password(email, new_password):
    """Step 5: Reset user password"""
    print("\n" + "=" * 60)
    print(f"Step 5: Resetting password for: {email}...")
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            print(f"❌ User not found!")
            return False
        
        # Hash new password
        new_hash = hash_password(new_password)
        
        # Update user
        user.password_hash = new_hash
        user.failed_login_attempts = 0
        user.locked_until = None
        db.commit()
        
        print("✅ Password reset successfully!")
        print(f"   New password set for: {email}")
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def create_admin_user(email, password):
    """Step 6: Create admin user if missing"""
    print("\n" + "=" * 60)
    print(f"Step 6: Creating admin user: {email}...")
    db = SessionLocal()
    try:
        # Check if user exists
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            print(f"⚠️  User already exists: {email}")
            return False
        
        # Create user
        password_hash = hash_password(password)
        admin = User(
            email=email,
            password_hash=password_hash,
            role=UserRole.ADMIN,
            is_active=True
        )
        
        db.add(admin)
        db.commit()
        db.refresh(admin)
        
        print("✅ Admin user created successfully!")
        print(f"   Email: {email}")
        print(f"   Role: ADMIN")
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def main():
    """Main diagnostic function"""
    print("\n" + "🔍 Authentication Diagnostic Tool")
    print("=" * 60)
    
    # Step 1: Check database
    if not check_database_connection():
        print("\n❌ Cannot proceed - database connection failed")
        sys.exit(1)
    
    # Step 2: List users
    if not list_all_users():
        print("\n⚠️  No users found. You may need to create users.")
    
    # Get email to check
    print("\n" + "=" * 60)
    email = input("Enter email to check (or press Enter for admin@ids.local): ").strip()
    email = email or "admin@ids.local"
    
    # Step 3: Check user
    user = check_specific_user(email)
    if not user:
        print(f"\n❌ User '{email}' not found!")
        create = input("Create this user? (y/n): ").strip().lower()
        if create == 'y':
            password = input("Enter password: ").strip()
            create_admin_user(email, password)
        sys.exit(1)
    
    # Step 4: Test password
    print("\n" + "=" * 60)
    print("Test password verification:")
    test_password = input(f"Enter password for {email}: ").strip()
    
    if test_password_verification(email, test_password):
        print("\n✅ Password is correct! Authentication should work.")
        print("\nIf authentication still fails, check:")
        print("  - Backend logs for errors")
        print("  - Token generation in auth.py")
        print("  - CORS settings")
    else:
        print("\n❌ Password is incorrect!")
        reset = input("Reset password? (y/n): ").strip().lower()
        if reset == 'y':
            new_password = input("Enter new password: ").strip()
            if new_password:
                if reset_user_password(email, new_password):
                    print(f"\n✅ Password reset! Try logging in with:")
                    print(f"   Email: {email}")
                    print(f"   Password: {new_password}")
    
    print("\n" + "=" * 60)
    print("Diagnostic complete!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Diagnostic cancelled")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()

