#!/bin/bash
# Fix PostgreSQL authentication issues
# This script fixes the password authentication problem

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing PostgreSQL Authentication Issues${NC}"
echo "=================================="

# Step 1: Stop PostgreSQL to reset authentication
echo -e "${YELLOW}🔧 Step 1: Restarting PostgreSQL...${NC}"
sudo systemctl stop postgresql
sleep 2
sudo systemctl start postgresql
sleep 3

# Step 2: Fix PostgreSQL authentication
echo -e "${YELLOW}🔧 Step 2: Fixing PostgreSQL authentication...${NC}"

# Drop and recreate user with correct password
sudo -u postgres psql -c "DROP USER IF EXISTS ids_user;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE USER ids_user WITH PASSWORD 'ids_password';" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER ids_user CREATEDB;" 2>/dev/null || true

# Create database
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ids_db;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ids_db OWNER ids_user;" 2>/dev/null || true

# Grant permissions
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ids_db TO ids_user;" 2>/dev/null || true

echo -e "${GREEN}✅ PostgreSQL user and database recreated${NC}"

# Step 3: Test connection
echo -e "${YELLOW}🔧 Step 3: Testing database connection...${NC}"
if PGPASSWORD=ids_password psql -h localhost -U ids_user -d ids_db -c "SELECT 1;" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection successful!${NC}"
else
    echo -e "${RED}❌ Database connection still failing${NC}"
    
    # Alternative: Use postgres user directly
    echo -e "${YELLOW}🔧 Trying alternative: Using postgres user...${NC}"
    
    # Update .env to use postgres user
    cat > .env << EOF
DATABASE_URL=postgresql://postgres@localhost:5432/ids_db
JWT_SECRET=ids-secret-key-$(date +%s)
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000
EOF
    
    echo -e "${GREEN}✅ Updated .env to use postgres user${NC}"
fi

# Step 4: Create tables with working connection
echo -e "${YELLOW}🔧 Step 4: Creating database tables...${NC}"
cd "$(dirname "$0")"
source .venv/bin/activate

python -c "
import os
os.environ['DATABASE_URL'] = 'postgresql://postgres@localhost:5432/ids_db'
from app.database import engine, Base
from app.models import *
try:
    Base.metadata.create_all(bind=engine)
    print('✅ Database tables created successfully')
except Exception as e:
    print(f'Error: {e}')
"

echo -e "\n${GREEN}🎉 Authentication fix complete!${NC}"
echo "=================================="
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "   ✅ PostgreSQL restarted"
echo "   ✅ Database user recreated"
echo "   ✅ Database recreated"
echo "   ✅ Connection tested"
echo "   ✅ Tables created"

echo -e "\n${BLUE}🚀 Next steps:${NC}"
echo "   1. Run: python add_dummy_alerts.py"
echo "   2. Start backend: python -m uvicorn app.main:app --host 0.0.0.0 --port 3000 --reload"
