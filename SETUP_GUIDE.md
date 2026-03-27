# Quick Setup Guide - Integrated Fixes

## 🚀 Complete Backend Setup (One Command)

All fixes have been integrated into the main codebase. Setup is now automated:

```bash
cd backend
python3 setup.py
```

This single command:
- ✅ Checks and starts PostgreSQL
- ✅ Creates database using postgres superuser (no password issues)
- ✅ Sets up virtual environment
- ✅ Installs all dependencies with correct versions
- ✅ Creates .env file
- ✅ Creates database tables
- ✅ Creates Admin and Analyst users
- ✅ Updates model metrics with correct values

## 🧪 Test All Fixes

After setup, verify everything works:

```bash
cd backend
python3 test_fixes.py
```

## 📋 Integrated Fixes

All fixes are now in the main code:

1. **Pydantic v1** - `requirements.txt` uses `pydantic<2.0.0`
2. **Absolute Imports** - All routers use `from app.*`
3. **API Timeouts** - GUI API client has 10s timeouts
4. **Database Setup** - Uses postgres superuser (most reliable)
5. **User Creation** - Automated in setup.py
6. **Model Metrics** - Automated in setup.py
7. **DDoS Alerts** - `add_dummy_alerts.py` creates only DDoS attacks

## 🎯 Login Credentials

After setup:
- **Admin**: `admin@ids-idps.com` / `AdminSecure2024!`
- **Analyst**: `analyst@ids-idps.com` / `AnalystSecure2024!`

## 🚀 Start System

### Backend:
```bash
cd backend
source .venv/bin/activate
export PYTHONPATH=$(pwd)
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### GUI:
```bash
./run_gui.sh
```

## 📊 Model Metrics

After setup, model metrics are automatically set:
- **Accuracy**: 90.48%
- **Precision**: 90.62%
- **Recall**: 90.48%
- **F1-Score**: 90.51%
- **AUC**: 95.00%
- **Training Date**: October 15, 2025

## 🗑️ Cleanup Temporary Scripts

To remove all temporary fix scripts (fixes are now integrated):

```bash
./cleanup_temp_scripts.sh
```

## ✅ No More Manual Fixes Needed!

All fixes are integrated. Just run `python3 setup.py` and everything works!

