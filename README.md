# Personal Blog

A minimalist full-stack personal blog built with Go (backend) and React + TypeScript (frontend).

## Features

- **Frontend**: Vite + React + TypeScript
  - Minimalist, text-focused design
  - Soft beige background (#FAF8F0)
  - Dark gray text (#222222)
  - Blue link accent (#2a6ebb)
  - Responsive layout (~700px column)
  - Markdown rendering

- **Backend**: Go REST API
  - List posts with metadata
  - Serve individual post content
  - Markdown parsing with [goldmark](https://github.com/yuin/goldmark)

- **Categories**: Personal, Religion, Dev

## Project Structure

```
blog/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   └── Layout.tsx
│   │   ├── pages/
│   │   │   ├── Home.tsx
│   │   │   ├── Post.tsx
│   │   │   └── About.tsx
│   │   ├── styles/
│   │   │   └── main.css
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── index.html
│   └── package.json
├── backend/
│   ├── cmd/
│   │   └── main.go
│   ├── internal/
│   │   └── handlers/
│   │       └── handlers.go
│   ├── posts/
│   │   └── *.md (sample posts)
│   └── go.mod
├── run-frontend.sh
├── run-backend.sh
├── setup-vps.sh       # VPS setup script (Debian)
├── deploy-to-vps.sh   # Deployment script
└── README.md
```

## Setup & Running

### Prerequisites

- Node.js 18+
- Go 1.21+

### Quick Start

1. **Install frontend dependencies**:
   ```bash
   cd frontend
   npm install
   ```

2. **Run the backend** (in one terminal):
   ```bash
   cd backend
   go run cmd/main.go
   ```
   Backend runs on http://localhost:8080

3. **Run the frontend** (in another terminal):
   ```bash
   cd frontend
   npm run dev
   ```
   Frontend runs on http://localhost:5173

### Using Run Scripts

Alternatively, use the provided scripts:

```bash
./run-backend.sh   # Starts Go server on :8080
./run-frontend.sh  # Starts Vite dev server on :5173
```

## Adding Posts

Add Markdown files to `backend/posts/` with frontmatter:

```markdown
---
title: Your Post Title
date: 2026-01-15
category: Personal
---

# Your content here

Write your post content in Markdown...
```

Supported categories: `Personal`, `Religion`, `Dev`

## API Endpoints

- `GET /api/posts` - List all posts (metadata only)
- `GET /api/posts/{slug}` - Get single post with content

## Production Build

```bash
# Build frontend
cd frontend
npm run build

# The backend serves the built files from ../frontend/dist
cd ../backend
go build -o blog ./cmd/main.go
./blog
```

## Deployment on VPS

### DNS Configuration (Required)

Before deploying, configure your domain's DNS at your registrar:

1. **Log in to your domain registrar** (Namecheap, GoDaddy, Reg.ru, etc.)

2. **Add DNS records**:

   | Type | Name/Host | Value/Points to | TTL |
   |------|-----------|-----------------|-----|
   | A | `@` | Your VPS IP (e.g., `192.168.1.100`) | Auto |
   | A | `www` | Your VPS IP (e.g., `192.168.1.100`) | Auto |

3. **Wait for propagation** (5-30 minutes)

4. **Verify**: `ping your-domain.com` should show your VPS IP

### Quick Deploy (Automated)

The project includes scripts for automated deployment to a fresh Debian VPS.

#### Step 1: Run Setup Script on VPS

Copy `setup-vps.sh` to your VPS and run it as root:

```bash
# Copy script to VPS
scp setup-vps.sh root@your-vps-ip:/root/

# Connect to VPS and run
ssh root@your-vps-ip
./setup-vps.sh
```

This script will:
- Update system packages
- Install Go, Node.js, Nginx
- Create `blog` user and directory structure
- Configure firewall (UFW) - ports 22, 80, 443
- Create systemd service
- Enable automatic security updates

#### Step 2: Deploy Your Blog

From your local machine, run the deploy script:

```bash
./deploy-to-vps.sh user@your-vps-ip
```

Example: `./deploy-to-vps.sh root@192.168.1.100`

#### Step 3: Setup SSL with Let's Encrypt

```bash
ssh user@your-vps-ip
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
sudo systemctl restart nginx
```

---

### Manual Deploy

If you prefer manual deployment:

#### 1. Build Locally

```bash
cd blog/frontend
npm run build

cd ../backend
GOOS=linux GOARCH=amd64 go build -o blog ./cmd/main.go
```

#### 2. Upload to VPS

```bash
# Create directory on server
ssh user@vps 'mkdir -p ~/blog'

# Copy files
scp -r backend/posts backend/blog ~/blog/
scp -r frontend/dist ~/blog/
```

#### 3. Run on Server

```bash
ssh user@vps
cd ~/blog
./blog
```

#### 4. Setup systemd (Auto-start)

Create `/etc/systemd/system/blog.service`:

```ini
[Unit]
Description=Personal Blog
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/home/user/blog
ExecStart=/home/user/blog/blog
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable blog
sudo systemctl start blog
```

#### 5. Configure Nginx (Optional)

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 6. Add New Posts

```bash
scp new-post.md user@vps:~/blog/posts/
sudo systemctl restart blog
```

#### 7. Setup SSL (Let's Encrypt)

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
sudo systemctl restart nginx
```

## Security

### Implemented Security Measures

- ✅ Path traversal protection (slug validation)
- ✅ Input validation (alphanumeric slugs only)
- ✅ Security headers (XSS, clickjacking protection)
- ✅ Error message sanitization (no internal details leaked)

### Production Recommendations

> **Note:** The `setup-vps.sh` script automatically configures most of these settings.

1. **Enable HTTPS** (required for production):
   ```nginx
   server {
       listen 443 ssl http2;
       server_name your-domain.com;
       
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       ssl_protocols TLSv1.2 TLSv1.3;
   }
   ```

2. **Add rate limiting** (Nginx):
   > Already configured in `setup-vps.sh`
   ```nginx
   limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
   
   location /api/ {
       limit_req zone=api burst=20 nodelay;
       proxy_pass http://localhost:8080;
   }
   ```

3. **Run as non-root user**:
   > Already configured - blog runs as `blog` user
   ```bash
   sudo useradd -r -s /bin/false blog
   sudo chown -R blog:blog /home/user/blog
   ```

4. **Configure firewall**:
   > Already configured by `setup-vps.sh`
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

5. **Enable automatic security updates**:
   > Already installed by `setup-vps.sh`
   ```bash
   sudo apt install unattended-upgrades
   ```

## License

MIT
