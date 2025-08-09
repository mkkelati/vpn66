#!/bin/bash

# VPN Manager Uninstall Script
# This script removes the VPN Manager and all its components

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

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to stop services
stop_services() {
    print_status "Stopping VPN Manager services..."
    
    # Stop web monitor service
    if systemctl is-active --quiet vpn-monitor; then
        systemctl stop vpn-monitor
        systemctl disable vpn-monitor
    fi
    
    # Stop Xray service
    if systemctl is-active --quiet xray; then
        systemctl stop xray
        systemctl disable xray
    fi
    
    print_success "Services stopped"
}

# Function to remove systemd services
remove_services() {
    print_status "Removing systemd services..."
    
    # Remove service files
    rm -f /etc/systemd/system/vpn-monitor.service
    rm -f /etc/systemd/system/xray.service
    
    # Reload systemd
    systemctl daemon-reload
    
    print_success "Systemd services removed"
}

# Function to remove VPN manager files
remove_files() {
    print_status "Removing VPN Manager files..."
    
    # Remove installation directory
    rm -rf /opt/vpn_manager
    
    # Remove configuration files
    rm -rf /etc/vpn_manager
    
    # Remove logs
    rm -rf /var/log/vpn_manager
    rm -rf /var/log/xray
    
    # Remove Xray binary and config
    rm -f /usr/local/bin/xray
    rm -rf /usr/local/etc/xray
    
    # Remove symlink
    rm -f /usr/local/bin/vpn-manager
    
    # Remove menu command
    rm -f /usr/local/bin/menu
    
    # Remove web monitor files
    rm -rf /usr/local/bin/vpn_manager
    
    print_success "VPN Manager files removed"
}

# Function to remove firewall rules
remove_firewall_rules() {
    print_status "Removing firewall rules..."
    
    # Remove custom port rules (if any)
    # Note: This is a basic removal, you may need to manually check UFW rules
    print_warning "Please manually check and remove any custom UFW rules if needed"
    
    print_success "Firewall rules processed"
}

# Function to show uninstall summary
show_summary() {
    echo
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    Uninstall Complete!        ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    print_status "VPN Manager has been uninstalled successfully!"
    echo
    echo "Removed components:"
    echo "✓ VPN Manager scripts and configuration"
    echo "✓ Xray proxy server"
    echo "✓ Web monitoring interface"
    echo "✓ Systemd services"
    echo "✓ Log files"
    echo
    echo "Note: SSL certificates and domain configurations were not removed."
    echo "If you want to remove them completely, run:"
    echo "  sudo certbot delete --cert-name yourdomain.com"
    echo
}

# Function to confirm uninstall
confirm_uninstall() {
    echo -e "${YELLOW}WARNING: This will completely remove the VPN Manager and all its components!${NC}"
    echo
    echo "This will remove:"
    echo "- VPN Manager scripts and configuration"
    echo "- Xray proxy server"
    echo "- Web monitoring interface"
    echo "- All client configurations"
    echo "- Log files"
    echo "- Systemd services"
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstall cancelled"
        exit 0
    fi
}

# Main uninstall function
main() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  VPN Manager Uninstall        ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    
    # Check root access
    check_root
    
    # Confirm uninstall
    confirm_uninstall
    
    # Stop services
    stop_services
    
    # Remove systemd services
    remove_services
    
    # Remove files
    remove_files
    
    # Remove firewall rules
    remove_firewall_rules
    
    # Show summary
    show_summary
}

# Run main function
main "$@" 