# WhisperCapRover Server - CapRover Deployment Guide

## 🚀 Best Practices for CapRover Deployment

### 📋 Prerequisites

1. **CapRover Instance**: Running CapRover server
2. **Domain**: Configured domain for your CapRover instance
3. **Git Repository**: Code pushed to GitHub/GitLab
4. **SSL Certificate**: CapRover will auto-generate Let's Encrypt certificates

### 🏗️ Deployment Options

#### Option 1: One-Click Deploy (Recommended)

1. **Access CapRover Dashboard**
   ```
   https://your-caprover-domain.com
   ```

2. **Go to One-Click Apps**
   - Click "One-Click Apps" in the sidebar
   - Search for "WhisperCapRover Server" or use custom template

3. **Configure Deployment**
   ```json
   {
     "appName": "whispercaprover-server",
     "imageName": "your-registry/whispercaprover-server:latest",
     "containerHttpPort": "8000",
     "environmentVariables": {
       "WHISPER_MODEL": "base",
       "MAX_CONNECTIONS": "10",
       "LOG_LEVEL": "info"
     }
   }
   ```

#### Option 2: Manual Deploy

1. **Build and Push Docker Image**
   ```bash
   # Build the image
   cd whispercaprover-server
   docker build -t your-registry/whispercaprover-server:latest .
   
   # Push to registry
   docker push your-registry/whispercaprover-server:latest
   ```

2. **Deploy via CapRover Dashboard**
   - Go to "Apps" → "One-Click Apps"
   - Select "Custom App"
   - Use the `captain-definition` file

#### Option 3: Git-Based Deploy

1. **Push Code to Repository**
   ```bash
   git add .
   git commit -m "Ready for CapRover deployment"
   git push origin main
   ```

2. **Deploy via CapRover**
   - Go to "Apps" → "One-Click Apps"
   - Select "Git Repository"
   - Enter your repository URL
   - CapRover will use the `captain-definition` file

### ⚙️ Configuration

#### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WHISPER_MODEL` | `base` | Whisper model size (tiny, base, small, medium, large) |
| `MAX_CONNECTIONS` | `10` | Maximum concurrent WebSocket connections |
| `LOG_LEVEL` | `info` | Logging level (debug, info, warning, error) |
| `HOST` | `0.0.0.0` | Server host binding |
| `PORT` | `8000` | Server port |
| `WHISPER_CACHE_DIR` | `/app/cache` | Whisper model cache directory |

#### Model Selection Guide

| Model | Size | Speed | Accuracy | Use Case |
|-------|------|-------|----------|----------|
| `tiny` | ~39MB | Fastest | Basic | Development/Testing |
| `base` | ~74MB | Fast | Good | Production (Recommended) |
| `small` | ~244MB | Medium | Better | High accuracy needed |
| `medium` | ~769MB | Slow | High | Premium service |
| `large` | ~1550MB | Slowest | Best | Maximum accuracy |

### 🔧 Performance Optimization

#### Resource Allocation

**Minimum Requirements:**
- **CPU**: 1 core
- **RAM**: 2GB
- **Storage**: 5GB

**Recommended for Production:**
- **CPU**: 2-4 cores
- **RAM**: 4-8GB
- **Storage**: 10GB

#### Scaling Configuration

```json
{
  "instanceCount": 2,
  "maxInstanceCount": 5,
  "notExposeAsWebApp": false,
  "containerHttpPort": "8000",
  "healthCheckPath": "/health"
}
```

### 🔒 Security Best Practices

1. **Non-Root User**: Container runs as non-root user (UID 1000)
2. **Health Checks**: Robust health check endpoint
3. **Resource Limits**: Set CPU and memory limits
4. **Network Security**: Use CapRover's built-in SSL/TLS
5. **Environment Variables**: Sensitive data via CapRover secrets

### 📊 Monitoring

#### Health Check Endpoint
```
GET https://your-app.caprover-domain.com/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": 1754111491.0324047,
  "service": "whispercaprover-server",
  "model": "base",
  "active_sessions": 0,
  "version": "1.0.0"
}
```

#### Logs
- Access logs via CapRover dashboard
- Log level configurable via `LOG_LEVEL` environment variable
- Structured JSON logging for production

### 🚨 Troubleshooting

#### Common Issues

1. **Container Won't Start**
   - Check resource allocation
   - Verify environment variables
   - Check logs for dependency issues

2. **Health Check Fails**
   - Increase `start-period` in health check
   - Verify port configuration
   - Check application logs

3. **High Memory Usage**
   - Reduce `MAX_CONNECTIONS`
   - Use smaller Whisper model
   - Monitor for memory leaks

4. **SSL Issues**
   - Verify domain configuration
   - Check Let's Encrypt certificate
   - Ensure proper DNS setup

#### Debug Commands

```bash
# Check container status
docker ps

# View logs
docker logs whispercaprover-server

# Check resource usage
docker stats whispercaprover-server

# Access container shell
docker exec -it whispercaprover-server /bin/bash
```

### 🔄 Updates and Maintenance

#### Rolling Updates
1. Build new Docker image
2. Push to registry
3. CapRover will automatically update with zero downtime

#### Backup Strategy
- Models cached in `/app/cache`
- Configuration via environment variables
- No persistent data to backup

#### Maintenance Window
- Schedule during low-traffic periods
- Use CapRover's rolling update feature
- Monitor health checks during updates

### 📈 Scaling Strategy

#### Horizontal Scaling
- Multiple instances behind load balancer
- Session affinity for WebSocket connections
- Shared model cache (if needed)

#### Vertical Scaling
- Increase CPU/RAM allocation
- Use larger Whisper models
- Optimize buffer sizes

### 🎯 Production Checklist

- [ ] SSL certificate configured
- [ ] Health checks passing
- [ ] Resource limits set
- [ ] Logging configured
- [ ] Monitoring enabled
- [ ] Backup strategy in place
- [ ] Scaling plan defined
- [ ] Security measures implemented
- [ ] Performance tested
- [ ] Documentation updated

### 📞 Support

For deployment issues:
1. Check CapRover logs
2. Verify configuration
3. Test locally first
4. Review this documentation

---

**Status**: ✅ Production Ready
**Last Updated**: 2024
**Version**: 1.0.0 