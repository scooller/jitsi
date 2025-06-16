#!/bin/bash

# Jitsi Meet Docker Setup Script for CentOS with WHM/cPanel
# This script automates the installation and configuration of Jitsi Meet using Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN=""
EMAIL=""
DOCKER_HOST_IP=""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to get user input
get_user_input() {
    read -p "Enter your domain name (e.g., meet.yourdomain.com): " DOMAIN
    read -p "Enter your email address: " EMAIL
    read -p "Enter your server's public IP address: " DOCKER_HOST_IP
    
    if [[ -z "$DOMAIN" || -z "$EMAIL" || -z "$DOCKER_HOST_IP" ]]; then
        print_error "All fields are required!"
        exit 1
    fi
}

# Function to update system
update_system() {
    print_status "Updating system packages..."
    yum update -y
    yum install -y epel-release
    yum install -y curl wget git unzip
}

# Function to install Docker
install_docker() {
    print_status "Installing Docker..."
    
    # Remove old versions
    yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    
    # Install Docker CE
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add user to docker group (optional, for non-root usage)
    # usermod -aG docker $USER
    
    print_status "Docker installed successfully"
}

# Function to install Docker Compose
install_docker_compose() {
    print_status "Installing Docker Compose..."
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    # Download and install
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    print_status "Docker Compose installed successfully"
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Install firewalld if not installed
    yum install -y firewalld
    systemctl start firewalld
    systemctl enable firewalld
    
    # Open required ports
    firewall-cmd --permanent --zone=public --add-port=80/tcp
    firewall-cmd --permanent --zone=public --add-port=443/tcp
    firewall-cmd --permanent --zone=public --add-port=10000/udp
    firewall-cmd --permanent --zone=public --add-port=4443/tcp
    
    # Reload firewall
    firewall-cmd --reload
    
    print_status "Firewall configured successfully"
}

# Function to setup directories
setup_directories() {
    print_status "Setting up directories..."
    
    mkdir -p /opt/jitsi-meet
    mkdir -p /opt/jitsi-meet/config/{web,prosody,jicofo,jvb}
    mkdir -p /opt/jitsi-meet/ssl
    mkdir -p /opt/jitsi-meet/logs/apache
    mkdir -p /opt/jitsi-meet/ssl-challenge
    
    # Set permissions
    chmod -R 755 /opt/jitsi-meet
    
    print_status "Directories created successfully"
}

# Function to configure environment
configure_environment() {
    print_status "Configuring environment variables..."
    
    # Update .env file
    sed -i "s/meet.yourdomain.com/${DOMAIN}/g" .env
    sed -i "s/admin@yourdomain.com/${EMAIL}/g" .env
    sed -i "s/192.168.1.1/${DOCKER_HOST_IP}/g" .env
    
    # Update apache configuration
    sed -i "s/meet.yourdomain.com/${DOMAIN}/g" apache/conf.d/jitsi.conf
    
    print_status "Environment configured successfully"
}

# Function to generate SSL certificates
generate_ssl_certificates() {
    print_status "Generating SSL certificates..."
    
    # Start apache first for Let's Encrypt challenge
    docker-compose up -d apache
    sleep 10
    
    # Generate certificates
    docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email $EMAIL --agree-tos --no-eff-email --force-renewal -d $DOMAIN
    
    # Copy certificates to apache location
    docker cp jitsi-certbot:/etc/letsencrypt/live/$DOMAIN/fullchain.pem ./ssl/
    docker cp jitsi-certbot:/etc/letsencrypt/live/$DOMAIN/privkey.pem ./ssl/
    
    print_status "SSL certificates generated successfully"
}

# Function to start services
start_services() {
    print_status "Starting Jitsi Meet services..."
    
    # Start all services
    docker-compose up -d
    
    # Wait for services to start
    sleep 30
    
    # Check if services are running
    docker-compose ps
    
    print_status "Jitsi Meet services started successfully"
}

# Function to setup SSL renewal
setup_ssl_renewal() {
    print_status "Setting up SSL certificate renewal..."
    
    # Create renewal script
    cat > /etc/cron.d/jitsi-ssl-renewal << EOF
0 3 * * * root cd /opt/jitsi-meet && docker-compose run --rm certbot renew --quiet && docker-compose restart apache
EOF
    
    print_status "SSL renewal cron job created"
}

# Function to create monitoring script
create_monitoring_script() {
    print_status "Creating monitoring script..."
    
    cat > /opt/jitsi-meet/monitor.sh << 'EOF'
#!/bin/bash

# Jitsi Meet Monitoring Script
LOGFILE="/var/log/jitsi-monitor.log"
HEALTHCHECK_URL="https://localhost/health"

check_services() {
    echo "$(date): Checking Jitsi Meet services..." >> $LOGFILE
    
    # Check if all containers are running
    if ! docker-compose ps | grep -q "Up"; then
        echo "$(date): Some services are down, restarting..." >> $LOGFILE
        docker-compose restart
    fi
    
    # Check web service health
    if ! curl -f -s $HEALTHCHECK_URL > /dev/null; then
        echo "$(date): Web service health check failed, restarting apache..." >> $LOGFILE
        docker-compose restart apache
    fi
    
    echo "$(date): Health check completed" >> $LOGFILE
}

check_services
EOF
    
    chmod +x /opt/jitsi-meet/monitor.sh
    
    # Add to cron
    echo "*/5 * * * * root /opt/jitsi-meet/monitor.sh" > /etc/cron.d/jitsi-monitor
    
    print_status "Monitoring script created"
}

# Function to display final information
display_final_info() {
    print_status "Installation completed successfully!"
    echo ""
    echo "=============================================="
    echo "Jitsi Meet is now running on: https://$DOMAIN"
    echo "=============================================="
    echo ""
    echo "Management Commands:"
    echo "- Start services: docker-compose up -d"
    echo "- Stop services: docker-compose down"
    echo "- View logs: docker-compose logs -f"
    echo "- Restart services: docker-compose restart"
    echo ""
    echo "Configuration files are located in:"
    echo "- Main config: /opt/jitsi-meet/.env"
    echo "- Apache config: /opt/jitsi-meet/apache/"
    echo "- SSL certificates: /opt/jitsi-meet/ssl/"
    echo ""
    echo "For support, check the logs or visit: https://jitsi.github.io/handbook/"
}

# Main execution
main() {
    print_status "Starting Jitsi Meet installation..."
    
    check_root
    get_user_input
    update_system
    install_docker
    install_docker_compose
    configure_firewall
    setup_directories
    configure_environment
    generate_ssl_certificates
    start_services
    setup_ssl_renewal
    create_monitoring_script
    display_final_info
}

# Run main function
main "$@"
