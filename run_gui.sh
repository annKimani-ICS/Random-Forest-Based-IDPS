#!/bin/bash
# Fix GUI Dependencies and Run GUI

# Don't exit on error - we'll handle errors explicitly
set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing GUI Dependencies${NC}"
echo "=============================================="

# Get script directory (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we're in the right place
if [ ! -d "gui" ]; then
    echo -e "${RED}❌ GUI directory not found${NC}"
    exit 1
fi

# Activate virtual environment
if [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${GREEN}✅ Virtual environment already active: $VIRTUAL_ENV${NC}"
elif [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
    echo -e "${BLUE}📦 Activating virtual environment...${NC}"
    source venv/bin/activate
elif [ -d ".venv" ] && [ -f ".venv/bin/activate" ]; then
    echo -e "${BLUE}📦 Activating virtual environment...${NC}"
    source .venv/bin/activate
elif [ -d "backend/.venv" ] && [ -f "backend/.venv/bin/activate" ]; then
    echo -e "${BLUE}📦 Activating backend virtual environment...${NC}"
    source backend/.venv/bin/activate
else
    echo -e "${YELLOW}⚠️  Virtual environment not found. Creating one...${NC}"
    python3 -m venv venv || python3 -m venv .venv
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    else
        echo -e "${RED}❌ Failed to create virtual environment${NC}"
        exit 1
    fi
fi

# Install GUI dependencies
echo -e "${BLUE}📦 Installing GUI dependencies...${NC}"
pip install --upgrade pip setuptools wheel
pip install PyQt5 requests python-dotenv

echo -e "${GREEN}✅ Dependencies installed${NC}"

# Check GUI files
echo -e "${BLUE}📋 Checking GUI files...${NC}"
if [ ! -f "gui/main.py" ]; then
    echo -e "${RED}❌ gui/main.py not found${NC}"
    exit 1
fi

if [ ! -f "gui/login_window.py" ]; then
    echo -e "${RED}❌ gui/login_window.py not found${NC}"
    exit 1
fi

if [ ! -f "gui/api_client.py" ]; then
    echo -e "${RED}❌ gui/api_client.py not found${NC}"
    exit 1
fi

# Check if backend is running
echo -e "${BLUE}📋 Checking if backend is running...${NC}"
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is running on http://localhost:8000${NC}"
else
    echo -e "${YELLOW}⚠️  Backend is not running. Please start it first:${NC}"
    echo "  cd backend && source .venv/bin/activate"
    echo "  export PYTHONPATH=\$(pwd)"
    echo "  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
    echo ""
    echo -e "${YELLOW}Do you want to continue anyway? (y/n)${NC}"
    read -r response
    if [ "$response" != "y" ]; then
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}🎉 GUI Dependencies Fixed!${NC}"
echo "=============================================="
echo -e "${BLUE}🚀 Starting GUI...${NC}"
echo ""

# Set PYTHONPATH and run GUI
export PYTHONPATH="$SCRIPT_DIR:$SCRIPT_DIR/gui"
cd gui
python3 main.py