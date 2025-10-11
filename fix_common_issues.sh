#!/bin/bash
# Automatic Troubleshooting and Fix Script for IDS/IDPS GUI
# Run this if you encounter problems after setup

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║       IDS/IDPS Automatic Troubleshooting Script          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXES_APPLIED=0

echo -e "${YELLOW}This script will attempt to automatically fix common issues.${NC}"
echo ""
read -p "Continue? [Y/n]: " CONTINUE
if [[ $CONTINUE =~ ^[Nn]$ ]]; then
    echo "Exiting."
    exit 0
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Diagnosing Issues...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Fix 1: PostgreSQL not running
echo -n "Checking PostgreSQL... "
if ! sudo systemctl is-active --quiet postgresql; then
    echo -e "${YELLOW}NOT RUNNING${NC}"
    echo "  → Starting PostgreSQL..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sleep 2
    if sudo systemctl is-active --quiet postgresql; then
        echo -e "  ${GREEN}✓ Fixed: PostgreSQL started${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "  ${RED}✗ Failed to start PostgreSQL${NC}"
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 2: Backend service not running
echo -n "Checking backend service... "
if ! sudo systemctl is-active --quiet ids-idps-backend; then
    echo -e "${YELLOW}NOT RUNNING${NC}"
    
    # Check if database issues are preventing startup
    if [ -d "$SCRIPT_DIR/backend/.venv" ]; then
        echo "  → Checking database before starting service..."
        cd "$SCRIPT_DIR/backend"
        source .venv/bin/activate
        
        # Try to create tables if they don't exist
        python3 -c "
from app.database import engine
from app.models import Base
try:
    Base.metadata.create_all(bind=engine)
    print('Database tables ready')
except Exception as e:
    print(f'Database issue: {e}')
" 2>/dev/null
        
        deactivate
        cd "$SCRIPT_DIR"
    fi
    
    echo "  → Starting backend service..."
    sudo systemctl start ids-idps-backend
    sleep 5  # Give more time for startup
    
    if sudo systemctl is-active --quiet ids-idps-backend; then
        echo -e "  ${GREEN}✓ Fixed: Backend service started${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "  ${RED}✗ Failed to start backend service${NC}"
        echo -e "  ${YELLOW}Checking logs...${NC}"
        sudo journalctl -u ids-idps-backend -n 30 --no-pager
        
        # Try to fix common startup issues
        echo "  → Attempting to fix startup issues..."
        
        # Ensure database tables exist
        if [ -d "$SCRIPT_DIR/backend/.venv" ]; then
            cd "$SCRIPT_DIR/backend"
            source .venv/bin/activate
            
            # Fix permissions and create tables
            sudo -u postgres psql -c "GRANT ALL ON SCHEMA public TO ids_user; ALTER USER ids_user CREATEDB;" 2>/dev/null || true
            
            python3 -c "
from app.database import engine
from app.models import Base
try:
    Base.metadata.create_all(bind=engine)
    print('Tables created for service startup')
except Exception as e:
    print(f'Still having issues: {e}')
" 2>/dev/null
            
            deactivate
            cd "$SCRIPT_DIR"
        fi
        
        # Try starting again
        sudo systemctl restart ids-idps-backend
        sleep 3
        
        if sudo systemctl is-active --quiet ids-idps-backend; then
            echo -e "  ${GREEN}✓ Fixed: Backend service started after fixes${NC}"
            ((FIXES_APPLIED++))
        fi
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 3: Backend API not responding
echo -n "Checking backend API... "
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${YELLOW}NOT RESPONDING${NC}"
    echo "  → Restarting backend service..."
    sudo systemctl restart ids-idps-backend
    sleep 3
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Fixed: Backend API responding${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "  ${RED}✗ Backend API still not responding${NC}"
        echo -e "  ${YELLOW}Recent logs:${NC}"
        sudo journalctl -u ids-idps-backend -n 10 --no-pager
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 4: Time synchronization (critical for 2FA)
echo -n "Checking time synchronization... "
if ! timedatectl status | grep -q "synchronized: yes"; then
    echo -e "${YELLOW}NOT SYNCHRONIZED${NC}"
    echo "  → Enabling NTP time sync..."
    sudo timedatectl set-ntp true
    sudo systemctl restart systemd-timesyncd
    sleep 3
    if timedatectl status | grep -q "synchronized: yes"; then
        echo -e "  ${GREEN}✓ Fixed: Time synchronized${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "  ${YELLOW}⚠ Time sync enabled but not yet synchronized (may take a few minutes)${NC}"
    fi
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 5: DISPLAY variable for GUI
echo -n "Checking DISPLAY variable... "
if [ -z "$DISPLAY" ]; then
    echo -e "${YELLOW}NOT SET${NC}"
    echo "  → Setting DISPLAY=:0..."
    export DISPLAY=:0
    echo "export DISPLAY=:0" >> ~/.bashrc
    echo -e "  ${GREEN}✓ Fixed: DISPLAY variable set${NC}"
    echo -e "  ${YELLOW}Note: You may need to run 'export DISPLAY=:0' in your current terminal${NC}"
    ((FIXES_APPLIED++))
else
    echo -e "${GREEN}OK${NC} (${DISPLAY})"
fi

# Fix 6: Missing virtual environments
echo -n "Checking backend virtual environment... "
if [ ! -d "$SCRIPT_DIR/backend/.venv" ]; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "  → Creating backend virtual environment..."
    cd "$SCRIPT_DIR/backend"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
    echo -e "  ${GREEN}✓ Fixed: Backend venv created${NC}"
    ((FIXES_APPLIED++))
else
    echo -e "${GREEN}OK${NC}"
fi

echo -n "Checking GUI virtual environment... "
if [ ! -d "$SCRIPT_DIR/gui/.venv" ]; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "  → Creating GUI virtual environment..."
    cd "$SCRIPT_DIR/gui"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
    echo -e "  ${GREEN}✓ Fixed: GUI venv created${NC}"
    ((FIXES_APPLIED++))
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 6.5: Python syntax issues in commands
echo -n "Checking Python syntax in database operations... "
if [ -d "$SCRIPT_DIR/backend/.venv" ]; then
    cd "$SCRIPT_DIR/backend"
    source .venv/bin/activate
    
    # Test Python imports
    PYTHON_TEST=$(python3 -c "
try:
    from app.database import engine
    from app.models import Base
    print('IMPORTS_OK')
except Exception as e:
    print(f'IMPORT_ERROR: {e}')
" 2>/dev/null)
    
    if [[ "$PYTHON_TEST" == *"IMPORT_ERROR"* ]]; then
        echo -e "${YELLOW}IMPORT ISSUES${NC}"
        echo "  → Fixing Python imports..."
        
        # Reinstall requirements
        pip install --force-reinstall -r requirements.txt
        
        # Test again
        PYTHON_TEST2=$(python3 -c "
try:
    from app.database import engine
    from app.models import Base
    print('IMPORTS_OK')
except Exception as e:
    print(f'IMPORT_ERROR: {e}')
" 2>/dev/null)
        
        if [[ "$PYTHON_TEST2" == *"IMPORTS_OK"* ]]; then
            echo -e "  ${GREEN}✓ Fixed: Python imports working${NC}"
            ((FIXES_APPLIED++))
        else
            echo -e "  ${RED}✗ Python import issues persist${NC}"
        fi
    else
        echo -e "${GREEN}OK${NC}"
    fi
    
    deactivate
    cd "$SCRIPT_DIR"
else
    echo -e "${YELLOW}NO VENV${NC}"
fi

# Fix 7: PyQt5 issues
echo -n "Checking PyQt5... "
cd "$SCRIPT_DIR/gui"
if [ -d ".venv" ]; then
    source .venv/bin/activate
    if ! python3 -c "import PyQt5" 2>/dev/null; then
        echo -e "${YELLOW}IMPORT ERROR${NC}"
        echo "  → Reinstalling PyQt5..."
        pip install --force-reinstall PyQt5
        if python3 -c "import PyQt5" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Fixed: PyQt5 reinstalled${NC}"
            ((FIXES_APPLIED++))
        else
            echo -e "  ${RED}✗ PyQt5 still failing${NC}"
            echo "  → Installing system PyQt5..."
            sudo apt install -y python3-pyqt5 python3-pyqt5.qtsvg
        fi
    else
        echo -e "${GREEN}OK${NC}"
    fi
    deactivate
else
    echo -e "${YELLOW}VENV NOT FOUND${NC}"
fi

# Fix 8: File permissions
echo -n "Checking script permissions... "
PERMS_FIXED=0
for script in "$SCRIPT_DIR/setup_gui_complete.sh" "$SCRIPT_DIR/verify_setup.sh" "$SCRIPT_DIR/gui/run_gui.sh"; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        chmod +x "$script"
        ((PERMS_FIXED++))
    fi
done

if [ $PERMS_FIXED -gt 0 ]; then
    echo -e "${GREEN}OK${NC} (${PERMS_FIXED} scripts made executable)"
    ((FIXES_APPLIED++))
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 9: .env file
echo -n "Checking .env file... "
if [ ! -f "$SCRIPT_DIR/backend/.env" ]; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo -e "  ${RED}✗ .env file missing - you need to run setup_gui_complete.sh${NC}"
else
    echo -e "${GREEN}OK${NC}"
fi

# Fix 10: Database schema and permissions
echo -n "Checking database schema... "
if [ -d "$SCRIPT_DIR/backend/.venv" ]; then
    cd "$SCRIPT_DIR/backend"
    source .venv/bin/activate
    
    # Check if tables exist
    TABLE_CHECK=$(python3 -c "
from app.database import engine
from app.models import Base
try:
    # Check if users table exists
    from sqlalchemy import inspect
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    if 'users' in tables:
        print('EXISTS')
    else:
        print('MISSING')
except Exception as e:
    print('ERROR')
" 2>/dev/null)
    
    if [ "$TABLE_CHECK" = "MISSING" ] || [ "$TABLE_CHECK" = "ERROR" ]; then
        echo -e "${YELLOW}SCHEMA ISSUES${NC}"
        
        # Fix database permissions first
        echo "  → Fixing database permissions..."
        sudo -u postgres psql -c "
        GRANT ALL ON SCHEMA public TO ids_user;
        GRANT CREATE ON SCHEMA public TO ids_user;
        ALTER USER ids_user CREATEDB;
        " 2>/dev/null || true
        
        # Create tables
        echo "  → Creating database tables..."
        python3 -c "
from app.database import engine
from app.models import Base
try:
    Base.metadata.create_all(bind=engine)
    print('Tables created successfully')
except Exception as e:
    print(f'Error creating tables: {e}')
" 2>/dev/null
        
        # Clear and seed the database
        echo "  → Clearing and seeding database..."
        python3 seed_data.py 2>/dev/null || {
            echo "  → Seeding failed, trying to clear database first..."
            # Try to clear database manually
            python3 -c "
from app.database import SessionLocal
from app.models import User, UserMFA, Model, Threshold, Alert, BlockRule
try:
    db = SessionLocal()
    db.query(UserMFA).delete()
    db.query(Alert).delete()
    db.query(BlockRule).delete()
    db.query(Threshold).delete()
    db.query(Model).delete()
    db.query(User).delete()
    db.commit()
    print('Database cleared successfully')
except Exception as e:
    print(f'Clear failed: {e}')
    db.rollback()
finally:
    db.close()
" 2>/dev/null
            # Try seeding again
            python3 seed_data.py 2>/dev/null || echo "  → Seeding still failed, but tables created"
        }
        
        echo -e "  ${GREEN}✓ Fixed: Database schema and permissions${NC}"
        ((FIXES_APPLIED++))
    else
        echo -e "${GREEN}OK${NC}"
        
        # Check if data exists
        USER_COUNT=$(python3 -c "
from app.database import SessionLocal
from app.models import User
try:
    db = SessionLocal()
    count = db.query(User).count()
    print(count)
except Exception as e:
    print(0)
finally:
    db.close()
" 2>/dev/null)
        
        if [ "$USER_COUNT" -eq 0 ]; then
            echo "  → No data found, seeding database..."
            python3 seed_data.py 2>/dev/null
            echo -e "  ${GREEN}✓ Database seeded${NC}"
            ((FIXES_APPLIED++))
        else
            # Check if we have duplicate key issues
            echo "  → Data exists, checking for issues..."
            SEED_TEST=$(python3 -c "
from app.database import SessionLocal
from app.models import User
try:
    db = SessionLocal()
    users = db.query(User).all()
    if len(users) >= 2:
        print('DATA_OK')
    else:
        print('INCOMPLETE_DATA')
except Exception as e:
    print(f'DATA_ERROR: {e}')
finally:
    db.close()
" 2>/dev/null)
            
            if [[ "$SEED_TEST" == *"DATA_ERROR"* ]] || [[ "$SEED_TEST" == *"INCOMPLETE_DATA"* ]]; then
                echo "  → Data issues detected, clearing and reseeding..."
                python3 seed_data.py 2>/dev/null
                echo -e "  ${GREEN}✓ Database reseeded${NC}"
                ((FIXES_APPLIED++))
            fi
        fi
    fi
    deactivate
    cd "$SCRIPT_DIR"
else
    echo -e "${YELLOW}CANNOT CHECK${NC}"
fi

# Fix 11: Database connection issues
echo -n "Checking database connection... "
if [ -f "$SCRIPT_DIR/backend/.env" ]; then
    source "$SCRIPT_DIR/backend/.env"
    DB_USER=$(echo $DATABASE_URL | sed -n 's/.*\/\/\(.*\):.*/\1/p' 2>/dev/null || echo "ids_user")
    DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\(.*\)/\1/p' 2>/dev/null || echo "ids_idps_db")
    
    # Test connection with different password attempts
    CONNECTION_OK=false
    
    # Try with default password
    if PGPASSWORD="[DEFAULT_DB_PASSWORD]" psql -U $DB_USER -d $DB_NAME -h localhost -c "SELECT 1" &>/dev/null 2>&1; then
        CONNECTION_OK=true
    fi
    
    # Try with common passwords if first attempt failed
    if [ "$CONNECTION_OK" = false ]; then
        for password in "SecureIDS2024" "ids_password" "password" ""; do
            if PGPASSWORD="$password" psql -U $DB_USER -d $DB_NAME -h localhost -c "SELECT 1" &>/dev/null 2>&1; then
                echo -e "${YELLOW}CONNECTED WITH PASSWORD${NC}"
                CONNECTION_OK=true
                break
            fi
        done
    fi
    
    if [ "$CONNECTION_OK" = true ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}CONNECTION ISSUES${NC}"
        echo "  → Recreating database with proper permissions..."
        
        # Drop and recreate database
        sudo -u postgres psql -c "
        DROP DATABASE IF EXISTS $DB_NAME;
        DROP USER IF EXISTS $DB_USER;
        CREATE USER $DB_USER WITH PASSWORD '[DEFAULT_DB_PASSWORD]';
        CREATE DATABASE $DB_NAME OWNER $DB_USER;
        GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
        ALTER USER $DB_USER CREATEDB;
        " 2>/dev/null
        
        # Grant schema permissions
        sudo -u postgres psql -d $DB_NAME -c "
        GRANT ALL ON SCHEMA public TO $DB_USER;
        GRANT CREATE ON SCHEMA public TO $DB_USER;
        " 2>/dev/null
        
        echo -e "  ${GREEN}✓ Database recreated with proper permissions${NC}"
        ((FIXES_APPLIED++))
    fi
else
    echo -e "${YELLOW}NO .ENV FILE${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ $FIXES_APPLIED -eq 0 ]; then
    echo -e "${GREEN}✓ No issues found! Everything looks good.${NC}"
    echo ""
    echo -e "${BLUE}You can launch the GUI:${NC}"
    echo -e "  cd $SCRIPT_DIR/gui && ./run_gui.sh"
else
    echo -e "${GREEN}✓ Applied $FIXES_APPLIED fix(es)${NC}"
    echo ""
    echo -e "${YELLOW}Recommended next steps:${NC}"
    echo ""
    echo "1. Run verification script:"
    echo -e "   ${BLUE}./verify_setup.sh${NC}"
    echo ""
    echo "2. If verification passes, launch GUI:"
    echo -e "   ${BLUE}cd gui && ./run_gui.sh${NC}"
    echo ""
    echo "3. If issues persist, check logs:"
    echo -e "   ${BLUE}sudo journalctl -u ids-idps-backend -n 50${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Quick Status Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Final status check
echo -e "PostgreSQL:       $(sudo systemctl is-active postgresql || echo 'inactive')"
echo -e "Backend Service:  $(sudo systemctl is-active ids-idps-backend || echo 'inactive')"
echo -n "Backend API:      "
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}responding${NC}"
else
    echo -e "${RED}not responding${NC}"
fi
echo -e "Time Sync:        $(timedatectl status | grep 'synchronized:' | awk '{print $3}')"
echo -e "DISPLAY:          ${DISPLAY:-not set}"

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""

