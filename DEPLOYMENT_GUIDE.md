# IDS/IDPS System - Ubuntu VM Deployment Guide

Complete guide for deploying the Random Forest-Based IDS/IDPS Admin Dashboard with 2FA on Ubuntu VM.

## Architecture Overview

```
Internet/Attacker → Network Traffic → L3 Switch (SPAN/Mirror) → IDS/IDPS Engine
                                                                        ↓
                                                            Detection & Analysis
                                                                        ↓
                                                    ┌──────────────────┴──────────────────┐
                                                    ↓                                      ↓
                                            Block Rules →                           Alerts/Logs →
                                            Firewall API                        Admin Dashboard (GUI)
                                                                                        ↓
                                                                                Administrator
                                                                                (Login → 2FA → Manage)
```

## System Components

### Backend (FastAPI)
- **Authentication**: JWT access/refresh tokens, bcrypt password hashing
- **2FA**: TOTP (Time-based One-Time Password) via Google Authenticator
- **Database**: PostgreSQL with JSONB support for flexible alert payloads
- **RBAC**: Admin and Analyst roles
- **API Endpoints**:
  - `/auth/*` - Authentication and MFA
  - `/api/*` - Dashboard, alerts, metrics, KPIs
  - `/users/*` - User management (Admin only)

### Frontend (React + Vite)
- **Pages**: Login, 2FA Verify, Dashboard, Settings, Users, MFA Enrollment
- **Features**: Real-time KPIs, alerts table, threshold control, block rules
- **Security**: Token-based auth, automatic refresh, RBAC enforcement

### Database Schema
- `users` - User accounts with password hashing
- `user_mfa` - TOTP secrets and recovery codes
- `refresh_tokens` - JWT refresh token management
- `models` - ML model metadata and metrics
- `thresholds` - Detection threshold history
- `alerts` - Security alerts with JSONB payload
- `block_rules` - IP blocking rules
- `audit_logs` - Complete audit trail

---

## Prerequisites

### Ubuntu VM Requirements
- **OS**: Ubuntu 22.04 LTS or newer
- **RAM**: Minimum 2GB (4GB recommended)
- **Disk**: 20GB available space
- **CPU**: 2 cores minimum
- **Network**: Static IP or DHCP reservation recommended
- **User**: Non-root user with sudo privileges

### Software Versions
- Python 3.10+
- PostgreSQL 14+
- Node.js 18+
- Nginx 1.18+

---

## Step-by-Step Deployment

### 1. Initial Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Set hostname (optional)
sudo hostnamectl set-hostname ids-idps

# Configure timezone
sudo timedatectl set-timezone UTC  # or your timezone

# Verify time synchronization (CRITICAL for TOTP 2FA)
sudo timedatectl set-ntp true
timedatectl status
```

### 2. Clone or Transfer Project Files

```bash
# Option A: Clone from Git (if repository exists)
git clone https://github.com/yourusername/Random-Forest-Based-IDPS.git
cd Random-Forest-Based-IDPS

# Option B: Transfer files via SCP
# On your local machine:
scp -r Random-Forest-Based-IDPS/ user@vm-ip:/home/user/
```

### 3. Run Backend Setup Script

```bash
cd backend
chmod +x setup_ubuntu.sh
./setup_ubuntu.sh
```

**The script will:**
1. Install all system dependencies (Python, PostgreSQL, Nginx, etc.)
2. Configure time synchronization for TOTP
3. Create PostgreSQL database and user
4. Setup Python virtual environment
5. Generate secure JWT secret
6. Create `.env` configuration file
7. Initialize database tables
8. Seed database with demo data
9. Create and enable systemd service
10. Configure firewall rules

**Prompts during setup:**
- Database name (default: `ids_idps_db`)
- Database user (default: `ids_user`)
- Database password (create a strong password)

### 4. Verify Backend Service

```bash
# Check service status
sudo systemctl status ids-idps

# View logs
sudo journalctl -u ids-idps -f

# Test API health
curl http://localhost:8000/health

# View API documentation
# Open in browser: http://YOUR_VM_IP:8000/docs
```

### 5. Setup Frontend

```bash
cd ../frontend
chmod +x setup_frontend.sh
./setup_frontend.sh
```

**The script will:**
1. Install Node.js 18.x
2. Install npm dependencies
3. Build production-ready static files
4. Configure Nginx as reverse proxy
5. Enable and start Nginx

### 6. Verify Complete Installation

```bash
# Check all services
sudo systemctl status ids-idps
sudo systemctl status nginx
sudo systemctl status postgresql

# Test frontend access
curl http://YOUR_VM_IP

# Check firewall
sudo ufw status
```

---

## Access the Application

### Default URLs
- **Frontend Dashboard**: `http://YOUR_VM_IP`
- **Backend API**: `http://YOUR_VM_IP:8000`
- **API Documentation**: `http://YOUR_VM_IP:8000/docs`

### Default Credentials

**Admin Account:**
- Email: `admin@ids-idps.com`
- Password: `Admin123!`

**Analyst Account:**
- Email: `analyst@ids-idps.com`
- Password: `Analyst123!`

⚠️ **Change these passwords immediately in production!**

---

## Post-Deployment Configuration

### 1. Enable 2FA for Users

1. Login to dashboard
2. Navigate to profile or `/mfa-enroll`
3. Scan QR code with Google Authenticator/Authy
4. Enter 6-digit code to activate
5. Save recovery codes securely

### 2. Configure Detection Threshold

1. Login as Admin
2. Go to Settings page
3. Adjust threshold slider (0.00 - 1.00)
4. Click "Save Threshold"
5. Monitor impact on alerts

### 3. Create Additional Users (Admin Only)

1. Navigate to Users page
2. Click "Create User"
3. Enter email, password, and role
4. User will receive credentials

### 4. Setup SSL/TLS (Production)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate (requires domain name)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is configured automatically
sudo certbot renew --dry-run
```

### 5. Configure Email Notifications (Optional)

Update backend to send email alerts:

```bash
# Install email dependencies
source ~/ids-idps/.venv/bin/activate
pip install aiosmtplib

# Add to .env (replace with your actual SMTP credentials)
echo "SMTP_HOST=your-smtp-server.com" >> ~/ids-idps/.env
echo "SMTP_PORT=587" >> ~/ids-idps/.env
echo "SMTP_USER=your-email@domain.com" >> ~/ids-idps/.env
echo "SMTP_PASSWORD=your-secure-password" >> ~/ids-idps/.env

# Restart service
sudo systemctl restart ids-idps
```

---

## Maintenance & Operations

### Service Management

```bash
# Start/Stop/Restart backend
sudo systemctl start ids-idps
sudo systemctl stop ids-idps
sudo systemctl restart ids-idps

# Enable/Disable auto-start
sudo systemctl enable ids-idps
sudo systemctl disable ids-idps

# View service logs
sudo journalctl -u ids-idps -f
sudo journalctl -u ids-idps --since "1 hour ago"
```

### Database Management

```bash
# Access PostgreSQL
sudo -u postgres psql

# Connect to IDS database
\c ids_idps_db

# List tables
\dt

# View alerts
SELECT * FROM alerts ORDER BY event_ts DESC LIMIT 10;

# Count alerts by type
SELECT attack_type, COUNT(*) FROM alerts GROUP BY attack_type;

# Exit
\q
```

### Backup Database

```bash
# Create backup
sudo -u postgres pg_dump ids_idps_db > backup_$(date +%Y%m%d).sql

# Restore backup
sudo -u postgres psql ids_idps_db < backup_20250101.sql
```

### Update Application

```bash
# Pull latest code
cd ~/Random-Forest-Based-IDPS
git pull

# Update backend
cd backend
source .venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart ids-idps

# Update frontend
cd ../frontend
npm install
npm run build
sudo systemctl restart nginx
```

### Monitor Performance

```bash
# System resources
htop

# Disk usage
df -h

# Database size
sudo -u postgres psql -c "SELECT pg_size_pretty(pg_database_size('ids_idps_db'));"

# Active connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE datname='ids_idps_db';"

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

---

## Security Considerations

### Production Deployment Checklist

- [ ] Change all default passwords
- [ ] Enable 2FA for all admin accounts
- [ ] Configure SSL/TLS with valid certificate
- [ ] Set strong JWT_SECRET (auto-generated by setup script)
- [ ] Configure firewall to restrict database access
- [ ] Enable fail2ban for SSH protection
- [ ] Regular database backups
- [ ] Monitor audit logs
- [ ] Keep system packages updated
- [ ] Use environment variables for secrets (never commit .env)
- [ ] Configure rate limiting on Nginx
- [ ] Set up log rotation
- [ ] Implement intrusion detection on the VM itself

### Rate Limiting (Nginx)

```nginx
# Add to /etc/nginx/sites-available/ids-idps

http {
    limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=5r/m;
    
    server {
        location /auth/login {
            limit_req zone=auth_limit burst=3 nodelay;
            # ... rest of config
        }
    }
}
```

### Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Block direct database access from external
sudo ufw deny 5432/tcp

# Enable firewall
sudo ufw enable
```

---

## Troubleshooting

### Backend won't start

```bash
# Check logs
sudo journalctl -u ids-idps -n 50

# Common issues:
# 1. Database connection - verify DATABASE_URL in .env
# 2. Port 8000 in use - check with: sudo lsof -i :8000
# 3. Python dependencies - reinstall: pip install -r requirements.txt
```

### Frontend shows blank page

```bash
# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Verify build files exist
ls -la /home/user/Random-Forest-Based-IDPS/frontend/dist

# Rebuild frontend
cd ~/Random-Forest-Based-IDPS/frontend
npm run build
sudo systemctl restart nginx
```

### 2FA codes not working

```bash
# Verify time synchronization (CRITICAL)
timedatectl status

# If not synchronized:
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd

# Check server time matches your phone
date
```

### Database connection errors

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection
psql -U ids_user -d ids_idps_db -h localhost

# Reset password if needed
sudo -u postgres psql -c "ALTER USER ids_user WITH PASSWORD 'newpassword';"
```

### High memory usage

```bash
# Check processes
htop

# Restart services to clear memory
sudo systemctl restart ids-idps
sudo systemctl restart nginx

# Configure swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## Demo Script for Viva

### Scenario: Complete System Demonstration

**1. Login Flow (2 minutes)**
```
→ Open browser: http://VM_IP
→ Enter: admin@ids-idps.com / Admin123!
→ Show: MFA challenge screen
→ Open Google Authenticator on phone
→ Enter 6-digit code
→ Result: Successful login to dashboard
```

**2. Dashboard Overview (3 minutes)**
```
→ Point to KPI cards: Alerts (24h), Active Blocks, Precision, Threshold
→ Show model metrics: Recall, F1, AUC, Training date
→ Explain model version: rf-iter4-2025-09-30
→ Show alerts table with filters
→ Demonstrate pagination
```

**3. Alert Management (2 minutes)**
```
→ Filter alerts by attack type (e.g., "DoS_SYN")
→ Select a high-score malicious alert
→ Click "ACK" to acknowledge
→ Show status change in real-time
→ Click "Block" on another alert
→ Enter block reason
→ Verify active blocks incremented
```

**4. Threshold Adjustment (2 minutes)**
```
→ Navigate to Settings (Admin only)
→ Show current threshold (e.g., 0.50)
→ Adjust slider to 0.65
→ Click "Save Threshold"
→ Return to dashboard
→ Show KPIs updated (fewer malicious alerts)
```

**5. RBAC Demonstration (2 minutes)**
```
→ Logout admin
→ Login as: analyst@ids-idps.com / Analyst123!
→ Show analyst CAN: view alerts, acknowledge, create blocks
→ Show analyst CANNOT: access Settings, User Management
→ Attempt to navigate to /settings → redirected
```

**6. User Management (2 minutes)**
```
→ Login as admin again
→ Navigate to Users page
→ Show existing users with roles and MFA status
→ Create new analyst user
→ Show audit log entry for user creation
```

**Total: ~15 minutes**

---

## API Endpoints Reference

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - Login (password)
- `POST /auth/mfa/verify` - Verify MFA code
- `POST /auth/mfa/enroll` - Generate MFA QR code
- `POST /auth/mfa/activate` - Activate MFA
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Logout
- `GET /auth/me` - Get current user

### Dashboard
- `GET /api/metrics` - Model performance metrics
- `GET /api/kpis` - Dashboard KPIs
- `GET /api/alerts` - List alerts (with filters)
- `PATCH /api/alerts/{id}/status` - Update alert status
- `GET /api/threshold` - Get current threshold
- `PUT /api/threshold` - Update threshold (Admin)
- `GET /api/blocks/active` - List active blocks
- `POST /api/blocks` - Create block rule
- `PATCH /api/blocks/{id}/deactivate` - Deactivate block (Admin)
- `GET /api/audit` - Audit logs (Admin)

### Users
- `POST /users` - Create user (Admin)
- `GET /users` - List users (Admin)
- `GET /users/{id}` - Get user details (Admin)
- `PATCH /users/{id}` - Update user (Admin)
- `POST /users/{id}/reset-password` - Reset password (Admin)

---

## Support & Documentation

- **API Docs**: http://YOUR_VM_IP:8000/docs (Interactive Swagger UI)
- **ReDoc**: http://YOUR_VM_IP:8000/redoc (Alternative API docs)
- **Project README**: See `README.md` in project root
- **EDA Summary**: See `eda_summary.md` for data analysis
- **Model Reports**: See `reports/` directory

---

## License

This project is part of an academic Information Security project demonstrating ML-based intrusion detection with secure authentication and RBAC.

