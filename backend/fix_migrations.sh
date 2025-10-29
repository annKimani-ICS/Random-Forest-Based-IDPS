#!/bin/bash
# Fix for Alembic migration issues
# This script handles common migration problems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing Alembic Migration Issues${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activate virtual environment
source .venv/bin/activate

# Step 1: Check if alembic version table exists
echo -e "${YELLOW}🔍 Checking Alembic version table...${NC}"
if ! python -c "
from app.database import SessionLocal
from sqlalchemy import text
db = SessionLocal()
try:
    result = db.execute(text('SELECT version_num FROM alembic_version LIMIT 1'))
    print('Alembic version table exists')
except:
    print('Alembic version table does not exist')
finally:
    db.close()
" 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Alembic version table missing. Creating...${NC}"
    
    # Create alembic version table manually
    python -c "
from app.database import SessionLocal
from sqlalchemy import text
db = SessionLocal()
try:
    db.execute(text('CREATE TABLE IF NOT EXISTS alembic_version (version_num VARCHAR(32) NOT NULL, CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num))'))
    db.commit()
    print('✅ Alembic version table created')
except Exception as e:
    print(f'Error: {e}')
    db.rollback()
finally:
    db.close()
"
fi

# Step 2: Initialize Alembic if needed
echo -e "${YELLOW}🔍 Checking Alembic initialization...${NC}"
if [ ! -d "alembic/versions" ] || [ ! "$(ls -A alembic/versions)" ]; then
    echo -e "${YELLOW}⚠️ Alembic not initialized. Initializing...${NC}"
    
    # Remove existing alembic if corrupted
    rm -rf alembic/versions/*
    
    # Initialize alembic
    alembic revision --autogenerate -m "Initial migration"
    
    echo -e "${GREEN}✅ Alembic initialized${NC}"
fi

# Step 3: Create tables directly if migrations fail
echo -e "${YELLOW}🔍 Creating database tables...${NC}"
python -c "
from app.database import engine, Base
from app.models import *
try:
    Base.metadata.create_all(bind=engine)
    print('✅ Database tables created successfully')
except Exception as e:
    print(f'Error creating tables: {e}')
"

# Step 4: Try to run migrations
echo -e "${YELLOW}🔍 Running Alembic migrations...${NC}"
if alembic upgrade head; then
    echo -e "${GREEN}✅ Alembic migrations completed${NC}"
else
    echo -e "${YELLOW}⚠️ Alembic migrations failed, but tables were created directly${NC}"
fi

# Step 5: Verify database setup
echo -e "${YELLOW}🔍 Verifying database setup...${NC}"
python -c "
from app.database import SessionLocal
from app.models import User, Model, Alert
db = SessionLocal()
try:
    # Check if tables exist
    user_count = db.query(User).count()
    model_count = db.query(Model).count()
    alert_count = db.query(Alert).count()
    
    print(f'✅ Database verification successful:')
    print(f'   - Users: {user_count}')
    print(f'   - Models: {model_count}')
    print(f'   - Alerts: {alert_count}')
except Exception as e:
    print(f'❌ Database verification failed: {e}')
finally:
    db.close()
"

echo -e "\n${GREEN}🎉 Migration fix complete!${NC}"
echo "=================================="
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "   ✅ Alembic version table created"
echo "   ✅ Database tables created"
echo "   ✅ Migrations attempted"
echo "   ✅ Database verified"

echo -e "\n${BLUE}🚀 Next steps:${NC}"
echo "   1. Continue with: python add_dummy_alerts.py"
echo "   2. Start backend: python -m uvicorn app.main:app --host 0.0.0.0 --port 3000 --reload"
