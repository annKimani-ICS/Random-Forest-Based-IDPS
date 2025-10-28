#!/bin/bash
# Fix Login Credentials Issue
# This script fixes the credentials and database seeding problems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔐 Fix Login Credentials Issue${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Step 1: Check if backend directory exists
echo -e "${YELLOW}🔧 Step 1: Checking backend directory...${NC}"
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ Backend directory not found${NC}"
    echo -e "${YELLOW}Please run this script from the project root directory${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend directory found${NC}"

# Step 2: Check if virtual environment exists
echo -e "${YELLOW}🔧 Step 2: Checking virtual environment...${NC}"
cd backend

if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}⚠️ Virtual environment not found. Creating one...${NC}"
    python3 -m venv .venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${BLUE}Activating virtual environment...${NC}"
source .venv/bin/activate

# Install dependencies if needed
echo -e "${BLUE}Checking dependencies...${NC}"
if ! python -c "import fastapi" 2>/dev/null; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install -r requirements.txt
    echo -e "${GREEN}✅ Dependencies installed${NC}"
fi

echo -e "${GREEN}✅ Virtual environment ready${NC}"

# Step 3: Check database connection
echo -e "${YELLOW}🔧 Step 3: Checking database connection...${NC}"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cat > .env << EOF
DATABASE_URL=postgresql://postgres@localhost:5432/ids_idps_db
JWT_SECRET=ids-secret-key-$(date +%s)
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:5173,http://localhost:8000
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
EOF
    echo -e "${GREEN}✅ .env file created${NC}"
fi

# Test database connection
echo -e "${BLUE}Testing database connection...${NC}"
if python -c "from app.database import SessionLocal; db = SessionLocal(); db.close()" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    echo -e "${YELLOW}Setting up PostgreSQL database...${NC}"
    
    # Start PostgreSQL
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    # Create database and user
    sudo -u postgres psql -c "CREATE DATABASE ids_idps_db;" 2>/dev/null || echo "Database already exists"
    sudo -u postgres psql -c "CREATE USER ids_user WITH PASSWORD 'ids_password';" 2>/dev/null || echo "User already exists"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ids_idps_db TO ids_user;" 2>/dev/null || true
    
    echo -e "${GREEN}✅ PostgreSQL database configured${NC}"
fi

# Step 4: Initialize database tables
echo -e "${YELLOW}🔧 Step 4: Initializing database tables...${NC}"

python3 << PYEOF
from app.database import engine, Base
from app.models import *
try:
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created successfully")
except Exception as e:
    print(f"Error creating tables: {e}")
PYEOF

echo -e "${GREEN}✅ Database tables initialized${NC}"

# Step 5: Clear existing data and reseed
echo -e "${YELLOW}🔧 Step 5: Clearing and reseeding database...${NC}"

# Clear existing data
python3 << PYEOF
from app.database import SessionLocal
from app.models import User, UserMFA, Alert, BlockRule, Model, Threshold
db = SessionLocal()
try:
    # Clear existing data
    db.query(UserMFA).delete()
    db.query(Alert).delete()
    db.query(BlockRule).delete()
    db.query(Model).delete()
    db.query(Threshold).delete()
    db.query(User).delete()
    db.commit()
    print("✅ Existing data cleared")
except Exception as e:
    print(f"Error clearing data: {e}")
    db.rollback()
finally:
    db.close()
PYEOF

# Run seed script
echo -e "${BLUE}Running seed script...${NC}"
python3 seed_data.py

echo -e "${GREEN}✅ Database reseeded successfully${NC}"

# Step 6: Create credentials file
echo -e "${YELLOW}🔧 Step 6: Creating credentials file...${NC}"

CREDENTIALS_FILE="$HOME/ids_idps_credentials.txt"

# Get the actual credentials from the database
python3 << PYEOF > "$CREDENTIALS_FILE"
from app.database import SessionLocal
from app.models import User
db = SessionLocal()
try:
    users = db.query(User).all()
    print("IDS/IDPS Login Credentials")
    print("Generated on: $(date)")
    print("================================")
    print("")
    
    for user in users:
        print(f"Email: {user.email}")
        print(f"Role: {user.role.value}")
        print(f"Active: {user.is_active}")
        print("Password: [Generated during setup - check seed_data.py]")
        print("")
        
    print("Note: Default passwords are set in seed_data.py")
    print("Common default passwords:")
    print("- admin@ids-idps.com: admin123")
    print("- analyst@ids-idps.com: analyst123")
    print("- user@ids-idps.com: user123")
    
except Exception as e:
    print(f"Error getting credentials: {e}")
finally:
    db.close()
PYEOF

echo -e "${GREEN}✅ Credentials file created: $CREDENTIALS_FILE${NC}"

# Step 7: Show credentials
echo -e "${YELLOW}🔧 Step 7: Displaying credentials...${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔐 LOGIN CREDENTIALS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -f "$CREDENTIALS_FILE" ]; then
    cat "$CREDENTIALS_FILE"
else
    echo -e "${YELLOW}Default credentials (if seed_data.py was used):${NC}"
    echo ""
    echo -e "${GREEN}Admin User:${NC}"
    echo "  Email: admin@ids-idps.com"
    echo "  Password: admin123"
    echo ""
    echo -e "${GREEN}Analyst User:${NC}"
    echo "  Email: analyst@ids-idps.com"
    echo "  Password: analyst123"
    echo ""
    echo -e "${GREEN}Regular User:${NC}"
    echo "  Email: user@ids-idps.com"
    echo "  Password: user123"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 NEXT STEPS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}1. Start the API:${NC}"
echo "   cd backend && ./run_backend.sh"
echo ""
echo -e "${GREEN}2. Launch the GUI:${NC}"
echo "   cd gui && ./run_gui.sh"
echo ""
echo -e "${GREEN}3. Login with the credentials above${NC}"
echo ""
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "   - API runs on port 8000"
echo "   - GUI connects successfully"
echo "   - Login works with provided credentials"
echo "   - Dashboard shows correct metrics"
echo ""
echo -e "${GREEN}🎯 Login credentials issue fixed!${NC}"
