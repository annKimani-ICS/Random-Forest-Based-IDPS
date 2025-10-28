#!/bin/bash
# Download Project Files Without Git
# This script downloads all necessary files from GitHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📥 Downloading IDS/IDPS Project Files${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Check if wget is available
if ! command -v wget &> /dev/null; then
    echo -e "${RED}❌ wget not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y wget unzip
fi

# Check if unzip is available
if ! command -v unzip &> /dev/null; then
    echo -e "${RED}❌ unzip not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y unzip
fi

# Download the project files
echo -e "${YELLOW}🔧 Downloading project files from GitHub...${NC}"

# Download the zip file
wget -O project.zip "https://github.com/annKimani-ICS/Random-Forest-Based-IDPS/archive/refs/heads/feat/sprint4-admin-dashboard.zip"

echo -e "${GREEN}✅ Project files downloaded${NC}"

# Extract the files
echo -e "${YELLOW}🔧 Extracting project files...${NC}"
unzip project.zip

# Move files to current directory
echo -e "${YELLOW}🔧 Moving files to current directory...${NC}"
mv Random-Forest-Based-IDPS-feat-sprint4-admin-dashboard/* .
mv Random-Forest-Based-IDPS-feat-sprint4-admin-dashboard/.* . 2>/dev/null || true

# Clean up
rm -rf Random-Forest-Based-IDPS-feat-sprint4-admin-dashboard project.zip

echo -e "${GREEN}✅ Project files extracted and organized${NC}"

# Make scripts executable
echo -e "${YELLOW}🔧 Making scripts executable...${NC}"
chmod +x simple_setup_no_git.sh 2>/dev/null || true
chmod +x automated_fix_sprint4.sh 2>/dev/null || true
chmod +x fix_git_repo.sh 2>/dev/null || true

echo -e "${GREEN}✅ Scripts made executable${NC}"

# Verify essential files
echo -e "${YELLOW}🔧 Verifying essential files...${NC}"

ESSENTIAL_FILES=(
    "backend/app/main.py"
    "gui/main.py"
    "gui/api_client.py"
    "backend/requirements.txt"
    "gui/requirements.txt"
    "simple_setup_no_git.sh"
)

ALL_FILES_PRESENT=true
for file in "${ESSENTIAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ✅ $file"
    else
        echo -e "   ❌ $file (missing)"
        ALL_FILES_PRESENT=false
    fi
done

if [ "$ALL_FILES_PRESENT" = true ]; then
    echo -e "${GREEN}✅ All essential files present${NC}"
else
    echo -e "${RED}❌ Some files are missing${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Project files downloaded successfully!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo "   1. Run: chmod +x simple_setup_no_git.sh"
echo "   2. Run: ./simple_setup_no_git.sh"
echo "   3. Follow the setup instructions"
echo ""
echo -e "${YELLOW}📋 What this provides:${NC}"
echo "   - Complete project files"
echo "   - No git repository required"
echo "   - Automated setup script"
echo "   - Ready for live traffic testing"
echo ""
echo -e "${GREEN}🎯 Ready to setup the system!${NC}"
