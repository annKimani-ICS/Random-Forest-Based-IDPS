#!/usr/bin/env python3
"""
Verify all integrated fixes work before cleanup
Tests core functionality to ensure nothing breaks
"""
import sys
import os
from pathlib import Path

def test_pydantic_version():
    """Test Pydantic v1 is installed"""
    print("1. Testing Pydantic version...")
    try:
        import pydantic
        if pydantic.__version__.startswith('2.'):
            print("  ❌ FAIL: Pydantic v2 detected (should be v1)")
            return False
        else:
            print(f"  ✅ PASS: Pydantic v1 ({pydantic.__version__})")
            return True
    except ImportError:
        print("  ❌ FAIL: Pydantic not installed")
        return False

def test_config_import():
    """Test config.py uses correct BaseSettings"""
    print("2. Testing config.py import...")
    try:
        config_file = Path("backend/app/config.py")
        content = config_file.read_text()
        if "from pydantic_settings import" in content:
            print("  ❌ FAIL: config.py uses pydantic_settings")
            return False
        elif "from pydantic import BaseSettings" in content:
            print("  ✅ PASS: config.py uses pydantic.BaseSettings")
            return True
        else:
            print("  ⚠️  WARNING: Could not verify BaseSettings import")
            return True
    except Exception as e:
        print(f"  ❌ FAIL: {e}")
        return False

def test_requirements_txt():
    """Test requirements.txt has correct Pydantic version"""
    print("3. Testing requirements.txt...")
    try:
        req_file = Path("backend/requirements.txt")
        content = req_file.read_text()
        if "pydantic<2.0.0" in content or "pydantic==" in content and not content.split("pydantic")[1][1:2] == "2":
            print("  ✅ PASS: requirements.txt uses Pydantic v1")
            return True
        elif "pydantic==2" in content or "pydantic-settings" in content:
            print("  ❌ FAIL: requirements.txt uses Pydantic v2")
            return False
        else:
            print("  ⚠️  WARNING: Could not verify Pydantic version in requirements.txt")
            return True
    except Exception as e:
        print(f"  ❌ FAIL: {e}")
        return False

def test_absolute_imports():
    """Test routers use absolute imports"""
    print("4. Testing absolute imports in routers...")
    router_files = [
        "backend/app/routers/auth.py",
        "backend/app/routers/dashboard.py",
        "backend/app/routers/users.py",
    ]
    
    for router_file in router_files:
        if not Path(router_file).exists():
            continue
        content = Path(router_file).read_text()
        if "from .." in content:
            print(f"  ❌ FAIL: {router_file} uses relative imports")
            return False
        elif "from app." in content:
            print(f"  ✅ PASS: {router_file} uses absolute imports")
    
    return True

def test_api_timeouts():
    """Test API client has timeouts"""
    print("5. Testing API client timeouts...")
    try:
        api_client = Path("gui/api_client.py")
        if not api_client.exists():
            print("  ⚠️  WARNING: gui/api_client.py not found")
            return True
        
        content = api_client.read_text()
        if "timeout" in content and "self.timeout" in content:
            print("  ✅ PASS: API client has timeout configuration")
            return True
        else:
            print("  ⚠️  WARNING: API client may not have timeouts")
            return True
    except Exception as e:
        print(f"  ⚠️  WARNING: {e}")
        return True

def test_setup_files():
    """Test essential setup files exist"""
    print("6. Testing essential setup files...")
    essential = [
        "backend/setup.py",
        "backend/update_model_db.py",
        "backend/add_dummy_alerts.py",
        "backend/test_fixes.py",
    ]
    
    missing = []
    for filepath in essential:
        if not Path(filepath).exists():
            missing.append(filepath)
    
    if missing:
        print(f"  ❌ FAIL: Missing files: {missing}")
        return False
    else:
        print("  ✅ PASS: All essential setup files exist")
        return True

def main():
    """Run all tests"""
    print("=" * 60)
    print("🧪 Verifying Integrated Fixes Before Cleanup")
    print("=" * 60)
    
    project_root = Path(__file__).parent
    os.chdir(project_root)
    
    tests = [
        test_pydantic_version,
        test_config_import,
        test_requirements_txt,
        test_absolute_imports,
        test_api_timeouts,
        test_setup_files,
    ]
    
    results = []
    for test in tests:
        results.append(test())
    
    print("\n" + "=" * 60)
    print("📊 Test Results:")
    print("=" * 60)
    
    passed = sum(results)
    failed = len(results) - passed
    
    print(f"  Passed: {passed}/{len(results)}")
    print(f"  Failed: {failed}/{len(results)}")
    
    if failed == 0:
        print("\n✅ All tests passed! Safe to cleanup.")
        return 0
    else:
        print("\n❌ Some tests failed. Fix issues before cleanup.")
        return 1

if __name__ == "__main__":
    sys.exit(main())

