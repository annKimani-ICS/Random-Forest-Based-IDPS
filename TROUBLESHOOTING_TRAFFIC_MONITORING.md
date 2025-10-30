# Troubleshooting Guide: Traffic Monitoring Issues

## Problem: No Alerts Showing in GUI

If you're not seeing alerts when launching attacks, follow these steps:

---

## Step 1: Check Backend Logs

**Look for these indicators:**

1. **Monitoring started successfully:**
   ```
   [API] Creating TrafficMonitor instance with interface=...
   [API] TrafficMonitor created, starting async monitoring...
   [BACKEND] Starting monitoring thread for interface: ...
   [BACKEND] is_monitoring is now: True
   ```

2. **Packets being captured:**
   ```
   [MONITOR] New flow detected: <src_ip> → <dst_ip>
   [MONITOR] Flow <src_ip> → <dst_ip>: 100 packets, XXX pps
   ```

3. **Alerts being created:**
   ```
   [MONITOR] Analyzing flow <src_ip> → <dst_ip> after 5.0s (XXX packets)
   🚨 Alert created: <src_ip> → <dst_ip> (score: X.XXX)
   ```

**If you DON'T see these messages, monitoring isn't working.**

---

## Step 2: Run Diagnostic Script

```bash
cd backend
python debug_traffic_monitoring.py
```

This will check:
- ✅ Scapy installation
- ✅ Model files existence
- ✅ Database alerts
- ✅ Monitor initialization
- ✅ Backend API availability

For packet capture test:
```bash
sudo python debug_traffic_monitoring.py --test-capture
```

---

## Common Issues and Fixes

### Issue 1: "Permission denied" or "Operation not permitted"

**Symptoms:**
- Backend logs show: `PermissionError` or `OSError: [Errno 1]`
- No packets being captured

**Solution:**

**Option A: Run backend with sudo (testing only)**
```bash
sudo python -m app.main
```

**Option B: Set CAP_NET_RAW capability (production)**
```bash
sudo setcap cap_net_raw=eip $(which python3)
# Or for systemd service:
sudo systemctl edit ids-idps-backend.service
```

Add:
```ini
[Service]
Capabilities=CAP_NET_RAW+eip
CapabilityBoundingSet=CAP_NET_RAW
AmbientCapabilities=CAP_NET_RAW
```

Then restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart ids-idps-backend.service
```

---

### Issue 2: Wrong Network Interface

**Symptoms:**
- Monitoring appears active but captures no packets
- Backend shows: `[MONITOR] Starting monitoring thread` but no flows detected

**Solution:**

1. **Find your interface:**
   ```bash
   ip addr show
   # or
   ifconfig
   ```

2. **Common interface names:**
   - Ubuntu VM: `ens33`, `enp0s3`, `eth0`
   - Kali: `eth0`, `wlan0`
   - Docker: `docker0`

3. **Set interface in GUI:**
   - When starting monitoring, ensure correct interface name
   - Or modify backend to auto-detect

4. **Test interface:**
   ```bash
   sudo tcpdump -i eth0 -c 10  # Replace eth0 with your interface
   ```

---

### Issue 3: Threshold Too High

**Symptoms:**
- Packets are captured (`[MONITOR] Flow detected`)
- Analysis runs (`[MONITOR] Analyzing flow`)
- But NO alerts created

**Solution:**

1. **Check current threshold in GUI**
   - Look at "Detection Threshold" card
   - Default is 0.50 (50%)

2. **Lower threshold:**
   - In GUI: Go to Settings tab → Move slider left (e.g., 0.30)
   - Or when starting monitoring: Set threshold lower

3. **Check score in logs:**
   ```
   [MONITOR] Analyzing flow 192.168.1.100 → 192.168.1.50 after 5.0s (150 packets)
   ⚠️ Score: 0.45 < threshold 0.50, skipping alert
   ```

---

### Issue 4: Window Size Too Long

**Symptoms:**
- Monitoring active
- Packets captured but no alerts for 5+ seconds

**Solution:**

The system waits **5 seconds** (window_size) before analyzing. This is normal.

**To see alerts faster:**
- Wait at least 5-10 seconds after starting traffic
- Or modify `window_size` in `traffic_monitor.py` (not recommended for production)

---

### Issue 5: No Traffic Reaching Monitor

**Symptoms:**
- Monitoring active (`is_monitoring = True`)
- No `[MONITOR] New flow detected` messages
- Backend shows monitoring thread running

**Solution:**

1. **Verify traffic is actually being sent:**
   ```bash
   # From Kali (as attacker)
   sudo hping3 -S --flood -V -p 80 <target_ip>
   ```

2. **Ensure target is correct:**
   - Target IP should be reachable from monitoring server
   - Check network connectivity: `ping <target_ip>`

3. **Check if monitor is on the right network:**
   - If using bridged networking, monitor should see all traffic
   - If using NAT, monitor might only see internal traffic

4. **Test with localhost traffic:**
   ```bash
   # On monitoring server
   curl http://localhost:8000/ &
   # Should see packets if monitoring localhost
   ```

---

### Issue 6: Duplicate Alert Prevention

**Symptoms:**
- First alert appears
- Subsequent attacks don't create new alerts
- Logs show: `⏭️ Skipping duplicate alert`

**Solution:**

This is **normal behavior**. The system prevents duplicate alerts within 30 seconds.

**To see new alerts:**
- Wait 30+ seconds between attacks
- Or use different source IPs
- Or modify `_create_alert()` in `traffic_monitor.py` (change duplicate window)

---

### Issue 7: GUI Not Refreshing

**Symptoms:**
- Alerts in database (check with diagnostic script)
- But GUI shows old/empty alerts list

**Solution:**

1. **Manual refresh:**
   - Click "Refresh" button in Alerts tab
   - Or switch to Dashboard tab and back

2. **Auto-refresh:**
   - GUI auto-refreshes every 30 seconds
   - Wait for next refresh cycle
   - Or reduce refresh interval in `dashboard_window.py` (line 146)

3. **Check filters:**
   - Ensure "Malicious Only" filter isn't hiding alerts
   - Check status filter ("All Status")

---

### Issue 8: Model Loading Failed

**Symptoms:**
- Backend logs: `⚠️ Model file not found` or loading errors
- No predictions, using dummy detection

**Solution:**

1. **Verify model files exist:**
   ```bash
   ls -la models/best_rf_iteration4_voting_ensemble.pkl
   ls -la models/scaler_iteration4.pkl
   ls -la models/imputer_iteration4.pkl
   ```

2. **Check file paths:**
   - Models should be in `Random-Forest-Based-IDPS/models/`
   - Backend runs from `backend/` directory
   - Path resolution should work, but verify

3. **Dummy detection still works:**
   - If model fails, system uses heuristic detection
   - High packet rate (>1000 pps) should trigger alerts
   - Lower threshold if needed

---

## Quick Diagnostic Checklist

Run through this checklist:

- [ ] Backend is running (`ps aux | grep "app.main"` or check systemd)
- [ ] Monitoring started (check GUI status or `/api/monitor/status`)
- [ ] Scapy installed (`pip list | grep scapy`)
- [ ] Correct interface selected
- [ ] Permission to capture packets (sudo or CAP_NET_RAW)
- [ ] Traffic is being generated (hping3 running, packets in logs)
- [ ] Threshold is reasonable (0.30-0.50 for testing)
- [ ] Wait 5+ seconds for window to complete
- [ ] Alerts in database (run diagnostic script)
- [ ] GUI refreshing (click Refresh or wait 30s)
- [ ] Filters not hiding alerts

---

## Testing Workflow

### Step 1: Start Backend
```bash
cd backend
python -m app.main
# Or with sudo if permission issues:
sudo python -m app.main
```

### Step 2: Start GUI
```bash
cd gui
python main.py
```

### Step 3: Start Monitoring (in GUI)
- Login as admin
- Go to Dashboard tab
- Click "Start Monitoring"
- Verify status shows "ACTIVE"

### Step 4: Generate Attack Traffic
```bash
# From Kali
sudo hping3 -S --flood -V -p 80 <target_ip>
```

### Step 5: Wait 5-10 seconds
The monitoring window is 5 seconds. Wait at least that long.

### Step 6: Check for Alerts
- Backend logs should show: `🚨 Alert created: ...`
- GUI should show alert in Alerts tab
- Click "Refresh" if needed

---

## Expected Log Output

**Successful monitoring:**

```
[API] Creating TrafficMonitor instance with interface=eth0, threshold=0.5
[BACKEND] Creating monitoring thread...
[BACKEND] Starting monitoring thread for interface: eth0
🔍 Starting traffic monitoring on interface: eth0
[BACKEND] Setting is_monitoring = True
[MONITOR] New flow detected: 192.168.1.100 → 192.168.1.50
[MONITOR] Flow 192.168.1.100 → 192.168.1.50: 100 packets, 500.0 pps
[MONITOR] Flow 192.168.1.100 → 192.168.1.50: 200 packets, 520.0 pps
[MONITOR] Analyzing flow 192.168.1.100 → 192.168.1.50 after 5.0s (250 packets)
🚨 Alert created: 192.168.1.100 → 192.168.1.50 (score: 0.750)
```

---

## Still Not Working?

1. **Run full diagnostic:**
   ```bash
   cd backend
   sudo python debug_traffic_monitoring.py --test-capture
   ```

2. **Check backend logs:**
   ```bash
   # If using systemd:
   sudo journalctl -u ids-idps-backend.service -f
   
   # If running manually:
   # Check console output for errors
   ```

3. **Test API directly:**
   ```bash
   curl -X GET http://localhost:8000/api/monitor/status \
     -H "Authorization: Bearer <your_token>"
   ```

4. **Check database:**
   ```bash
   cd backend
   python -c "from app.database import SessionLocal; from app.models import Alert; from datetime import datetime, timedelta; db = SessionLocal(); alerts = db.query(Alert).filter(Alert.event_ts >= datetime.utcnow() - timedelta(minutes=5)).all(); print(f'Recent alerts: {len(alerts)}'); [print(f'  {a.id}: {a.src_ip} -> {a.dst_ip} (score: {a.score})') for a in alerts[:5]]"
   ```

---

## Summary

Most common issues:
1. **Permission denied** → Run with sudo or set CAP_NET_RAW
2. **Wrong interface** → Use `ip addr` to find correct interface
3. **Threshold too high** → Lower to 0.30-0.40 for testing
4. **Not waiting long enough** → System needs 5 seconds per window
5. **GUI not refreshing** → Click Refresh or wait 30 seconds

If all else fails, check backend logs - they're your best friend for debugging!


