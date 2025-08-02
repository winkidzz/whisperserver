#!/bin/bash

# Git-based Deployment to CapRover
# This script pushes to a git branch and lets CapRover auto-deploy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BRANCH="deploy-local"
REMOTE="origin"
CAPROVER_URL="https://captain.ishworks.website"

echo -e "${BLUE}🚀 Git-based Deployment to CapRover${NC}"
echo "=========================================="

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
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        print_error "Not in a git repository. Please run this from the project root."
        exit 1
    fi
    
    # Check if remote exists
    if ! git remote get-url "$REMOTE" > /dev/null 2>&1; then
        print_error "Remote '$REMOTE' not found. Please add your git remote."
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Create deployment branch
create_deploy_branch() {
    print_status "Creating deployment branch..."
    
    # Check if branch exists
    if git show-ref --verify --quiet refs/heads/"$BRANCH"; then
        print_warning "Branch $BRANCH already exists. Switching to it..."
        git checkout "$BRANCH"
        git pull "$REMOTE" "$BRANCH" || true
    else
        print_status "Creating new branch $BRANCH..."
        git checkout -b "$BRANCH"
    fi
}

# Update captain-definition for local deployment
update_captain_definition() {
    print_status "Updating captain-definition for local deployment..."
    
    # Create a local deployment configuration
    cat > captain-definition.local << EOF
{
  "schemaVersion": 2,
  "dockerfilePath": "./Dockerfile",
  "expose": [
    {
      "httpPort": 8000,
      "httpsPort": 443
    }
  ],
  "environmentVariables": {
    "WHISPER_MODEL": "base",
    "HOST": "0.0.0.0",
    "PORT": "8000",
    "LOG_LEVEL": "info",
    "MAX_CONNECTIONS": "10",
    "WHISPER_CACHE_DIR": "/app/cache"
  },
  "notExposeAsWebApp": false,
  "containerHttpPort": "8000",
  "description": "Local deployment of WhisperCapRover Server"
}
EOF
    
    # Use the local configuration
    cp captain-definition.local captain-definition
}

# Commit and push changes
commit_and_push() {
    print_status "Committing and pushing changes..."
    
    # Add all changes
    git add .
    
    # Commit with timestamp
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    git commit -m "deploy: local deployment $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Push to remote
    git push "$REMOTE" "$BRANCH"
    
    if [ $? -eq 0 ]; then
        print_status "Successfully pushed to $REMOTE/$BRANCH"
    else
        print_error "Failed to push to remote."
        exit 1
    fi
}

# Health check
health_check() {
    print_status "Waiting for CapRover to deploy..."
    sleep 60
    
    # Try to check health endpoint
    HEALTH_URL="${CAPROVER_URL}/whispercaprover/health"
    print_status "Checking health endpoint: ${HEALTH_URL}"
    
    if curl -f "${HEALTH_URL}" > /dev/null 2>&1; then
        print_status "Health check passed! Deployment successful!"
        print_status "🌐 Your app is available at: ${CAPROVER_URL}/whispercaprover"
    else
        print_warning "Health check failed. Please check CapRover dashboard."
        print_warning "Dashboard: ${CAPROVER_URL}"
    fi
}

# Cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Switch back to main branch
    git checkout main
    
    # Delete local deployment branch
    if git show-ref --verify --quiet refs/heads/"$BRANCH"; then
        git branch -D "$BRANCH"
    fi
    
    print_status "Cleanup completed!"
}

# Main deployment flow
main() {
    case "${1:-all}" in
        "check")
            check_prerequisites
            ;;
        "deploy")
            check_prerequisites
            create_deploy_branch
            update_captain_definition
            commit_and_push
            ;;
        "health")
            health_check
            ;;
        "cleanup")
            cleanup
            ;;
        "all")
            check_prerequisites
            create_deploy_branch
            update_captain_definition
            commit_and_push
            health_check
            ;;
        *)
            echo "Usage: $0 [check|deploy|health|cleanup|all]"
            echo ""
            echo "Commands:"
            echo "  check   - Check prerequisites"
            echo "  deploy  - Create branch and push for deployment"
            echo "  health  - Check deployment health"
            echo "  cleanup - Clean up deployment branch"
            echo "  all     - Run complete deployment (default)"
            echo ""
            echo "This will:"
            echo "  1. Create a deployment branch"
            echo "  2. Update captain-definition"
            echo "  3. Push to trigger CapRover deployment"
            echo "  4. Check deployment health"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 