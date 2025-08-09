#!/bin/bash

# VPN Manager Status Check Script
# This script checks the status of all VPN Manager components

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Function to check if component exists
check_component() {
    local component="$1"
    local path="$2"
    local description="$3"
    
    if [[ -e "$path" ]]; then
        echo -e "✓ $description"
        return 0
    else
        echo -e "✗ $description"
        return 1
    fi
}

# Function to check service status
check_service() {
    local service="$1"
    local description="$2"
    
    if systemctl is-active --quiet "$service"; then
        echo -e "✓ $description (Running)"
        return 0
    elif systemctl is-enabled --quiet "$service"; then
        echo -e "⚠ $description (Enabled but not running)"
        return 1
    else
        echo -e "✗ $description (Not found)"
        return 1
    fi
}

# Function to check port status
check_port() {
    local port="$1"
    local description="$2"
    
    if netstat -tuln | grep -q ":$port "; then
        echo -e "✓ $description (Port $port is listening)"
        return 0
    else
        echo -e "✗ $description (Port $port is not listening)"
        return 1
    fi
}

# Function to get server IP
get_server_ip() {
    local server_ip=$(curl -s ifconfig.me 2>/dev/null)
    echo "$server_ip"
}

# Function to show configuration
show_config() {
    local config_file="/etc/vpn_manager/config.json"
    
    if [[ -f "$config_file" ]]; then
        echo
        echo -e "${CYAN}Configuration:${NC}"
        echo "Domain: $(jq -r '.domain // "Not configured"' "$config_file")"
        echo "Port: $(jq -r '.port // "Not configured"' "$config_file")"
        echo "Installed: $(jq -r '.installed // "false"' "$config_file")"
    else
        echo -e "${RED}Configuration file not found${NC}"
    fi
}

# Function to show client statistics
show_client_stats() {
    local clients_file="/etc/vpn_manager/clients.json"
    
    if [[ -f "$clients_file" ]]; then
        local total_clients=$(jq '.clients | length' "$clients_file" 2>/dev/null || echo "0")
        local enabled_clients=$(jq '.clients | map(select(.enabled)) | length' "$clients_file" 2>/dev/null || echo "0")
        
        echo
        echo -e "${CYAN}Client Statistics:${NC}"
        echo "Total Clients: $total_clients"
        echo "Enabled Clients: $enabled_clients"
    else
        echo -e "${YELLOW}No clients configured${NC}"
    fi
}

# Function to show system information
show_system_info() {
    echo
    echo -e "${CYAN}System Information:${NC}"
    echo "OS: $(lsb_release -d | cut -f2 2>/dev/null || echo "Unknown")"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Server IP: $(get_server_ip)"
}

# Function to show web dashboard info
show_web_dashboard_info() {
    local server_ip=$(get_server_ip)
    
    echo
    echo -e "${CYAN}Web Dashboard:${NC}"
    if systemctl is-active --quiet vpn-monitor; then
        echo "Status: Running"
        echo "URL: http://$server_ip:8080"
    else
        echo "Status: Not running"
        echo "To start: sudo systemctl start vpn-monitor"
    fi
}

# Main status check function
main() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  VPN Manager Status Check      ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    
    # Check installation components
    echo -e "${BLUE}Installation Components:${NC}"
    check_component "VPN Manager Script" "/opt/vpn_manager/vpn_manager_enhanced.sh" "VPN Manager Script"
    check_component "Symlink" "/usr/local/bin/vpn-manager" "Command Line Access"
    check_component "Configuration" "/etc/vpn_manager/config.json" "Configuration File"
    check_component "Xray Binary" "/usr/local/bin/xray" "Xray Proxy Server"
    check_component "Xray Config" "/usr/local/etc/xray/config.json" "Xray Configuration"
    check_component "Web Monitor" "/usr/local/bin/vpn_manager/web_monitor.py" "Web Monitoring Interface"
    
    echo
    echo -e "${BLUE}Services:${NC}"
    check_service "xray" "Xray Proxy Service"
    check_service "vpn-monitor" "Web Monitor Service"
    
    echo
    echo -e "${BLUE}Ports:${NC}"
    check_port "443" "HTTPS/VPN Port"
    check_port "80" "HTTP Port"
    check_port "8080" "Web Dashboard Port"
    
    # Show additional information
    show_config
    show_client_stats
    show_system_info
    show_web_dashboard_info
    
    echo
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    Status Check Complete       ${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Run main function
main "$@" 