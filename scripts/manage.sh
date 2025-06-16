#!/bin/bash

# Jitsi Meet Management Script
# This script provides common management operations for Jitsi Meet Docker deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to show usage
show_usage() {
    echo "Jitsi Meet Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start all Jitsi Meet services"
    echo "  stop        Stop all Jitsi Meet services"
    echo "  restart     Restart all Jitsi Meet services"
    echo "  status      Show status of all services"
    echo "  logs        Show logs from all services"
    echo "  update      Update all service images"
    echo "  backup      Create backup of configuration"
    echo "  restore     Restore configuration from backup"
    echo "  ssl-renew   Manually renew SSL certificates"
    echo "  cleanup     Clean up unused Docker images and volumes"
    echo "  health      Perform health check"
    echo "  help        Show this help message"
}

# Function to start services
start_services() {
    print_status "Starting Jitsi Meet services..."
    docker-compose up -d
    sleep 10
    docker-compose ps
    print_status "Services started successfully"
}

# Function to stop services
stop_services() {
    print_status "Stopping Jitsi Meet services..."
    docker-compose down
    print_status "Services stopped successfully"
}

# Function to restart services
restart_services() {
    print_status "Restarting Jitsi Meet services..."
    docker-compose restart
    sleep 10
    docker-compose ps
    print_status "Services restarted successfully"
}

# Function to show status
show_status() {
    print_header "=== Jitsi Meet Services Status ==="
    docker-compose ps
    echo ""
    print_header "=== Docker System Status ==="
    docker system df
}

# Function to show logs
show_logs() {
    if [ -n "$2" ]; then
        print_status "Showing logs for service: $2"
        docker-compose logs -f "$2"
    else
        print_status "Showing logs for all services..."
        docker-compose logs -f
    fi
}

# Function to update images
update_images() {
    print_status "Updating Jitsi Meet images..."
    docker-compose pull
    docker-compose up -d
    print_status "Images updated successfully"
}

# Function to backup configuration
backup_config() {
    BACKUP_DIR="/opt/jitsi-backup-$(date +%Y%m%d-%H%M%S)"
    print_status "Creating backup in $BACKUP_DIR..."
    
    mkdir -p "$BACKUP_DIR"
    cp -r config "$BACKUP_DIR/"
    cp -r ssl "$BACKUP_DIR/"
    cp .env "$BACKUP_DIR/"
    cp docker-compose.yml "$BACKUP_DIR/"
    cp -r apache "$BACKUP_DIR/"
    
    tar -czf "$BACKUP_DIR.tar.gz" -C "$(dirname $BACKUP_DIR)" "$(basename $BACKUP_DIR)"
    rm -rf "$BACKUP_DIR"
    
    print_status "Backup created: $BACKUP_DIR.tar.gz"
}

# Function to restore configuration
restore_config() {
    if [ -z "$2" ]; then
        print_error "Please specify backup file: $0 restore /path/to/backup.tar.gz"
        exit 1
    fi
    
    BACKUP_FILE="$2"
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    print_warning "This will overwrite current configuration. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    print_status "Stopping services..."
    docker-compose down
    
    print_status "Restoring configuration from $BACKUP_FILE..."
    TEMP_DIR="/tmp/jitsi-restore-$$"
    mkdir -p "$TEMP_DIR"
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
    
    # Find the backup directory
    BACKUP_DIR=$(find "$TEMP_DIR" -type d -name "jitsi-backup-*" | head -1)
    
    if [ -z "$BACKUP_DIR" ]; then
        print_error "Invalid backup file format"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Restore files
    cp -r "$BACKUP_DIR"/* .
    rm -rf "$TEMP_DIR"
    
    print_status "Starting services..."
    docker-compose up -d
    
    print_status "Configuration restored successfully"
}

# Function to renew SSL certificates
renew_ssl() {
    print_status "Renewing SSL certificates..."
    docker-compose run --rm certbot renew
    docker-compose restart apache
    print_status "SSL certificates renewed successfully"
}

# Function to cleanup Docker
cleanup_docker() {
    print_status "Cleaning up Docker system..."
    docker system prune -f
    docker volume prune -f
    docker image prune -f
    print_status "Docker cleanup completed"
}

# Function to perform health check
health_check() {
    print_header "=== Jitsi Meet Health Check ==="
    
    # Check if services are running
    print_status "Checking service status..."
    if docker-compose ps | grep -q "Up"; then
        print_status "✓ Services are running"
    else
        print_error "✗ Some services are not running"
    fi
    
    # Check web service
    print_status "Checking web service..."
    if curl -f -s http://localhost/health > /dev/null 2>&1; then
        print_status "✓ Web service is responding"
    else
        print_warning "⚠ Web service health check failed"
    fi
    
    # Check disk space
    print_status "Checking disk space..."
    df -h / | tail -n 1 | awk '{
        usage = $5
        gsub(/%/, "", usage)
        if (usage > 80) {
            print "⚠ Disk usage is high: " usage "%"
        } else {
            print "✓ Disk usage is normal: " usage "%"
        }
    }'
    
    # Check memory usage
    print_status "Checking memory usage..."
    free -m | awk 'NR==2{
        usage = $3*100/$2
        if (usage > 80) {
            print "⚠ Memory usage is high: " usage "%"
        } else {
            print "✓ Memory usage is normal: " usage "%"
        }
    }'
    
    # Check SSL certificate expiry
    print_status "Checking SSL certificate..."
    if [ -f "ssl/fullchain.pem" ]; then
        EXPIRY=$(openssl x509 -enddate -noout -in ssl/fullchain.pem | cut -d= -f2)
        EXPIRY_DATE=$(date -d "$EXPIRY" +%s)
        CURRENT_DATE=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_DATE - CURRENT_DATE) / 86400 ))
        
        if [ $DAYS_LEFT -lt 30 ]; then
            print_warning "⚠ SSL certificate expires in $DAYS_LEFT days"
        else
            print_status "✓ SSL certificate is valid for $DAYS_LEFT days"
        fi
    else
        print_warning "⚠ SSL certificate not found"
    fi
    
    print_header "=== Health Check Complete ==="
}

# Main script logic
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$@"
        ;;
    update)
        update_images
        ;;
    backup)
        backup_config
        ;;
    restore)
        restore_config "$@"
        ;;
    ssl-renew)
        renew_ssl
        ;;
    cleanup)
        cleanup_docker
        ;;
    health)
        health_check
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
