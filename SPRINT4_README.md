# IDS/IDPS Sprint4 Admin Dashboard - Live Traffic Ready

## 🚀 Quick Start for Live Traffic Testing

This branch contains the **working version** merged from main with all fixes applied for live traffic testing.

### ⚡ One-Command Setup

```bash
# Clone and setup everything automatically
git clone https://github.com/annKimani-ICS/Random-Forest-Based-IDPS.git
cd Random-Forest-Based-IDPS
git checkout feat/sprint4-admin-dashboard
chmod +x automated_fix_sprint4.sh
./automated_fix_sprint4.sh
```

### 🎯 What This Fixes

✅ **API Port Issue** - GUI now connects to port 8000 (not 3000)  
✅ **Database Authentication** - Uses postgres user (no auth issues)  
✅ **Environment Setup** - Automated virtual environments  
✅ **Database Initialization** - Tables created and seeded  
✅ **Dependencies** - All packages installed correctly  
✅ **Systemd Service** - Backend auto-starts on boot  
✅ **Firewall** - Port 8000 opened for API access  

### 🚀 Starting the System

#### Method 1: Manual Start
```bash
# Terminal 1 - Start Backend
cd backend
./start_backend.sh

# Terminal 2 - Start GUI
cd gui
./start_gui.sh
```

#### Method 2: Systemd Service
```bash
# Start backend service
sudo systemctl start ids-idps-backend

# Start GUI manually
cd gui
./start_gui.sh
```

### 📊 Expected Results

- **Backend**: Runs on `http://localhost:8000`
- **API Docs**: Available at `http://localhost:8000/docs`
- **GUI**: Desktop application with correct metrics
- **Database**: PostgreSQL with working data
- **Metrics**: Random Forest performance metrics displayed

### 🔧 System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kali Linux    │    │   Ubuntu VM     │    │   Ubuntu VM     │
│   (Attacker)    │───▶│   (Backend)     │◀───│   (GUI Client)  │
│                 │    │   Port 8000     │    │   Desktop App   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   PostgreSQL    │
                       │   Database      │
                       └─────────────────┘
```

### 🎯 Live Traffic Testing Setup

1. **Ubuntu VM (Server)**:
   - Backend API running on port 8000
   - PostgreSQL database
   - GUI application

2. **Kali Linux VM (Client)**:
   - Normal user traffic
   - Malicious traffic (DDoS attacks)
   - Network tools for testing

### 🔐 Default Credentials

After running the automated fix script, check:
```bash
cat ~/ids_idps_credentials.txt
```

### 🛠️ Troubleshooting

#### Backend Not Starting
```bash
# Check service status
sudo systemctl status ids-idps-backend

# View logs
sudo journalctl -u ids-idps-backend -f

# Restart service
sudo systemctl restart ids-idps-backend
```

#### GUI Not Connecting
```bash
# Check if backend is running
curl http://localhost:8000/health

# Verify API client configuration
grep "localhost:8000" gui/api_client.py
```

#### Database Issues
```bash
# Test database connection
cd backend
source .venv/bin/activate
python -c "from app.database import SessionLocal; db = SessionLocal(); db.close()"
```

### 📈 Performance Metrics

The system displays:
- **Accuracy**: 90.48%
- **Precision**: 90.62%
- **Recall**: 90.48%
- **F1-Score**: 90.51%
- **AUC**: 95.00%

### 🔄 Updates

To get the latest fixes:
```bash
git pull origin feat/sprint4-admin-dashboard
./automated_fix_sprint4.sh
```

### 🎉 Ready for Live Traffic!

The system is now configured and ready for live traffic testing with:
- ✅ Stable backend API
- ✅ Working GUI dashboard
- ✅ Correct performance metrics
- ✅ Database with test data
- ✅ Automated setup scripts
- ✅ Systemd service for reliability

**Start testing with live traffic!** 🚀
