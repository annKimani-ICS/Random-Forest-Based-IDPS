# IDS/IDPS Desktop GUI - Complete Setup Guide

## 📋 Overview

This guide provides step-by-step instructions for setting up the IDS/IDPS Desktop GUI application on Ubuntu after restoring your VM snapshot.

## 🎯 What This Setup Does

The automated setup script will:

1. ✅ Install all system dependencies (Python, PostgreSQL, PyQt5, etc.)
2. ✅ Configure time synchronization (critical for 2FA)
3. ✅ Set up PostgreSQL database with proper permissions
4. ✅ Create and configure backend Python environment
5. ✅ Generate secure JWT secrets automatically
6. ✅ Initialize database with demo data
7. ✅ Create systemd service for backend (auto-starts on boot)
8. ✅ Set up GUI Python environment with all dependencies
9. ✅ Create desktop application launcher
10. ✅ Configure firewall rules
11. ✅ Save login credentials securely

## 🚀 Quick Start (Recommended)

### 1. Restore Your VM Snapshot

First, restore your Ubuntu VM to the clean snapshot state.

### 2. Copy Project Files

Ensure your project is at: `~/Random-Forest-Based-IDPS/`

```bash
cd ~
ls -la Random-Forest-Based-IDPS/
# Should show: backend/, gui/, models/, etc.
```

### 3. Run the Automated Setup

```bash
cd ~/Random-Forest-Based-IDPS
chmod +x setup_gui_complete.sh
./setup_gui_complete.sh
```

### 4. Follow the Prompts

- Press Enter to use default database password, or type 'n' to set custom
- Wait for all 11 setup steps to complete (~5-10 minutes)
- Setup will automatically save your login credentials
- Choose whether to launch GUI immediately at the end

### 5. Login to the Application

Use the credentials saved in `~/ids_idps_credentials.txt`:

```bash
cat ~/ids_idps_credentials.txt
```

Default format:
- **Admin**: `admin@ids-idps.com` / `[generated password]`
- **Analyst**: `analyst@ids-idps.com` / `[generated password]`

## 📁 What Gets Created

```
~/Random-Forest-Based-IDPS/
├── backend/
│   ├── .venv/                    # Python virtual environment
│   └── .env                      # Environment configuration
├── gui/
│   └── .venv/                    # GUI Python virtual environment
└── [project files]

~/.local/share/applications/
└── ids-idps.desktop              # Desktop launcher

/etc/systemd/system/
└── ids-idps-backend.service      # Backend auto-start service

~/ids_idps_credentials.txt        # Login credentials (KEEP SECURE!)
```

## 🎮 Using the Application

### Starting the GUI

**Method 1: Desktop Launcher (Easiest)**
```bash
# Press Super/Windows key
# Type "IDS/IDPS Dashboard"
# Click the application icon
```

**Method 2: Run Script**
```bash
cd ~/Random-Forest-Based-IDPS/gui
./run_gui.sh
```

**Method 3: Manual Launch**
```bash
cd ~/Random-Forest-Based-IDPS/gui
source .venv/bin/activate
python3 main.py
```

### Backend Management

The backend runs automatically as a systemd service:

```bash
# Check backend status
sudo systemctl status ids-idps-backend

# Restart backend
sudo systemctl restart ids-idps-backend

# Stop backend
sudo systemctl stop ids-idps-backend

# View real-time logs
sudo journalctl -u ids-idps-backend -f

# View last 50 log lines
sudo journalctl -u ids-idps-backend -n 50
```

### Test Backend API

```bash
# Health check
curl http://localhost:8000/health

# Should return: {"status":"healthy"}

# View API documentation
# Open browser: http://localhost:8000/docs
```

## 🔧 Troubleshooting

### Issue 1: GUI Won't Start

**Symptom**: `Cannot connect to display` or GUI window doesn't appear

**Solution**:
```bash
# Check DISPLAY variable
echo $DISPLAY

# If empty, set it
export DISPLAY=:0

# Try launching again
cd ~/Random-Forest-Based-IDPS/gui && ./run_gui.sh

# For SSH sessions, use X11 forwarding
ssh -X username@vm-ip-address
```

### Issue 2: Backend Service Not Running

**Symptom**: GUI shows "Backend API not responding"

**Solution**:
```bash
# Check service status
sudo systemctl status ids-idps-backend

# Check for errors in logs
sudo journalctl -u ids-idps-backend -n 50

# Restart service
sudo systemctl restart ids-idps-backend

# Wait 3 seconds, then test
sleep 3
curl http://localhost:8000/health
```

### Issue 3: Database Connection Errors

**Symptom**: Backend logs show "could not connect to database"

**Solution**:
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql

# Test database connection
psql -U ids_user -d ids_idps_db -h localhost

# If password fails, check .env file
cat ~/Random-Forest-Based-IDPS/backend/.env | grep DATABASE_URL
```

### Issue 4: PyQt5 Import Errors

**Symptom**: `ModuleNotFoundError: No module named 'PyQt5'`

**Solution**:
```bash
cd ~/Random-Forest-Based-IDPS/gui

# Activate virtual environment
source .venv/bin/activate

# Reinstall PyQt5
pip install --force-reinstall PyQt5

# Test import
python3 -c "import PyQt5; print('PyQt5 OK')"

# If still fails, install system-wide
sudo apt install python3-pyqt5 python3-pyqt5.qtsvg
```

### Issue 5: 2FA Codes Not Working

**Symptom**: "Invalid OTP code" even with correct code

**Solution**:
```bash
# Check time synchronization (CRITICAL!)
timedatectl status

# If not synchronized, fix it
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd

# Wait a moment
sleep 5

# Verify time sync
timedatectl status | grep "synchronized"

# Check time matches your phone/authenticator device
date
```

### Issue 6: Forgot Login Credentials

**Solution**:
```bash
# View saved credentials
cat ~/ids_idps_credentials.txt

# If file is missing, reset passwords via database
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
python3 seed_data.py  # Re-runs seeding (will show new passwords)
```

### Issue 7: Port 8000 Already in Use

**Symptom**: Backend fails to start, logs show "Address already in use"

**Solution**:
```bash
# Find process using port 8000
sudo lsof -i :8000

# Kill the process (replace PID with actual number)
sudo kill -9 <PID>

# Or kill all uvicorn processes
sudo pkill -9 uvicorn

# Restart backend
sudo systemctl restart ids-idps-backend
```

## 🛡️ Security Best Practices

After setup, immediately:

1. **Change Default Passwords**
   - Login to GUI as admin
   - Navigate to Settings
   - Update password

2. **Enable 2FA for Admin Accounts**
   - Login as admin
   - Go to Settings → Security
   - Click "Enable 2FA"
   - Scan QR code with Google Authenticator
   - Save backup codes

3. **Secure Credentials File**
   ```bash
   # Move credentials to secure location
   mkdir -p ~/secure
   mv ~/ids_idps_credentials.txt ~/secure/
   chmod 600 ~/secure/ids_idps_credentials.txt
   ```

4. **Review Firewall Rules**
   ```bash
   sudo ufw status
   # Ensure only necessary ports are open
   ```

5. **Regular Backups**
   ```bash
   # Backup database
   pg_dump -U ids_user -d ids_idps_db > ~/backup_$(date +%Y%m%d).sql
   ```

## 📊 Verification Checklist

Before considering setup complete, verify:

- [ ] PostgreSQL is running: `sudo systemctl status postgresql`
- [ ] Backend service is active: `sudo systemctl status ids-idps-backend`
- [ ] Backend API responds: `curl http://localhost:8000/health`
- [ ] Database exists: `psql -U ids_user -d ids_idps_db -h localhost -c '\dt'`
- [ ] GUI can import PyQt5: `cd ~/Random-Forest-Based-IDPS/gui && source .venv/bin/activate && python3 -c "import PyQt5"`
- [ ] Time is synchronized: `timedatectl status | grep synchronized`
- [ ] You have saved login credentials
- [ ] GUI launches without errors
- [ ] You can login successfully

## 🔄 Updating the Application

If you pull new code from git:

```bash
cd ~/Random-Forest-Based-IDPS

# Pull updates
git pull

# Update backend dependencies
cd backend
source .venv/bin/activate
pip install -r requirements.txt

# Restart backend
sudo systemctl restart ids-idps-backend

# Update GUI dependencies
cd ../gui
source .venv/bin/activate
pip install -r requirements.txt

# Restart GUI (close and reopen)
```

## 🗑️ Complete Removal

To completely remove the installation:

```bash
# Stop and disable backend service
sudo systemctl stop ids-idps-backend
sudo systemctl disable ids-idps-backend
sudo rm /etc/systemd/system/ids-idps-backend.service
sudo systemctl daemon-reload

# Drop database
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ids_idps_db;"
sudo -u postgres psql -c "DROP USER IF EXISTS ids_user;"

# Remove virtual environments
rm -rf ~/Random-Forest-Based-IDPS/backend/.venv
rm -rf ~/Random-Forest-Based-IDPS/gui/.venv

# Remove desktop launcher
rm ~/.local/share/applications/ids-idps.desktop
update-desktop-database ~/.local/share/applications

# Remove credentials file
rm ~/ids_idps_credentials.txt

# Optionally remove system packages (if not needed for other projects)
sudo apt remove --purge postgresql postgresql-contrib python3-pyqt5
sudo apt autoremove
```

## 📞 Support & Additional Help

### Useful Commands Reference

```bash
# === Backend ===
sudo systemctl status ids-idps-backend
sudo systemctl restart ids-idps-backend
sudo journalctl -u ids-idps-backend -f

# === Database ===
psql -U ids_user -d ids_idps_db -h localhost
sudo -u postgres psql

# === Testing ===
curl http://localhost:8000/health
curl http://localhost:8000/docs

# === Logs ===
sudo journalctl -u ids-idps-backend -n 100 --no-pager
sudo journalctl -u postgresql -n 50 --no-pager

# === GUI ===
cd ~/Random-Forest-Based-IDPS/gui && ./run_gui.sh
```

### Log Locations

- **Backend Logs**: `sudo journalctl -u ids-idps-backend`
- **PostgreSQL Logs**: `sudo journalctl -u postgresql`
- **System Logs**: `/var/log/syslog`

## 🎓 Understanding the Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Ubuntu Desktop VM                        │
│                                                             │
│  ┌────────────────────┐         ┌────────────────────────┐ │
│  │   PyQt5 Desktop    │   HTTP  │   FastAPI Backend      │ │
│  │   GUI Application  │◄───────►│   (systemd service)    │ │
│  │   (manual launch)  │         │   Port 8000            │ │
│  └────────────────────┘         └───────────┬────────────┘ │
│                                              │              │
│                                              ▼              │
│                                  ┌──────────────────────┐  │
│                                  │  PostgreSQL Database │  │
│                                  │  - Users & Auth      │  │
│                                  │  - Alerts            │  │
│                                  │  - Models            │  │
│                                  │  - Thresholds        │  │
│                                  │  - Block Rules       │  │
│                                  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## ✨ Features You'll Get

After successful setup, your GUI will have:

- 🔐 **Secure Authentication**: Email/password + optional 2FA
- 📊 **Real-time Dashboard**: KPIs, metrics, recent alerts
- 🚨 **Alert Management**: View, filter, acknowledge, and block alerts
- ⚙️ **Settings Panel**: Adjust detection threshold, manage blocks (Admin only)
- 👥 **User Management**: Create users, manage roles (Admin only)
- 🎨 **Modern UI**: Clean PyQt5 interface with dark theme
- 🔄 **Auto-refresh**: Dashboard updates every 30 seconds
- 📈 **Visualizations**: Charts, graphs, and color-coded indicators

## 📝 Notes

- Backend runs as a systemd service and starts automatically on boot
- GUI must be launched manually (it's a desktop app, not a web service)
- Time synchronization is critical for 2FA to work properly
- Always keep your credentials file secure
- Change default passwords immediately after first login
- Enable 2FA for production use

---

**Need more help?** Check the logs, verify each component separately, and ensure all prerequisites are met.

**Good luck!** 🚀

