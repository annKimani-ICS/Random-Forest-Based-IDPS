#!/bin/bash
# Simple script to clear all alerts from database
# Uses the same Python that the systemd service uses

cd "$(dirname "$0")"

# Use venv's python directly (same as systemd service does)
# No activation needed - just use the venv's python binary
if [ -f ".venv/bin/python3" ]; then
    PYTHON_CMD=".venv/bin/python3"
elif [ -f ".venv/bin/python" ]; then
    PYTHON_CMD=".venv/bin/python"
else
    echo "❌ Virtual environment not found at .venv/bin/python3"
    echo "   Please ensure the backend is set up properly"
    echo "   Expected: $(pwd)/.venv/bin/python3"
    exit 1
fi

# Run the clear script
echo "🧹 Clearing all alerts from database..."
echo "   Using: $PYTHON_CMD"
$PYTHON_CMD clear_all_alerts.py

echo ""
echo "✅ Done! Database is clean. Only malicious alerts will appear when you simulate attacks."

