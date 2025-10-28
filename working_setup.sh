#!/bin/bash
# Working Setup Script - Uses Proven Working Scripts from Main Branch
# This script uses the exact same setup that was working before

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 IDS/IDPS Working Setup (Using Proven Scripts)${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Check if we have the working scripts
echo -e "${YELLOW}🔧 Step 1: Checking for working scripts...${NC}"

WORKING_SCRIPTS=(
    "setup_gui_complete.sh"
    "run_backend.sh"
    "run_gui.sh"
    "setup.sh"
)

MISSING_SCRIPTS=()
for script in "${WORKING_SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        MISSING_SCRIPTS+=("$script")
    fi
done

if [ ${#MISSING_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing working scripts:${NC}"
    for script in "${MISSING_SCRIPTS[@]}"; do
        echo -e "   - $script"
    done
    echo ""
    echo -e "${YELLOW}⚠️ Please ensure you have the working scripts from main branch${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All working scripts found${NC}"

# Make scripts executable
echo -e "${YELLOW}🔧 Step 2: Making scripts executable...${NC}"
chmod +x setup_gui_complete.sh
chmod +x run_backend.sh
chmod +x run_gui.sh
chmod +x setup.sh

echo -e "${GREEN}✅ Scripts made executable${NC}"

# Check if we have the required directories
echo -e "${YELLOW}🔧 Step 3: Checking project structure...${NC}"

REQUIRED_DIRS=(
    "backend"
    "gui"
)

MISSING_DIRS=()
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        MISSING_DIRS+=("$dir")
    fi
done

if [ ${#MISSING_DIRS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required directories:${NC}"
    for dir in "${MISSING_DIRS[@]}"; do
        echo -e "   - $dir"
    done
    echo ""
    echo -e "${YELLOW}⚠️ Please ensure you have the complete project structure${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Project structure verified${NC}"

# Check if we have the required files
echo -e "${YELLOW}🔧 Step 4: Checking required files...${NC}"

REQUIRED_FILES=(
    "backend/app/main.py"
    "gui/main.py"
    "gui/api_client.py"
    "backend/requirements.txt"
    "gui/requirements.txt"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required files:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo -e "   - $file"
    done
    echo ""
    echo -e "${YELLOW}⚠️ Please ensure you have all required files${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All required files found${NC}"

# Verify API client port configuration
echo -e "${YELLOW}🔧 Step 5: Verifying API client configuration...${NC}"
if grep -q "http://localhost:8000" gui/api_client.py; then
    echo -e "${GREEN}✅ API client configured for port 8000${NC}"
else
    echo -e "${RED}❌ API client not configured for port 8000${NC}"
    echo -e "${YELLOW}Fixing API client configuration...${NC}"
    sed -i 's/http:\/\/localhost:3000/http:\/\/localhost:8000/g' gui/api_client.py
    echo -e "${GREEN}✅ API client fixed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Working Setup Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What's available:${NC}"
echo "   ✅ Working setup scripts from main branch"
echo "   ✅ Complete project structure"
echo "   ✅ All required files"
echo "   ✅ API client configured for port 8000"
echo "   ✅ Scripts made executable"

echo ""
echo -e "${BLUE}🚀 Ready to Use!${NC}"
echo "=============================================="
echo ""
echo -e "${GREEN}Option 1 - Complete Setup (Recommended):${NC}"
echo "  ./setup_gui_complete.sh"
echo ""
echo -e "${GREEN}Option 2 - Basic Setup:${NC}"
echo "  ./setup.sh"
echo ""
echo -e "${GREEN}Option 3 - Manual Setup:${NC}"
echo "  # Terminal 1 - Start Backend"
echo "  ./run_backend.sh"
echo ""
echo "  # Terminal 2 - Start GUI"
echo "  ./run_gui.sh"
echo ""
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "   - Backend runs on port 8000"
echo "   - GUI connects successfully"
echo "   - Correct Random Forest metrics displayed"
echo "   - Ready for live traffic testing"
echo ""
echo -e "${GREEN}🎯 Choose your preferred setup method!${NC}"
