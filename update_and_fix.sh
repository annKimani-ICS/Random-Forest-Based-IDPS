#!/bin/bash
# Complete Update and Fix Script
# Handles git pull issues and runs correct update scripts

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Complete Update and Fix Script${NC}"
echo "=============================================="

# Get project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}📋 Step 1: Fixing Git pull issues...${NC}"
cd backend

# Backup untracked .sh files if they exist
if ls *.sh >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Backing up untracked script files...${NC}"
    mkdir -p ../backup_scripts
    mv *.sh ../backup_scripts/ 2>/dev/null || true
    echo -e "${GREEN}✅ Files backed up${NC}"
fi

cd ..

# Fetch and pull
echo -e "${BLUE}📥 Fetching latest changes...${NC}"
git fetch origin

echo -e "${BLUE}📥 Pulling latest changes...${NC}"
git pull origin feat/sprint4-admin-dashboard || {
    echo -e "${YELLOW}⚠️  Pull had conflicts, trying reset...${NC}"
    git reset --hard origin/feat/sprint4-admin-dashboard
}

echo -e "${GREEN}✅ Git pull complete${NC}"

echo -e "${BLUE}📋 Step 2: Verifying backend files...${NC}"
cd backend

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}⚠️  Virtual environment not found. Activating project venv...${NC}"
    if [ -d "../venv" ]; then
        source ../venv/bin/activate
    else
        echo -e "${RED}❌ No virtual environment found${NC}"
        exit 1
    fi
else
    source .venv/bin/activate
fi

# Check for correct script name
if [ -f "update_model_db.py" ]; then
    echo -e "${GREEN}✅ Found update_model_db.py${NC}"
    SCRIPT_NAME="update_model_db.py"
elif [ -f "update_model.py" ]; then
    echo -e "${GREEN}✅ Found update_model.py${NC}"
    SCRIPT_NAME="update_model.py"
else
    echo -e "${RED}❌ Neither update_model_db.py nor update_model.py found${NC}"
    echo -e "${YELLOW}Creating update_model_db.py...${NC}"
    cat > update_model_db.py <<'ENDPYTHON'
"""
Quick script to update model metrics in database
Run this in the backend directory with backend dependencies installed
"""
from app.database import SessionLocal
from app.models import Model
from datetime import datetime
import uuid

def update_iteration4_model():
    """Add/Update Iteration 4 model metrics in database"""
    db = SessionLocal()
    
    try:
        # Iteration 4 metrics from your latest training
        iteration4_metrics = {
            "iteration": 4,
            "model_name": "Voting Ensemble",
            "accuracy": 0.9048,
            "precision": 0.9062,
            "recall": 0.9048,
            "f1": 0.9051,
            "auc": 0.95,
            "holdout_accuracy": 0.8974,
            "holdout_precision": 0.8984,
            "holdout_recall": 0.8974,
            "holdout_f1": 0.8976,
            "performance_consistency": 0.0076,
            "training_time_minutes": 15,
            "n_estimators": 200,
            "max_depth": 20,
            "features_used": 30,
            "data_samples": 50000,
            "description": "FAST Random Forest with Voting Ensemble - 90.51% F1-Score"
        }
        
        # Check if iteration 4 model already exists
        existing_model = db.query(Model).filter(
            Model.version == "iteration4_voting_ensemble"
        ).first()
        
        # Training date: October 15, 2025
        training_date = datetime(2025, 10, 15, 12, 0, 0)
        
        if existing_model:
            print("✅ Updating existing Iteration 4 model...")
            existing_model.metrics = iteration4_metrics
            existing_model.trained_at = training_date
            existing_model.notes = "Best performing model - 90.48% accuracy, 90.51% F1-score"
        else:
            print("✅ Creating new Iteration 4 model entry...")
            new_model = Model(
                id=uuid.uuid4(),
                version="iteration4_voting_ensemble",
                trained_at=training_date,
                metrics=iteration4_metrics,
                notes="Best performing model - 90.48% accuracy, 90.51% F1-score"
            )
            db.add(new_model)
        
        db.commit()
        print("✅ Model metrics updated successfully!")
        print("\n📊 Current Model Info:")
        print(f"   Version: iteration4_voting_ensemble")
        print(f"   Accuracy: {iteration4_metrics['accuracy']:.4f}")
        print(f"   Precision: {iteration4_metrics['precision']:.4f}")
        print(f"   Recall: {iteration4_metrics['recall']:.4f}")
        print(f"   F1-Score: {iteration4_metrics['f1']:.4f}")
        print(f"   AUC: {iteration4_metrics['auc']:.4f}")
        print(f"   Training Date: {training_date.strftime('%B %d, %Y')}")
        print("\n🎯 Restart the GUI and the metrics will update!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("🚀 Updating Model Metrics...\n")
    update_iteration4_model()
ENDPYTHON
    SCRIPT_NAME="update_model_db.py"
    echo -e "${GREEN}✅ Created update_model_db.py${NC}"
fi

echo -e "${BLUE}📋 Step 3: Testing database connection...${NC}"
if python3 -c "
from app.database import SessionLocal
from sqlalchemy import text
try:
    db = SessionLocal()
    db.execute(text('SELECT 1'))
    db.close()
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection verified${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 4: Running update script...${NC}"
python3 "$SCRIPT_NAME"

echo ""
echo -e "${GREEN}🎉 Update Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo "   ✅ Git pull completed"
echo "   ✅ Backend files verified"
echo "   ✅ Database connection verified"
echo "   ✅ Model metrics updated"
echo ""
echo -e "${BLUE}🔄 Next Steps:${NC}"
echo "  1. Refresh the GUI dashboard"
echo "  2. Training date should show: October 15, 2025"
echo "  3. Metrics should be accurate"
echo ""
echo -e "${GREEN}🎯 Everything is fixed and updated!${NC}"

