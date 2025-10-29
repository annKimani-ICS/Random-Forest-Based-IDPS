#!/bin/bash
# Fix git pull conflict with untracked files

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing Git Pull Conflict${NC}"
echo "=================================="

# Get script directory (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo -e "${YELLOW}Checking for conflicting untracked files...${NC}"

# Check if backend/fix_ddos_only.sh exists
if [ -f "backend/fix_ddos_only.sh" ]; then
    echo -e "${YELLOW}⚠️  Found: backend/fix_ddos_only.sh${NC}"
    echo -e "${BLUE}This file was replaced by integrated fixes in setup.py${NC}"
    
    # Backup the file just in case
    if [ ! -f "backend/fix_ddos_only.sh.backup" ]; then
        echo -e "${BLUE}Creating backup...${NC}"
        cp "backend/fix_ddos_only.sh" "backend/fix_ddos_only.sh.backup"
    fi
    
    # Remove the conflicting file
    echo -e "${YELLOW}Removing conflicting file...${NC}"
    rm -f "backend/fix_ddos_only.sh"
    echo -e "${GREEN}✅ Removed backend/fix_ddos_only.sh${NC}"
fi

# Check for any other untracked files that might conflict
echo ""
echo -e "${BLUE}Checking for other potential conflicts...${NC}"
CONFLICTING_FILES=$(git status --porcelain | grep "^??" | awk '{print $2}' || true)

if [ -z "$CONFLICTING_FILES" ]; then
    echo -e "${GREEN}✅ No untracked files found${NC}"
else
    echo -e "${YELLOW}Found untracked files:${NC}"
    echo "$CONFLICTING_FILES" | while read file; do
        echo "  - $file"
    done
fi

echo ""
echo -e "${BLUE}Attempting git pull...${NC}"
if git pull origin feat/sprint4-admin-dashboard; then
    echo ""
    echo -e "${GREEN}✅ Successfully pulled latest changes!${NC}"
    echo ""
    echo -e "${BLUE}Latest changes include:${NC}"
    echo "  ✅ Security fixes (no hardcoded secrets)"
    echo "  ✅ Environment variable support for passwords"
    echo "  ✅ Updated .gitignore"
    echo "  ✅ SECURITY.md documentation"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Review SECURITY.md for security guidelines"
    echo "  2. Copy backend/.env.example to backend/.env"
    echo "  3. Set ADMIN_PASSWORD and ANALYST_PASSWORD in backend/.env"
    echo "  4. Run: cd backend && python3 setup.py"
else
    echo ""
    echo -e "${RED}❌ Git pull failed${NC}"
    echo -e "${YELLOW}Please resolve conflicts manually:${NC}"
    echo "  1. Check git status: git status"
    echo "  2. Remove or commit conflicting files"
    echo "  3. Try again: git pull origin feat/sprint4-admin-dashboard"
    exit 1
fi

