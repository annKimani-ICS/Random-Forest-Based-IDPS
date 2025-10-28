#!/bin/bash
# Check and Fix Credentials File
# This script checks the credentials file and fixes any issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Check and Fix Credentials File${NC}"
echo "=================================="

# Check if credentials file exists
CREDENTIALS_FILE="$HOME/ids_idps_credentials.txt"

if [ -f "$CREDENTIALS_FILE" ]; then
    echo -e "${GREEN}✅ Credentials file found: $CREDENTIALS_FILE${NC}"
    echo ""
    echo -e "${BLUE}Current contents:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$CREDENTIALS_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo -e "${RED}❌ Credentials file not found: $CREDENTIALS_FILE${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 Common Issues and Solutions:${NC}"
echo ""
echo -e "${BLUE}Issue 1: Empty or corrupted credentials file${NC}"
echo "Solution: Run ./fix_login_credentials.sh"
echo ""
echo -e "${BLUE}Issue 2: Database not seeded properly${NC}"
echo "Solution: Run ./fix_login_credentials.sh"
echo ""
echo -e "${BLUE}Issue 3: Wrong password${NC}"
echo "Solution: Try these default passwords:"
echo "  - admin@ids-idps.com: admin123"
echo "  - analyst@ids-idps.com: analyst123"
echo "  - user@ids-idps.com: user123"
echo ""
echo -e "${BLUE}Issue 4: API not running${NC}"
echo "Solution: Start API first with: cd backend && ./run_backend.sh"
echo ""

# Check if API is running
echo -e "${YELLOW}🔍 Checking if API is running...${NC}"
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API is running${NC}"
else
    echo -e "${RED}❌ API is not running${NC}"
    echo -e "${YELLOW}Start API first: cd backend && ./run_backend.sh${NC}"
fi

echo ""
echo -e "${GREEN}🎯 Quick Fix Commands:${NC}"
echo ""
echo -e "${BLUE}Fix credentials:${NC}"
echo "  ./fix_login_credentials.sh"
echo ""
echo -e "${BLUE}Start API:${NC}"
echo "  cd backend && ./run_backend.sh"
echo ""
echo -e "${BLUE}Start GUI:${NC}"
echo "  cd gui && ./run_gui.sh"
echo ""
echo -e "${BLUE}Test API:${NC}"
echo "  curl http://localhost:8000/health"
echo ""

# Offer to run the fix
echo -e "${YELLOW}Would you like to run the credentials fix now? (y/N)${NC}"
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}🚀 Running credentials fix...${NC}"
    ./fix_login_credentials.sh
else
    echo -e "${BLUE}You can run it later with: ./fix_login_credentials.sh${NC}"
fi
