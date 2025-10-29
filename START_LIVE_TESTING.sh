#!/bin/bash
# Quick start guide for live traffic testing
# Run this on your Ubuntu VM to set up and test live traffic detection

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Live Traffic Testing Setup${NC}"
echo "=================================="

# Step 1: Verify backend is running
echo -e "\n${YELLOW}Step 1: Verifying backend is running...${NC}"
if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend is not running!${NC}"
    echo "   Start with: sudo systemctl start ids-idps-backend"
    exit 1
fi

# Step 2: Get authentication token
echo -e "\n${YELLOW}Step 2: Authenticating...${NC}"
echo -e "${BLUE}Enter admin email (default: admin@ids.local):${NC} "
read -r EMAIL
EMAIL=${EMAIL:-admin@ids.local}

echo -e "${BLUE}Enter admin password:${NC} "
read -rs PASSWORD

TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}" \
  | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

if [ -z "$TOKEN" ] || [ "$TOKEN" == "None" ]; then
    echo -e "${RED}❌ Authentication failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authentication successful${NC}"

# Step 3: Find network interface
echo -e "\n${YELLOW}Step 3: Finding network interface...${NC}"
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$INTERFACE" ]; then
    INTERFACE="eth0"
fi
echo -e "${GREEN}✅ Using interface: $INTERFACE${NC}"

# Step 4: Get current IP address
echo -e "\n${YELLOW}Step 4: Getting your IP address...${NC}"
VM_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}✅ Your VM IP: $VM_IP${NC}"
echo -e "${BLUE}   Use this IP as TARGET_IP in your Kali VM${NC}"

# Step 5: Check monitoring status
echo -e "\n${YELLOW}Step 5: Checking monitoring status...${NC}"
STATUS=$(curl -s http://localhost:8000/api/monitor/status \
  -H "Authorization: Bearer $TOKEN")

IS_MONITORING=$(echo "$STATUS" | python3 -c "import sys, json; print(json.load(sys.stdin).get('is_monitoring', False))" 2>/dev/null || echo "false")

if [ "$IS_MONITORING" = "True" ] || [ "$IS_MONITORING" = "true" ]; then
    echo -e "${GREEN}✅ Monitoring is already active${NC}"
else
    echo -e "${YELLOW}⚠️  Monitoring is not active${NC}"
    echo -e "${BLUE}Starting monitoring...${NC}"
    
    RESPONSE=$(curl -s -X POST http://localhost:8000/api/monitor/start \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"interface\": \"$INTERFACE\", \"threshold\": 0.50}")
    
    if echo "$RESPONSE" | grep -q "message"; then
        echo -e "${GREEN}✅ Monitoring started successfully${NC}"
    else
        echo -e "${RED}❌ Failed to start monitoring${NC}"
        echo "Response: $RESPONSE"
        exit 1
    fi
fi

# Step 6: Display testing instructions
echo ""
echo -e "${GREEN}🎉 Setup Complete! Ready for Testing${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}Testing Instructions:${NC}"
echo ""
echo "1. ${YELLOW}On Kali Linux VM:${NC}"
echo "   sudo apt-get install hping3"
echo ""
echo "2. ${YELLOW}Launch DDoS Attack:${NC}"
echo "   sudo hping3 -S --flood -V -p 80 $VM_IP"
echo ""
echo "   Other attacks to try:"
echo "   # UDP flood"
echo "   sudo hping3 --udp --flood -V -p 53 $VM_IP"
echo ""
echo "   # ICMP flood"
echo "   sudo hping3 --icmp --flood -V $VM_IP"
echo ""
echo "3. ${YELLOW}Watch for Alerts:${NC}"
echo "   - Open GUI application"
echo "   - Login as admin"
echo "   - Dashboard should show alerts appearing in real-time"
echo "   - Alert count should increase"
echo ""
echo "4. ${YELLOW}Or check via API:${NC}"
echo "   curl \"http://localhost:8000/api/alerts?page=1&page_size=10\" \\"
echo "     -H \"Authorization: Bearer $TOKEN\" | jq"
echo ""
echo -e "${BLUE}Current Monitoring Status:${NC}"
curl -s http://localhost:8000/api/monitor/status \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool 2>/dev/null || echo "$STATUS"
echo ""
echo -e "${GREEN}✅ Ready to test! Start your attack from Kali VM.${NC}"

