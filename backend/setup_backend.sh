#!/bin/bash
# One-Command Backend Setup
# Creates users, seeds data, and ensures everything is ready

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 One-Command Backend Setup${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activate virtual environment
if [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo -e "${RED}❌ Virtual environment not found. Please run simple_postgres_fix.sh first${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Testing database connection...${NC}"
if python3 -c "
from app.database import SessionLocal
from sqlalchemy import text
try:
    db = SessionLocal()
    db.execute(text('SELECT 1'))
    db.close()
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection verified${NC}"
else
    echo -e "${RED}❌ Database connection failed. Please run simple_postgres_fix.sh first${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 2: Creating users...${NC}"
if python3 <<'ENDPYTHON'
import sys
sys.path.insert(0, '.')
from app.database import SessionLocal, engine, Base
from app.models import User, UserRole
from app.auth import hash_password

db = SessionLocal()
try:
    # Ensure tables exist
    Base.metadata.create_all(bind=engine)
    
    # Create Admin user
    u = db.query(User).filter(User.email == "admin@ids-idps.com").first()
    if not u:
        u = User(email="admin@ids-idps.com", password_hash=hash_password("AdminSecure2024!"), role=UserRole.ADMIN, is_active=True)
        db.add(u)
        print("✅ Created admin@ids-idps.com")
    else:
        u.password_hash = hash_password("AdminSecure2024!")
        u.role = UserRole.ADMIN
        u.is_active = True
        print("✅ Updated admin@ids-idps.com")
    db.commit()
    
    # Create Analyst user
    u = db.query(User).filter(User.email == "analyst@ids-idps.com").first()
    if not u:
        u = User(email="analyst@ids-idps.com", password_hash=hash_password("AnalystSecure2024!"), role=UserRole.ANALYST, is_active=True)
        db.add(u)
        print("✅ Created analyst@ids-idps.com")
    else:
        u.password_hash = hash_password("AnalystSecure2024!")
        u.role = UserRole.ANALYST
        u.is_active = True
        print("✅ Updated analyst@ids-idps.com")
    db.commit()
    
    print("✅ All users created successfully")
    sys.exit(0)
except Exception as e:
    print(f"❌ Error: {e}")
    db.rollback()
    sys.exit(1)
finally:
    db.close()
ENDPYTHON
; then
    echo -e "${GREEN}✅ Users created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create users${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 3: Checking if seed_data exists...${NC}"
if [ -f "seed_data.py" ]; then
    echo -e "${BLUE}📋 Step 4: Running seed_data.py...${NC}"
    if python3 seed_data.py; then
        echo -e "${GREEN}✅ Data seeded successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  seed_data.py failed, but continuing...${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  seed_data.py not found. Skipping data seeding${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Backend Setup Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 Login Credentials:${NC}"
echo "   Admin:  admin@ids-idps.com / AdminSecure2024!"
echo "   Analyst: analyst@ids-idps.com / AnalystSecure2024!"
echo ""
echo -e "${BLUE}🚀 Start the backend:${NC}"
echo "  source .venv/bin/activate"
echo "  export PYTHONPATH=\$(pwd)"
echo "  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}🎯 Users are now ready for GUI login!${NC}"

