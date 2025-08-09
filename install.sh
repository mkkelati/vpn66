#!/bin/bash

# VPN Manager Installation Script
# This script downloads and installs the VPN Manager from GitHub

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# GitHub repository
GITHUB_REPO="https://github.com/mkkelati/vpn66.git"
INSTALL_DIR="/opt/vpn_manager"

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

# Function to install git if not present
install_git() {
    if ! command -v git &> /dev/null; then
        print_status "Installing git..."
        apt update
        apt install -y git
    fi
}

# Function to download VPN manager
download_vpn_manager() {
    print_status "Downloading VPN Manager from GitHub..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Clone repository
    if git clone "$GITHUB_REPO" "$INSTALL_DIR"; then
        print_success "VPN Manager downloaded successfully"
    else
        print_error "Failed to download VPN Manager"
        exit 1
    fi
}

# Function to setup VPN manager
setup_vpn_manager() {
    print_status "Setting up VPN Manager..."
    
    cd "$INSTALL_DIR"
    
    # Make scripts executable
    chmod +x vpn_manager_enhanced.sh
    chmod +x vpn_manager.sh
    
    # Create symlink for easy access
    ln -sf "$INSTALL_DIR/vpn_manager_enhanced.sh" /usr/local/bin/vpn-manager
    
    print_success "VPN Manager setup completed"
}

# Function to show installation summary
show_summary() {
    echo
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    Installation Complete!      ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    print_status "VPN Manager has been installed successfully!"
    echo
    echo "Next steps:"
    echo "1. Run the VPN Manager:"
    echo "   sudo vpn-manager"
    echo "   or"
    echo "   sudo $INSTALL_DIR/vpn_manager_enhanced.sh"
    echo
    echo "2. Follow the setup wizard to:"
    echo "   - Install VPN server"
    echo "   - Configure domain and port"
    echo "   - Install SSL certificate"
    echo "   - Create clients"
    echo "   - Start web monitoring"
    echo
    echo "3. Access web dashboard at: http://YOUR_SERVER_IP:8080"
    echo
    echo "For more information, see: $INSTALL_DIR/README.md"
    echo
}

# Main installation function
main() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  VPN Manager Installation      ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    
    # Check root access
    check_root
    
    # Check system requirements
    check_system
    
    # Install git if needed
    install_git
    
    # Download VPN manager
    download_vpn_manager
    
    # Setup VPN manager
    setup_vpn_manager
    
    # Show summary
    show_summary
}

# Run main function
main "$@" 