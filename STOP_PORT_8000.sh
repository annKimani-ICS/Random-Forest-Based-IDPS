#!/bin/bash
# Quick script to free port 8000 and restart the backend

echo "🔍 Finding processes using port 8000..."

# Find and kill processes using port 8000
PID=$(lsof -ti :8000)
if [ -z "$PID" ]; then
    # Try alternative method
    PID=$(ss -tlnp | grep :8000 | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | head -1)
fi

if [ ! -z "$PID" ]; then
    echo "⚠️  Found process $PID using port 8000"
    echo "🛑 Killing process..."
    kill -9 $PID 2>/dev/null || sudo kill -9 $PID
    sleep 1
    echo "✅ Process killed"
else
    echo "ℹ️  No process found on port 8000"
fi

# Also try stopping any uvicorn processes
pkill -9 uvicorn 2>/dev/null || sudo pkill -9 uvicorn
sleep 1

# Stop the systemd service
echo "🛑 Stopping ids-idps-backend service..."
sudo systemctl stop ids-idps-backend

# Wait a moment
sleep 2

# Verify port is free
if lsof -i :8000 > /dev/null 2>&1; then
    echo "⚠️  Port 8000 still in use, trying harder..."
    sudo fuser -k 8000/tcp 2>/dev/null
    sleep 2
fi

# Verify
if lsof -i :8000 > /dev/null 2>&1; then
    echo "❌ Port 8000 is still in use. Please manually check:"
    echo "   sudo lsof -i :8000"
    echo "   sudo fuser -k 8000/tcp"
else
    echo "✅ Port 8000 is now free"
    
    # Restart the service
    echo "🔄 Starting ids-idps-backend service..."
    sudo systemctl daemon-reload
    sudo systemctl start ids-idps-backend
    
    sleep 3
    
    # Check status
    if sudo systemctl is-active --quiet ids-idps-backend; then
        echo "✅ Backend service started successfully"
        echo "📋 Service status:"
        sudo systemctl status ids-idps-backend --no-pager -l
    else
        echo "❌ Backend service failed to start"
        echo "📋 Checking logs:"
        sudo journalctl -u ids-idps-backend -n 20 --no-pager
    fi
fi

