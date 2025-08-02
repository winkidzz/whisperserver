#!/bin/bash

# Setup Docker Insecure Registry for CapRover
# This script configures Docker to accept self-signed certificates for the CapRover registry

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REGISTRY="registry.captain.ishworks.website"

echo -e "${BLUE}🔧 Setting up Docker for CapRover Registry${NC}"
echo "=============================================="

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Detected macOS"
    
    # Check if Docker Desktop is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi
    
    # Configure Docker Desktop for insecure registry
    print_status "Configuring Docker Desktop for insecure registry..."
    
    # Create or update Docker daemon configuration
    DOCKER_CONFIG_DIR="$HOME/.docker"
    DOCKER_CONFIG_FILE="$DOCKER_CONFIG_DIR/daemon.json"
    
    mkdir -p "$DOCKER_CONFIG_DIR"
    
    # Check if daemon.json exists
    if [ -f "$DOCKER_CONFIG_FILE" ]; then
        print_warning "Docker daemon.json already exists. Backing up..."
        cp "$DOCKER_CONFIG_FILE" "$DOCKER_CONFIG_FILE.backup"
    fi
    
    # Create daemon.json with insecure registry configuration
    cat > "$DOCKER_CONFIG_FILE" << EOF
{
  "insecure-registries": [
    "$REGISTRY"
  ],
  "experimental": false
}
EOF
    
    print_status "Docker daemon configuration updated!"
    print_warning "Please restart Docker Desktop for changes to take effect."
    print_warning "After restarting Docker Desktop, run this script again to test the connection."
    
else
    print_error "This script is designed for macOS. For other platforms, please configure Docker daemon manually."
    exit 1
fi

print_status "Setup completed! Please restart Docker Desktop and run the test script again." 