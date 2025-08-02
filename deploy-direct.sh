#!/bin/bash

# Direct Deployment to CapRover (No Registry Required)
# This script builds locally and deploys directly to CapRover using the API

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="whispercaprover-direct"
CAPROVER_URL="https://captain.captain.ishworks.website"
CAPROVER_TOKEN="prasanna"

echo -e "${BLUE}🚀 Direct Deployment to CapRover (No Registry)${NC}"
echo "======================================================"

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
    
    # Check if we're in the right directory
    if [ ! -f "Dockerfile" ] || [ ! -f "captain-definition" ]; then
        print_error "Please run this script from the whispercaprover-server directory."
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Build Docker image locally
build_image() {
    print_status "Building Docker image locally..."
    
    # Build the image with a local tag
    # Use the cached build script for faster builds
    if [ -f "./build-simple-cached.sh" ]; then
        print_status "Using cached build for faster deployment..."
        ./build-simple-cached.sh build
        # Tag the cached image with the deployment name
        docker tag "whispercaprover-cached:latest" "${APP_NAME}:latest"
    else
        print_warning "Cached build script not found, using standard build..."
        docker build -t "${APP_NAME}:latest" .
    fi
    
    if [ $? -eq 0 ]; then
        print_status "Docker image built successfully!"
    else
        print_error "Failed to build Docker image."
        exit 1
    fi
}

# Create deployment tar file
create_deployment_tar() {
    print_status "Creating deployment tar file..."
    
    # Create a temporary directory for deployment
    TEMP_DIR="/tmp/caprover-deploy-${APP_NAME}"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Copy necessary files
    cp captain-definition "$TEMP_DIR/"
    cp Dockerfile "$TEMP_DIR/"
    cp requirements.txt "$TEMP_DIR/"
    cp server.py "$TEMP_DIR/"
    cp .dockerignore "$TEMP_DIR/" 2>/dev/null || true
    
    # Create tar file
    cd "$TEMP_DIR"
    tar -czf "/tmp/${APP_NAME}-deploy.tar.gz" .
    cd - > /dev/null
    
    print_status "Deployment tar file created: /tmp/${APP_NAME}-deploy.tar.gz"
}

# Deploy to CapRover using API
deploy_to_caprover() {
    print_status "Deploying to CapRover using API..."
    
    # Deploy using CapRover API
    response=$(curl -s -w "%{http_code}" -X POST \
        -H "X-Captain-Token: $CAPROVER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
          "appName": "'$APP_NAME'",
          "gitHash": "'$(git rev-parse HEAD 2>/dev/null || echo "local")'",
          "tarFile": null,
          "gitBranch": "main"
        }' \
        "$CAPROVER_URL/api/v2/user/apps/deployapp")
    
    http_code="${response: -3}"
    body="${response%???}"
    
    echo "Response: $body"
    echo "HTTP Code: $http_code"
    
    if [ "$http_code" = "200" ]; then
        print_status "Deployment initiated successfully!"
    else
        print_error "Deployment failed with HTTP code: $http_code"
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
    rm -rf "/tmp/caprover-deploy-${APP_NAME}"
}

# Main deployment flow
main() {
    case "${1:-all}" in
        "check")
            check_prerequisites
            ;;
        "build")
            check_prerequisites
            build_image
            ;;
        "deploy")
            check_prerequisites
            build_image
            create_deployment_tar
            deploy_to_caprover
            ;;
        "health")
            health_check
            ;;
        "all")
            check_prerequisites
            build_image
            create_deployment_tar
            deploy_to_caprover
            health_check
            cleanup
            ;;
        *)
            echo "Usage: $0 [check|build|deploy|health|all]"
            echo ""
            echo "Commands:"
            echo "  check   - Check prerequisites"
            echo "  build   - Build Docker image locally"
            echo "  deploy  - Build and deploy to CapRover"
            echo "  health  - Check deployment health"
            echo "  all     - Run complete deployment (default)"
            echo ""
            echo "This script deploys directly to CapRover without using a registry."
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 