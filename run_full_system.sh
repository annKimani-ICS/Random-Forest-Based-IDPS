#!/bin/bash
# Full system startup script - starts both backend and GUI
# Usage: ./run_full_system.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 Starting Full IDS/IDPS System${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Check if virtual environment exists
if [ ! -d "$PROJECT_DIR/venv" ]; then
    echo -e "${YELLOW}⚠️ Virtual environment not found. Run ./setup.sh first${NC}"
    exit 1
fi

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down...${NC}"
    # Kill background jobs
    jobs -p | xargs -r kill 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start backend in background
echo -e "${BLUE}🔧 Starting backend server...${NC}"
source "$PROJECT_DIR/venv/bin/activate"
cd "$PROJECT_DIR/backend"

# Start backend in background
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Wait for backend to start
echo -e "${YELLOW}⏳ Waiting for backend to start...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:8000/docs > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend started successfully${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Backend failed to start${NC}"
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

# Start GUI
echo -e "${BLUE}🖥️ Starting GUI application...${NC}"
cd "$PROJECT_DIR/gui"
python main.py &
GUI_PID=$!

echo ""
echo -e "${GREEN}🎉 Full system started!${NC}"
echo "=================================="
echo -e "${BLUE}Backend:${NC} http://localhost:8000"
echo -e "${BLUE}API Docs:${NC} http://localhost:8000/docs"
echo -e "${BLUE}GUI:${NC} Desktop application"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop both services${NC}"

# Wait for GUI process
wait $GUI_PID
