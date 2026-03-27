# 🚀 Automated Backend Setup

This script automatically applies all fixes and sets up the backend for you.

## Quick Start

```bash
# On your Ubuntu VM, run this single command:
cd ~/Random-Forest-Based-IDPS/backend
chmod +x auto_setup.sh
./auto_setup.sh
```

## What It Does Automatically

✅ **PostgreSQL Setup**
- Installs PostgreSQL if missing
- Creates database `ids_db`
- Creates user `ids_user` with password `ids_password`
- Grants proper permissions

✅ **Environment Configuration**
- Creates `.env` file with correct database URL
- Sets up JWT secrets
- Configures CORS for port 3000

✅ **Python Environment**
- Creates virtual environment `.venv`
- Installs all dependencies
- Upgrades pip and tools

✅ **Database Setup**
- Runs Alembic migrations
- Creates all tables
- Populates correct Random Forest metrics

✅ **Startup Script**
- Creates `start_backend.sh` for easy startup
- Configures backend to run on port 3000

## After Setup

```bash
# Start backend
./start_backend.sh

# In another terminal, start GUI
cd ../gui
python main.py
```

## Expected Results

The GUI will now show:
- **Accuracy**: 90.48%
- **Precision**: 90.62%
- **Recall**: 90.48%
- **F1-Score**: 90.51%
- **AUC**: 95.00%
- **Model**: Random Forest Voting Ensemble

## Troubleshooting

If you get permission errors:
```bash
sudo chmod +x auto_setup.sh
```

If PostgreSQL fails to start:
```bash
sudo systemctl restart postgresql
```
