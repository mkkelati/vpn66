# VPN Manager for VLESS (WebSocket + TLS) with CDN

A comprehensive SSH script manager for creating and managing VLESS VPN servers with WebSocket + TLS support, designed to work with HTTP Injector and compatible with CDN services.

## Features

### Core Features
- ✅ **VLESS Protocol Support**: WebSocket + TLS configuration
- ✅ **CDN Compatibility**: Works with Cloudflare and other CDN services
- ✅ **HTTP Injector Support**: Generates compatible links for HTTP Injector
- ✅ **Client Management**: Create, list, and delete clients
- ✅ **Live Connection Monitoring**: Real-time connection tracking
- ✅ **Web Dashboard**: Beautiful web-based monitoring interface
- ✅ **SSL Certificate Management**: Automatic Let's Encrypt certificate installation
- ✅ **Port & Domain Management**: Flexible configuration options
- ✅ **Backup & Restore**: Configuration backup and restore functionality

### Advanced Features
- 🔄 **Auto-restart Services**: Automatic service management
- 📊 **Statistics Dashboard**: System and network statistics
- 🔒 **Firewall Configuration**: Automatic UFW setup
- 📝 **Comprehensive Logging**: Detailed activity logs
- 🎨 **Modern UI**: Bootstrap-based web interface
- ⚡ **Real-time Updates**: Live data refresh every 5 seconds

## System Requirements

- **OS**: Ubuntu 22.04+ (recommended)
- **Architecture**: 64-bit
- **RAM**: Minimum 512MB (1GB+ recommended)
- **Storage**: 10GB+ free space
- **Network**: Public IP address
- **Domain**: A domain name pointing to your server

## Installation

### Quick Installation

1. **Clone the repository**:
```bash
git clone https://github.com/mkkelati/vpn66.git
cd vpn66
```

2. **Make the script executable**:
```bash
chmod +x vpn_manager_enhanced.sh
```

3. **Run the installation**:
```bash
sudo ./vpn_manager_enhanced.sh
```

### Manual Installation

If you prefer to install directly from GitHub:

```bash
# Download the script
wget https://raw.githubusercontent.com/mkkelati/vpn66/main/vpn_manager_enhanced.sh

# Make executable
chmod +x vpn_manager_enhanced.sh

# Run as root
sudo ./vpn_manager_enhanced.sh
```

## Usage Guide

### Initial Setup

1. **Install VPN Server** (Option 1):
   - Runs system checks
   - Installs dependencies (Xray, Python, Node.js, etc.)
   - Configures firewall
   - Sets up systemd services

2. **Configure Domain** (Option 2):
   - Enter your domain name
   - Script validates domain resolution
   - Ensures domain points to server IP

3. **Configure Port** (Option 3):
   - Set custom port (default: 443)
   - Port validation and availability check
   - Firewall rule updates

4. **Install SSL Certificate** (Option 4):
   - Automatic Let's Encrypt certificate installation
   - Creates VLESS configuration
   - Restarts Xray service

5. **Create Clients** (Option 5):
   - Generate unique client configurations
   - Create HTTP Injector compatible links
   - Save links to files for easy access

### Quick Access with Menu Command

After installation, you can easily access the VPN Manager using the `menu` command:

```bash
menu
```

This command will:
- Check if VPN Manager is installed
- Start the VPN Manager if installed
- Show installation instructions if not installed

Additional menu options:
```bash
menu status    # Check VPN Manager status
menu install   # Show installation instructions
menu help      # Show help message
```

### Client Management

#### Creating a Client
```bash
# Run the script and select option 5
sudo ./vpn_manager_enhanced.sh
# Enter client name when prompted
```

The script will generate:
- Unique UUID for the client
- HTTP Injector compatible link
- Client configuration file

#### HTTP Injector Link Format
```
vless://[UUID]@[DOMAIN]:[PORT]?type=ws&security=tls&path=%2Fvless&host=[DOMAIN]#[CLIENT_NAME]
```

### Web Dashboard

Access the web monitoring dashboard at:
```
http://YOUR_SERVER_IP:8080
```

**Dashboard Features**:
- Real-time system statistics (CPU, Memory, Disk)
- Network usage monitoring
- Active connection tracking
- Client status overview
- Recent connection logs
- Xray service status

### Monitoring Features

#### Live Connection Monitoring
- Real-time connection tracking
- Client usage statistics
- Connection history
- Bandwidth monitoring

#### System Statistics
- CPU and memory usage
- Disk space monitoring
- Network interface statistics
- Service status monitoring

## Configuration Files

### Main Configuration
- **Location**: `/etc/vpn_manager/config.json`
- **Contains**: Domain, port, UUID, installation status

### Client Database
- **Location**: `/etc/vpn_manager/clients.json`
- **Contains**: Client information, usage statistics

### Xray Configuration
- **Location**: `/usr/local/etc/xray/config.json`
- **Contains**: VLESS server configuration

### Log Files
- **VPN Manager Logs**: `/var/log/vpn_manager.log`
- **Xray Logs**: `/var/log/xray/access.log`
- **Xray Error Logs**: `/var/log/xray/error.log`

## Service Management

### Systemd Services

#### Xray Service
```bash
# Check status
sudo systemctl status xray

# Start service
sudo systemctl start xray

# Stop service
sudo systemctl stop xray

# Restart service
sudo systemctl restart xray
```

#### Web Monitor Service
```bash
# Check status
sudo systemctl status vpn-monitor

# Start service
sudo systemctl start vpn-monitor

# Stop service
sudo systemctl stop vpn-monitor
```

### Manual Service Control
```bash
# Start web monitor manually
sudo python3 /usr/local/bin/vpn_manager/web_monitor.py

# Check Xray configuration
sudo /usr/local/bin/xray run -config /usr/local/etc/xray/config.json -test
```

## Backup and Restore

### Creating Backups
```bash
# Run the script and select option 11
sudo ./vpn_manager_enhanced.sh
```

Backups include:
- Configuration files
- Client database
- Xray configuration
- Client links

### Restoring Backups
```bash
# Run the script and select option 12
sudo ./vpn_manager_enhanced.sh
```

## Troubleshooting

### Common Issues

#### 1. SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew

# Manual certificate installation
sudo certbot certonly --standalone -d yourdomain.com
```

#### 2. Xray Service Issues
```bash
# Check Xray logs
sudo journalctl -u xray -f

# Test configuration
sudo /usr/local/bin/xray run -config /usr/local/etc/xray/config.json -test

# Restart service
sudo systemctl restart xray
```

#### 3. Firewall Issues
```bash
# Check UFW status
sudo ufw status

# Allow specific ports
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw allow 8080/tcp
```

#### 4. Domain Resolution Issues
```bash
# Test domain resolution
dig yourdomain.com

# Check server IP
curl -s ifconfig.me

# Verify DNS settings
nslookup yourdomain.com
```

### Log Analysis

#### VPN Manager Logs
```bash
# View recent logs
tail -f /var/log/vpn_manager.log

# Search for errors
grep ERROR /var/log/vpn_manager.log
```

#### Xray Logs
```bash
# View access logs
tail -f /var/log/xray/access.log

# View error logs
tail -f /var/log/xray/error.log
```

## Security Considerations

### Firewall Configuration
- SSH access (port 22)
- HTTP/HTTPS (ports 80/443)
- Web dashboard (port 8080)
- Custom VPN ports

### SSL/TLS Security
- Automatic Let's Encrypt certificates
- TLS 1.3 support
- Certificate auto-renewal

### Access Control
- Root access required for installation
- Service runs with minimal privileges
- Logging for audit trails

## Performance Optimization

### System Tuning
```bash
# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize network settings
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
sysctl -p
```

### Monitoring Performance
- Web dashboard shows real-time statistics
- Connection monitoring tracks usage
- System resource monitoring
- Network bandwidth tracking

## CDN Configuration

### Cloudflare Setup
1. Add your domain to Cloudflare
2. Set DNS A record to your server IP
3. Enable "Proxied" (orange cloud)
4. Configure SSL/TLS mode to "Full (strict)"

### Other CDN Services
- Works with any CDN supporting WebSocket
- Ensure proper SSL certificate configuration
- Test connection after CDN setup

## HTTP Injector Configuration

### Importing Links
1. Copy the generated VLESS link
2. Open HTTP Injector
3. Tap the "+" button
4. Select "Import from clipboard"
5. The configuration will be imported automatically

### Manual Configuration
If manual configuration is needed:
- **Protocol**: VLESS
- **Address**: Your domain
- **Port**: Configured port (usually 443)
- **UUID**: Generated client UUID
- **Network**: WebSocket
- **Security**: TLS
- **Path**: /vless
- **Host**: Your domain

## Contributing

### Development
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Reporting Issues
- Check existing issues first
- Provide detailed error information
- Include system specifications
- Attach relevant log files

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

### Documentation
- This README file
- Inline script comments
- Web dashboard help

### Community
- GitHub Issues: [Report bugs or request features](https://github.com/mkkelati/vpn5/issues)
- Discussions: [Community support](https://github.com/mkkelati/vpn5/discussions)

### Professional Support
For professional support and custom configurations, please contact the maintainer.

## Changelog

### Version 2.0 (Current)
- ✅ Enhanced web monitoring dashboard
- ✅ Improved SSL certificate management
- ✅ Better error handling and logging
- ✅ Real-time connection monitoring
- ✅ Backup and restore functionality
- ✅ Comprehensive documentation

### Version 1.0
- ✅ Basic VLESS server setup
- ✅ Client management
- ✅ HTTP Injector link generation
- ✅ Basic monitoring

## Acknowledgments

- [Xray-core](https://github.com/XTLS/Xray-core) - Core proxy server
- [Let's Encrypt](https://letsencrypt.org/) - SSL certificates
- [Bootstrap](https://getbootstrap.com/) - Web UI framework
- [Font Awesome](https://fontawesome.com/) - Icons

---

**Note**: This script is designed for educational and legitimate use only. Users are responsible for complying with local laws and regulations regarding VPN usage. 