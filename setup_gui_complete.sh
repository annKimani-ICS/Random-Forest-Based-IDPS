#!/bin/bash
# Complete IDS/IDPS GUI Setup Script for Ubuntu VM
# This script sets up the entire system: Backend API + Desktop GUI
# Fixes path issues and ensures everything works correctly

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        IDS/IDPS System - Complete Ubuntu Setup           ║
║     Backend API + Desktop GUI Application Setup          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}❌ ERROR: Please do not run as root!${NC}"
   echo -e "${YELLOW}   Run as a regular user with sudo privileges.${NC}"
   exit 1
fi

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}📁 Project Directory: ${PROJECT_DIR}${NC}"
echo -e "${BLUE}👤 Current User: $(whoami)${NC}"
echo ""

# Verify we're in the right directory
if [ ! -d "$PROJECT_DIR/backend" ] || [ ! -d "$PROJECT_DIR/gui" ]; then
    echo -e "${RED}❌ ERROR: Cannot find backend/ and gui/ directories!${NC}"
    echo -e "${YELLOW}   Please run this script from the project root directory.${NC}"
    exit 1
fi

# Database configuration
DB_NAME="ids_idps_db"
DB_USER="ids_user"
DB_PASSWORD="[DEFAULT_DB_PASSWORD]"

# Prompt for custom database password (optional)
read -p "$(echo -e ${YELLOW}Use default database password? [Y/n]: ${NC})" USE_DEFAULT_DB_PASS
if [[ $USE_DEFAULT_DB_PASS =~ ^[Nn]$ ]]; then
    read -sp "$(echo -e ${YELLOW}Enter database password: ${NC})" DB_PASSWORD
    echo ""
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[1/11] Updating system packages...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
sudo apt update
sudo apt upgrade -y

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[2/11] Installing system dependencies...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    python3-pip \
    python3-venv \
    python3-dev \
    postgresql \
    postgresql-contrib \
    python3-pyqt5 \
    python3-pyqt5.qtsvg \
    libpq-dev \
    build-essential \
    git \
    curl \
    wget \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    libxcb-xinerama0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xfixes0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libxkbcommon-dev \
    dbus-x11

echo -e "${GREEN}✓ System dependencies installed${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[3/11] Configuring time synchronization (Critical for 2FA)...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd 2>/dev/null || true
sleep 2
echo -e "${BLUE}Current system time: $(date)${NC}"
timedatectl status | grep "synchronized" || echo -e "${YELLOW}⚠️  Time may not be fully synchronized yet${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[4/11] Setting up PostgreSQL database...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Wait for PostgreSQL to be ready
sleep 3

# Create database and user
sudo -u postgres psql <<EOF
-- Drop existing if present
DROP DATABASE IF EXISTS ${DB_NAME};
DROP USER IF EXISTS ${DB_USER};

-- Create fresh
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
ALTER USER ${DB_USER} CREATEDB;

-- Connect to database and grant schema privileges
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
ALTER SCHEMA public OWNER TO ${DB_USER};
EOF

echo -e "${GREEN}✓ Database '${DB_NAME}' created successfully${NC}"

# Test database connection
if PGPASSWORD="${DB_PASSWORD}" psql -U ${DB_USER} -d ${DB_NAME} -h localhost -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection test successful${NC}"
else
    echo -e "${RED}❌ Database connection test failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[5/11] Setting up backend Python environment...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

BACKEND_DIR="$PROJECT_DIR/backend"
cd "$BACKEND_DIR"

# Remove old venv if exists
if [ -d ".venv" ]; then
    echo -e "${YELLOW}Removing old virtual environment...${NC}"
    rm -rf .venv
fi

# Create new virtual environment
python3 -m venv .venv
source .venv/bin/activate

echo -e "${GREEN}✓ Virtual environment created${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[6/11] Installing backend Python dependencies...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "${GREEN}✓ Backend dependencies installed${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[7/11] Configuring backend environment (.env)...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

# Generate secure JWT secret
JWT_SECRET=$(openssl rand -hex 32)

# Create .env file
cat > .env <<EOF
DATABASE_URL=postgresql+psycopg2://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}
JWT_SECRET=${JWT_SECRET}
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:5173,http://localhost:8000
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
EOF

echo -e "${GREEN}✓ .env file created with secure JWT secret${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[8/11] Initializing database and seeding data...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

# Run seed script and capture credentials
CREDENTIALS_FILE="$HOME/ids_idps_credentials.txt"
echo "IDS/IDPS Login Credentials" > "$CREDENTIALS_FILE"
echo "Generated on: $(date)" >> "$CREDENTIALS_FILE"
echo "================================" >> "$CREDENTIALS_FILE"
echo "" >> "$CREDENTIALS_FILE"

# Run seeding
python3 seed_data.py 2>&1 | tee -a "$CREDENTIALS_FILE"

echo ""
echo -e "${GREEN}✓ Database seeded successfully${NC}"
echo -e "${YELLOW}📝 Credentials saved to: ${CREDENTIALS_FILE}${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[9/11] Creating backend systemd service...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

# Stop existing service if running
sudo systemctl stop ids-idps-backend 2>/dev/null || true

# Create systemd service file
sudo tee /etc/systemd/system/ids-idps-backend.service > /dev/null <<EOF
[Unit]
Description=IDS/IDPS Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=$(whoami)
Group=$(id -gn)
WorkingDirectory=${BACKEND_DIR}
Environment="PATH=${BACKEND_DIR}/.venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=${BACKEND_DIR}/.env
ExecStart=${BACKEND_DIR}/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable ids-idps-backend

# Start service
sudo systemctl start ids-idps-backend

# Wait for service to start
sleep 3

# Check service status
if sudo systemctl is-active --quiet ids-idps-backend; then
    echo -e "${GREEN}✓ Backend service started successfully${NC}"
else
    echo -e "${RED}❌ Backend service failed to start!${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    sudo journalctl -u ids-idps-backend -n 20 --no-pager
    exit 1
fi

# Test backend API
echo -e "${BLUE}Testing backend API...${NC}"
sleep 2
if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✓ Backend API is responding${NC}"
else
    echo -e "${RED}❌ Backend API not responding!${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    sudo journalctl -u ids-idps-backend -n 20 --no-pager
    exit 1
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[10/11] Setting up Desktop GUI...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

GUI_DIR="$PROJECT_DIR/gui"
cd "$GUI_DIR"

# Remove old venv if exists
if [ -d ".venv" ]; then
    echo -e "${YELLOW}Removing old GUI virtual environment...${NC}"
    rm -rf .venv
fi

# Create virtual environment for GUI
python3 -m venv .venv
source .venv/bin/activate

# Install GUI dependencies
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "${GREEN}✓ GUI dependencies installed${NC}"

# Make run script executable
chmod +x run_gui.sh 2>/dev/null || true

# Test PyQt5 import
if python3 -c "import PyQt5" 2>/dev/null; then
    echo -e "${GREEN}✓ PyQt5 verified and working${NC}"
else
    echo -e "${RED}❌ PyQt5 import failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[11/11] Creating desktop application launcher...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

# Create desktop launcher directory
mkdir -p ~/.local/share/applications

# Create desktop entry
cat > ~/.local/share/applications/ids-idps.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=IDS/IDPS Dashboard
Comment=Intrusion Detection & Prevention System Admin GUI
Exec=${GUI_DIR}/run_gui.sh
Icon=security-high
Terminal=false
Categories=System;Security;Network;
StartupNotify=true
EOF

chmod +x ~/.local/share/applications/ids-idps.desktop

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
fi

echo -e "${GREEN}✓ Desktop launcher created${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Configuring firewall...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

# Configure UFW firewall
if command -v ufw &> /dev/null; then
    sudo ufw allow OpenSSH 2>/dev/null || true
    sudo ufw allow 8000/tcp comment 'IDS/IDPS Backend API' 2>/dev/null || true
    echo "y" | sudo ufw enable 2>/dev/null || true
    echo -e "${GREEN}✓ Firewall configured${NC}"
else
    echo -e "${YELLOW}⚠️  UFW not available, skipping firewall configuration${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Running final verification checks...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"

CHECKS_PASSED=0
CHECKS_TOTAL=5

# Check 1: PostgreSQL
echo -n "Checking PostgreSQL... "
if sudo systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✓${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗${NC}"
fi

# Check 2: Backend service
echo -n "Checking backend service... "
if sudo systemctl is-active --quiet ids-idps-backend; then
    echo -e "${GREEN}✓${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗${NC}"
fi

# Check 3: Backend API
echo -n "Checking backend API... "
if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗${NC}"
fi

# Check 4: Database connection
echo -n "Checking database connection... "
cd "$BACKEND_DIR"
source .venv/bin/activate
if python3 -c "from app.database import SessionLocal; db = SessionLocal(); db.close()" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗${NC}"
fi

# Check 5: PyQt5
echo -n "Checking PyQt5... "
cd "$GUI_DIR"
source .venv/bin/activate
if python3 -c "import PyQt5" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗${NC}"
fi

echo ""
echo -e "${BLUE}Verification: ${CHECKS_PASSED}/${CHECKS_TOTAL} checks passed${NC}"

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
else
    echo -e "${YELLOW}⚠️  Some checks failed, but setup may still work${NC}"
fi

# Final summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║              🎉 INSTALLATION COMPLETE! 🎉                 ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 SYSTEM STATUS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Backend API:${NC}       http://localhost:8000"
echo -e "${GREEN}API Docs:${NC}          http://localhost:8000/docs"
echo -e "${GREEN}Health Check:${NC}      http://localhost:8000/health"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔐 LOGIN CREDENTIALS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Credentials have been saved to:${NC}"
echo -e "${GREEN}${CREDENTIALS_FILE}${NC}"
echo ""
echo -e "${YELLOW}View credentials:${NC}"
echo -e "  cat ${CREDENTIALS_FILE}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 LAUNCHING THE GUI${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Method 1 - Using run script:${NC}"
echo -e "  cd ${GUI_DIR}"
echo -e "  ./run_gui.sh"
echo ""
echo -e "${GREEN}Method 2 - Manual launch:${NC}"
echo -e "  cd ${GUI_DIR}"
echo -e "  source .venv/bin/activate"
echo -e "  python3 main.py"
echo ""
echo -e "${GREEN}Method 3 - Application menu:${NC}"
echo -e "  Press Super key → Search 'IDS/IDPS Dashboard' → Click to launch"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 USEFUL COMMANDS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Backend Management:${NC}"
echo -e "  sudo systemctl status ids-idps-backend    # Check status"
echo -e "  sudo systemctl restart ids-idps-backend   # Restart backend"
echo -e "  sudo systemctl stop ids-idps-backend      # Stop backend"
echo -e "  sudo journalctl -u ids-idps-backend -f    # View live logs"
echo ""
echo -e "${YELLOW}Database:${NC}"
echo -e "  psql -U ${DB_USER} -d ${DB_NAME} -h localhost  # Connect to DB"
echo ""
echo -e "${YELLOW}Testing:${NC}"
echo -e "  curl http://localhost:8000/health          # Test API"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚠️  IMPORTANT NOTES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}1.${NC} Backend runs as systemd service (auto-starts on boot)"
echo -e "${YELLOW}2.${NC} GUI must be launched manually from desktop"
echo -e "${YELLOW}3.${NC} Time synchronization enabled for 2FA functionality"
echo -e "${YELLOW}4.${NC} Change default passwords after first login!"
echo -e "${YELLOW}5.${NC} Enable 2FA for admin accounts for security"
echo -e "${YELLOW}6.${NC} Credentials file contains sensitive info - keep secure"
echo ""

# Offer to launch GUI immediately
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -p "$(echo -e ${GREEN}Would you like to launch the GUI now? [Y/n]: ${NC})" LAUNCH_GUI

if [[ ! $LAUNCH_GUI =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${GREEN}🚀 Launching IDS/IDPS Desktop GUI...${NC}"
    echo ""
    
    # Check DISPLAY variable
    if [ -z "$DISPLAY" ]; then
        echo -e "${YELLOW}⚠️  DISPLAY variable not set!${NC}"
        echo -e "${YELLOW}   If you're on SSH, use: ssh -X user@host${NC}"
        echo -e "${YELLOW}   Otherwise, try: export DISPLAY=:0${NC}"
        read -p "$(echo -e ${YELLOW}Try setting DISPLAY=:0 and continue? [y/N]: ${NC})" FIX_DISPLAY
        if [[ $FIX_DISPLAY =~ ^[Yy]$ ]]; then
            export DISPLAY=:0
        else
            echo -e "${YELLOW}Skipping GUI launch. Run manually later.${NC}"
            exit 0
        fi
    fi
    
    cd "$GUI_DIR"
    source .venv/bin/activate
    python3 main.py
else
    echo ""
    echo -e "${GREEN}Setup complete! Launch the GUI when ready.${NC}"
    echo ""
fi

echo -e "${GREEN}✨ Thank you for using IDS/IDPS System! ✨${NC}"
echo ""

