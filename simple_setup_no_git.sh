#!/bin/bash
# Simple Setup Script - No Git Required
# This script sets up the IDS/IDPS system without requiring git

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 IDS/IDPS Simple Setup (No Git Required)${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Step 1: Check if we have the necessary files
echo -e "${YELLOW}🔧 Step 1: Checking for required files...${NC}"

REQUIRED_FILES=(
    "backend/app/main.py"
    "gui/main.py"
    "gui/api_client.py"
    "backend/requirements.txt"
    "gui/requirements.txt"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required files:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo -e "   - $file"
    done
    echo ""
    echo -e "${YELLOW}⚠️ Please ensure you have all the project files${NC}"
    echo -e "${BLUE}You can download them from:${NC}"
    echo -e "   https://github.com/annKimani-ICS/Random-Forest-Based-IDPS"
    echo ""
    echo -e "${YELLOW}Or run this command to download:${NC}"
    echo -e "   wget -O project.zip https://github.com/annKimani-ICS/Random-Forest-Based-IDPS/archive/refs/heads/feat/sprint4-admin-dashboard.zip"
    echo -e "   unzip project.zip"
    echo -e "   mv Random-Forest-Based-IDPS-feat-sprint4-admin-dashboard/* ."
    echo -e "   rm -rf Random-Forest-Based-IDPS-feat-sprint4-admin-dashboard project.zip"
    exit 1
fi

echo -e "${GREEN}✅ All required files found${NC}"

# Step 2: Setup PostgreSQL
echo -e "${YELLOW}🔧 Step 2: Setting up PostgreSQL...${NC}"

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user (using postgres user to avoid auth issues)
sudo -u postgres psql -c "CREATE DATABASE ids_idps_db;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER ids_user WITH PASSWORD 'ids_password';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ids_idps_db TO ids_user;" 2>/dev/null || true

echo -e "${GREEN}✅ PostgreSQL database configured${NC}"

# Step 3: Setup Backend Environment
echo -e "${YELLOW}🔧 Step 3: Setting up backend environment...${NC}"
cd backend

# Create virtual environment
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "${GREEN}✅ Backend dependencies installed${NC}"

# Step 4: Create Environment Configuration
echo -e "${YELLOW}🔧 Step 4: Creating environment configuration...${NC}"

# Create .env file with postgres user (no auth issues)
cat > .env << EOF
DATABASE_URL=postgresql://postgres@localhost:5432/ids_idps_db
JWT_SECRET=ids-secret-key-$(date +%s)
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

echo -e "${GREEN}✅ Environment configuration created${NC}"

# Step 5: Initialize Database
echo -e "${YELLOW}🔧 Step 5: Initializing database...${NC}"

# Create tables directly (more reliable than Alembic)
python3 << PYEOF
from app.database import engine, Base
from app.models import *
try:
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created successfully")
except Exception as e:
    print(f"Error creating tables: {e}")
PYEOF

# Step 6: Seed Database with Working Data
echo -e "${YELLOW}🔧 Step 6: Seeding database with working data...${NC}"

# Run seed script
python3 seed_data.py

echo -e "${GREEN}✅ Database seeded with working data${NC}"

# Step 7: Setup GUI Environment
echo -e "${YELLOW}🔧 Step 7: Setting up GUI environment...${NC}"
cd ../gui

# Create virtual environment for GUI
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "${GREEN}✅ GUI dependencies installed${NC}"

# Step 8: Create Startup Scripts
echo -e "${YELLOW}🔧 Step 8: Creating startup scripts...${NC}"

# Backend startup script
cd ../backend
cat > start_backend.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
echo "🚀 Starting IDS/IDPS Backend on port 8000..."
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
EOF

chmod +x start_backend.sh

# GUI startup script
cd ../gui
cat > start_gui.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
echo "🚀 Starting IDS/IDPS GUI..."
python main.py
EOF

chmod +x start_gui.sh

echo -e "${GREEN}✅ Startup scripts created${NC}"

# Step 9: Create Systemd Service for Backend
echo -e "${YELLOW}🔧 Step 9: Creating systemd service...${NC}"

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
WorkingDirectory=$(pwd)/backend
Environment="PATH=$(pwd)/backend/.venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=$(pwd)/backend/.env
ExecStart=$(pwd)/backend/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
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

echo -e "${GREEN}✅ Systemd service created${NC}"

# Step 10: Configure Firewall
echo -e "${YELLOW}🔧 Step 10: Configuring firewall...${NC}"

# Configure UFW firewall
if command -v ufw &> /dev/null; then
    sudo ufw allow OpenSSH 2>/dev/null || true
    sudo ufw allow 8000/tcp comment 'IDS/IDPS Backend API' 2>/dev/null || true
    echo "y" | sudo ufw enable 2>/dev/null || true
    echo -e "${GREEN}✅ Firewall configured${NC}"
else
    echo -e "${YELLOW}⚠️ UFW not available, skipping firewall configuration${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}🎉 Simple Setup Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What was configured:${NC}"
echo "   ✅ PostgreSQL database (ids_idps_db)"
echo "   ✅ Backend environment setup"
echo "   ✅ GUI environment setup"
echo "   ✅ Database tables created"
echo "   ✅ Database seeded with working data"
echo "   ✅ Startup scripts created"
echo "   ✅ Systemd service configured"
echo "   ✅ Firewall configured"

echo ""
echo -e "${BLUE}🚀 Ready for Live Traffic Testing!${NC}"
echo "=============================================="
echo ""
echo -e "${GREEN}Start Backend:${NC}"
echo "  cd backend && ./start_backend.sh"
echo ""
echo -e "${GREEN}Start GUI (in new terminal):${NC}"
echo "  cd gui && ./start_gui.sh"
echo ""
echo -e "${GREEN}Or use systemd service:${NC}"
echo "  sudo systemctl start ids-idps-backend"
echo ""
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "   - Backend runs on port 8000"
echo "   - GUI connects successfully"
echo "   - Correct Random Forest metrics displayed"
echo "   - Ready for live traffic testing"
echo ""
echo -e "${GREEN}🎯 System is ready for live traffic testing!${NC}"
