# IDS/IDPS Desktop GUI - Complete Setup Documentation

<div align="center">

## 🛡️ Random Forest Based Intrusion Detection & Prevention System
### Desktop GUI Application for Ubuntu

[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109.0-green.svg)](https://fastapi.tiangolo.com)
[![PyQt5](https://img.shields.io/badge/PyQt5-5.15.10-orange.svg)](https://riverbankcomputing.com/software/pyqt/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://postgresql.org)

</div>

---

## 📑 Table of Contents

- [Overview](#overview)
- [What's New - Automated Setup](#whats-new---automated-setup)
- [Quick Start](#quick-start)
- [Detailed Documentation](#detailed-documentation)
- [System Requirements](#system-requirements)
- [Architecture](#architecture)
- [Features](#features)
- [Setup Options](#setup-options)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Support](#support)

---

## 🎯 Overview

This is a **desktop GUI application** for Ubuntu that provides a comprehensive admin interface for managing the Random Forest-based IDS/IDPS system. It includes:

- 🔐 **Secure Authentication** with optional 2FA/TOTP
- 📊 **Real-time Dashboard** with metrics and KPIs
- 🚨 **Alert Management** (view, filter, acknowledge, block)
- ⚙️ **Settings Panel** (threshold adjustment, block rules)
- 👥 **User Management** (create, edit, role-based access)
- 🎨 **Modern PyQt5 Interface** with intuitive design

---

## ⭐ What's New - Automated Setup

### 🚀 New Comprehensive Setup System

We've created a **fully automated setup system** that eliminates all previous issues:

#### ✅ Fixed Issues:
- ❌ **OLD**: Path mismatch (`~/ids-idps/` vs actual project location)
- ✅ **NEW**: Auto-detects correct project directory
- ❌ **OLD**: Manual configuration required
- ✅ **NEW**: Completely automated with verification
- ❌ **OLD**: No error checking
- ✅ **NEW**: Comprehensive validation and auto-fixes

#### 📦 New Files Included:

| File | Purpose | When to Use |
|------|---------|-------------|
| `setup_gui_complete.sh` | **Main automated setup** | Run once after VM restore ⭐ |
| `verify_setup.sh` | Comprehensive verification | After setup, or when troubleshooting |
| `fix_common_issues.sh` | Auto-fix common problems | When encountering issues |
| `GUI_SETUP_GUIDE.md` | Complete detailed guide | For in-depth reference |
| `QUICK_START.md` | Quick reference card | For fast lookups |
| `STEP_BY_STEP_VISUAL_GUIDE.md` | Visual walkthrough | For first-time setup |
| `GUI_SETUP_SUMMARY.md` | Overview of everything | To understand the system |

---

## 🚀 Quick Start

### After Restoring Your Ubuntu VM Snapshot

```bash
# 1. Navigate to project
cd ~/Random-Forest-Based-IDPS

# 2. Make scripts executable
chmod +x setup_gui_complete.sh verify_setup.sh fix_common_issues.sh gui/run_gui.sh

# 3. Run automated setup (this does everything!)
./setup_gui_complete.sh

# 4. Get your login credentials
cat ~/ids_idps_credentials.txt

# 5. Launch the GUI
cd gui && ./run_gui.sh
```

**That's it!** The setup script handles:
- ✅ System package installation
- ✅ PostgreSQL database setup
- ✅ Backend API configuration
- ✅ GUI environment setup
- ✅ Service creation & startup
- ✅ Desktop launcher
- ✅ Credential generation

**Time Required**: ~5-10 minutes

---

## 📚 Detailed Documentation

### Choose Your Guide:

#### 🎯 For First-Time Setup
👉 **Start here**: [`STEP_BY_STEP_VISUAL_GUIDE.md`](STEP_BY_STEP_VISUAL_GUIDE.md)
- Visual walkthrough with diagrams
- Screenshots of what to expect
- Step-by-step instructions
- Perfect for beginners

#### ⚡ For Quick Reference
👉 **Quick commands**: [`QUICK_START.md`](QUICK_START.md)
- Essential commands only
- Common troubleshooting fixes
- Quick verification checklist
- Perfect for experienced users

#### 📖 For Complete Details
👉 **Full guide**: [`GUI_SETUP_GUIDE.md`](GUI_SETUP_GUIDE.md)
- Comprehensive setup instructions
- Detailed troubleshooting section
- Architecture explanations
- Security best practices
- Advanced configurations

#### 📝 For System Overview
👉 **Summary**: [`GUI_SETUP_SUMMARY.md`](GUI_SETUP_SUMMARY.md)
- Overview of all components
- What gets installed
- File structure
- Component interactions

---

## 💻 System Requirements

### Hardware
- **RAM**: 4GB minimum (8GB recommended)
- **Disk**: 20GB free space
- **CPU**: 2+ cores recommended

### Software
- **OS**: Ubuntu 22.04 LTS (Desktop or Server with GUI)
- **Display**: X11 or Wayland display server
- **Network**: Internet connection for initial setup

### Automatically Installed By Setup Script
- Python 3.10+
- PostgreSQL 14+
- PyQt5 and dependencies
- All required Python packages
- Qt5 framework components

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Ubuntu Desktop VM                         │
│                                                              │
│  ┌─────────────────┐         ┌──────────────────────────┐  │
│  │  PyQt5 Desktop  │  HTTP   │   FastAPI Backend        │  │
│  │  GUI App        │◄────────│   (systemd service)      │  │
│  │  (user launch)  │         │   Port 8000              │  │
│  └─────────────────┘         └──────────┬───────────────┘  │
│                                          │                   │
│                                          ▼                   │
│                              ┌────────────────────────┐     │
│                              │  PostgreSQL Database   │     │
│                              │  - Users & Auth        │     │
│                              │  - Alerts & Events     │     │
│                              │  - Models & Metrics    │     │
│                              │  - Block Rules         │     │
│                              │  - Threshold Config    │     │
│                              └────────────────────────┘     │
│                                                              │
│  Network Traffic → IDS Model → Alerts → Database → GUI      │
└──────────────────────────────────────────────────────────────┘
```

### Component Details:

**Backend API (FastAPI)**
- Runs as systemd service
- Auto-starts on boot
- Listens on port 8000
- RESTful API with JWT auth
- Real-time alert management

**GUI Application (PyQt5)**
- Desktop application (not web)
- Manual launch required
- Connects to backend via HTTP
- Real-time dashboard updates
- Role-based access control

**Database (PostgreSQL)**
- Stores all system data
- Users, alerts, models, settings
- Secure password storage
- Transaction support

---

## ✨ Features

### Authentication & Security
- 🔐 Email/password authentication
- 🔑 JWT token-based sessions
- 📱 Optional 2FA/TOTP (Google Authenticator)
- 🛡️ Rate limiting on login attempts
- 🔒 Account lockout after failed attempts
- 🔐 bcrypt password hashing

### Dashboard
- 📊 Real-time KPIs (alerts, blocks, precision, threshold)
- 📈 Model performance metrics (recall, F1, AUC)
- 🔔 Recent alerts table
- 🔄 Auto-refresh every 30 seconds
- 📉 Visual charts and graphs

### Alert Management
- 🚨 View all alerts with pagination
- 🔍 Filter by status, type, maliciousness
- ✅ Acknowledge alerts
- 🛑 Block malicious IPs
- 🎨 Color-coded severity (red/green)
- 📝 Add notes to alerts

### Settings (Admin Only)
- 🎯 Adjust detection threshold (0.00 - 1.00)
- 📊 Visual threshold preview
- 🛑 View active block rules
- ❌ Deactivate blocks
- ⚙️ System configuration

### User Management (Admin Only)
- 👥 List all users
- ➕ Create new users (admin/analyst)
- ✏️ Edit user details
- 🔄 Activate/deactivate accounts
- 👁️ View last login times
- 🔐 View 2FA status

---

## 🔧 Setup Options

### Option 1: Automated Setup (Recommended) ⭐

**Perfect for**: First-time setup, VM restoration, clean installations

```bash
cd ~/Random-Forest-Based-IDPS
./setup_gui_complete.sh
```

**What it does**: Everything! Completely automated.

**Time**: 5-10 minutes

**Difficulty**: ⭐ Easy

---

### Option 2: Manual Setup

**Perfect for**: Custom configurations, understanding the system

See [`GUI_SETUP_GUIDE.md`](GUI_SETUP_GUIDE.md) for detailed manual setup instructions.

**Time**: 20-30 minutes

**Difficulty**: ⭐⭐⭐ Advanced

---

### Option 3: Verification Only

**Perfect for**: Checking existing setup, troubleshooting

```bash
./verify_setup.sh
```

**What it does**: Checks all components without making changes.

**Time**: 1-2 minutes

**Difficulty**: ⭐ Easy

---

## 🆘 Troubleshooting

### Quick Fixes

#### GUI Won't Start
```bash
export DISPLAY=:0
cd ~/Random-Forest-Based-IDPS/gui && ./run_gui.sh
```

#### Backend Not Responding
```bash
sudo systemctl restart ids-idps-backend
curl http://localhost:8000/health
```

#### Database Connection Error
```bash
sudo systemctl restart postgresql
sudo systemctl restart ids-idps-backend
```

#### Forgot Password
```bash
cat ~/ids_idps_credentials.txt
```

#### 2FA Not Working
```bash
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd
```

### Automated Troubleshooting

Run the auto-fix script:
```bash
./fix_common_issues.sh
```

This automatically:
- ✅ Restarts services
- ✅ Fixes time sync
- ✅ Recreates virtual environments
- ✅ Repairs permissions
- ✅ Verifies database

### Comprehensive Diagnostics

```bash
./verify_setup.sh
```

Shows detailed status of:
- System dependencies
- Project structure
- Backend setup
- Database
- Services
- GUI environment
- Configuration

### Still Having Issues?

1. **Check backend logs**:
   ```bash
   sudo journalctl -u ids-idps-backend -n 50
   ```

2. **Test API directly**:
   ```bash
   curl http://localhost:8000/health
   curl http://localhost:8000/docs
   ```

3. **Verify database**:
   ```bash
   psql -U ids_user -d ids_idps_db -h localhost
   ```

4. **Check detailed guide**:
   See [`GUI_SETUP_GUIDE.md`](GUI_SETUP_GUIDE.md) troubleshooting section

---

## 🔐 Security

### Default Credentials

After setup, credentials are saved to `~/ids_idps_credentials.txt`

**Default users**:
- Admin: `admin@ids-idps.com`
- Analyst: `analyst@ids-idps.com`

**Passwords**: Randomly generated (12+ characters, alphanumeric + symbols)

### Security Checklist

After setup, complete these tasks:

- [ ] Change default passwords
- [ ] Enable 2FA for admin accounts
- [ ] Secure credentials file (`chmod 600 ~/ids_idps_credentials.txt`)
- [ ] Review firewall rules (`sudo ufw status`)
- [ ] Enable auto-updates (`sudo apt install unattended-upgrades`)
- [ ] Regular database backups
- [ ] Monitor audit logs
- [ ] Restrict backend API access (if needed)

### Best Practices

1. **Use 2FA**: Enable for all admin accounts
2. **Strong Passwords**: Change from defaults immediately
3. **Regular Updates**: Keep system and packages updated
4. **Firewall**: Ensure UFW is configured correctly
5. **Backups**: Regular PostgreSQL database backups
6. **Monitoring**: Check logs regularly
7. **Access Control**: Use analyst role for non-admin users

---

## 📞 Support & Resources

### Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Main project README |
| `GUI_SETUP_README.md` | This file - Complete GUI setup |
| `GUI_SETUP_GUIDE.md` | Detailed setup instructions |
| `QUICK_START.md` | Quick reference commands |
| `STEP_BY_STEP_VISUAL_GUIDE.md` | Visual walkthrough |
| `GUI_SETUP_SUMMARY.md` | System overview |
| `README_DESKTOP_GUI.md` | Original GUI documentation |
| `DEPLOYMENT_GUIDE.md` | Web deployment (different system) |

### Scripts

| Script | Purpose |
|--------|---------|
| `setup_gui_complete.sh` | Automated complete setup |
| `verify_setup.sh` | Verification and diagnostics |
| `fix_common_issues.sh` | Auto-fix common problems |
| `gui/run_gui.sh` | Launch GUI application |

### Useful Commands

```bash
# Setup & Verification
./setup_gui_complete.sh          # Complete setup
./verify_setup.sh                # Verify setup
./fix_common_issues.sh           # Auto-fix issues

# Launch GUI
cd gui && ./run_gui.sh           # Start application

# Backend Management
sudo systemctl status ids-idps-backend     # Check status
sudo systemctl restart ids-idps-backend    # Restart
sudo journalctl -u ids-idps-backend -f     # View logs

# Database
psql -U ids_user -d ids_idps_db -h localhost  # Connect

# Testing
curl http://localhost:8000/health          # Health check
curl http://localhost:8000/docs            # API docs

# Credentials
cat ~/ids_idps_credentials.txt             # View passwords
```

### URLs

- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

---

## 🎓 Learning Resources

### Understanding the System

1. **Start with**: `STEP_BY_STEP_VISUAL_GUIDE.md`
   - Visual walkthrough
   - Perfect for first-time setup

2. **Reference**: `QUICK_START.md`
   - Quick commands
   - Common tasks

3. **Deep Dive**: `GUI_SETUP_GUIDE.md`
   - Complete details
   - Advanced topics

4. **Overview**: `GUI_SETUP_SUMMARY.md`
   - System architecture
   - Component interactions

### Common Workflows

#### First-Time Setup
```bash
1. Restore VM snapshot
2. cd ~/Random-Forest-Based-IDPS
3. chmod +x setup_gui_complete.sh
4. ./setup_gui_complete.sh
5. cat ~/ids_idps_credentials.txt
6. cd gui && ./run_gui.sh
7. Login and change password
8. Enable 2FA
```

#### Daily Use
```bash
# Launch GUI
cd ~/Random-Forest-Based-IDPS/gui && ./run_gui.sh

# Backend runs automatically (no action needed)
```

#### After System Restart
```bash
# Backend auto-starts (systemd service)
# Just launch GUI
cd ~/Random-Forest-Based-IDPS/gui && ./run_gui.sh
```

#### Troubleshooting
```bash
# Quick fix
./fix_common_issues.sh

# Detailed check
./verify_setup.sh

# Manual restart
sudo systemctl restart ids-idps-backend
```

---

## 🎯 Next Steps

### After Successful Setup

1. **Login to GUI**
   - Use credentials from `~/ids_idps_credentials.txt`
   - Explore the dashboard

2. **Change Passwords**
   - Settings → Account → Change Password

3. **Enable 2FA**
   - Settings → Security → Enable 2FA
   - Scan QR with Google Authenticator

4. **Explore Features**
   - Dashboard: View metrics
   - Alerts: Manage detections
   - Settings: Adjust threshold (admin)
   - Users: Create accounts (admin)

5. **Integrate ML Model**
   - See `GUI_SETUP_GUIDE.md` for ML integration
   - Configure packet capture
   - Set up real-time detection

---

## 📄 License

This project is part of an academic Information Security project demonstrating Random Forest-based intrusion detection.

---

## 🙏 Acknowledgments

- **FastAPI**: Modern web framework
- **PyQt5**: Desktop GUI framework
- **PostgreSQL**: Robust database
- **Scikit-learn**: Machine learning library

---

## 📊 Project Status

✅ **Backend API**: Complete and tested  
✅ **Database**: Schema and migrations ready  
✅ **GUI Application**: Fully functional  
✅ **Authentication**: JWT + 2FA implemented  
✅ **Setup Scripts**: Automated and verified  
✅ **Documentation**: Comprehensive guides  
✅ **Troubleshooting**: Auto-fix scripts included  

**Status**: Production Ready ✨

---

<div align="center">

### 🚀 Ready to Get Started?

Run the setup script and have your GUI running in minutes!

```bash
cd ~/Random-Forest-Based-IDPS
./setup_gui_complete.sh
```

**Questions?** Check the [detailed guide](GUI_SETUP_GUIDE.md) or run `./verify_setup.sh`

---

**Built with ❤️ for Information Security**

</div>

