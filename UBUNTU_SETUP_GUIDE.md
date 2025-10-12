# Ubuntu VM Setup Guide

## 🐧 Quick Setup for Ubuntu Virtual Machine

This guide provides automated scripts to set up and run the IDS/IDPS system on Ubuntu, resolving the "externally-managed-environment" error.

---

## 🚀 One-Command Setup

### Option 1: Fresh Clone & Setup
```bash
# Clone the repository
git clone https://github.com/annKimani-ICS/Random-Forest-Based-IDPS.git
cd Random-Forest-Based-IDPS

# Run automated setup (handles everything!)
chmod +x setup.sh
./setup.sh
```

### Option 2: Update Existing Project
```bash
# Navigate to your project
cd ~/Random-Forest-Based-IDPS

# Pull latest changes
git fetch origin
git pull origin feat/sprint4-admin-dashboard

# Run setup (will update dependencies)
chmod +x setup.sh
./setup.sh
```

---

## 🎯 What the Scripts Do

### `setup.sh` - Complete Setup
- ✅ Creates virtual environment automatically
- ✅ Installs all backend dependencies
- ✅ Installs all GUI dependencies  
- ✅ Tests imports to verify installation
- ✅ Makes all scripts executable
- ✅ Provides clear next steps

### `run_backend.sh` - Backend Startup
- ✅ Activates virtual environment automatically
- ✅ Checks dependencies are installed
- ✅ Starts FastAPI server on port 8000
- ✅ Provides helpful status messages

### `run_gui.sh` - GUI Startup
- ✅ Activates virtual environment automatically
- ✅ Checks GUI dependencies
- ✅ Verifies backend is running
- ✅ Starts PyQt5 desktop application

### `run_full_system.sh` - Everything Together
- ✅ Starts backend in background
- ✅ Waits for backend to be ready
- ✅ Starts GUI application
- ✅ Handles cleanup on exit (Ctrl+C)

---

## 📋 Step-by-Step Usage

### 1. Initial Setup
```bash
# Download and setup
git clone https://github.com/annKimani-ICS/Random-Forest-Based-IDPS.git
cd Random-Forest-Based-IDPS
chmod +x setup.sh
./setup.sh
```

### 2. Start the System

#### Option A: Start Everything Together
```bash
./run_full_system.sh
```

#### Option B: Start Separately (Recommended for Development)
```bash
# Terminal 1 - Backend
./run_backend.sh

# Terminal 2 - GUI (open new terminal)
./run_gui.sh
```

### 3. Access the System
- **GUI Application**: Desktop window will open
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

---

## 🔧 Troubleshooting

### "externally-managed-environment" Error
**Solution**: The automation scripts handle this automatically by using virtual environments.

### Permission Denied
```bash
# Make scripts executable
chmod +x *.sh
```

### Python Version Issues
```bash
# Check Python version
python3 --version

# Should be 3.8+ (recommended: 3.10+)
```

### Port Already in Use
```bash
# Check what's using port 8000
lsof -i :8000

# Kill process if needed
sudo kill -9 <PID>
```

### GUI Won't Start
```bash
# Check if backend is running
curl http://localhost:8000/docs

# If not running, start backend first
./run_backend.sh
```

---

## 📱 Multi-Factor Authentication

After logging in, you can enable MFA:

1. **Click the 🔐 Security tab**
2. **Click "Enable Two-Factor Authentication"**
3. **Scan QR code** with Google Authenticator
4. **Enter verification code**
5. **Save recovery codes**

📚 **Detailed guides:**
- `QUICK_START_MFA.md` - Quick setup
- `MFA_SETUP_GUIDE.md` - Complete guide

---

## 🔄 Updating the System

### Pull Latest Changes
```bash
cd ~/Random-Forest-Based-IDPS

# Fetch and pull updates
git fetch origin
git pull origin feat/sprint4-admin-dashboard

# Re-run setup if needed
./setup.sh
```

### Update Dependencies Only
```bash
# Activate virtual environment
source venv/bin/activate

# Update backend dependencies
cd backend
pip install -r requirements.txt

# Update GUI dependencies
cd ../gui
pip install -r requirements.txt
```

---

## 📊 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 18.04+ (20.04+ recommended)
- **RAM**: 2GB minimum (4GB recommended)
- **Storage**: 2GB free space
- **Python**: 3.8+ (3.10+ recommended)

### Dependencies Installed
- **Backend**: FastAPI, SQLAlchemy, pyotp, qrcode, etc.
- **GUI**: PyQt5, matplotlib, requests, etc.
- **Database**: PostgreSQL (if using external DB)

---

## 🎯 Quick Commands Reference

| Task | Command |
|------|---------|
| **Setup** | `./setup.sh` |
| **Start Backend** | `./run_backend.sh` |
| **Start GUI** | `./run_gui.sh` |
| **Start Both** | `./run_full_system.sh` |
| **Manual Activation** | `source venv/bin/activate` |
| **Update Project** | `git pull origin feat/sprint4-admin-dashboard` |

---

## 🎉 Success Indicators

After successful setup, you should see:

```
🎉 Setup Complete!
==================================

🚀 Quick Start Commands:

Start Backend:
  ./run_backend.sh

Start GUI (in new terminal):
  ./run_gui.sh

Manual activation:
  source venv/bin/activate

📚 Documentation:
  README.md - Main project documentation
  README_MFA.md - MFA setup guide
  QUICK_START_MFA.md - Quick MFA guide

Happy coding! 🎊
```

---

## 📞 Need Help?

1. **Check logs** in the terminal output
2. **Verify Python version**: `python3 --version`
3. **Check dependencies**: `source venv/bin/activate && pip list`
4. **Test imports**: `python -c "import fastapi, PyQt5"`
5. **Review documentation**: `cat README.md`

---

**Your IDS/IDPS system with MFA is now ready to run! 🚀**
