#!/bin/bash
# Complete project setup script
# Usage: ./setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 IDS/IDPS Project Setup${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}📁 Project directory: $PROJECT_DIR${NC}"

# Check Python version
echo -e "${BLUE}🐍 Checking Python version...${NC}"
if ! python3 --version | grep -E "Python 3\.([8-9]|1[0-9])" > /dev/null; then
    echo -e "${YELLOW}⚠️ Warning: Python 3.8+ recommended${NC}"
    python3 --version
else
    echo -e "${GREEN}✅ Python version OK${NC}"
    python3 --version
fi

# Check if git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️ Not a git repository${NC}"
    echo "Consider running: git init"
fi

# Create virtual environment
echo -e "${BLUE}📦 Setting up virtual environment...${NC}"
if [ -d "venv" ]; then
    echo -e "${YELLOW}⚠️ Virtual environment already exists${NC}"
    read -p "Recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf venv
        python3 -m venv venv
        echo -e "${GREEN}✅ Virtual environment recreated${NC}"
    fi
else
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${BLUE}🔌 Activating virtual environment...${NC}"
source venv/bin/activate

# Upgrade pip
echo -e "${BLUE}⬆️ Upgrading pip...${NC}"
pip install --upgrade pip

# Install backend requirements
echo -e "${BLUE}📥 Installing backend dependencies...${NC}"
cd backend
pip install -r requirements.txt
echo -e "${GREEN}✅ Backend dependencies installed${NC}"

# Install GUI requirements
echo -e "${BLUE}📥 Installing GUI dependencies...${NC}"
cd ../gui
pip install -r requirements.txt
echo -e "${GREEN}✅ GUI dependencies installed${NC}"

# Make scripts executable
echo -e "${BLUE}🔧 Making scripts executable...${NC}"
cd ..
chmod +x run_backend.sh run_gui.sh setup.sh

# Test imports
echo -e "${BLUE}🧪 Testing installation...${NC}"
cd backend
python -c "import fastapi, uvicorn, sqlalchemy, pyotp; print('✅ Backend imports OK')"
cd ../gui
python -c "import PyQt5, qrcode, requests; print('✅ GUI imports OK')"

# Database setup
echo -e "${BLUE}🗄️ Database setup...${NC}"
cd ../backend
if [ -f "alembic.ini" ]; then
    echo -e "${YELLOW}⚠️ Database migrations available${NC}"
    echo "To initialize database, run: alembic upgrade head"
fi

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=================================="
echo ""
echo -e "${PURPLE}🚀 Quick Start Commands:${NC}"
echo ""
echo -e "${BLUE}Start Backend:${NC}"
echo "  ./run_backend.sh"
echo ""
echo -e "${BLUE}Start GUI (in new terminal):${NC}"
echo "  ./run_gui.sh"
echo ""
echo -e "${BLUE}Manual activation:${NC}"
echo "  source venv/bin/activate"
echo ""
echo -e "${PURPLE}📚 Documentation:${NC}"
echo "  README.md - Main project documentation"
echo "  README_MFA.md - MFA setup guide"
echo "  QUICK_START_MFA.md - Quick MFA guide"
echo ""
echo -e "${GREEN}Happy coding! 🎊${NC}"
