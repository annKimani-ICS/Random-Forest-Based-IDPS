#!/bin/bash
# Fix for Git Repository Issue
# This script handles the case where the repository wasn't cloned properly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔧 Git Repository Fix Script${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Check if we're in the right directory
if [[ "$CURRENT_DIR" != *"Random-Forest-Based-IDPS"* ]]; then
    echo -e "${RED}❌ Error: Not in Random-Forest-Based-IDPS directory${NC}"
    echo -e "${YELLOW}Please navigate to the correct directory first${NC}"
    exit 1
fi

# Check if .git directory exists
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️ Git repository not found. Cloning repository...${NC}"
    
    # Move up one directory
    cd ..
    
    # Remove existing directory if it exists
    if [ -d "Random-Forest-Based-IDPS" ]; then
        echo -e "${YELLOW}Removing existing directory...${NC}"
        rm -rf Random-Forest-Based-IDPS
    fi
    
    # Clone the repository
    echo -e "${BLUE}Cloning repository from GitHub...${NC}"
    git clone https://github.com/annKimani-ICS/Random-Forest-Based-IDPS.git
    
    # Navigate to the cloned directory
    cd Random-Forest-Based-IDPS
    
    # Checkout the correct branch
    echo -e "${BLUE}Checking out sprint4-admin-dashboard branch...${NC}"
    git checkout feat/sprint4-admin-dashboard
    
    echo -e "${GREEN}✅ Repository cloned successfully!${NC}"
else
    echo -e "${GREEN}✅ Git repository found${NC}"
    
    # Check if we're on the correct branch
    CURRENT_BRANCH=$(git branch --show-current)
    echo -e "${BLUE}Current branch: $CURRENT_BRANCH${NC}"
    
    if [ "$CURRENT_BRANCH" != "feat/sprint4-admin-dashboard" ]; then
        echo -e "${YELLOW}Switching to sprint4-admin-dashboard branch...${NC}"
        git checkout feat/sprint4-admin-dashboard
    fi
    
    # Pull latest changes
    echo -e "${BLUE}Pulling latest changes...${NC}"
    git pull origin feat/sprint4-admin-dashboard
fi

# Verify we're in the right place
echo -e "${BLUE}📁 Final directory: $(pwd)${NC}"
echo -e "${BLUE}🌿 Current branch: $(git branch --show-current)${NC}"

# Check if automated fix script exists
if [ -f "automated_fix_sprint4.sh" ]; then
    echo -e "${GREEN}✅ Automated fix script found${NC}"
    
    # Make it executable
    chmod +x automated_fix_sprint4.sh
    
    echo -e "${GREEN}🎉 Ready to run automated fix!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Run: ./automated_fix_sprint4.sh"
    echo "  2. Follow the setup instructions"
    echo ""
    echo -e "${YELLOW}Would you like to run the automated fix now? (y/N)${NC}"
    read -p "" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}🚀 Running automated fix...${NC}"
        ./automated_fix_sprint4.sh
    else
        echo -e "${BLUE}You can run it later with: ./automated_fix_sprint4.sh${NC}"
    fi
else
    echo -e "${RED}❌ Automated fix script not found${NC}"
    echo -e "${YELLOW}Please ensure you're on the correct branch${NC}"
fi

echo ""
echo -e "${GREEN}🎯 Git repository issue resolved!${NC}"
