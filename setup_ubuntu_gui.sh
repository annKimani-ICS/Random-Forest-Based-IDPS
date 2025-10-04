#!/bin/bash
# Complete IDS/IDPS System Setup for Ubuntu VM
# Includes Backend API + Desktop GUI Application
# Based on project requirements: Python, FastAPI, PyQt5, PostgreSQL, Scikit-learn

set -e

echo "=============================================="
echo "IDS/IDPS System - Complete Ubuntu Setup"
echo "Backend API + Desktop GUI Application"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run as root. Run as a regular user with sudo privileges.${NC}"
   exit 1
fi

echo -e "${GREEN}[1/10] Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y

echo -e "${GREEN}[2/10] Installing system dependencies...${NC}"
sudo apt install -y \
    python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib \
    python3-pyqt5 python3-pyqt5.qtsvg \
    libpq-dev \
    build-essential \
    git curl wget \
    qt5-default \
    libxcb-xinerama0

echo -e "${GREEN}[3/10] Setting up time synchronization (CRITICAL for 2FA)...${NC}"
sudo timedatectl set-ntp true
echo "Current time: $(date)"
timedatectl status

echo -e "${GREEN}[4/10] Configuring PostgreSQL database...${NC}"
read -p "Enter database name [ids_idps_db]: " DB_NAME
DB_NAME=${DB_NAME:-ids_idps_db}

read -p "Enter database user [ids_user]: " DB_USER
DB_USER=${DB_USER:-ids_user}

read -sp "Enter database password: " DB_PASSWORD
echo

# Create PostgreSQL user and database
sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS ${DB_NAME};
DROP USER IF EXISTS ${DB_USER};
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
\q
EOF

echo -e "${GREEN}Database '${DB_NAME}' created successfully${NC}"

echo -e "${GREEN}[5/10] Setting up backend API directory...${NC}"
BACKEND_DIR="$HOME/ids-idps/backend"
mkdir -p $BACKEND_DIR
cd $BACKEND_DIR

# Create Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

echo -e "${GREEN}[6/10] Installing Python backend dependencies...${NC}"
pip install --upgrade pip

# Create requirements if not exists
cat > requirements.txt <<EOF
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
psycopg2-binary==2.9.9
alembic==1.13.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
pyotp==2.9.0
qrcode[pil]==7.4.2
python-dotenv==1.0.0
pydantic==2.5.3
pydantic-settings==2.1.0
email-validator==2.1.0
slowapi==0.1.9
scikit-learn==1.3.2
pandas==2.1.4
numpy==1.26.2
EOF

pip install -r requirements.txt

echo -e "${GREEN}[7/10] Configuring backend environment...${NC}"
JWT_SECRET=$(openssl rand -hex 32)

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

echo -e "${GREEN}.env file created${NC}"

# Note: Assume backend files are already in place from project
if [ ! -f "app/main.py" ]; then
    echo -e "${YELLOW}Warning: Backend app files not found. Please copy backend files to $BACKEND_DIR${NC}"
    echo "Expected structure: backend/app/main.py, backend/app/models.py, etc."
fi

echo -e "${GREEN}[8/10] Initializing database and seeding data...${NC}"
if [ -f "seed_data.py" ]; then
    # Run seeding and capture output to save passwords
    python3 seed_data.py 2>&1 | tee /tmp/ids_idps_credentials.txt
    echo -e "${GREEN}Database seeded successfully${NC}"
    echo -e "${YELLOW}Credentials saved to: /tmp/ids_idps_credentials.txt${NC}"
    echo -e "${YELLOW}Please save these credentials securely!${NC}"
else
    echo -e "${YELLOW}Warning: seed_data.py not found. Skipping database seeding.${NC}"
fi

# Create systemd service for backend
echo -e "${GREEN}[9/10] Creating backend systemd service...${NC}"
sudo tee /etc/systemd/system/ids-idps-backend.service > /dev/null <<EOF
[Unit]
Description=IDS/IDPS Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/.venv/bin"
EnvironmentFile=$BACKEND_DIR/.env
ExecStart=$BACKEND_DIR/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ids-idps-backend
sudo systemctl start ids-idps-backend

echo -e "${GREEN}[10/10] Setting up Desktop GUI Application...${NC}"
GUI_DIR="$HOME/ids-idps/gui"
mkdir -p $GUI_DIR
cd $GUI_DIR

# Create GUI Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install GUI dependencies
cat > requirements.txt <<EOF
PyQt5==5.15.10
requests==2.31.0
pyqtgraph==0.13.3
qrcode[pil]==7.4.2
Pillow==10.1.0
matplotlib==3.8.2
EOF

pip install -r requirements.txt

# Create desktop launcher
echo -e "${GREEN}Creating desktop application launcher...${NC}"
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/ids-idps.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=IDS/IDPS Dashboard
Comment=Intrusion Detection & Prevention System Admin GUI
Exec=$GUI_DIR/.venv/bin/python3 $GUI_DIR/main.py
Icon=security
Terminal=false
Categories=System;Security;Network;
EOF

chmod +x ~/.local/share/applications/ids-idps.desktop

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database ~/.local/share/applications
fi

# Configure firewall
echo -e "${GREEN}Configuring firewall...${NC}"
sudo ufw allow OpenSSH
sudo ufw allow 8000/tcp  # Backend API
echo "y" | sudo ufw enable || true

# Check backend service status
echo -e "${GREEN}=============================================="
echo "Installation Complete!"
echo "==============================================${NC}"
echo ""
echo -e "${GREEN}Backend API Status:${NC}"
sudo systemctl status ids-idps-backend --no-pager -l || true
echo ""
echo -e "${GREEN}Backend API URL:${NC} http://localhost:8000"
echo -e "${GREEN}API Documentation:${NC} http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}Default Login Credentials:${NC}"
echo "  Admin User:"
echo "    Email: admin@ids-idps.com"
echo "    Password: [Generated during setup - check .env file]"
echo ""
echo "  Analyst User:"
echo "    Email: analyst@ids-idps.com"
echo "    Password: [Generated during setup - check .env file]"
echo ""
echo -e "${GREEN}Starting Desktop GUI Application...${NC}"
echo ""
echo "The GUI application can be launched:"
echo "  1. From Applications menu: Search for 'IDS/IDPS Dashboard'"
echo "  2. From terminal: cd $GUI_DIR && ./run_gui.sh"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "  • Backend API runs as systemd service (auto-starts on boot)"
echo "  • GUI is a desktop application (manual launch)"
echo "  • Time sync enabled for TOTP 2FA"
echo "  • Change default passwords immediately!"
echo "  • Enable 2FA for all admin accounts"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  sudo systemctl status ids-idps-backend   # Check backend status"
echo "  sudo systemctl restart ids-idps-backend  # Restart backend"
echo "  sudo journalctl -u ids-idps-backend -f   # View backend logs"
echo "  cd $GUI_DIR && source .venv/bin/activate # Activate GUI venv"
echo "  python3 $GUI_DIR/main.py                 # Run GUI manually"
echo ""

