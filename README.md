# Random Forest-Based Intrusion Detection & Prevention System (IDPS)

## 📖 Overview
This project implements a **machine learning-based Intrusion Detection and Prevention System (IDPS)** for detecting and mitigating **Denial-of-Service (DoS) attacks** in corporate networks.  
It uses the **Random Forest algorithm** trained on the **CIC-DDoS2019 dataset**, optimized for accuracy and practical deployment in Kenyan enterprise environments.  
A **Graphical User Interface (GUI)** provides real-time traffic monitoring, alert management, and report generation.

## 🎯 Objectives
- Detect and classify malicious DoS traffic with high accuracy.
- Isolate and block suspicious traffic in real-time.
- Provide a usable **GUI dashboard** for administrators.
- Support explainability with feature importance and SHAP analysis.
- Deliver a modular, scalable solution aligned with enterprise security needs.

## 🏗️ System Features

### Core Functionality
- **Data Preprocessing:** Cleaning, scaling, and feature engineering pipeline
- **Model Training:** Random Forest classifier with evaluation metrics (Accuracy, Precision, Recall, F1, AUC)
- **Testing & Evaluation:** CIC-DDoS2019 dataset split into training/test sets; evaluated for robustness
- **Real-time Detection:** Live traffic monitoring and DoS attack detection

### User Interface
- **Desktop GUI:** PyQt5-based dashboard for system management
- **Multi-Factor Authentication:** TOTP-based 2FA with Google Authenticator
- **User Management:** Role-based access control (Admin/Analyst)
- **Alert Management:** Real-time alert monitoring and response

### Security & Operations
- **Automated Setup:** One-command installation and configuration
- **Virtual Environment:** Isolated Python environment for stability
- **Database Integration:** PostgreSQL with Alembic migrations
- **Audit Logging:** Comprehensive event logging for security
- **API Documentation:** Auto-generated Swagger/OpenAPI docs

## 📂 Repository Structure
```
Random-Forest-Based-IDPS/
│
├── 🔧 Automation Scripts
│   ├── setup.sh              # Complete project setup
│   ├── run_backend.sh         # Start backend with venv
│   ├── run_gui.sh            # Start GUI with venv
│   └── run_full_system.sh    # Start both backend & GUI
│
├── 🖥️ GUI Application
│   ├── gui/
│   │   ├── main.py           # GUI entry point
│   │   ├── login_window.py   # Login & MFA dialogs
│   │   ├── dashboard_window.py # Main dashboard
│   │   └── api_client.py     # Backend communication
│
├── ⚙️ Backend API
│   ├── backend/
│   │   ├── app/
│   │   │   ├── main.py       # FastAPI application
│   │   │   ├── auth.py       # Authentication logic
│   │   │   ├── totp.py       # MFA implementation
│   │   │   ├── models.py     # Database models
│   │   │   └── routers/      # API endpoints
│
├── 📚 Documentation
│   ├── README.md             # Main project docs
│   ├── README_MFA.md         # MFA overview
│   ├── QUICK_START_MFA.md    # Quick MFA setup
│   ├── MFA_SETUP_GUIDE.md    # Complete MFA guide
│   └── MFA_VISUAL_GUIDE.md   # Visual MFA walkthrough
│
├── 📊 Analysis & Models
│   ├── notebooks/            # Jupyter notebooks
│   ├── config/              # Model configurations
│   ├── models/              # Trained ML models
│   └── reports/             # Evaluation reports
│
└── 🔧 Configuration
    ├── requirements.txt      # Python dependencies
    ├── .gitignore          # Ignored files
    └── venv/               # Virtual environment (created by setup)
```


---

## ⚙️ Tech Stack
- **Python** – Core development
- **scikit-learn** – Random Forest training & evaluation
- **pandas, numpy** – Data preprocessing
- **matplotlib, seaborn** – Visualization
- **PyQt5** – Graphical User Interface
- **SHAP** – Explainability
- **VirtualBox + Kali Linux** – Traffic simulation

---

## 🚀 Getting Started

### Quick Setup (Recommended)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/annKimani-ICS/Random-Forest-Based-IDPS.git
   cd Random-Forest-Based-IDPS
   ```

2. **Run automated setup:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Start the system:**
   ```bash
   # Start backend only (defaults to port 3000; override with PORT=8000)
   ./run_backend.sh
   # or specify a custom port
   PORT=8000 ./run_backend.sh
   
   # Or start GUI only (in new terminal)
   ./run_gui.sh
   
   # Or start both together
   ./run_full_system.sh
   ```

### Manual Setup (Alternative)

If you prefer manual setup or encounter issues with the automated scripts:

#### Prerequisites
- Python 3.8+ (3.10+ recommended)
- Git
- Virtual environment support

#### Step-by-Step Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/annKimani-ICS/Random-Forest-Based-IDPS.git
   cd Random-Forest-Based-IDPS
   ```

2. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Linux/Mac
   # or
   venv\Scripts\activate     # Windows
   ```

3. **Install backend dependencies:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

4. **Install GUI dependencies:**
   ```bash
   cd ../gui
   pip install -r requirements.txt
   ```

5. **Initialize database (if needed):**
   ```bash
   cd ../backend
   alembic upgrade head  # Run migrations
   ```

6. **Run the system:**
   ```bash
   # Terminal 1 - Backend (recommended: local venv inside backend)
   cd backend
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   uvicorn app.main:app --reload --host 0.0.0.0 --port 3000
   
   # Terminal 2 - GUI
   cd gui
   source ../venv/bin/activate
   python main.py
   ```

### 🔐 Multi-Factor Authentication Setup

This system includes **TOTP-based Multi-Factor Authentication** using Google Authenticator:

1. **After logging in**, navigate to the **🔐 Security** tab
2. **Click "Enable Two-Factor Authentication"**
3. **Scan QR code** with Google Authenticator app
4. **Enter verification code** to activate
5. **Save recovery codes** for backup access

📚 **Detailed MFA guides:**
- `QUICK_START_MFA.md` - Quick 5-minute setup
- `MFA_SETUP_GUIDE.md` - Complete admin guide
- `README_MFA.md` - MFA documentation index

#📊 Results (First Iteration)
Accuracy: >99%
Macro-averaged AUC: ~1.0
Key Features: Packet size, flow duration, source port, etc.
Robust detection of DoS attack flows in simulated corporate network settings.

#📌 Roadmap
 Sprint 1 – Data Cleaning & Preprocessing
 Sprint 2 – Model Training & Evaluation
 Sprint 3 – GUI Development (PyQt5 Dashboard)
 Sprint 4 – Integration with VM Simulation (Ubuntu + Kali)
 Sprint 5 – Final Evaluation & Defense

#👩‍💻 Author
Kimani Ann Wangari
BSc Informatics and Computer Science, Strathmore University, Nairobi, Kenya
Supervisor: Mr. James Gikera

#📜 License
This project is for academic and research purposes only. Unauthorized use in production environments is not advised without further security hardening.

[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/F63P1L7A)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-2e0aaae1b6195c2367325f4f02e2d04e9abb55f0b24a779b69b11b9e10269abc.svg)](https://classroom.github.com/online_ide?assignment_repo_id=20100707&assignment_repo_type=AssignmentRepo)

Git cheatsheet: https://philomatics.com/git-cheatsheet-release
