#!/bin/bash
# Quick Verification Script for IDS/IDPS GUI Setup
# Run this after setup to verify everything is working

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
║          IDS/IDPS Setup Verification Script              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSED=0
FAILED=0
WARNINGS=0

# Helper function
check() {
    echo -n "  $1... "
}

pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}"
    if [ -n "$1" ]; then
        echo -e "${YELLOW}    → $1${NC}"
    fi
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠ WARNING${NC}"
    if [ -n "$1" ]; then
        echo -e "${YELLOW}    → $1${NC}"
    fi
    ((WARNINGS++))
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. System Dependencies${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "Python 3"
if command -v python3 &> /dev/null; then
    VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓ PASS${NC} (${VERSION})"
    ((PASSED++))
else
    fail "Python 3 not found"
fi

check "PostgreSQL"
if command -v psql &> /dev/null; then
    VERSION=$(psql --version | cut -d' ' -f3)
    echo -e "${GREEN}✓ PASS${NC} (${VERSION})"
    ((PASSED++))
else
    fail "PostgreSQL not installed"
fi

check "PyQt5 system package"
if dpkg -l | grep -q python3-pyqt5; then
    pass
else
    warn "python3-pyqt5 not installed (may still work with pip version)"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. Project Structure${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "Backend directory"
if [ -d "$SCRIPT_DIR/backend" ]; then
    pass
else
    fail "backend/ directory not found"
fi

check "GUI directory"
if [ -d "$SCRIPT_DIR/gui" ]; then
    pass
else
    fail "gui/ directory not found"
fi

check "Models directory"
if [ -d "$SCRIPT_DIR/models" ]; then
    pass
else
    warn "models/ directory not found"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. Backend Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "Backend virtual environment"
if [ -d "$SCRIPT_DIR/backend/.venv" ]; then
    pass
else
    fail "Run setup_gui_complete.sh first"
fi

check "Backend .env file"
if [ -f "$SCRIPT_DIR/backend/.env" ]; then
    pass
else
    fail ".env file not created"
fi

check "Backend dependencies"
if [ -d "$SCRIPT_DIR/backend/.venv" ]; then
    source "$SCRIPT_DIR/backend/.venv/bin/activate"
    if python3 -c "import fastapi, sqlalchemy, uvicorn" 2>/dev/null; then
        pass
    else
        fail "Backend dependencies not installed"
    fi
    deactivate 2>/dev/null || true
else
    fail "Virtual environment not found"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. Database${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "PostgreSQL service"
if sudo systemctl is-active --quiet postgresql; then
    pass
else
    fail "PostgreSQL not running. Run: sudo systemctl start postgresql"
fi

check "Database exists"
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw ids_idps_db; then
    pass
else
    fail "Database 'ids_idps_db' not found"
fi

check "Database connection"
if [ -f "$SCRIPT_DIR/backend/.env" ]; then
    source "$SCRIPT_DIR/backend/.env"
    DB_USER=$(echo $DATABASE_URL | sed -n 's/.*\/\/\(.*\):.*/\1/p')
    DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\(.*\)/\1/p')
    
    if PGPASSWORD="${DATABASE_URL#*:}" psql -U ${DB_USER:-ids_user} -d ${DB_NAME:-ids_idps_db} -h localhost -c "SELECT 1" &>/dev/null 2>&1; then
        pass
    else
        # Try default credentials
        if PGPASSWORD="[DEFAULT_PASSWORD]" psql -U ids_user -d ids_idps_db -h localhost -c "SELECT 1" &>/dev/null 2>&1; then
            pass
        else
            fail "Cannot connect to database"
        fi
    fi
else
    fail ".env file not found"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. Backend Service${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "Systemd service exists"
if [ -f /etc/systemd/system/ids-idps-backend.service ]; then
    pass
else
    fail "Systemd service not created"
fi

check "Backend service status"
if sudo systemctl is-active --quiet ids-idps-backend; then
    pass
else
    fail "Backend service not running. Run: sudo systemctl start ids-idps-backend"
fi

check "Backend service enabled"
if sudo systemctl is-enabled --quiet ids-idps-backend; then
    pass
else
    warn "Service not enabled for auto-start. Run: sudo systemctl enable ids-idps-backend"
fi

check "Backend API health"
sleep 1  # Give API a moment
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    pass
else
    fail "API not responding. Check: sudo journalctl -u ids-idps-backend -n 20"
fi

check "Backend API docs accessible"
if curl -s http://localhost:8000/docs | grep -q "FastAPI"; then
    pass
else
    warn "API docs not accessible (may be normal)"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. GUI Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "GUI virtual environment"
if [ -d "$SCRIPT_DIR/gui/.venv" ]; then
    pass
else
    fail "Run setup_gui_complete.sh first"
fi

check "GUI dependencies"
if [ -d "$SCRIPT_DIR/gui/.venv" ]; then
    source "$SCRIPT_DIR/gui/.venv/bin/activate"
    if python3 -c "import PyQt5" 2>/dev/null; then
        pass
    else
        fail "PyQt5 not installed in GUI venv"
    fi
    deactivate 2>/dev/null || true
else
    fail "Virtual environment not found"
fi

check "GUI run script"
if [ -x "$SCRIPT_DIR/gui/run_gui.sh" ]; then
    pass
else
    if [ -f "$SCRIPT_DIR/gui/run_gui.sh" ]; then
        warn "run_gui.sh not executable. Run: chmod +x $SCRIPT_DIR/gui/run_gui.sh"
    else
        fail "run_gui.sh not found"
    fi
fi

check "Desktop launcher"
if [ -f "$HOME/.local/share/applications/ids-idps.desktop" ]; then
    pass
else
    warn "Desktop launcher not created (optional)"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}7. System Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "Time synchronization"
if timedatectl status | grep -q "synchronized: yes"; then
    pass
else
    warn "Time not synchronized (critical for 2FA). Run: sudo timedatectl set-ntp true"
fi

check "DISPLAY variable"
if [ -n "$DISPLAY" ]; then
    echo -e "${GREEN}✓ PASS${NC} (${DISPLAY})"
    ((PASSED++))
else
    warn "DISPLAY not set. For GUI, run: export DISPLAY=:0"
fi

check "Firewall status"
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "8000"; then
        pass
    else
        warn "Port 8000 not in firewall (may be okay)"
    fi
else
    warn "UFW not installed (may use different firewall)"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}8. Credentials & Security${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "Credentials file"
if [ -f "$HOME/ids_idps_credentials.txt" ]; then
    pass
else
    warn "Credentials file not found (check ~/ids_idps_credentials.txt)"
fi

check ".env file permissions"
if [ -f "$SCRIPT_DIR/backend/.env" ]; then
    PERMS=$(stat -c "%a" "$SCRIPT_DIR/backend/.env")
    if [ "$PERMS" = "600" ] || [ "$PERMS" = "644" ]; then
        pass
    else
        warn "Consider restricting .env permissions: chmod 600 $SCRIPT_DIR/backend/.env"
    fi
else
    fail ".env file not found"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}9. Additional Checks${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check "Backend logs available"
if sudo journalctl -u ids-idps-backend -n 1 &>/dev/null; then
    pass
else
    warn "Cannot read backend logs (may need sudo)"
fi

check "Port 8000 listening"
if sudo lsof -i :8000 &>/dev/null || netstat -tuln 2>/dev/null | grep -q ":8000"; then
    pass
else
    fail "Nothing listening on port 8000"
fi

check "Database has data"
if [ -d "$SCRIPT_DIR/backend/.venv" ]; then
    source "$SCRIPT_DIR/backend/.venv/bin/activate"
    cd "$SCRIPT_DIR/backend"
    COUNT=$(python3 -c "
from app.database import SessionLocal
from app.models import User
db = SessionLocal()
try:
    count = db.query(User).count()
    print(count)
except:
    print(0)
finally:
    db.close()
" 2>/dev/null)
    
    if [ "$COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC} (${COUNT} users found)"
        ((PASSED++))
    else
        fail "No users in database. Run: python3 backend/seed_data.py"
    fi
    deactivate 2>/dev/null || true
    cd "$SCRIPT_DIR"
else
    fail "Cannot check database"
fi

# Summary
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    VERIFICATION SUMMARY                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

TOTAL=$((PASSED + FAILED + WARNINGS))
echo -e "  ${GREEN}✓ Passed:   $PASSED${NC}"
echo -e "  ${RED}✗ Failed:   $FAILED${NC}"
echo -e "  ${YELLOW}⚠ Warnings: $WARNINGS${NC}"
echo -e "  ─────────────────"
echo -e "  Total:      $TOTAL"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║          ✅ SETUP VERIFICATION SUCCESSFUL! ✅             ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}🚀 You're ready to launch the GUI!${NC}"
    echo ""
    echo -e "${GREEN}Launch command:${NC}"
    echo -e "  cd $SCRIPT_DIR/gui && ./run_gui.sh"
    echo ""
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: There are $WARNINGS warning(s) above. Review them if you encounter issues.${NC}"
        echo ""
    fi
    
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                           ║${NC}"
    echo -e "${RED}║            ❌ SETUP VERIFICATION FAILED ❌                ║${NC}"
    echo -e "${RED}║                                                           ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Please fix the failed checks above before launching the GUI.${NC}"
    echo ""
    echo -e "${BLUE}Common fixes:${NC}"
    echo -e "  • Run setup script:  ./setup_gui_complete.sh"
    echo -e "  • Start backend:     sudo systemctl start ids-idps-backend"
    echo -e "  • Check logs:        sudo journalctl -u ids-idps-backend -n 50"
    echo -e "  • Seed database:     cd backend && source .venv/bin/activate && python3 seed_data.py"
    echo ""
    
    exit 1
fi

