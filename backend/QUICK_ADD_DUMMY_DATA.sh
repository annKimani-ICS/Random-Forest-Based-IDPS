#!/bin/bash
# Quick script to add dummy data (only malicious alerts)
# Uses the same approach as the working setup scripts

cd "$(dirname "$0")"

echo "🔍 Checking virtual environment..."

# Find virtual environment (check common locations)
if [ -d ".venv" ]; then
    VENV_PATH=".venv"
elif [ -d "venv" ]; then
    VENV_PATH="venv"
elif [ -d "env" ]; then
    VENV_PATH="env"
else
    echo "⚠️  Virtual environment not found. Creating one..."
    python3 -m venv .venv
    VENV_PATH=".venv"
    echo "✅ Virtual environment created"
fi

# Activate virtual environment (same as old working scripts)
echo "🔌 Activating virtual environment..."
source "$VENV_PATH/bin/activate"

# Check if dependencies are installed
if ! python -c "import sqlalchemy" 2>/dev/null && ! python3 -c "import sqlalchemy" 2>/dev/null; then
    echo "⚠️  Dependencies not installed. Installing..."
    pip install -r requirements.txt
    echo "✅ Dependencies installed"
fi

# Force remove ALL benign alerts first (by flag and by score)
if [ -f "force_remove_all_benign.py" ]; then
    echo "🧹 Force removing ALL benign alerts (by flag and by score)..."
    python3 force_remove_all_benign.py 2>/dev/null || python force_remove_all_benign.py 2>/dev/null || echo "⚠️  Could not remove benign alerts"
elif [ -f "remove_benign_alerts.py" ]; then
    echo "🧹 Removing benign alerts..."
    python3 remove_benign_alerts.py 2>/dev/null || python remove_benign_alerts.py 2>/dev/null || echo "⚠️  Could not remove benign alerts"
fi

# Use the old working script (add_dummy_alerts.py) - updated to only create malicious alerts
echo "🚀 Running dummy data script (malicious alerts only)..."
if [ -f "add_dummy_alerts.py" ]; then
    python3 add_dummy_alerts.py 2>/dev/null || python add_dummy_alerts.py
elif [ -f "populate_dummy_data.py" ]; then
    python3 populate_dummy_data.py 2>/dev/null || python populate_dummy_data.py
else
    echo "❌ No dummy data script found!"
    exit 1
fi

echo ""
echo "✅ Done! All dummy alerts are malicious. Refresh your dashboard to see the analytics charts."

