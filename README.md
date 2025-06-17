# Jitsi Meet Docker Deployment for WHM/cPanel

A production-ready Jitsi Meet video conferencing solution using Docker, specifically designed for deployment on CentOS servers with WHM/cPanel environments using Apache as reverse proxy.

## 🚀 Features

- **Complete Docker Setup** - All services containerized with Docker Compose
- **Apache Reverse Proxy** - SSL termination and WebSocket support
- **WHM/cPanel Integration** - Pre-configured for shared hosting environments
- **SSL/HTTPS Support** - Works with existing SSL certificates
- **WebSocket Support** - Full real-time communication support
- **Production Ready** - Optimized for stability and performance
- **Easy Configuration** - Environment-based configuration
- **Health Checks** - Built-in monitoring for all services

## 📋 Prerequisites

- CentOS 7/8 server with root access
- WHM/cPanel with Apache
- Docker and Docker Compose installed
- Domain name with DNS configured
- SSL certificate configured in WHM/cPanel
- Minimum 2GB RAM, 2 CPU cores
- Open ports: 80, 443, 10000/udp, 4443/tcp

## 🛠 Installation

### 1. Clone Repository

```bash
git clone https://github.com/your-username/jitsi-meet-docker.git /opt/jitsi-meet
cd /opt/jitsi-meet
```

### 2. Configure Environment

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```bash
# Basic configuration
PUBLIC_URL=https://meet.yourdomain.com
LETSENCRYPT_DOMAIN=meet.yourdomain.com
LETSENCRYPT_EMAIL=admin@yourdomain.com
DOCKER_HOST_ADDRESS=YOUR_SERVER_IP

# Generate secure passwords
JVB_AUTH_PASSWORD=$(openssl rand -hex 16)
JICOFO_AUTH_PASSWORD=$(openssl rand -hex 16)
JICOFO_COMPONENT_SECRET=$(openssl rand -hex 16)
```

### 3. WHM/cPanel Configuration

#### Configure Apache Virtual Host

In WHM, add this configuration to your domain's "Pre VirtualHost Include":

```apache
# Load required modules
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
LoadModule headers_module modules/mod_headers.so
LoadModule rewrite_module modules/mod_rewrite.so

# Enable directory features for rewrite rules
<Directory "/home/yourdomain/public_html">
    Options FollowSymLinks
    AllowOverride All
</Directory>

# WebSocket proxy configuration
<Location "/xmpp-websocket">
    ProxyPass ws://127.0.0.1:5280/xmpp-websocket
    ProxyPassReverse ws://127.0.0.1:5280/xmpp-websocket
    ProxyPreserveHost On
    # Headers for WebSocket
    Header always set Access-Control-Allow-Origin "*"
    Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS"
    Header always set Access-Control-Allow-Headers "Content-Type, Sec-WebSocket-Key, Sec-WebSocket-Version, Sec-WebSocket-Protocol, Upgrade, Connection"
</Location>

# BOSH proxy configuration
<Location "/http-bind">
    ProxyPass http://127.0.0.1:5280/http-bind
    ProxyPassReverse http://127.0.0.1:5280/http-bind
    ProxyPreserveHost On
    Header always set Access-Control-Allow-Origin "*"
    Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS"
    Header always set Access-Control-Allow-Headers "Content-Type, Authorization"
</Location>

# Main application proxy
<Location "/">
    ProxyPass http://127.0.0.1:8081/
    ProxyPassReverse http://127.0.0.1:8081/
    ProxyPreserveHost On
    # Security headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</Location>
```

### 4. Start Services

```bash
# Start all Jitsi Meet services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 5. Firewall Configuration

```bash
# Open required ports
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=10000/udp
firewall-cmd --permanent --add-port=4443/tcp
firewall-cmd --reload
```

## � Configuration

### Docker Services

The deployment includes these services:

- **jitsi-web** - Frontend web interface (port 8081)
- **prosody** - XMPP server for signaling (port 5280)
- **jicofo** - Jitsi Conference Focus component
- **jvb** - Jitsi Videobridge for media routing (port 10000/udp)

### Environment Variables

Key configuration options in `.env`:

```bash
# Domain configuration
PUBLIC_URL=https://meet.yourdomain.com
XMPP_BOSH_URL_BASE=https://meet.yourdomain.com/http-bind

# Security
JVB_AUTH_PASSWORD=your-secure-password
JICOFO_AUTH_PASSWORD=your-secure-password
JICOFO_COMPONENT_SECRET=your-secret-key

# Network settings
HTTP_PORT=8081
DOCKER_HOST_ADDRESS=your.server.ip.address

# Features
ENABLE_PREJOINPAGE=1
ENABLE_WELCOME_PAGE=1
ENABLE_GUESTS=1
ENABLE_AUTH=0
```

## 🎯 Usage

1. **Access the Interface**: Navigate to `https://meet.yourdomain.com`
2. **Create Room**: Enter a room name and click "Go"
3. **Join Meeting**: Allow camera/microphone permissions
4. **Share Link**: Copy the URL to invite participants

## � Troubleshooting

### Check Service Health

```bash
# Check all containers
docker-compose ps

# Check specific service logs
docker-compose logs jitsi-web
docker-compose logs prosody
docker-compose logs jvb
docker-compose logs jicofo

# Test endpoints
curl -I https://meet.yourdomain.com/
curl -I https://meet.yourdomain.com/http-bind
curl -I https://meet.yourdomain.com/xmpp-websocket
```

### Common Issues

1. **WebSocket Connection Failed**

   - Verify Apache proxy_wstunnel module is loaded
   - Check firewall allows port 5280
   - Ensure proper WebSocket headers in Apache config

2. **Cannot Join Meeting**

   - Verify DOCKER_HOST_ADDRESS is your public IP
   - Check UDP port 10000 is open
   - Confirm JVB service is running

3. **SSL Certificate Issues**
   - Ensure SSL is properly configured in WHM/cPanel
   - Verify HTTPS redirect is working
   - Check certificate expiration

### Debug Mode

Enable debug logging:

```bash
# Edit docker-compose.yml and add to web service environment:
ENABLE_XMPP_WEBSOCKET_DEBUG=1
XMPP_BOSH_URL_BASE_DEBUG=1

# Restart services
docker-compose restart
```

## � Monitoring

### Health Checks

All services include health checks that can be monitored:

```bash
# Check health status
docker-compose ps
docker inspect --format='{{.State.Health.Status}}' jitsi_jitsi-web_1
```

### Performance Monitoring

- Monitor CPU/RAM usage: `docker stats`
- Check network connections: `netstat -tulpn | grep -E '(8081|5280|10000|4443)'`
- Apache access logs: `/usr/local/apache/logs/access_log`

## 🔐 Security

### Security Features

- HTTPS enforcement with Apache SSL termination
- CORS headers properly configured
- Container isolation with Docker
- No root processes in containers
- Secure random password generation

### Recommended Security Practices

1. **Regular Updates**: Keep Docker images updated
2. **Access Control**: Implement authentication if needed
3. **Firewall**: Restrict access to necessary ports only
4. **Monitoring**: Set up log monitoring and alerts
5. **Backups**: Regular configuration backups

## � Production Deployment

### Performance Optimization

For production environments:

```bash
# Increase Docker memory limits in docker-compose.yml
services:
  jvb:
    environment:
      - JVB_XMX=3072m
      - JVB_XMS=3072m
```

### Scaling

For larger deployments:

- Deploy multiple JVB instances
- Use external database for Prosody
- Implement load balancing
- Use dedicated STUN/TURN servers

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support and questions:

- 📧 Email: support@yourdomain.com
- 📝 Issues: [GitHub Issues](https://github.com/your-username/jitsi-meet-docker/issues)
- � Wiki: [Project Wiki](https://github.com/your-username/jitsi-meet-docker/wiki)

## 🙏 Acknowledgments

- [Jitsi Meet](https://jitsi.org/jitsi-meet/) - The core video conferencing platform
- [Docker](https://www.docker.com/) - Containerization platform
- [Apache HTTP Server](https://httpd.apache.org/) - Web server and reverse proxy

4. Push to the branch
5. Create a Pull Request

---

**Note:** Remember to change default passwords and review security settings before production deployment!
