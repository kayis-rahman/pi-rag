# Deploying Pi-RAG on Raspberry Pi 5 with Docker

This guide walks you through deploying the synapse system on a Raspberry Pi 5 using Docker with remote context. The deployment runs the embedding model locally on the Pi while offloading the chat model to your external GPU server.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Quick Start](#quick-start)
- [Manual Deployment Steps](#manual-deployment-steps)
- [Configuration](#configuration)
- [Docker Volume Management](#docker-volume-management)
- [Monitoring and Debugging](#monitoring-and-debugging)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### On Raspberry Pi 5

1. **Raspberry Pi OS 64-bit Lite** (recommended) or Full
2. **Docker installed** on Pi:
   ```bash
   # Install Docker
   curl -sSL https://get.docker.com | sh
   
   # Add user to docker group
   sudo usermod -aG docker pi
   
   # Enable Docker on boot
   sudo systemctl enable docker
   ```

3. **SSH access** to Pi
4. **At least 8GB RAM** (Pi 5 8GB model recommended)
5. **Network access** to external GPU server
6. **16GB+ storage** (for models, data, and containers)

### On Local Machine (Development Machine)

1. **Docker Desktop** or **Docker Engine** installed
2. **Docker context** configured for Pi:
   ```bash
   # Create Docker context for Pi
   docker context create pi --docker "host=ssh://pi@raspberrypi.local"
   
   # Or with IP address
   docker context create pi --docker "host=ssh://pi@192.168.1.100"
   
   # Verify context
   docker context ls
   ```

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│              Raspberry Pi 5 (8GB RAM)                    │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │   Docker Container (synapse)                        │  │
│  │                                                    │  │
│  │   ┌────────────────────────────────────────────┐    │  │
│  │   │   FastAPI Server (uvicorn)               │    │  │
│  │   │   Port: 8001                             │    │  │
│  │   └────────────────────────────────────────────┘    │  │
│  │                                                    │  │
│  │   ┌────────────────────────────────────────────┐    │  │
│  │   │   Orchestrator                        │    │  │
│  │   │   ├─ Retriever                         │    │  │
│  │   │   ├─ Model Manager                   │    │  │
│  │   │   └─ External API Client             │    │  │
│  │   └────────────────────────────────────────────┘    │  │
│  │                                                    │  │
│  │   ┌────────────────────────────────────────────┐    │  │
│  │   │   Local Models (on Pi)                   │    │  │
│  │   │   └─ nomic-embed-text-v1.5 Q4_K_M      │    │  │
│  │   └────────────────────────────────────────────┘    │  │
│  │                                                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│   Docker Volumes:                                         │
│   - synapse-models: GGUF model storage                     │
│   - synapse-data: Vector store & documents                 │
│   - synapse-cache: Pip/HF cache                           │
│                                                           │
└───────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              │
                              ▼
┌───────────────────────────────────────────────────────────┐
│         External GPU Server (Your LLM Server)           │
│                                                           │
│   Qwen3-Coder-30B-A3B-Instruct                          │
│   https://u425-afb3-687d7019.singapore-a.gpuhub.com     │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

**Key Components:**

- **Embedding Model**: `nomic-embed-text-v1.5 Q4_K_M` (~350MB) runs on Pi
- **Chat Model**: Qwen3-Coder-30B via external API
- **Vector Store**: ChromaDB with persistent storage
- **API Server**: FastAPI on port 8001
- **Memory Usage**: ~1-2GB total on Pi

## Quick Start

### Option 1: Automated Deployment (Recommended)

Use the provided deployment script:

```bash
# Clone repository (if not already done)
git clone <your-repo-url> synapse
cd synapse

# Make scripts executable
chmod +x scripts/deploy.sh scripts/manage.sh

# Deploy to Pi
./scripts/deploy.sh pi@raspberrypi.local

# Or with IP address
./scripts/deploy.sh pi@192.168.1.100
```

The script will:
1. Check prerequisites
2. Create directory structure on Pi
3. Download embedding model
4. Build Docker image on Pi
5. Start the container
6. Run health checks

### Option 2: Manual Deployment

```bash
# Set Docker context to Pi
docker context use pi

# Create necessary directories
ssh pi@raspberrypi.local "mkdir -p /home/pi/synapse/{configs,data,models}"

# Copy configs
scp -r configs pi@raspberrypi.local:/home/pi/synapse/

# Download embedding model
ssh pi@raspberrypi.local << 'EOF'
cd /home/pi/synapse/models
wget https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q4_K_M.gguf
EOF

# Copy Docker files
scp docker-compose.pi.yml Dockerfile.pi pi@raspberrypi.local:/home/pi/synapse/

# Build and deploy
docker compose -f docker-compose.pi.yml --context pi up -d
```

## Configuration

### Required Configuration Files

**`configs/rag_config.json`** - Main RAG configuration:

```json
{
  "rag_enabled": true,
  "chunk_size": 500,
  "chunk_overlap": 50,
  "top_k": 3,
  
  "index_path": "/app/data/rag_index",
  "docs_path": "/app/data/docs",
  
  "embedding_model_path": "/app/models/nomic-embed-text-v1.5.Q4_K_M.gguf",
  "embedding_n_ctx": 2048,
  "embedding_n_gpu_layers": 0,
  "embedding_cache_enabled": true,
  "embedding_cache_size": 500,
  
  "use_external_chat_model": true,
  "external_chat_api_url": "https://your-gpu-server:8443/v1/chat/completions",
  "external_chat_api_key": "your-key-here",
  
  "rag_api_port": 8001,
  "rag_api_host": "0.0.0.0"
}
```

**`configs/models_config.json`** - Model registry:

```json
{
  "max_loaded_models": 1,
  "models": {
    "embedding": {
      "path": "/app/models/nomic-embed-text-v1.5.Q4_K_M.gguf",
      "type": "embedding",
      "n_ctx": 2048,
      "n_gpu_layers": 0
    },
    "external_chat": {
      "is_external": true,
      "api_url": "https://your-gpu-server:8443/v1/chat/completions",
      "api_key": "your-key",
      "type": "chat"
    }
  }
}
```

### Environment Variables

Create `.env.pi` in project directory:

```bash
# External LLM API
EXTERNAL_CHAT_API_URL=https://u425-afb3-687d7019.singapore-a.gpuhub.com:8443/v1/chat/completions
EXTERNAL_CHAT_API_KEY=your-api-key-here

# Embedding model path
EMBEDDING_MODEL_PATH=/app/models/nomic-embed-text-v1.5.Q4_K_M.gguf

# Performance tuning
EMBEDDING_N_GPU_LAYERS=0
MAX_LOADED_MODELS=1
```

## Docker Volume Management

### Volume Structure

```
synapse-models/         # GGUF model files
  └─ nomic-embed-text-v1.5.Q4_K_M.gguf

synapse-data/           # Application data
  ├─ rag_index/         # Vector store
  ├─ docs/              # Source documents
  └─ logs/              # Application logs

synapse-cache/          # Pip cache
synapse-huggingface/    # HuggingFace cache
```

### Backup Volumes

```bash
# Backup data volume
docker run --rm \
  -v synapse-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/synapse-data-backup.tar.gz /data

# Restore data volume
docker run --rm \
  -v synapse-data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/synapse-data-backup.tar.gz --strip 1"
```

### Inspect Volume Contents

```bash
# View data volume
docker run --rm -v synapse-data:/data alpine ls -la /data

# Get volume size
docker system df -v | grep synapse
```

## Deployment Management

### Using the Management Script

```bash
# Interactive menu
./scripts/manage.sh interactive

# View logs
./scripts/manage.sh logs

# Test API
./scripts/manage.sh test

# Restart service
./scripts/manage.sh restart

# Update to latest version
./scripts/manage.sh update

# Open shell in container
./scripts/manage.sh shell

# Stop service
./scripts/manage.sh stop

# Cleanup Docker resources
./scripts/manage.sh cleanup

# Show detailed info
./scripts/manage.sh info
```

### Manual Docker Commands

```bash
# Set context
docker context use pi

# View logs
docker logs -f synapse

# Restart container
docker restart synapse

# Execute command in container
docker exec synapse python -m rag.bulk_ingest /app/data/docs /path/to/docs

# Scale resources
docker update --memory 3g --cpus 3 synapse

# Cleanup
docker system prune -a --volumes
```

## Monitoring and Debugging

### Container Health

```bash
# Check container status
docker ps

# View health status
docker inspect synapse --format='{{.State.Health.Status}}'

# Detailed container info
docker inspect synapse
```

### Resource Usage

```bash
# Real-time stats
docker stats synapse

# Memory usage
docker exec synapse ps aux --sort=-%mem | head -10

# Disk usage
docker exec synapse df -h
```

### API Health Checks

```bash
# Health endpoint
curl http://<pi-ip>:8001/health

# API stats
curl http://<pi-ip>:8001/v1/stats

# List models
curl http://<pi-ip>:8001/v1/models
```

### Log Analysis

```bash
# View all logs
docker logs synapse

# Follow logs in real-time
docker logs -f synapse

# Last 100 lines
docker logs --tail 100 synapse

# Search for errors
docker logs synapse 2>&1 | grep -i error
```

### Common Issues

**Container won't start:**
```bash
# Check logs
docker logs synapse

# Check if port is in use
ssh pi@raspberrypi.local "netstat -tlnp | grep 8001"
```

**Out of memory:**
```bash
# Increase swap
docker exec synapse dmesg | grep -i memory

# Check container limits
docker inspect synapse --format='{{.HostConfig.Memory}}'
```

**Model loading fails:**
```bash
# Check model file exists
docker exec synapse ls -la /app/models/

# Check permissions
docker exec synapse ls -la /app/models/nomic-embed-text-v1.5.Q4_K_M.gguf
```

## Performance Optimization

### ARM64 Optimizations

The Dockerfile includes ARM NEON optimizations:

```dockerfile
CMAKE_ARGS="-DLLAMA_NATIVE=ON \
  -DLLAMA_ARM_NEON=ON \
  -DLLAMA_ARM_FMA=ON \
  -DLLAMA_AVX=OFF \
  -DLLAMA_AVX2=OFF"
```

Expected performance: 50-100 tokens/sec for embeddings on Pi 5.

### Resource Limits

Adjust in `docker-compose.pi.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '3.0'  # Leave 1 core for OS
      memory: 3G   # Leave 5GB for OS/other services
```

### Memory Optimization

If you experience OOM issues:

1. Reduce embedding cache size in config:
   ```json
   "embedding_cache_size": 250
   ```

2. Reduce context size:
   ```json
   "embedding_n_ctx": 1024
   ```

3. Add swap space on Pi:
   ```bash
   sudo dphys-swapfile swapoff
   sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```

### Network Optimization

For better API latency to external GPU server:

```bash
# Use ethernet instead of WiFi on Pi
# Or optimize WiFi:
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

# Add for 5GHz priority:
country=YOUR_COUNTRY
network={
    ssid="YourSSID"
    psk="YourPassword"
    priority=5
    scan_ssid=1
}
```

## Ingesting Documents

### Bulk Ingestion

```bash
# Copy documents to Pi
scp -r /path/to/documents pi@raspberrypi.local:/home/pi/synapse-data/docs/

# Ingest documents
docker exec synapse python -m rag.bulk_ingest \
  /app/data/docs \
  --tags "source:my-documents" \
  --chunk-size 500 \
  --chunk-overlap 50
```

### Single File Ingestion

```bash
# Copy file to Pi
scp document.pdf pi@raspberrypi.local:/home/pi/synapse-data/docs/

# Ingest single file
docker exec synapse python -m rag.ingest \
  /app/data/docs/document.pdf
```

### Via API

```bash
# Ingest via API
curl -X POST http://<pi-ip>:8001/v1/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Your document content...",
    "source_name": "api-document",
    "chunk_size": 500,
    "chunk_overlap": 50
  }'
```

## Testing the Deployment

### Basic Health Check

```bash
# Check if API is responding
curl http://<pi-ip>:8001/health

# Expected response:
# {"status": "ok", "service": "synapse"}
```

### Model Status

```bash
# Check loaded models
curl http://<pi-ip>:8001/v1/models

# Expected: embedding model should show as loaded
```

### RAG Query Test

```bash
# Test with RAG
curl -X POST http://<pi-ip>:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "What is synapse?"}]
  }'

# Test without RAG
curl -X POST http://<pi-ip>:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "system", "content": "disable-rag"},
      {"role": "user", "content": "What is synapse?"}
    ]
  }'
```

### Search Test

```bash
# Search documents directly
curl -X POST http://<pi-ip>:8001/v1/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "vector store",
    "top_k": 5
  }'
```

## Updating the Deployment

### Update to Latest Code

```bash
# Using management script
./scripts/manage.sh update

# Or manually
docker context use pi
docker compose -f docker-compose.pi.yml build --no-cache
docker compose -f docker-compose.pi.yml up -d --no-deps synapse
```

### Update Configuration

1. Update local configs
2. Copy to Pi:
   ```bash
   scp -r configs pi@raspberrypi.local:/home/pi/synapse/
   ```
3. Restart container:
   ```bash
   docker restart synapse
   ```

### Update Model File

```bash
# SSH to Pi
ssh pi@raspberrypi.local

# Download new model
cd /home/pi/synapse-models
wget https://huggingface.co/.../new-model.gguf

# Update config to point to new model
nano /home/pi/synapse-configs/rag_config.json

# Restart container
docker restart synapse
```

## Production Considerations

### Security

1. **Firewall** - Limit access to port 8001:
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 8001
   ```

2. **SSL/TLS** - Use nginx reverse proxy with Let's Encrypt:
   ```bash
   # Add nginx service to docker-compose.pi.yml
   docker compose -f docker-compose.pi.yml up -d nginx
   ```

3. **API key** - Set in environment, not in configs

### Monitoring

```bash
# Install cAdvisor for container monitoring
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  gcr.io/cadvisor/cadvisor:latest
```

### Backup Strategy

Automated backup script (`scripts/backup.sh`):

```bash
#!/bin/bash
# Backup synapse data daily
BACKUP_DIR="/home/pi/backups"
DATE=$(date +%Y%m%d_%H%M%S)

docker run --rm \
  -v synapse-data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/synapse-data-$DATE.tar.gz /data

# Keep only last 7 days
find $BACKUP_DIR -name "synapse-data-*.tar.gz" -mtime +7 -delete
```

Add to cron:
```bash
crontab -e
# Add: 0 2 * * * /home/pi/backup.sh
```

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker logs synapse
```

**Common causes:**
1. Port 8001 already in use: `sudo netstat -tlnp | grep 8001`
2. Model file missing: Check volume mount
3. Config error: Validate JSON syntax

### Out of Memory

**Symptoms:** Container restarts, slow performance

**Solutions:**
1. Reduce memory limit in docker-compose
2. Decrease embedding_n_ctx
3. Add swap space
4. Use smaller model quantization

### API Connection Failures

**Test external API:**
```bash
# From Pi
ssh pi@raspberrypi.local
curl -v https://your-gpu-server:8443/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "test"}]}'
```

**Check network:**
```bash
# From Pi container
docker exec synapse curl -v https://your-gpu-server:8443/health
```

### Slow Performance

**Check CPU usage:**
```bash
# On Pi
top

# In container
docker exec synapse top
```

**Optimization steps:**
1. Verify ARM NEON flags were used: `docker exec synapse pip show llama-cpp-python`
2. Check memory pressure: `free -h`
3. Use ethernet instead of WiFi
4. Move data to USB 3.0 SSD

## Uninstalling

```bash
# Stop and remove containers
docker context use pi
docker compose -f docker-compose.pi.yml down --volumes --rmi all

# Remove Docker context
docker context rm pi

# Cleanup on Pi (optional)
ssh pi@raspberrypi.local << 'EOF'
# Remove directories
rm -rf /home/pi/synapse
rm -rf /home/pi/synapse-data
rm -rf /home/pi/synapse-models

# Remove Docker volumes
docker volume rm synapse-data synapse-models synapse-cache synapse-huggingface
EOF
```

## Community and Support

- **Issues**: Report on GitHub
- **Discussions**: GitHub Discussions
- **Documentation**: Main README.md

## License

Apache 2.0
