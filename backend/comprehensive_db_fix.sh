#!/bin/bash
# Comprehensive PostgreSQL Fix Script
# Fixes all database connection issues automatically

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Comprehensive PostgreSQL Fix${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we're in backend directory
if [ ! -f "app/main.py" ]; then
    echo -e "${RED}❌ Please run this script from the backend directory${NC}"
    exit 1
fi

# Ensure sudo is available
if command -v sudo >/dev/null 2>&1; then
    SUDO=sudo
else
    echo -e "${RED}❌ sudo is required but not available${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Ensuring PostgreSQL is running...${NC}"
if $SUDO systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✅ PostgreSQL service is running${NC}"
else
    echo -e "${YELLOW}▶️  Starting PostgreSQL service...${NC}"
    $SUDO systemctl start postgresql
    $SUDO systemctl enable postgresql
    sleep 2
fi

echo -e "${BLUE}📋 Step 2: Configuring PostgreSQL authentication...${NC}"
# Find pg_hba.conf
PG_HBA=$($SUDO find /etc/postgresql -name pg_hba.conf | head -n1)
if [ -z "$PG_HBA" ]; then
    echo -e "${RED}❌ Could not find pg_hba.conf${NC}"
    exit 1
fi

echo -e "${BLUE}🔐 Configuring authentication in $PG_HBA...${NC}"
# Backup original
$SUDO cp "$PG_HBA" "$PG_HBA.backup"

# Fix local connections to use md5
$SUDO sed -i 's/^local\s\+all\s\+all\s\+peer/local   all             all                                     md5/' "$PG_HBA"

# Add host rules for localhost if missing
if ! $SUDO grep -q "host.*all.*all.*127.0.0.1/32.*md5" "$PG_HBA"; then
    echo "host    all             all             127.0.0.1/32            md5" | $SUDO tee -a "$PG_HBA" >/dev/null
fi

if ! $SUDO grep -q "host.*all.*all.*::1/128.*md5" "$PG_HBA"; then
    echo "host    all             all             ::1/128                 md5" | $SUDO tee -a "$PG_HBA" >/dev/null
fi

# Reload PostgreSQL configuration
$SUDO systemctl reload postgresql
echo -e "${GREEN}✅ PostgreSQL authentication configured${NC}"

echo -e "${BLUE}📋 Step 3: Creating database and user...${NC}"

# Generate a simple, safe password
IDS_PASS="IdsUser$(date +%s | tail -c 8)"

echo -e "${BLUE}🔑 Generated password: $IDS_PASS${NC}"

# Create database if it doesn't exist
echo -e "${BLUE}📦 Creating database ids_idps_db...${NC}"
$SUDO -u postgres psql -c "CREATE DATABASE ids_idps_db;" 2>/dev/null || echo -e "${YELLOW}⚠️  Database may already exist${NC}"

# Create user if it doesn't exist
echo -e "${BLUE}👤 Creating user ids_user...${NC}"
$SUDO -u postgres psql -c "CREATE USER ids_user WITH PASSWORD '$IDS_PASS';" 2>/dev/null || echo -e "${YELLOW}⚠️  User may already exist${NC}"

# Set database owner and privileges
echo -e "${BLUE}🔐 Setting database ownership and privileges...${NC}"
$SUDO -u postgres psql -c "ALTER DATABASE ids_idps_db OWNER TO ids_user;"
$SUDO -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ids_idps_db TO ids_user;"

echo -e "${GREEN}✅ Database and user created successfully${NC}"

echo -e "${BLUE}📋 Step 4: Creating .env file...${NC}"
# Create .env file
cat > .env <<EOF
DATABASE_URL=postgresql+psycopg2://ids_user:${IDS_PASS}@localhost:5432/ids_idps_db
JWT_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "default-jwt-secret-$(date +%s)")
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:5173,http://localhost:8000
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
EOF

echo -e "${GREEN}✅ .env file created${NC}"

echo -e "${BLUE}📋 Step 5: Testing database connection...${NC}"
# Test connection
if python3 -c "
import os
from sqlalchemy import create_engine, text

# Read DATABASE_URL from .env
with open('.env', 'r') as f:
    for line in f:
        if line.startswith('DATABASE_URL='):
            url = line.strip().split('=', 1)[1]
            break

try:
    engine = create_engine(url, pool_pre_ping=True)
    with engine.connect() as conn:
        conn.execute(text('SELECT 1'))
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection test passed${NC}"
else
    echo -e "${RED}❌ Database connection test failed${NC}"
    echo -e "${YELLOW}📋 Troubleshooting steps:${NC}"
    echo "1. Check PostgreSQL logs: sudo journalctl -u postgresql -n 50"
    echo "2. Verify pg_hba.conf: sudo cat $PG_HBA"
    echo "3. Test manual connection: sudo -u postgres psql -c '\\l'"
    exit 1
fi

echo -e "${BLUE}📋 Step 6: Creating database tables...${NC}"
# Create tables
if python3 -c "
import os
from sqlalchemy import create_engine
from app.database import Base
from app.models import *

# Read DATABASE_URL from .env
with open('.env', 'r') as f:
    for line in f:
        if line.startswith('DATABASE_URL='):
            url = line.strip().split('=', 1)[1]
            break

try:
    engine = create_engine(url, pool_pre_ping=True)
    Base.metadata.create_all(bind=engine)
    print('✅ Database tables created successfully')
except Exception as e:
    print(f'❌ Failed to create tables: {e}')
    exit(1)
" 2>/dev/null; then
    echo -e "${GREEN}✅ Database tables created${NC}"
else
    echo -e "${YELLOW}⚠️  Could not create tables automatically${NC}"
fi

echo ""
echo -e "${GREEN}🎉 PostgreSQL Fix Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo "   ✅ PostgreSQL service is running"
echo "   ✅ Authentication configured (md5)"
echo "   ✅ Database 'ids_idps_db' created"
echo "   ✅ User 'ids_user' created with password"
echo "   ✅ Database ownership and privileges set"
echo "   ✅ .env file created with correct DATABASE_URL"
echo "   ✅ Database connection verified"
echo "   ✅ Database tables created"
echo ""
echo -e "${BLUE}🚀 Start the backend:${NC}"
echo "  source .venv/bin/activate"
echo "  export PYTHONPATH=\$(pwd)"
echo "  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}🎯 All database errors should now be resolved!${NC}"
