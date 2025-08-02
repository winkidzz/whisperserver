# Local Deployment to CapRover Guide

This guide shows you how to build locally and deploy directly to CapRover from your Mac, keeping it updated automatically.

## 🚀 Deployment Options

### Option 1: Direct CapRover CLI Deployment (Recommended)

**Best for:** Full control, direct deployment, custom configurations

#### Prerequisites:
```bash
# Install CapRover CLI
npm install -g caprover

# Ensure Docker is running
docker --version
```

#### Quick Start:
```bash
# Run complete deployment
./deploy-local.sh all

# Or step by step:
./deploy-local.sh check    # Check prerequisites
./deploy-local.sh build    # Build Docker image
./deploy-local.sh deploy   # Deploy to CapRover
./deploy-local.sh health   # Check deployment health
```

#### Configuration:
Edit `deploy-local.sh` to customize:
- `APP_NAME`: Your CapRover app name
- `REGISTRY`: Your Docker registry (optional)
- `CAPROVER_URL`: Your CapRover instance URL
- `CAPROVER_TOKEN`: Your CapRover access token

### Option 2: Git-based Deployment (Simpler)

**Best for:** Automatic updates, CI/CD integration, team collaboration

#### Quick Start:
```bash
# Deploy and keep updated
./deploy-git.sh all

# Or step by step:
./deploy-git.sh check    # Check prerequisites
./deploy-git.sh deploy   # Create branch and push
./deploy-git.sh health   # Check deployment health
./deploy-git.sh cleanup  # Clean up deployment branch
```

#### How it works:
1. Creates a `deploy-local` branch
2. Updates `captain-definition` for local deployment
3. Pushes to trigger CapRover auto-deployment
4. Monitors deployment health

## 🔧 Setup Instructions

### 1. Install CapRover CLI
```bash
npm install -g caprover
```

### 2. Get CapRover Access Token
1. Go to your CapRover dashboard
2. Navigate to "Settings" → "Access Tokens"
3. Create a new token with appropriate permissions
4. Copy the token to use in deployment scripts

### 3. Configure Docker Registry (Optional)
If using a remote registry:
```bash
# Set your registry
export REGISTRY="your-docker-registry.com"
export DOCKER_USERNAME="your-username"
export DOCKER_PASSWORD="your-password"

# Login to registry
docker login $REGISTRY
```

### 4. Test Local Build
```bash
# Test the build process locally first
./test-ci-build.sh
```

## 📊 Deployment Workflows

### Workflow 1: Development → Local Deployment
```bash
# Make your changes
git add .
git commit -m "feat: new feature"

# Deploy locally
./deploy-local.sh all

# Or use git-based deployment
./deploy-git.sh all
```

### Workflow 2: Continuous Local Updates
```bash
# Set up automatic deployment
while true; do
    # Watch for changes
    inotifywait -r -e modify .
    
    # Deploy automatically
    ./deploy-local.sh deploy
    ./deploy-local.sh health
    
    sleep 30
done
```

### Workflow 3: Production Deployment
```bash
# Deploy to production
export APP_NAME="whispercaprover-prod"
export TAG="v1.0.0"
./deploy-local.sh all
```

## 🔍 Monitoring and Maintenance

### Health Checks
```bash
# Check deployment health
./deploy-local.sh health

# Or manually check
curl -f https://captain.ishworks.website/your-app/health
```

### Logs and Debugging
```bash
# View CapRover logs
caprover app logs --appName your-app-name

# View Docker logs
docker logs your-container-name
```

### Cleanup
```bash
# Clean up deployment branches
./deploy-git.sh cleanup

# Remove old Docker images
docker system prune -a
```

## 🛠️ Troubleshooting

### Common Issues:

1. **CapRover CLI not found:**
   ```bash
   npm install -g caprover
   ```

2. **Docker build fails:**
   ```bash
   # Test locally first
   ./test-ci-build.sh
   ```

3. **Deployment fails:**
   ```bash
   # Check CapRover logs
   caprover app logs --appName your-app-name
   ```

4. **Health check fails:**
   ```bash
   # Wait longer for deployment
   sleep 120
   ./deploy-local.sh health
   ```

### Performance Optimization:

1. **Use Docker layer caching:**
   ```bash
   # Build with cache
   docker build --cache-from your-image:latest -t your-image:latest .
   ```

2. **Optimize image size:**
   ```bash
   # Use multi-stage builds
   docker build --target production -t your-image:latest .
   ```

3. **Parallel deployments:**
   ```bash
   # Deploy multiple instances
   for i in {1..3}; do
     export APP_NAME="whispercaprover-$i"
     ./deploy-local.sh deploy &
   done
   wait
   ```

## 📈 Advanced Features

### Environment-Specific Deployments
```bash
# Development
export ENV="dev"
export WHISPER_MODEL="tiny"
./deploy-local.sh all

# Staging
export ENV="staging"
export WHISPER_MODEL="base"
./deploy-local.sh all

# Production
export ENV="prod"
export WHISPER_MODEL="medium"
./deploy-local.sh all
```

### Blue-Green Deployment
```bash
# Deploy to blue environment
export APP_NAME="whispercaprover-blue"
./deploy-local.sh deploy

# Test blue deployment
./deploy-local.sh health

# Switch traffic to blue
# (Update load balancer configuration)

# Deploy to green environment
export APP_NAME="whispercaprover-green"
./deploy-local.sh deploy
```

### Automated Rollbacks
```bash
# Deploy with rollback capability
./deploy-local.sh deploy

# If health check fails, rollback
if ! ./deploy-local.sh health; then
    echo "Deployment failed, rolling back..."
    caprover app rollback --appName your-app-name
fi
```

## 🎯 Best Practices

1. **Always test locally first** using `./test-ci-build.sh`
2. **Use semantic versioning** for your Docker images
3. **Monitor deployment health** after each deployment
4. **Keep deployment scripts in version control**
5. **Use environment variables** for configuration
6. **Implement proper logging** for debugging
7. **Set up monitoring** for production deployments

## 📞 Support

For deployment issues:
1. Check the troubleshooting section above
2. Review CapRover logs
3. Test locally first
4. Check network connectivity to CapRover

---

**Status**: ✅ Ready for Production Use
**Last Updated**: 2024-12-30
**Version**: 1.0.0 