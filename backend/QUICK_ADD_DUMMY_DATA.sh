#!/bin/bash
# Quick script to add dummy data (only malicious alerts)
# This script ensures the virtual environment is activated before running

cd "$(dirname "$0")"

echo "🔍 Checking virtual environment..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "⚠️  Virtual environment not found. Creating one..."
    python3 -m venv .venv
    echo "✅ Virtual environment created"
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source .venv/bin/activate

# Check if dependencies are installed
if ! python3 -c "import sqlalchemy" 2>/dev/null; then
    echo "⚠️  Dependencies not installed. Installing..."
    pip install -r requirements.txt
    echo "✅ Dependencies installed"
fi

# Remove any existing benign alerts first
echo "🧹 Removing any existing benign alerts..."
python3 remove_benign_alerts.py

# Run the script (only creates malicious alerts)
echo "🚀 Running dummy data script (malicious alerts only)..."
python3 populate_dummy_data.py

echo ""
echo "✅ Done! All dummy alerts are malicious. Refresh your dashboard to see the analytics charts."

