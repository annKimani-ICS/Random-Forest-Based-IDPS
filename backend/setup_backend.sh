#!/bin/bash
# One-Command Backend Setup
# Creates users, seeds data, and ensures everything is ready

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 One-Command Backend Setup${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activate virtual environment
if [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo -e "${RED}❌ Virtual environment not found. Please run simple_postgres_fix.sh first${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Creating users...${NC}"
python3 create_users.py

echo -e "${BLUE}📋 Step 2: Checking if seed_data exists...${NC}"
if [ -f "seed_data.py" ]; then
    echo -e "${BLUE}📋 Step 3: Running seed_data.py...${NC}"
    python3 seed_data.py
else
    echo -e "${YELLOW}⚠️  seed_data.py not found. Skipping data seeding${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Backend Setup Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 Login Credentials:${NC}"
echo "   Admin:  admin@ids-idps.com / AdminSecure2024!"
echo "   Analyst: analyst@ids-idps.com / AnalystSecure2024!"
echo ""
echo -e "${BLUE}🚀 Start the backend:${NC}"
echo "  source .venv/bin/activate"
echo "  export PYTHONPATH=\$(pwd)"
echo "  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}🎯 Users are now ready for GUI login!${NC}"

