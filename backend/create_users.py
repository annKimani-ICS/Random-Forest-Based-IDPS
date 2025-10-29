#!/usr/bin/env python3
"""Create default Admin and Analyst users for testing."""
import sys
import os

sys.path.insert(0, os.getcwd())

from app.database import SessionLocal, engine, Base
from app.models import User, UserRole
from app.auth import hash_password

db = SessionLocal()

def ensure_user(email, password, role):
    u = db.query(User).filter(User.email == email).first()
    if not u:
        u = User(email=email, password_hash=hash_password(password), role=role)
        db.add(u)
    else:
        u.password_hash = hash_password(password)
        u.role = role
        u.is_active = True
    db.commit()
    print(f"✅ Ensured {email} as {role.value}")

# Ensure tables exist
Base.metadata.create_all(bind=engine)

# Create users
ensure_user("admin@ids-idps.com", "AdminSecure2024!", UserRole.ADMIN)
ensure_user("analyst@ids-idps.com", "AnalystSecure2024!", UserRole.ANALYST)

# Verify
print("\n📋 Users in database:")
for u in db.query(User).all():
    print(f"  - {u.email} ({u.role.value})")

db.close()

