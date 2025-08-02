#!/bin/bash

# Fast Build Script with Maximum Caching
# This script uses Docker BuildKit cache mounts to speed up builds

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

echo -e "${BLUE}🚀 Fast Build with Maximum Caching${NC}"
echo "====================================="

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

# Build with maximum caching
build_with_cache() {
    print_status "Building with maximum caching..."
    
    # Enable BuildKit for advanced caching
    export DOCKER_BUILDKIT=1
    
    # Build with cache mounts using buildx
    docker buildx build \
        --file Dockerfile.cached \
        --tag "$IMAGE_NAME:latest" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --cache-from "$IMAGE_NAME:latest" \
        --build-arg PIP_CACHE_DIR=/tmp/pip-cache \
        --build-arg APT_CACHE_DIR=/tmp/apt-cache \
        --mount=type=cache,target=/tmp/pip-cache,id=pip-cache \
        --mount=type=cache,target=/tmp/apt-cache,id=apt-cache \
        --mount=type=cache,target=/root/.cache/pip,id=pip-user-cache \
        --mount=type=cache,target=/var/cache/apt,id=apt-system-cache \
        --mount=type=cache,target=/var/lib/apt,id=apt-lib-cache \
        --load \
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
    echo "  build     - Build with maximum caching (default)"
    echo "  setup     - Setup cache directories"
    echo "  stats     - Show cache statistics"
    echo "  clean     - Clean cache directories"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 build     # Build with caching"
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