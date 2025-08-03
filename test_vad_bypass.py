#!/usr/bin/env python3
"""
Test VAD bypass to verify transcription works
"""

import asyncio
import websockets
import json
import time
import logging
import wave
import numpy as np

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_vad_bypass():
    """Test transcription by bypassing VAD temporarily."""
    server_url = "ws://localhost:8000/ws/audio"
    wav_file = "recording_20250802_193938.wav"
    
    print("🎤 Testing VAD Bypass")
    print("=" * 30)
    
    try:
        # Connect to WebSocket server
        websocket = await websockets.connect(server_url)
        
        # Wait for welcome message
        welcome_msg = await websocket.recv()
        welcome_data = json.loads(welcome_msg)
        print(f"✅ Connected! Model: {welcome_data.get('model', 'Unknown')}")
        
        # Read entire WAV file and send as one chunk
        with wave.open(wav_file, 'rb') as wav:
            frames = wav.readframes(wav.getnframes())
        
        print(f"📤 Sending entire audio file ({len(frames)} bytes)...")
        await websocket.send(frames)
        print("✅ Audio sent")
        
        # Wait for transcription
        print("🎧 Waiting for transcription...")
        start_time = time.time()
        
        while time.time() - start_time < 30:
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                data = json.loads(message)
                
                if data.get("type") == "transcription":
                    text = data.get('text', '')
                    print(f"📝 Transcription: '{text}'")
                    if text.strip():
                        print(f"🎉 SUCCESS! Transcription: '{text}'")
                        await websocket.close()
                        return True
                        
            except asyncio.TimeoutError:
                print(".", end="", flush=True)
                continue
        
        print("\n⏰ Timeout - no transcription received")
        await websocket.close()
        return False
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.run(test_vad_bypass())
    if success:
        print("\n🎉 VAD bypass test successful!")
    else:
        print("\n💥 VAD bypass test failed!")
        exit(1) 