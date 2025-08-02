#!/bin/bash

# Simple Cached Build Script
# This script uses volume mounts for caching instead of BuildKit cache mounts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="whispercaprover-cached"
CACHE_DIR="$HOME/.docker-cache"
PIP_CACHE_DIR="$CACHE_DIR/pip"
APT_CACHE_DIR="$CACHE_DIR/apt"

echo -e "${BLUE}🚀 Simple Cached Build${NC}"
echo "========================"

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

# Create cache directories
setup_cache() {
    print_status "Setting up cache directories..."
    mkdir -p "$PIP_CACHE_DIR"
    mkdir -p "$APT_CACHE_DIR"
    print_status "Cache directories ready:"
    echo "  - Pip cache: $PIP_CACHE_DIR"
    echo "  - Apt cache: $APT_CACHE_DIR"
}

# Build with volume mount caching
build_with_cache() {
    print_status "Building with volume mount caching..."
    
    # Build using simple caching
    docker build \
        --file Dockerfile.simple-cached \
        --tag "$IMAGE_NAME:latest" \
        .
    
    print_status "Build completed successfully!"
}

# Build with volume mounts (alternative approach)
build_with_volumes() {
    print_status "Building with volume mounts..."
    
    # Create a temporary container to install dependencies
    docker run --rm \
        -v "$PIP_CACHE_DIR:/root/.cache/pip" \
        -v "$APT_CACHE_DIR:/var/cache/apt" \
        -v "$(pwd):/app" \
        -w /app \
        python:3.9-slim \
        bash -c "
            apt-get update && apt-get install -y gcc g++ make portaudio19-dev python3-dev build-essential libasound2-dev libportaudio2 libportaudiocpp0 ffmpeg pkg-config &&
            pip install --upgrade pip &&
            pip install -r requirements.txt
        "
    
    # Now build the final image
    docker build \
        --file Dockerfile.simple-cached \
        --tag "$IMAGE_NAME:latest" \
        .
    
    print_status "Build completed successfully!"
}

# Show cache statistics
show_cache_stats() {
    print_status "Cache Statistics:"
    echo "  - Pip cache size: $(du -sh "$PIP_CACHE_DIR" 2>/dev/null | cut -f1 || echo '0B')"
    echo "  - Apt cache size: $(du -sh "$APT_CACHE_DIR" 2>/dev/null | cut -f1 || echo '0B')"
    echo "  - Total cache size: $(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1 || echo '0B')"
}

# Clean cache
clean_cache() {
    print_warning "Cleaning cache directories..."
    rm -rf "$CACHE_DIR"
    print_status "Cache cleaned!"
}

# Show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build     - Build with volume mount caching (default)"
    echo "  volumes   - Build with volume mounts (alternative)"
    echo "  setup     - Setup cache directories"
    echo "  stats     - Show cache statistics"
    echo "  clean     - Clean cache directories"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 build     # Build with caching"
    echo "  $0 volumes   # Build with volume mounts"
    echo "  $0 setup     # Setup cache directories"
    echo "  $0 stats     # Show cache usage"
}

# Main script logic
case "${1:-build}" in
    "build")
        setup_cache
        build_with_cache
        show_cache_stats
        ;;
    "volumes")
        setup_cache
        build_with_volumes
        show_cache_stats
        ;;
    "setup")
        setup_cache
        ;;
    "stats")
        show_cache_stats
        ;;
    "clean")
        clean_cache
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 