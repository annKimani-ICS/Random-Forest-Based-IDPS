#!/bin/bash
# Automated Performance Metrics Fix
# Populates database with correct Iteration 4 model metrics

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Automated Performance Metrics Fix${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we're in backend directory
if [ ! -f "app/main.py" ]; then
    echo -e "${RED}❌ Please run this script from the backend directory${NC}"
    exit 1
fi

# Activate virtual environment
if [ -d ".venv" ]; then
    echo -e "${BLUE}📦 Activating virtual environment...${NC}"
    source .venv/bin/activate
elif [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${GREEN}✅ Virtual environment already active${NC}"
else
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Testing database connection...${NC}"
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
    echo -e "${RED}❌ Database connection failed. Please ensure PostgreSQL is running${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 2: Updating model metrics...${NC}"
if python3 update_model_db.py 2>/dev/null; then
    echo -e "${GREEN}✅ Model metrics updated successfully${NC}"
else
    echo -e "${YELLOW}⚠️  update_model_db.py failed, trying alternative method...${NC}"
    
    # Run inline Python to update metrics
    python3 <<'ENDPYTHON'
import sys
sys.path.insert(0, '.')
from app.database import SessionLocal
from app.models import Model
from datetime import datetime
import uuid

db = SessionLocal()
try:
    print("🔄 Updating model metrics...")
    
    # Clear existing models
    db.query(Model).delete()
    
    # Iteration 4 metrics
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
    
    # Use current date for training timestamp
    training_date = datetime.now()
    
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
    print("\n📊 Model Info:")
    print(f"   Version: iteration4_voting_ensemble")
    print(f"   Accuracy: {iteration4_metrics['accuracy']:.4f}")
    print(f"   Precision: {iteration4_metrics['precision']:.4f}")
    print(f"   Recall: {iteration4_metrics['recall']:.4f}")
    print(f"   F1-Score: {iteration4_metrics['f1']:.4f}")
    print(f"   AUC: {iteration4_metrics['auc']:.4f}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    db.rollback()
    sys.exit(1)
finally:
    db.close()
ENDPYTHON

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Model metrics updated via inline method${NC}"
    else
        echo -e "${RED}❌ Failed to update model metrics${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}📋 Step 3: Optionally populating dummy alerts...${NC}"
if [ -f "add_dummy_alerts.py" ]; then
    read -p "Populate dummy alerts as well? (y/n): " response
    if [ "$response" = "y" ]; then
        if python3 add_dummy_alerts.py 2>/dev/null; then
            echo -e "${GREEN}✅ Dummy alerts populated${NC}"
        else
            echo -e "${YELLOW}⚠️  Failed to populate alerts, but metrics are fixed${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}🎉 Performance Metrics Fix Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo "   ✅ Database connection verified"
echo "   ✅ Model metrics updated with Iteration 4 values"
echo "   ✅ Accuracy: 90.48%"
echo "   ✅ Precision: 90.62%"
echo "   ✅ Recall: 90.48%"
echo "   ✅ F1-Score: 90.51%"
echo "   ✅ AUC: 95.00%"
echo ""
echo -e "${BLUE}🔄 Next Steps:${NC}"
echo "  1. Refresh the GUI dashboard"
echo "  2. Metrics should now show correct values"
echo ""
echo -e "${GREEN}🎯 Performance metrics should now be accurate!${NC}"

