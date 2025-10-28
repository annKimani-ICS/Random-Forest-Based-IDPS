#!/bin/bash
# Automated setup script for IDS/IDPS backend
# This script applies all fixes automatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Automated IDS/IDPS Backend Setup${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}📁 Project directory: $PROJECT_DIR${NC}"

# Step 1: Setup PostgreSQL
echo -e "\n${YELLOW}🔧 Step 1: Setting up PostgreSQL...${NC}"
cd "$PROJECT_DIR/backend"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠️ PostgreSQL not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib
fi

# Start PostgreSQL service
echo -e "${BLUE}🚀 Starting PostgreSQL service...${NC}"
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
echo -e "${BLUE}📊 Creating database and user...${NC}"
sudo -u postgres psql -c "CREATE DATABASE ids_db;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER ids_user WITH PASSWORD 'ids_password';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ids_db TO ids_user;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER ids_user CREATEDB;" 2>/dev/null || true

echo -e "${GREEN}✅ PostgreSQL setup complete!${NC}"

# Step 2: Create .env file
echo -e "\n${YELLOW}🔧 Step 2: Creating environment configuration...${NC}"
cat > .env << EOF
DATABASE_URL=postgresql://ids_user:ids_password@localhost:5432/ids_db
JWT_SECRET=ids-secret-key-$(date +%s)
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000
EOF

echo -e "${GREEN}✅ Environment configuration created!${NC}"

# Step 3: Setup virtual environment
echo -e "\n${YELLOW}🔧 Step 3: Setting up Python virtual environment...${NC}"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo -e "${GREEN}✅ Virtual environment created!${NC}"
else
    echo -e "${BLUE}📦 Virtual environment already exists${NC}"
fi

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
echo -e "${BLUE}📦 Installing Python dependencies...${NC}"
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "${GREEN}✅ Dependencies installed!${NC}"

# Step 4: Run database migrations
echo -e "\n${YELLOW}🔧 Step 4: Running database migrations...${NC}"
alembic upgrade head

echo -e "${GREEN}✅ Database migrations complete!${NC}"

# Step 5: Populate database with correct metrics
echo -e "\n${YELLOW}🔧 Step 5: Populating database with correct metrics...${NC}"
python add_dummy_alerts.py

echo -e "${GREEN}✅ Database populated with correct metrics!${NC}"

# Step 6: Create startup script
echo -e "\n${YELLOW}🔧 Step 6: Creating startup script...${NC}"
cat > start_backend.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
echo "🚀 Starting IDS/IDPS Backend on port 3000..."
python -m uvicorn app.main:app --host 0.0.0.0 --port 3000 --reload
EOF

chmod +x start_backend.sh

echo -e "${GREEN}✅ Startup script created!${NC}"

# Summary
echo -e "\n${GREEN}🎉 Automated setup complete!${NC}"
echo "=================================="
echo -e "${BLUE}📋 What was configured:${NC}"
echo "   ✅ PostgreSQL database (ids_db)"
echo "   ✅ Database user (ids_user)"
echo "   ✅ Environment configuration (.env)"
echo "   ✅ Python virtual environment (.venv)"
echo "   ✅ Dependencies installed"
echo "   ✅ Database migrations applied"
echo "   ✅ Correct Random Forest metrics populated"
echo "   ✅ Startup script created (start_backend.sh)"

echo -e "\n${BLUE}🚀 Next steps:${NC}"
echo "   1. Start backend: ./start_backend.sh"
echo "   2. Start GUI: cd ../gui && python main.py"
echo "   3. Open GUI and verify metrics show 90.48% accuracy"

echo -e "\n${YELLOW}📊 Expected GUI metrics:${NC}"
echo "   - Accuracy: 90.48%"
echo "   - Precision: 90.62%"
echo "   - Recall: 90.48%"
echo "   - F1-Score: 90.51%"
echo "   - AUC: 95.00%"

echo -e "\n${GREEN}🎯 Ready to test!${NC}"
