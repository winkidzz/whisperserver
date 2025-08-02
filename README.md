# WhisperCapRover Server

Real-time audio transcription server using WhisperLive for true streaming with word-by-word output.

## 🚀 Features

- **True Real-time Streaming**: Word-by-word transcription as you speak
- **Low Latency**: 200-800ms expected latency
- **WebSocket API**: Real-time audio streaming
- **CapRover Ready**: Production deployment configuration
- **Health Checks**: Built-in monitoring endpoints
- **Multiple Models**: Support for different Whisper model sizes

## 📁 Project Structure

```
whispercaprover-server/
├── Dockerfile                 # Production Docker image
├── captain-definition         # CapRover deployment config
├── requirements.txt           # Python dependencies
├── server.py                  # Main server implementation
├── README.md                  # This file
└── .dockerignore             # Docker ignore file
```

## 🛠️ Quick Start

### Local Development

1. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Run server:**
   ```bash
   python server.py
   ```

3. **Test health endpoint:**
   ```bash
   curl http://localhost:8000/health
   ```

### Docker Build

```bash
docker build -t whispercaprover-server .
docker run -p 8000:8000 whispercaprover-server
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