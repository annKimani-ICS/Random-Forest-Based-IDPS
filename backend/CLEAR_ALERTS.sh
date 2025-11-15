#!/bin/bash
# Simple script to clear all alerts from database
# Uses the systemd service's Python environment

cd "$(dirname "$0")"

# Get the Python path from systemd service (if it exists)
# This matches how the backend service runs
if [ -f "/etc/systemd/system/ids-idps-backend.service" ]; then
    # Extract Python path from systemd service
    SERVICE_PYTHON=$(grep "ExecStart" /etc/systemd/system/ids-idps-backend.service | sed 's/.*ExecStart=//' | sed 's|/uvicorn.*||')
    if [ -n "$SERVICE_PYTHON" ] && [ -f "$SERVICE_PYTHON/python3" ]; then
        PYTHON_CMD="$SERVICE_PYTHON/python3"
        echo "✅ Using Python from systemd service: $PYTHON_CMD"
    elif [ -n "$SERVICE_PYTHON" ] && [ -f "$SERVICE_PYTHON/python" ]; then
        PYTHON_CMD="$SERVICE_PYTHON/python"
        echo "✅ Using Python from systemd service: $PYTHON_CMD"
    else
        # Fallback: try to find venv
        if [ -d ".venv" ] && [ -f ".venv/bin/python3" ]; then
            PYTHON_CMD=".venv/bin/python3"
        elif [ -d ".venv" ] && [ -f ".venv/bin/python" ]; then
            PYTHON_CMD=".venv/bin/python"
        else
            PYTHON_CMD="python3"
        fi
    fi
else
    # No systemd service, try venv or system python
    if [ -d ".venv" ] && [ -f ".venv/bin/python3" ]; then
        PYTHON_CMD=".venv/bin/python3"
    elif [ -d ".venv" ] && [ -f ".venv/bin/python" ]; then
        PYTHON_CMD=".venv/bin/python"
    else
        PYTHON_CMD="python3"
    fi
fi

# Run the clear script
echo "🧹 Clearing all alerts from database..."
$PYTHON_CMD clear_all_alerts.py

echo ""
echo "✅ Done! Database is clean. Only malicious alerts will appear when you simulate attacks."

