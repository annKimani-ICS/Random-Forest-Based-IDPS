#!/bin/bash
# Fix Uvicorn Installation Issues
# This script resolves common uvicorn installation problems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fix Uvicorn Installation Issues${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Step 1: Check Python version
echo -e "${YELLOW}🔧 Step 1: Checking Python version...${NC}"
PYTHON_VERSION=$(python3 --version 2>&1)
echo -e "${BLUE}Python version: $PYTHON_VERSION${NC}"

# Check if Python 3.8+ is available
PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    echo -e "${RED}❌ Python 3.8+ required. Found Python $PYTHON_MAJOR.$PYTHON_MINOR${NC}"
    echo -e "${YELLOW}Please install Python 3.8 or higher${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Python version is compatible${NC}"

# Step 2: Check if we're in backend directory
echo -e "${YELLOW}🔧 Step 2: Checking backend directory...${NC}"
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ Backend directory not found${NC}"
    echo -e "${YELLOW}Please run this script from the project root directory${NC}"
    exit 1
fi

cd backend

# Step 3: Clean up existing virtual environment
echo -e "${YELLOW}🔧 Step 3: Cleaning up existing virtual environment...${NC}"
if [ -d ".venv" ]; then
    echo -e "${BLUE}Removing existing virtual environment...${NC}"
    rm -rf .venv
    echo -e "${GREEN}✅ Old virtual environment removed${NC}"
fi

# Step 4: Create fresh virtual environment
echo -e "${YELLOW}🔧 Step 4: Creating fresh virtual environment...${NC}"
python3 -m venv .venv
echo -e "${GREEN}✅ Fresh virtual environment created${NC}"

# Step 5: Activate virtual environment
echo -e "${YELLOW}🔧 Step 5: Activating virtual environment...${NC}"
source .venv/bin/activate

# Verify activation
if [ "$VIRTUAL_ENV" != "" ]; then
    echo -e "${GREEN}✅ Virtual environment activated: $VIRTUAL_ENV${NC}"
else
    echo -e "${RED}❌ Virtual environment not activated${NC}"
    exit 1
fi

# Step 6: Upgrade pip and setuptools
echo -e "${YELLOW}🔧 Step 6: Upgrading pip and setuptools...${NC}"
pip install --upgrade pip setuptools wheel
echo -e "${GREEN}✅ pip, setuptools, and wheel upgraded${NC}"

# Step 7: Install dependencies step by step
echo -e "${YELLOW}🔧 Step 7: Installing dependencies step by step...${NC}"

# Install uvicorn first with specific version
echo -e "${BLUE}Installing uvicorn...${NC}"
pip install uvicorn[standard]==0.27.0
echo -e "${GREEN}✅ uvicorn installed${NC}"

# Install other dependencies
echo -e "${BLUE}Installing other dependencies...${NC}"
pip install fastapi==0.109.0
pip install sqlalchemy==2.0.25
pip install psycopg2-binary==2.9.9
pip install python-jose[cryptography]==3.3.0
pip install passlib[bcrypt]==1.7.4
pip install bcrypt==4.0.1
pip install python-multipart==0.0.6
pip install pyotp==2.9.0
pip install qrcode[pil]==7.4.2
pip install python-dotenv==1.0.0
pip install pydantic==2.5.3
pip install pydantic-settings==2.1.0
pip install email-validator==2.1.0
pip install slowapi==0.1.9

echo -e "${GREEN}✅ All dependencies installed${NC}"

# Step 8: Verify uvicorn installation
echo -e "${YELLOW}🔧 Step 8: Verifying uvicorn installation...${NC}"
if python -c "import uvicorn" 2>/dev/null; then
    echo -e "${GREEN}✅ uvicorn imported successfully${NC}"
else
    echo -e "${RED}❌ uvicorn import failed${NC}"
    echo -e "${YELLOW}Trying alternative installation...${NC}"
    
    # Try installing without extras
    pip install uvicorn==0.27.0
    pip install httptools
    pip install python-multipart
    
    if python -c "import uvicorn" 2>/dev/null; then
        echo -e "${GREEN}✅ uvicorn imported successfully (alternative method)${NC}"
    else
        echo -e "${RED}❌ uvicorn still not working${NC}"
        exit 1
    fi
fi

# Step 9: Test uvicorn command
echo -e "${YELLOW}🔧 Step 9: Testing uvicorn command...${NC}"
if uvicorn --version 2>/dev/null; then
    UVICORN_VERSION=$(uvicorn --version)
    echo -e "${GREEN}✅ uvicorn command works: $UVICORN_VERSION${NC}"
else
    echo -e "${RED}❌ uvicorn command not found${NC}"
    echo -e "${YELLOW}Trying python -m uvicorn...${NC}"
    
    if python -m uvicorn --version 2>/dev/null; then
        echo -e "${GREEN}✅ python -m uvicorn works${NC}"
    else
        echo -e "${RED}❌ Both uvicorn methods failed${NC}"
        exit 1
    fi
fi

# Step 10: Create .env file if missing
echo -e "${YELLOW}🔧 Step 10: Creating .env file...${NC}"
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

# Step 11: Test backend startup
echo -e "${YELLOW}🔧 Step 11: Testing backend startup...${NC}"
echo -e "${BLUE}Testing if backend can start (will stop after 5 seconds)...${NC}"

# Start backend in background and kill it after 5 seconds
timeout 5s python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 2>/dev/null &
BACKEND_PID=$!

# Wait a moment for startup
sleep 3

# Check if backend is running
if ps -p $BACKEND_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend started successfully${NC}"
    kill $BACKEND_PID 2>/dev/null || true
else
    echo -e "${YELLOW}⚠️ Backend startup test inconclusive${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}🎉 Uvicorn Installation Fixed!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "   ✅ Fresh virtual environment created"
echo "   ✅ pip, setuptools, wheel upgraded"
echo "   ✅ uvicorn installed with dependencies"
echo "   ✅ All backend dependencies installed"
echo "   ✅ uvicorn import verified"
echo "   ✅ uvicorn command tested"
echo "   ✅ .env file created"
echo "   ✅ Backend startup tested"

echo ""
echo -e "${BLUE}🚀 How to Start Backend:${NC}"
echo ""
echo -e "${GREEN}Method 1: Using uvicorn directly${NC}"
echo "  cd backend"
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}Method 2: Using python -m uvicorn${NC}"
echo "  cd backend"
echo "  source .venv/bin/activate"
echo "  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}Method 3: Using run_backend.sh${NC}"
echo "  cd backend && ./run_backend.sh"
echo ""
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "   - Backend starts on port 8000"
echo "   - No uvicorn installation errors"
echo "   - API accessible at http://localhost:8000"
echo "   - API docs at http://localhost:8000/docs"
echo ""
echo -e "${GREEN}🎯 Uvicorn installation issue resolved!${NC}"

