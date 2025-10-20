# Fix GUI Display Issues

## Problems Identified:
1. **Model metrics mismatch**: GUI shows different scores than your Iteration 4 model
2. **Empty alerts section**: No dummy alerts for demonstration

## Solution: Populate Database with Correct Data

### **On Ubuntu VM (Recommended):**

```bash
# 1. Navigate to project
cd ~/Random-Forest-Based-IDPS

# 2. Pull latest changes
git pull origin feat/sprint4-admin-dashboard

# 3. Activate virtual environment
source venv/bin/activate

# 4. Run the population script
cd backend
python populate_dummy_data.py

# 5. Restart the GUI
cd ..
./run_gui.sh
```

### **Alternative (from project root):**

```bash
# If you have backend dependencies installed globally
python scripts/populate_database.py
```

## What This Will Fix:

### **Model Performance Section:**
- ✅ **Accuracy**: 90.48% (matches your Iteration 4)
- ✅ **Precision**: 90.62%
- ✅ **Recall**: 90.48%
- ✅ **F1-Score**: 90.51%
- ✅ **AUC**: 95.00%

### **Alerts Section:**
- ✅ **25 realistic dummy alerts** over last 7 days
- ✅ **Various attack types**: DDoS, Brute Force, SQL Injection, etc.
- ✅ **Realistic IP addresses**: 192.168.x.x and 10.0.x.x
- ✅ **Random scores**: 0.3 to 0.95
- ✅ **Different statuses**: NEW, ACK, BLOCKED, CLOSED
- ✅ **Rich payload data**: packet counts, protocols, ports

### **KPI Cards:**
- ✅ **Alerts (24h)**: Will show actual count
- ✅ **Active Blocks**: Will show 3 (if any exist)
- ✅ **Precision**: Will show 90.62%
- ✅ **Threshold**: Will show 0.50

## Expected Result:

After running the script and restarting the GUI, you should see:

1. **Dashboard tab** with correct model metrics
2. **Alerts tab** with populated alert table
3. **Realistic data** for demonstration purposes
4. **Consistent metrics** matching your actual model performance

## Files Created:
- `backend/populate_dummy_data.py` - Main population script
- `scripts/populate_database.py` - Alternative script location

## Note:
The GUI reads from the database, not from your `.pkl` files. This script updates the database with the correct metrics and adds realistic dummy data for demonstration.
