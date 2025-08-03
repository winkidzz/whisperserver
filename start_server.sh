#!/bin/bash

# WhisperCapRover Server Startup Script
# This script sets up the environment and starts the transcription server

set -e  # Exit on any error

echo "🎤 WhisperCapRover Server Startup Script"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Python is installed
print_step "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
print_status "Python version: $PYTHON_VERSION"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_step "Creating virtual environment..."
    python3 -m venv venv
    print_status "Virtual environment created successfully"
else
    print_status "Virtual environment already exists"
fi

# Activate virtual environment
print_step "Activating virtual environment..."
source venv/bin/activate

# Check if requirements are installed
print_step "Checking dependencies..."
if ! python -c "import whisper, fastapi, uvicorn, webrtcvad" 2>/dev/null; then
    print_warning "Dependencies not found. Installing requirements..."
    pip install -r requirements.txt
    print_status "Dependencies installed successfully"
else
    print_status "Dependencies already installed"
fi

# Create logs directory if it doesn't exist
if [ ! -d "logs" ]; then
    print_step "Creating logs directory..."
    mkdir -p logs
    print_status "Logs directory created"
fi

# Set environment variables
print_step "Setting up environment variables..."
export WHISPER_DEBUG=true
export WHISPER_MODEL=base
export HOST=0.0.0.0
export PORT=8000

print_status "Environment variables set:"
print_status "  - WHISPER_DEBUG=true (debug mode enabled)"
print_status "  - WHISPER_MODEL=base (using base model)"
print_status "  - HOST=0.0.0.0 (listen on all interfaces)"
print_status "  - PORT=8000 (server port)"

# Check if port is available
print_step "Checking if port 8000 is available..."
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    print_warning "Port 8000 is already in use. Attempting to kill existing process..."
    pkill -f "python server.py" || true
    sleep 2
fi

# Start the server
print_step "Starting WhisperCapRover Server..."
echo ""
echo "🚀 Server starting on http://localhost:8000"
echo "📝 Logs will be written to logs/server.log"
echo "🧪 Test with: python test_vad_bypass.py"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start server with logging
python server.py 2>&1 | tee logs/server.log 