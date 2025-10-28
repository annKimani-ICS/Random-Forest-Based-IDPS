#!/bin/bash
# Alternative Backend Startup (No Global Uvicorn Required)
# This script starts the backend without requiring global uvicorn installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Alternative Backend Startup${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/app/main.py" ]; then
    echo -e "${RED}❌ Error: app/main.py not found${NC}"
    echo "Please run this script from the backend directory"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "$PROJECT_DIR/.venv" ]; then
    echo -e "${YELLOW}⚠️ Virtual environment not found. Creating one...${NC}"
    python3 -m venv "$PROJECT_DIR/.venv"
    echo -e "${GREEN}✅ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${BLUE}🔌 Activating virtual environment...${NC}"
source "$PROJECT_DIR/.venv/bin/activate"

# Check if we can import uvicorn
echo -e "${BLUE}📦 Checking uvicorn availability...${NC}"
if python -c "import uvicorn" 2>/dev/null; then
    echo -e "${GREEN}✅ uvicorn is available${NC}"
    UVICORN_CMD="uvicorn"
elif python -m uvicorn --version 2>/dev/null; then
    echo -e "${GREEN}✅ uvicorn available via python -m${NC}"
    UVICORN_CMD="python -m uvicorn"
else
    echo -e "${RED}❌ uvicorn not available${NC}"
    echo -e "${YELLOW}Installing uvicorn...${NC}"
    
    # Try to install uvicorn
    pip install uvicorn[standard]==0.27.0 || pip install uvicorn==0.27.0
    
    if python -c "import uvicorn" 2>/dev/null; then
        echo -e "${GREEN}✅ uvicorn installed successfully${NC}"
        UVICORN_CMD="uvicorn"
    elif python -m uvicorn --version 2>/dev/null; then
        echo -e "${GREEN}✅ uvicorn available via python -m${NC}"
        UVICORN_CMD="python -m uvicorn"
    else
        echo -e "${RED}❌ Failed to install uvicorn${NC}"
        echo -e "${YELLOW}Trying alternative startup method...${NC}"
        
        # Alternative: Use gunicorn or direct FastAPI
        if python -c "import gunicorn" 2>/dev/null; then
            echo -e "${GREEN}✅ Using gunicorn as alternative${NC}"
            gunicorn app.main:app -w 1 -b 0.0.0.0:8000 --reload
            exit 0
        else
            echo -e "${RED}❌ No suitable server found${NC}"
            echo -e "${YELLOW}Please run: ./fix_uvicorn_installation.sh${NC}"
            exit 1
        fi
    fi
fi

# Check if requirements are installed
echo -e "${BLUE}📦 Checking other dependencies...${NC}"
if ! python -c "import fastapi" 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Dependencies not installed. Installing...${NC}"
    pip install -r requirements.txt
    echo -e "${GREEN}✅ Dependencies installed${NC}"
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️ .env file not found. Creating one...${NC}"
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
    echo -e "${GREEN}✅ .env file created${NC}"
fi

# Start the backend server
echo -e "${GREEN}🌟 Starting FastAPI backend server...${NC}"
echo "Server will be available at: http://localhost:8000"
echo "API documentation: http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo "=================================="

# Start uvicorn with the determined command
if [ "$UVICORN_CMD" = "uvicorn" ]; then
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
else
    python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
fi
