#!/bin/bash

# SSL Setup Script for Jitsi Meet
# Run this after the initial deployment is working

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

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "Please run this script from the jitsi-meet directory"
    exit 1
fi

print_status "Setting up SSL certificates for Jitsi Meet..."

# Load environment variables
source .env

# Verify domain is accessible
print_status "Testing domain accessibility..."
if ! curl -f http://${LETSENCRYPT_DOMAIN} >/dev/null 2>&1; then
    print_warning "Domain ${LETSENCRYPT_DOMAIN} is not accessible via HTTP"
    read -p "Do you want to continue anyway? (y/N): " continue_setup
    if [[ $continue_setup != "y" && $continue_setup != "Y" ]]; then
        print_error "SSL setup cancelled"
        exit 1
    fi
fi

# Step 1: Get SSL certificate using certbot
print_status "Obtaining SSL certificate..."

# Enable certbot in docker-compose.yml
sed -i 's/# certbot:/certbot:/g' docker-compose.yml
sed -i 's/#     /    /g' docker-compose.yml

# Run certbot to get certificate
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${LETSENCRYPT_EMAIL} \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d ${LETSENCRYPT_DOMAIN}

if [[ $? -eq 0 ]]; then
    print_status "SSL certificate obtained successfully!"
else
    print_error "Failed to obtain SSL certificate"
    exit 1
fi

# Step 2: Enable SSL configuration
print_status "Enabling SSL configuration..."

# Backup current config and enable SSL version
mv apache/conf.d/jitsi-temp.conf apache/conf.d/jitsi-temp.conf.bak
mv apache/conf.d/jitsi.conf.ssl apache/conf.d/jitsi.conf

# Step 3: Update environment for SSL
print_status "Updating environment for SSL..."
sed -i 's/DISABLE_HTTPS=1/DISABLE_HTTPS=0/g' .env
sed -i 's|PUBLIC_URL=http://|PUBLIC_URL=https://|g' .env

# Step 4: Restart services
print_status "Restarting services with SSL..."
docker-compose restart apache
docker-compose restart web

# Step 5: Set up certificate renewal
print_status "Setting up automatic certificate renewal..."
(crontab -l 2>/dev/null; echo "0 3 * * * cd /opt/jitsi-meet && docker-compose run --rm certbot renew --quiet && docker-compose restart apache") | crontab -

print_status "SSL setup completed successfully!"
print_status "Your Jitsi Meet instance is now available at: https://${LETSENCRYPT_DOMAIN}"

# Test the SSL setup
print_status "Testing SSL setup..."
sleep 5
if curl -f https://${LETSENCRYPT_DOMAIN} >/dev/null 2>&1; then
    print_status "SSL is working correctly!"
else
    print_warning "SSL test failed, please check the configuration manually"
fi

print_status "Setup complete! You can now use your Jitsi Meet instance."
