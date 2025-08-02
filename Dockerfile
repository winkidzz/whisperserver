# Multi-stage build for optimized production image
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    portaudio19-dev \
    libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim as production

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    curl \
    portaudio19-dev \
    libasound2-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy application files
COPY server.py .

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs /app/models /app/cache && \
    chown -R 1000:1000 /app

# Set environment variables for production
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV WHISPER_MODEL=base
ENV HOST=0.0.0.0
ENV PORT=8000
ENV MAX_CONNECTIONS=10
ENV LOG_LEVEL=info
ENV WHISPER_CACHE_DIR=/app/cache

# Expose port
EXPOSE 8000

# Health check for CapRover (more robust)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash --uid 1000 app && \
    chown -R app:app /app

# Switch to non-root user
USER app

# Run the server with proper signal handling
CMD ["python", "server.py"] 