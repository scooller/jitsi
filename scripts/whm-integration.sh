#!/bin/bash

# Jitsi Meet WHM Integration Script
# Run this after configuring WHM/cPanel

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "=== Jitsi Meet WHM Integration ==="

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "Please run this script from the jitsi-meet directory"
    exit 1
fi

# Load environment variables
source .env

print_status "1. Stopping any existing containers..."
docker-compose down

print_status "2. Starting Jitsi services without Apache container..."
docker-compose up -d web prosody jicofo jvb watchtower

print_status "3. Waiting for services to start..."
sleep 10

print_status "4. Checking service status..."
docker-compose ps

print_status "5. Testing internal connectivity..."
if curl -f http://127.0.0.1:${HTTP_PORT:-8081} >/dev/null 2>&1; then
    print_status "✅ Jitsi web service is accessible on port ${HTTP_PORT:-8081}"
else
    print_warning "⚠️  Jitsi web service is not accessible on port ${HTTP_PORT:-8081}"
fi

if nc -z 127.0.0.1 5280 2>/dev/null; then
    print_status "✅ Prosody BOSH service is accessible on port 5280"
else
    print_warning "⚠️  Prosody BOSH service is not accessible on port 5280"
fi

print_status "6. Checking firewall status..."
if systemctl is-active --quiet firewalld; then
    print_status "Firewall is active. Checking rules..."
    firewall-cmd --list-ports | grep -q "10000/udp" && echo "✅ Port 10000/udp is open" || print_warning "⚠️  Port 10000/udp may not be open"
    firewall-cmd --list-ports | grep -q "4443/tcp" && echo "✅ Port 4443/tcp is open" || print_warning "⚠️  Port 4443/tcp may not be open"
else
    print_warning "Firewall is not active"
fi

print_status "7. Configuration files for WHM:"
echo "   - Pre VirtualHost Include: whm-configs/pre-virtualhost-include.conf"
echo "   - Virtual Host Config: whm-configs/virtualhost-config.conf"
echo "   - Setup Guide: whm-configs/WHM-SETUP-GUIDE.md"

print_status "8. Next steps:"
echo "   1. Configure WHM Apache with the provided configuration files"
echo "   2. Create subdomain 'meet.scooller.work.gd' in cPanel"
echo "   3. Set up SSL certificate (AutoSSL recommended)"
echo "   4. Test access to https://meet.scooller.work.gd"

print_status "=== Integration script completed ==="

# Show current service status
print_status "Current Docker services:"
docker-compose ps

print_status "Port usage check:"
netstat -tlnp | grep -E "(${HTTP_PORT:-8081}|5280|10000|4443)" || echo "No services found on expected ports"

print_status "For troubleshooting, check logs with:"
echo "   docker-compose logs -f web"
echo "   docker-compose logs -f prosody"
