# WhisperCapRover Server

Real-time audio transcription server using WhisperLiveKit for streaming voice-to-text conversion.

## Features

- **Real-time streaming transcription** using WhisperLiveKit
- **WebSocket-based communication** for low-latency audio streaming
- **Speaker diarization** support (optional)
- **Multiple language support** via Whisper models
- **CapRover deployment ready** with Docker support
- **Async processing** for optimal performance

## Architecture

The server uses WhisperLiveKit's streaming API to provide real-time transcription:

1. **WebSocket Connection**: Clients connect via WebSocket to `/transcribe`
2. **Audio Streaming**: Raw audio bytes are streamed directly to the server
3. **Real-time Processing**: WhisperLiveKit processes audio chunks asynchronously
4. **Live Results**: Transcription results are sent back to clients in real-time

## Installation

### Prerequisites

- Python 3.8+
- FFmpeg (for audio processing)

### Install FFmpeg

```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Windows
# Download from https://ffmpeg.org/download.html and add to PATH
```

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Optional Dependencies

For enhanced functionality:

```bash
# Speaker diarization
pip install diart

# Voice Activity Controller
pip install torch

# Sentence-based buffer trimming
pip install mosestokenizer wtpsplit
```

## Usage

### Start the Server

```bash
python server.py
```

The server will start on `localhost:8000` by default.

### Environment Variables

- `HOST`: Server host (default: `0.0.0.0`)
- `PORT`: Server port (default: `8000`)
- `WHISPER_MODEL`: Whisper model size (default: `base`)
- `WHISPER_LANGUAGE`: Source language (default: `en`)
- `WHISPER_DIARIZATION`: Enable speaker diarization (default: `false`)
- `LOG_LEVEL`: Logging level (default: `info`)

### Test the Server

```bash
# Test without microphone
python test_whisper.py

# Test with microphone
python test_client.py

# Test with microphone (verbose)
python test_client.py --microphone
```

## WebSocket API

### Connection

Connect to `ws://localhost:8000/transcribe`

### Message Format

The server expects raw audio bytes sent directly via WebSocket.

### Response Format

```json
{
  "type": "transcription",
  "text": "transcribed text",
  "is_final": true,
  "confidence": 0.95,
  "language": "en",
  "processing_time": 0.5,
  "timestamp": 1234567890.123,
  "partial": false,
  "speaker": 1,
  "lines": [...],
  "buffer_transcription": "",
  "buffer_diarization": "",
  "segment_id": "session-1234567890-123"
}
```

### Special Messages

- `ready_to_stop`: Sent when processing is complete
- `connection_established`: Sent when WebSocket connection is established

## Client Example

```python
import asyncio
import websockets
import pyaudio

async def transcribe_audio():
    async with websockets.connect('ws://localhost:8000/transcribe') as websocket:
        # Send raw audio bytes
        audio_data = b'...'  # Your audio data
        await websocket.send(audio_data)
        
        # Receive transcription
        response = await websocket.recv()
        data = json.loads(response)
        print(f"Transcription: {data['text']}")
```

## Deployment

### CapRover Deployment

1. Ensure your `captain-definition` file is configured
2. Deploy to CapRover using the provided script:

```bash
./deploy-simple.sh
```

### Docker Deployment

```bash
# Build image
docker build -t whispercaprover .

# Run container
docker run -p 8000:8000 whispercaprover
```

## Models

Available Whisper models:
- `tiny` - Fastest, least accurate
- `base` - Good balance (default)
- `small` - Better accuracy
- `medium` - High accuracy
- `large` - Best accuracy, slowest

## Performance

- **Latency**: ~200-500ms for real-time transcription
- **Memory**: Varies by model size (tiny: ~1GB, large: ~10GB)
- **CPU**: Moderate usage, benefits from GPU acceleration
- **Concurrent Sessions**: Limited by available memory

## Troubleshooting

### Common Issues

1. **Import Error**: Ensure WhisperLiveKit is installed
   ```bash
   pip install whisperlivekit
   ```

2. **Audio Issues**: Check microphone permissions and audio format
   - Sample rate: 16kHz
   - Format: 16-bit PCM
   - Channels: Mono

3. **Memory Issues**: Use smaller models for limited resources
   ```bash
   export WHISPER_MODEL=tiny
   ```

4. **Performance Issues**: Enable GPU acceleration if available
   ```bash
   pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```

### Logs

Check server logs for detailed error information:
```bash
python server.py 2>&1 | tee server.log
```

## License

This project is licensed under the MIT License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Acknowledgments

- [WhisperLiveKit](https://github.com/QuentinFuxa/WhisperLiveKit) - Real-time streaming transcription
- [OpenAI Whisper](https://github.com/openai/whisper) - Speech recognition model
- [FastAPI](https://fastapi.tiangolo.com/) - Web framework 