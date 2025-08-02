#!/bin/bash

# WhisperCapRover Server - Grogu Server Deployment Script
# Run this script on the grogu server after SSH'ing in

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 WhisperCapRover Server - Grogu Deployment${NC}"
echo "=================================================="

# Configuration
APP_NAME="whispercaprover"
CAPROVER_URL="https://captain.ishworks.website"
CAPROVER_TOKEN="718dbed697631ee134cfa77f2628917deaeeb72a750f063a1c08e145d29fb19d"
GIT_REPO="https://gitlab.captain.ishworks.website/audio/whispercaprover.git"

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

# Step 1: Login to CapRover
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

# Step 2: Clone the repository
clone_repository() {
    print_status "Cloning WhisperCapRover repository..."
    
    # Create a temporary directory
    TEMP_DIR="/tmp/whispercaprover-deploy"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Clone the repository
    git clone "$GIT_REPO" .
    
    if [ $? -eq 0 ]; then
        print_status "Repository cloned successfully!"
    else
        print_error "Failed to clone repository."
        exit 1
    fi
}

# Step 3: Deploy using CapRover CLI
deploy_app() {
    print_status "Deploying WhisperCapRover app..."
    
    # Deploy the app using CapRover CLI
    caprover app deploy --appName "$APP_NAME" --imageName "$GIT_REPO" --tarFile captain-definition
    
    if [ $? -eq 0 ]; then
        print_status "App deployment initiated successfully!"
    else
        print_error "Failed to deploy app."
        exit 1
    fi
}

# Step 4: Check deployment status
check_deployment() {
    print_status "Checking deployment status..."
    
    # Wait a bit for deployment to start
    sleep 10
    
    # Check app status
    caprover app status --appName "$APP_NAME"
    
    print_status "Deployment check completed!"
}

# Step 5: Health check
health_check() {
    print_status "Performing health check..."
    
    # Wait for deployment to complete
    sleep 30
    
    # Try to access the health endpoint
    HEALTH_URL="$CAPROVER_URL/$APP_NAME/health"
    print_status "Checking health endpoint: $HEALTH_URL"
    
    if curl -f "$HEALTH_URL" > /dev/null 2>&1; then
        print_status "Health check passed! Deployment successful!"
        print_status "Your WhisperCapRover server is now running at: $CAPROVER_URL/$APP_NAME"
    else
        print_warning "Health check failed. Please check CapRover logs."
        print_warning "You can check logs with: caprover app logs --appName $APP_NAME"
    fi
}

# Main deployment flow
main() {
    print_status "Starting WhisperCapRover deployment on Grogu server..."
    
    # Check if caprover CLI is available
    if ! command -v caprover &> /dev/null; then
        print_error "CapRover CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Run deployment steps
    login_to_caprover
    clone_repository
    deploy_app
    check_deployment
    health_check
    
    print_status "Deployment process completed!"
    print_status "You can monitor the deployment in the CapRover dashboard: $CAPROVER_URL"
}

# Run main function
main "$@" 