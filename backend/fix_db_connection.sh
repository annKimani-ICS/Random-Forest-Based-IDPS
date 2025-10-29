#!/bin/bash
# Auto-fix PostgreSQL connection for the backend
# - Resolves: password authentication failed for user "ids_user"
# - Strategy: Prefer local postgres superuser connection. Fallback: create ids_user with password.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing PostgreSQL connection for backend...${NC}"

# Move to script dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure .env exists
if [ ! -f .env ]; then
  echo -e "${YELLOW}⚠️  .env not found. Creating a default one...${NC}"
  cat > .env <<EOF
DATABASE_URL=postgresql://postgres@localhost:5432/ids_idps_db
JWT_SECRET=$(openssl rand -hex 32 2>/dev/null || echo default-secret)
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
REFRESH_TOKEN_EXPIRE_DAYS=7
ISSUER=IDS-IDPS
CORS_ORIGINS=http://localhost:5173,http://localhost:8000
RATE_LIMIT_LOGIN=5/minute
RATE_LIMIT_MFA=5/minute
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
EOF
fi

echo -e "${BLUE}📄 Backing up .env -> .env.bak${NC}"
cp .env .env.bak

# Read current DATABASE_URL
CURRENT_URL=$(grep -E '^DATABASE_URL=' .env | head -n1 | cut -d'=' -f2- || true)

fix_to_postgres_superuser() {
  echo -e "${BLUE}🔁 Switching DATABASE_URL to local postgres superuser (no password)...${NC}"
  sed -i 's#^DATABASE_URL=.*#DATABASE_URL=postgresql://postgres@localhost:5432/ids_idps_db#g' .env
}

create_db_if_missing() {
  echo -e "${BLUE}🛠  Ensuring database exists...${NC}"
  if command -v sudo >/dev/null 2>&1; then
    SUDO=sudo
  fi
  if $SUDO -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='ids_idps_db'" | grep -q 1; then
    echo -e "${GREEN}✅ Database ids_idps_db already exists${NC}"
  else
    echo -e "${BLUE}📦 Creating database ids_idps_db...${NC}"
    $SUDO -u postgres createdb ids_idps_db || true
    echo -e "${GREEN}✅ Database created (or already present)${NC}"
  fi
}

try_connect() {
  python - <<'PY'
import os, sys
from sqlalchemy import create_engine

url = None
for line in open('.env'):
    if line.startswith('DATABASE_URL='):
        url = line.strip().split('=',1)[1]
        break

if not url:
    print('❌ DATABASE_URL not found in .env')
    sys.exit(2)

try:
    engine = create_engine(url, pool_pre_ping=True)
    with engine.connect() as conn:
        conn.execute("SELECT 1")
    print('OK')
except Exception as e:
    print('ERR:' + str(e))
    sys.exit(1)
PY
}

# Path A: Use postgres superuser for local dev (most reliable)
fix_to_postgres_superuser
create_db_if_missing

echo -e "${BLUE}🔎 Testing connection...${NC}"
if OUTPUT=$(try_connect); then
  echo -e "${GREEN}✅ Connection successful using postgres superuser${NC}"
  EXIT_OK=1
else
  echo -e "${YELLOW}⚠️  Connection with postgres user failed. Will create ids_user and configure password...${NC}"

  # Create ids_user with password and grant privileges
  if command -v openssl >/dev/null 2>&1; then
    IDS_PASS=$(openssl rand -base64 18 | tr -d '=+/')
  else
    IDS_PASS="IdsUser$(date +%s)Pwd!"
  fi

  if command -v sudo >/dev/null 2>&1; then
    SUDO=sudo
  fi

  $SUDO -u postgres psql -v ON_ERROR_STOP=1 <<SQL || true
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ids_user') THEN
    CREATE ROLE ids_user LOGIN PASSWORD '${IDS_PASS}';
  END IF;
END$$;
SQL

  $SUDO -u postgres psql -v ON_ERROR_STOP=1 <<SQL || true
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'ids_idps_db') THEN
    CREATE DATABASE ids_idps_db OWNER ids_user;
  ELSE
    ALTER DATABASE ids_idps_db OWNER TO ids_user;
  END IF;
END$$;
GRANT ALL PRIVILEGES ON DATABASE ids_idps_db TO ids_user;
SQL

  echo -e "${BLUE}🔁 Updating .env to use ids_user with password...${NC}"
  sed -i "s#^DATABASE_URL=.*#DATABASE_URL=postgresql+psycopg2://ids_user:${IDS_PASS}@localhost:5432/ids_idps_db#g" .env

  echo -e "${BLUE}🔎 Re-testing connection...${NC}"
  if OUTPUT=$(try_connect); then
    echo -e "${GREEN}✅ Connection successful using ids_user${NC}"
    EXIT_OK=1
    echo -e "${YELLOW}🔐 Saved credentials in .env for ids_user${NC}"
  else
    echo -e "${RED}❌ Still cannot connect to Postgres. Please verify PostgreSQL is running and local auth rules (pg_hba.conf) allow local connections.${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}🎉 Database connection fixed.${NC}"
echo -e "${BLUE}You can now start the backend:${NC}"
echo "  cd $(pwd) && source ../backend/.venv/bin/activate 2>/dev/null || true"
echo "  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"


