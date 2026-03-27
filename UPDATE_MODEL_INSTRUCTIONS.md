# How to Update GUI Model Metrics to Iteration 4

## Problem
The GUI is showing old model metrics because it reads from the database `models` table, not directly from your saved model files.

## Solution: Update Database with Iteration 4 Metrics

### **On Ubuntu VM (Easiest):**

1. **Navigate to project:**
   ```bash
   cd ~/Random-Forest-Based-IDPS
   ```

2. **Pull latest changes:**
   ```bash
   git pull origin feat/sprint4-admin-dashboard
   ```

3. **Activate virtual environment:**
   ```bash
   source venv/bin/activate
   ```

4. **Run the update script:**
   ```bash
   cd backend
   python update_model_db.py
   ```

5. **Restart the GUI:**
   ```bash
   cd ..
   ./run_gui.sh
   ```

### **Expected Result:**

After running the script, you should see:
```
🚀 Updating Model Metrics...

✅ Creating new Iteration 4 model entry...
✅ Model metrics updated successfully!

📊 Current Model Info:
   Version: iteration4_voting_ensemble
   Accuracy: 0.9048
   Precision: 0.9062
   Recall: 0.9048
   F1-Score: 0.9051
   AUC: 0.9500

🎯 Restart the GUI and the metrics will update!
```

### **What This Updates:**

The GUI will now display:
- ✅ **Accuracy**: 90.48% (instead of old ~72%)
- ✅ **Precision**: 90.62%
- ✅ **Recall**: 90.48%
- ✅ **F1-Score**: 90.51%
- ✅ **AUC**: 95.00%
- ✅ **Model Version**: iteration4_voting_ensemble

### **Alternative: Direct Database SQL** (Advanced)

If you can access the PostgreSQL database directly:

```sql
INSERT INTO models (id, version, trained_at, metrics, notes)
VALUES (
    gen_random_uuid(),
    'iteration4_voting_ensemble',
    '2024-10-15 12:00:00',
    '{
        "iteration": 4,
        "model_name": "Voting Ensemble",
        "accuracy": 0.9048,
        "precision": 0.9062,
        "recall": 0.9048,
        "f1": 0.9051,
        "auc": 0.95,
        "holdout_f1": 0.8976,
        "performance_consistency": 0.0076,
        "description": "FAST Random Forest with Voting Ensemble - 90.51% F1-Score"
    }'::jsonb,
    'Best performing model - 90.48% accuracy, 90.51% F1-score'
)
ON CONFLICT (version) DO UPDATE SET
    metrics = EXCLUDED.metrics,
    trained_at = EXCLUDED.trained_at,
    notes = EXCLUDED.notes;
```

## Verification

After updating, check the GUI:
1. Navigate to the **Overview/Dashboard** tab
2. Look at the **Model Performance** section
3. You should see the updated metrics displaying ~90% accuracy

## Files Modified
- `backend/update_model_db.py` - Script to update database
- `scripts/update_model_metrics.py` - Alternative script location

## Note
The GUI gets model metrics from the database, not from the `.pkl` files. You must update the database for the GUI to reflect your latest model performance.

