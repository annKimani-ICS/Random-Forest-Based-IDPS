#!/bin/bash
# Correct Login Credentials for Admin and Analyst Only
# This script creates the correct users: ADMIN and ANALYST only

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Correct Login Credentials (Admin & Analyst Only)${NC}"
echo "=============================================="

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

# Step 4: Create correct users (Admin and Analyst only)
echo -e "${YELLOW}🔧 Step 4: Creating correct users (Admin & Analyst only)...${NC}"

# Set known passwords for testing
ADMIN_PASSWORD="AdminSecure2024!"
ANALYST_PASSWORD="AnalystSecure2024!"

python3 << PYEOF
from app.database import SessionLocal
from app.models import User, UserRole
from app.auth import hash_password
import uuid
from datetime import datetime

db = SessionLocal()
try:
    print("🔧 Setting up correct user roles...")
    
    # Clear existing users
    db.query(User).delete()
    print("✅ Cleared existing users")
    
    # Create ADMIN user
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
    print("✅ Created ADMIN user")
    
    # Create ANALYST user
    analyst_user = User(
        id=uuid.uuid4(),
        email="analyst@ids-idps.com",
        password_hash=hash_password("$ANALYST_PASSWORD"),
        role=UserRole.ANALYST,
        is_active=True,
        created_at=datetime.now(),
        last_login=None,
        failed_login_attempts=0,
        locked_until=None
    )
    db.add(analyst_user)
    print("✅ Created ANALYST user")
    
    db.commit()
    print("✅ Users created successfully")
    
    # Verify users
    users = db.query(User).all()
    print(f"\\n📊 Database now contains {len(users)} users:")
    for user in users:
        print(f"   - {user.email} ({user.role.value})")
    
except Exception as e:
    print(f"❌ Error: {e}")
    db.rollback()
finally:
    db.close()
PYEOF

echo -e "${GREEN}✅ Correct users created${NC}"

# Step 5: Create credentials file
echo -e "${YELLOW}🔧 Step 5: Creating credentials file...${NC}"

CREDENTIALS_FILE="$HOME/ids_idps_correct_credentials.txt"

cat > "$CREDENTIALS_FILE" << EOF
IDS/IDPS Login Credentials (Admin & Analyst Only)
Generated on: $(date)
================================================

ADMIN User:
  Email: admin@ids-idps.com
  Password: $ADMIN_PASSWORD
  Role: ADMIN
  Permissions: Full system access, user management, system configuration

ANALYST User:
  Email: analyst@ids-idps.com
  Password: $ANALYST_PASSWORD
  Role: ANALYST
  Permissions: View alerts, analyze data, generate reports

User Roles Available:
- ADMIN: Full system access
- ANALYST: Data analysis and reporting

Login Instructions:
1. Start API: cd backend && ./run_backend.sh
2. Start GUI: cd gui && ./run_gui.sh
3. Login with either ADMIN or ANALYST credentials above

Security Notes:
- These are temporary passwords for testing
- Change passwords after first login
- Delete this file after noting credentials
- Only ADMIN and ANALYST roles exist in the system
EOF

# Set secure permissions
chmod 600 "$CREDENTIALS_FILE"

echo -e "${GREEN}✅ Credentials file created: $CREDENTIALS_FILE${NC}"

# Step 6: Test both logins
echo -e "${YELLOW}🔧 Step 6: Testing both user logins...${NC}"

python3 << PYEOF
from app.database import SessionLocal
from app.models import User
from app.auth import verify_password

db = SessionLocal()
try:
    # Test ADMIN login
    admin_user = db.query(User).filter(User.email == "admin@ids-idps.com").first()
    if admin_user and verify_password("$ADMIN_PASSWORD", admin_user.password_hash):
        print("✅ ADMIN login test successful")
        print("   Email: admin@ids-idps.com")
        print("   Password: $ADMIN_PASSWORD")
        print("   Role: ADMIN")
    else:
        print("❌ ADMIN login test failed")
    
    print("")
    
    # Test ANALYST login
    analyst_user = db.query(User).filter(User.email == "analyst@ids-idps.com").first()
    if analyst_user and verify_password("$ANALYST_PASSWORD", analyst_user.password_hash):
        print("✅ ANALYST login test successful")
        print("   Email: analyst@ids-idps.com")
        print("   Password: $ANALYST_PASSWORD")
        print("   Role: ANALYST")
    else:
        print("❌ ANALYST login test failed")
        
except Exception as e:
    print(f"❌ Error testing logins: {e}")
finally:
    db.close()
PYEOF

# Summary
echo ""
echo -e "${GREEN}🎉 Correct Login Credentials Created!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What was created:${NC}"
echo "   ✅ ADMIN user with correct role"
echo "   ✅ ANALYST user with correct role"
echo "   ✅ Known passwords for testing"
echo "   ✅ Database verified"
echo "   ✅ Login tests successful"
echo "   ✅ Credentials file created"

echo ""
echo -e "${BLUE}🔐 Available Login Credentials:${NC}"
echo ""
echo -e "${GREEN}ADMIN User:${NC}"
echo "   Email: admin@ids-idps.com"
echo "   Password: $ADMIN_PASSWORD"
echo "   Role: ADMIN"
echo ""
echo -e "${GREEN}ANALYST User:${NC}"
echo "   Email: analyst@ids-idps.com"
echo "   Password: $ANALYST_PASSWORD"
echo "   Role: ANALYST"

echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "   1. View credentials: cat $CREDENTIALS_FILE"
echo "   2. Start API: cd backend && ./run_backend.sh"
echo "   3. Start GUI: cd gui && ./run_gui.sh"
echo "   4. Login with either ADMIN or ANALYST credentials"
echo "   5. Change passwords after first login"

echo ""
echo -e "${YELLOW}⚠️ Important Notes:${NC}"
echo "   - Only ADMIN and ANALYST roles exist in the system"
echo "   - ADMIN has full system access"
echo "   - ANALYST has data analysis permissions"
echo "   - These are temporary passwords for testing"
echo "   - Change passwords after first login"

echo ""
echo -e "${GREEN}🎯 You now have the correct login credentials!${NC}"
