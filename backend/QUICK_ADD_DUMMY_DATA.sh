#!/bin/bash
# Quick script to add dummy data (only malicious alerts)
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
    # Check if python3-venv is installed
    if ! python3 -m venv --help > /dev/null 2>&1; then
        echo "❌ python3-venv module not available. Installing..."
        echo "   Please run: sudo apt install python3-venv python3-full"
        exit 1
    fi
    python3 -m venv .venv
    VENV_PATH=".venv"
    
    # Verify venv was created properly
    if [ ! -f ".venv/bin/python3" ] && [ ! -f ".venv/bin/python" ]; then
        echo "❌ Virtual environment creation failed"
        echo "   Trying alternative: python3 -m venv --without-pip .venv"
        python3 -m venv --without-pip .venv
        # Install pip manually
        curl -sS https://bootstrap.pypa.io/get-pip.py | .venv/bin/python3
    fi
    echo "✅ Virtual environment created"
fi

# Use venv's python and pip directly (more reliable than activation)
# Check for python3 first, then python
if [ -f "$VENV_PATH/bin/python3" ]; then
    PYTHON_BIN="$VENV_PATH/bin/python3"
elif [ -f "$VENV_PATH/bin/python" ]; then
    PYTHON_BIN="$VENV_PATH/bin/python"
else
    echo "❌ Python not found in virtual environment"
    echo "   Expected at: $VENV_PATH/bin/python3 or $VENV_PATH/bin/python"
    echo "   Please check if python3-venv is installed: sudo apt install python3-venv python3-full"
    exit 1
fi

PIP_BIN="$VENV_PATH/bin/pip"
if [ ! -f "$PIP_BIN" ]; then
    PIP_BIN="$VENV_PATH/bin/pip3"
fi

# Check if dependencies are installed
if ! $PYTHON_BIN -c "import sqlalchemy" 2>/dev/null; then
    echo "⚠️  Dependencies not installed. Installing..."
    $PIP_BIN install -r requirements.txt
    echo "✅ Dependencies installed"
fi

# Force remove ALL benign alerts first (by flag and by score)
if [ -f "force_remove_all_benign.py" ]; then
    echo "🧹 Force removing ALL benign alerts (by flag and by score)..."
    $PYTHON_BIN force_remove_all_benign.py || echo "⚠️  Could not remove benign alerts"
elif [ -f "remove_benign_alerts.py" ]; then
    echo "🧹 Removing benign alerts..."
    $PYTHON_BIN remove_benign_alerts.py || echo "⚠️  Could not remove benign alerts"
fi

# Run the script (only creates malicious alerts)
echo "🚀 Running dummy data script (malicious alerts only)..."
$PYTHON_BIN populate_dummy_data.py

echo ""
echo "✅ Done! All dummy alerts are malicious. Refresh your dashboard to see the analytics charts."

