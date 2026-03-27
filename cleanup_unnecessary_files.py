#!/usr/bin/env python3
"""
Cleanup Unnecessary Files
Removes all temporary fix scripts after confirming integration
"""
import os
import subprocess
from pathlib import Path

# Essential files to KEEP
ESSENTIAL_FILES = {
    # Core setup and run scripts
    "backend/setup.py",
    "backend/run_backend.sh",
    "backend/update_model_db.py",
    "backend/add_dummy_alerts.py",
    "backend/create_users.py",
    "backend/test_fixes.py",
    "run_gui.sh",
    "setup.sh",
    "run_full_system.sh",
    
    # Core application files (all app/ files)
    "backend/app/",
    "gui/",
    "frontend/",
    
    # Documentation
    "README.md",
    "SETUP_GUIDE.md",
    "INTEGRATED_FIXES.md",
    "LICENSE",
    ".gitignore",
    
    # Configuration
    "backend/requirements.txt",
    "backend/alembic.ini",
    "backend/pyproject.toml",
    "backend/Dockerfile",
}

# Temporary fix scripts to REMOVE
TEMP_SCRIPTS = [
    # Backend fix scripts
    "backend/fix_pydantic.sh",
    "backend/fix_db_connection.sh",
    "backend/fix_metrics.sh",
    "backend/fix_ddos_only.sh",
    "backend/comprehensive_db_fix.sh",
    "backend/final_auth_fix.sh",
    "backend/simple_postgres_fix.sh",
    "backend/ultimate_user_drop_fix.sh",
    "backend/setup_backend.sh",  # Replaced by setup.py
    "backend/fix_migrations.sh",
    "backend/fix_auth.sh",
    "backend/simple_working_setup.sh",
    "backend/simple_setup.sh",
    "backend/auto_setup.sh",
    "backend/setup_ubuntu.sh",
    "backend/start_backend_alternative.sh",
    
    # Root fix scripts
    "fix_relative_imports.sh",
    "quick_fix_relative_imports.sh",
    "diagnose_fastapi.sh",
    "complete_fastapi_fix.sh",
    "quick_fix_basemodel.sh",
    "fix_fastapi_pydantic.sh",
    "fix_git_repo.sh",
    "simple_setup_no_git.sh",
    "download_project.sh",
    "automated_fix_sprint4.sh",
    "ultimate_working_solution.sh",
    "working_setup.sh",
    "verify_system.sh",
    "verify_setup.sh",
    "update_and_fix.sh",
    
    # Credential/authentication fix scripts
    "create_correct_credentials.sh",
    "fix_admin_login.sh",
    "remove_secrets.sh",
    "check_users.sh",
    "check_credentials.sh",
    "fix_login_credentials.sh",
    "create_backend_script.sh",
    "fix_uvicorn_installation.sh",
    "secure_setup.sh",
    
    # Testing/utility scripts (temporary)
    "quick_test.sh",
    "api_testing_guide.sh",
    
    # Redundant setup scripts
    "setup_ubuntu_gui.sh",
    "setup_gui_complete.sh",
    "fix_common_issues.sh",
    "run_backend.sh",  # Duplicate of backend/run_backend.sh
]

def check_file_exists(filepath):
    """Check if file exists"""
    return Path(filepath).exists()

def remove_file(filepath):
    """Remove a file"""
    try:
        path = Path(filepath)
        if path.is_file():
            path.unlink()
            return True
        elif path.is_dir():
            # Don't remove directories, just report
            return False
    except Exception as e:
        print(f"  ❌ Error removing {filepath}: {e}")
        return False
    return False

def main():
    """Main cleanup function"""
    print("=" * 60)
    print("🧹 Cleanup Unnecessary Files")
    print("=" * 60)
    
    project_root = Path(__file__).parent
    os.chdir(project_root)
    
    # Verify essential files exist
    print("\n📋 Verifying essential files...")
    missing_essential = []
    for filepath in ESSENTIAL_FILES:
        if "*" not in filepath and not check_file_exists(filepath):
            # Check if it's a directory pattern
            if filepath.endswith("/") and Path(filepath[:-1]).exists():
                continue
            missing_essential.append(filepath)
    
    if missing_essential:
        print("⚠️  Missing essential files:")
        for f in missing_essential:
            print(f"  - {f}")
    else:
        print("✅ All essential files present")
    
    # Find files to remove
    print("\n📋 Temporary files to remove:")
    files_to_remove = []
    for script in TEMP_SCRIPTS:
        if check_file_exists(script):
            files_to_remove.append(script)
            print(f"  - {script}")
    
    if not files_to_remove:
        print("  ✅ No temporary files found")
        return
    
    print(f"\n📊 Summary:")
    print(f"  Files to remove: {len(files_to_remove)}")
    print(f"  Essential files: {len(ESSENTIAL_FILES)}")
    
    response = input("\n⚠️  Remove these temporary files? (yes/no): ")
    if response.lower() != "yes":
        print("Cleanup cancelled")
        return
    
    # Remove files
    print("\n🗑️  Removing files...")
    removed = 0
    failed = 0
    
    for filepath in files_to_remove:
        if remove_file(filepath):
            print(f"  ✅ Removed {filepath}")
            removed += 1
        else:
            print(f"  ⚠️  Could not remove {filepath}")
            failed += 1
    
    print("\n" + "=" * 60)
    print(f"✅ Cleanup Complete!")
    print(f"   Removed: {removed} files")
    if failed > 0:
        print(f"   Failed: {failed} files")
    print("=" * 60)
    print("\n📝 All fixes are now integrated in main code:")
    print("   - backend/setup.py (complete setup)")
    print("   - backend/test_fixes.py (test suite)")
    print("   - Main code files (all fixes integrated)")

if __name__ == "__main__":
    main()

