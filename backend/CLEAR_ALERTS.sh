#!/bin/bash
# Simple script to clear all alerts from database
# Automatically finds the Python virtual environment

cd "$(dirname "$0")"
CURRENT_DIR="$(pwd)"

echo "🔍 Searching for virtual environment..."

# Method 1: Check running uvicorn process to find actual Python being used
PYTHON_CMD=""
if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
    # Get the PID of the uvicorn process
    UVICORN_PID=$(pgrep -f "uvicorn.*app.main:app" | head -1)
    
    if [ -n "$UVICORN_PID" ]; then
        # Method 1a: Get the actual Python executable from the process
        if [ -f "/proc/$UVICORN_PID/exe" ]; then
            PYTHON_EXE=$(readlink -f "/proc/$UVICORN_PID/exe" 2>/dev/null)
            if [ -n "$PYTHON_EXE" ] && [ -f "$PYTHON_EXE" ]; then
                PYTHON_CMD="$PYTHON_EXE"
                echo "✅ Found Python from running backend process (PID $UVICORN_PID): $PYTHON_CMD"
            fi
        fi
        
        # Method 1b: If that didn't work, get the uvicorn path and derive venv
        if [ -z "$PYTHON_CMD" ]; then
            # Get the full command line
            UVICORN_CMD=$(cat "/proc/$UVICORN_PID/cmdline" 2>/dev/null | tr '\0' ' ')
            # Extract uvicorn path (first argument after PID)
            UVICORN_BIN=$(echo "$UVICORN_CMD" | awk '{print $1}')
            if [ -n "$UVICORN_BIN" ] && [ -f "$UVICORN_BIN" ]; then
                # uvicorn is at /path/to/venv/bin/uvicorn, so venv is parent of bin
                VENV_DIR=$(dirname "$(dirname "$UVICORN_BIN")")
                if [ -f "$VENV_DIR/bin/python3" ]; then
                    PYTHON_CMD="$VENV_DIR/bin/python3"
                    echo "✅ Found Python from uvicorn path: $PYTHON_CMD"
                fi
            fi
        fi
        
        # Method 1c: Get working directory and check for venv there
        if [ -z "$PYTHON_CMD" ]; then
            WORK_DIR=$(readlink -f "/proc/$UVICORN_PID/cwd" 2>/dev/null)
            if [ -n "$WORK_DIR" ]; then
                for VENV_NAME in ".venv" "venv" "env"; do
                    if [ -f "$WORK_DIR/$VENV_NAME/bin/python3" ]; then
                        PYTHON_CMD="$WORK_DIR/$VENV_NAME/bin/python3"
                        echo "✅ Found Python from process working directory: $PYTHON_CMD"
                        break
                    fi
                done
            fi
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

