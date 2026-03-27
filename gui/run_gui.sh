#!/bin/bash
# Launch IDS/IDPS Desktop GUI Application

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Activate virtual environment
source "$SCRIPT_DIR/.venv/bin/activate"

# Check if backend is running
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "⚠️  Warning: Backend API not responding at http://localhost:8000"
    echo "Please ensure the backend service is running:"
    echo "  sudo systemctl status ids-idps-backend"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Launch GUI
echo "🚀 Launching IDS/IDPS Desktop GUI..."
python3 "$SCRIPT_DIR/main.py"

