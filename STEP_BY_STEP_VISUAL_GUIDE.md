# 🎯 IDS/IDPS GUI - Step-by-Step Visual Guide

## 📖 Complete Setup Journey

This guide walks you through the entire process from restoring your VM snapshot to launching the GUI.

---

## 🔄 Step 1: Restore Your Ubuntu VM Snapshot

```
┌─────────────────────────────────────┐
│     Your VM Snapshot (Clean)        │
│                                     │
│   ✓ Fresh Ubuntu installation      │
│   ✓ No PostgreSQL configured       │
│   ✓ No services running            │
│   ✓ No virtual environments        │
└─────────────────────────────────────┘
                  │
                  ▼
         [Restore Snapshot]
                  │
                  ▼
┌─────────────────────────────────────┐
│   Clean Ubuntu VM (Restored)        │
└─────────────────────────────────────┘
```

**Action**: Restore your VM to the snapshot you took when you first set it up.

---

## 📁 Step 2: Verify Project Files Are Present

```bash
cd ~
ls -la Random-Forest-Based-IDPS/
```

**Expected output**:
```
drwxr-xr-x  backend/
drwxr-xr-x  gui/
drwxr-xr-x  models/
drwxr-xr-x  data/
drwxr-xr-x  notebooks/
-rwxr-xr-x  setup_gui_complete.sh      ← NEW!
-rwxr-xr-x  verify_setup.sh            ← NEW!
-rwxr-xr-x  fix_common_issues.sh       ← NEW!
-rw-r--r--  GUI_SETUP_GUIDE.md         ← NEW!
-rw-r--r--  QUICK_START.md             ← NEW!
... other files ...
```

**If files are missing**: Transfer them from your Windows machine to Ubuntu VM.

---

## 🔧 Step 3: Make Scripts Executable

```bash
cd ~/Random-Forest-Based-IDPS
chmod +x setup_gui_complete.sh verify_setup.sh fix_common_issues.sh gui/run_gui.sh
```

**Visual**:
```
Before:
-rw-r--r-- setup_gui_complete.sh    ← Not executable

After:
-rwxr-xr-x setup_gui_complete.sh    ← Executable ✓
```

---

## 🚀 Step 4: Run the Automated Setup

```bash
./setup_gui_complete.sh
```

### What You'll See:

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        IDS/IDPS System - Complete Ubuntu Setup           ║
║     Backend API + Desktop GUI Application Setup          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

📁 Project Directory: /home/user/Random-Forest-Based-IDPS
👤 Current User: youruser

Use default database password? [Y/n]: 
```

**Recommendation**: Press **Enter** to use default password.

### Progress Indicator:

```
════════════════════════════════════════════════════
[1/11] Updating system packages...
════════════════════════════════════════════════════
✓ System packages updated

════════════════════════════════════════════════════
[2/11] Installing system dependencies...
════════════════════════════════════════════════════
✓ System dependencies installed

[... continues through 11 steps ...]

════════════════════════════════════════════════════
[11/11] Creating desktop application launcher...
════════════════════════════════════════════════════
✓ Desktop launcher created
```

### At the End:

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              🎉 INSTALLATION COMPLETE! 🎉                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SYSTEM STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Backend API:       http://localhost:8000
API Docs:          http://localhost:8000/docs
Health Check:      http://localhost:8000/health

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 LOGIN CREDENTIALS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Credentials have been saved to:
/home/user/ids_idps_credentials.txt

Would you like to launch the GUI now? [Y/n]: 
```

**Action**: Type **Y** and press Enter to launch GUI immediately.

---

## 💾 Step 5: Save Your Credentials

```bash
cat ~/ids_idps_credentials.txt
```

**Output**:
```
IDS/IDPS Login Credentials
Generated on: Tue Oct 7 2025 14:23:45
================================

🌱 Seeding database...
Creating users...
  ✓ Created admin: admin@ids-idps.com
  ✓ Created analyst: analyst@ids-idps.com
Creating model record...
  ✓ Created model: rf-iter4-2025-09-30
Creating threshold...
  ✓ Created threshold: 0.50
Generating sample alerts...
  ✓ Created 200 alerts
Creating block rules...
  ✓ Created 3 block rules

✅ Database seeded successfully!

📝 Login Credentials (SAVE THESE SECURELY):
  Admin:
    Email: admin@ids-idps.com
    Password: [Generated during setup]

  Analyst:
    Email: analyst@ids-idps.com
    Password: [Generated during setup]

⚠️  IMPORTANT: Save these passwords securely!
   They will not be displayed again.
```

**Action**: Copy these credentials to a secure location!

---

## ✅ Step 6: Verify Setup (Optional but Recommended)

```bash
./verify_setup.sh
```

**What You'll See**:

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          IDS/IDPS Setup Verification Script              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. System Dependencies
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Python 3... ✓ PASS (3.10.12)
  PostgreSQL... ✓ PASS (14.9)
  PyQt5 system package... ✓ PASS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. Project Structure
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Backend directory... ✓ PASS
  GUI directory... ✓ PASS
  Models directory... ✓ PASS

[... continues through all checks ...]

╔═══════════════════════════════════════════════════════════╗
║                    VERIFICATION SUMMARY                   ║
╚═══════════════════════════════════════════════════════════╝

  ✓ Passed:   25
  ✗ Failed:   0
  ⚠ Warnings: 2
  ─────────────────
  Total:      27

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          ✅ SETUP VERIFICATION SUCCESSFUL! ✅             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

🚀 You're ready to launch the GUI!

Launch command:
  cd /home/user/Random-Forest-Based-IDPS/gui && ./run_gui.sh
```

---

## 🖥️ Step 7: Launch the GUI

### Method 1: Using Run Script (Recommended)

```bash
cd ~/Random-Forest-Based-IDPS/gui
./run_gui.sh
```

**Visual**:
```
🚀 Launching IDS/IDPS Desktop GUI...

┌─────────────────────────────────────┐
│                                     │
│         GUI Window Opens            │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  IDS/IDPS Login             │   │
│  │                             │   │
│  │  Email:    [____________]   │   │
│  │  Password: [____________]   │   │
│  │                             │   │
│  │         [  Login  ]         │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### Method 2: Desktop Application Menu

```
1. Press Super key (Windows key)
2. Type: "IDS/IDPS Dashboard"
3. Click the application icon
```

**Visual**:
```
┌────────────────────────────────┐
│  🔍 Search Applications        │
│  ┌──────────────────────────┐  │
│  │ IDS/IDPS Dashboard       │  │
│  └──────────────────────────┘  │
│                                │
│  Recent Results:               │
│  🛡️  IDS/IDPS Dashboard        │
│      Security application      │
│                                │
└────────────────────────────────┘
```

### Method 3: Manual Launch

```bash
cd ~/Random-Forest-Based-IDPS/gui
source .venv/bin/activate
python3 main.py
```

---

## 🔐 Step 8: Login to the Application

### Login Screen:

```
╔═══════════════════════════════════════╗
║                                       ║
║     IDS/IDPS Admin Dashboard         ║
║                                       ║
╠═══════════════════════════════════════╣
║                                       ║
║  Email Address:                       ║
║  ┌─────────────────────────────────┐  ║
║  │ admin@ids-idps.com              │  ║
║  └─────────────────────────────────┘  ║
║                                       ║
║  Password:                            ║
║  ┌─────────────────────────────────┐  ║
║  │ ••••••••••••                    │  ║
║  └─────────────────────────────────┘  ║
║                                       ║
║        ┌───────────────┐              ║
║        │     Login     │              ║
║        └───────────────┘              ║
║                                       ║
╚═══════════════════════════════════════╝
```

**Enter**:
- Email: `admin@ids-idps.com`
- Password: `[from ~/ids_idps_credentials.txt]`

### If 2FA is Enabled:

```
╔═══════════════════════════════════════╗
║                                       ║
║     Two-Factor Authentication        ║
║                                       ║
╠═══════════════════════════════════════╣
║                                       ║
║  Enter the 6-digit code from your    ║
║  authenticator app:                  ║
║                                       ║
║  ┌─────────────────────────────────┐  ║
║  │       [_] [_] [_] [_] [_] [_]   │  ║
║  └─────────────────────────────────┘  ║
║                                       ║
║        ┌───────────────┐              ║
║        │    Verify     │              ║
║        └───────────────┘              ║
║                                       ║
╚═══════════════════════════════════════╝
```

---

## 📊 Step 9: Explore the Dashboard

### After Successful Login:

```
╔═══════════════════════════════════════════════════════════════════╗
║  IDS/IDPS Dashboard                      admin@ids-idps.com  [≡] ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  [Dashboard] [Alerts] [Settings] [Users]                         ║
║                                                                   ║
║  ┌────────────────────────────────────────────────────────────┐  ║
║  │  📊 Key Performance Indicators                            │  ║
║  ├────────────────────────────────────────────────────────────┤  ║
║  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │  ║
║  │  │ 🚨 24h   │  │ 🛑 Active│  │ 📈 Prec. │  │ 🎯 Thresh│  │  ║
║  │  │ Alerts   │  │ Blocks   │  │          │  │          │  │  ║
║  │  │   156    │  │    3     │  │  95.4%   │  │   0.50   │  │  ║
║  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │  ║
║  └────────────────────────────────────────────────────────────┘  ║
║                                                                   ║
║  ┌────────────────────────────────────────────────────────────┐  ║
║  │  🎯 Model Metrics                                         │  ║
║  ├────────────────────────────────────────────────────────────┤  ║
║  │  Model: rf-iter4-2025-09-30                               │  ║
║  │  Recall: 93.8%  │  F1: 94.6%  │  AUC: 98.1%              │  ║
║  │  Trained: 2025-10-06                                      │  ║
║  └────────────────────────────────────────────────────────────┘  ║
║                                                                   ║
║  ┌────────────────────────────────────────────────────────────┐  ║
║  │  🔔 Recent Alerts                                         │  ║
║  ├────────────────────────────────────────────────────────────┤  ║
║  │  Time       │ Source IP    │ Attack Type   │ Score │ Stat │  ║
║  │  14:23:45   │ 192.168.1.100│ DoS_SYN       │ 0.98  │ NEW  │  ║
║  │  14:22:31   │ 10.0.0.50    │ PortScan      │ 0.87  │ ACK  │  ║
║  │  14:21:18   │ 172.16.0.200 │ DDoS_LOIC     │ 0.95  │ BLCK │  ║
║  └────────────────────────────────────────────────────────────┘  ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 🎉 Success! What Now?

### ✅ You Can Now:

1. **View Dashboard** - See real-time metrics and alerts
2. **Manage Alerts** - ACK, block, or close alerts
3. **Adjust Threshold** - Fine-tune detection sensitivity (Admin)
4. **Manage Users** - Create/edit user accounts (Admin)
5. **Enable 2FA** - Enhance security for your account
6. **Block IPs** - Add malicious IPs to block list

### 🔄 Backend Runs Automatically

```
┌─────────────────────────────────────┐
│   On Every System Boot:             │
│                                     │
│   1. PostgreSQL starts ✓            │
│   2. Backend API starts ✓           │
│   3. Port 8000 opens ✓              │
│   4. Ready for GUI connection ✓     │
│                                     │
│   You only need to launch GUI!      │
└─────────────────────────────────────┘
```

**No need to manually start backend!** It auto-starts with the system.

---

## 🆘 Troubleshooting Visual Guide

### Problem: GUI Won't Start

```
┌─────────────────────────────────────┐
│  ⚠️ Error: Cannot connect to        │
│     display                         │
└─────────────────────────────────────┘
                  │
                  ▼
         [Run Command]
     export DISPLAY=:0
                  │
                  ▼
       [Try Launching Again]
    cd gui && ./run_gui.sh
                  │
                  ▼
         ✅ GUI Opens!
```

### Problem: Backend Not Responding

```
┌─────────────────────────────────────┐
│  ⚠️ Warning: Backend API not        │
│     responding                      │
└─────────────────────────────────────┘
                  │
                  ▼
         [Check Status]
    sudo systemctl status
      ids-idps-backend
                  │
       ┌──────────┴──────────┐
       │                     │
    [Active]             [Inactive]
       │                     │
    ✅ Good              [Restart]
                    sudo systemctl
                      restart
                  ids-idps-backend
                          │
                          ▼
                     ✅ Fixed!
```

### Problem: Forgot Password

```
┌─────────────────────────────────────┐
│  ❓ Can't remember password         │
└─────────────────────────────────────┘
                  │
                  ▼
         [Check File]
  cat ~/ids_idps_credentials.txt
                  │
       ┌──────────┴──────────┐
       │                     │
   [File Exists]      [File Missing]
       │                     │
   [Use Password]       [Re-seed DB]
       │              cd backend &&
       │              source .venv/bin/activate &&
       │              python3 seed_data.py
       │                     │
       └──────────┬──────────┘
                  ▼
            ✅ Login!
```

---

## 📚 Quick Reference Card

```
╔════════════════════════════════════════════════════════════╗
║               IDS/IDPS GUI - QUICK REFERENCE              ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  SETUP:                                                    ║
║    ./setup_gui_complete.sh     Complete setup             ║
║    ./verify_setup.sh           Verify everything          ║
║    ./fix_common_issues.sh      Auto-fix problems          ║
║                                                            ║
║  LAUNCH GUI:                                               ║
║    cd gui && ./run_gui.sh      Start application          ║
║                                                            ║
║  BACKEND:                                                  ║
║    sudo systemctl status ids-idps-backend                 ║
║    sudo systemctl restart ids-idps-backend                ║
║    sudo journalctl -u ids-idps-backend -f                 ║
║                                                            ║
║  CREDENTIALS:                                              ║
║    cat ~/ids_idps_credentials.txt                         ║
║                                                            ║
║  API:                                                      ║
║    curl http://localhost:8000/health                      ║
║    http://localhost:8000/docs                             ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

---

## 🎓 You're All Set!

Follow these steps in order and you'll have a fully functional IDS/IDPS Desktop GUI with:

✅ Automated setup  
✅ Backend running as service  
✅ Database populated with demo data  
✅ GUI ready to launch  
✅ Credentials saved securely  
✅ Comprehensive verification  
✅ Auto-fix scripts available  

**Enjoy your IDS/IDPS system! 🛡️🚀**

