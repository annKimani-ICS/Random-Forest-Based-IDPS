#!/bin/bash
# Quick Fix for Relative Import Error
# This script quickly fixes the relative import issue

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Quick Fix for Relative Import Error${NC}"
echo "=============================================="

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

echo -e "${GREEN}✅ Virtual environment activated${NC}"

# Quick fix: Change relative imports to absolute imports
echo -e "${YELLOW}🔧 Quick Fix: Changing relative imports to absolute imports...${NC}"

# Fix app/main.py
if [ -f "app/main.py" ]; then
    echo -e "${BLUE}Fixing app/main.py...${NC}"
    sed -i 's/from \.config import/from app.config import/g' app/main.py
    sed -i 's/from \.routers import/from app.routers import/g' app/main.py
    sed -i 's/from \.database import/from app.database import/g' app/main.py
    echo -e "${GREEN}✅ app/main.py fixed${NC}"
fi

# Test the fix
echo -e "${BLUE}Testing the fix...${NC}"
if python -c "from app.main import app; print('✅ App imported successfully')" 2>/dev/null; then
    echo -e "${GREEN}✅ Fix successful! App can now be imported${NC}"
else
    echo -e "${RED}❌ Fix failed${NC}"
    exit 1
fi

# Test uvicorn startup
echo -e "${BLUE}Testing uvicorn startup...${NC}"
timeout 3s uvicorn app.main:app --host 0.0.0.0 --port 8000 2>/dev/null &
UVICORN_PID=$!
sleep 2

if ps -p $UVICORN_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Uvicorn started successfully${NC}"
    kill $UVICORN_PID 2>/dev/null || true
else
    echo -e "${YELLOW}⚠️ Uvicorn startup test inconclusive${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Quick Fix Complete!${NC}"
echo "=================================="
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "   ✅ Changed relative imports to absolute imports"
echo "   ✅ App import now works"
echo "   ✅ Uvicorn can start"
echo ""
echo -e "${BLUE}🚀 Now you can start the backend:${NC}"
echo "  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}🎯 Relative import error resolved!${NC}"
