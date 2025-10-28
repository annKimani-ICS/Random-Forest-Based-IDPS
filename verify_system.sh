#!/bin/bash
# Comprehensive System Verification Script
# This script checks for all potential errors and issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔍 Comprehensive System Verification${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}📁 Project directory: $PROJECT_DIR${NC}"

# Initialize counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Function to run check
run_check() {
    local check_name="$1"
    local check_command="$2"
    local is_critical="${3:-true}"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "Checking $check_name... "
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        if [ "$is_critical" = "true" ]; then
            echo -e "${RED}✗${NC}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        else
            echo -e "${YELLOW}⚠${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. GIT AND BRANCH VERIFICATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_check "Git repository status" "git status"
run_check "Correct branch (sprint4-admin-dashboard)" "git branch --show-current | grep -q 'feat/sprint4-admin-dashboard'"
run_check "Branch is up to date" "git status | grep -q 'up to date'"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. FILE STRUCTURE VERIFICATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_check "Backend directory exists" "test -d backend"
run_check "GUI directory exists" "test -d gui"
run_check "Backend main.py exists" "test -f backend/app/main.py"
run_check "GUI main.py exists" "test -f gui/main.py"
run_check "API client exists" "test -f gui/api_client.py"
run_check "Requirements files exist" "test -f backend/requirements.txt && test -f gui/requirements.txt"
run_check "Automated fix script exists" "test -f automated_fix_sprint4.sh"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. CONFIGURATION VERIFICATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_check "API client connects to port 8000" "grep -q 'http://localhost:8000' gui/api_client.py"
run_check "Backend main.py imports correct modules" "grep -q 'from fastapi import FastAPI' backend/app/main.py"
run_check "Backend includes all routers" "grep -q 'app.include_router' backend/app/main.py"
run_check "GUI main.py imports PyQt5" "grep -q 'from PyQt5' gui/main.py"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. DEPENDENCIES VERIFICATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_check "Backend requirements.txt has FastAPI" "grep -q 'fastapi' backend/requirements.txt"
run_check "Backend requirements.txt has uvicorn" "grep -q 'uvicorn' backend/requirements.txt"
run_check "Backend requirements.txt has SQLAlchemy" "grep -q 'sqlalchemy' backend/requirements.txt"
run_check "Backend requirements.txt has psycopg2" "grep -q 'psycopg2' backend/requirements.txt"
run_check "GUI requirements.txt has PyQt5" "grep -q 'PyQt5' gui/requirements.txt"
run_check "GUI requirements.txt has requests" "grep -q 'requests' gui/requirements.txt"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. SYSTEM REQUIREMENTS VERIFICATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_check "Python3 is available" "command -v python3"
run_check "pip3 is available" "command -v pip3"
run_check "PostgreSQL is available" "command -v psql"
run_check "Git is available" "command -v git"
run_check "curl is available" "command -v curl"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. SCRIPT PERMISSIONS VERIFICATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_check "Automated fix script is executable" "test -x automated_fix_sprint4.sh" "false"
run_check "Backend setup script is executable" "test -x backend/setup_ubuntu.sh" "false"
run_check "GUI run script is executable" "test -x gui/run_gui.sh" "false"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}7. POTENTIAL ISSUE DETECTION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check for hardcoded ports
echo -n "Checking for hardcoded port issues... "
if grep -r "localhost:3000" . --exclude-dir=.git > /dev/null 2>&1; then
    echo -e "${RED}✗ Found hardcoded port 3000${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
    echo -e "${GREEN}✓ No hardcoded port 3000 found${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# Check for missing imports
echo -n "Checking for missing imports... "
if grep -q "from app" backend/app/main.py && grep -q "from PyQt5" gui/main.py; then
    echo -e "${GREEN}✓ All imports look correct${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ Missing critical imports${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# Check for database configuration issues
echo -n "Checking database configuration... "
if grep -q "DATABASE_URL" backend/app/config.py; then
    echo -e "${GREEN}✓ Database configuration present${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ Database configuration missing${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# Check for CORS configuration
echo -n "Checking CORS configuration... "
if grep -q "CORS_ORIGINS" backend/app/config.py; then
    echo -e "${GREEN}✓ CORS configuration present${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ CORS configuration missing${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}8. SUMMARY${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${BLUE}📊 Verification Results:${NC}"
echo -e "   Total Checks: $TOTAL_CHECKS"
echo -e "   ${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "   ${RED}Failed: $FAILED_CHECKS${NC}"
echo -e "   ${YELLOW}Warnings: $WARNINGS${NC}"

echo ""
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ ALL CRITICAL CHECKS PASSED!${NC}"
    echo -e "${GREEN}🎉 System is ready for live traffic testing!${NC}"
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $WARNINGS warnings found (non-critical)${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "   1. Run: ./automated_fix_sprint4.sh"
    echo "   2. Start backend: cd backend && ./start_backend.sh"
    echo "   3. Start GUI: cd gui && ./start_gui.sh"
    echo "   4. Begin live traffic testing!"
    
else
    echo -e "${RED}❌ $FAILED_CHECKS critical issues found!${NC}"
    echo -e "${YELLOW}⚠️  Please fix these issues before proceeding${NC}"
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Also $WARNINGS warnings found${NC}"
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 Automated Fix Available${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}If issues are found, run the automated fix:${NC}"
echo -e "  chmod +x automated_fix_sprint4.sh"
echo -e "  ./automated_fix_sprint4.sh"
echo ""
echo -e "${GREEN}This will fix all known issues automatically!${NC}"
