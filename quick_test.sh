#!/bin/bash

# Quick Test Script for WhisperCapRover Server
# This script tests the server functionality

set -e

echo "🧪 WhisperCapRover Quick Test"
echo "============================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if server is running
echo "1. Checking if server is running..."
if curl -s http://localhost:8000/health > /dev/null; then
    print_success "Server is running"
else
    print_error "Server is not running. Please start it first with: ./start_server.sh"
    exit 1
fi

# Test health endpoint
echo "2. Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    print_success "Health check passed"
    echo "   Response: $HEALTH_RESPONSE"
else
    print_error "Health check failed"
    echo "   Response: $HEALTH_RESPONSE"
    exit 1
fi

# Test transcription
echo "3. Testing transcription with audio file..."
if [ -f "test_vad_bypass.py" ]; then
    print_info "Running transcription test..."
    python test_vad_bypass.py
    if [ $? -eq 0 ]; then
        print_success "Transcription test passed"
    else
        print_error "Transcription test failed"
        exit 1
    fi
else
    print_error "test_vad_bypass.py not found"
    exit 1
fi

echo ""
print_success "All tests passed! 🎉"
echo ""
echo "🎤 Server is working correctly!"
echo "📝 Ready for real-time transcription"
echo "🌐 Access at: http://localhost:8000"
echo "🧪 Test with: python test_vad_bypass.py" 