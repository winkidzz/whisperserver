#!/bin/bash

# WhisperCapRover Server - CapRover Deployment Script
# This script helps deploy the server to CapRover

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="whispercaprover-server"
REGISTRY=${REGISTRY:-"your-registry"}
IMAGE_NAME="${REGISTRY}/${APP_NAME}"
TAG=${TAG:-"latest"}
CAPROVER_URL=${CAPROVER_URL:-"https://your-caprover-domain.com"}

echo -e "${BLUE}🚀 WhisperCapRover Server - CapRover Deployment${NC}"
echo "=================================================="

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

# Build Docker image
build_image() {
    print_status "Building Docker image..."
    
    docker build -t "${IMAGE_NAME}:${TAG}" .
    
    if [ $? -eq 0 ]; then
        print_status "Docker image built successfully!"
    else
        print_error "Failed to build Docker image."
        exit 1
    fi
}

# Push to registry
push_image() {
    print_status "Pushing image to registry..."
    
    docker push "${IMAGE_NAME}:${TAG}"
    
    if [ $? -eq 0 ]; then
        print_status "Image pushed successfully!"
    else
        print_error "Failed to push image to registry."
        exit 1
    fi
}

# Deploy to CapRover
deploy_to_caprover() {
    print_status "Deploying to CapRover..."
    
    # Create deployment JSON
    cat > deploy.json << EOF
{
  "appName": "${APP_NAME}",
  "imageName": "${IMAGE_NAME}:${TAG}",
  "containerHttpPort": "8000",
  "environmentVariables": {
    "WHISPER_MODEL": "base",
    "MAX_CONNECTIONS": "10",
    "LOG_LEVEL": "info"
  }
}
EOF
    
    print_status "Deployment configuration created:"
    cat deploy.json
    
    print_warning "Please deploy manually via CapRover dashboard:"
    echo "1. Go to ${CAPROVER_URL}"
    echo "2. Navigate to 'One-Click Apps'"
    echo "3. Select 'Custom App'"
    echo "4. Use the deploy.json configuration above"
    echo "5. Or use the captain-definition file for Git-based deployment"
}

# Health check
health_check() {
    print_status "Waiting for deployment to complete..."
    sleep 30
    
    # Try to check health endpoint
    if [ -n "$CAPROVER_URL" ]; then
        HEALTH_URL="${CAPROVER_URL}/${APP_NAME}/health"
        print_status "Checking health endpoint: ${HEALTH_URL}"
        
        if curl -f "${HEALTH_URL}" > /dev/null 2>&1; then
            print_status "Health check passed! Deployment successful!"
        else
            print_warning "Health check failed. Please check CapRover logs."
        fi
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
            deploy_to_caprover
            ;;
        "health")
            health_check
            ;;
        "all")
            check_prerequisites
            build_image
            push_image
            deploy_to_caprover
            health_check
            ;;
        *)
            echo "Usage: $0 [check|build|push|deploy|health|all]"
            echo ""
            echo "Commands:"
            echo "  check   - Check prerequisites"
            echo "  build   - Build Docker image"
            echo "  push    - Build and push image"
            echo "  deploy  - Build, push, and deploy"
            echo "  health  - Check deployment health"
            echo "  all     - Run complete deployment (default)"
            echo ""
            echo "Environment variables:"
            echo "  REGISTRY      - Docker registry (default: your-registry)"
            echo "  TAG           - Image tag (default: latest)"
            echo "  CAPROVER_URL  - CapRover instance URL"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 