#!/bin/bash

# Local Build and Deploy to CapRover
# This script builds locally and deploys directly to CapRover

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="whispercaprover-local"
CAPROVER_URL="https://captain.ishworks.website"
CAPROVER_TOKEN="718dbed697631ee134cfa77f2628917deaeeb72a750f063a1c08e145d29fb19d"
REGISTRY="your-registry"  # Change this to your Docker registry
IMAGE_NAME="${REGISTRY}/${APP_NAME}"
TAG="latest"

echo -e "${BLUE}🚀 Local Build and Deploy to CapRover${NC}"
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
        print_warning "CapRover CLI not found. Installing..."
        npm install -g caprover
    fi
    
    print_status "Prerequisites check passed!"
}

# Build Docker image locally
build_image() {
    print_status "Building Docker image locally..."
    
    # Use the production Dockerfile
    docker build -t "${IMAGE_NAME}:${TAG}" .
    
    if [ $? -eq 0 ]; then
        print_status "Docker image built successfully!"
    else
        print_error "Failed to build Docker image."
        exit 1
    fi
}

# Push to registry (if using remote registry)
push_image() {
    if [ "$REGISTRY" != "your-registry" ]; then
        print_status "Pushing image to registry..."
        docker push "${IMAGE_NAME}:${TAG}"
        
        if [ $? -eq 0 ]; then
            print_status "Image pushed successfully!"
        else
            print_error "Failed to push image to registry."
            exit 1
        fi
    else
        print_warning "Skipping registry push (using local image)"
    fi
}

# Login to CapRover
login_to_caprover() {
    print_status "Logging into CapRover..."
    caprover login --caproverUrl "$CAPROVER_URL" --caproverPassword "$CAPROVER_TOKEN"
    
    if [ $? -eq 0 ]; then
        print_status "Successfully logged into CapRover!"
    else
        print_error "Failed to login to CapRover."
        exit 1
    fi
}

# Deploy to CapRover
deploy_to_caprover() {
    print_status "Deploying to CapRover..."
    
    if [ "$REGISTRY" != "your-registry" ]; then
        # Deploy using remote image
        caprover app deploy --appName "$APP_NAME" --imageName "${IMAGE_NAME}:${TAG}"
    else
        # Deploy using local image (requires CapRover to have access to local Docker)
        print_warning "Deploying local image - ensure CapRover can access your Docker daemon"
        caprover app deploy --appName "$APP_NAME" --imageName "${IMAGE_NAME}:${TAG}"
    fi
    
    if [ $? -eq 0 ]; then
        print_status "App deployment initiated successfully!"
    else
        print_error "Failed to deploy app."
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
    fi
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
        "push")
            check_prerequisites
            build_image
            push_image
            ;;
        "deploy")
            check_prerequisites
            build_image
            push_image
            login_to_caprover
            deploy_to_caprover
            ;;
        "health")
            health_check
            ;;
        "all")
            check_prerequisites
            build_image
            push_image
            login_to_caprover
            deploy_to_caprover
            health_check
            ;;
        *)
            echo "Usage: $0 [check|build|push|deploy|health|all]"
            echo ""
            echo "Commands:"
            echo "  check   - Check prerequisites"
            echo "  build   - Build Docker image locally"
            echo "  push    - Build and push image"
            echo "  deploy  - Build, push, and deploy"
            echo "  health  - Check deployment health"
            echo "  all     - Run complete deployment (default)"
            echo ""
            echo "Environment variables:"
            echo "  REGISTRY      - Docker registry (default: your-registry)"
            echo "  TAG           - Image tag (default: latest)"
            echo "  APP_NAME      - CapRover app name (default: whispercaprover-local)"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 