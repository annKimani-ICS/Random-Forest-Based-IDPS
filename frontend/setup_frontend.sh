#!/bin/bash
# Frontend Setup Script for Ubuntu VM

set -e

echo "======================================"
echo "IDS/IDPS Frontend Setup"
echo "======================================"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Install Node.js and npm
echo -e "${GREEN}[1/5] Installing Node.js...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

# Navigate to frontend directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR

# Install dependencies
echo -e "${GREEN}[2/5] Installing frontend dependencies...${NC}"
npm install

# Get backend URL
read -p "Enter backend API URL [http://localhost:8000]: " BACKEND_URL
BACKEND_URL=${BACKEND_URL:-http://localhost:8000}

# Update API base URL if needed
echo -e "${GREEN}[3/5] Configuring API endpoint...${NC}"
# For production, update vite.config.js proxy settings

# Build for production
echo -e "${GREEN}[4/5] Building frontend...${NC}"
npm run build

# Setup Nginx to serve frontend
echo -e "${GREEN}[5/5] Setting up Nginx...${NC}"
sudo tee /etc/nginx/sites-available/ids-idps > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Frontend static files
    root $SCRIPT_DIR/dist;
    index index.html;

    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /auth/ {
        proxy_pass http://127.0.0.1:8000/auth/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /users/ {
        proxy_pass http://127.0.0.1:8000/users/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Frontend routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

# Enable site and restart Nginx
sudo ln -sf /etc/nginx/sites-available/ids-idps /etc/nginx/sites-enabled/ids-idps
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo -e "${GREEN}======================================"
echo "Frontend Setup Complete!"
echo "======================================${NC}"
echo ""
echo -e "${GREEN}Access the application at:${NC}"
echo "  http://$(hostname -I | awk '{print $1}')"
echo ""
echo -e "${YELLOW}For SSL/TLS (Production):${NC}"
echo "  sudo apt install certbot python3-certbot-nginx"
echo "  sudo certbot --nginx -d yourdomain.com"
echo ""

