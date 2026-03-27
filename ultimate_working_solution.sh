#!/bin/bash
# Ultimate Working Solution - Uses Exact Files from Main Branch
# This script copies the exact working files from main branch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🎯 Ultimate Working Solution${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Step 1: Copy exact working files from main branch
echo -e "${YELLOW}🔧 Step 1: Copying exact working files from main branch...${NC}"

# Copy the exact working files from main branch
git checkout main -- setup_gui_complete.sh
git checkout main -- run_backend.sh
git checkout main -- run_gui.sh
git checkout main -- setup.sh
git checkout main -- gui/api_client.py
git checkout main -- backend/seed_data.py

echo -e "${GREEN}✅ Working files copied from main branch${NC}"

# Step 2: Make scripts executable
echo -e "${YELLOW}🔧 Step 2: Making scripts executable...${NC}"
chmod +x setup_gui_complete.sh
chmod +x run_backend.sh
chmod +x run_gui.sh
chmod +x setup.sh

echo -e "${GREEN}✅ Scripts made executable${NC}"

# Step 3: Verify the working configuration
echo -e "${YELLOW}🔧 Step 3: Verifying working configuration...${NC}"

# Check API client port
if grep -q "http://localhost:8000" gui/api_client.py; then
    echo -e "${GREEN}✅ API client configured for port 8000${NC}"
else
    echo -e "${RED}❌ API client not configured correctly${NC}"
    exit 1
fi

# Check if working scripts exist
WORKING_SCRIPTS=(
    "setup_gui_complete.sh"
    "run_backend.sh"
    "run_gui.sh"
    "setup.sh"
)

for script in "${WORKING_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo -e "${GREEN}✅ $script found${NC}"
    else
        echo -e "${RED}❌ $script missing${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ All working files verified${NC}"

# Step 4: Create a simple working setup script
echo -e "${YELLOW}🔧 Step 4: Creating simple working setup script...${NC}"

cat > WORKING_SETUP.sh << 'EOF'
#!/bin/bash
# Simple Working Setup - Uses Proven Working Scripts

echo "🚀 IDS/IDPS Working Setup"
echo "========================"

echo "📋 Available setup options:"
echo ""
echo "1. Complete Setup (Recommended):"
echo "   ./setup_gui_complete.sh"
echo ""
echo "2. Basic Setup:"
echo "   ./setup.sh"
echo ""
echo "3. Manual Setup:"
echo "   # Terminal 1 - Start Backend"
echo "   ./run_backend.sh"
echo ""
echo "   # Terminal 2 - Start GUI"
echo "   ./run_gui.sh"
echo ""

read -p "Choose setup option (1-3): " choice

case $choice in
    1)
        echo "🚀 Running complete setup..."
        ./setup_gui_complete.sh
        ;;
    2)
        echo "🚀 Running basic setup..."
        ./setup.sh
        ;;
    3)
        echo "🚀 Manual setup selected"
        echo "Please run the commands in separate terminals"
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac
EOF

chmod +x WORKING_SETUP.sh

echo -e "${GREEN}✅ Working setup script created${NC}"

# Summary
echo ""
echo -e "${GREEN}🎉 Ultimate Working Solution Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What was restored:${NC}"
echo "   ✅ Exact working files from main branch"
echo "   ✅ setup_gui_complete.sh (proven working)"
echo "   ✅ run_backend.sh (proven working)"
echo "   ✅ run_gui.sh (proven working)"
echo "   ✅ setup.sh (proven working)"
echo "   ✅ GUI API client (port 8000)"
echo "   ✅ Backend seed_data.py (working)"
echo "   ✅ All scripts made executable"

echo ""
echo -e "${BLUE}🚀 Ready to Use!${NC}"
echo "=============================================="
echo ""
echo -e "${GREEN}Quick Start:${NC}"
echo "  ./WORKING_SETUP.sh"
echo ""
echo -e "${GREEN}Or run directly:${NC}"
echo "  ./setup_gui_complete.sh"
echo ""
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "   - Backend runs on port 8000"
echo "   - GUI connects successfully"
echo "   - Correct Random Forest metrics displayed"
echo "   - Ready for live traffic testing"
echo ""
echo -e "${GREEN}🎯 This uses the exact same files that were working!${NC}"

