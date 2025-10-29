#!/bin/bash
# Complete setup and testing script for Ubuntu VM
# This resolves conflicts, pulls changes, sets up environment, and prepares for testing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║       Complete VM Setup & Testing Script                 ║
║       Resolves conflicts + Pulls + Sets up + Tests         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get script directory (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}STEP 1: Resolving Git Conflicts${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check current git status
echo -e "${YELLOW}Checking current git status...${NC}"
git status --short || true

# List all untracked files that might conflict
echo ""
echo -e "${YELLOW}Checking for conflicting untracked files...${NC}"
CONFLICTING_FILES=()

# Known conflicting files
if [ -f "backend/fix_ddos_only.sh" ]; then
    CONFLICTING_FILES+=("backend/fix_ddos_only.sh")
fi

# Check git status for untracked files that exist in remote
UNTRACKED=$(git status --porcelain | grep "^??" | awk '{print $2}' || true)

if [ ! -z "$UNTRACKED" ]; then
    while IFS= read -r file; do
        # Check if this file exists in the remote branch
        if git ls-tree -r origin/feat/sprint4-admin-dashboard --name-only | grep -q "^${file}$"; then
            CONFLICTING_FILES+=("$file")
        fi
    done <<< "$UNTRACKED"
fi

# Remove conflicting files
if [ ${#CONFLICTING_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found ${#CONFLICTING_FILES[@]} conflicting file(s):${NC}"
    for file in "${CONFLICTING_FILES[@]}"; do
        echo -e "   - ${file}"
        if [ -f "$file" ]; then
            # Create backup
            if [ ! -f "${file}.backup" ]; then
                echo -e "${BLUE}   Creating backup: ${file}.backup${NC}"
                cp "$file" "${file}.backup"
            fi
            # Remove file
            rm -f "$file"
            echo -e "${GREEN}   ✅ Removed: ${file}${NC}"
        fi
    done
else
    echo -e "${GREEN}✅ No conflicting files found${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}STEP 2: Pulling Latest Changes${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Fetch latest changes
echo -e "${BLUE}Fetching latest changes from remote...${NC}"
git fetch origin feat/sprint4-admin-dashboard

# Check if we're on the right branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
echo -e "${BLUE}Current branch: ${CURRENT_BRANCH}${NC}"

if [ "$CURRENT_BRANCH" != "feat/sprint4-admin-dashboard" ]; then
    echo -e "${YELLOW}⚠️  Not on feat/sprint4-admin-dashboard branch${NC}"
    read -p "Switch to feat/sprint4-admin-dashboard? [Y/n]: " SWITCH
    if [[ ! $SWITCH =~ ^[Nn]$ ]]; then
        git checkout feat/sprint4-admin-dashboard 2>/dev/null || git checkout -b feat/sprint4-admin-dashboard origin/feat/sprint4-admin-dashboard
    fi
fi

# Pull changes
echo ""
echo -e "${BLUE}Pulling latest changes...${NC}"
if git pull origin feat/sprint4-admin-dashboard; then
    echo -e "${GREEN}✅ Successfully pulled latest changes!${NC}"
else
    echo -e "${RED}❌ Git pull failed${NC}"
    echo -e "${YELLOW}Please resolve conflicts manually and try again${NC}"
    echo ""
    echo "Check status: git status"
    echo "View conflicts: git diff"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}STEP 3: Setting Up Environment Variables${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd backend

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found${NC}"
    
    if [ -f ".env.example" ]; then
        echo -e "${BLUE}Copying .env.example to .env...${NC}"
        cp .env.example .env
        echo -e "${GREEN}✅ Created .env from .env.example${NC}"
    else
        echo -e "${YELLOW}⚠️  .env.example not found. Creating default .env...${NC}"
        cat > .env << 'ENVFILE'
# Database Configuration
DATABASE_URL=postgresql+psycopg2://postgres@localhost:5432/ids_idps_db

# JWT Configuration (REQUIRED - generate secure secret)
JWT_SECRET=REPLACE_WITH_SECURE_SECRET
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS

# CORS Configuration
CORS_ORIGINS=http://localhost:5173,http://localhost:8000

# Rate Limiting
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5

# User Passwords (Optional - will be auto-generated if not set)
ADMIN_PASSWORD=
ANALYST_PASSWORD=
ENVFILE
        echo -e "${GREEN}✅ Created default .env${NC}"
    fi
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Generate JWT_SECRET if it's still the placeholder
if grep -q "REPLACE_WITH_SECURE_SECRET" .env 2>/dev/null || ! grep -q "^JWT_SECRET=" .env 2>/dev/null; then
    echo -e "${YELLOW}⚠️  JWT_SECRET needs to be set${NC}"
    JWT_SECRET=$(openssl rand -hex 32 2>/dev/null || python3 -c "import secrets; print(secrets.token_hex(32))")
    
    # Update JWT_SECRET in .env
    if grep -q "^JWT_SECRET=" .env; then
        sed -i "s|^JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET}|" .env
    else
        echo "JWT_SECRET=${JWT_SECRET}" >> .env
    fi
    echo -e "${GREEN}✅ Generated and set JWT_SECRET${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}STEP 4: Installing Dependencies${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create virtual environment if needed
if [ ! -d ".venv" ]; then
    echo -e "${BLUE}Creating virtual environment...${NC}"
    python3 -m venv .venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${BLUE}Activating virtual environment...${NC}"
source .venv/bin/activate

# Install/upgrade dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
echo -e "${GREEN}✅ Dependencies installed${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}STEP 5: Setting Up Database and System${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Run setup.py
echo -e "${BLUE}Running automated setup...${NC}"
echo -e "${YELLOW}This will:${NC}"
echo "  • Set up PostgreSQL database"
echo "  • Create database tables"
echo "  • Create admin and analyst users"
echo "  • Populate model metrics"
echo ""

if python3 setup.py; then
    echo -e "${GREEN}✅ Setup completed successfully!${NC}"
else
    echo -e "${RED}❌ Setup failed${NC}"
    echo -e "${YELLOW}Check the error messages above and resolve any issues${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}STEP 6: Verification & Testing${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd ..

# Run test_fixes.py if it exists
if [ -f "backend/test_fixes.py" ]; then
    echo -e "${BLUE}Running comprehensive tests...${NC}"
    cd backend
    source .venv/bin/activate
    if python3 test_fixes.py; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Review the output above${NC}"
    fi
    cd ..
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ SETUP COMPLETE!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}📋 What's New in This Version:${NC}"
echo ""
echo "  ✅ Security fixes - No hardcoded secrets"
echo "  ✅ Environment variable support for passwords"
echo "  ✅ Enhanced .gitignore for credential files"
echo "  ✅ SECURITY.md documentation"
echo "  ✅ Integrated all fixes into main codebase"
echo "  ✅ Comprehensive setup.py script"
echo "  ✅ Test suite (test_fixes.py)"
echo ""

echo -e "${BLUE}🔐 Login Credentials:${NC}"
echo ""
echo "Check your .env file or the output above for generated passwords"
echo "Default emails:"
echo "  • Admin: admin@ids-idps.com"
echo "  • Analyst: analyst@ids-idps.com"
echo ""

echo -e "${BLUE}🧪 Testing Checklist:${NC}"
echo ""
echo "  [ ] Start backend: cd backend && source .venv/bin/activate && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
echo "  [ ] Test GUI login with admin credentials"
echo "  [ ] Test GUI login with analyst credentials"
echo "  [ ] Verify performance metrics are accurate (90.48% accuracy)"
echo "  [ ] Verify training date is October 15, 2025"
echo "  [ ] Verify all alerts are DDoS type only"
echo "  [ ] Test dashboard functionality"
echo "  [ ] Verify no secrets in source code (GitGuardian scan)"
echo ""

echo -e "${BLUE}🚀 Next Steps:${NC}"
echo ""
echo "  1. Start the backend server"
echo "  2. Launch the GUI"
echo "  3. Test all functionality"
echo "  4. If everything works, create your Pull Request!"
echo ""

echo -e "${GREEN}All done! You're ready to test. 🎉${NC}"

