#!/bin/bash
# GUI startup script with automatic virtual environment activation
# Usage: ./run_gui.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🖥️ Starting IDS/IDPS Desktop GUI${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/gui/main.py" ]; then
    echo -e "${RED}❌ Error: gui/main.py not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "$PROJECT_DIR/venv" ]; then
    echo -e "${YELLOW}⚠️ Virtual environment not found. Creating one...${NC}"
    python3 -m venv "$PROJECT_DIR/venv"
    echo -e "${GREEN}✅ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${BLUE}🔌 Activating virtual environment...${NC}"
source "$PROJECT_DIR/venv/bin/activate"

# Check if requirements are installed
echo -e "${BLUE}📦 Checking GUI dependencies...${NC}"
cd "$PROJECT_DIR/gui"

if ! python -c "import PyQt5" 2>/dev/null; then
    echo -e "${YELLOW}⚠️ GUI dependencies not installed. Installing...${NC}"
    pip install -r requirements.txt
    echo -e "${GREEN}✅ GUI dependencies installed${NC}"
fi

# Check if backend is running
echo -e "${BLUE}🔍 Checking backend connection...${NC}"
if ! curl -s http://localhost:8000/docs > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ Backend server not detected at http://localhost:8000${NC}"
    echo -e "${YELLOW}Please start the backend first: ./run_backend.sh${NC}"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Exiting. Start backend first with: ./run_backend.sh${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Backend server detected${NC}"
fi

# Start the GUI
echo -e "${GREEN}🌟 Starting PyQt5 GUI application...${NC}"
echo "=================================="

python main.py
