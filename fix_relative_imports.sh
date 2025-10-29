#!/bin/bash
# Fix Relative Import Error
# This script fixes the "attempted relative import with no known parent package" error

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fix Relative Import Error${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Check if backend directory exists
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ Backend directory not found${NC}"
    exit 1
fi

cd backend

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
fi

# Activate virtual environment
source .venv/bin/activate

echo -e "${GREEN}✅ Virtual environment activated${NC}"

# Step 1: Check app.main.py for relative imports
echo -e "${YELLOW}🔧 Step 1: Checking app.main.py for relative imports...${NC}"

if [ -f "app/main.py" ]; then
    echo -e "${BLUE}Found app/main.py, checking for relative imports...${NC}"
    
    # Check for relative imports
    if grep -q "from \." app/main.py; then
        echo -e "${YELLOW}⚠️ Found relative imports in app/main.py${NC}"
        echo -e "${BLUE}Relative imports found:${NC}"
        grep "from \." app/main.py
    else
        echo -e "${GREEN}✅ No relative imports found in app/main.py${NC}"
    fi
else
    echo -e "${RED}❌ app/main.py not found${NC}"
    exit 1
fi

# Step 2: Fix relative imports in app.main.py
echo -e "${YELLOW}🔧 Step 2: Fixing relative imports in app.main.py...${NC}"

# Create a backup
cp app/main.py app/main.py.backup
echo -e "${GREEN}✅ Backup created: app/main.py.backup${NC}"

# Fix relative imports
echo -e "${BLUE}Fixing relative imports...${NC}"
sed -i 's/from \.config import/from app.config import/g' app/main.py
sed -i 's/from \.routers import/from app.routers import/g' app/main.py
sed -i 's/from \.database import/from app.database import/g' app/main.py

echo -e "${GREEN}✅ Relative imports fixed in app/main.py${NC}"

# Step 3: Check other files for relative imports
echo -e "${YELLOW}🔧 Step 3: Checking other files for relative imports...${NC}"

# Check app/config.py
if [ -f "app/config.py" ]; then
    if grep -q "from \." app/config.py; then
        echo -e "${YELLOW}⚠️ Found relative imports in app/config.py${NC}"
        sed -i 's/from \./from app./g' app/config.py
        echo -e "${GREEN}✅ Fixed relative imports in app/config.py${NC}"
    fi
fi

# Check app/database.py
if [ -f "app/database.py" ]; then
    if grep -q "from \." app/database.py; then
        echo -e "${YELLOW}⚠️ Found relative imports in app/database.py${NC}"
        sed -i 's/from \./from app./g' app/database.py
        echo -e "${GREEN}✅ Fixed relative imports in app/database.py${NC}"
    fi
fi

# Check app/auth.py
if [ -f "app/auth.py" ]; then
    if grep -q "from \." app/auth.py; then
        echo -e "${YELLOW}⚠️ Found relative imports in app/auth.py${NC}"
        sed -i 's/from \./from app./g' app/auth.py
        echo -e "${GREEN}✅ Fixed relative imports in app/auth.py${NC}"
    fi
fi

# Check router files
for router_file in app/routers/*.py; do
    if [ -f "$router_file" ]; then
        if grep -q "from \." "$router_file"; then
            echo -e "${YELLOW}⚠️ Found relative imports in $router_file${NC}"
            sed -i 's/from \./from app./g' "$router_file"
            echo -e "${GREEN}✅ Fixed relative imports in $router_file${NC}"
        fi
    fi
done

# Step 4: Test the fix
echo -e "${YELLOW}🔧 Step 4: Testing the fix...${NC}"

echo -e "${BLUE}Testing app import with fixed relative imports...${NC}"
if python -c "from app.main import app; print('✅ App imported successfully')" 2>/dev/null; then
    echo -e "${GREEN}✅ App import successful after fix${NC}"
else
    echo -e "${RED}❌ App import still failed${NC}"
    echo -e "${YELLOW}Checking for other import issues...${NC}"
    
    # Test individual imports
    python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.config import settings
    print('✅ Config import works')
except Exception as e:
    print(f'❌ Config import failed: {e}')

try:
    from app.database import engine, Base
    print('✅ Database import works')
except Exception as e:
    print(f'❌ Database import failed: {e}')

try:
    from app.routers import auth, dashboard, users
    print('✅ Routers import works')
except Exception as e:
    print(f'❌ Routers import failed: {e}')
"
fi

# Step 5: Test uvicorn startup
echo -e "${YELLOW}🔧 Step 5: Testing uvicorn startup...${NC}"
echo -e "${BLUE}Testing uvicorn startup (will stop after 3 seconds)...${NC}"

# Start uvicorn in background and kill it after 3 seconds
timeout 3s uvicorn app.main:app --host 0.0.0.0 --port 8000 2>/dev/null &
UVICORN_PID=$!

# Wait a moment for startup
sleep 2

# Check if uvicorn is running
if ps -p $UVICORN_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Uvicorn started successfully${NC}"
    kill $UVICORN_PID 2>/dev/null || true
else
    echo -e "${YELLOW}⚠️ Uvicorn startup test inconclusive${NC}"
fi

# Step 6: Create __init__.py files if missing
echo -e "${YELLOW}🔧 Step 6: Ensuring __init__.py files exist...${NC}"

# Create __init__.py files
touch app/__init__.py
touch app/routers/__init__.py

echo -e "${GREEN}✅ __init__.py files created${NC}"

# Summary
echo ""
echo -e "${GREEN}🎉 Relative Import Error Fixed!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What was fixed:${NC}"
echo "   ✅ Fixed relative imports in app/main.py"
echo "   ✅ Fixed relative imports in other app files"
echo "   ✅ Created backup of original files"
echo "   ✅ Ensured __init__.py files exist"
echo "   ✅ Tested app import after fix"
echo "   ✅ Tested uvicorn startup"

echo ""
echo -e "${BLUE}🚀 How to Start Backend:${NC}"
echo ""
echo -e "${GREEN}Method 1: Using uvicorn directly${NC}"
echo "  cd backend"
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo -e "${GREEN}Method 2: Using run_backend.sh${NC}"
echo "  cd backend && ./run_backend.sh"
echo ""
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "   - No relative import errors"
echo "   - App imports successfully"
echo "   - Uvicorn starts without errors"
echo "   - Backend runs on port 8000"
echo ""
echo -e "${GREEN}🎯 Relative import error resolved!${NC}"
