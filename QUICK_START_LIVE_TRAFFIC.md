# Quick Start: Live Traffic Testing

Fast guide to test live traffic detection with DDoS simulation.

## Prerequisites Check

✅ Backend running: `curl http://localhost:8000/health`  
✅ Database connected  
✅ Models in `models/` directory  
✅ Admin login credentials  

## Step 1: Install Dependencies

```bash
cd backend
source .venv/bin/activate  # or: .venv/Scripts/activate on Windows
pip install -r requirements.txt
```

## Step 2: Start Monitoring

### Via API:
```bash
# Get token
TOKEN=$(curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@ids.local", "password": "YOUR_PASSWORD"}' \
  | jq -r '.access_token')

# Start monitoring
curl -X POST http://localhost:8000/api/monitor/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"interface": "eth0", "threshold": 0.50}'
```

### Via Command Line:
```bash
cd backend
python3 -m app.traffic_monitor --interface eth0 --threshold 0.50
```

## Step 3: Find Target IP

```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
# Note the IP (e.g., 192.168.1.100)
```

## Step 4: Launch Attack (Kali Linux)

```bash
# Install tools
sudo apt-get install hping3

# SYN flood
sudo hping3 -S --flood -V -p 80 TARGET_IP

# UDP flood
sudo hping3 --udp --flood -V -p 53 TARGET_IP

# ICMP flood
sudo hping3 --icmp --flood -V TARGET_IP
```

## Step 5: Verify in GUI

1. **Open GUI**: `cd gui && python main.py`
2. **Login** as Admin
3. **Dashboard** shows:
   - Alert count increasing
   - New alerts in table
   - Source IPs matching attacker
   - Detection scores > threshold

## Step 6: Verify via API

```bash
# Check alerts
curl "http://localhost:8000/api/alerts?page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# Check KPIs
curl http://localhost:8000/api/kpis \
  -H "Authorization: Bearer $TOKEN" | jq
```

## Expected Results

✅ Alerts appear within **5-10 seconds**  
✅ Alert count increases  
✅ Source IPs match attacker  
✅ Scores are **0.70-0.95** for DDoS  
✅ GUI updates automatically  

## Troubleshooting

**No alerts?**
- Check monitoring status: `curl http://localhost:8000/api/monitor/status`
- Verify interface: `ip addr show`
- Check backend logs for errors
- Lower threshold: `{"threshold": 0.30}`

**GUI not updating?**
- Check API connectivity
- Refresh manually
- Re-login if token expired

## Full Guide

See `LIVE_TRAFFIC_TESTING_GUIDE.md` for detailed instructions.

