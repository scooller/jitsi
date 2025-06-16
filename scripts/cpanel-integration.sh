#!/bin/bash

# WHM/cPanel Integration Script for Jitsi Meet
# This script helps integrate Jitsi Meet with WHM/cPanel environments

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

# Function to create subdomain in cPanel
create_subdomain() {
    local DOMAIN="$1"
    local SUBDOMAIN="$2"
    
    print_status "Creating subdomain $SUBDOMAIN.$DOMAIN in cPanel..."
    
    # This would typically use cPanel API
    # For now, we'll provide manual instructions
    cat << EOF

Manual cPanel Configuration Required:
=====================================

1. Log into cPanel
2. Go to "Subdomains" section
3. Create subdomain: $SUBDOMAIN
4. Set document root to: /home/[username]/public_html/$SUBDOMAIN
5. Add the following DNS records in cPanel DNS Zone Editor:

   A Record: $SUBDOMAIN.${DOMAIN} -> [SERVER_IP]

6. If using Cloudflare, add these records:
   - Type: A
   - Name: $SUBDOMAIN
   - Content: [SERVER_IP]
   - Proxy: DNS only (gray cloud)

EOF
}

# Function to setup reverse proxy in .htaccess
setup_htaccess_proxy() {
    local SUBDOMAIN="$1"
    local DOMAIN="$2"
    local DOCROOT="/home/$(whoami)/public_html/$SUBDOMAIN"
    
    print_status "Setting up .htaccess reverse proxy..."
    
    mkdir -p "$DOCROOT"
    
    cat > "$DOCROOT/.htaccess" << EOF
# Jitsi Meet Reverse Proxy Configuration
RewriteEngine On

# Enable proxy module
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so

# Proxy all requests to Jitsi Meet Docker container
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ http://localhost:8080/$1 [P,L]

# Set proxy headers
ProxyPreserveHost On
ProxyPass / http://localhost:8080/
ProxyPassReverse / http://localhost:8080/

# WebSocket support
RewriteCond %{HTTP:Upgrade} websocket [NC]
RewriteCond %{HTTP:Connection} upgrade [NC]
RewriteRule ^/?(.*) "ws://localhost:8080/$1" [P,L]

# Security headers
Header always set X-Frame-Options SAMEORIGIN
Header always set X-Content-Type-Options nosniff
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"

# CORS headers for Jitsi
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE"
Header always set Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range"

# Compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# Cache static content
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType image/png "access plus 1 month"
    ExpiresByType image/jpg "access plus 1 month"
    ExpiresByType image/jpeg "access plus 1 month"
    ExpiresByType image/gif "access plus 1 month"
    ExpiresByType image/ico "access plus 1 month"
    ExpiresByType image/icon "access plus 1 month"
    ExpiresByType text/ico "access plus 1 month"
    ExpiresByType application/ico "access plus 1 month"
</IfModule>
EOF

    print_status ".htaccess reverse proxy configured at $DOCROOT"
}

# Function to create cPanel cron jobs
setup_cron_jobs() {
    print_status "Setting up cron jobs for maintenance..."
    
    # Add SSL renewal cron job
    (crontab -l 2>/dev/null; echo "0 3 * * * cd /opt/jitsi-meet && ./scripts/manage.sh ssl-renew") | crontab -
    
    # Add health check cron job
    (crontab -l 2>/dev/null; echo "*/15 * * * * cd /opt/jitsi-meet && ./scripts/manage.sh health >> /var/log/jitsi-health.log") | crontab -
    
    # Add cleanup cron job (weekly)
    (crontab -l 2>/dev/null; echo "0 2 * * 0 cd /opt/jitsi-meet && ./scripts/manage.sh cleanup") | crontab -
    
    print_status "Cron jobs configured successfully"
}

# Function to setup log rotation
setup_log_rotation() {
    print_status "Setting up log rotation..."
    
    cat > /etc/logrotate.d/jitsi-meet << EOF
/opt/jitsi-meet/logs/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    copytruncate
    postrotate
        docker-compose -f /opt/jitsi-meet/docker-compose.yml restart nginx
    endscript
}

/var/log/jitsi-*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

    print_status "Log rotation configured"
}

# Function to create monitoring dashboard
create_monitoring_dashboard() {
    local DOMAIN="$1"
    local DOCROOT="/home/$(whoami)/public_html/jitsi-admin"
    
    print_status "Creating monitoring dashboard..."
    
    mkdir -p "$DOCROOT"
    
    cat > "$DOCROOT/index.php" << 'EOF'
<?php
// Jitsi Meet Monitoring Dashboard
session_start();

// Simple authentication
$admin_password = 'jitsi2024!'; // Change this password!

if (isset($_POST['password'])) {
    if ($_POST['password'] === $admin_password) {
        $_SESSION['authenticated'] = true;
    } else {
        $error = 'Invalid password';
    }
}

if (!isset($_SESSION['authenticated']) || $_SESSION['authenticated'] !== true) {
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>Jitsi Meet Admin</title>
        <style>
            body { font-family: Arial, sans-serif; background: #f0f0f0; margin: 0; padding: 50px; }
            .login-form { max-width: 300px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            input[type="password"] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 5px; }
            button { width: 100%; padding: 10px; background: #007cba; color: white; border: none; border-radius: 5px; cursor: pointer; }
            .error { color: red; margin-top: 10px; }
        </style>
    </head>
    <body>
        <div class="login-form">
            <h2>Jitsi Meet Admin Login</h2>
            <form method="post">
                <input type="password" name="password" placeholder="Enter password" required>
                <button type="submit">Login</button>
                <?php if (isset($error)) echo "<div class='error'>$error</div>"; ?>
            </form>
        </div>
    </body>
    </html>
    <?php
    exit;
}

// Get system information
function getSystemInfo() {
    $info = [];
    
    // Docker status
    $info['docker_status'] = shell_exec('cd /opt/jitsi-meet && docker-compose ps 2>/dev/null') ?: 'Error getting status';
    
    // Disk usage
    $info['disk_usage'] = shell_exec('df -h / | tail -n 1') ?: 'Error getting disk usage';
    
    // Memory usage
    $info['memory_usage'] = shell_exec('free -m | head -n 2 | tail -n 1') ?: 'Error getting memory usage';
    
    // Load average
    $info['load_average'] = shell_exec('uptime') ?: 'Error getting load average';
    
    // SSL cert info
    if (file_exists('/opt/jitsi-meet/ssl/fullchain.pem')) {
        $info['ssl_expiry'] = shell_exec('openssl x509 -enddate -noout -in /opt/jitsi-meet/ssl/fullchain.pem 2>/dev/null') ?: 'Error checking SSL';
    } else {
        $info['ssl_expiry'] = 'SSL certificate not found';
    }
    
    return $info;
}

$info = getSystemInfo();

// Handle actions
if (isset($_GET['action'])) {
    switch ($_GET['action']) {
        case 'restart':
            shell_exec('cd /opt/jitsi-meet && ./scripts/manage.sh restart > /dev/null 2>&1 &');
            $message = 'Services restart initiated';
            break;
        case 'logs':
            $logs = shell_exec('cd /opt/jitsi-meet && docker-compose logs --tail=50 2>/dev/null');
            break;
        case 'logout':
            session_destroy();
            header('Location: index.php');
            exit;
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Jitsi Meet Admin Dashboard</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 0; background: #f5f5f5; }
        .header { background: #007cba; color: white; padding: 15px; display: flex; justify-content: space-between; align-items: center; }
        .container { max-width: 1200px; margin: 20px auto; padding: 0 20px; }
        .card { background: white; border-radius: 8px; padding: 20px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status { display: inline-block; padding: 5px 10px; border-radius: 20px; color: white; font-size: 12px; }
        .status.running { background: #28a745; }
        .status.stopped { background: #dc3545; }
        .actions { margin: 20px 0; }
        .btn { display: inline-block; padding: 10px 20px; background: #007cba; color: white; text-decoration: none; border-radius: 5px; margin-right: 10px; }
        .btn:hover { background: #005a8b; }
        .logs { background: #000; color: #00ff00; padding: 15px; border-radius: 5px; font-family: monospace; font-size: 12px; max-height: 400px; overflow-y: auto; }
        pre { white-space: pre-wrap; word-wrap: break-word; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Jitsi Meet Admin Dashboard</h1>
        <div>
            <a href="?action=logout" class="btn">Logout</a>
        </div>
    </div>
    
    <div class="container">
        <?php if (isset($message)): ?>
            <div class="card" style="background: #d4edda; color: #155724; border: 1px solid #c3e6cb;">
                <?php echo htmlspecialchars($message); ?>
            </div>
        <?php endif; ?>
        
        <div class="card">
            <h3>Service Status</h3>
            <pre><?php echo htmlspecialchars($info['docker_status']); ?></pre>
        </div>
        
        <div class="card">
            <h3>System Resources</h3>
            <p><strong>Disk Usage:</strong> <?php echo htmlspecialchars($info['disk_usage']); ?></p>
            <p><strong>Memory Usage:</strong> <?php echo htmlspecialchars($info['memory_usage']); ?></p>
            <p><strong>Load Average:</strong> <?php echo htmlspecialchars($info['load_average']); ?></p>
        </div>
        
        <div class="card">
            <h3>SSL Certificate</h3>
            <p><?php echo htmlspecialchars($info['ssl_expiry']); ?></p>
        </div>
        
        <div class="actions">
            <a href="?action=restart" class="btn" onclick="return confirm('Are you sure you want to restart services?')">Restart Services</a>
            <a href="?action=logs" class="btn">View Logs</a>
        </div>
        
        <?php if (isset($logs)): ?>
        <div class="card">
            <h3>Recent Logs</h3>
            <div class="logs">
                <pre><?php echo htmlspecialchars($logs); ?></pre>
            </div>
        </div>
        <?php endif; ?>
    </div>
</body>
</html>
EOF

    print_status "Monitoring dashboard created at http://$DOMAIN/jitsi-admin/"
    print_warning "Default password is 'jitsi2024!' - Please change it in the dashboard file!"
}

# Function to show cPanel integration instructions
show_cpanel_instructions() {
    cat << EOF

===========================================
cPanel/WHM Integration Instructions
===========================================

1. DNS Configuration:
   - In cPanel DNS Zone Editor, add A record: meet -> [SERVER_IP]
   - If using Cloudflare, set to "DNS only" (gray cloud)

2. Subdomain Setup:
   - Create subdomain 'meet' in cPanel
   - Document root: /home/[username]/public_html/meet

3. Proxy Configuration:
   - Upload the generated .htaccess file to subdomain directory
   - Ensure mod_proxy is enabled in Apache

4. SSL Certificate:
   - Let's Encrypt will automatically generate certificates
   - Or use cPanel SSL/TLS section for custom certificates

5. Security:
   - Configure firewall to allow ports 80, 443, 10000/udp, 4443
   - Consider using Cloudflare for DDoS protection

6. Monitoring:
   - Access admin dashboard at: http://yourdomain.com/jitsi-admin/
   - Check cron jobs in cPanel Cron Jobs section

7. Backup:
   - Include /opt/jitsi-meet in your server backup routine
   - Use the backup script: ./scripts/manage.sh backup

For support: https://jitsi.github.io/handbook/

EOF
}

# Main function
main() {
    if [ "$#" -eq 0 ]; then
        show_cpanel_instructions
        exit 0
    fi
    
    case "$1" in
        subdomain)
            if [ "$#" -ne 3 ]; then
                print_error "Usage: $0 subdomain <domain> <subdomain>"
                exit 1
            fi
            create_subdomain "$2" "$3"
            setup_htaccess_proxy "$3" "$2"
            ;;
        cron)
            setup_cron_jobs
            ;;
        logrotate)
            setup_log_rotation
            ;;
        dashboard)
            if [ "$#" -ne 2 ]; then
                print_error "Usage: $0 dashboard <domain>"
                exit 1
            fi
            create_monitoring_dashboard "$2"
            ;;
        *)
            print_error "Unknown command: $1"
            show_cpanel_instructions
            exit 1
            ;;
    esac
}

main "$@"
EOF
