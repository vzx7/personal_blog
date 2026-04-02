#!/bin/bash
# Blog Deployment Script
# Run this after setup-vps.sh to deploy your blog

set -e

echo "=========================================="
echo "  Personal Blog - Deployment Script"
echo "=========================================="
echo ""

# Configuration
BLOG_USER="blog"
BLOG_DIR="/home/${BLOG_USER}/blog"
VPS_HOST="${1:-}"

if [ -z "${VPS_HOST}" ]; then
    echo "Usage: ./deploy-to-vps.sh <vps-host>"
    echo "Example: ./deploy-to-vps.sh user@192.168.1.100"
    exit 1
fi

echo "Deploying to: ${VPS_HOST}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/5] Building frontend..."
cd "${SCRIPT_DIR}/frontend"
npm install
npm run build

echo "[2/5] Building backend..."
cd "${SCRIPT_DIR}/backend"
GOOS=linux GOARCH=amd64 go build -o blog ./cmd/main.go

echo "[3/5] Copying files to VPS..."
ssh "${VPS_HOST}" "mkdir -p ${BLOG_DIR}/{backend,frontend}"

scp -r "${SCRIPT_DIR}/frontend/dist" "${VPS_HOST}:${BLOG_DIR}/frontend/"
scp -r "${SCRIPT_DIR}/backend/posts" "${VPS_HOST}:${BLOG_DIR}/backend/"
scp "${SCRIPT_DIR}/backend/blog" "${VPS_HOST}:${BLOG_DIR}/backend/"

echo "[4/5] Setting permissions..."
ssh "${VPS_HOST}" "sudo chown -R ${BLOG_USER}:${BLOG_USER} ${BLOG_DIR}"
ssh "${VPS_HOST}" "sudo chmod +x ${BLOG_DIR}/backend/blog"

echo "[5/5] Restarting blog service..."
ssh "${VPS_HOST}" "sudo systemctl restart blog"

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Your blog is now running at:"
echo "  http://${VPS_HOST#*@}"
echo ""
echo "To check status:"
echo "  ssh ${VPS_HOST} 'sudo systemctl status blog'"
echo ""
echo "To view logs:"
echo "  ssh ${VPS_HOST} 'sudo journalctl -u blog -f'"
echo ""
