# Testing Guide: DDoS Attacks and Normal Traffic Simulation

## Prerequisites

1. **Kali Linux VM** with `hping3` installed:
   ```bash
   sudo apt update
   sudo apt install -y hping3
   ```

2. **Ubuntu IDS/IDPS VM** with monitoring **ACTIVE** in the GUI

3. **Find the Ubuntu VM's IP Address** (if you don't know it):
   ```bash
   # On Ubuntu VM:
   hostname -I
   # or
   ip addr show | grep "inet " | grep -v "127.0.0.1"
   ```

---

## Step 1: Start Monitoring in GUI

1. Open the IDS/IDPS GUI on Ubuntu VM
2. Log in as admin
3. Go to **Dashboard** tab
4. In **Traffic Monitoring** section, click **"▶ Start Monitoring"**
5. Verify status shows: **"Status: ✅ ACTIVE"**
6. Note the interface (e.g., `enp0s3`) and threshold (e.g., `0.50`)

---

## Step 2: Launch DDoS Attack Tests

### Attack Type 1: SYN Flood (Most Common)

```bash
# On Kali Linux VM
# Replace <UBUNTU_VM_IP> with actual IP (e.g., 192.168.1.100)

# Light attack (for testing - won't overwhelm)
sudo hping3 -S --flood -V -p 80 <UBUNTU_VM_IP>

# Heavier attack (more packets)
sudo hping3 -S --flood -V -p 80 --fast <UBUNTU_VM_IP>

# Attack with data
sudo hping3 -S --flood -V -p 80 --data 64 <UBUNTU_VM_IP>

# To stop the attack: Press Ctrl+C
```

### Attack Type 2: UDP Flood

```bash
# UDP flood attack
sudo hping3 --udp --flood -V -p 53 <UBUNTU_VM_IP>

# To stop: Ctrl+C
```

### Attack Type 3: ICMP Flood (Ping Flood)

```bash
# ICMP/Ping flood
sudo hping3 --icmp --flood -V <UBUNTU_VM_IP>

# To stop: Ctrl+C
```

### Attack Type 4: Multi-Port SYN Flood

```bash
# Attack multiple ports simultaneously
sudo hping3 -S --flood -V -p ++80 <UBUNTU_VM_IP>

# To stop: Ctrl+C
```

### Attack Type 5: Random Source IP Flood (DDoS with spoofing)

```bash
# SYN flood with random source IPs (if allowed)
sudo hping3 -S --flood -V -p 80 -a <RANDOM_IP> <UBUNTU_VM_IP>

# Example with fake source:
sudo hping3 -S --flood -V -p 80 -a 198.51.100.50 <UBUNTU_VM_IP>

# To stop: Ctrl+C
```

---

## Step 3: Simulate Normal User Traffic

### Normal Traffic 1: HTTP Requests (Web Browsing)

```bash
# On Kali Linux VM - Simulate normal web browsing

# Single HTTP GET request
curl -v http://<UBUNTU_VM_IP>:8000/

# Multiple sequential requests (slow, normal pace)
for i in {1..10}; do
    curl http://<UBUNTU_VM_IP>:8000/
    sleep 1  # 1 second delay between requests
done

# More realistic: Slow requests with delays
for i in {1..5}; do
    curl -v http://<UBUNTU_VM_IP>:8000/ > /dev/null 2>&1
    echo "Request $i sent"
    sleep 2
done
```

### Normal Traffic 2: Slow, Intermittent Connections

```bash
# Simulate user browsing with pauses
for i in {1..20}; do
    curl -s http://<UBUNTU_VM_IP>:8000/ > /dev/null
    echo "Normal request $i"
    sleep 3  # 3 seconds between requests (normal user pace)
done
```

### Normal Traffic 3: SSH Connection (Legitimate)

```bash
# Try to SSH (will fail but creates legitimate connection attempts)
ssh -o ConnectTimeout=5 server@<UBUNTU_VM_IP> || true

# Multiple legitimate connection attempts
for i in {1..5}; do
    ssh -o ConnectTimeout=3 server@<UBUNTU_VM_IP> || true
    sleep 2
done
```

### Normal Traffic 4: Ping (Normal ICMP)

```bash
# Normal ping (not flood)
ping -c 10 <UBUNTU_VM_IP>  # 10 pings with default intervals

# Slow ping
ping -c 5 -i 2 <UBUNTU_VM_IP>  # 5 pings, 2 seconds apart
```

### Normal Traffic 5: TCP Connection to Known Ports

```bash
# Normal TCP connections (will timeout, but shows legitimate traffic)
nc -zv <UBUNTU_VM_IP> 8000   # Try to connect
nc -zv <UBUNTU_VM_IP> 80     # Try HTTP port
nc -zv <UBUNTU_VM_IP> 443    # Try HTTPS port

# With delays between attempts
for port in 80 443 8000 22; do
    echo "Trying port $port..."
    nc -zv -w 2 <UBUNTU_VM_IP> $port || true
    sleep 1
done
```

---

## Step 4: Monitor Results in GUI

### What to Check After Attacks:

1. **Dashboard Tab:**
   - **Alert count** should increase after attacks
   - **Recent Alerts** table shows new DDoS detections
   - Each alert should have:
     - Source IP (from Kali VM)
     - Attack Type: "DDoS"
     - Score: > 0.50 (threshold)
     - Status: "NEW"

2. **Alerts Tab:**
   - Full table of all alerts
   - Filter by "Malicious Only" to see attack alerts
   - Check timestamps match attack times

3. **Status:**
   - Monitoring should remain "✅ ACTIVE"
   - Interface and threshold shown correctly

### What to Check After Normal Traffic:

1. **Alerts Tab:**
   - Should have **NO new alerts** or **very few** (if any, they should have lower scores < 0.50)
   - Normal traffic should **NOT** be marked as malicious

2. **Dashboard:**
   - Alert count should **NOT** increase significantly
   - Any new alerts from normal traffic should be benign (green score indicators)

---

## Step 5: Testing Scenarios

### Scenario 1: Attack → Normal Traffic → Attack

```bash
# 1. Launch attack (30 seconds)
sudo hping3 -S --flood -V -p 80 <UBUNTU_VM_IP> &
ATTACK_PID=$!
sleep 30
kill $ATTACK_PID

# 2. Wait and send normal traffic
sleep 10
for i in {1..5}; do
    curl -s http://<UBUNTU_VM_IP>:8000/ > /dev/null
    sleep 2
done

# 3. Launch another attack
sudo hping3 -S --flood -V -p 80 <UBUNTU_VM_IP> &
sleep 30
kill $ATTACK_PID
```

### Scenario 2: Gradual Attack (Slow Ramp-Up)

```bash
# Gradually increase packet rate
for rate in 10 50 100 200 500; do
    echo "Testing at rate: $rate pps"
    sudo hping3 -S --flood -V -p 80 --faster $rate <UBUNTU_VM_IP> &
    sleep 10
    pkill hping3
    sleep 5
done
```

### Scenario 3: Mixed Traffic (Attack + Normal)

```bash
# In Terminal 1: Launch attack
sudo hping3 -S --flood -V -p 80 <UBUNTU_VM_IP>

# In Terminal 2 (new terminal): Send normal traffic
for i in {1..20}; do
    curl -s http://<UBUNTU_VM_IP>:8000/ > /dev/null
    sleep 1
done
```

---

## Expected Results

### ✅ Successful DDoS Detection:
- Alerts appear within 5-10 seconds of attack start
- Alerts show:
  - High scores (> 0.50)
  - Attack Type: "DDoS"
  - Source IP from Kali VM
  - Status: "NEW"

### ✅ Successful False Positive Avoidance:
- Normal traffic does NOT trigger alerts
- Alert count stays low during normal traffic tests
- If any alerts appear from normal traffic, scores should be < 0.50

### ❌ If No Alerts Appear:
1. Check monitoring is "✅ ACTIVE"
2. Verify backend logs: `sudo journalctl -u ids-idps-backend -f`
3. Check if packets are being captured
4. Verify threshold is set correctly (0.50)

### ❌ If Too Many False Positives:
1. Increase threshold in Settings tab
2. Check if normal traffic patterns are too aggressive
3. Review alert scores - they should be < 0.50 for benign traffic

---

## Cleanup

After testing:
1. Stop any running attacks: `sudo pkill hping3`
2. Stop monitoring in GUI: Click "⏹ Stop Monitoring"
3. Verify status shows "⏸ INACTIVE"

---

## Tips

- **Start small**: Test with light attacks first
- **One at a time**: Test attacks separately to see results clearly
- **Watch logs**: Monitor backend logs for detailed information
- **Adjust threshold**: If you need more/less sensitivity, adjust in Settings tab
- **Check timing**: Alerts should appear quickly but may take a few seconds for aggregation

