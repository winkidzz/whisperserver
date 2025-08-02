#!/bin/bash

# Test CapRover Registry Connection
# This script tests the connection to CapRover's built-in registry

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CAPROVER_URL="https://captain.ishworks.website"
CAPROVER_TOKEN="718dbed697631ee134cfa77f2628917deaeeb72a750f063a1c08e145d29fb19d"
REGISTRY="captain.ishworks.website:996"

echo -e "${BLUE}🐳 Testing CapRover Registry Connection${NC}"
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

# Test 1: Check if registry is accessible
print_status "Testing registry accessibility..."
if curl -f "http://${REGISTRY}/v2/" > /dev/null 2>&1; then
    print_status "Registry is accessible!"
else
    print_error "Registry is not accessible. Check if CapRover registry is enabled."
    exit 1
fi

# Test 2: Test Docker login
print_status "Testing Docker login to registry..."
if echo "$CAPROVER_TOKEN" | docker login "$REGISTRY" --username "captain" --password-stdin > /dev/null 2>&1; then
    print_status "Docker login successful!"
else
    print_error "Docker login failed. Check your CapRover token."
    exit 1
fi

# Test 3: List repositories (if any)
print_status "Listing repositories in registry..."
if curl -s "http://${REGISTRY}/v2/_catalog" | grep -q "repositories"; then
    print_status "Registry contains repositories:"
    curl -s "http://${REGISTRY}/v2/_catalog" | jq '.repositories[]' 2>/dev/null || echo "No repositories found"
else
    print_warning "No repositories found in registry (this is normal for a new setup)"
fi

# Test 4: Check registry info
print_status "Registry information:"
echo "  URL: $REGISTRY"
echo "  CapRover Dashboard: $CAPROVER_URL"
echo "  Registry Web UI: $CAPROVER_URL/#/registry"

print_status "CapRover registry connection test completed successfully!"
print_status "You can now use the registry for your deployments." 