# IDS/IDPS GUI - Quick Start Guide

## 🎯 After Restoring Your Ubuntu VM Snapshot

### 1️⃣ Transfer Project Files to Ubuntu VM

Make sure your project is located at:
```
~/Random-Forest-Based-IDPS/
```

### 2️⃣ Run the Automated Setup Script

```bash
cd ~/Random-Forest-Based-IDPS

# Make scripts executable
chmod +x setup_gui_complete.sh verify_setup.sh gui/run_gui.sh

# Run the setup
./setup_gui_complete.sh
```

**Setup Time**: ~5-10 minutes  
**What it does**: Installs everything, creates database, sets up services, saves credentials

### 3️⃣ Verify Setup (Optional but Recommended)

```bash
./verify_setup.sh
```

This checks all components and tells you if something is wrong.

### 4️⃣ Get Your Login Credentials

```bash
cat ~/ids_idps_credentials.txt
```

Save these credentials - you'll need them to login!

### 5️⃣ Launch the GUI

**Option A - Run Script:**
```bash
cd ~/Random-Forest-Based-IDPS/gui
./run_gui.sh
```

**Option B - Application Menu:**
- Press `Super` key (Windows key)
- Type "IDS/IDPS Dashboard"
- Click the app

**Option C - Manual:**
```bash
cd ~/Random-Forest-Based-IDPS/gui
source .venv/bin/activate
python3 main.py
```

---

## 🔧 Common Commands

### Backend Management
```bash
# Check backend status
sudo systemctl status ids-idps-backend

# Restart backend
sudo systemctl restart ids-idps-backend

# View logs
sudo journalctl -u ids-idps-backend -f

# Test API
curl http://localhost:8000/health
```

### Database
```bash
# Connect to database
psql -U ids_user -d ids_idps_db -h localhost

# Re-seed database (resets data and shows new passwords)
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
python3 seed_data.py
```

### GUI
```bash
# Launch GUI
cd ~/Random-Forest-Based-IDPS/gui && ./run_gui.sh

# If DISPLAY error, try:
export DISPLAY=:0
cd ~/Random-Forest-Based-IDPS/gui && ./run_gui.sh
```

---

## 🚨 Troubleshooting

### "Backend API not responding"
```bash
sudo systemctl restart ids-idps-backend
sleep 3
curl http://localhost:8000/health
```

### "Cannot connect to display"
```bash
export DISPLAY=:0
# Then try launching GUI again
```

### "Database connection error"
```bash
sudo systemctl restart postgresql
sudo systemctl restart ids-idps-backend
```

### "ModuleNotFoundError: PyQt5"
```bash
cd ~/Random-Forest-Based-IDPS/gui
source .venv/bin/activate
pip install --force-reinstall PyQt5
```

### "Invalid OTP code" (2FA)
```bash
# Fix time synchronization
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd
```

---

## 📋 Verification Checklist

Before launching GUI, ensure:

- [ ] Backend service running: `sudo systemctl status ids-idps-backend`
- [ ] API responds: `curl http://localhost:8000/health`
- [ ] Database accessible: `psql -U ids_user -d ids_idps_db -h localhost`
- [ ] You have credentials: `cat ~/ids_idps_credentials.txt`
- [ ] DISPLAY is set: `echo $DISPLAY`

---

## 📞 Quick Help

**Read the full guide**: `GUI_SETUP_GUIDE.md`

**Files created by setup**:
- `~/Random-Forest-Based-IDPS/backend/.venv` - Backend Python environment
- `~/Random-Forest-Based-IDPS/backend/.env` - Backend configuration
- `~/Random-Forest-Based-IDPS/gui/.venv` - GUI Python environment
- `~/ids_idps_credentials.txt` - Your login credentials
- `/etc/systemd/system/ids-idps-backend.service` - Backend service

**Important URLs**:
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Health Check: http://localhost:8000/health

---

## ✨ That's It!

You should now have:
✅ Backend running automatically  
✅ Database populated with demo data  
✅ GUI ready to launch  
✅ Credentials saved  

**Launch the GUI and login!** 🚀

