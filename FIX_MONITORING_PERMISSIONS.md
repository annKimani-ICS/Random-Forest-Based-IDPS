# Fix Monitoring Permissions Issue

## Problem
The backend service cannot capture packets because it lacks the necessary permissions. Error:
```
❌ Error during monitoring: [Errno 1] Operation not permitted
```

## Solution 1: Grant CAP_NET_RAW capability (Recommended)

This allows packet capture without running as root:

```bash
# Stop the service
sudo systemctl stop ids-idps-backend

# Edit the systemd service file
sudo nano /etc/systemd/system/ids-idps-backend.service
```

Add `AmbientCapabilities=CAP_NET_RAW` and `CapabilityBoundingSet=CAP_NET_RAW` to the `[Service]` section:

```ini
[Unit]
Description=IDS/IDPS Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=YOUR_USERNAME
Group=YOUR_GROUP
WorkingDirectory=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/backend
Environment="PATH=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/backend/.venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/backend/.env
ExecStart=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/backend/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
AmbientCapabilities=CAP_NET_RAW
CapabilityBoundingSet=CAP_NET_RAW

[Install]
WantedBy=multi-user.target
```

Then reload and restart:
```bash
sudo systemctl daemon-reload
sudo systemctl start ids-idps-backend
sudo systemctl status ids-idps-backend
```

## Solution 2: Use setcap on Python binary (Alternative)

```bash
# Make Python executable allow packet capture
sudo setcap cap_net_raw,cap_net_admin=eip $(which python3)

# Or specifically on your venv Python
sudo setcap cap_net_raw,cap_net_admin=eip ~/Random-Forest-Based-IDPS/backend/.venv/bin/python3
```

## Solution 3: Run as root (NOT recommended for production)

Only for testing. Modify the service to run as root:

```ini
[Service]
Type=simple
User=root
# ... rest of config
```

Then restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart ids-idps-backend
```

## Verify

After applying the fix, check backend logs:
```bash
sudo journalctl -u ids-idps-backend -f
```

Then try starting monitoring from the GUI. You should see:
- `[BACKEND] Calling sniff() on interface enp0s3...`
- NO "Operation not permitted" errors
- `is_monitoring = True` in status checks

