#!/bin/bash
# Cleanup temporary fix scripts
# Removes all temporary .sh fix scripts, keeping only essential files

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧹 Cleaning up temporary fix scripts${NC}"
echo "=============================================="

# Get project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# List of temporary fix scripts to remove (from backend/)
TEMPORARY_SCRIPTS=(
    "backend/fix_pydantic.sh"
    "backend/fix_db_connection.sh"
    "backend/fix_metrics.sh"
    "backend/fix_ddos_only.sh"
    "backend/comprehensive_db_fix.sh"
    "backend/final_auth_fix.sh"
    "backend/simple_postgres_fix.sh"
    "backend/ultimate_user_drop_fix.sh"
    "backend/setup_backend.sh"  # Replaced by setup.py
    "backend/fix_migrations.sh"
    "backend/fix_auth.sh"
    "backend/simple_working_setup.sh"
    "backend/simple_setup.sh"
    "backend/auto_setup.sh"
)

# List of scripts to keep
KEEP_SCRIPTS=(
    "backend/run_backend.sh"
    "backend/setup.py"
    "backend/update_model_db.py"
    "backend/add_dummy_alerts.py"
    "backend/test_fixes.py"
    "backend/create_users.py"
    "run_gui.sh"
)

echo -e "${BLUE}📋 Temporary scripts to remove:${NC}"
for script in "${TEMPORARY_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  - $script"
    fi
done

echo ""
echo -e "${BLUE}📋 Essential scripts to keep:${NC}"
for script in "${KEEP_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  ✅ $script"
    fi
done

echo ""
read -p "Remove temporary fix scripts? (y/n): " response

if [ "$response" = "y" ]; then
    removed=0
    for script in "${TEMPORARY_SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            rm "$script"
            echo -e "${GREEN}✅ Removed $script${NC}"
            removed=$((removed + 1))
        fi
    done
    
    echo ""
    echo -e "${GREEN}🎉 Cleanup complete!${NC}"
    echo "   Removed $removed temporary scripts"
    echo "   All fixes are now integrated in main code"
else
    echo "Cleanup cancelled"
fi

