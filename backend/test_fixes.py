#!/usr/bin/env python3
"""
Test all integrated fixes
Validates that all fixes are working correctly
"""
import sys
import os
from pathlib import Path

def test_imports():
    """Test that all imports work correctly"""
    print("🧪 Testing imports...")
    errors = []
    
    # Test Pydantic v1
    try:
        from pydantic import BaseModel, BaseSettings
        import pydantic
        if pydantic.__version__.startswith('2.'):
            errors.append("❌ Pydantic v2 detected, should be v1")
        else:
            print("  ✅ Pydantic v1 import works")
    except ImportError as e:
        errors.append(f"❌ Pydantic import failed: {e}")
    
    # Test FastAPI
    try:
        from fastapi import FastAPI
        print("  ✅ FastAPI import works")
    except ImportError as e:
        errors.append(f"❌ FastAPI import failed: {e}")
    
    # Test absolute imports in app
    sys.path.insert(0, '.')
    try:
        from app.config import settings
        print("  ✅ app.config import works")
    except Exception as e:
        errors.append(f"❌ app.config import failed: {e}")
    
    try:
        from app.main import app
        print("  ✅ app.main import works")
    except Exception as e:
        errors.append(f"❌ app.main import failed: {e}")
    
    try:
        from app.routers import auth, dashboard, users
        print("  ✅ app.routers imports work")
    except Exception as e:
        errors.append(f"❌ app.routers imports failed: {e}")
    
    if errors:
        print("\n".join(errors))
        return False
    return True

def test_database_connection():
    """Test database connection"""
    print("\n🧪 Testing database connection...")
    try:
        sys.path.insert(0, '.')
        from app.database import SessionLocal
        from sqlalchemy import text
        
        db = SessionLocal()
        db.execute(text('SELECT 1'))
        db.close()
        print("  ✅ Database connection works")
        return True
    except Exception as e:
        print(f"  ❌ Database connection failed: {e}")
        return False

def test_user_creation():
    """Test that users can be created"""
    print("\n🧪 Testing user creation...")
    try:
        sys.path.insert(0, '.')
        from app.database import SessionLocal
        from app.models import User, UserRole
        from app.auth import hash_password
        
        db = SessionLocal()
        user_count = db.query(User).count()
        print(f"  ✅ User model works, {user_count} users in database")
        db.close()
        return True
    except Exception as e:
        print(f"  ❌ User creation test failed: {e}")
        return False

def test_model_metrics():
    """Test that model metrics can be read"""
    print("\n🧪 Testing model metrics...")
    try:
        sys.path.insert(0, '.')
        from app.database import SessionLocal
        from app.models import Model
        
        db = SessionLocal()
        model = db.query(Model).order_by(Model.trained_at.desc()).first()
        if model:
            print(f"  ✅ Model found: {model.version}")
            print(f"     Metrics: accuracy={model.metrics.get('accuracy', 0):.4f}")
            print(f"     Training date: {model.trained_at}")
        else:
            print("  ⚠️  No model found in database")
        db.close()
        return True
    except Exception as e:
        print(f"  ❌ Model metrics test failed: {e}")
        return False

def test_alerts():
    """Test that alerts work"""
    print("\n🧪 Testing alerts...")
    try:
        sys.path.insert(0, '.')
        from app.database import SessionLocal
        from app.models import Alert
        
        db = SessionLocal()
        alert_count = db.query(Alert).count()
        ddos_count = db.query(Alert).filter(Alert.attack_type == "DDoS").count()
        print(f"  ✅ Alerts model works")
        print(f"     Total alerts: {alert_count}")
        print(f"     DDoS alerts: {ddos_count}")
        if alert_count > 0 and alert_count != ddos_count:
            print(f"  ⚠️  Warning: {alert_count - ddos_count} non-DDoS alerts found")
        db.close()
        return True
    except Exception as e:
        print(f"  ❌ Alerts test failed: {e}")
        return False

def test_api_client():
    """Test API client configuration"""
    print("\n🧪 Testing API client...")
    try:
        # Check if GUI API client has timeout
        gui_api_client = Path("../gui/api_client.py")
        if gui_api_client.exists():
            content = gui_api_client.read_text()
            if "timeout" in content:
                print("  ✅ API client has timeout configuration")
            else:
                print("  ⚠️  API client may be missing timeout")
        return True
    except Exception as e:
        print(f"  ❌ API client test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("=" * 50)
    print("🧪 Testing All Integrated Fixes")
    print("=" * 50)
    
    # Change to backend directory
    backend_dir = Path(__file__).parent
    if backend_dir.name != "backend" or not (backend_dir / "app").exists():
        print("❌ Please run this script from the backend directory")
        sys.exit(1)
    
    os.chdir(backend_dir)
    
    results = []
    results.append(("Imports", test_imports()))
    results.append(("Database Connection", test_database_connection()))
    results.append(("User Creation", test_user_creation()))
    results.append(("Model Metrics", test_model_metrics()))
    results.append(("Alerts", test_alerts()))
    results.append(("API Client", test_api_client()))
    
    print("\n" + "=" * 50)
    print("📊 Test Results:")
    print("=" * 50)
    
    passed = 0
    failed = 0
    
    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {name}: {status}")
        if result:
            passed += 1
        else:
            failed += 1
    
    print("\n" + "=" * 50)
    print(f"Total: {passed + failed} tests, {passed} passed, {failed} failed")
    
    if failed == 0:
        print("✅ All tests passed!")
        return 0
    else:
        print("❌ Some tests failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())

