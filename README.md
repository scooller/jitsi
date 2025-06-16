# Jitsi Meet Docker Deployment

A production-ready Jitsi Meet video conferencing solution using Docker, specifically designed for deployment on CentOS servers with WHM/cPanel environments.

## 🚀 Features

- **Complete Docker Setup** - All services containerized with Docker Compose
- **SSL/HTTPS Support** - Automatic Let's Encrypt certificate management
- **Apache HTTP Server** - Reverse proxy with SSL termination
- **CentOS/WHM Compatible** - Tailored for shared hosting environments
- **Monitoring & Health Checks** - Built-in system monitoring
- **Automated Management** - Scripts for deployment, backup, and maintenance
- **Security Hardened** - Production security configurations
- **cPanel Integration** - Easy subdomain and DNS management

## 📋 Prerequisites

- CentOS 7/8 server with root access
- WHM/cPanel (optional but recommended)
- Domain name with DNS access
- Minimum 2GB RAM, 2 CPU cores
- Open ports: 80, 443, 10000/udp, 4443/tcp

## 🛠 Quick Installation

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url> /opt/jitsi-meet
cd /opt/jitsi-meet

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Configure Environment

Edit the `.env` file with your domain and email:

```bash
# Basic configuration
PUBLIC_URL=https://meet.yourdomain.com
LETSENCRYPT_DOMAIN=meet.yourdomain.com
LETSENCRYPT_EMAIL=admin@yourdomain.com
DOCKER_HOST_ADDRESS=YOUR_SERVER_IP
```

### 3. Automated Installation

Run the installation script:

```bash
sudo ./scripts/install.sh
```

The script will:

- Install Docker and Docker Compose
- Configure firewall
- Generate SSL certificates
- Start all services
- Set up monitoring

### 4. Manual Steps (if needed)

If you prefer manual installation:

```bash
# Install Docker
sudo yum update -y
sudo yum install -y docker docker-compose

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start services
docker-compose up -d
```

## 🔧 Configuration

### Environment Variables

Key variables in `.env`:

| Variable              | Description             | Example                         |
| --------------------- | ----------------------- | ------------------------------- |
| `PUBLIC_URL`          | Your Jitsi Meet URL     | `https://meet.example.com`      |
| `LETSENCRYPT_DOMAIN`  | Domain for SSL cert     | `meet.example.com`              |
| `LETSENCRYPT_EMAIL`   | Email for Let's Encrypt | `admin@example.com`             |
| `DOCKER_HOST_ADDRESS` | Server public IP        | `192.168.1.100`                 |
| `ENABLE_AUTH`         | Enable authentication   | `0` (disabled) or `1` (enabled) |

### Nginx Configuration

The Nginx configuration in `nginx/conf.d/jitsi.conf` handles:

- SSL termination
- HTTP to HTTPS redirects
- WebSocket proxying
- Security headers
- Rate limiting

### Authentication (Optional)

To enable user authentication:

1. Set `ENABLE_AUTH=1` in `.env`
2. Restart services: `./scripts/manage.sh restart`
3. Create users via Prosody admin interface

## 🎯 cPanel/WHM Integration

### Subdomain Setup

1. **Create Subdomain in cPanel:**

   ```bash
   ./scripts/cpanel-integration.sh subdomain yourdomain.com meet
   ```

2. **DNS Configuration:**

   - Add A record: `meet.yourdomain.com` → `YOUR_SERVER_IP`
   - If using Cloudflare, set to "DNS only" mode

3. **Setup Monitoring Dashboard:**
   ```bash
   ./scripts/cpanel-integration.sh dashboard yourdomain.com
   ```

### Automatic Setup

```bash
# Complete cPanel integration
./scripts/cpanel-integration.sh subdomain yourdomain.com meet
./scripts/cpanel-integration.sh cron
./scripts/cpanel-integration.sh dashboard yourdomain.com
```

## 📊 Management

### Service Management

```bash
# Start services
./scripts/manage.sh start

# Stop services
./scripts/manage.sh stop

# Restart services
./scripts/manage.sh restart

# Check status
./scripts/manage.sh status

# View logs
./scripts/manage.sh logs

# Health check
./scripts/manage.sh health
```

### Maintenance

```bash
# Update images
./scripts/manage.sh update

# Backup configuration
./scripts/manage.sh backup

# Restore from backup
./scripts/manage.sh restore /path/to/backup.tar.gz

# Renew SSL certificates
./scripts/manage.sh ssl-renew

# Clean up Docker
./scripts/manage.sh cleanup
```

## 🔒 Security

### SSL Certificates

- Automatic Let's Encrypt certificates
- Auto-renewal via cron job
- HTTPS enforcement with HSTS

### Firewall Configuration

Required ports:

- `80/tcp` - HTTP (redirects to HTTPS)
- `443/tcp` - HTTPS
- `10000/udp` - JVB media
- `4443/tcp` - JVB fallback

### Security Headers

Nginx automatically adds:

- `Strict-Transport-Security`
- `X-Frame-Options`
- `X-Content-Type-Options`
- `X-XSS-Protection`
- `Referrer-Policy`

## 📈 Monitoring

### Admin Dashboard

Access the monitoring dashboard at:
`https://yourdomain.com/jitsi-admin/`

Default password: `jitsi2024!` (change this!)

Features:

- Service status monitoring
- System resource usage
- SSL certificate status
- Recent logs
- Service restart controls

### Health Checks

Automated health checks run every 15 minutes via cron:

- Service availability
- SSL certificate expiry
- System resources
- Disk space

### Log Management

Logs are automatically rotated and stored in:

- Nginx logs: `./logs/nginx/`
- System logs: `/var/log/jitsi-*.log`
- Docker logs: `docker-compose logs`

## 🔧 Troubleshooting

### Common Issues

1. **Services won't start:**

   ```bash
   # Check Docker status
   sudo systemctl status docker

   # Check logs
   ./scripts/manage.sh logs
   ```

2. **SSL certificate issues:**

   ```bash
   # Manually renew certificates
   ./scripts/manage.sh ssl-renew

   # Check certificate status
   openssl x509 -text -in ssl/fullchain.pem
   ```

3. **Connection issues:**

   ```bash
   # Check firewall
   sudo firewall-cmd --list-all

   # Test ports
   sudo netstat -tlnp | grep -E ':80|:443|:10000|:4443'
   ```

4. **Performance issues:**

   ```bash
   # Check resources
   ./scripts/manage.sh health

   # Monitor in real-time
   docker stats
   ```

### Debug Mode

Enable debug logging in `.env`:

```bash
ENABLE_TRANSCRIPTIONS=1
SENTRY_DSN=your_sentry_dsn
```

## 📁 Directory Structure

```
jitsi-meet/
├── docker-compose.yml          # Main Docker Compose file
├── .env                        # Environment configuration
├── nginx/                      # Nginx configuration
│   ├── nginx.conf
│   └── conf.d/jitsi.conf
├── scripts/                    # Management scripts
│   ├── install.sh             # Automated installation
│   ├── manage.sh              # Service management
│   └── cpanel-integration.sh  # cPanel integration
├── config/                     # Service configurations (auto-generated)
├── ssl/                        # SSL certificates
├── logs/                       # Log files
└── .github/
    └── copilot-instructions.md # AI assistant instructions
```

## 🔄 Updates

### Updating Jitsi Images

```bash
# Pull latest images and restart
./scripts/manage.sh update
```

### Updating Configuration

1. Modify configuration files
2. Restart affected services:
   ```bash
   ./scripts/manage.sh restart
   ```

## 🆘 Support

### Documentation

- [Jitsi Meet Handbook](https://jitsi.github.io/handbook/)
- [Docker Documentation](https://docs.docker.com/)

### Logs

Check logs for issues:

```bash
# All services
./scripts/manage.sh logs

# Specific service
docker-compose logs jitsi-web

# System logs
journalctl -u docker
```

### Community

- [Jitsi Community Forum](https://community.jitsi.org/)
- [GitHub Issues](https://github.com/jitsi/docker-jitsi-meet/issues)

## 📄 License

This project is based on the official Jitsi Meet Docker setup and follows the same licensing terms.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

**Note:** Remember to change default passwords and review security settings before production deployment!
