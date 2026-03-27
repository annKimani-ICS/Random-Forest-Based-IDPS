#!/bin/bash
# IDS/IDPS Ubuntu VM Setup Script
# Run as non-root user with sudo privileges

set -e

echo "======================================"
echo "IDS/IDPS System - Ubuntu Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run as root. Run as a regular user with sudo privileges.${NC}"
   exit 1
fi

# Update system
echo -e "${GREEN}[1/9] Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y

# Install dependencies
echo -e "${GREEN}[2/9] Installing system dependencies...${NC}"
sudo apt install -y python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib \
    nginx \
    ufw \
    git \
    curl \
    build-essential \
    libpq-dev

# Setup NTP for time synchronization (critical for TOTP)
echo -e "${GREEN}[3/9] Setting up time synchronization (critical for 2FA)...${NC}"
sudo timedatectl set-ntp true
echo "Current time: $(date)"

# Configure PostgreSQL
echo -e "${GREEN}[4/9] Configuring PostgreSQL...${NC}"
read -p "Enter database name [ids_idps_db]: " DB_NAME
DB_NAME=${DB_NAME:-ids_idps_db}

read -p "Enter database user [ids_user]: " DB_USER
DB_USER=${DB_USER:-ids_user}

read -sp "Enter database password: " DB_PASSWORD
echo

# Create PostgreSQL user and database
sudo -u postgres psql <<EOF
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
\q
EOF

echo -e "${GREEN}Database created successfully${NC}"

# Setup application directory
echo -e "${GREEN}[5/9] Setting up application directory...${NC}"
APP_DIR="$HOME/ids-idps"
mkdir -p $APP_DIR
cd $APP_DIR

# Copy backend files (assumes script is run from project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -r "$SCRIPT_DIR"/* $APP_DIR/

# Create Python virtual environment
echo -e "${GREEN}[6/9] Creating Python virtual environment...${NC}"
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
echo -e "${GREEN}Installing Python packages...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
echo -e "${GREEN}[7/9] Creating environment configuration...${NC}"
JWT_SECRET=$(openssl rand -hex 32)

cat > .env <<EOF
DATABASE_URL=postgresql+psycopg2://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}
JWT_SECRET=${JWT_SECRET}
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:5173,http://$(hostname -I | awk '{print $1}')
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
EOF

echo -e "${GREEN}.env file created${NC}"

# Initialize database
echo -e "${GREEN}[8/9] Initializing database...${NC}"
# Create tables directly using SQLAlchemy
python3 <<PYEOF
from app.database import engine, Base
from app.models import *
Base.metadata.create_all(bind=engine)
print("Database tables created successfully")
PYEOF

# Seed database
echo -e "${GREEN}Seeding database with initial data...${NC}"
python3 seed_data.py

# Create systemd service
echo -e "${GREEN}[9/9] Creating systemd service...${NC}"
sudo tee /etc/systemd/system/ids-idps.service > /dev/null <<EOF
[Unit]
Description=IDS/IDPS Admin API
After=network.target postgresql.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/.venv/bin"
EnvironmentFile=$APP_DIR/.env
ExecStart=$APP_DIR/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable ids-idps
sudo systemctl start ids-idps

# Configure firewall
echo -e "${GREEN}Configuring firewall...${NC}"
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
echo "y" | sudo ufw enable

# Check service status
echo -e "${GREEN}======================================"
echo "Installation Complete!"
echo "======================================${NC}"
echo ""
echo "Service Status:"
sudo systemctl status ids-idps --no-pager
echo ""
echo -e "${GREEN}Backend API:${NC} http://$(hostname -I | awk '{print $1}'):8000"
echo -e "${GREEN}API Docs:${NC} http://$(hostname -I | awk '{print $1}'):8000/docs"
echo ""
echo -e "${YELLOW}Default Credentials:${NC}"
echo "  Admin:   admin@ids-idps.com / [Generated during setup]"
echo "  Analyst: analyst@ids-idps.com / [Generated during setup]"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Setup and build the frontend (see setup_frontend.sh)"
echo "  2. Configure Nginx reverse proxy (optional)"
echo "  3. Setup SSL/TLS with Let's Encrypt (production)"
echo "  4. Enable 2FA for users via /mfa-enroll"
echo ""
echo -e "${GREEN}Useful Commands:${NC}"
echo "  sudo systemctl status ids-idps    # Check service status"
echo "  sudo systemctl restart ids-idps   # Restart service"
echo "  sudo journalctl -u ids-idps -f    # View logs"
echo ""

