# Quick Fix: Missing Dependencies

## Issue
When running `python3 debug_traffic_monitoring.py`, you get:
```
ModuleNotFoundError: No module named 'sqlalchemy'
```

## Solution

### Option 1: Install all backend dependencies (Recommended)

```bash
cd ~/Random-Forest-Based-IDPS/backend
pip3 install -r requirements.txt
pip3 install scapy  # For packet capture
```

### Option 2: Use the provided script

```bash
cd ~/Random-Forest-Based-IDPS/backend
chmod +x install_dependencies.sh
./install_dependencies.sh
```

### Option 3: Install manually if needed

```bash
cd ~/Random-Forest-Based-IDPS/backend
pip3 install sqlalchemy fastapi uvicorn pydantic python-jose passlib bcrypt python-multipart
pip3 install scapy  # For packet capture
```

## Verify Installation

After installing, test with:

```bash
python3 -c "import sqlalchemy; import fastapi; import scapy; print('✅ All modules found!')"
```

## Then Run Diagnostic

```bash
python3 debug_traffic_monitoring.py
```

## Note
If you're using a virtual environment, make sure it's activated first:
```bash
source venv/bin/activate  # If you have a venv
pip3 install -r requirements.txt
```

