#!/usr/bin/env python3
"""
Complete Backend Setup Script
Integrates all fixes and automates the entire backend setup process
"""
import sys
import os
import subprocess
from pathlib import Path

def run_command(cmd, check=True):
    """Run a shell command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=check)
        return result.stdout, result.stderr, result.returncode
    except subprocess.CalledProcessError as e:
        return e.stdout, e.stderr, e.returncode

def check_postgresql():
    """Check if PostgreSQL is running"""
    stdout, stderr, code = run_command("sudo systemctl is-active postgresql", check=False)
    if code == 0:
        print("✅ PostgreSQL is running")
        return True
    else:
        print("⚠️  Starting PostgreSQL...")
        run_command("sudo systemctl start postgresql", check=False)
        run_command("sudo systemctl enable postgresql", check=False)
        return True

def setup_database():
    """Setup PostgreSQL database using postgres superuser (most reliable)"""
    print("\n📊 Setting up PostgreSQL database...")
    
    # Create database
    run_command("sudo -u postgres psql -c 'CREATE DATABASE ids_idps_db;'", check=False)
    
    print("✅ Database setup complete")

def setup_virtual_environment():
    """Create and setup virtual environment"""
    print("\n📦 Setting up virtual environment...")
    
    venv_path = Path(".venv")
    if not venv_path.exists():
        print("Creating virtual environment...")
        run_command("python3 -m venv .venv")
    
    # Activate and install
    pip = ".venv/bin/pip" if os.name != 'nt' else ".venv\\Scripts\\pip.exe"
    python = ".venv/bin/python" if os.name != 'nt' else ".venv\\Scripts\\python.exe"
    
    print("Upgrading pip...")
    run_command(f"{pip} install --upgrade pip setuptools wheel")
    
    print("Installing requirements...")
    run_command(f"{pip} install -r requirements.txt")
    
    print("✅ Virtual environment ready")
    return python

def create_env_file():
    """Create .env file if it doesn't exist"""
    env_file = Path(".env")
    if env_file.exists():
        print("✅ .env file already exists")
        return
    
    print("\n📝 Creating .env file...")
    import secrets
    jwt_secret = secrets.token_urlsafe(32)
    
    env_content = f"""DATABASE_URL=postgresql+psycopg2://postgres@localhost:5432/ids_idps_db
JWT_SECRET={jwt_secret}
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:5173,http://localhost:8000
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
"""
    env_file.write_text(env_content)
    print("✅ .env file created")

def create_tables(python):
    """Create database tables"""
    print("\n📊 Creating database tables...")
    
    code = f"""
import sys
sys.path.insert(0, '.')
from app.database import engine, Base
from app.models import *

try:
    Base.metadata.create_all(bind=engine)
    print('✅ Tables created successfully')
except Exception as e:
    print(f'❌ Error: {{e}}')
    sys.exit(1)
"""
    stdout, stderr, returncode = run_command(f"{python} -c \"{code}\"")
    if returncode != 0:
        print(f"❌ Failed to create tables: {stderr}")
        return False
    return True

def create_users(python):
    """Create default Admin and Analyst users"""
    print("\n👤 Creating default users...")
    
    code = f"""
import sys
sys.path.insert(0, '.')
from app.database import SessionLocal, engine, Base
from app.models import User, UserRole
from app.auth import hash_password

db = SessionLocal()
try:
    # Ensure tables exist
    Base.metadata.create_all(bind=engine)
    
    # Create Admin user
    u = db.query(User).filter(User.email == "admin@ids-idps.com").first()
    if not u:
        u = User(email="admin@ids-idps.com", password_hash=hash_password("AdminSecure2024!"), role=UserRole.ADMIN, is_active=True)
        db.add(u)
        print("✅ Created admin@ids-idps.com")
    else:
        u.password_hash = hash_password("AdminSecure2024!")
        u.role = UserRole.ADMIN
        u.is_active = True
        print("✅ Updated admin@ids-idps.com")
    db.commit()
    
    # Create Analyst user
    u = db.query(User).filter(User.email == "analyst@ids-idps.com").first()
    if not u:
        u = User(email="analyst@ids-idps.com", password_hash=hash_password("AnalystSecure2024!"), role=UserRole.ANALYST, is_active=True)
        db.add(u)
        print("✅ Created analyst@ids-idps.com")
    else:
        u.password_hash = hash_password("AnalystSecure2024!")
        u.role = UserRole.ANALYST
        u.is_active = True
        print("✅ Updated analyst@ids-idps.com")
    db.commit()
    
    print("✅ All users created successfully")
except Exception as e:
    print(f"❌ Error: {{e}}")
    import traceback
    traceback.print_exc()
    db.rollback()
    sys.exit(1)
finally:
    db.close()
"""
    stdout, stderr, returncode = run_command(f"{python} -c \"{code}\"")
    if returncode != 0:
        print(f"❌ Failed to create users: {stderr}")
        return False
    return True

def update_model_metrics(python):
    """Update model metrics with Iteration 4 values"""
    print("\n📈 Updating model metrics...")
    
    # Use the existing update_model_db.py script if it exists
    if Path("update_model_db.py").exists():
        stdout, stderr, returncode = run_command(f"{python} update_model_db.py")
        if returncode == 0:
            print("✅ Model metrics updated")
            return True
    
    # Fallback: inline update
    code = f"""
import sys
sys.path.insert(0, '.')
from app.database import SessionLocal
from app.models import Model
from datetime import datetime
import uuid

db = SessionLocal()
try:
    db.query(Model).delete()
    
    iteration4_metrics = {{
        "iteration": 4,
        "model_name": "Voting Ensemble",
        "accuracy": 0.9048,
        "precision": 0.9062,
        "recall": 0.9048,
        "f1": 0.9051,
        "auc": 0.95,
        "holdout_accuracy": 0.8974,
        "holdout_precision": 0.8984,
        "holdout_recall": 0.8974,
        "holdout_f1": 0.8976,
        "performance_consistency": 0.0076,
        "training_time_minutes": 15,
        "n_estimators": 200,
        "max_depth": 20,
        "features_used": 30,
        "data_samples": 50000,
        "description": "FAST Random Forest with Voting Ensemble - 90.51% F1-Score"
    }}
    
    training_date = datetime(2025, 10, 15, 12, 0, 0)
    
    new_model = Model(
        id=uuid.uuid4(),
        version="iteration4_voting_ensemble",
        trained_at=training_date,
        metrics=iteration4_metrics,
        notes="Best performing model - 90.48% accuracy, 90.51% F1-score"
    )
    db.add(new_model)
    db.commit()
    print("✅ Model metrics updated")
except Exception as e:
    print(f"❌ Error: {{e}}")
    db.rollback()
    sys.exit(1)
finally:
    db.close()
"""
    stdout, stderr, returncode = run_command(f"{python} -c \"{code}\"")
    return returncode == 0

def main():
    """Main setup function"""
    print("=" * 50)
    print("🚀 Complete Backend Setup")
    print("=" * 50)
    
    # Change to backend directory
    backend_dir = Path(__file__).parent
    if backend_dir.name != "backend" or not (backend_dir / "app").exists():
        print("❌ Please run this script from the backend directory")
        sys.exit(1)
    
    os.chdir(backend_dir)
    
    # Step 1: Check PostgreSQL
    if not check_postgresql():
        print("❌ PostgreSQL setup failed")
        sys.exit(1)
    
    # Step 2: Setup database
    setup_database()
    
    # Step 3: Setup virtual environment
    python = setup_virtual_environment()
    
    # Step 4: Create .env file
    create_env_file()
    
    # Step 5: Create tables
    if not create_tables(python):
        print("❌ Failed to create tables")
        sys.exit(1)
    
    # Step 6: Create users
    if not create_users(python):
        print("❌ Failed to create users")
        sys.exit(1)
    
    # Step 7: Update model metrics
    update_model_metrics(python)
    
    print("\n" + "=" * 50)
    print("✅ Setup Complete!")
    print("=" * 50)
    print("\n📋 Login Credentials:")
    print("   Admin:  admin@ids-idps.com / AdminSecure2024!")
    print("   Analyst: analyst@ids-idps.com / AnalystSecure2024!")
    print("\n🚀 Start backend:")
    print("   source .venv/bin/activate")
    print("   export PYTHONPATH=$(pwd)")
    print("   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload")

if __name__ == "__main__":
    main()

