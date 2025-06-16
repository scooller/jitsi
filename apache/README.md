# Apache Configuration for Jitsi Meet

This directory contains the Apache HTTP Server configuration files for the Jitsi Meet Docker deployment.

## Structure

```
apache/
├── httpd.conf          # Main Apache configuration
└── conf.d/
    └── jitsi.conf      # Jitsi Meet virtual host configuration
```

## Key Features

### SSL/TLS Configuration

- Modern SSL protocols (TLS 1.2+)
- Strong cipher suites
- OCSP Stapling
- Perfect Forward Secrecy

### Security Headers

- HSTS (HTTP Strict Transport Security)
- Content Security Policy
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection

### Performance Optimizations

- Gzip/Deflate compression
- Static file caching
- HTTP/2 support (when available)
- Keep-alive connections

### Proxy Configuration

- Reverse proxy to Jitsi Web container
- WebSocket support for real-time communication
- BOSH (Bidirectional-streams Over Synchronous HTTP) support
- Load balancing capabilities

## Environment Variables

The following variables are used in the configuration:

- `JITSI_DOMAIN` - Your Jitsi Meet domain name
- `LETSENCRYPT_DOMAIN` - Domain for SSL certificates
- `LETSENCRYPT_EMAIL` - Email for Let's Encrypt notifications

## SSL Certificate Paths

Certificates are expected at:

- Certificate: `/etc/ssl/certs/live/${JITSI_DOMAIN}/fullchain.pem`
- Private Key: `/etc/ssl/certs/live/${JITSI_DOMAIN}/privkey.pem`

## Customization

### Adding Custom Headers

Add custom headers in the `<VirtualHost *:443>` section:

```apache
Header always set Custom-Header "Custom Value"
```

### Modifying Security Policies

Update the Content Security Policy in `jitsi.conf`:

```apache
Header always set Content-Security-Policy "default-src 'self'; ..."
```

### Performance Tuning

Adjust worker settings in `httpd.conf`:

```apache
<IfModule mpm_event_module>
    StartServers             4
    MinSpareThreads          100
    MaxSpareThreads          400
    ThreadsPerChild          50
    MaxRequestWorkers        800
</IfModule>
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Not Found**

   - Ensure Let's Encrypt certificates are properly generated
   - Check certificate paths in the configuration
   - Verify file permissions

2. **WebSocket Connection Fails**

   - Confirm `mod_proxy_wstunnel` is loaded
   - Check WebSocket proxy configuration
   - Verify firewall rules

3. **Performance Issues**
   - Enable compression for static files
   - Adjust worker process settings
   - Monitor resource usage

### Debug Commands

```bash
# Test Apache configuration syntax
docker exec jitsi-apache httpd -t

# View real-time error logs
docker logs -f jitsi-apache

# Check loaded modules
docker exec jitsi-apache httpd -M
```

## WHM/cPanel Integration

For servers with WHM/cPanel:

1. **Subdomain Setup**

   - Create subdomain in cPanel
   - Point to server IP
   - Update DNS records

2. **Port Management**

   - Ensure ports 80/443 are available
   - Configure firewall rules
   - Update WHM service settings

3. **SSL Management**
   - Use cPanel AutoSSL or manual certificates
   - Configure certificate paths
   - Set up automatic renewal

## Monitoring

### Health Checks

The configuration includes endpoints for monitoring:

- `/health` - Application health status
- `/metrics` - Performance metrics (if enabled)

### Log Files

- Access logs: `/usr/local/apache2/logs/jitsi_ssl_access.log`
- Error logs: `/usr/local/apache2/logs/jitsi_ssl_error.log`
- SSL logs: `/usr/local/apache2/logs/jitsi_ssl_request.log`

## Security Considerations

### Rate Limiting

Consider implementing rate limiting for API endpoints:

```apache
<LocationMatch "/(http-bind|xmpp-websocket)">
    # Add rate limiting configuration
</LocationMatch>
```

### ModSecurity

Enable ModSecurity for additional protection:

```apache
<IfModule mod_security2.c>
    SecRuleEngine On
    # Add custom rules
</IfModule>
```

### Firewall Integration

Ensure proper firewall configuration:

- Allow ports 80, 443 (HTTP/HTTPS)
- Allow port 10000/UDP (JVB)
- Allow port 4443/TCP (JVB fallback)

## Backup and Recovery

### Configuration Backup

```bash
# Backup Apache configuration
tar -czf apache-config-$(date +%Y%m%d).tar.gz apache/
```

### SSL Certificate Backup

```bash
# Backup SSL certificates
tar -czf ssl-certs-$(date +%Y%m%d).tar.gz ssl/
```

## Updates and Maintenance

### Updating Configuration

1. Edit configuration files
2. Test syntax: `docker exec jitsi-apache httpd -t`
3. Reload: `docker-compose restart apache`

### Certificate Renewal

Automatic renewal via cron job:

```bash
0 3 * * * cd /opt/jitsi-meet && docker-compose run --rm certbot renew --quiet && docker-compose restart apache 2>&1
```
