#!/bin/bash
# Script to remove all benign alerts from the database
# This script ensures the virtual environment is activated before running

cd "$(dirname "$0")"

echo "🔍 Checking virtual environment..."

# Find virtual environment (check common locations)
VENV_PATH=""
if [ -d ".venv" ]; then
    VENV_PATH=".venv"
elif [ -d "venv" ]; then
    VENV_PATH="venv"
elif [ -d "env" ]; then
    VENV_PATH="env"
fi

# Create venv if it doesn't exist
if [ -z "$VENV_PATH" ]; then
    echo "⚠️  Virtual environment not found. Creating one..."
    python3 -m venv .venv
    VENV_PATH=".venv"
    echo "✅ Virtual environment created"
fi

# Use venv's python and pip directly
PYTHON_BIN="$VENV_PATH/bin/python3"
PIP_BIN="$VENV_PATH/bin/pip"

# Check if python exists in venv
if [ ! -f "$PYTHON_BIN" ]; then
    echo "❌ Python not found in virtual environment at $PYTHON_BIN"
    exit 1
fi

# Check if dependencies are installed
if ! $PYTHON_BIN -c "import sqlalchemy" 2>/dev/null; then
    echo "⚠️  Dependencies not installed. Installing..."
    $PIP_BIN install -r requirements.txt
    echo "✅ Dependencies installed"
fi

# Run the script
echo "🧹 Removing benign alerts from database..."
$PYTHON_BIN force_remove_all_benign.py || $PYTHON_BIN remove_benign_alerts.py

echo ""
echo "✅ Done! All benign alerts have been removed."

