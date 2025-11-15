#!/bin/bash
# Simple script to clear all alerts from database
# Automatically finds the Python virtual environment

cd "$(dirname "$0")"
CURRENT_DIR="$(pwd)"

echo "🔍 Searching for virtual environment..."

# Method 1: Check systemd service file for the actual path
PYTHON_CMD=""
if [ -f "/etc/systemd/system/ids-idps-backend.service" ]; then
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
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        echo "⚠️  Using system python3 (virtual environment not found)"
        echo "   This may not work if dependencies aren't installed system-wide"
    else
        echo "❌ Could not find Python executable"
        echo ""
        echo "Searched locations:"
        echo "  - $CURRENT_DIR/.venv/bin/python3"
        echo "  - $CURRENT_DIR/venv/bin/python3"
        echo "  - $CURRENT_DIR/env/bin/python3"
        echo "  - Systemd service paths"
        echo ""
        echo "Please ensure the backend virtual environment is set up properly"
        exit 1
    fi
fi

# Run the clear script
echo ""
echo "🧹 Clearing all alerts from database..."
echo "   Using: $PYTHON_CMD"
$PYTHON_CMD clear_all_alerts.py

echo ""
echo "✅ Done! Database is clean. Only malicious alerts will appear when you simulate attacks."

