#!/bin/bash
# Automated Backend Pydantic Fix
# Fixes Pydantic v2 incompatibility that prevents backend from starting

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Automated Backend Pydantic Fix${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we're in backend directory
if [ ! -f "app/main.py" ]; then
    echo -e "${RED}❌ Please run this script from the backend directory${NC}"
    exit 1
fi

# Activate virtual environment
if [ -d ".venv" ]; then
    echo -e "${BLUE}📦 Activating virtual environment...${NC}"
    source .venv/bin/activate
elif [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${GREEN}✅ Virtual environment already active${NC}"
else
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Checking current Pydantic version...${NC}"
PYDANTIC_VERSION=$(python3 -c "import pydantic; print(pydantic.__version__)" 2>/dev/null || echo "not installed")
echo -e "${YELLOW}Current Pydantic version: $PYDANTIC_VERSION${NC}"

if echo "$PYDANTIC_VERSION" | grep -qE "^[2-9]\."; then
    echo -e "${YELLOW}⚠️  Pydantic v2 detected - incompatible with FastAPI 0.109.0${NC}"
    
    echo -e "${BLUE}📋 Step 2: Uninstalling Pydantic v2...${NC}"
    pip uninstall -y pydantic pydantic-settings pydantic-core 2>/dev/null || true
    echo -e "${GREEN}✅ Pydantic v2 uninstalled${NC}"
    
    echo -e "${BLUE}📋 Step 3: Installing Pydantic v1 (<2.0.0)...${NC}"
    pip install --upgrade pip setuptools wheel
    pip install "pydantic<2.0.0"
    echo -e "${GREEN}✅ Pydantic v1 installed${NC}"
else
    echo -e "${GREEN}✅ Pydantic version looks compatible${NC}"
    # Still ensure it's v1
    pip install --upgrade "pydantic<2.0.0" 2>/dev/null || true
fi

echo -e "${BLUE}📋 Step 4: Verifying Pydantic v1 installation...${NC}"
if python3 -c "from pydantic import BaseModel, BaseSettings; print('✅ Pydantic v1 OK')" 2>/dev/null; then
    echo -e "${GREEN}✅ Pydantic v1 verified${NC}"
else
    echo -e "${RED}❌ Pydantic v1 verification failed${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 5: Verifying FastAPI compatibility...${NC}"
if python3 -c "from fastapi import FastAPI; print('✅ FastAPI OK')" 2>/dev/null; then
    echo -e "${GREEN}✅ FastAPI verified${NC}"
else
    echo -e "${YELLOW}⚠️  FastAPI import failed, installing...${NC}"
    pip install fastapi==0.109.0
fi

echo -e "${BLUE}📋 Step 6: Testing backend import...${NC}"
if python3 -c "
import sys
sys.path.insert(0, '.')
from app.config import settings
from app.main import app
print('✅ Backend imports OK')
" 2>/dev/null; then
    echo -e "${GREEN}✅ Backend imports verified${NC}"
else
    echo -e "${RED}❌ Backend import failed. Checking config.py...${NC}"
    
    # Check if config.py uses BaseSettings correctly
    if grep -q "from pydantic_settings import BaseSettings" app/config.py 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Found pydantic_settings import, fixing...${NC}"
        sed -i 's/from pydantic_settings import BaseSettings/from pydantic import BaseSettings/g' app/config.py
        echo -e "${GREEN}✅ Fixed config.py${NC}"
    fi
    
    # Test again
    if python3 -c "
import sys
sys.path.insert(0, '.')
from app.config import settings
from app.main import app
print('✅ Backend imports OK')
" 2>/dev/null; then
        echo -e "${GREEN}✅ Backend imports now working${NC}"
    else
        echo -e "${RED}❌ Backend still failing. Check error messages above${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}🎉 Backend Pydantic Fix Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo "   ✅ Pydantic v1 installed"
echo "   ✅ FastAPI compatibility verified"
echo "   ✅ Backend imports working"
echo ""
echo -e "${BLUE}🚀 Start the backend:${NC}"
echo "  source .venv/bin/activate"
echo "  export PYTHONPATH=\$(pwd)"
echo "  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}🎯 Backend should now start without errors!${NC}"

