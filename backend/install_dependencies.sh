#!/bin/bash
# Install backend dependencies for traffic monitoring diagnostics

echo "🔧 Installing backend dependencies..."

# Check if we're in the backend directory
if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found. Run this from the backend/ directory."
    exit 1
fi

# Install dependencies
echo "📦 Installing Python packages from requirements.txt..."
pip3 install -r requirements.txt

# Also install scapy if not already installed (needed for packet capture)
echo "📦 Installing scapy for packet capture..."
pip3 install scapy

echo ""
echo "✅ Dependencies installed!"
echo ""
echo "You can now run:"
echo "  python3 debug_traffic_monitoring.py"
echo ""

