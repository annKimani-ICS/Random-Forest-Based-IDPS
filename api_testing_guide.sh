#!/bin/bash
# API Testing and GUI Launch Guide
# This script shows you how to test the API and launch the GUI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🧪 API Testing and GUI Launch Guide${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. TESTING IF API IS RUNNING${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}Method 1: Health Check (Recommended)${NC}"
echo "curl http://localhost:8000/health"
echo ""
echo -e "${YELLOW}Expected response:${NC}"
echo '{"status": "healthy"}'

echo ""
echo -e "${GREEN}Method 2: Root Endpoint${NC}"
echo "curl http://localhost:8000/"
echo ""
echo -e "${YELLOW}Expected response:${NC}"
echo '{"message": "IDS/IDPS Admin API", "version": "1.0.0", "docs": "/docs"}'

echo ""
echo -e "${GREEN}Method 3: API Documentation${NC}"
echo "Open in browser: http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}Expected:${NC} Interactive API documentation page"

echo ""
echo -e "${GREEN}Method 4: Check if port is listening${NC}"
echo "netstat -tlnp | grep :8000"
echo ""
echo -e "${YELLOW}Expected:${NC} Shows port 8000 is listening"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. STARTING THE API${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}Option 1: Using Working Script (Recommended)${NC}"
echo "cd backend"
echo "./run_backend.sh"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo "  - Activate virtual environment"
echo "  - Install dependencies if needed"
echo "  - Start API on port 8000"
echo "  - Show startup messages"

echo ""
echo -e "${GREEN}Option 2: Manual Start${NC}"
echo "cd backend"
echo "source .venv/bin/activate"
echo "python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo "  - Start API directly"
echo "  - Enable auto-reload on changes"

echo ""
echo -e "${GREEN}Option 3: Systemd Service${NC}"
echo "sudo systemctl start ids-idps-backend"
echo "sudo systemctl status ids-idps-backend"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo "  - Start API as background service"
echo "  - Auto-start on boot"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. LAUNCHING THE GUI${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}Option 1: Using Working Script (Recommended)${NC}"
echo "cd gui"
echo "./run_gui.sh"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo "  - Check if backend is running"
echo "  - Activate virtual environment"
echo "  - Launch GUI application"

echo ""
echo -e "${GREEN}Option 2: Manual Launch${NC}"
echo "cd gui"
echo "source .venv/bin/activate"
echo "python main.py"
echo ""
echo -e "${YELLOW}This will:${NC}"
echo "  - Start GUI directly"
echo "  - Show login window"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. COMPLETE TESTING WORKFLOW${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}Step 1: Start API${NC}"
echo "cd backend && ./run_backend.sh"
echo ""
echo -e "${GREEN}Step 2: Test API (in new terminal)${NC}"
echo "curl http://localhost:8000/health"
echo ""
echo -e "${GREEN}Step 3: Launch GUI (in new terminal)${NC}"
echo "cd gui && ./run_gui.sh"
echo ""
echo -e "${GREEN}Step 4: Login to GUI${NC}"
echo "Use the credentials from the setup process"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. TROUBLESHOOTING${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${YELLOW}If API won't start:${NC}"
echo "  - Check if port 8000 is already in use: netstat -tlnp | grep :8000"
echo "  - Kill existing process: sudo kill -9 \$(lsof -t -i:8000)"
echo "  - Check virtual environment: source .venv/bin/activate"
echo "  - Check dependencies: pip list | grep fastapi"

echo ""
echo -e "${YELLOW}If GUI won't connect:${NC}"
echo "  - Check if API is running: curl http://localhost:8000/health"
echo "  - Check API client port: grep 'localhost:8000' gui/api_client.py"
echo "  - Check virtual environment: source .venv/bin/activate"
echo "  - Check PyQt5: python -c 'import PyQt5'"

echo ""
echo -e "${YELLOW}If you get 'no such file' errors:${NC}"
echo "  - Run: ./ultimate_working_solution.sh"
echo "  - This copies the exact working files from main branch"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. QUICK COMMANDS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}Test API:${NC}"
echo "curl http://localhost:8000/health"
echo ""
echo -e "${GREEN}Start API:${NC}"
echo "cd backend && ./run_backend.sh"
echo ""
echo -e "${GREEN}Start GUI:${NC}"
echo "cd gui && ./run_gui.sh"
echo ""
echo -e "${GREEN}Check API status:${NC}"
echo "netstat -tlnp | grep :8000"
echo ""
echo -e "${GREEN}View API docs:${NC}"
echo "Open http://localhost:8000/docs in browser"

echo ""
echo -e "${GREEN}🎯 Ready to test!${NC}"
