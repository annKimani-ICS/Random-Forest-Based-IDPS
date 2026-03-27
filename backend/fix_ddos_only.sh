#!/bin/bash
# Fix DDoS-only dummy data
# Clears all alerts and repopulates with only DDoS attacks

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fix DDoS-Only Dummy Data${NC}"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we're in backend directory
if [ ! -f "app/main.py" ]; then
    echo -e "${RED}❌ Please run this script from the backend directory${NC}"
    exit 1
fi

# Activate virtual environment
if [ -d ".venv" ]; then
    source .venv/bin/activate
elif [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${GREEN}✅ Virtual environment already active${NC}"
else
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Testing database connection...${NC}"
if python3 -c "
from app.database import SessionLocal
from sqlalchemy import text
try:
    db = SessionLocal()
    db.execute(text('SELECT 1'))
    db.close()
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection verified${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 2: Clearing ALL existing alerts...${NC}"
python3 <<'ENDPYTHON'
import sys
sys.path.insert(0, '.')
from app.database import SessionLocal
from app.models import Alert

db = SessionLocal()
try:
    # Delete all existing alerts
    count = db.query(Alert).count()
    db.query(Alert).delete()
    db.commit()
    print(f"✅ Deleted {count} existing alerts")
except Exception as e:
    print(f"❌ Error deleting alerts: {e}")
    db.rollback()
finally:
    db.close()
ENDPYTHON

echo -e "${BLUE}📋 Step 3: Creating DDoS-only dummy alerts...${NC}"
python3 <<'ENDPYTHON'
import sys
sys.path.insert(0, '.')
from app.database import SessionLocal
from app.models import Alert, AlertStatus
from datetime import datetime, timedelta
import random

db = SessionLocal()
try:
    # Only DDoS attacks
    attack_type = "DDoS"
    
    # Sample IP addresses
    source_ips = [
        "192.168.1.100", "10.0.0.50", "172.16.0.25", "203.0.113.10",
        "198.51.100.5", "192.0.2.15", "203.0.113.45", "198.51.100.20"
    ]
    
    dest_ips = [
        "192.168.1.1", "10.0.0.1", "172.16.0.1", "203.0.113.1",
        "198.51.100.1", "192.0.2.1", "10.10.10.1", "172.20.0.1"
    ]
    
    # Generate alerts for the last 7 days
    alerts = []
    base_time = datetime.now()
    
    for i in range(50):  # Generate 50 DDoS alerts
        # Random time in last 7 days
        hours_ago = random.randint(0, 168)  # 0 to 168 hours (7 days)
        event_time = base_time - timedelta(hours=hours_ago)
        
        # Random source and destination IPs
        src_ip = random.choice(source_ips)
        dst_ip = random.choice(dest_ips)
        
        # Random score (0.0 to 1.0)
        score = round(random.uniform(0.1, 0.99), 4)
        
        # Determine if malicious based on score
        is_malicious = score >= 0.5
        
        # Random status
        status = random.choice(list(AlertStatus))
        
        # Create alert - ONLY DDoS
        alert = Alert(
            event_ts=event_time,
            src_ip=src_ip,
            dst_ip=dst_ip,
            attack_type=attack_type,  # Always DDoS
            score=score,
            is_malicious=is_malicious,
            status=status,
            model_version="iteration4_voting_ensemble",
            payload={
                "protocol": random.choice(["TCP", "UDP", "ICMP"]),
                "port": random.randint(1, 65535),
                "packet_count": random.randint(1000, 100000),  # High packet count for DDoS
                "bytes_transferred": random.randint(100000, 10000000)  # High bytes for DDoS
            }
        )
        alerts.append(alert)
    
    # Bulk insert
    db.bulk_save_objects(alerts)
    db.commit()
    
    print(f"✅ Created {len(alerts)} DDoS alerts")
    print(f"   All alerts are of type: DDoS")
    
    # Verify all alerts are DDoS
    total_alerts = db.query(Alert).count()
    ddos_alerts = db.query(Alert).filter(Alert.attack_type == "DDoS").count()
    
    print(f"\n📊 Verification:")
    print(f"   Total alerts: {total_alerts}")
    print(f"   DDoS alerts: {ddos_alerts}")
    
    if total_alerts == ddos_alerts:
        print("✅ All alerts are DDoS attacks!")
    else:
        print(f"⚠️  Warning: {total_alerts - ddos_alerts} non-DDoS alerts found")
        
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    db.rollback()
finally:
    db.close()
ENDPYTHON

echo ""
echo -e "${GREEN}🎉 DDoS-Only Fix Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 Summary:${NC}"
echo "   ✅ Cleared all existing alerts"
echo "   ✅ Created 50 new alerts"
echo "   ✅ All alerts are DDoS attacks only"
echo ""
echo -e "${BLUE}🔄 Next Steps:${NC}"
echo "  1. Refresh the GUI dashboard"
echo "  2. All alerts should show 'DDoS' as attack type"
echo ""
echo -e "${GREEN}🎯 DDoS-only dummy data is now fixed!${NC}"

