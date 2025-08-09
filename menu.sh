#!/bin/bash

# VPN Manager Menu Script
# This script provides easy access to the VPN Manager

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# VPN Manager path
VPN_MANAGER_PATH="/opt/vpn_manager/vpn_manager_enhanced.sh"
VPN_MANAGER_SYMLINK="/usr/local/bin/vpn-manager"

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

# Function to check if VPN Manager is installed
check_installation() {
    if [[ -f "$VPN_MANAGER_PATH" ]] || [[ -f "$VPN_MANAGER_SYMLINK" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to show installation prompt
show_install_prompt() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    VPN Manager Not Found       ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    echo "VPN Manager is not installed on this system."
    echo
    echo "To install VPN Manager, run:"
    echo "curl -sSL https://raw.githubusercontent.com/mkkelati/vpn66/main/install.sh | sudo bash"
    echo
    echo "Or visit: https://github.com/mkkelati/vpn66"
    echo
}

# Function to show welcome message
show_welcome() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    Welcome to VPN Manager      ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    print_status "Starting VPN Manager..."
    echo
}

# Function to start VPN Manager
start_vpn_manager() {
    if [[ -f "$VPN_MANAGER_SYMLINK" ]]; then
        # Use symlink if available
        sudo "$VPN_MANAGER_SYMLINK"
    elif [[ -f "$VPN_MANAGER_PATH" ]]; then
        # Use direct path
        sudo "$VPN_MANAGER_PATH"
    else
        print_error "VPN Manager not found. Please install it first."
        show_install_prompt
        exit 1
    fi
}

# Function to show help
show_help() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    VPN Manager Help            ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    echo "Usage: menu [options]"
    echo
    echo "Options:"
    echo "  start     - Start VPN Manager"
    echo "  status    - Check VPN Manager status"
    echo "  install   - Show installation instructions"
    echo "  help      - Show this help message"
    echo
    echo "Examples:"
    echo "  menu              - Start VPN Manager"
    echo "  menu start        - Start VPN Manager"
    echo "  menu status       - Check status"
    echo "  menu install      - Show install instructions"
    echo
}

# Function to check status
check_status() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    VPN Manager Status          ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    
    # Check if VPN Manager is installed
    if check_installation; then
        print_success "VPN Manager is installed"
        
        # Check if status script exists
        if [[ -f "/opt/vpn_manager/status.sh" ]]; then
            echo
            print_status "Running status check..."
            sudo /opt/vpn_manager/status.sh
        else
            echo "Status script not found"
        fi
    else
        print_error "VPN Manager is not installed"
        show_install_prompt
    fi
}

# Function to show installation instructions
show_install_instructions() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    Installation Instructions    ${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    echo "To install VPN Manager, run one of these commands:"
    echo
    echo "1. One-command installation:"
    echo "   curl -sSL https://raw.githubusercontent.com/mkkelati/vpn66/main/install.sh | sudo bash"
    echo
    echo "2. Manual installation:"
    echo "   git clone https://github.com/mkkelati/vpn66.git"
    echo "   cd vpn66"
    echo "   chmod +x vpn_manager_enhanced.sh"
    echo "   sudo ./vpn_manager_enhanced.sh"
    echo
    echo "3. Direct download:"
    echo "   wget https://raw.githubusercontent.com/mkkelati/vpn66/main/vpn_manager_enhanced.sh"
    echo "   chmod +x vpn_manager_enhanced.sh"
    echo "   sudo ./vpn_manager_enhanced.sh"
    echo
    echo "After installation, you can use 'menu' to access VPN Manager anytime."
    echo
}

# Main function
main() {
    case "${1:-}" in
        "start"|"")
            if check_installation; then
                show_welcome
                start_vpn_manager
            else
                show_install_prompt
            fi
            ;;
        "status")
            check_status
            ;;
        "install")
            show_install_instructions
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 