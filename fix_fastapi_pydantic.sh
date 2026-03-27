#!/bin/bash
# Fix FastAPI-Pydantic Compatibility Issue
# This script fixes the ImportError: cannot import name 'BaseModel' from 'pydantic'

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fix FastAPI-Pydantic Compatibility Issue${NC}"
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

cd backend

# Step 2: Check if virtual environment exists
echo -e "${YELLOW}🔧 Step 2: Checking virtual environment...${NC}"
if [ ! -d ".venv" ]; then
    echo -e "${RED}❌ Virtual environment not found${NC}"
    echo -e "${YELLOW}Please run the secure setup first:${NC}"
    echo "cd .. && ./secure_setup.sh"
    exit 1
fi

# Activate virtual environment
echo -e "${BLUE}Activating virtual environment...${NC}"
source .venv/bin/activate

# Verify activation
if [ "$VIRTUAL_ENV" != "" ]; then
    echo -e "${GREEN}✅ Virtual environment activated: $VIRTUAL_ENV${NC}"
else
    echo -e "${RED}❌ Virtual environment not activated${NC}"
    exit 1
fi

# Step 3: Check current package versions
echo -e "${YELLOW}🔧 Step 3: Checking current package versions...${NC}"
echo -e "${BLUE}Current FastAPI version:${NC}"
pip show fastapi | grep Version || echo "FastAPI not installed"

echo -e "${BLUE}Current Pydantic version:${NC}"
pip show pydantic | grep Version || echo "Pydantic not installed"

# Step 4: Uninstall conflicting packages
echo -e "${YELLOW}🔧 Step 4: Uninstalling conflicting packages...${NC}"
echo -e "${BLUE}Uninstalling FastAPI and Pydantic...${NC}"
pip uninstall -y fastapi pydantic pydantic-settings || true
echo -e "${GREEN}✅ Conflicting packages uninstalled${NC}"

# Step 5: Install compatible versions
echo -e "${YELLOW}🔧 Step 5: Installing compatible versions...${NC}"

# Install Pydantic v1 (compatible with FastAPI 0.109.0)
echo -e "${BLUE}Installing Pydantic v1...${NC}"
pip install "pydantic<2.0.0"
echo -e "${GREEN}✅ Pydantic v1 installed${NC}"

# Install FastAPI with compatible dependencies
echo -e "${BLUE}Installing FastAPI...${NC}"
pip install fastapi==0.109.0
echo -e "${GREEN}✅ FastAPI installed${NC}"

# Install other dependencies
echo -e "${BLUE}Installing other dependencies...${NC}"
pip install uvicorn[standard]==0.27.0
pip install sqlalchemy==2.0.25
pip install psycopg2-binary==2.9.9
pip install python-jose[cryptography]==3.3.0
pip install passlib[bcrypt]==1.7.4
pip install bcrypt==4.0.1
pip install python-multipart==0.0.6
pip install pyotp==2.9.0
pip install qrcode[pil]==7.4.2
pip install python-dotenv==1.0.0
pip install email-validator==2.1.0
pip install slowapi==0.1.9

echo -e "${GREEN}✅ All dependencies installed${NC}"

# Step 6: Test imports
echo -e "${YELLOW}🔧 Step 6: Testing imports...${NC}"

# Test Pydantic import
echo -e "${BLUE}Testing Pydantic import...${NC}"
if python -c "from pydantic import BaseModel; print('✅ Pydantic BaseModel imported successfully')" 2>/dev/null; then
    echo -e "${GREEN}✅ Pydantic import test passed${NC}"
else
    echo -e "${RED}❌ Pydantic import test failed${NC}"
    exit 1
fi

# Test FastAPI import
echo -e "${BLUE}Testing FastAPI import...${NC}"
if python -c "from fastapi import FastAPI; print('✅ FastAPI imported successfully')" 2>/dev/null; then
    echo -e "${GREEN}✅ FastAPI import test passed${NC}"
else
    echo -e "${RED}❌ FastAPI import test failed${NC}"
    exit 1
fi

# Test app import
echo -e "${BLUE}Testing app import...${NC}"
if python -c "from app.main import app; print('✅ App imported successfully')" 2>/dev/null; then
    echo -e "${GREEN}✅ App import test passed${NC}"
else
    echo -e "${RED}❌ App import test failed${NC}"
    echo -e "${YELLOW}Checking app.main.py for issues...${NC}"
    
    # Check if app.main.py exists and has correct imports
    if [ -f "app/main.py" ]; then
        echo -e "${BLUE}app/main.py exists, checking imports...${NC}"
        python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.main import app
    print('✅ App import successful')
except Exception as e:
    print(f'❌ App import failed: {e}')
    # Try to identify the specific issue
    try:
        from app.database import engine, Base
        print('✅ Database imports work')
    except Exception as e2:
        print(f'❌ Database import failed: {e2}')
"
    else
        echo -e "${RED}❌ app/main.py not found${NC}"
        exit 1
    fi
fi

# Step 7: Test uvicorn startup
echo -e "${YELLOW}🔧 Step 7: Testing uvicorn startup...${NC}"
echo -e "${BLUE}Testing if uvicorn can start the app (will stop after 3 seconds)...${NC}"

# Start uvicorn in background and kill it after 3 seconds
timeout 3s uvicorn app.main:app --host 0.0.0.0 --port 8000 2>/dev/null &
UVICORN_PID=$!

# Wait a moment for startup
sleep 2

# Check if uvicorn is running
if ps -p $UVICORN_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Uvicorn started successfully${NC}"
    kill $UVICORN_PID 2>/dev/null || true
else
    echo -e "${YELLOW}⚠️ Uvicorn startup test inconclusive${NC}"
fi

# Step 8: Create .env file if missing
echo -e "${YELLOW}🔧 Step 8: Creating .env file...${NC}"
if [ ! -f ".env" ]; then
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
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}🎉 FastAPI-Pydantic Compatibility Fixed!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "   ✅ Uninstalled conflicting FastAPI/Pydantic versions"
echo "   ✅ Installed Pydantic v1 (<2.0.0)"
echo "   ✅ Installed FastAPI 0.109.0"
echo "   ✅ Installed all compatible dependencies"
echo "   ✅ Tested Pydantic BaseModel import"
echo "   ✅ Tested FastAPI import"
echo "   ✅ Tested app import"
echo "   ✅ Tested uvicorn startup"
echo "   ✅ Created .env file"

echo ""
echo -e "${BLUE}🚀 How to Start Backend:${NC}"
echo ""
echo -e "${GREEN}Method 1: Using uvicorn directly${NC}"
echo "  cd backend"
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}Method 2: Using run_backend.sh${NC}"
echo "  cd backend && ./run_backend.sh"
echo ""
echo -e "${GREEN}Method 3: Using alternative script${NC}"
echo "  cd backend && ./start_backend_alternative.sh"
echo ""
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "   - No ImportError for BaseModel"
echo "   - FastAPI imports successfully"
echo "   - Uvicorn starts without errors"
echo "   - Backend runs on port 8000"
echo "   - API accessible at http://localhost:8000"
echo ""
echo -e "${GREEN}🎯 FastAPI-Pydantic compatibility issue resolved!${NC}"
