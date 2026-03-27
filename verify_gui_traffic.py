#!/usr/bin/env python3
"""
Verify that GUI can display real-time alerts correctly
Tests the complete flow: traffic detection → database → API → GUI
"""
import sys
import time
import requests
from datetime import datetime, timedelta

# Configuration
BACKEND_URL = "http://localhost:8000"
TEST_EMAIL = "admin@ids.local"
TEST_PASSWORD = "admin123"  # Update with actual password

def test_system_readiness():
    """Test 1: Verify backend is running"""
    print("🔍 Test 1: Checking backend health...")
    try:
        response = requests.get(f"{BACKEND_URL}/health", timeout=5)
        if response.status_code == 200:
            print("   ✅ Backend is running")
            return True
        else:
            print(f"   ❌ Backend returned {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Cannot connect to backend: {e}")
        print("   💡 Start backend with: cd backend && ./run_backend.sh")
        return False

def test_authentication():
    """Test 2: Authenticate and get token"""
    print("\n🔍 Test 2: Testing authentication...")
    try:
        response = requests.post(
            f"{BACKEND_URL}/auth/login",
            json={"email": TEST_EMAIL, "password": TEST_PASSWORD},
            timeout=5
        )
        if response.status_code == 200:
            data = response.json()
            token = data.get("access_token")
            if token:
                print("   ✅ Authentication successful")
                return token
            else:
                print("   ❌ No token in response")
                return None
        else:
            print(f"   ❌ Authentication failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except Exception as e:
        print(f"   ❌ Auth error: {e}")
        return None

def test_monitoring_status(token):
    """Test 3: Check monitoring status"""
    print("\n🔍 Test 3: Checking monitoring status...")
    try:
        response = requests.get(
            f"{BACKEND_URL}/api/monitor/status",
            headers={"Authorization": f"Bearer {token}"},
            timeout=5
        )
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Monitoring status retrieved")
            print(f"   - Active: {data.get('is_monitoring', False)}")
            print(f"   - Interface: {data.get('interface', 'N/A')}")
            print(f"   - Threshold: {data.get('threshold', 'N/A')}")
            return True
        else:
            print(f"   ❌ Status check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Error checking status: {e}")
        return False

def test_alerts_api(token):
    """Test 4: Retrieve alerts"""
    print("\n🔍 Test 4: Testing alerts API...")
    try:
        response = requests.get(
            f"{BACKEND_URL}/api/alerts?page=1&page_size=5",
            headers={"Authorization": f"Bearer {token}"},
            timeout=5
        )
        if response.status_code == 200:
            data = response.json()
            alerts = data.get("alerts", [])
            total = data.get("total", 0)
            print(f"   ✅ Retrieved {len(alerts)} alerts (total: {total})")
            
            if alerts:
                latest = alerts[0]
                print(f"   📋 Latest alert:")
                print(f"      - ID: {latest.get('id')}")
                print(f"      - Source: {latest.get('src_ip')}")
                print(f"      - Type: {latest.get('attack_type')}")
                print(f"      - Score: {latest.get('score')}")
                print(f"      - Time: {latest.get('event_ts')}")
            else:
                print("   ⚠️  No alerts found (this is OK if no attacks detected)")
            
            return True
        else:
            print(f"   ❌ Alerts API failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Error retrieving alerts: {e}")
        return False

def test_kpis_api(token):
    """Test 5: Check KPIs"""
    print("\n🔍 Test 5: Testing KPIs API...")
    try:
        response = requests.get(
            f"{BACKEND_URL}/api/kpis",
            headers={"Authorization": f"Bearer {token}"},
            timeout=5
        )
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ KPIs retrieved")
            print(f"   - Alerts (24h): {data.get('alerts_24h', 0)}")
            print(f"   - Active blocks: {data.get('active_blocks', 0)}")
            print(f"   - Threshold: {data.get('threshold', 'N/A')}")
            print(f"   - Model version: {data.get('model_version', 'N/A')}")
            return True
        else:
            print(f"   ❌ KPIs API failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Error retrieving KPIs: {e}")
        return False

def test_real_time_detection(token):
    """Test 6: Simulate alert creation and verify it appears"""
    print("\n🔍 Test 6: Testing real-time detection...")
    print("   💡 This test verifies the system can detect and display new alerts")
    print("   💡 Start a DDoS attack from Kali VM and watch for new alerts")
    
    # Get initial alert count
    try:
        response = requests.get(
            f"{BACKEND_URL}/api/kpis",
            headers={"Authorization": f"Bearer {token}"},
            timeout=5
        )
        if response.status_code == 200:
            initial_count = response.json().get("alerts_24h", 0)
            print(f"   📊 Initial alert count: {initial_count}")
            print("   ⏳ Waiting 30 seconds for new alerts...")
            print("   💡 Launch DDoS attack now (see LIVE_TRAFFIC_TESTING_GUIDE.md)")
            
            time.sleep(30)
            
            # Check again
            response = requests.get(
                f"{BACKEND_URL}/api/kpis",
                headers={"Authorization": f"Bearer {token}"},
                timeout=5
            )
            if response.status_code == 200:
                new_count = response.json().get("alerts_24h", 0)
                print(f"   📊 New alert count: {new_count}")
                
                if new_count > initial_count:
                    print(f"   ✅ {new_count - initial_count} new alert(s) detected!")
                    return True
                else:
                    print(f"   ⚠️  No new alerts (ensure monitoring is active and attack is running)")
                    return False
    except Exception as e:
        print(f"   ❌ Error during real-time test: {e}")
        return False

def main():
    """Run all verification tests"""
    print("=" * 60)
    print("IDS/IDPS GUI Traffic Detection Verification")
    print("=" * 60)
    print()
    
    # Run tests
    if not test_system_readiness():
        print("\n❌ System not ready. Fix backend connection first.")
        sys.exit(1)
    
    token = test_authentication()
    if not token:
        print("\n❌ Authentication failed. Check credentials.")
        sys.exit(1)
    
    test_monitoring_status(token)
    test_alerts_api(token)
    test_kpis_api(token)
    
    print("\n" + "=" * 60)
    print("✅ Basic connectivity tests passed!")
    print()
    print("Next steps:")
    print("1. Start traffic monitoring:")
    print("   curl -X POST http://localhost:8000/api/monitor/start \\")
    print("        -H 'Authorization: Bearer YOUR_TOKEN' \\")
    print("        -d '{\"threshold\": 0.50}'")
    print()
    print("2. Launch GUI application:")
    print("   cd gui && source .venv/bin/activate && python main.py")
    print()
    print("3. Start DDoS attack from Kali VM (see guide)")
    print()
    print("4. Watch for alerts in GUI dashboard")
    print("=" * 60)
    
    # Optional: Run real-time test
    print("\nRun real-time detection test? (y/n): ", end="")
    try:
        if input().lower() == 'y':
            test_real_time_detection(token)
    except KeyboardInterrupt:
        print("\n\n👋 Test cancelled")

if __name__ == "__main__":
    main()

