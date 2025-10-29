#!/bin/bash
# FastAPI Import Diagnostic Script
# This script diagnoses why FastAPI import is failing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 FastAPI Import Diagnostic${NC}"
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

echo -e "${BLUE}🔍 Diagnostic Information:${NC}"
echo "=================================="

# Check Python version
echo -e "${YELLOW}Python Version:${NC}"
python --version

# Check pip version
echo -e "${YELLOW}Pip Version:${NC}"
pip --version

# Check installed packages
echo -e "${YELLOW}Installed Packages:${NC}"
pip list | grep -E "(fastapi|pydantic|uvicorn|starlette)" || echo "No relevant packages found"

# Check FastAPI installation
echo -e "${YELLOW}FastAPI Installation:${NC}"
pip show fastapi || echo "FastAPI not installed"

# Check Pydantic installation
echo -e "${YELLOW}Pydantic Installation:${NC}"
pip show pydantic || echo "Pydantic not installed"

# Test individual imports
echo -e "${YELLOW}Testing Individual Imports:${NC}"
echo ""

# Test Pydantic
echo -e "${BLUE}Testing Pydantic...${NC}"
python -c "
try:
    import pydantic
    print('✅ Pydantic imported')
    print(f'   Version: {pydantic.__version__}')
    from pydantic import BaseModel
    print('✅ BaseModel imported')
except Exception as e:
    print(f'❌ Pydantic error: {e}')
"

# Test Starlette
echo -e "${BLUE}Testing Starlette...${NC}"
python -c "
try:
    import starlette
    print('✅ Starlette imported')
    print(f'   Version: {starlette.__version__}')
except Exception as e:
    print(f'❌ Starlette error: {e}')
"

# Test FastAPI
echo -e "${BLUE}Testing FastAPI...${NC}"
python -c "
try:
    import fastapi
    print('✅ FastAPI imported')
    print(f'   Version: {fastapi.__version__}')
    from fastapi import FastAPI
    print('✅ FastAPI class imported')
    from fastapi import Request, status
    print('✅ FastAPI Request, status imported')
    from fastapi.middleware.cors import CORSMiddleware
    print('✅ CORS middleware imported')
    from fastapi.responses import JSONResponse
    print('✅ JSONResponse imported')
except Exception as e:
    print(f'❌ FastAPI error: {e}')
    import traceback
    traceback.print_exc()
"

# Test SlowAPI
echo -e "${BLUE}Testing SlowAPI...${NC}"
python -c "
try:
    import slowapi
    print('✅ SlowAPI imported')
    from slowapi import Limiter, _rate_limit_exceeded_handler
    print('✅ SlowAPI Limiter imported')
    from slowapi.util import get_remote_address
    print('✅ SlowAPI util imported')
    from slowapi.errors import RateLimitExceeded
    print('✅ SlowAPI errors imported')
except Exception as e:
    print(f'❌ SlowAPI error: {e}')
"

# Test app imports
echo -e "${BLUE}Testing App Imports...${NC}"
python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.config import settings
    print('✅ Config imported')
except Exception as e:
    print(f'❌ Config error: {e}')

try:
    from app.database import engine, Base
    print('✅ Database imported')
except Exception as e:
    print(f'❌ Database error: {e}')

try:
    from app.routers import auth, dashboard, users
    print('✅ Routers imported')
except Exception as e:
    print(f'❌ Routers error: {e}')
"

# Test complete app import
echo -e "${BLUE}Testing Complete App Import...${NC}"
python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.main import app
    print('✅ Complete app imported successfully')
    print(f'   App type: {type(app)}')
except Exception as e:
    print(f'❌ Complete app import error: {e}')
    import traceback
    traceback.print_exc()
"

# Check for conflicting packages
echo -e "${YELLOW}Checking for Conflicting Packages:${NC}"
pip list | grep -E "(pydantic|fastapi)" | head -10

# Check Python path
echo -e "${YELLOW}Python Path:${NC}"
python -c "import sys; print('\\n'.join(sys.path))"

# Summary
echo ""
echo -e "${BLUE}🔍 Diagnostic Complete${NC}"
echo "=================================="
echo -e "${YELLOW}If FastAPI import failed, try:${NC}"
echo "  1. ./complete_fastapi_fix.sh"
echo "  2. pip uninstall fastapi pydantic"
echo "  3. pip install 'pydantic<2.0.0' fastapi==0.109.0"
echo ""
echo -e "${GREEN}🎯 Run this diagnostic to identify the exact issue!${NC}"
