#!/bin/bash
# Script to remove all benign alerts from the database
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

# Run the script
echo "🧹 Removing benign alerts from database..."
python3 remove_benign_alerts.py

echo ""
echo "✅ Done! All benign alerts have been removed."

