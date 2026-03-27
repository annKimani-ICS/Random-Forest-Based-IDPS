#!/bin/bash
# Backend startup script with automatic virtual environment activation
# Usage: ./run_backend.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting IDS/IDPS Backend Server${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/backend/app/main.py" ]; then
    echo -e "${RED}❌ Error: backend/app/main.py not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Use backend-local virtual environment
BACKEND_DIR="$PROJECT_DIR/backend"
VENV_DIR="$BACKEND_DIR/.venv"
PORT="${PORT:-3000}"

# Create venv if missing
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}⚠️ Virtual environment not found in backend. Creating one at $VENV_DIR...${NC}"
    python3 -m venv "$VENV_DIR"
    echo -e "${GREEN}✅ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${BLUE}🔌 Activating virtual environment...${NC}"
source "$VENV_DIR/bin/activate"

# Check and install dependencies
echo -e "${BLUE}📦 Checking dependencies...${NC}"
cd "$BACKEND_DIR"

if ! python -c "import fastapi, uvicorn" 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Dependencies not found. Upgrading pip and installing...${NC}"
    python -m pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
    echo -e "${GREEN}✅ Dependencies installed${NC}"
fi

# Start the backend server
echo -e "${GREEN}🌟 Starting FastAPI backend server...${NC}"
echo "Server will be available at: http://localhost:$PORT"
echo "API documentation: http://localhost:$PORT/docs"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo "=================================="

# Start uvicorn with proper configuration (default port 3000, override with PORT env)
uvicorn app.main:app --reload --host 0.0.0.0 --port "$PORT"
