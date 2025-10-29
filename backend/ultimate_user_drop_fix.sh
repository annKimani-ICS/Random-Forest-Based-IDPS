#!/bin/bash
# Ultimate PostgreSQL User Drop Fix
# Aggressively removes ids_user and recreates it

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Ultimate PostgreSQL User Drop Fix${NC}"
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

echo -e "${BLUE}📋 Step 1: Terminating all connections to ids_user...${NC}"
# Kill all connections to the user
$SUDO -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'ids_user';" 2>/dev/null || true

echo -e "${BLUE}📋 Step 2: Revoking all privileges from ids_user...${NC}"
# Revoke all privileges
$SUDO -u postgres psql -c "REVOKE ALL PRIVILEGES ON DATABASE ids_idps_db FROM ids_user;" 2>/dev/null || true
$SUDO -u postgres psql -c "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM ids_user;" 2>/dev/null || true
$SUDO -u postgres psql -c "REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM ids_user;" 2>/dev/null || true

echo -e "${BLUE}📋 Step 3: Dropping database first...${NC}"
# Drop database first to remove ownership
$SUDO -u postgres psql -c "DROP DATABASE IF EXISTS ids_idps_db;" 2>/dev/null || true

echo -e "${BLUE}📋 Step 4: Multiple attempts to drop user...${NC}"
# Try multiple methods to drop the user
for i in {1..3}; do
    echo -e "${BLUE}Attempt $i: Dropping user ids_user...${NC}"
    
    # Method 1: Drop with CASCADE
    $SUDO -u postgres psql -c "DROP USER IF EXISTS ids_user CASCADE;" 2>/dev/null || true
    
    # Method 2: Drop without IF EXISTS (will error if doesn't exist, but that's OK)
    $SUDO -u postgres psql -c "DROP USER ids_user CASCADE;" 2>/dev/null || true
    
    # Method 3: Drop role (PostgreSQL treats users as roles)
    $SUDO -u postgres psql -c "DROP ROLE IF EXISTS ids_user CASCADE;" 2>/dev/null || true
    
    # Check if user still exists
    if ! $SUDO -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='ids_user';" | grep -q 1; then
        echo -e "${GREEN}✅ User ids_user successfully dropped${NC}"
        break
    else
        echo -e "${YELLOW}⚠️  User still exists, trying again...${NC}"
        sleep 2
    fi
done

# Final check
if $SUDO -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='ids_user';" | grep -q 1; then
    echo -e "${RED}❌ Could not drop user ids_user after multiple attempts${NC}"
    echo -e "${YELLOW}📋 Manual fix required:${NC}"
    echo "1. Connect as postgres: sudo -u postgres psql"
    echo "2. Run: DROP USER ids_user CASCADE;"
    echo "3. Verify: \\du"
    exit 1
fi

echo -e "${BLUE}📋 Step 5: Creating new user with fresh password...${NC}"
# Generate a completely new password
NEW_PASS="FreshPass$(date +%s | tail -c 6)"

echo -e "${BLUE}🔑 New password: $NEW_PASS${NC}"

# Create user with new password
$SUDO -u postgres psql -c "CREATE USER ids_user WITH PASSWORD '$NEW_PASS';"

echo -e "${BLUE}📋 Step 6: Creating database with new owner...${NC}"
# Create database with proper owner
$SUDO -u postgres psql -c "CREATE DATABASE ids_idps_db OWNER ids_user;"

# Grant all privileges
$SUDO -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ids_idps_db TO ids_user;"

echo -e "${GREEN}✅ User and database recreated successfully${NC}"

echo -e "${BLUE}📋 Step 7: Updating .env file...${NC}"
# Create .env file with new password
cat > .env <<EOF
DATABASE_URL=postgresql+psycopg2://ids_user:${NEW_PASS}@localhost:5432/ids_idps_db
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

echo -e "${GREEN}✅ .env file updated${NC}"

echo -e "${BLUE}📋 Step 8: Testing connection...${NC}"
# Test connection with SQLAlchemy
if python3 -c "
import os
from sqlalchemy import create_engine

# Read DATABASE_URL from .env
with open('.env', 'r') as f:
    for line in f:
        if line.startswith('DATABASE_URL='):
            url = line.strip().split('=', 1)[1]
            break

try:
    engine = create_engine(url, pool_pre_ping=True)
    with engine.connect() as conn:
        result = conn.execute('SELECT 1 as test')
        print('✅ SQLAlchemy connection successful')
except Exception as e:
    print(f'❌ SQLAlchemy connection failed: {e}')
    exit(1)
" 2>/dev/null; then
    echo -e "${GREEN}✅ Connection test passed${NC}"
else
    echo -e "${RED}❌ Connection test failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Ultimate User Drop Fix Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo "   ✅ Terminated all connections to ids_user"
echo "   ✅ Revoked all privileges"
echo "   ✅ Dropped database first"
echo "   ✅ Multiple attempts to drop user"
echo "   ✅ Created new user with fresh password"
echo "   ✅ Created database with new owner"
echo "   ✅ Updated .env file"
echo "   ✅ Connection test passed"
echo ""
echo -e "${BLUE}🚀 Start the backend:${NC}"
echo "  source .venv/bin/activate"
echo "  export PYTHONPATH=\$(pwd)"
echo "  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}🎯 User drop issue should now be resolved!${NC}"
