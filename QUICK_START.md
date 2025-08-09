# Quick Start Guide - VPN Manager

## 🚀 One-Command Installation

Install VPN Manager on your Ubuntu server with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/mkkelati/vpn66/main/install.sh | sudo bash
```

## 📋 Prerequisites

Before installation, ensure you have:
- ✅ Ubuntu 22.04+ server
- ✅ Root/sudo access
- ✅ Domain name pointing to your server
- ✅ Public IP address

## 🔧 Quick Setup Steps

### 1. Install VPN Manager
```bash
curl -sSL https://raw.githubusercontent.com/mkkelati/vpn66/main/install.sh | sudo bash
```

### 2. Run the VPN Manager
```bash
sudo vpn-manager
```

### 3. Follow the Setup Wizard
1. **Install VPN Server** (Option 1)
2. **Configure Domain** (Option 2) - Enter your domain
3. **Configure Port** (Option 3) - Usually 443
4. **Install SSL Certificate** (Option 4)
5. **Create Client** (Option 5) - Generate HTTP Injector links
6. **Start Web Monitor** (Option 10) - Access dashboard

### 4. Access Web Dashboard
Open your browser and go to:
```
http://YOUR_SERVER_IP:8080
```

## 📱 HTTP Injector Setup

### Import Generated Links
1. Copy the VLESS link from the VPN Manager
2. Open HTTP Injector
3. Tap "+" button
4. Select "Import from clipboard"
5. Start connection

### Link Format
```
vless://[UUID]@[DOMAIN]:[PORT]?type=ws&security=tls&path=%2Fvless&host=[DOMAIN]#[CLIENT_NAME]
```

## 🔍 Useful Commands

### Check Status
```bash
sudo /opt/vpn_manager/status.sh
```

### View Logs
```bash
# VPN Manager logs
sudo tail -f /var/log/vpn_manager.log

# Xray logs
sudo tail -f /var/log/xray/access.log
```

### Service Management
```bash
# Check Xray status
sudo systemctl status xray

# Restart Xray
sudo systemctl restart xray

# Check web monitor
sudo systemctl status vpn-monitor
```

## 🆘 Troubleshooting

### Common Issues

#### SSL Certificate Problems
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew
```

#### Domain Resolution Issues
```bash
# Test domain
dig yourdomain.com

# Check server IP
curl -s ifconfig.me
```

#### Firewall Issues
```bash
# Check UFW status
sudo ufw status

# Allow ports
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw allow 8080/tcp
```

## 📊 Monitoring Features

### Web Dashboard
- Real-time system statistics
- Live connection monitoring
- Client usage tracking
- Network bandwidth monitoring

### Command Line Monitoring
```bash
# Show live connections
sudo vpn-manager
# Select option 8

# Show statistics
sudo vpn-manager
# Select option 9
```

## 🔒 Security Notes

- ✅ Automatic SSL certificate installation
- ✅ Firewall configuration
- ✅ Service isolation
- ✅ Comprehensive logging
- ✅ Access control

## 📞 Support

- 📖 **Documentation**: See README.md for detailed guide
- 🐛 **Issues**: Report on GitHub
- 💬 **Community**: GitHub Discussions

## 🎯 Features Summary

- ✅ VLESS WebSocket + TLS
- ✅ CDN compatibility (Cloudflare)
- ✅ HTTP Injector support
- ✅ Client management
- ✅ Live connection monitoring
- ✅ Web dashboard
- ✅ SSL certificate management
- ✅ Backup/restore functionality

---

**Ready to start? Run the installation command above!** 🚀 