# WhisperCapRover Server

Real-time audio transcription server using WhisperLive for **streaming-only** word-by-word transcription. This server requires WhisperLive streaming and will not start without it.

## 🚀 Features

- **Streaming-Only**: **Requires** WhisperLive streaming - no fallback options
- **True Real-time Streaming**: Word-by-word transcription as you speak
- **Low Latency**: 200-800ms expected latency
- **WebSocket API**: Real-time audio streaming
- **CapRover Ready**: Production deployment configuration
- **Health Checks**: Built-in monitoring endpoints
- **Multiple Models**: Support for different Whisper model sizes

## 📁 Project Structure

```
whispercaprover-server/
├── server.py                  # Main server implementation
├── requirements.txt           # Python dependencies
├── Dockerfile.complete        # Production Docker image
├── captain-definition         # CapRover deployment config
├── deploy-simple.sh           # Simple deployment script
├── venv/                      # Virtual environment
├── README.md                  # This file
├── .dockerignore             # Docker ignore file
└── .gitignore                # Git ignore file
```

## 🛠️ Quick Start

### Local Development

1. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run server:**
   ```bash
   python server.py
   ```
   
   **Note:** All dependencies are included in the single requirements.txt file.

4. **Test health endpoint:**
   ```bash
   curl http://localhost:8000/health
   ```

### 🚀 Simple Docker Deployment

This project uses a **single Dockerfile** for easy deployment:

```bash
# Build the Docker image
docker build -f Dockerfile.complete -t whispercaprover-server .

# Run locally
docker run -p 8000:80 whispercaprover-server

# Deploy to CapRover
./deploy-simple.sh deploy
```

**Benefits:**
- ⚡ **Simple setup** - Single Dockerfile with all dependencies
- 🎯 **Easy deployment** - One command to deploy
- 🏠 **Production ready** - Optimized for CapRover deployment

### Alternative: Direct Docker Build

```bash
docker build -f Dockerfile.complete -t whispercaprover-server .
docker run -p 8000:80 whispercaprover-server
```

## 🌐 API Endpoints

### Health Check
- **GET** `/health` - Server health status
- **Response:** JSON with service status and metrics

### Root Info
- **GET** `/` - Service information
- **Response:** JSON with service details and endpoints

### WebSocket Transcription
- **WebSocket** `/transcribe` - Real-time audio transcription
- **Protocol:** WebSocket with JSON messages

## 🔧 Configuration

Environment variables:
- `WHISPER_MODEL`: Whisper model size (default: "base")
- `HOST`: Server host (default: "0.0.0.0")
- `PORT`: Server port (default: 8000)
- `LOG_LEVEL`: Logging level (default: "info")

## 🚀 CapRover Deployment

1. **One-Click Deploy:**
   - Use the `captain-definition` file
   - Deploy directly to CapRover

2. **Manual Deploy:**
   ```bash
   # Build and push to registry
   docker build -t your-registry/whispercaprover-server .
   docker push your-registry/whispercaprover-server
   ```

## 📊 Performance

- **Latency:** 200-800ms for real-time transcription
- **Streaming:** True word-by-word output
- **Concurrent Sessions:** Configurable via environment
- **Model Loading:** Automatic model download and caching

## 🔗 Integration

This server is designed to work with the `whispercaprover-client` for complete real-time transcription solutions.

## 🚀 Deployment

This project includes simple deployment options:
- **Local development** - Run with Python directly
- **Docker deployment** - Build and run with Docker
- **CapRover deployment** - Deploy to production with one command

**Last Updated:** 2024-12-30 - Simplified project structure 