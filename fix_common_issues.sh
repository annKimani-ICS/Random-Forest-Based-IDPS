#!/bin/bash
# Automatic Troubleshooting and Fix Script for IDS/IDPS GUI
# Run this if you encounter problems after setup

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║       IDS/IDPS Automatic Troubleshooting Script          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXES_APPLIED=0

echo -e "${YELLOW}This script will attempt to automatically fix common issues.${NC}"
echo ""
read -p "Continue? [Y/n]: " CONTINUE
if [[ $CONTINUE =~ ^[Nn]$ ]]; then
    echo "Exiting."
    exit 0
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Diagnosing Issues...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Fix 1: PostgreSQL not running
echo -n "Checking PostgreSQL... "
if ! sudo systemctl is-active --quiet postgresql; then
    echo -e "${YELLOW}NOT RUNNING${NC}"
    echo "  → Starting PostgreSQL..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sleep 2
    if sudo systemctl is-active --quiet postgresql; then
        echo -e "  ${GREEN}✓ Fixed: PostgreSQL started${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "  ${RED}✗ Failed to start PostgreSQL${NC}"
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 2: Backend service not running
echo -n "Checking backend service... "
if ! sudo systemctl is-active --quiet ids-idps-backend; then
    echo -e "${YELLOW}NOT RUNNING${NC}"
    echo "  → Starting backend service..."
    sudo systemctl start ids-idps-backend
    sleep 3
    if sudo systemctl is-active --quiet ids-idps-backend; then
        echo -e "  ${GREEN}✓ Fixed: Backend service started${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "  ${RED}✗ Failed to start backend service${NC}"
        echo -e "  ${YELLOW}Checking logs...${NC}"
        sudo journalctl -u ids-idps-backend -n 20 --no-pager
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 3: Backend API not responding
echo -n "Checking backend API... "
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${YELLOW}NOT RESPONDING${NC}"
    echo "  → Restarting backend service..."
    sudo systemctl restart ids-idps-backend
    sleep 3
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Fixed: Backend API responding${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "  ${RED}✗ Backend API still not responding${NC}"
        echo -e "  ${YELLOW}Recent logs:${NC}"
        sudo journalctl -u ids-idps-backend -n 10 --no-pager
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 4: Time synchronization (critical for 2FA)
echo -n "Checking time synchronization... "
if ! timedatectl status | grep -q "synchronized: yes"; then
    echo -e "${YELLOW}NOT SYNCHRONIZED${NC}"
    echo "  → Enabling NTP time sync..."
    sudo timedatectl set-ntp true
    sudo systemctl restart systemd-timesyncd
    sleep 3
    if timedatectl status | grep -q "synchronized: yes"; then
        echo -e "  ${GREEN}✓ Fixed: Time synchronized${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "  ${YELLOW}⚠ Time sync enabled but not yet synchronized (may take a few minutes)${NC}"
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 5: DISPLAY variable for GUI
echo -n "Checking DISPLAY variable... "
if [ -z "$DISPLAY" ]; then
    echo -e "${YELLOW}NOT SET${NC}"
    echo "  → Setting DISPLAY=:0..."
    export DISPLAY=:0
    echo "export DISPLAY=:0" >> ~/.bashrc
    echo -e "  ${GREEN}✓ Fixed: DISPLAY variable set${NC}"
    echo -e "  ${YELLOW}Note: You may need to run 'export DISPLAY=:0' in your current terminal${NC}"
    ((FIXES_APPLIED++))
else
    echo -e "${GREEN}OK${NC} (${DISPLAY})"
fi

# Fix 6: Missing virtual environments
echo -n "Checking backend virtual environment... "
if [ ! -d "$SCRIPT_DIR/backend/.venv" ]; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "  → Creating backend virtual environment..."
    cd "$SCRIPT_DIR/backend"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
    echo -e "  ${GREEN}✓ Fixed: Backend venv created${NC}"
    ((FIXES_APPLIED++))
else
    echo -e "${GREEN}OK${NC}"
fi

echo -n "Checking GUI virtual environment... "
if [ ! -d "$SCRIPT_DIR/gui/.venv" ]; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "  → Creating GUI virtual environment..."
    cd "$SCRIPT_DIR/gui"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
    echo -e "  ${GREEN}✓ Fixed: GUI venv created${NC}"
    ((FIXES_APPLIED++))
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 7: PyQt5 issues
echo -n "Checking PyQt5... "
cd "$SCRIPT_DIR/gui"
if [ -d ".venv" ]; then
    source .venv/bin/activate
    if ! python3 -c "import PyQt5" 2>/dev/null; then
        echo -e "${YELLOW}IMPORT ERROR${NC}"
        echo "  → Reinstalling PyQt5..."
        pip install --force-reinstall PyQt5
        if python3 -c "import PyQt5" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Fixed: PyQt5 reinstalled${NC}"
            ((FIXES_APPLIED++))
        else
            echo -e "  ${RED}✗ PyQt5 still failing${NC}"
            echo "  → Installing system PyQt5..."
            sudo apt install -y python3-pyqt5 python3-pyqt5.qtsvg
        fi
    else
        echo -e "${GREEN}OK${NC}"
    fi
    deactivate
else
    echo -e "${YELLOW}VENV NOT FOUND${NC}"
fi

# Fix 8: File permissions
echo -n "Checking script permissions... "
PERMS_FIXED=0
for script in "$SCRIPT_DIR/setup_gui_complete.sh" "$SCRIPT_DIR/verify_setup.sh" "$SCRIPT_DIR/gui/run_gui.sh"; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        chmod +x "$script"
        ((PERMS_FIXED++))
    fi
done

if [ $PERMS_FIXED -gt 0 ]; then
    echo -e "${GREEN}OK${NC} (${PERMS_FIXED} scripts made executable)"
    ((FIXES_APPLIED++))
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 9: .env file
echo -n "Checking .env file... "
if [ ! -f "$SCRIPT_DIR/backend/.env" ]; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo -e "  ${RED}✗ .env file missing - you need to run setup_gui_complete.sh${NC}"
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 10: Database seeding
echo -n "Checking database data... "
if [ -d "$SCRIPT_DIR/backend/.venv" ]; then
    cd "$SCRIPT_DIR/backend"
    source .venv/bin/activate
    USER_COUNT=$(python3 -c "
from app.database import SessionLocal
from app.models import User
try:
    db = SessionLocal()
    count = db.query(User).count()
    print(count)
except Exception as e:
    print(0)
finally:
    db.close()
" 2>/dev/null)
    
    if [ "$USER_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}NO DATA${NC}"
        echo "  → Seeding database..."
        python3 seed_data.py
        echo -e "  ${GREEN}✓ Fixed: Database seeded${NC}"
        echo -e "  ${YELLOW}⚠ New credentials generated - check output above${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "${GREEN}OK${NC} (${USER_COUNT} users)"
    fi
    deactivate
    cd "$SCRIPT_DIR"
else
    echo -e "${YELLOW}CANNOT CHECK${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ $FIXES_APPLIED -eq 0 ]; then
    echo -e "${GREEN}✓ No issues found! Everything looks good.${NC}"
    echo ""
    echo -e "${BLUE}You can launch the GUI:${NC}"
    echo -e "  cd $SCRIPT_DIR/gui && ./run_gui.sh"
else
    echo -e "${GREEN}✓ Applied $FIXES_APPLIED fix(es)${NC}"
    echo ""
    echo -e "${YELLOW}Recommended next steps:${NC}"
    echo ""
    echo "1. Run verification script:"
    echo -e "   ${BLUE}./verify_setup.sh${NC}"
    echo ""
    echo "2. If verification passes, launch GUI:"
    echo -e "   ${BLUE}cd gui && ./run_gui.sh${NC}"
    echo ""
    echo "3. If issues persist, check logs:"
    echo -e "   ${BLUE}sudo journalctl -u ids-idps-backend -n 50${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Quick Status Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Final status check
echo -e "PostgreSQL:       $(sudo systemctl is-active postgresql || echo 'inactive')"
echo -e "Backend Service:  $(sudo systemctl is-active ids-idps-backend || echo 'inactive')"
echo -n "Backend API:      "
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}responding${NC}"
else
    echo -e "${RED}not responding${NC}"
fi
echo -e "Time Sync:        $(timedatectl status | grep 'synchronized:' | awk '{print $3}')"
echo -e "DISPLAY:          ${DISPLAY:-not set}"

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""

