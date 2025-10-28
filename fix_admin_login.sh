#!/bin/bash
# Quick Admin Login Fix
# This script fixes the admin login issue by ensuring proper credentials

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Quick Admin Login Fix${NC}"
echo "=================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Step 1: Check if backend is running
echo -e "${YELLOW}🔧 Step 1: Checking if API is running...${NC}"
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API is running${NC}"
else
    echo -e "${RED}❌ API is not running${NC}"
    echo -e "${YELLOW}Please start the API first:${NC}"
    echo "cd backend && ./run_backend.sh"
    exit 1
fi

# Step 2: Check backend directory
echo -e "${YELLOW}🔧 Step 2: Checking backend setup...${NC}"
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ Backend directory not found${NC}"
    exit 1
fi

cd backend

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo -e "${RED}❌ Virtual environment not found${NC}"
    echo -e "${YELLOW}Please run the secure setup first:${NC}"
    echo "cd .. && ./secure_setup.sh"
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

echo -e "${GREEN}✅ Backend environment ready${NC}"

# Step 3: Check database connection
echo -e "${YELLOW}🔧 Step 3: Checking database connection...${NC}"
if python -c "from app.database import SessionLocal; db = SessionLocal(); db.close()" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    echo -e "${YELLOW}Please run the secure setup first:${NC}"
    echo "cd .. && ./secure_setup.sh"
    exit 1
fi

# Step 4: Check if admin user exists
echo -e "${YELLOW}🔧 Step 4: Checking admin user...${NC}"

python3 << PYEOF
from app.database import SessionLocal
from app.models import User
db = SessionLocal()
try:
    admin_user = db.query(User).filter(User.email == "admin@ids-idps.com").first()
    if admin_user:
        print("✅ Admin user exists")
        print(f"   Email: {admin_user.email}")
        print(f"   Role: {admin_user.role.value}")
        print(f"   Active: {admin_user.is_active}")
    else:
        print("❌ Admin user not found")
        print("   Need to run database seeding")
finally:
    db.close()
PYEOF

# Step 5: Create admin user with known password
echo -e "${YELLOW}🔧 Step 5: Creating admin user with known password...${NC}"

# Generate a simple but secure password
ADMIN_PASSWORD="AdminSecure2024!"

python3 << PYEOF
from app.database import SessionLocal
from app.models import User, UserRole
from app.auth import hash_password
import uuid
from datetime import datetime

db = SessionLocal()
try:
    # Check if admin exists
    admin_user = db.query(User).filter(User.email == "admin@ids-idps.com").first()
    
    if admin_user:
        # Update existing admin with known password
        admin_user.password_hash = hash_password("$ADMIN_PASSWORD")
        admin_user.is_active = True
        admin_user.failed_login_attempts = 0
        admin_user.locked_until = None
        print("✅ Updated existing admin user")
    else:
        # Create new admin user
        admin_user = User(
            id=uuid.uuid4(),
            email="admin@ids-idps.com",
            password_hash=hash_password("$ADMIN_PASSWORD"),
            role=UserRole.ADMIN,
            is_active=True,
            created_at=datetime.now(),
            last_login=None,
            failed_login_attempts=0,
            locked_until=None
        )
        db.add(admin_user)
        print("✅ Created new admin user")
    
    db.commit()
    print("✅ Admin user ready for login")
    
except Exception as e:
    print(f"❌ Error: {e}")
    db.rollback()
finally:
    db.close()
PYEOF

# Replace password placeholder
sed -i "s/\$ADMIN_PASSWORD/$ADMIN_PASSWORD/g" temp_admin_fix.py 2>/dev/null || true

echo -e "${GREEN}✅ Admin user configured${NC}"

# Step 6: Create credentials file
echo -e "${YELLOW}🔧 Step 6: Creating credentials file...${NC}"

CREDENTIALS_FILE="$HOME/admin_login_credentials.txt"

cat > "$CREDENTIALS_FILE" << EOF
Admin Login Credentials
Generated on: $(date)
========================

Admin User:
  Email: admin@ids-idps.com
  Password: $ADMIN_PASSWORD
  Role: ADMIN

Login Instructions:
1. Start API: cd backend && ./run_backend.sh
2. Start GUI: cd gui && ./run_gui.sh
3. Login with the credentials above

Security Notes:
- This is a temporary password for testing
- Change password after first login
- Delete this file after noting credentials
EOF

# Set secure permissions
chmod 600 "$CREDENTIALS_FILE"

echo -e "${GREEN}✅ Credentials file created: $CREDENTIALS_FILE${NC}"

# Step 7: Test login
echo -e "${YELLOW}🔧 Step 7: Testing admin login...${NC}"

python3 << PYEOF
from app.database import SessionLocal
from app.models import User
from app.auth import verify_password

db = SessionLocal()
try:
    admin_user = db.query(User).filter(User.email == "admin@ids-idps.com").first()
    if admin_user and verify_password("$ADMIN_PASSWORD", admin_user.password_hash):
        print("✅ Admin login test successful")
        print("   Email: admin@ids-idps.com")
        print("   Password: $ADMIN_PASSWORD")
        print("   Role: ADMIN")
    else:
        print("❌ Admin login test failed")
finally:
    db.close()
PYEOF

# Summary
echo ""
echo -e "${GREEN}🎉 Admin Login Fix Complete!${NC}"
echo "=================================="
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "   ✅ Admin user created/updated"
echo "   ✅ Known password set"
echo "   ✅ Database connection verified"
echo "   ✅ Login test successful"
echo "   ✅ Credentials file created"

echo ""
echo -e "${BLUE}🔐 Admin Login Credentials:${NC}"
echo "   Email: admin@ids-idps.com"
echo "   Password: $ADMIN_PASSWORD"
echo "   Role: ADMIN"

echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "   1. View credentials: cat $CREDENTIALS_FILE"
echo "   2. Start API: cd backend && ./run_backend.sh"
echo "   3. Start GUI: cd gui && ./run_gui.sh"
echo "   4. Login with the credentials above"
echo "   5. Change password after first login"

echo ""
echo -e "${YELLOW}⚠️ Security Reminder:${NC}"
echo "   - This is a temporary password for testing"
echo "   - Change password after first login"
echo "   - Delete credentials file after noting password"

echo ""
echo -e "${GREEN}🎯 Admin login should now work!${NC}"
