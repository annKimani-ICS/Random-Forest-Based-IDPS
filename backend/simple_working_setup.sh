#!/bin/bash
# Simple working setup for IDS/IDPS
# This uses the stable main branch configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Simple Working Setup for IDS/IDPS${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}📁 Project directory: $PROJECT_DIR${NC}"

# Step 1: Setup PostgreSQL
echo -e "${YELLOW}🔧 Step 1: Setting up PostgreSQL...${NC}"
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user (using postgres user to avoid auth issues)
sudo -u postgres psql -c "CREATE DATABASE ids_idps_db;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER ids_user WITH PASSWORD 'ids_password';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ids_idps_db TO ids_user;" 2>/dev/null || true

echo -e "${GREEN}✅ PostgreSQL setup complete${NC}"

# Step 2: Setup backend
echo -e "${YELLOW}🔧 Step 2: Setting up backend...${NC}"
cd "$PROJECT_DIR/backend"

# Create virtual environment
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}✅ Backend dependencies installed${NC}"

# Step 3: Create .env file (using postgres user to avoid auth issues)
echo -e "${YELLOW}🔧 Step 3: Creating environment configuration...${NC}"
cat > .env << EOF
DATABASE_URL=postgresql://postgres@localhost:5432/ids_idps_db
JWT_SECRET=ids-secret-key-$(date +%s)
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:5173
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
EOF

echo -e "${GREEN}✅ Environment configuration created${NC}"

# Step 4: Initialize database
echo -e "${YELLOW}🔧 Step 4: Initializing database...${NC}"
python3 << PYEOF
from app.database import engine, Base
from app.models import *
Base.metadata.create_all(bind=engine)
print("✅ Database tables created successfully")
PYEOF

# Step 5: Seed database with working data
echo -e "${YELLOW}🔧 Step 5: Seeding database...${NC}"
python3 seed_data.py

echo -e "${GREEN}✅ Database seeded with working data${NC}"

# Step 6: Create startup script
echo -e "${YELLOW}🔧 Step 6: Creating startup script...${NC}"
cat > start_backend.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
echo "🚀 Starting IDS/IDPS Backend on port 8000 (working version)..."
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
EOF

chmod +x start_backend.sh

echo -e "${GREEN}✅ Startup script created${NC}"

# Summary
echo -e "\n${GREEN}🎉 Working Setup Complete!${NC}"
echo "=================================="
echo -e "${BLUE}📋 What was configured:${NC}"
echo "   ✅ PostgreSQL database (ids_idps_db)"
echo "   ✅ Backend dependencies installed"
echo "   ✅ Environment configuration (.env)"
echo "   ✅ Database tables created"
echo "   ✅ Database seeded with working data"
echo "   ✅ Startup script created"

echo -e "\n${BLUE}🚀 Next steps:${NC}"
echo "   1. Start backend: ./start_backend.sh"
echo "   2. Start GUI: cd ../gui && python main.py"
echo "   3. Login with working credentials"

echo -e "\n${YELLOW}📊 Expected results:${NC}"
echo "   - Backend runs on port 8000"
echo "   - GUI connects successfully"
echo "   - Correct performance metrics displayed"
echo "   - No authentication errors"

echo -e "\n${GREEN}🎯 Ready to test!${NC}"
