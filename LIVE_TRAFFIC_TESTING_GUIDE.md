# Live Traffic Testing Guide for IDS/IDPS System

Complete guide for testing the IDS/IDPS system with real network traffic and DDoS attacks.

## Overview

This guide explains how to:
1. Start the traffic monitoring service
2. Simulate DDoS attacks from a Kali Linux VM
3. Verify that the system detects attacks in real-time
4. Confirm alerts appear correctly in the GUI

## Prerequisites

### On Ubuntu VM (IDS/IDPS Server)
- ✅ Backend API running on port 8000
- ✅ PostgreSQL database accessible
- ✅ ML models loaded (in `models/` directory)
- ✅ Admin user created and logged in
- ✅ GUI application (optional, for visualization)
- ✅ Traffic monitor service ready

### On Kali Linux VM (Attacker)
- ✅ Network connectivity to Ubuntu VM
- ✅ Root privileges for packet crafting
- ✅ Tools: `hping3`, `slowhttptest`, `nmap`

## System Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│   Kali Linux    │         │   Ubuntu VM      │         │   Database      │
│   (Attacker)    │────────►│   (IDS/IDPS)     │────────►│   (PostgreSQL)  │
│                 │ Traffic │                  │ Alerts  │                 │
│  - hping3       │         │  - Traffic       │         │  - Alerts table  │
│  - slowhttptest │         │    Monitor       │         │  - Metrics       │
└─────────────────┘         │  - ML Model      │         └─────────────────┘
                            │  - GUI           │
                            └──────────────────┘
```

## Step 1: Start Traffic Monitoring

### Option A: Via GUI (Recommended)
1. Launch the desktop GUI
2. Login as Admin
3. Navigate to Dashboard
4. Click "Start Monitoring" button (if available)
5. Select network interface (e.g., `eth0`, `enp0s3`)
6. Set detection threshold (default: 0.50)

### Option B: Via API
```bash
# 1. Get authentication token
TOKEN=$(curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@ids.local", "password": "YOUR_PASSWORD"}' \
  | jq -r '.access_token')

# 2. Start monitoring
curl -X POST http://localhost:8000/api/monitor/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "interface": "eth0",
    "threshold": 0.50
  }'

# 3. Check status
curl http://localhost:8000/api/monitor/status \
  -H "Authorization: Bearer $TOKEN"
```

### Option C: Via Command Line (Direct)
```bash
cd backend
source .venv/bin/activate
python3 -m app.traffic_monitor --interface eth0 --threshold 0.50
```

## Step 2: Find Target IP Address

On Ubuntu VM:
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
# Example output: inet 192.168.1.100/24
```

Note the IP address (e.g., `192.168.1.100`).

## Step 3: Install Attack Tools on Kali Linux

```bash
sudo apt-get update
sudo apt-get install -y hping3 slowhttptest nmap
```

## Step 4: Launch DDoS Attacks

### SYN Flood (TCP)
```bash
# Basic SYN flood
sudo hping3 -S --flood -V -p 80 TARGET_IP

# SYN flood with specific rate
sudo hping3 -S --flood -V -p 80 -i u100 TARGET_IP

# SYN flood to specific port range
sudo hping3 -S --flood -V -p ++80 TARGET_IP
```

### UDP Flood
```bash
# UDP flood to DNS port
sudo hping3 --udp --flood -V -p 53 TARGET_IP

# UDP flood to custom port
sudo hping3 --udp --flood -V -p 8080 TARGET_IP
```

### ICMP Flood (Ping Flood)
```bash
# ICMP ping flood
sudo hping3 --icmp --flood -V TARGET_IP

# Using ping command
sudo ping -f TARGET_IP
```

### Slow HTTP Attack
```bash
# Slow HTTP GET attack
slowhttptest -c 1000 -H -g -o /tmp/slowhttp -i 10 -r 200 \
  -t GET -u http://TARGET_IP:8000 -x 24 -p 3

# Slow HTTP POST attack
slowhttptest -c 1000 -B -g -o /tmp/slowhttp -i 10 -r 200 \
  -t POST -u http://TARGET_IP:8000 -x 24 -p 3
```

### Multi-vector Attack (Combined)
```bash
# Run multiple attacks simultaneously
sudo hping3 -S --flood -V -p 80 TARGET_IP &
sudo hping3 --udp --flood -V -p 53 TARGET_IP &
sudo hping3 --icmp --flood -V TARGET_IP &
```

## Step 5: Verify Detection in GUI

### Check Dashboard
1. Open GUI application
2. Navigate to Dashboard
3. Verify:
   - **Alerts in last 24h** counter increases
   - Alert table shows new entries
   - Source IPs match attacker IP
   - Attack type is "DDoS"
   - Detection scores are above threshold

### Check Alert Details
Each alert should show:
- **Event Timestamp**: When detected
- **Source IP**: Attacker's IP address
- **Destination IP**: Target server IP
- **Attack Type**: "DDoS"
- **Score**: Detection confidence (0.0-1.0)
- **Status**: "NEW"
- **Payload**: Packet statistics (packets, bytes, protocols)

### Real-time Updates
- GUI should auto-refresh every few seconds
- New alerts appear at the top of the table
- KPIs update automatically

## Step 6: Verify via API

### Check Recent Alerts
```bash
curl "http://localhost:8000/api/alerts?page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN" | jq
```

Expected output:
```json
{
  "alerts": [
    {
      "id": 123,
      "event_ts": "2025-01-15T10:30:00",
      "src_ip": "192.168.1.50",
      "dst_ip": "192.168.1.100",
      "attack_type": "DDoS",
      "score": 0.85,
      "is_malicious": true,
      "status": "NEW",
      "payload": {
        "packets": 15000,
        "bytes": 1200000,
        "packets_per_second": 3000,
        "protocols": {"tcp": 12000, "udp": 3000, "icmp": 0}
      }
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 10
}
```

### Check KPIs
```bash
curl http://localhost:8000/api/kpis \
  -H "Authorization: Bearer $TOKEN" | jq
```

Expected:
- `alerts_24h` increases
- `active_blocks` may increase if blocking enabled

## Step 7: Monitor Backend Logs

### If Running as Service
```bash
sudo journalctl -u ids-idps-backend -f
```

Look for messages like:
```
🚨 Alert created: 192.168.1.50 → 192.168.1.100 (score: 0.850)
```

### If Running Manually
Check the terminal where traffic monitor is running for:
- `✅ Loaded ML model`
- `🔍 Starting traffic monitoring`
- `🚨 Alert created` messages

## Step 8: Performance Verification

### Detection Latency
- Alerts should appear within **5-10 seconds** of attack start
- Model processes packets in 5-second windows

### False Positive Check
- Normal browsing/SSH traffic should NOT trigger alerts
- Only high-volume, suspicious traffic should be flagged

### System Performance
Monitor system resources:
```bash
# CPU usage
top -p $(pgrep -f traffic_monitor)

# Memory usage
ps aux | grep traffic_monitor

# Network statistics
iftop -i eth0
```

## Troubleshooting

### No Alerts Appearing

1. **Check monitoring status**:
   ```bash
   curl http://localhost:8000/api/monitor/status \
     -H "Authorization: Bearer $TOKEN"
   ```

2. **Verify interface**:
   - Ensure correct network interface selected
   - Check `ip addr show` for available interfaces

3. **Check model loading**:
   - Verify model files exist in `models/` directory
   - Check backend logs for model loading errors

4. **Verify threshold**:
   - Lower threshold (e.g., 0.30) for more sensitive detection
   - Check if attack volume is sufficient

### Alerts Not Updating in GUI

1. **Check API connectivity**:
   ```bash
   curl http://localhost:8000/health
   ```

2. **Verify GUI refresh interval**:
   - GUI should auto-refresh every 5-10 seconds
   - Manually refresh if needed

3. **Check authentication**:
   - Token may have expired
   - Re-login if necessary

### Model Not Loading

1. **Check file paths**:
   ```bash
   ls -la models/*.pkl
   ls -la models/*.json
   ```

2. **Verify file permissions**:
   ```bash
   chmod 644 models/*.pkl models/*.json
   ```

3. **Check Python dependencies**:
   ```bash
   pip install scikit-learn joblib pandas numpy
   ```

## Expected Results

### Successful Detection

✅ **Before Attack**:
- Dashboard shows baseline metrics
- No new alerts in last minute
- Alert count stable

✅ **During Attack**:
- Alert count increases rapidly
- New alerts appear every 5-10 seconds
- Source IP matches attacker
- High detection scores (0.70-0.95)
- Payload shows high packet/byte counts

✅ **After Attack**:
- Alert generation slows/stops
- Alerts remain visible in table
- Can acknowledge/block suspicious IPs

## Security Notes

⚠️ **IMPORTANT**: 
- Only run DDoS tests in **isolated lab environments**
- Do NOT test against production systems
- Obtain proper authorization before testing
- Monitor system resources to avoid overload
- Stop attacks immediately after verification

## Next Steps

After successful testing:
1. **Fine-tune threshold** based on false positive rate
2. **Configure blocking rules** for automatic mitigation
3. **Set up alerts** for security team notifications
4. **Document baseline traffic** for comparison
5. **Plan production deployment** with proper monitoring

## Additional Resources

- [CIC-DDoS2019 Dataset Documentation](https://www.unb.ca/cic/datasets/ddos-2019.html)
- [Scapy Documentation](https://scapy.readthedocs.io/)
- [hping3 Manual](http://www.hping.org/manpage.html)

---

**Last Updated**: January 2025  
**System Version**: Iteration 4 (Voting Ensemble Model)

