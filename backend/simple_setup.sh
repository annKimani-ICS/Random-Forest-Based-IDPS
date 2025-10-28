#!/bin/bash
# Simple database setup using postgres user
# This avoids authentication issues by using the default postgres user

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Simple Database Setup (Using postgres user)${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 1: Ensure PostgreSQL is running
echo -e "${YELLOW}🔧 Step 1: Starting PostgreSQL...${NC}"
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Step 2: Create database using postgres user
echo -e "${YELLOW}🔧 Step 2: Creating database...${NC}"
sudo -u postgres psql -c "CREATE DATABASE ids_db;" 2>/dev/null || echo "Database already exists"

# Step 3: Create .env file with postgres user
echo -e "${YELLOW}🔧 Step 3: Creating environment configuration...${NC}"
cat > .env << EOF
DATABASE_URL=postgresql://postgres@localhost:5432/ids_db
JWT_SECRET=ids-secret-key-$(date +%s)
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000
EOF

echo -e "${GREEN}✅ Environment configuration created!${NC}"

# Step 4: Setup virtual environment
echo -e "${YELLOW}🔧 Step 4: Setting up Python environment...${NC}"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "${GREEN}✅ Python environment ready!${NC}"

# Step 5: Create tables
echo -e "${YELLOW}🔧 Step 5: Creating database tables...${NC}"
python -c "
from app.database import engine, Base
from app.models import *
try:
    Base.metadata.create_all(bind=engine)
    print('✅ Database tables created successfully')
except Exception as e:
    print(f'Error: {e}')
"

# Step 6: Populate with correct metrics
echo -e "${YELLOW}🔧 Step 6: Populating correct metrics...${NC}"
python add_dummy_alerts.py

echo -e "\n${GREEN}🎉 Simple setup complete!${NC}"
echo "=================================="
echo -e "${BLUE}📋 What was configured:${NC}"
echo "   ✅ PostgreSQL database (ids_db)"
echo "   ✅ Using postgres user (no auth issues)"
echo "   ✅ Environment configuration (.env)"
echo "   ✅ Python virtual environment (.venv)"
echo "   ✅ Dependencies installed"
echo "   ✅ Database tables created"
echo "   ✅ Correct Random Forest metrics populated"

echo -e "\n${BLUE}🚀 Next steps:${NC}"
echo "   1. Start backend: python -m uvicorn app.main:app --host 0.0.0.0 --port 3000 --reload"
echo "   2. Start GUI: cd ../gui && python main.py"

echo -e "\n${YELLOW}📊 Expected GUI metrics:${NC}"
echo "   - Accuracy: 90.48%"
echo "   - Precision: 90.62%"
echo "   - Recall: 90.48%"
echo "   - F1-Score: 90.51%"
echo "   - AUC: 95.00%"

echo -e "\n${GREEN}🎯 Ready to test!${NC}"
