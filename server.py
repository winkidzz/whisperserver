#!/usr/bin/env python3
"""
WhisperCapRover Server - Real-time Audio Transcription
Provides true streaming transcription with word-by-word output using WhisperLive
"""

import asyncio
import json
import base64
import numpy as np
import time
import logging
import os
from typing import Dict, Any, Optional
from dataclasses import dataclass
from collections import deque
import threading
import queue

# FastAPI imports for CapRover deployment
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
import uvicorn

# Import WhisperLive for true streaming
try:
    from whisper_live.client import TranscriptionClient
    WHISPERLIVE_AVAILABLE = True
    logging.info("WhisperLive library available - streaming transcription enabled")
except ImportError as e:
    WHISPERLIVE_AVAILABLE = False
    logging.error(f"WhisperLive library not available: {e}")
    raise RuntimeError("WhisperLive streaming is required but not available. Please install whisper-live library.")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class StreamingTranscriptionResult:
    """Represents a streaming transcription result."""
    text: str
    is_final: bool
    confidence: float
    language: str
    processing_time: float
    timestamp: float
    words: list = None
    partial: bool = False

class WhisperCapRoverTranscriber:
    """Real-time transcription using WhisperLive."""
    
    def __init__(self, model_name: str = "base"):
        self.model_name = model_name
        self.transcriber = None
        self.audio_buffer = deque(maxlen=16000 * 5)  # 5 seconds buffer for streaming
        self.is_processing = False
        self.processing_thread = None
        self.result_queue = queue.Queue()
        self.last_transcription = ""
        self.partial_text = ""
        
        # Initialize the transcriber
        self._load_transcriber()
    
    def _load_transcriber(self):
        """Load the WhisperLive transcriber."""
        try:
            logger.info(f"Loading WhisperLive model: {self.model_name}")
            # Initialize WhisperLive client for real-time transcription
            self.transcriber = TranscriptionClient(
                host="localhost",
                port=6006,
                model=self.model_name,
                lang="en"
            )
            logger.info("WhisperLive transcriber initialized successfully")
                
        except Exception as e:
            logger.error(f"Failed to load WhisperLive transcriber: {e}")
            raise
    
    def add_audio(self, audio_data: bytes):
        """Add audio data to the buffer for processing."""
        # Convert bytes to numpy array
        audio_array = np.frombuffer(audio_data, dtype=np.int16)
        audio_float = audio_array.astype(np.float32) / 32768.0
        
        # Add to buffer
        self.audio_buffer.extend(audio_float)
        
        # Start processing if not already running
        if not self.is_processing:
            self._start_processing()
    
    def _start_processing(self):
        """Start the processing thread."""
        if self.processing_thread is None or not self.processing_thread.is_alive():
            self.is_processing = True
            self.processing_thread = threading.Thread(target=self._process_audio_stream)
            self.processing_thread.daemon = True
            self.processing_thread.start()
    
    def _process_audio_stream(self):
        """Process audio stream in background thread using WhisperLive streaming."""
        if not WHISPERLIVE_AVAILABLE:
            raise RuntimeError("WhisperLive streaming is required but not available.")
        self._process_with_whisperlive()
    
    def _process_with_whisperlive(self):
        """Process with WhisperLive for true streaming."""
        try:
            logger.info("Starting WhisperLive transcription process")
            
            # Connect to WhisperLive server
            self.transcriber.connect()
            
            while self.is_processing:
                if len(self.audio_buffer) >= 16000 * 2:  # 2 seconds of audio
                    try:
                        # Get audio chunk
                        audio_chunk = np.array(list(self.audio_buffer)[-16000 * 2:])
                        
                        # Send audio to WhisperLive server
                        start_time = time.time()
                        result = self.transcriber.transcribe(audio_chunk)
                        processing_time = time.time() - start_time
                        
                        if result and result.text.strip():
                            text = result.text.strip()
                            
                            # Check if this is new content
                            if text != self.last_transcription:
                                # Create result
                                transcription = StreamingTranscriptionResult(
                                    text=text,
                                    is_final=result.is_final,
                                    confidence=result.confidence if hasattr(result, 'confidence') else 0.95,
                                    language=result.language if hasattr(result, 'language') else "en",
                                    processing_time=processing_time,
                                    timestamp=time.time(),
                                    partial=not result.is_final
                                )
                                
                                # Add to result queue
                                self.result_queue.put(transcription)
                                
                                # Update last transcription
                                self.last_transcription = text
                                
                                logger.info(f"WhisperLive: '{text}' (final: {result.is_final}, time: {processing_time:.2f}s)")
                        
                    except Exception as e:
                        logger.error(f"Error in WhisperLive processing: {e}")
                    
                    # Delay for streaming processing
                    time.sleep(0.1)
                else:
                    time.sleep(0.05)
                    
        except Exception as e:
            logger.error(f"Error in WhisperLive streaming: {e}")
            raise RuntimeError(f"WhisperLive streaming failed: {e}")
    

    
    def get_results(self) -> list:
        """Get all available transcription results."""
        results = []
        while not self.result_queue.empty():
            try:
                results.append(self.result_queue.get_nowait())
            except queue.Empty:
                break
        return results
    
    def stop(self):
        """Stop the processing thread."""
        self.is_processing = False
        if self.processing_thread:
            self.processing_thread.join(timeout=1.0)

class WhisperCapRoverServer:
    """FastAPI server for real-time transcription."""
    
    def __init__(self):
        self.app = FastAPI(
            title="WhisperCapRover Server",
            description="Real-time audio transcription using WhisperLive",
            version="1.0.0"
        )
        self.transcriber = None
        self.active_sessions: Dict[str, Dict[str, Any]] = {}
        self.setup_routes()
    
    def setup_routes(self):
        """Setup FastAPI routes."""
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint for CapRover."""
            return JSONResponse({
                "status": "healthy",
                "timestamp": time.time(),
                "service": "whispercaprover-server",
                "model": os.getenv("WHISPER_MODEL", "base"),
                "streaming_enabled": True,
                "streaming_type": "word-by-word",
                "active_sessions": len(self.active_sessions),
                "version": "1.0.0"
            })
        
        @self.app.get("/")
        async def root():
            """Root endpoint with service info."""
            return JSONResponse({
                "service": "WhisperCapRover Server",
                "version": "1.0.0",
                "description": "Real-time audio transcription using WhisperLive streaming",
                "streaming_type": "word-by-word",
                "streaming_required": True,
                "endpoints": {
                    "websocket": "/transcribe",
                    "health": "/health",
                    "docs": "/docs"
                },
                "model": os.getenv("WHISPER_MODEL", "base"),
                "status": "running"
            })
        
        @self.app.websocket("/transcribe")
        async def websocket_endpoint(websocket: WebSocket):
            """WebSocket endpoint for real-time transcription."""
            await websocket.accept()
            await self.handle_websocket(websocket)
    
    async def handle_websocket(self, websocket: WebSocket):
        """Handle WebSocket connections."""
        session_id = f"session-{int(time.time() * 1000)}"
        client_address = websocket.client.host if websocket.client else "unknown"
        
        logger.info(f"New connection from {client_address}: {session_id}")
        
        # Initialize session
        self.active_sessions[session_id] = {
            "websocket": websocket,
            "start_time": time.time(),
            "audio_buffer": deque(maxlen=16000 * 5),
            "last_transcription": None
        }
        
        try:
            # Send welcome message
            welcome_msg = {
                "type": "connection_established",
                "session_id": session_id,
                "message": "Connected to WhisperCapRover Server",
                "streaming_type": "word-by-word"
            }
            await websocket.send_text(json.dumps(welcome_msg))
            
            # Handle messages
            while True:
                try:
                    message = await websocket.receive_text()
                    await self.handle_message(session_id, message)
                except WebSocketDisconnect:
                    break
                    
        except Exception as e:
            logger.error(f"Error handling connection {session_id}: {e}")
        finally:
            # Cleanup session
            if session_id in self.active_sessions:
                del self.active_sessions[session_id]
            logger.info(f"Session ended: {session_id}")
    
    async def handle_message(self, session_id: str, message: str):
        """Handle incoming WebSocket messages."""
        try:
            data = json.loads(message)
            msg_type = data.get("type")
            
            if msg_type == "start_session":
                await self.handle_start_session(session_id, data)
            elif msg_type == "audio_chunk":
                await self.handle_audio_chunk(session_id, data)
            elif msg_type == "end_session":
                await self.handle_end_session(session_id, data)
            else:
                logger.warning(f"Unknown message type: {msg_type}")
                
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON message from {session_id}")
        except Exception as e:
            logger.error(f"Error handling message from {session_id}: {e}")
    
    async def handle_start_session(self, session_id: str, data: dict):
        """Handle session start."""
        logger.info(f"Session started: {session_id}")
        
        # Send session confirmation
        response = {
            "type": "session_started",
            "session_id": session_id,
            "timestamp": time.time(),
            "streaming_type": "word-by-word"
        }
        await self.active_sessions[session_id]["websocket"].send_text(json.dumps(response))
    
    async def handle_audio_chunk(self, session_id: str, data: dict):
        """Handle incoming audio chunk."""
        try:
            # Decode audio data
            audio_base64 = data.get("data", "")
            audio_data = base64.b64decode(audio_base64)
            
            # Add to transcriber
            self.transcriber.add_audio(audio_data)
            
            # Check for transcription results
            results = self.transcriber.get_results()
            for result in results:
                await self.send_transcription(session_id, result)
                
        except Exception as e:
            logger.error(f"Error processing audio chunk: {e}")
    
    async def handle_end_session(self, session_id: str, data: dict):
        """Handle session end."""
        logger.info(f"Session ending: {session_id}")
        
        # Send session end confirmation
        response = {
            "type": "session_ended",
            "session_id": session_id,
            "timestamp": time.time()
        }
        await self.active_sessions[session_id]["websocket"].send_text(json.dumps(response))
    
    async def send_transcription(self, session_id: str, result: StreamingTranscriptionResult):
        """Send transcription result to client."""
        if session_id not in self.active_sessions:
            return
        
        try:
            message = {
                "type": "transcription",
                "text": result.text,
                "is_final": result.is_final,
                "confidence": result.confidence,
                "language": result.language,
                "processing_time": result.processing_time,
                "timestamp": result.timestamp,
                "partial": result.partial,
                "words": result.words,
                "segment_id": f"{session_id}-{int(result.timestamp * 1000)}"
            }
            
            await self.active_sessions[session_id]["websocket"].send_text(json.dumps(message))
            
        except Exception as e:
            logger.error(f"Error sending transcription to {session_id}: {e}")
    
    def initialize_transcriber(self):
        """Initialize the Whisper transcriber."""
        model_name = os.getenv("WHISPER_MODEL", "base")
        logger.info(f"Initializing transcriber with model: {model_name}")
        self.transcriber = WhisperCapRoverTranscriber(model_name=model_name)

def main():
    """Main function for CapRover deployment."""
    # Get configuration from environment
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    log_level = os.getenv("LOG_LEVEL", "info").lower()
    
    # Validate log level
    valid_levels = ["critical", "error", "warning", "info", "debug", "trace"]
    if log_level not in valid_levels:
        log_level = "info"
    
    # Verify WhisperLive is available before starting
    if not WHISPERLIVE_AVAILABLE:
        raise RuntimeError("WhisperLive streaming is required but not available. Cannot start server.")
    
    # Create server
    server = WhisperCapRoverServer()
    server.initialize_transcriber()
    
    # Start FastAPI server
    logger.info(f"Starting WhisperCapRover Server on {host}:{port}")
    logger.info("WhisperLive streaming enabled - word-by-word transcription")
    uvicorn.run(
        server.app,
        host=host,
        port=port,
        log_level=log_level,
        access_log=True
    )

if __name__ == "__main__":
    main() # Test comment for caching
