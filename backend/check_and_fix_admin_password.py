#!/usr/bin/env python3
"""
Check and fix admin password
Allows you to verify or reset the admin password
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine, Base
from app.models import User, UserRole
from app.auth import hash_password, verify_password

def check_users():
    """Check existing users"""
    db = SessionLocal()
    try:
        users = db.query(User).all()
        if not users:
            print("❌ No users found in database")
            return False
        
        print("\n📋 Existing Users:")
        print("=" * 50)
        for user in users:
            print(f"  Email: {user.email}")
            print(f"  Role: {user.role.value}")
            print(f"  Active: {user.is_active}")
            print(f"  Has Password: {'Yes' if user.password_hash else 'No'}")
            print("-" * 50)
        
        return True
    except Exception as e:
        print(f"❌ Error checking users: {e}")
        return False
    finally:
        db.close()

def reset_admin_password(new_password=None):
    """Reset admin password"""
    db = SessionLocal()
    try:
        # Ensure tables exist
        Base.metadata.create_all(bind=engine)
        
        # Get or create admin user
        admin = db.query(User).filter(User.email == "admin@ids-idps.com").first()
        
        if not admin:
            print("❌ Admin user not found. Creating new admin user...")
            import secrets
            if not new_password:
                new_password = secrets.token_urlsafe(16)
            
            admin = User(
                email="admin@ids-idps.com",
                password_hash=hash_password(new_password),
                role=UserRole.ADMIN,
                is_active=True
            )
            db.add(admin)
            print("✅ Created admin user")
        else:
            # Use provided password or generate one
            import secrets
            if not new_password:
                new_password = secrets.token_urlsafe(16)
            
            admin.password_hash = hash_password(new_password)
            admin.role = UserRole.ADMIN
            admin.is_active = True
            print("✅ Updated admin password")
        
        db.commit()
        
        print("\n" + "=" * 50)
        print("🔐 ADMIN CREDENTIALS")
        print("=" * 50)
        print(f"Email: admin@ids-idps.com")
        print(f"Password: {new_password}")
        print("=" * 50)
        print("\n⚠️  Save this password securely!")
        print("You can now login with these credentials.")
        
        return True, new_password
    except Exception as e:
        print(f"❌ Error resetting password: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        return False, None
    finally:
        db.close()

def test_login(email, password):
    """Test login with credentials"""
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            print(f"❌ User {email} not found")
            return False
        
        if not user.is_active:
            print(f"❌ User {email} is inactive")
            return False
        
        if verify_password(password, user.password_hash):
            print(f"✅ Login successful for {email}")
            print(f"   Role: {user.role.value}")
            return True
        else:
            print(f"❌ Incorrect password for {email}")
            return False
    except Exception as e:
        print(f"❌ Error testing login: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()

def main():
    print("\n🔧 Admin Password Checker & Fixer")
    print("=" * 50)
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "check":
            check_users()
        elif command == "reset":
            new_password = sys.argv[2] if len(sys.argv) > 2 else None
            reset_admin_password(new_password)
        elif command == "test":
            email = sys.argv[2] if len(sys.argv) > 2 else "admin@ids-idps.com"
            password = sys.argv[3] if len(sys.argv) > 3 else None
            if not password:
                print("❌ Please provide password to test")
                print("Usage: python3 check_and_fix_admin_password.py test <email> <password>")
                return
            test_login(email, password)
        else:
            print(f"❌ Unknown command: {command}")
            print("\nUsage:")
            print("  python3 check_and_fix_admin_password.py check           # Check existing users")
            print("  python3 check_and_fix_admin_password.py reset          # Reset with auto-generated password")
            print("  python3 check_and_fix_admin_password.py reset <pass>   # Reset with specific password")
            print("  python3 check_and_fix_admin_password.py test <email> <pass>  # Test login")
    else:
        # Interactive mode
        print("\nOptions:")
        print("1. Check existing users")
        print("2. Reset admin password (auto-generate)")
        print("3. Reset admin password (custom)")
        print("4. Test login")
        print("5. Exit")
        
        choice = input("\nSelect option (1-5): ").strip()
        
        if choice == "1":
            check_users()
        elif choice == "2":
            reset_admin_password()
        elif choice == "3":
            password = input("Enter new password: ").strip()
            if password:
                reset_admin_password(password)
            else:
                print("❌ Password cannot be empty")
        elif choice == "4":
            email = input("Email (default: admin@ids-idps.com): ").strip() or "admin@ids-idps.com"
            password = input("Password: ").strip()
            if password:
                test_login(email, password)
            else:
                print("❌ Password cannot be empty")
        elif choice == "5":
            print("Exiting...")
        else:
            print("❌ Invalid option")

if __name__ == "__main__":
    main()

