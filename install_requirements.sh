#!/data/data/com.termux/files/usr/bin/bash

# SMS Stealer - Requirements Installer for Termux
# This script sets up the environment needed to run sms-stealer.rb

set -e  # Exit on error

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running on Termux
if [[ -z "$PREFIX" ]]; then
    print_error "This script is designed for Termux only."
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package list
print_info "Updating package list..."
apt update -y

# 1. Check and install Termux Void repository if missing
VOID_LIST="$PREFIX/etc/apt/sources.list.d/termuxvoid.list"
if [[ ! -f "$VOID_LIST" ]]; then
    print_warning "Termux Void repository not found. Installing..."
    bash <(curl -sL is.gd/termuxvoid) -s
    print_success "Termux Void repository installed."
    # Re-update after adding repo
    apt update -y
else
    print_success "Termux Void repository already present."
fi

# 2. Required packages
PACKAGES=("ruby" "apkeditor" "apksigner")
MISSING=()

for pkg in "${PACKAGES[@]}"; do
    if ! command_exists "$pkg"; then
        MISSING+=("$pkg")
    fi
done

if [[ ${#MISSING[@]} -ne 0 ]]; then
    print_info "Installing missing packages: ${MISSING[*]}"
    apt install -y "${MISSING[@]}"
else
    print_success "All required packages are already installed."
fi

# 3. Verify installations
print_info "Verifying installations..."
ALL_OK=true

for pkg in "${PACKAGES[@]}"; do
    if command_exists "$pkg"; then
        print_success "$pkg is available."
    else
        print_error "$pkg is still missing. Please install manually: apt install $pkg"
        ALL_OK=false
    fi
done

if [[ "$ALL_OK" == true ]]; then
    print_success "All dependencies installed successfully."
    print_info "You can now run the SMS Stealer script:"
    echo -e "${GREEN}./sms-stealer.rb${NC}"
else
    print_error "Some dependencies could not be installed automatically."
    exit 1
fi
