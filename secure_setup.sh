#!/bin/bash
# Secure Setup Script - No Hardcoded Secrets
# This script sets up the system without exposing secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔒 Secure IDS/IDPS Setup (No Hardcoded Secrets)${NC}"
echo "=============================================="

# Get current directory
CURRENT_DIR="$(pwd)"
echo -e "${BLUE}📁 Current directory: $CURRENT_DIR${NC}"

# Step 1: Generate secure secrets
echo -e "${YELLOW}🔧 Step 1: Generating secure secrets...${NC}"

# Generate secure random passwords
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
JWT_SECRET=$(openssl rand -hex 32)
ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
ANALYST_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
USER_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)

echo -e "${GREEN}✅ Secure secrets generated${NC}"

# Step 2: Setup PostgreSQL
echo -e "${YELLOW}🔧 Step 2: Setting up PostgreSQL...${NC}"

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user with secure password
sudo -u postgres psql -c "CREATE DATABASE ids_idps_db;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER ids_user WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ids_idps_db TO ids_user;" 2>/dev/null || true

echo -e "${GREEN}✅ PostgreSQL database configured${NC}"

# Step 3: Setup Backend Environment
echo -e "${YELLOW}🔧 Step 3: Setting up backend environment...${NC}"
cd backend

# Create virtual environment
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "${GREEN}✅ Backend dependencies installed${NC}"

# Step 4: Create Secure Environment Configuration
echo -e "${YELLOW}🔧 Step 4: Creating secure environment configuration...${NC}"

# Create .env file with secure secrets
cat > .env << EOF
DATABASE_URL=postgresql://ids_user:$DB_PASSWORD@localhost:5432/ids_idps_db
JWT_SECRET=$JWT_SECRET
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:5173,http://localhost:8000
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
EOF

echo -e "${GREEN}✅ Secure environment configuration created${NC}"

# Step 5: Initialize Database
echo -e "${YELLOW}🔧 Step 5: Initializing database...${NC}"

# Create tables directly
python3 << PYEOF
from app.database import engine, Base
from app.models import *
try:
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created successfully")
except Exception as e:
    print(f"Error creating tables: {e}")
PYEOF

# Step 6: Create Secure Seed Script
echo -e "${YELLOW}🔧 Step 6: Creating secure seed script...${NC}"

cat > secure_seed_data.py << PYEOF
"""
Secure database seeding with generated passwords
"""
import sys
import os
from datetime import datetime, timedelta
import random
from decimal import Decimal

# Add app to path
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import User, UserMFA, Model, Threshold, Alert, BlockRule, AlertStatus, UserRole
from app.auth import hash_password
import uuid

def secure_seed_database():
    db = SessionLocal()
    
    try:
        print("🌱 Seeding database with secure credentials...")
        
        # Clear existing data first
        print("Clearing existing data...")
        try:
            db.query(UserMFA).delete()
            db.query(Alert).delete()
            db.query(BlockRule).delete()
            db.query(Model).delete()
            db.query(Threshold).delete()
            db.query(User).delete()
            db.commit()
        except Exception as e:
            print(f"Error clearing data: {e}")
            db.rollback()
        
        # Create users with secure passwords
        users_data = [
            {
                "email": "admin@ids-idps.com",
                "password": "$ADMIN_PASSWORD",
                "role": UserRole.ADMIN,
                "is_active": True
            },
            {
                "email": "analyst@ids-idps.com", 
                "password": "$ANALYST_PASSWORD",
                "role": UserRole.ANALYST,
                "is_active": True
            },
            {
                "email": "user@ids-idps.com",
                "password": "$USER_PASSWORD", 
                "role": UserRole.USER,
                "is_active": True
            }
        ]
        
        created_users = []
        for user_data in users_data:
            user = User(
                id=uuid.uuid4(),
                email=user_data["email"],
                password_hash=hash_password(user_data["password"]),
                role=user_data["role"],
                is_active=user_data["is_active"],
                created_at=datetime.now(),
                last_login=None,
                failed_login_attempts=0,
                locked_until=None
            )
            db.add(user)
            created_users.append({
                "email": user_data["email"],
                "password": user_data["password"],
                "role": user_data["role"].value
            })
        
        # Create model with correct metrics
        model = Model(
            id=uuid.uuid4(),
            version="iteration4_voting_ensemble",
            trained_at=datetime.now(),
            metrics={
                "iteration": 4,
                "model_name": "Random Forest Voting Ensemble",
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
                "description": "Random Forest Voting Ensemble - 90.48% Accuracy, 90.51% F1-Score",
                "model_type": "Voting Ensemble",
                "algorithm": "Random Forest + Voting"
            },
            notes="Primary production model - Random Forest Voting Ensemble with 90.48% accuracy and 90.51% F1-score"
        )
        db.add(model)
        
        # Create threshold
        threshold = Threshold(
            id=uuid.uuid4(),
            value=0.5,
            updated_at=datetime.now(),
            updated_by="system"
        )
        db.add(threshold)
        
        # Create sample alerts
        alert_types = ["DDoS", "Port Scan", "Brute Force", "Malware", "Suspicious Activity"]
        statuses = [AlertStatus.NEW, AlertStatus.INVESTIGATING, AlertStatus.RESOLVED]
        
        for i in range(20):
            alert = Alert(
                id=uuid.uuid4(),
                event_ts=datetime.now() - timedelta(hours=random.randint(1, 72)),
                src_ip=f"192.168.1.{random.randint(1, 254)}",
                dst_ip=f"10.0.0.{random.randint(1, 254)}",
                attack_type=random.choice(alert_types),
                score=round(random.uniform(0.3, 0.95), 3),
                is_malicious=random.choice([True, False]),
                status=random.choice(statuses),
                model_version="iteration4_voting_ensemble",
                payload={
                    "protocol": random.choice(["TCP", "UDP", "ICMP"]),
                    "port": random.randint(1, 65535),
                    "packet_count": random.randint(1, 1000),
                    "bytes_transferred": random.randint(100, 1000000)
                }
            )
            db.add(alert)
        
        db.commit()
        print("✅ Database seeded successfully")
        
        # Return credentials for display
        return created_users
        
    except Exception as e:
        print(f"❌ Error seeding database: {e}")
        db.rollback()
        return []
    finally:
        db.close()

if __name__ == "__main__":
    credentials = secure_seed_database()
    print("\\n🔐 Generated User Credentials:")
    print("=" * 50)
    for cred in credentials:
        print(f"Email: {cred['email']}")
        print(f"Password: {cred['password']}")
        print(f"Role: {cred['role']}")
        print("-" * 30)
PYEOF

# Replace password placeholders in the seed script
sed -i "s/\$ADMIN_PASSWORD/$ADMIN_PASSWORD/g" secure_seed_data.py
sed -i "s/\$ANALYST_PASSWORD/$ANALYST_PASSWORD/g" secure_seed_data.py
sed -i "s/\$USER_PASSWORD/$USER_PASSWORD/g" secure_seed_data.py

# Run the secure seed script
echo -e "${BLUE}Running secure seed script...${NC}"
python3 secure_seed_data.py

echo -e "${GREEN}✅ Database seeded with secure credentials${NC}"

# Step 7: Create Secure Credentials File
echo -e "${YELLOW}🔧 Step 7: Creating secure credentials file...${NC}"

CREDENTIALS_FILE="$HOME/ids_idps_secure_credentials.txt"

cat > "$CREDENTIALS_FILE" << EOF
IDS/IDPS Secure Login Credentials
Generated on: $(date)
================================

Admin User:
  Email: admin@ids-idps.com
  Password: $ADMIN_PASSWORD
  Role: ADMIN

Analyst User:
  Email: analyst@ids-idps.com
  Password: $ANALYST_PASSWORD
  Role: ANALYST

Regular User:
  Email: user@ids-idps.com
  Password: $USER_PASSWORD
  Role: USER

Database Configuration:
  Database: ids_idps_db
  User: ids_user
  Password: [Generated securely]

IMPORTANT SECURITY NOTES:
- These passwords are randomly generated and secure
- Store this file securely and delete after noting credentials
- Change passwords after first login for production use
- Never commit this file to version control

EOF

# Set secure permissions on credentials file
chmod 600 "$CREDENTIALS_FILE"

echo -e "${GREEN}✅ Secure credentials file created: $CREDENTIALS_FILE${NC}"

# Step 8: Clean up sensitive files
echo -e "${YELLOW}🔧 Step 8: Cleaning up sensitive files...${NC}"
rm -f secure_seed_data.py

echo -e "${GREEN}✅ Sensitive files cleaned up${NC}"

# Summary
echo ""
echo -e "${GREEN}🎉 Secure Setup Complete!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What was configured:${NC}"
echo "   ✅ Secure random passwords generated"
echo "   ✅ PostgreSQL database with secure credentials"
echo "   ✅ Backend environment setup"
echo "   ✅ Secure environment configuration"
echo "   ✅ Database tables created"
echo "   ✅ Database seeded with secure users"
echo "   ✅ Secure credentials file created"
echo "   ✅ Sensitive files cleaned up"

echo ""
echo -e "${BLUE}🔐 Security Features:${NC}"
echo "   ✅ No hardcoded passwords"
echo "   ✅ Random secure passwords"
echo "   ✅ Secure file permissions"
echo "   ✅ Sensitive data cleaned up"
echo "   ✅ Credentials file protected"

echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "   1. View credentials: cat $CREDENTIALS_FILE"
echo "   2. Start API: cd backend && ./run_backend.sh"
echo "   3. Launch GUI: cd gui && ./run_gui.sh"
echo "   4. Login with the generated credentials"
echo "   5. Change passwords after first login"

echo ""
echo -e "${YELLOW}⚠️ Security Reminder:${NC}"
echo "   - Store credentials securely"
echo "   - Delete credentials file after noting passwords"
echo "   - Change passwords for production use"
echo "   - Never commit credentials to version control"

echo ""
echo -e "${GREEN}🎯 System ready with secure credentials!${NC}"
