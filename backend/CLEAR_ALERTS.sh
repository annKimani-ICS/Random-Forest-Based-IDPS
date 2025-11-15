#!/bin/bash
# Simple script to clear all alerts from database
# Uses the same approach as the working setup scripts

cd "$(dirname "$0")"

echo "🔍 Checking virtual environment..."

# Find virtual environment
if [ -d ".venv" ]; then
    VENV_PATH=".venv"
elif [ -d "venv" ]; then
    VENV_PATH="venv"
elif [ -d "env" ]; then
    VENV_PATH="env"
else
    echo "❌ Virtual environment not found!"
    echo "   Please ensure the backend is set up properly"
    exit 1
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source "$VENV_PATH/bin/activate"

# Run the clear script
echo "🧹 Clearing all alerts from database..."
python3 clear_all_alerts.py 2>/dev/null || python clear_all_alerts.py

echo ""
echo "✅ Done! Database is clean. Only malicious alerts will appear when you simulate attacks."

