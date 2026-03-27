# Fix Authentication Failure - Quick Guide

## Quick Fix on Ubuntu VM

### Step 1: Run Diagnostic Tool

```bash
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
python3 diagnose_auth.py
```

This will:
- Check database connection
- List all users
- Test password verification
- Let you reset passwords

### Step 2: Quick Password Reset

**Option A: Using existing script**
```bash
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
python3 check_and_fix_admin_password.py reset
```

This will:
- Generate a new secure password
- Display credentials for you to save

**Option B: Set custom password**
```bash
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
python3 check_and_fix_admin_password.py reset "YourNewPassword123"
```

**Option C: Interactive mode**
```bash
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
python3 check_and_fix_admin_password.py
# Then select option 2 or 3
```

### Step 3: Test Login

**Test via script:**
```bash
python3 check_and_fix_admin_password.py test admin@ids.local "YourPassword"
```

**Test via API:**
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@ids.local", "password": "YourPassword"}'
```

## Common Issues

### Issue 1: User Doesn't Exist

**Fix: Create admin user**
```bash
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
python3 << 'EOF'
from app.database import SessionLocal
from app.models import User, UserRole
from app.auth import hash_password

db = SessionLocal()
admin = User(
    email="admin@ids.local",
    password_hash=hash_password("admin123"),
    role=UserRole.ADMIN,
    is_active=True
)
db.add(admin)
db.commit()
print("✅ Admin user created!")
print("Email: admin@ids.local")
print("Password: admin123")
db.close()
EOF
```

### Issue 2: Password Hash Issue

**Fix: Reset password**
```bash
python3 check_and_fix_admin_password.py reset "newpassword123"
```

### Issue 3: Account Locked

**Fix: Unlock account**
```bash
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate
python3 << 'EOF'
from app.database import SessionLocal
from app.models import User

db = SessionLocal()
user = db.query(User).filter(User.email == "admin@ids.local").first()
if user:
    user.failed_login_attempts = 0
    user.locked_until = None
    db.commit()
    print("✅ Account unlocked!")
db.close()
EOF
```

### Issue 4: Wrong Email Format

**Check available emails:**
```bash
python3 check_and_fix_admin_password.py check
```

Common email formats:
- `admin@ids.local`
- `admin@ids-idps.com`
- `admin@ids.localhost`

### Issue 5: Database Connection Issues

**Fix: Verify database**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U ids_user -d ids_idps_db -h localhost -c "SELECT 1"

# If connection fails, check .env file
cat backend/.env | grep DATABASE_URL
```

## Verify Setup

After fixing, verify everything works:

```bash
# 1. Check users exist
python3 check_and_fix_admin_password.py check

# 2. Test login
python3 check_and_fix_admin_password.py test admin@ids.local "YourPassword"

# 3. Test API
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@ids.local", "password": "YourPassword"}'
```

## Quick Fix Script

Save this as `quick_fix_auth.sh`:

```bash
#!/bin/bash
cd ~/Random-Forest-Based-IDPS/backend
source .venv/bin/activate

echo "🔧 Quick Auth Fix"
echo "================="

# Check if admin exists
python3 << 'EOF'
from app.database import SessionLocal
from app.models import User, UserRole
from app.auth import hash_password, verify_password

db = SessionLocal()
admin = db.query(User).filter(User.email == "admin@ids.local").first()

if not admin:
    print("Creating admin user...")
    admin = User(
        email="admin@ids.local",
        password_hash=hash_password("admin123"),
        role=UserRole.ADMIN,
        is_active=True
    )
    db.add(admin)
    db.commit()
    print("✅ Admin created!")
    print("Email: admin@ids.local")
    print("Password: admin123")
else:
    print("Resetting admin password...")
    admin.password_hash = hash_password("admin123")
    admin.is_active = True
    admin.failed_login_attempts = 0
    admin.locked_until = None
    db.commit()
    print("✅ Password reset!")
    print("Email: admin@ids.local")
    print("Password: admin123")

db.close()
EOF
```

Then run:
```bash
chmod +x quick_fix_auth.sh
./quick_fix_auth.sh
```

## Next Steps After Fix

Once authentication works:

1. **Test login via API**
2. **Start monitoring** (from previous steps)
3. **Launch DDoS attacks** from Kali VM
4. **Watch alerts** in GUI

---

**Still having issues?** Run the full diagnostic:
```bash
python3 backend/diagnose_auth.py
```

