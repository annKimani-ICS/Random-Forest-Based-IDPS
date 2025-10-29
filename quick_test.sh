#!/bin/bash
# Quick API Test and GUI Launch Script
# Simple commands to test API and launch GUI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Quick API Test and GUI Launch${NC}"
echo "=================================="

# Function to test API
test_api() {
    echo -e "${YELLOW}Testing API...${NC}"
    
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API is running!${NC}"
        echo -e "${BLUE}Response:${NC}"
        curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8000/health
        return 0
    else
        echo -e "${RED}❌ API is not running${NC}"
        return 1
    fi
}

# Function to start API
start_api() {
    echo -e "${YELLOW}Starting API...${NC}"
    
    if [ -f "backend/run_backend.sh" ]; then
        echo -e "${BLUE}Using working script...${NC}"
        cd backend
        ./run_backend.sh &
        API_PID=$!
        cd ..
        
        # Wait a moment for API to start
        sleep 3
        
        if test_api; then
            echo -e "${GREEN}✅ API started successfully!${NC}"
            echo -e "${YELLOW}API PID: $API_PID${NC}"
            echo -e "${YELLOW}To stop API: kill $API_PID${NC}"
        else
            echo -e "${RED}❌ API failed to start${NC}"
        fi
    else
        echo -e "${RED}❌ run_backend.sh not found${NC}"
        echo -e "${YELLOW}Run: ./ultimate_working_solution.sh first${NC}"
    fi
}

# Function to launch GUI
launch_gui() {
    echo -e "${YELLOW}Launching GUI...${NC}"
    
    if [ -f "gui/run_gui.sh" ]; then
        echo -e "${BLUE}Using working script...${NC}"
        cd gui
        ./run_gui.sh
    else
        echo -e "${RED}❌ run_gui.sh not found${NC}"
        echo -e "${YELLOW}Run: ./ultimate_working_solution.sh first${NC}"
    fi
}

# Main menu
echo ""
echo -e "${BLUE}Choose an option:${NC}"
echo "1. Test if API is running"
echo "2. Start API"
echo "3. Launch GUI"
echo "4. Start API and Launch GUI"
echo "5. Show API status"
echo "6. Exit"

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        test_api
        ;;
    2)
        start_api
        ;;
    3)
        if test_api; then
            launch_gui
        else
            echo -e "${RED}❌ API is not running. Start API first.${NC}"
        fi
        ;;
    4)
        start_api
        if test_api; then
            echo -e "${YELLOW}Waiting 2 seconds for API to fully start...${NC}"
            sleep 2
            launch_gui
        fi
        ;;
    5)
        echo -e "${BLUE}API Status:${NC}"
        if test_api; then
            echo -e "${GREEN}✅ API is healthy and running${NC}"
            echo -e "${BLUE}Port 8000 status:${NC}"
            netstat -tlnp | grep :8000 || echo "Port 8000 not listening"
        else
            echo -e "${RED}❌ API is not running${NC}"
        fi
        ;;
    6)
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎯 Done!${NC}"

