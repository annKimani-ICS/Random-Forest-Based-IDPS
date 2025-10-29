#!/bin/bash
# Fix "Address already in use" error on port 8000
# This script finds and kills processes using port 8000

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing Port 8000 'Address Already in Use' Error${NC}"
echo "=================================="

# Method 1: Check if systemd service is running
echo -e "\n${YELLOW}Step 1: Checking systemd service...${NC}"
if systemctl is-active --quiet ids-idps-backend 2>/dev/null; then
    echo -e "${GREEN}✅ ids-idps-backend service is running${NC}"
    echo -e "${YELLOW}Stopping service...${NC}"
    sudo systemctl stop ids-idps-backend
    sleep 2
    echo -e "${GREEN}✅ Service stopped${NC}"
else
    echo -e "${YELLOW}⚠️  ids-idps-backend service is not running${NC}"
fi

# Method 2: Find processes using port 8000
echo -e "\n${YELLOW}Step 2: Checking for processes using port 8000...${NC}"

# Try lsof first
if command -v lsof &> /dev/null; then
    PIDS=$(sudo lsof -ti :8000 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
        echo -e "${RED}Found processes using port 8000:${NC}"
        sudo lsof -i :8000
        echo -e "${YELLOW}Killing processes...${NC}"
        echo "$PIDS" | xargs sudo kill -9 2>/dev/null || true
        sleep 1
        echo -e "${GREEN}✅ Processes killed${NC}"
    else
        echo -e "${GREEN}✅ No processes found using port 8000${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  lsof not available, trying alternative method...${NC}"
    
    # Alternative: Use fuser
    if command -v fuser &> /dev/null; then
        if sudo fuser 8000/tcp &> /dev/null; then
            echo -e "${YELLOW}Killing processes using fuser...${NC}"
            sudo fuser -k 8000/tcp 2>/dev/null || true
            sleep 1
            echo -e "${GREEN}✅ Processes killed${NC}"
        else
            echo -e "${GREEN}✅ No processes found using port 8000${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  fuser not available, trying pkill...${NC}"
    fi
fi

# Method 3: Kill all uvicorn processes
echo -e "\n${YELLOW}Step 3: Checking for uvicorn processes...${NC}"
UVICORN_PIDS=$(pgrep -f "uvicorn.*8000" 2>/dev/null || true)
if [ -n "$UVICORN_PIDS" ]; then
    echo -e "${RED}Found uvicorn processes:${NC}"
    ps aux | grep "[u]vicorn"
    echo -e "${YELLOW}Killing uvicorn processes...${NC}"
    sudo pkill -9 -f "uvicorn.*8000" 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}✅ Uvicorn processes killed${NC}"
else
    echo -e "${GREEN}✅ No uvicorn processes found${NC}"
fi

# Method 4: Kill all python processes running app.main (be careful!)
echo -e "\n${YELLOW}Step 4: Checking for Python backend processes...${NC}"
PYTHON_PIDS=$(pgrep -f "python.*app.main" 2>/dev/null || true)
if [ -n "$PYTHON_PIDS" ]; then
    echo -e "${RED}Found Python backend processes:${NC}"
    ps aux | grep "[p]ython.*app.main"
    echo -e "${YELLOW}Killing Python backend processes...${NC}"
    sudo pkill -9 -f "python.*app.main" 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}✅ Python backend processes killed${NC}"
else
    echo -e "${GREEN}✅ No Python backend processes found${NC}"
fi

# Verify port is free
echo -e "\n${YELLOW}Step 5: Verifying port 8000 is free...${NC}"
sleep 2

if command -v lsof &> /dev/null; then
    if sudo lsof -i :8000 &> /dev/null; then
        echo -e "${RED}❌ Port 8000 is still in use:${NC}"
        sudo lsof -i :8000
        echo -e "${YELLOW}⚠️  You may need to manually kill the process${NC}"
    else
        echo -e "${GREEN}✅ Port 8000 is now free${NC}"
    fi
elif command -v netstat &> /dev/null; then
    if sudo netstat -tlnp | grep -q ":8000"; then
        echo -e "${RED}❌ Port 8000 is still in use:${NC}"
        sudo netstat -tlnp | grep ":8000"
    else
        echo -e "${GREEN}✅ Port 8000 is now free${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Cannot verify (lsof/netstat not available)${NC}"
    echo -e "${YELLOW}   Try starting the backend and see if it works${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Port 8000 Cleanup Complete!${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Choose ONE method to start backend:"
echo ""
echo -e "${GREEN}Option A: Start via systemd service (recommended)${NC}"
echo "   sudo systemctl start ids-idps-backend"
echo "   sudo systemctl status ids-idps-backend"
echo ""
echo -e "${GREEN}Option B: Start manually${NC}"
echo "   cd backend"
echo "   source .venv/bin/activate"
echo "   python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
echo ""
echo -e "${YELLOW}⚠️  Do NOT use both methods at the same time!${NC}"

