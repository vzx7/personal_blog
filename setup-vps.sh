#!/bin/bash
# Blog VPS Setup Script for Debian
# Run this script on a fresh Debian VPS to prepare the environment

set -e

echo "=========================================="
echo "  Personal Blog - VPS Setup Script"
echo "  Debian 11/12"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./setup-vps.sh)"
    exit 1
fi

# Configuration
BLOG_USER="blog"
BLOG_DIR="/home/${BLOG_USER}/blog"
NGINX_DOMAIN="${NGINX_DOMAIN:-your-domain.com}"

echo "[1/10] Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

echo "[2/10] Installing essential tools..."
apt-get install -y -qq \
    curl \
    wget \
    git \
    unzip \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    nginx \
    certbot \
    python3-certbot-nginx

echo "[3/10] Installing Go..."
GO_VERSION="1.22.0"
GO_ARCH="amd64"
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

# Add Go to PATH
if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
fi
export PATH=$PATH:/usr/local/go/bin

echo "[4/10] Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y -qq nodejs

echo "[5/10] Creating blog user..."
if ! id "${BLOG_USER}" &>/dev/null; then
    useradd -r -m -s /bin/bash "${BLOG_USER}"
    echo "User '${BLOG_USER}' created"
else
    echo "User '${BLOG_USER}' already exists"
fi

echo "[6/10] Creating blog directory structure..."
mkdir -p "${BLOG_DIR}"/{backend,frontend}
chown -R "${BLOG_USER}:${BLOG_USER}" "${BLOG_DIR}"
chmod 755 "${BLOG_DIR}"

echo "[7/10] Configuring firewall (UFW)..."
# Reset UFW to default
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (port 22)
ufw allow 22/tcp

# Allow HTTP (port 80)
ufw allow 80/tcp

# Allow HTTPS (port 443)
ufw allow 443/tcp

# Enable UFW
echo "y" | ufw enable

echo "[8/10] Configuring Nginx..."
cat > /etc/nginx/sites-available/blog << 'NGINX_CONFIG'
server {
    listen 80;
    server_name _;

    # Redirect HTTP to HTTPS (uncomment after SSL setup)
    # return 301 https://$host$request_uri;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
}

# HTTPS server (uncomment after SSL certificate setup)
# server {
#     listen 443 ssl http2;
#     server_name your-domain.com;
#     
#     ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
#     ssl_protocols TLSv1.2 TLSv1.3;
#     ssl_ciphers HIGH:!aNULL:!MD5;
#     ssl_prefer_server_ciphers on;
#     
#     location / {
#         proxy_pass http://localhost:8080;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade $http_upgrade;
#         proxy_set_header Connection 'upgrade';
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto $scheme;
#         proxy_cache_bypass $http_upgrade;
#     }
# }
NGINX_CONFIG

# Enable site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/blog /etc/nginx/sites-enabled/blog

# Test Nginx config
nginx -t

# Restart Nginx
systemctl restart nginx
systemctl enable nginx

echo "[9/10] Creating systemd service for blog..."
cat > /etc/systemd/system/blog.service << 'SYSTEMD_CONFIG'
[Unit]
Description=Personal Blog
After=network.target

[Service]
Type=simple
User=blog
Group=blog
WorkingDirectory=/home/blog/blog/backend
ExecStart=/home/blog/blog/backend/blog
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=blog

# Security hardening
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
SYSTEMD_CONFIG

systemctl daemon-reload

echo "[10/10] Installing security updates..."
apt-get install -y -qq unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Installed:"
echo "  - Go $(go version | awk '{print $3}')"
echo "  - Node.js $(node --version)"
echo "  - Nginx $(nginx -v 2>&1 | awk -F'/' '{print $2}')"
echo "  - UFW (firewall)"
echo "  - unattended-upgrades"
echo ""
echo "Created:"
echo "  - User: ${BLOG_USER}"
echo "  - Directory: ${BLOG_DIR}"
echo "  - Systemd service: blog.service"
echo ""
echo "Firewall rules:"
echo "  - Port 22 (SSH) - OPEN"
echo "  - Port 80 (HTTP) - OPEN"
echo "  - Port 443 (HTTPS) - OPEN"
echo "  - All other incoming - BLOCKED"
echo ""
echo "=========================================="
echo "  DNS Configuration Required!"
echo "=========================================="
echo ""
echo "To use your domain, configure DNS at your registrar:"
echo ""
echo "  1. Log in to your domain registrar (Namecheap, GoDaddy, etc.)"
echo "  2. Add DNS records:"
echo ""
echo "     Type: A"
echo "     Name: @"
echo "     Value: $(curl -s ifconfig.me)"
echo "     TTL: Automatic"
echo ""
echo "     Type: A"
echo "     Name: www"
echo "     Value: $(curl -s ifconfig.me)"
echo "     TTL: Automatic"
echo ""
echo "  3. Wait for DNS propagation (5-30 minutes)"
echo "  4. Test: ping your-domain.com"
echo ""
echo "Next steps:"
echo "  1. Copy your blog files to ${BLOG_DIR}"
echo "  2. Build the blog:"
echo "     sudo -u ${BLOG_USER} bash -c '"
echo "       cd ${BLOG_DIR}/frontend && npm install && npm run build"
echo "       cd ${BLOG_DIR}/backend && go build -o blog ./cmd/main.go"
echo "     '"
echo "  3. Start the blog:"
echo "     sudo systemctl start blog"
echo "  4. Setup SSL with Let's Encrypt:"
echo "     certbot --nginx -d your-domain.com -d www.your-domain.com"
echo ""
echo "=========================================="
