#!/bin/bash

# Enhanced VPN Script Manager for VLESS (WebSocket + TLS) with CDN
# Author: VPN Manager
# Version: 2.0
# Compatible with Ubuntu 22.04+

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE="/etc/vpn_manager/config.json"
CLIENTS_FILE="/etc/vpn_manager/clients.json"
LOG_FILE="/var/log/vpn_manager.log"

# Default values
DEFAULT_PORT=443
DEFAULT_DOMAIN=""
XRAY_VERSION="1.8.4"

# Create necessary directories
mkdir -p /etc/vpn_manager
mkdir -p /var/log/vpn_manager
mkdir -p /usr/local/bin/vpn_manager
mkdir -p /etc/vpn_manager/backups
mkdir -p /etc/vpn_manager/links

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to check system requirements
check_system() {
    print_status "Checking system requirements..."
    
    # Check OS
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_warning "This script is designed for Ubuntu. Other distributions may work but are not tested."
    fi
    
    # Check if system is 64-bit
    if [[ $(getconf LONG_BIT) -ne 64 ]]; then
        print_error "This script requires a 64-bit system"
        exit 1
    fi
    
    # Check available memory
    local mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [[ $mem -lt 512 ]]; then
        print_warning "System has less than 512MB RAM. Performance may be affected."
    fi
    
    print_success "System requirements check completed"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    apt update
    apt install -y curl wget unzip jq uuid-runtime net-tools iptables-persistent dnsutils
    
    # Install Python and Flask for web monitoring
    apt install -y python3 python3-pip python3-psutil
    
    # Install Node.js for monitoring
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    # Install Flask
    pip3 install flask
    
    print_success "Dependencies installed successfully"
}

# Function to install Xray
install_xray() {
    print_status "Installing Xray..."
    
    # Download Xray
    local xray_url="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip"
    wget -O /tmp/xray.zip "$xray_url"
    
    # Extract and install
    unzip -o /tmp/xray.zip -d /usr/local/bin/
    chmod +x /usr/local/bin/xray
    
    # Create systemd service
    cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    # Create Xray config directory
    mkdir -p /usr/local/etc/xray
    
    # Enable and start Xray service
    systemctl daemon-reload
    systemctl enable xray
    
    print_success "Xray installed successfully"
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow web monitoring port
    ufw allow 8080/tcp
    
    # Allow custom ports
    if [[ -n "$CUSTOM_PORT" ]]; then
        ufw allow "$CUSTOM_PORT/tcp"
    fi
    
    # Enable UFW
    ufw --force enable
    
    print_success "Firewall configured successfully"
}

# Function to get server IP
get_server_ip() {
    local server_ip=$(curl -s ifconfig.me)
    echo "$server_ip"
}

# Function to configure domain
configure_domain() {
    print_status "Configuring domain..."
    
    read -p "Enter your domain name (e.g., example.com): " DOMAIN
    
    if [[ -z "$DOMAIN" ]]; then
        print_error "Domain name is required"
        return 1
    fi
    
    # Test domain resolution
    local resolved_ip=$(dig +short "$DOMAIN" | head -1)
    local server_ip=$(get_server_ip)
    
    if [[ "$resolved_ip" != "$server_ip" ]]; then
        print_warning "Domain $DOMAIN does not resolve to this server's IP ($server_ip)"
        print_warning "Please ensure your domain points to this server's IP address"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Save domain to config
    jq --arg domain "$DOMAIN" '.domain = $domain' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    print_success "Domain configured: $DOMAIN"
}

# Function to configure port
configure_port() {
    print_status "Configuring port..."
    
    read -p "Enter port number (default: 443): " PORT
    PORT=${PORT:-443}
    
    # Validate port
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [[ "$PORT" -lt 1 ]] || [[ "$PORT" -gt 65535 ]]; then
        print_error "Invalid port number. Must be between 1 and 65535"
        return 1
    fi
    
    # Check if port is available
    if netstat -tuln | grep -q ":$PORT "; then
        print_warning "Port $PORT is already in use"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Save port to config
    jq --arg port "$PORT" '.port = $port' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    # Update firewall
    ufw allow "$PORT/tcp"
    
    print_success "Port configured: $PORT"
}

# Function to create VLESS configuration
create_vless_config() {
    print_status "Creating VLESS configuration..."
    
    # Read config
    local domain=$(jq -r '.domain' "$CONFIG_FILE")
    local port=$(jq -r '.port' "$CONFIG_FILE")
    
    if [[ "$domain" == "null" ]] || [[ "$port" == "null" ]]; then
        print_error "Domain and port must be configured first"
        return 1
    fi
    
    # Generate UUID for VLESS
    local uuid=$(uuidgen)
    
    # Create Xray config
    cat > /usr/local/etc/xray/config.json << EOF
{
    "log": {
        "loglevel": "warning",
        "access": "/var/log/xray/access.log",
        "error": "/var/log/xray/error.log"
    },
    "inbounds": [
        {
            "port": $port,
            "protocol": "vless",
            "settings": {
                "clients": [],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "wsSettings": {
                    "path": "/vless",
                    "headers": {
                        "Host": "$domain"
                    }
                },
                "tlsSettings": {
                    "serverName": "$domain",
                    "certificates": [
                        {
                            "certificateFile": "/etc/letsencrypt/live/$domain/fullchain.pem",
                            "keyFile": "/etc/letsencrypt/live/$domain/privkey.pem"
                        }
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF

    # Create log directory
    mkdir -p /var/log/xray
    
    # Save UUID to config
    jq --arg uuid "$uuid" '.vless_uuid = $uuid' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    print_success "VLESS configuration created"
    print_status "UUID: $uuid"
}

# Function to install SSL certificate
install_ssl() {
    print_status "Installing SSL certificate..."
    
    local domain=$(jq -r '.domain' "$CONFIG_FILE")
    
    if [[ "$domain" == "null" ]]; then
        print_error "Domain must be configured first"
        return 1
    fi
    
    # Install certbot
    apt install -y certbot
    
    # Get SSL certificate
    certbot certonly --standalone -d "$domain" --non-interactive --agree-tos --email admin@"$domain"
    
    if [[ $? -eq 0 ]]; then
        print_success "SSL certificate installed successfully"
        
        # Create VLESS config after SSL installation
        create_vless_config
        
        # Restart Xray
        systemctl restart xray
    else
        print_error "Failed to install SSL certificate"
        return 1
    fi
}

# Function to create client
create_client() {
    print_status "Creating new client..."
    
    read -p "Enter client name: " CLIENT_NAME
    
    if [[ -z "$CLIENT_NAME" ]]; then
        print_error "Client name is required"
        return 1
    fi
    
    # Generate client UUID
    local client_uuid=$(uuidgen)
    
    # Read config
    local domain=$(jq -r '.domain' "$CONFIG_FILE")
    local port=$(jq -r '.port' "$CONFIG_FILE")
    
    # Create client config
    local client_config=$(cat << EOF
{
    "name": "$CLIENT_NAME",
    "uuid": "$client_uuid",
    "created_at": "$(date -Iseconds)",
    "enabled": true,
    "last_used": null,
    "connection_count": 0
}
EOF
)
    
    # Add client to clients file
    if [[ ! -f "$CLIENTS_FILE" ]]; then
        echo '{"clients": []}' > "$CLIENTS_FILE"
    fi
    
    jq --argjson client "$client_config" '.clients += [$client]' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
    
    # Add client to Xray config
    local xray_client=$(cat << EOF
{
    "id": "$client_uuid",
    "email": "$CLIENT_NAME"
}
EOF
)
    
    jq --argjson client "$xray_client" '.inbounds[0].settings.clients += [$client]' /usr/local/etc/xray/config.json > /tmp/xray_config.json && mv /tmp/xray_config.json /usr/local/etc/xray/config.json
    
    # Restart Xray
    systemctl restart xray
    
    # Generate HTTP Injector link
    local http_injector_link="vless://${client_uuid}@${domain}:${port}?type=ws&security=tls&path=%2Fvless&host=${domain}#${CLIENT_NAME}"
    
    print_success "Client created successfully"
    print_status "Client Name: $CLIENT_NAME"
    print_status "UUID: $client_uuid"
    echo
    print_status "HTTP Injector Link:"
    echo "$http_injector_link"
    echo
    
    # Save link to file
    echo "$http_injector_link" > "/etc/vpn_manager/links/${CLIENT_NAME}.txt"
    
    log_message "Client created: $CLIENT_NAME ($client_uuid)"
}

# Function to list clients
list_clients() {
    print_status "Listing all clients..."
    
    if [[ ! -f "$CLIENTS_FILE" ]]; then
        print_warning "No clients found"
        return
    fi
    
    local clients=$(jq -r '.clients[] | "\(.name) - \(.uuid) - Enabled: \(.enabled) - Connections: \(.connection_count)"' "$CLIENTS_FILE")
    
    if [[ -z "$clients" ]]; then
        print_warning "No clients found"
    else
        echo "$clients"
    fi
}

# Function to delete client
delete_client() {
    print_status "Deleting client..."
    
    read -p "Enter client name to delete: " CLIENT_NAME
    
    if [[ -z "$CLIENT_NAME" ]]; then
        print_error "Client name is required"
        return 1
    fi
    
    # Remove from clients file
    jq --arg name "$CLIENT_NAME" 'del(.clients[] | select(.name == $name))' "$CLIENTS_FILE" > /tmp/clients.json && mv /tmp/clients.json "$CLIENTS_FILE"
    
    # Remove from Xray config
    jq --arg name "$CLIENT_NAME" 'del(.inbounds[0].settings.clients[] | select(.email == $name))' /usr/local/etc/xray/config.json > /tmp/xray_config.json && mv /tmp/xray_config.json /usr/local/etc/xray/config.json
    
    # Restart Xray
    systemctl restart xray
    
    # Remove link file
    rm -f "/etc/vpn_manager/links/${CLIENT_NAME}.txt"
    
    print_success "Client deleted successfully"
    log_message "Client deleted: $CLIENT_NAME"
}

# Function to start web monitoring
start_web_monitor() {
    print_status "Starting web monitoring interface..."
    
    # Copy web monitor files
    cp web_monitor.py /usr/local/bin/vpn_manager/
    cp -r templates /usr/local/bin/vpn_manager/
    
    # Create systemd service for web monitor
    cat > /etc/systemd/system/vpn-monitor.service << EOF
[Unit]
Description=VPN Manager Web Monitor
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin/vpn_manager
ExecStart=/usr/bin/python3 /usr/local/bin/vpn_manager/web_monitor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start web monitor
    systemctl daemon-reload
    systemctl enable vpn-monitor
    systemctl start vpn-monitor
    
    print_success "Web monitoring interface started"
    print_status "Access dashboard at: http://$(get_server_ip):8080"
}

# Function to show live connections
show_live_connections() {
    print_status "Showing live connections..."
    
    # Show current connections
    local connections=$(netstat -tuln | grep -E ":(443|80|8080|8443)" | wc -l)
    print_status "Active connections: $connections"
    
    # Show recent log entries
    if [[ -f "/var/log/xray/access.log" ]]; then
        print_status "Recent connections:"
        tail -10 /var/log/xray/access.log | grep "accepted" | while read line; do
            echo "  $line"
        done
    fi
}

# Function to show statistics
show_statistics() {
    print_status "VPN Manager Statistics"
    echo "=========================="
    
    # System info
    echo "System Information:"
    echo "  OS: $(lsb_release -d | cut -f2)"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p)"
    echo
    
    # Xray status
    echo "Xray Service:"
    if systemctl is-active --quiet xray; then
        echo "  Status: Running"
        echo "  Port: $(jq -r '.port // "Not configured"' "$CONFIG_FILE")"
        echo "  Domain: $(jq -r '.domain // "Not configured"' "$CONFIG_FILE")"
    else
        echo "  Status: Stopped"
    fi
    echo
    
    # Web monitor status
    echo "Web Monitor:"
    if systemctl is-active --quiet vpn-monitor; then
        echo "  Status: Running"
        echo "  URL: http://$(get_server_ip):8080"
    else
        echo "  Status: Stopped"
    fi
    echo
    
    # Client statistics
    if [[ -f "$CLIENTS_FILE" ]]; then
        local total_clients=$(jq '.clients | length' "$CLIENTS_FILE")
        local enabled_clients=$(jq '.clients | map(select(.enabled)) | length' "$CLIENTS_FILE")
        local total_connections=$(jq '.clients | map(.connection_count // 0) | add' "$CLIENTS_FILE")
        
        echo "Client Statistics:"
        echo "  Total Clients: $total_clients"
        echo "  Enabled Clients: $enabled_clients"
        echo "  Total Connections: $total_connections"
    else
        echo "Client Statistics: No clients configured"
    fi
    echo
    
    # Network statistics
    echo "Network Statistics:"
    echo "  Active Connections: $(netstat -tuln | grep -E ":(443|80|8080|8443)" | wc -l)"
    echo "  Bandwidth Usage: $(du -sh /var/log/xray/ 2>/dev/null | cut -f1 || echo "N/A")"
}

# Function to backup configuration
backup_config() {
    print_status "Creating backup..."
    
    local backup_dir="/etc/vpn_manager/backups"
    local backup_file="vpn_manager_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    mkdir -p "$backup_dir"
    
    tar -czf "$backup_dir/$backup_file" \
        "$CONFIG_FILE" \
        "$CLIENTS_FILE" \
        /usr/local/etc/xray/config.json \
        /etc/vpn_manager/links/ 2>/dev/null
    
    print_success "Backup created: $backup_dir/$backup_file"
}

# Function to restore configuration
restore_config() {
    print_status "Restoring configuration..."
    
    local backup_dir="/etc/vpn_manager/backups"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_error "No backups found"
        return 1
    fi
    
    echo "Available backups:"
    ls -la "$backup_dir"/*.tar.gz 2>/dev/null || { print_error "No backup files found"; return 1; }
    
    read -p "Enter backup filename: " backup_file
    
    if [[ ! -f "$backup_dir/$backup_file" ]]; then
        print_error "Backup file not found"
        return 1
    fi
    
    # Extract backup
    tar -xzf "$backup_dir/$backup_file" -C /
    
    # Restart Xray
    systemctl restart xray
    
    print_success "Configuration restored successfully"
}

# Function to show main menu
show_menu() {
    clear
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  Enhanced VPN Manager v2.0     ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    echo "1.  Install/Setup VPN Server"
    echo "2.  Configure Domain"
    echo "3.  Configure Port"
    echo "4.  Install SSL Certificate"
    echo "5.  Create Client"
    echo "6.  List Clients"
    echo "7.  Delete Client"
    echo "8.  Show Live Connections"
    echo "9.  Show Statistics"
    echo "10. Start Web Monitor"
    echo "11. Backup Configuration"
    echo "12. Restore Configuration"
    echo "13. Exit"
    echo
}

# Function to initialize configuration
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
{
    "domain": null,
    "port": $DEFAULT_PORT,
    "vless_uuid": null,
    "installed": false,
    "created_at": "$(date -Iseconds)"
}
EOF
    fi
    
    # Create links directory
    mkdir -p /etc/vpn_manager/links
}

# Main installation function
install_vpn() {
    print_status "Starting VPN installation..."
    
    check_root
    check_system
    install_dependencies
    install_xray
    configure_firewall
    
    # Mark as installed
    jq '.installed = true' "$CONFIG_FILE" > /tmp/config.json && mv /tmp/config.json "$CONFIG_FILE"
    
    print_success "VPN installation completed successfully!"
    print_status "Next steps:"
    print_status "1. Configure your domain"
    print_status "2. Configure port"
    print_status "3. Install SSL certificate"
    print_status "4. Create clients"
    print_status "5. Start web monitoring"
}

# Main function
main() {
    # Initialize configuration
    init_config
    
    while true; do
        show_menu
        read -p "Select option (1-13): " choice
        
        case $choice in
            1)
                install_vpn
                ;;
            2)
                configure_domain
                ;;
            3)
                configure_port
                ;;
            4)
                install_ssl
                ;;
            5)
                create_client
                ;;
            6)
                list_clients
                ;;
            7)
                delete_client
                ;;
            8)
                show_live_connections
                ;;
            9)
                show_statistics
                ;;
            10)
                start_web_monitor
                ;;
            11)
                backup_config
                ;;
            12)
                restore_config
                ;;
            13)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 