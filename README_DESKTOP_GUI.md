# IDS/IDPS Desktop GUI Application - Ubuntu Deployment

## System Architecture

This is a **desktop application** (not a web interface) for Ubuntu Linux that provides a GUI for managing the Random Forest-Based Intrusion Detection & Prevention System.

### Architecture Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Ubuntu Desktop VM                        │
│                                                             │
│  ┌────────────────────┐         ┌────────────────────────┐ │
│  │   PyQt5 Desktop    │   HTTP  │   FastAPI Backend      │ │
│  │   GUI Application  │◄───────►│   (systemd service)    │ │
│  │   (User launches)  │         │   Port 8000            │ │
│  └────────────────────┘         └───────────┬────────────┘ │
│                                              │              │
│                                              ▼              │
│                                  ┌──────────────────────┐  │
│                                  │  PostgreSQL Database │  │
│                                  │  (alerts, users,     │  │
│                                  │   models, thresholds)│  │
│                                  └──────────────────────┘  │
│                                                             │
│  Network Traffic → IDS/IDPS Engine (RF Model) → Alerts     │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack (Per Project Requirements)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Backend Language** | Python 3.10+ | Main programming language |
| **ML Framework** | Scikit-learn | Random Forest model training/inference |
| **Data Processing** | Pandas, Numpy | Data cleaning, feature engineering |
| **Backend API** | FastAPI | REST API for GUI ↔ Backend communication |
| **Database** | PostgreSQL | Store alerts, users, models, audit logs |
| **Desktop GUI** | PyQt5 | Native desktop application framework |
| **Visualization** | Matplotlib, PyQtGraph | Charts and graphs in GUI |
| **2FA** | PyOTP | TOTP-based two-factor authentication |
| **Password Security** | bcrypt (via passlib) | Secure password hashing |
| **Deployment** | Ubuntu Server/Desktop | VM environment |
| **Process Management** | systemd | Backend API as service |

## Installation Steps

### Prerequisites

- **Ubuntu 22.04 LTS** (Desktop or Server with GUI)
- **4GB RAM** minimum (8GB recommended)
- **20GB disk space**
- **Non-root user** with sudo privileges
- **Display server** (X11 or Wayland) for GUI

### Option 1: Automated Installation

```bash
# Clone or copy project files to Ubuntu VM
cd ~/Random-Forest-Based-IDPS

# Make setup script executable
chmod +x setup_ubuntu_gui.sh

# Run installation script
./setup_ubuntu_gui.sh
```

**What the script does:**
1. Installs Python, PostgreSQL, PyQt5, and dependencies
2. Configures time synchronization (critical for 2FA)
3. Creates database and user
4. Sets up backend API as systemd service
5. Creates GUI application launcher
6. Seeds database with demo data
7. Configures firewall

### Option 2: Manual Installation

#### Step 1: Install System Dependencies

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
    python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib \
    python3-pyqt5 python3-pyqt5.qtsvg \
    libpq-dev build-essential \
    qt5-default
```

#### Step 2: Configure PostgreSQL

```bash
sudo -u postgres psql

# In PostgreSQL shell:
CREATE USER ids_user WITH PASSWORD 'your_secure_password';
CREATE DATABASE ids_idps_db OWNER ids_user;
GRANT ALL PRIVILEGES ON DATABASE ids_idps_db TO ids_user;
\q
```

#### Step 3: Setup Backend API

```bash
cd ~/Random-Forest-Based-IDPS/backend

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cat > .env <<EOF
DATABASE_URL=postgresql+psycopg2://ids_user:your_secure_password@localhost:5432/ids_idps_db
JWT_SECRET=$(openssl rand -hex 32)
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:8000
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
EOF

# Initialize database
python3 seed_data.py
```

#### Step 4: Create Backend Systemd Service

```bash
sudo nano /etc/systemd/system/ids-idps-backend.service
```

Paste:
```ini
[Unit]
Description=IDS/IDPS Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/backend
Environment="PATH=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/backend/.venv/bin"
EnvironmentFile=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/backend/.env
ExecStart=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/backend/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable ids-idps-backend
sudo systemctl start ids-idps-backend
sudo systemctl status ids-idps-backend
```

#### Step 5: Setup Desktop GUI

```bash
cd ~/Random-Forest-Based-IDPS/gui

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Make run script executable
chmod +x run_gui.sh
```

#### Step 6: Create Desktop Launcher

```bash
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/ids-idps.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=IDS/IDPS Dashboard
Comment=Intrusion Detection & Prevention System Admin GUI
Exec=/home/YOUR_USERNAME/Random-Forest-Based-IDPS/gui/run_gui.sh
Icon=security
Terminal=false
Categories=System;Security;Network;
EOF

chmod +x ~/.local/share/applications/ids-idps.desktop
update-desktop-database ~/.local/share/applications
```

## Running the Application

### Start Backend (if not running)

```bash
sudo systemctl start ids-idps-backend

# Check status
sudo systemctl status ids-idps-backend

# View logs
sudo journalctl -u ids-idps-backend -f
```

### Launch Desktop GUI

**Method 1: Application Menu**
1. Open Applications menu (Super key / Windows key)
2. Search for "IDS/IDPS Dashboard"
3. Click to launch

**Method 2: Terminal**
```bash
cd ~/Random-Forest-Based-IDPS/gui
./run_gui.sh
```

**Method 3: Manual**
```bash
cd ~/Random-Forest-Based-IDPS/gui
source .venv/bin/activate
python3 main.py
```

## Default Login Credentials

| Role | Email | Password |
|------|-------|----------|
| **Admin** | admin@ids-idps.com | Admin123! |
| **Analyst** | analyst@ids-idps.com | Analyst123! |

⚠️ **Change these immediately in production!**

## GUI Features

### 1. Login Window
- Email/password authentication
- 2FA challenge dialog (if enabled)
- Clean, professional interface

### 2. Dashboard Tab
- **KPI Cards**: Alerts (24h), Active Blocks, Precision, Threshold
- **Model Metrics**: Recall, F1 Score, AUC, Training date
- **Recent Alerts Table**: Top 10 most recent alerts
- **Auto-refresh**: Updates every 30 seconds

### 3. Alerts Tab
- **Full Alerts Table**: Paginated view of all alerts
- **Filters**: By status (NEW/ACK/BLOCKED/CLOSED), malicious/benign
- **Actions**: 
  - ACK button for new alerts
  - Block button for malicious IPs
- **Color-coded**: Red for malicious, green for benign

### 4. Settings Tab (Admin Only)
- **Threshold Slider**: Adjust detection threshold (0.00 - 1.00)
  - Visual gradient (green → yellow → red)
  - Real-time preview
  - Save and apply to all alerts
- **Active Block Rules Table**:
  - View all blocked IPs
  - Deactivate blocks
  - See reason and timestamp

### 5. Users Tab (Admin Only)
- **Users List**: Email, role, 2FA status, last login
- **Create User**: Add new admin or analyst accounts
- **User Management**: Activate/deactivate users

## Integrating with ML Model

The GUI connects to the backend API which uses your trained Random Forest model:

### Backend Model Integration

```python
# backend/app/ml_model.py (example)
import joblib
import pandas as pd
from pathlib import Path

class IDSModel:
    def __init__(self):
        model_path = Path("../models/best_rf_iteration4_voting_ensemble.pkl")
        self.model = joblib.load(model_path)
        
        scaler_path = Path("../models/scaler_iteration4.pkl")
        self.scaler = joblib.load(scaler_path)
        
        features_path = Path("../models/feature_selection_iteration4.json")
        with open(features_path) as f:
            self.selected_features = json.load(f)["selected_features"]
    
    def predict(self, flow_features: dict) -> dict:
        """
        Predict if traffic is malicious
        Returns: {"score": float, "label": str, "is_malicious": bool}
        """
        df = pd.DataFrame([flow_features])
        df = df[self.selected_features]
        
        # Scale features
        X_scaled = self.scaler.transform(df)
        
        # Get probability
        proba = self.model.predict_proba(X_scaled)[0]
        score = proba[1]  # Probability of malicious class
        
        # Get threshold from database
        threshold = get_current_threshold()
        
        return {
            "score": float(score),
            "label": "Malicious" if score >= threshold else "Benign",
            "is_malicious": bool(score >= threshold)
        }
```

### Real-time Traffic Processing

```python
# Pseudo-code for traffic monitoring
from scapy.all import sniff
from app.ml_model import IDSModel

model = IDSModel()

def process_packet(packet):
    # Extract features from packet
    features = extract_features(packet)
    
    # Run through Random Forest model
    prediction = model.predict(features)
    
    # Create alert if malicious
    if prediction["is_malicious"]:
        alert = create_alert(
            src_ip=packet.src,
            dst_ip=packet.dst,
            attack_type=prediction["label"],
            score=prediction["score"]
        )
        
        # Save to database (will appear in GUI)
        db.add(alert)
        db.commit()

# Start monitoring
sniff(prn=process_packet, store=False)
```

## Troubleshooting

### GUI won't start

```bash
# Check if backend is running
curl http://localhost:8000/health

# If not, start it
sudo systemctl start ids-idps-backend

# Check GUI dependencies
cd ~/Random-Forest-Based-IDPS/gui
source .venv/bin/activate
python3 -c "import PyQt5; print('PyQt5 OK')"
```

### Display issues

```bash
# Check DISPLAY variable
echo $DISPLAY

# If empty, set it
export DISPLAY=:0

# For SSH with X11 forwarding
ssh -X user@vm-ip
```

### 2FA codes not working

```bash
# Check time synchronization (CRITICAL!)
timedatectl status

# If not synced
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd

# Verify time matches your phone
date
```

### Database connection errors

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection
psql -U ids_user -d ids_idps_db -h localhost

# Check backend logs
sudo journalctl -u ids-idps-backend -n 50
```

## Performance Optimization

### Backend API

- Runs as systemd service (auto-restart on failure)
- Connection pooling via SQLAlchemy
- Async endpoints with FastAPI
- JWT token caching

### GUI Application

- Lazy loading of alerts (pagination)
- Auto-refresh with configurable interval
- Efficient table updates (only changed rows)
- Background threads for network calls

## Security Best Practices

- [ ] Change default passwords
- [ ] Enable 2FA for all admin accounts
- [ ] Use strong JWT_SECRET (auto-generated)
- [ ] Keep PostgreSQL port (5432) firewalled
- [ ] Regular database backups
- [ ] Monitor audit logs
- [ ] Update system packages regularly
- [ ] Use SSL/TLS for production API (if exposing remotely)

## Demo Script for Viva/Presentation

### 1. Launch Application (1 min)
```bash
# Show backend is running
sudo systemctl status ids-idps-backend

# Launch GUI from terminal or app menu
./gui/run_gui.sh
```

### 2. Login with 2FA (2 min)
- Enter admin@ids-idps.com / Admin123!
- Show 2FA dialog appears (if enabled)
- Enter Google Authenticator code
- Successfully login to dashboard

### 3. Dashboard Overview (3 min)
- Point to KPI cards (real-time metrics)
- Show Random Forest model version and metrics
- Explain precision, recall, F1, AUC scores
- Show recent alerts table

### 4. Alerts Management (3 min)
- Switch to Alerts tab
- Apply filter: "Malicious Only"
- Click ACK on a new alert
- Show status change
- Click Block on a high-score alert
- Enter reason in dialog
- Show Active Blocks increment

### 5. Threshold Adjustment (2 min)
- Switch to Settings tab (Admin only)
- Show current threshold (e.g., 0.50)
- Drag slider to 0.70
- Explain impact (fewer false positives)
- Click "Save Threshold"
- Return to dashboard
- Show how KPIs updated

### 6. RBAC Demo (2 min)
- Logout admin
- Login as analyst@ids-idps.com
- Show analyst can view/ACK/block
- Show Settings and Users tabs are hidden
- Explain role-based access control

**Total: ~15 minutes**

## File Structure

```
Random-Forest-Based-IDPS/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI application
│   │   ├── models.py            # SQLAlchemy models
│   │   ├── auth.py              # JWT + 2FA logic
│   │   ├── totp.py              # TOTP implementation
│   │   ├── routers/
│   │   │   ├── auth.py          # Auth endpoints
│   │   │   ├── dashboard.py    # Dashboard APIs
│   │   │   └── users.py         # User management
│   │   └── config.py            # Configuration
│   ├── .env                     # Environment variables
│   ├── requirements.txt         # Python dependencies
│   └── seed_data.py             # Database seeding
│
├── gui/
│   ├── main.py                  # GUI entry point
│   ├── login_window.py          # Login UI
│   ├── dashboard_window.py      # Main dashboard UI
│   ├── api_client.py            # API communication
│   ├── requirements.txt         # PyQt5 dependencies
│   └── run_gui.sh               # Launch script
│
├── models/
│   ├── best_rf_iteration4_voting_ensemble.pkl  # Trained model
│   ├── scaler_iteration4.pkl                   # Feature scaler
│   └── feature_selection_iteration4.json       # Selected features
│
└── setup_ubuntu_gui.sh          # Installation script
```

## Support

For issues or questions:
1. Check logs: `sudo journalctl -u ids-idps-backend -f`
2. Verify backend health: `curl http://localhost:8000/health`
3. Test API: Open http://localhost:8000/docs in browser
4. Check database: `sudo -u postgres psql ids_idps_db`

---

**Important**: This is a desktop GUI application for Ubuntu, not a web interface. It requires a display server (X11/Wayland) to run.

