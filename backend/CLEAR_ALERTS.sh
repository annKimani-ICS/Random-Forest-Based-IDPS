#!/bin/bash
# Simple script to clear all alerts from database
# Automatically finds the Python virtual environment

cd "$(dirname "$0")"
CURRENT_DIR="$(pwd)"

echo "🔍 Searching for virtual environment..."

# Method 1: Check running uvicorn process to find actual Python being used
PYTHON_CMD=""
if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
    # Get the command line of the running uvicorn process
    UVICORN_CMD=$(ps aux | grep "[u]vicorn.*app.main:app" | head -1 | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
    # Extract the path - uvicorn is usually at /path/to/venv/bin/uvicorn
    if echo "$UVICORN_CMD" | grep -q "/bin/uvicorn"; then
        UVICORN_PATH=$(echo "$UVICORN_CMD" | sed 's|/bin/uvicorn.*||' | awk '{print $1}' | sed 's|/uvicorn$||')
        if [ -n "$UVICORN_PATH" ] && [ -f "$UVICORN_PATH/bin/python3" ]; then
            PYTHON_CMD="$UVICORN_PATH/bin/python3"
            echo "✅ Found Python from running backend process: $PYTHON_CMD"
        fi
    fi
fi

# Method 2: Check systemd service file for the actual path
if [ -z "$PYTHON_CMD" ] && [ -f "/etc/systemd/system/ids-idps-backend.service" ]; then
    # Extract the uvicorn path from ExecStart
    UVICORN_PATH=$(grep "^ExecStart=" /etc/systemd/system/ids-idps-backend.service | sed 's/ExecStart=//' | sed 's|/uvicorn.*||')
    if [ -n "$UVICORN_PATH" ]; then
        # Try python3 first, then python
        if [ -f "$UVICORN_PATH/python3" ]; then
            PYTHON_CMD="$UVICORN_PATH/python3"
            echo "✅ Found Python from systemd service: $PYTHON_CMD"
        elif [ -f "$UVICORN_PATH/python" ]; then
            PYTHON_CMD="$UVICORN_PATH/python"
            echo "✅ Found Python from systemd service: $PYTHON_CMD"
        fi
    fi
fi

# Method 2: Check common venv locations in current directory
if [ -z "$PYTHON_CMD" ]; then
    for VENV_DIR in ".venv" "venv" "env"; do
        if [ -f "$VENV_DIR/bin/python3" ]; then
            PYTHON_CMD="$VENV_DIR/bin/python3"
            echo "✅ Found Python in $VENV_DIR: $PYTHON_CMD"
            break
        elif [ -f "$VENV_DIR/bin/python" ]; then
            PYTHON_CMD="$VENV_DIR/bin/python"
            echo "✅ Found Python in $VENV_DIR: $PYTHON_CMD"
            break
        fi
    done
fi

# Method 3: Check parent directory (in case backend is a subdirectory)
if [ -z "$PYTHON_CMD" ]; then
    PARENT_DIR="$(dirname "$CURRENT_DIR")"
    for VENV_DIR in "$PARENT_DIR/.venv" "$PARENT_DIR/venv" "$PARENT_DIR/env"; do
        if [ -f "$VENV_DIR/bin/python3" ]; then
            PYTHON_CMD="$VENV_DIR/bin/python3"
            echo "✅ Found Python in parent directory: $PYTHON_CMD"
            break
        elif [ -f "$VENV_DIR/bin/python" ]; then
            PYTHON_CMD="$VENV_DIR/bin/python"
            echo "✅ Found Python in parent directory: $PYTHON_CMD"
            break
        fi
    done
fi

# Method 4: Check if systemd service WorkingDirectory has a venv
if [ -z "$PYTHON_CMD" ] && [ -f "/etc/systemd/system/ids-idps-backend.service" ]; then
    WORK_DIR=$(grep "^WorkingDirectory=" /etc/systemd/system/ids-idps-backend.service | sed 's/WorkingDirectory=//')
    if [ -n "$WORK_DIR" ]; then
        if [ -f "$WORK_DIR/.venv/bin/python3" ]; then
            PYTHON_CMD="$WORK_DIR/.venv/bin/python3"
            echo "✅ Found Python from systemd WorkingDirectory: $PYTHON_CMD"
        elif [ -f "$WORK_DIR/.venv/bin/python" ]; then
            PYTHON_CMD="$WORK_DIR/.venv/bin/python"
            echo "✅ Found Python from systemd WorkingDirectory: $PYTHON_CMD"
        fi
    fi
fi

# If still not found, try system python3 (last resort)
if [ -z "$PYTHON_CMD" ]; then
    echo "❌ Could not find Python virtual environment"
    echo ""
    echo "Searched locations:"
    echo "  - Running backend process"
    echo "  - Systemd service file: /etc/systemd/system/ids-idps-backend.service"
    echo "  - $CURRENT_DIR/.venv/bin/python3"
    echo "  - $CURRENT_DIR/venv/bin/python3"
    echo "  - $CURRENT_DIR/env/bin/python3"
    echo ""
    echo "💡 To manually clear alerts, try:"
    echo "   1. Find your venv: find ~ -name 'uvicorn' -type f 2>/dev/null | head -1"
    echo "   2. Use that venv's python: /path/to/venv/bin/python3 clear_all_alerts.py"
    echo ""
    echo "   Or activate venv and run:"
    echo "   source .venv/bin/activate  # or wherever your venv is"
    echo "   python3 clear_all_alerts.py"
    exit 1
fi

# Run the clear script
echo ""
echo "🧹 Clearing all alerts from database..."
echo "   Using: $PYTHON_CMD"
$PYTHON_CMD clear_all_alerts.py

echo ""
echo "✅ Done! Database is clean. Only malicious alerts will appear when you simulate attacks."

