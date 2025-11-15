#!/bin/bash
# Simple script to clear all alerts from database
# Automatically finds the Python virtual environment

cd "$(dirname "$0")"
CURRENT_DIR="$(pwd)"

echo "🔍 Searching for virtual environment..."

PYTHON_CMD=""

# Method 1: Read systemd service file directly (most reliable)
if [ -f "/etc/systemd/system/ids-idps-backend.service" ]; then
    echo "📋 Reading systemd service file..."
    # Extract WorkingDirectory
    WORK_DIR=$(grep "^WorkingDirectory=" /etc/systemd/system/ids-idps-backend.service | sed 's/WorkingDirectory=//' | tr -d ' ')
    # Extract ExecStart to get uvicorn path
    EXEC_START=$(grep "^ExecStart=" /etc/systemd/system/ids-idps-backend.service | sed 's/ExecStart=//' | tr -d ' ')
    
    if [ -n "$EXEC_START" ]; then
        # Extract the uvicorn binary path (everything before "uvicorn")
        UVICORN_BIN=$(echo "$EXEC_START" | sed 's|/uvicorn.*||')
        if [ -n "$UVICORN_BIN" ] && [ -d "$UVICORN_BIN" ]; then
            # uvicorn is at /path/to/venv/bin/uvicorn, so venv is the parent of bin
            VENV_DIR=$(dirname "$UVICORN_BIN")
            if [ -f "$VENV_DIR/python3" ]; then
                PYTHON_CMD="$VENV_DIR/python3"
                echo "✅ Found Python from systemd ExecStart: $PYTHON_CMD"
            fi
        fi
    fi
    
    # Also check WorkingDirectory for venv
    if [ -z "$PYTHON_CMD" ] && [ -n "$WORK_DIR" ]; then
        for VENV_NAME in ".venv" "venv" "env"; do
            if [ -f "$WORK_DIR/$VENV_NAME/bin/python3" ]; then
                PYTHON_CMD="$WORK_DIR/$VENV_NAME/bin/python3"
                echo "✅ Found Python from systemd WorkingDirectory: $PYTHON_CMD"
                break
            fi
        done
    fi
fi

# Method 2: Check running uvicorn process
if [ -z "$PYTHON_CMD" ] && pgrep -f "uvicorn.*app.main:app" > /dev/null; then
    UVICORN_PID=$(pgrep -f "uvicorn.*app.main:app" | head -1)
    echo "🔍 Found running uvicorn process (PID $UVICORN_PID)"
    
    if [ -n "$UVICORN_PID" ] && [ -f "/proc/$UVICORN_PID/exe" ]; then
        PYTHON_EXE=$(readlink -f "/proc/$UVICORN_PID/exe" 2>/dev/null)
        if [ -n "$PYTHON_EXE" ] && [ -f "$PYTHON_EXE" ]; then
            PYTHON_CMD="$PYTHON_EXE"
            echo "✅ Found Python from running process: $PYTHON_CMD"
        fi
    fi
    
    # Also try to get uvicorn path from cmdline
    if [ -z "$PYTHON_CMD" ] && [ -f "/proc/$UVICORN_PID/cmdline" ]; then
        UVICORN_CMD=$(cat "/proc/$UVICORN_PID/cmdline" 2>/dev/null | tr '\0' ' ')
        UVICORN_BIN=$(echo "$UVICORN_CMD" | awk '{print $1}')
        if [ -n "$UVICORN_BIN" ] && [ -f "$UVICORN_BIN" ]; then
            VENV_DIR=$(dirname "$(dirname "$UVICORN_BIN")")
            if [ -f "$VENV_DIR/bin/python3" ]; then
                PYTHON_CMD="$VENV_DIR/bin/python3"
                echo "✅ Found Python from uvicorn binary: $PYTHON_CMD"
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

# If still not found, show detailed debug info and try to help
if [ -z "$PYTHON_CMD" ]; then
    echo ""
    echo "❌ Could not find Python virtual environment"
    echo ""
    echo "📋 Debug Information:"
    
    # Show systemd service content
    if [ -f "/etc/systemd/system/ids-idps-backend.service" ]; then
        echo ""
        echo "Systemd service file contents:"
        echo "---"
        grep -E "^(WorkingDirectory|ExecStart)=" /etc/systemd/system/ids-idps-backend.service || echo "  (could not read)"
        echo "---"
    fi
    
    # Show running process info
    if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
        UVICORN_PID=$(pgrep -f "uvicorn.*app.main:app" | head -1)
        echo ""
        echo "Running uvicorn process (PID $UVICORN_PID):"
        if [ -f "/proc/$UVICORN_PID/cmdline" ]; then
            echo "  Command: $(cat /proc/$UVICORN_PID/cmdline | tr '\0' ' ')"
        fi
        if [ -f "/proc/$UVICORN_PID/cwd" ]; then
            echo "  Working Dir: $(readlink -f /proc/$UVICORN_PID/cwd 2>/dev/null)"
        fi
        if [ -f "/proc/$UVICORN_PID/exe" ]; then
            echo "  Executable: $(readlink -f /proc/$UVICORN_PID/exe 2>/dev/null)"
        fi
    fi
    
    echo ""
    echo "💡 Manual Solution:"
    echo "   Run this command to find uvicorn, then use its venv's python:"
    echo "   UVICORN=\$(which uvicorn 2>/dev/null || find / -name uvicorn -type f 2>/dev/null | head -1)"
    echo "   VENV_DIR=\$(dirname \$(dirname \"\$UVICORN\"))"
    echo "   \"\$VENV_DIR/bin/python3\" clear_all_alerts.py"
    echo ""
    echo "   Or if you know the venv path:"
    echo "   /path/to/venv/bin/python3 clear_all_alerts.py"
    exit 1
fi

# Run the clear script
echo ""
echo "🧹 Clearing all alerts from database..."
echo "   Using: $PYTHON_CMD"
$PYTHON_CMD clear_all_alerts.py

echo ""
echo "✅ Done! Database is clean. Only malicious alerts will appear when you simulate attacks."

