"""
Seed database with initial data for demo
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

def seed_database():
    db = SessionLocal()
    
    try:
        print("🌱 Seeding database...")
        
        # 1. Create users
        print("Creating users...")
        admin_user = User(
            email="admin@ids-idps.com",
            password_hash=hash_password("Admin123!"),
            role=UserRole.ADMIN,
            is_active=True
        )
        db.add(admin_user)
        
        analyst_user = User(
            email="analyst@ids-idps.com",
            password_hash=hash_password("Analyst123!"),
            role=UserRole.ANALYST,
            is_active=True
        )
        db.add(analyst_user)
        db.commit()
        
        # Create MFA records
        admin_mfa = UserMFA(user_id=admin_user.id, is_enabled=False)
        analyst_mfa = UserMFA(user_id=analyst_user.id, is_enabled=False)
        db.add(admin_mfa)
        db.add(analyst_mfa)
        db.commit()
        
        print(f"  ✓ Created admin: {admin_user.email}")
        print(f"  ✓ Created analyst: {analyst_user.email}")
        
        # 2. Insert model metadata
        print("Creating model record...")
        model = Model(
            version="rf-iter4-2025-09-30",
            trained_at=datetime.utcnow() - timedelta(days=1),
            metrics={
                "precision": 0.9542,
                "recall": 0.9378,
                "f1": 0.9459,
                "auc": 0.9812,
                "accuracy": 0.9523
            },
            notes="Random Forest with Voting Ensemble - Iteration 4"
        )
        db.add(model)
        db.commit()
        print(f"  ✓ Created model: {model.version}")
        
        # 3. Create initial threshold
        print("Creating threshold...")
        threshold = Threshold(
            current_value=Decimal("0.50"),
            updated_by=admin_user.id,
            updated_at=datetime.utcnow() - timedelta(hours=1)
        )
        db.add(threshold)
        db.commit()
        print(f"  ✓ Created threshold: {threshold.current_value}")
        
        # 4. Generate sample alerts
        print("Generating sample alerts...")
        attack_types = [
            "DoS_SYN", "DoS_HULK", "DoS_Slowloris", "DDoS_LOIC_HTTP",
            "DDoS_HOIC", "PortScan", "Bot", "Infiltration", "Benign"
        ]
        
        src_ips = [
            "192.168.1.100", "10.0.0.50", "172.16.0.200", "192.168.1.150",
            "10.0.0.75", "172.16.0.100", "192.168.1.200", "10.0.0.100"
        ]
        
        dst_ips = [
            "192.168.1.1", "10.0.0.1", "172.16.0.1", "192.168.1.10"
        ]
        
        alerts_created = 0
        for i in range(200):
            attack_type = random.choice(attack_types)
            
            # Benign traffic has lower scores
            if attack_type == "Benign":
                score = Decimal(str(round(random.uniform(0.05, 0.45), 4)))
            else:
                score = Decimal(str(round(random.uniform(0.30, 0.98), 4)))
            
            is_malicious = score >= Decimal("0.50")
            
            # Random status distribution
            status_weights = [AlertStatus.NEW, AlertStatus.ACK, AlertStatus.BLOCKED, AlertStatus.CLOSED]
            status = random.choices(status_weights, weights=[0.5, 0.3, 0.15, 0.05])[0]
            
            alert = Alert(
                event_ts=datetime.utcnow() - timedelta(
                    hours=random.randint(0, 168),  # Last 7 days
                    minutes=random.randint(0, 59)
                ),
                src_ip=random.choice(src_ips),
                dst_ip=random.choice(dst_ips),
                attack_type=attack_type,
                score=score,
                is_malicious=is_malicious,
                status=status,
                model_version=model.version,
                payload={
                    "protocol": random.choice(["TCP", "UDP", "ICMP"]),
                    "port": random.choice([80, 443, 22, 3389, 8080]),
                    "packet_size": random.randint(64, 1500),
                    "flow_duration": random.randint(100, 10000)
                }
            )
            db.add(alert)
            alerts_created += 1
        
        db.commit()
        print(f"  ✓ Created {alerts_created} alerts")
        
        # 5. Create some block rules
        print("Creating block rules...")
        malicious_ips = ["192.168.1.100", "10.0.0.50", "172.16.0.200"]
        for ip in malicious_ips:
            block = BlockRule(
                src_ip=ip,
                reason=f"Multiple DoS attacks detected from {ip}",
                active=True,
                created_by=admin_user.id
            )
            db.add(block)
        
        db.commit()
        print(f"  ✓ Created {len(malicious_ips)} block rules")
        
        print("\n✅ Database seeded successfully!")
        print("\n📝 Login Credentials:")
        print("  Admin:")
        print("    Email: admin@ids-idps.com")
        print("    Password: Admin123!")
        print("\n  Analyst:")
        print("    Email: analyst@ids-idps.com")
        print("    Password: Analyst123!")
        
    except Exception as e:
        print(f"❌ Error seeding database: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()

