# Technical Plan: Mac Local RAG Setup

**Feature ID**: 008-mac-local-rag-setup
**Created**: January 29, 2026
**Status**: [Planning]
**Model**: BGE-M3 Q8_0 (~730MB)

---

## Overview

This plan details the technical implementation for setting up a local RAG system on macOS, replicating the working Pi configuration. The setup uses the existing `synapse setup` command which already supports macOS through automatic path detection.

---

## Phase 1: Environment Check (5 minutes)

### Tasks

#### 1.1: Verify Python Installation
```bash
# Check Python version
python3 --version

# Expected output: Python 3.13.x
# Verify pip is available
pip --version
```

**Success Criteria**:
- Python 3.8+ installed
- pip available
- Virtual environment support enabled

#### 1.2: Check Disk Space
```bash
# Check available disk space
df -h /

# Verify >2GB available for model and data
```

**Success Criteria**:
- At least 2GB free space
- Write access to home directory

#### 1.3: Verify Port Availability
```bash
# Check if port 8002 is in use
lsof -i :8002

# If in use, identify process
netstat -an | grep 8002
```

**Success Criteria**:
- Port 8002 is free OR
- Confirmed process using port and decision made to kill or use different port

#### 1.4: Test CLI Entry Point
```bash
# Navigate to project
cd /Users/kayisrahman/Documents/workspace/ideas/synapse

# Test CLI without installation
python3 -m synapse.cli.main --help

# Expected: Shows 8 commands (start, stop, status, ingest, query, config, setup, onboard, models)
```

**Success Criteria**:
- No import errors
- All 8 commands displayed
- No missing dependencies reported

---

## Phase 2: Install Dependencies (15 minutes)

### Tasks

#### 2.1: Install System Dependencies (if needed)
```bash
# Check if cmake is installed
which cmake
cmake --version

# If not installed, install via Homebrew
brew install cmake

# Check protobuf
which protoc
protoc --version

# If not installed
brew install protobuf
```

**Success Criteria**:
- cmake >= 3.18 installed
- protobuf >= 3.20 installed

#### 2.2: Create Virtual Environment
```bash
# Navigate to project
cd /Users/kayisrahman/Documents/workspace/ideas/synapse

# Create virtual environment
python3 -m venv venv

# Verify creation
ls -la venv/
```

**Success Criteria**:
- `venv/` directory created
- Python executable at `venv/bin/python`
- pip available at `venv/bin/pip`

#### 2.3: Activate Virtual Environment
```bash
# Activate
source venv/bin/activate

# Verify activation
which python
# Should point to venv/bin/python

python --version
# Should show Python 3.13.x
```

**Success Criteria**:
- Virtual environment active
- Python and pip from venv

#### 2.4: Install Synapse
```bash
# Install in development mode
pip install -e .

# Expected output:
# Successfully installed synapse-1.2.0 ...
# Successfully installed dependencies...
```

**Success Criteria**:
- All dependencies installed
- No installation errors
- synapse command available

#### 2.5: Verify Installation
```bash
# Test synapse command
synapse --help

# Expected output:
# Usage: synapse [OPTIONS] COMMAND [ARGS]...
# 
# Options:
#   --install-completion  Install completion for the current shell.
#   --show-completion     Show completion for the current shell, to copy it or to pipe it in a file.
#   --help                Show this message and exit.
# 
# Commands:
#   config     Show configuration
#   ingest     Ingest documents into knowledge base
#   models     Manage models
#   onboard    Interactive onboarding
#   query      Query the knowledge base
#   setup      First-time setup
#   start      Start the SYNAPSE server
#   status     Show server status
#   stop       Stop the SYNAPSE server

# All 8 commands displayed
```

**Success Criteria**:
- All 8 commands visible
- No missing dependencies
- No import errors

---

## Phase 3: Run Setup (10 minutes)

### Tasks

#### 3.1: Execute Setup Command
```bash
# Run setup (will prompt for model download)
synapse setup

# Expected output:
# 🚀 SYNAPSE Setup
# =================
# 
# ℹ️  Auto-detected user home data directory: /Users/kayisrahman/.synapse/data
# 📁 Data directory: /Users/kayisrahman/.synapse/data
# 📁 Models directory: /Users/kayisrahman/.synapse/data/models
# 
# 📂 Creating directories...
# ✓ Created: /Users/kayisrahman/.synapse/data
# ✓ Created: /Users/kayisrahman/.synapse/data/models
# ✓ Created: /Users/kayisrahman/.synapse/data/rag_index
# ✓ Created: /Users/kayisrahman/.synapse/data/docs
# ✓ Created: /Users/kayisrahman/.synapse/data/logs
# 
# 🧠 Checking models...
# ✗ embedding: bge-m3-q8_0.gguf - Not installed
# 
# ⚠️  embedding: bge-m3-q8_0.gguf - Not installed
# 
#   Download bge-m3-q8_0.gguf (730 MB) now? [Y/n]:
```

**Success Criteria**:
- Directories created at `~/.synapse/data/`
- Model check executed
- Prompt for model download displayed

#### 3.2: Download BGE-M3 Model
```bash
# When prompted, type 'Y' to download
# Or run non-interactively:
echo "Y" | synapse setup --no-model-check

# Or download manually:
synapse models download embedding
```

**Expected download output**:
```
📥 Downloading bge-m3-q8_0.gguf (730 MB)...
  From: BAAI/bge-m3/gguf/bge-m3-q8_0.gguf
  To: /Users/kayisrahman/.synapse/data/models/bge-m3-q8_0.gguf

[################....] 100%
✓ Model downloaded successfully
```

**Success Criteria**:
- Model downloaded from HuggingFace
- File saved to `~/.synapse/data/models/bge-m3-q8_0.gguf`
- File size ~730MB

#### 3.3: Verify Model File
```bash
# Check model file
ls -lh ~/.synapse/data/models/

# Expected:
# -rw-r--r--  1 kayisrahman  staff  730M Jan 29 10:00 bge-m3-q8_0.gguf

# Verify with models verify
synapse models verify

# Expected output:
# 🔍 Verifying Models:
# ==================================================
# 
# ✓ embedding: bge-m3-q8_0.gguf (730 MB)
# 
# ==================================================
# ✅ All models verified
```

**Success Criteria**:
- Model file exists
- File size within ±10% of 730MB
- Verification passes

#### 3.4: Complete Setup Summary
```bash
# Run setup again to verify
synapse setup

# Expected output:
# 🚀 SYNAPSE Setup
# =================
# 
# ℹ️  Auto-detected user home data directory: /Users/kayisrahman/.synapse/data
# 📁 Data directory: /Users/kayisrahman/.synapse/data
# 📁 Models directory: /Users/kayisrahman/.synapse/data/models
# 
# 📂 Creating directories...
# ✓ All directories already exist
# 
# 🧠 Checking models...
# ✓ embedding: bge-m3-q8_0.gguf (730 MB)
# 
# ⚙️  Configuration:
# ✓ Auto-detection enabled
# ✓ Sensible defaults loaded
# 
# =================
# ✓ SYNAPSE setup complete!
# 
#   Next steps:
#     1. Start server: synapse start
#     2. Ingest documents: synapse ingest <path>
#     3. Query knowledge: synapse query 'your question'
```

**Success Criteria**:
- Setup reports complete
- Model detected as installed
- Next steps displayed

---

## Phase 4: Start & Test (10 minutes)

### Tasks

#### 4.1: Start Server
```bash
# Start the server
synapse start

# Expected output:
# 🚀 Starting SYNAPSE server...
#   Port: 8002
#   Environment: native
# 🚀 Starting SYNAPSE server in native mode on port 8002...
# ✓ SYNAPSE server started successfully
#   Port: 8002
#   Health check: http://localhost:8002/health
#   PID: [process_id]
```

**Success Criteria**:
- Server starts
- Port 8002 opened
- PID recorded
- No errors displayed

#### 4.2: Health Check
```bash
# Wait a moment for server to initialize
sleep 3

# Check health endpoint
curl http://localhost:8002/health

# Expected JSON response:
# {
#   "status": "ok",
#   "timestamp": "2026-01-29T10:00:00.000000+00:00",
#   "version": "2.0.0",
#   "protocol": "MCP Streamable HTTP",
#   "tools_available": 8,
#   "transport": "http",
#   "data_directory": "/Users/kayisrahman/.synapse/data",
#   "server": "RAG Memory Backend",
#   "health_checks": {
#     "backend": "OK",
#     "episodic_store": "OK",
#     "semantic_store": "OK",
#     "symbolic_store": "OK"
#   }
# }
```

**Success Criteria**:
- HTTP 200 response
- JSON with "status":"ok"
- All health checks pass
- Tools available: 8

#### 4.3: Test Status Command
```bash
# Check server status
synapse status

# Expected output:
# 🔍 SYNAPSE Status
# =================
# 
# Server:     ✅ Running
# Port:       8002
# PID:        [process_id]
# Uptime:     0:00:15
# 
# Models:
#   ✓ embedding: bge-m3-q8_0.gguf (730 MB)
# 
# Storage:
#   ✅ Data directory: /Users/kayisrahman/.synapse/data
#   ✅ RAG index ready
#   ✅ Docs directory exists
# 
# Configuration:
#   Chunk size:     500
#   Chunk overlap:  50
#   Top K:          3
```

**Success Criteria**:
- Server detected as running
- Model status correct
- Storage status correct

#### 4.4: Test Query Command
```bash
# Test simple query
synapse query "test query"

# Expected output:
# 🔍 Query: "test query"
#   Format: text
#   Mode: semantic
#   Top K: 3
# 
# ℹ️  Note: Full implementation coming in Phase 1
# ✅ Query command accepted (placeholder)
```

**Success Criteria**:
- Query command executes
- Parameters parsed correctly
- Placeholder or actual results returned

#### 4.5: Stop Server
```bash
# Stop the server
synapse stop

# Expected output:
# 🛑 Stopping SYNAPSE server...
#   PID: [process_id]
# ✓ Server stopped successfully
# 
# Cleanup:
#   ✓ Process terminated
#   ✓ No zombie processes
```

**Success Criteria**:
- Server stops gracefully
- PID matches start PID
- Cleanup successful

#### 4.6: Final Verification
```bash
# Verify server stopped
synapse status

# Expected:
# 🔍 SYNAPSE Status
# =================
# 
# Server:     ❌ Stopped
# 
# ℹ️  Server is not running
# ℹ️  Start with: synapse start

# Verify port is free
lsof -i :8002
# Should show no processes
```

**Success Criteria**:
- Status shows stopped
- Port 8002 is free
- No zombie processes

---

## Rollback Plan

If any step fails:

### Step 2: Dependency Installation Fails
```bash
# Deactivate and remove virtual environment
deactivate
rm -rf venv

# Clean pip cache
pip cache purge

# Retry with verbose logging
pip install -e . -v
```

### Step 3: Setup Fails
```bash
# Manual cleanup
rm -rf ~/.synapse/

# Retry setup
synapse setup --force
```

### Step 4: Server Fails to Start
```bash
# Check logs
cat ~/.synapse/data/logs/*.log

# Check port
lsof -i :8002

# Kill conflicting process if needed
kill [PID]

# Or use different port
export SYNAPSE_API_PORT=8080
synapse start
```

---

## Verification Checklist

Before marking complete:

- [ ] Python 3.13.2 installed and working
- [ ] Virtual environment created at `/Users/kayisrahman/Documents/workspace/ideas/synapse/venv/`
- [ ] Synapse installed: `pip list | grep synapse`
- [ ] CLI works: `synapse --help` (8 commands)
- [ ] Setup ran: `synapse setup` completed
- [ ] Model downloaded: `~/.synapse/data/models/bge-m3-q8_0.gguf` (~730MB)
- [ ] Model verified: `synapse models verify` passes
- [ ] Server starts: `synapse start` succeeds
- [ ] Health check: `curl http://localhost:8002/health` returns OK
- [ ] Server stops: `synapse stop` succeeds
- [ ] All commands documented in this plan executed successfully

---

## Files Created/Modified

### Created
- `~/.synapse/` directory structure
- `~/.synapse/data/models/bge-m3-q8_0.gguf` (~730MB)
- `~/.synapse/data/rag_index/` (empty, for vector store)
- `~/.synapse/data/docs/` (empty, for document storage)
- `~/.synapse/data/logs/` (empty, for logs)
- `~/.synapse/configs/rag_config.json` (generated)

### Modified (Project)
- No project files modified
- Virtual environment in `/Users/kayisrahman/Documents/workspace/ideas/synapse/venv/`

---

## Timeline Summary

| Phase | Duration | Tasks |
|-------|----------|-------|
| Phase 1: Environment Check | 5 min | 4 |
| Phase 2: Install Dependencies | 15 min | 5 |
| Phase 3: Run Setup | 10 min | 4 |
| Phase 4: Start & Test | 10 min | 6 |
| **Total** | **~40 min** | **19 tasks** |

---

*Document created for SDD Protocol - Planning Phase*
