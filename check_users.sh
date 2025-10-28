#!/bin/bash
# Check Database Users Script
# This script shows what users exist in the database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Check Database Users${NC}"
echo "=================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Check if backend directory exists
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ Backend directory not found${NC}"
    exit 1
fi

cd backend

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

# Check database connection
echo -e "${YELLOW}🔧 Checking database connection...${NC}"
if python -c "from app.database import SessionLocal; db = SessionLocal(); db.close()" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    exit 1
fi

# Check what users exist
echo -e "${YELLOW}🔧 Checking database users...${NC}"

python3 << PYEOF
from app.database import SessionLocal
from app.models import User
from app.auth import verify_password

db = SessionLocal()
try:
    users = db.query(User).all()
    
    if not users:
        print("❌ No users found in database")
        print("   Database needs to be seeded")
    else:
        print(f"✅ Found {len(users)} users in database:")
        print("")
        
        for user in users:
            print(f"Email: {user.email}")
            print(f"Role: {user.role.value}")
            print(f"Active: {user.is_active}")
            print(f"Created: {user.created_at}")
            print(f"Last Login: {user.last_login}")
            print(f"Failed Attempts: {user.failed_login_attempts}")
            print(f"Locked Until: {user.locked_until}")
            print("-" * 40)
            
        # Test admin login specifically
        admin_user = db.query(User).filter(User.email == "admin@ids-idps.com").first()
        if admin_user:
            print("\\n🔐 Admin User Details:")
            print(f"   Email: {admin_user.email}")
            print(f"   Role: {admin_user.role.value}")
            print(f"   Active: {admin_user.is_active}")
            print(f"   Password Hash: {admin_user.password_hash[:20]}...")
            
            # Test common passwords
            common_passwords = ["admin123", "AdminSecure2024!", "admin", "password", "123456"]
            print("\\n🔍 Testing common passwords:")
            
            for pwd in common_passwords:
                if verify_password(pwd, admin_user.password_hash):
                    print(f"   ✅ Password '{pwd}' works!")
                    break
            else:
                print("   ❌ None of the common passwords work")
                print("   Need to reset admin password")
                
except Exception as e:
    print(f"❌ Error checking users: {e}")
finally:
    db.close()
PYEOF

echo ""
echo -e "${BLUE}🚀 Quick Fix Options:${NC}"
echo ""
echo -e "${GREEN}Option 1: Run admin login fix${NC}"
echo "  ./fix_admin_login.sh"
echo ""
echo -e "${GREEN}Option 2: Run secure setup${NC}"
echo "  ./secure_setup.sh"
echo ""
echo -e "${GREEN}Option 3: Manual password reset${NC}"
echo "  # Contact system administrator"
echo ""
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "   - Admin user should exist"
echo "   - Password should be known"
echo "   - User should be active"
echo "   - Login should work"
echo ""
echo -e "${GREEN}🎯 Choose the appropriate fix option!${NC}"
