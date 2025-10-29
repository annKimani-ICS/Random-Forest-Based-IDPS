# Update Ubuntu VM - Step-by-Step Guide

Complete guide to update your Ubuntu VM with the latest changes including live traffic monitoring.

## Prerequisites

- ✅ Ubuntu VM has network connectivity
- ✅ SSH access to Ubuntu VM (or direct console access)
- ✅ Git repository cloned on Ubuntu VM
- ✅ Current branch: `feat/sprint4-admin-dashboard` (or will switch to it)

## Step 1: Backup Current State (Recommended)

```bash
# On Ubuntu VM
cd ~/Random-Forest-Based-IDPS

# Check current branch
git branch

# Backup current database (optional but recommended)
cd backend
source .venv/bin/activate
python3 -c "
from app.database import SessionLocal
from app.models import Alert
import json
from datetime import datetime

db = SessionLocal()
alerts = db.query(Alert).all()
backup = {
    'timestamp': datetime.now().isoformat(),
    'alert_count': len(alerts)
}
with open('/tmp/db_backup.json', 'w') as f:
    json.dump(backup, f)
print(f'Backup created: {len(alerts)} alerts')
"
```

## Step 2: Pull Latest Changes

```bash
# On Ubuntu VM
cd ~/Random-Forest-Based-IDPS

# Check current status
git status

# If you have uncommitted changes, stash them
git stash

# Fetch latest changes from remote
git fetch origin

# Switch to the feature branch (if not already)
git checkout feat/sprint4-admin-dashboard

# Pull latest changes
git pull origin feat/sprint4-admin-dashboard
```

## Step 3: Resolve Any Conflicts

```bash
# If there are merge conflicts, resolve them
git status

# For each conflicted file, edit and resolve conflicts
# Then:
git add <resolved-file>
git commit -m "Resolve merge conflicts"
```

## Step 4: Update Python Dependencies

```bash
# Navigate to backend directory
cd backend

# Activate virtual environment
source .venv/bin/activate

# Upgrade pip (recommended)
pip install --upgrade pip

# Install/update dependencies
pip install -r requirements.txt

# Verify new packages installed
pip list | grep -E "(scapy|pandas|numpy|scikit-learn|joblib)"
```

## Step 5: Verify System Requirements

```bash
# Check if required system packages are installed
# For scapy, we may need additional system libraries

# Install system dependencies for packet capture (if needed)
sudo apt-get update
sudo apt-get install -y \
    python3-dev \
    libpcap-dev \
    tcpdump \
    wireshark-common

# Note: Scapy may need root/privileges for packet capture
# Check if we can capture packets (requires sudo or root)
sudo python3 -c "from scapy.all import get_if_list; print('Interfaces:', get_if_list())"
```

## Step 6: Update Database Schema (If Needed)

```bash
# The database schema should already be compatible
# But verify tables exist
cd backend
source .venv/bin/activate

python3 << 'EOF'
from app.database import SessionLocal, engine
from app.models import Base
from sqlalchemy import inspect

# Ensure all tables exist
Base.metadata.create_all(bind=engine)

# Verify tables
inspector = inspect(engine)
tables = inspector.get_table_names()
print("✅ Database tables:", tables)

# Check alerts table structure
if 'alerts' in tables:
    columns = [col['name'] for col in inspector.get_columns('alerts')]
    print("✅ Alerts table columns:", columns)
EOF
```

## Step 7: Verify Model Files

```bash
# Check that model files exist
cd ~/Random-Forest-Based-IDPS

ls -lh models/*.pkl models/*.json | head -10

# Verify key model files exist
test -f models/best_rf_iteration4_voting_ensemble.pkl && echo "✅ Model file exists" || echo "❌ Model file missing"
test -f models/feature_selection_iteration4.json && echo "✅ Feature selection exists" || echo "❌ Feature selection missing"
test -f models/scaler_iteration4.pkl && echo "✅ Scaler exists" || echo "❌ Scaler missing"
```

## Step 8: Test Backend API

```bash
# Start backend if not running
cd ~/Random-Forest-Based-IDPS/backend

# Check if backend is running
curl http://localhost:8000/health || echo "Backend not running"

# If not running, start it
source .venv/bin/activate
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &
# Or use: ./run_backend.sh

# Wait a few seconds, then test
sleep 3
curl http://localhost:8000/health
```

## Step 9: Test New Monitoring API

```bash
# Get authentication token
cd ~/Random-Forest-Based-IDPS

TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@ids.local", "password": "YOUR_PASSWORD"}' \
  | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

# Test monitoring status endpoint
curl http://localhost:8000/api/monitor/status \
  -H "Authorization: Bearer $TOKEN"

# Should return JSON with monitoring status
```

## Step 10: Verify Traffic Monitor Module

```bash
# Test that traffic monitor can be imported
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate

python3 << 'EOF'
try:
    from app.traffic_monitor import TrafficMonitor
    print("✅ TrafficMonitor imported successfully")
    
    # Try to initialize (will check for model files)
    monitor = TrafficMonitor()
    print("✅ TrafficMonitor initialized")
    print(f"   Interface: {monitor.interface}")
    print(f"   Threshold: {monitor.threshold}")
except Exception as e:
    print(f"❌ Error: {e}")
EOF
```

## Step 11: Update GUI (If Applicable)

```bash
# If GUI is also updated, pull frontend changes
cd ~/Random-Forest-Based-IDPS

# Check if frontend directory exists
if [ -d "frontend" ]; then
    cd frontend
    npm install  # If using npm
    # Or pip install if Python GUI
    cd ..
fi
```

## Step 12: Start Monitoring Service (Optional)

**IMPORTANT**: Only start monitoring when ready to test. Monitoring requires root privileges.

```bash
# Option A: Start via API (recommended)
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@ids.local", "password": "YOUR_PASSWORD"}' \
  | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))")

curl -X POST http://localhost:8000/api/monitor/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"interface": "eth0", "threshold": 0.50}'

# Option B: Start via command line (requires sudo for packet capture)
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
sudo python3 -m app.traffic_monitor --interface eth0 --threshold 0.50
```

## Step 13: Verification Checklist

Run this verification script:

```bash
cd ~/Random-Forest-Based-IDPS

cat > /tmp/verify_update.sh << 'EOF'
#!/bin/bash
echo "=== Verifying Update ==="

# 1. Check Git status
echo -n "Git status: "
git branch | grep "*" | grep feat/sprint4-admin-dashboard && echo "✅" || echo "❌"

# 2. Check dependencies
echo -n "Scapy installed: "
python3 -c "import scapy; print('✅')" 2>/dev/null || echo "❌"

# 3. Check model files
echo -n "Model files exist: "
test -f models/best_rf_iteration4_voting_ensemble.pkl && echo "✅" || echo "❌"

# 4. Check backend
echo -n "Backend running: "
curl -s http://localhost:8000/health > /dev/null && echo "✅" || echo "❌"

# 5. Check monitoring API
echo -n "Monitoring API: "
curl -s http://localhost:8000/api/monitor/status > /dev/null && echo "✅" || echo "❌ (needs auth)"

echo "=== Verification Complete ==="
EOF

chmod +x /tmp/verify_update.sh
/tmp/verify_update.sh
```

## Troubleshooting

### Issue: Git Pull Conflicts

```bash
# If conflicts occur:
git status
# Resolve conflicts manually in files
git add <resolved-files>
git commit -m "Resolve conflicts"
```

### Issue: Dependencies Fail to Install

```bash
# Update pip first
pip install --upgrade pip setuptools wheel

# Install dependencies one by one to identify issue
pip install scapy
pip install pandas
pip install numpy
pip install scikit-learn
pip install joblib
```

### Issue: Scapy Cannot Capture Packets

```bash
# Scapy requires root privileges for packet capture
# Run with sudo:
sudo python3 -m app.traffic_monitor

# Or add user to appropriate groups (advanced):
sudo usermod -aG wireshark $USER
# Then log out and back in
```

### Issue: Model Files Not Found

```bash
# Verify models directory exists
ls -la models/

# If missing, they should be in the repository
git ls-files models/*.pkl models/*.json

# If still missing, check if they're in .gitignore
git check-ignore models/*.pkl
```

### Issue: Backend Won't Start

```bash
# Check if port 8000 is in use
sudo netstat -tlnp | grep 8000

# Kill existing process
sudo pkill -f uvicorn

# Check backend logs
tail -f /var/log/ids-idps-backend.log  # If systemd service
# Or check terminal output if running manually
```

## Quick Update Script

For convenience, here's a complete update script:

```bash
#!/bin/bash
# Quick update script for Ubuntu VM

set -e

cd ~/Random-Forest-Based-IDPS

echo "🔄 Updating repository..."
git fetch origin
git pull origin feat/sprint4-admin-dashboard

echo "📦 Installing dependencies..."
cd backend
source .venv/bin/activate
pip install -r requirements.txt

echo "✅ Database schema check..."
python3 -c "from app.database import engine, Base; Base.metadata.create_all(bind=engine)"

echo "🔍 Verification..."
python3 -c "from app.traffic_monitor import TrafficMonitor; print('✅ TrafficMonitor OK')"

echo "✅ Update complete!"
```

Save as `update_vm.sh`, then:
```bash
chmod +x update_vm.sh
./update_vm.sh
```

## Post-Update Testing

After update, verify everything works:

1. **Test Backend API**:
   ```bash
   curl http://localhost:8000/health
   ```

2. **Test Authentication**:
   ```bash
   curl -X POST http://localhost:8000/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email": "admin@ids.local", "password": "YOUR_PASSWORD"}'
   ```

3. **Test Monitoring Status** (with auth token):
   ```bash
   curl http://localhost:8000/api/monitor/status \
     -H "Authorization: Bearer $TOKEN"
   ```

4. **Test GUI** (if applicable):
   - Launch GUI application
   - Login and verify dashboard loads
   - Check that monitoring controls are visible

## Next Steps

After successful update:

1. ✅ Review `LIVE_TRAFFIC_TESTING_GUIDE.md` for testing instructions
2. ✅ Start monitoring service when ready to test
3. ✅ Prepare Kali Linux VM for DDoS simulation
4. ✅ Run verification tests: `python3 verify_gui_traffic.py`

---

**Last Updated**: January 2025  
**Branch**: `feat/sprint4-admin-dashboard`

