<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Jitsi Meet Docker Project Instructions

This project is a complete Jitsi Meet video conferencing solution deployed using Docker containers, specifically designed for deployment on CentOS servers with WHM/cPanel environments.

## Project Structure

- `docker-compose.yml` - Main Docker Compose configuration for all Jitsi services
- `.env` - Environment variables for configuration
- `apache/` - Apache reverse proxy configuration with SSL support
- `scripts/` - Deployment and management scripts for CentOS/WHM
- Configuration volumes are mounted from `./config/` directory

## Key Components

1. **Jitsi Web** - Frontend web interface (port 8080 internal)
2. **Prosody** - XMPP server for signaling
3. **Jicofo** - Jitsi Conference Focus component
4. **JVB** - Jitsi Videobridge for media routing
5. **Apache** - Reverse proxy with SSL termination
6. **Certbot** - Automatic SSL certificate management

## Deployment Environment

- Target OS: CentOS with WHM/cPanel
- Production-ready with SSL, monitoring, and backup features
- Includes firewall configuration and security hardening
- Supports both subdomain and main domain deployments

## Configuration Guidelines

- Always use environment variables for sensitive data
- SSL certificates are automatically managed via Let's Encrypt
- Firewall ports: 80, 443, 10000/udp, 4443/tcp
- All logs are centralized in `./logs/` directory

## Security Features

- HTTPS enforcement with HSTS
- Security headers configuration
- Rate limiting for API endpoints
- Automated SSL certificate renewal
- Docker container isolation

## Management

Use the provided scripts in `scripts/` directory:

- `install.sh` - Complete installation automation
- `manage.sh` - Service management operations
- `cpanel-integration.sh` - WHM/cPanel specific integration

## Monitoring

- Built-in health checks for all services
- Automated monitoring scripts with cron jobs
- Web-based admin dashboard with PHP
- Log rotation and cleanup automation
