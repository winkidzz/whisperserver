#!/bin/bash

# CLI-based Deployment to CapRover
# This script uses CapRover CLI to deploy the cached image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="whispercaprover-cli"
CAPROVER_URL="https://captain.captain.ishworks.website"

echo -e "${BLUE}🚀 CLI-based Deployment to CapRover${NC}"
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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check if CapRover CLI is installed
    if ! command -v caprover &> /dev/null; then
        print_error "CapRover CLI not found. Please install it first: npm install -g caprover"
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Build Docker image locally
build_image() {
    print_status "Building Docker image locally..."
    
    # Use the cached build script for faster builds
    if [ -f "./build-simple-cached.sh" ]; then
        print_status "Using cached build for faster deployment..."
        ./build-simple-cached.sh build
        print_status "Docker image built successfully!"
    else
        print_error "Cached build script not found!"
        exit 1
    fi
}

# Create app in CapRover
create_app() {
    print_status "Creating app in CapRover..."
    
    # Try to create the app (will fail if it already exists, which is fine)
    caprover app create --appName "$APP_NAME" || print_warning "App might already exist"
}

# Deploy using CapRover CLI
deploy_app() {
    print_status "Deploying app using CapRover CLI..."
    
    # Create a temporary directory for deployment
    TEMP_DIR="/tmp/caprover-cli-deploy-${APP_NAME}"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Copy necessary files
    cp captain-definition "$TEMP_DIR/"
    cp Dockerfile.simple-cached "$TEMP_DIR/Dockerfile"
    cp requirements.txt "$TEMP_DIR/"
    cp server.py "$TEMP_DIR/"
    cp .dockerignore "$TEMP_DIR/" 2>/dev/null || true
    
    # Create tar file
    cd "$TEMP_DIR"
    tar -czf "/tmp/${APP_NAME}-deploy.tar.gz" .
    cd - > /dev/null
    
    print_status "Deployment tar file created: /tmp/${APP_NAME}-deploy.tar.gz"
    
    # Deploy using CapRover CLI with default flag
    caprover deploy --default --tarFile "/tmp/${APP_NAME}-deploy.tar.gz"
    
    if [ $? -eq 0 ]; then
        print_status "Deployment initiated successfully!"
    else
        print_error "Deployment failed."
        exit 1
    fi
}

# Health check
health_check() {
    print_status "Waiting for deployment to complete..."
    sleep 30
    
    # Try to check health endpoint
    HEALTH_URL="${CAPROVER_URL}/${APP_NAME}/health"
    print_status "Checking health endpoint: ${HEALTH_URL}"
    
    if curl -f "${HEALTH_URL}" > /dev/null 2>&1; then
        print_status "Health check passed! Deployment successful!"
        print_status "🌐 Your app is available at: ${CAPROVER_URL}/${APP_NAME}"
    else
        print_warning "Health check failed. Please check CapRover logs."
        print_warning "Dashboard: ${CAPROVER_URL}"
    fi
}

# Cleanup
cleanup() {
    print_status "Cleaning up..."
    rm -f "/tmp/${APP_NAME}-deploy.tar.gz"
    rm -rf "/tmp/caprover-cli-deploy-${APP_NAME}"
}

# Show app status
show_status() {
    print_status "Checking app status..."
    caprover app status --appName "$APP_NAME"
}

# Show app logs
show_logs() {
    print_status "Showing app logs..."
    caprover app logs --appName "$APP_NAME"
}

# Show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  all       - Build and deploy (default)"
    echo "  build     - Build Docker image only"
    echo "  deploy    - Deploy to CapRover only"
    echo "  status    - Show app status"
    echo "  logs      - Show app logs"
    echo "  health    - Check app health"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 all     # Build and deploy"
    echo "  $0 status  # Check app status"
    echo "  $0 logs    # View app logs"
}

# Main deployment flow
main() {
    case "${1:-all}" in
        "all")
            check_prerequisites
            build_image
            create_app
            deploy_app
            health_check
            cleanup
            ;;
        "build")
            check_prerequisites
            build_image
            ;;
        "deploy")
            check_prerequisites
            create_app
            deploy_app
            cleanup
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "health")
            health_check
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
}

# Run main function
main "$@" 