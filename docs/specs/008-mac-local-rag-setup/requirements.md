# Feature Specification: Mac Local RAG Setup with BGE-M3 Q8_0

**Feature ID**: 008-mac-local-rag-setup
**Created**: January 29, 2026
**Status**: [Planning - Awaiting Approval]
**Model**: BGE-M3 Q8_0 (~730MB)

---

## Executive Summary

Set up a complete RAG (Retrieval-Augmented Generation) system locally on macOS, replicating the existing Pi setup. The system will use the BGE-M3 embedding model for local semantic search without cloud dependencies.

**Target Configuration**:
- **Data directory**: `~/.synapse/data`
- **Models directory**: `~/.synapse/models/`
- **Embedding model**: `bge-m3-q8_0.gguf` (~730MB)
- **Server port**: 8002 (MCP Streamable HTTP)
- **Python environment**: Virtual environment with pip install

---

## User Stories

### US1: Setup macOS Environment
**As a** macOS user  
**I want to** run `synapse setup` and have everything configured automatically  
**So that** I can start using the RAG system without manual configuration

**Acceptance Criteria**:
- [ ] `synapse setup` detects macOS environment
- [ ] Config files generated at `~/.synapse/`
- [ ] Data directory created: `~/.synapse/data/`
- [ ] Models directory created: `~/.synapse/models/`
- [ ] All CLI commands work without errors

### US2: Download BGE-M3 Q8_0 Model
**As a** user  
**I want to** download the BGE-M3 Q8_0 embedding model locally  
**So that** the RAG system can generate embeddings without cloud API calls

**Acceptance Criteria**:
- [ ] `synapse models download embedding` succeeds
- [ ] Model saved to `~/.synapse/models/bge-m3-q8_0.gguf`
- [ ] Model size ~730MB (within ±10% variance)
- [ ] `synapse models verify` confirms model integrity

### US3: Start RAG Server
**As a** developer  
**I want to** start the RAG server locally  
**So that** I can query the knowledge base

**Acceptance Criteria**:
- [ ] `synapse start` starts server on port 8002
- [ ] Health check passes: `curl http://localhost:8002/health` returns `{"status":"ok"}`
- [ ] `synapse status` shows server running
- [ ] `synapse stop` gracefully stops server
- [ ] Server persists in background

### US4: Test Full Stack
**As a** user  
**I want to** verify the complete RAG stack works  
**So that** I can trust the system for production use

**Acceptance Criteria**:
- [ ] `synapse query "test"` returns results
- [ ] MCP tools accessible via curl
- [ ] No errors in server logs
- [ ] All 8 CLI commands functional

---

## Technical Architecture

### Directory Structure

```
~/.synapse/
├── models/
│   └── bge-m3-q8_0.gguf  (~730MB)
├── data/
│   ├── rag_index/
│   ├── docs/
│   ├── logs/
│   ├── memory.db
│   └── metrics.db
└── configs/
    └── rag_config.json
```

**Project directory**: `/Users/kayisrahman/Documents/workspace/ideas/synapse`

### Component Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **LLM Backend** | llama-cpp-python | Local model inference |
| **Embedding Model** | BGE-M3 (Q8_0) | Text embeddings (~730MB) |
| **Vector Store** | ChromaDB/JSON | Semantic storage |
| **Memory System** | SQLite | Episodic/symbolic memory |
| **API Protocol** | MCP (Streamable HTTP) | Agent integration |
| **CLI Framework** | Typer | Command interface |
| **HTTP Server** | Uvicorn + FastAPI | MCP transport |

### Configuration (from Pi setup)

| Setting | Value | Location |
|---------|-------|----------|
| **Data directory** | `~/.synapse/data` | Environment + code |
| **Models directory** | `~/.synapse/models/` | Environment + code |
| **Model file** | `bge-m3-q8_0.gguf` | Models directory |
| **Server port** | 8002 | rag_config.json |
| **Chunk size** | 500 characters | rag_config.json |
| **Chunk overlap** | 50 characters | rag_config.json |
| **Top K results** | 3 | rag_config.json |

---

## Dependencies

### System Dependencies
```bash
# Already installed on Mac:
- Python 3.13.2
- Docker 29.1.3
- Homebrew 5.0.12

# May be needed:
- cmake (for llama-cpp-python build)
- protobuf (for MCP server)
```

### Python Dependencies
```bash
# Core dependencies (from requirements.txt):
llama-cpp-python>=0.3.0
fastapi>=0.115.0
uvicorn[standard]>=0.30.0
pydantic>=2.0.0
chromadb>=0.5.0
httpx>=0.27.0
python-dotenv>=1.0.0
mcp>=0.1.4
typer>=0.12.0
huggingface_hub>=0.20.0
pytest>=7.4.0
```

### Model Assets
- **BGE-M3 Embedding Model**: ~730MB (Q8_0 quantization)
  - Source: `https://huggingface.co/BAAI/bge-m3/gguf/bge-m3-q8_0.gguf`
  - Destination: `~/.synapse/models/bge-m3-q8_0.gguf`
  - Alternative: `https://huggingface.co/BAAI/bge-m3/gguf/resolve/main/bge-m3-q8_0.gguf`

---

## Reference: Pi Setup Configuration

From the existing Pi setup, these settings are confirmed working:

### Pi Configuration (Reference)
```json
{
  "embedding_model_path": "/home/dietpi/.synapse/models/bge-m3-q8_0.gguf",
  "embedding_model_name": "embedding",
  "index_path": "/home/dietpi/.synapse/data/rag_index",
  "docs_path": "/home/dietpi/.synapse/data/docs",
  "memory_db_path": "/home/dietpi/.synapse/data/memory.db"
}
```

### macOS Adaptation
Replace `/home/dietpi/` with `~/.synapse/` for macOS compatibility.

---

## Commands Reference

### Installation Commands
```bash
# Navigate to project
cd /Users/kayisrahman/Documents/workspace/ideas/synapse

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install synapse in development mode
pip install -e .

# Verify installation
synapse --help
```

### Setup Commands
```bash
# Run setup (will prompt for model download)
synapse setup

# Or skip model download
synapse setup --no-model-check

# Or run in offline mode
synapse setup --offline
```

### Model Commands
```bash
# Download embedding model
synapse models download embedding

# Verify model integrity
synapse models verify

# List all models
synapse models list
```

### Server Commands
```bash
# Start server
synapse start

# Check status
synapse status

# Stop server
synapse stop
```

### Test Commands
```bash
# Health check
curl http://localhost:8002/health

# Query test
synapse query "test"

# Full status
synapse status --verbose
```

---

## Risk Assessment

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| HuggingFace rate limits | Medium | Medium | Retry logic, manual download fallback |
| llama-cpp-python build fails on Apple Silicon | High | Low | Use pre-built wheel, verify installation |
| ChromaDB compatibility | Medium | Low | Use JSON fallback if needed |
| Port 8002 already in use | Low | Low | Check with `lsof -i :8002` |
| Insufficient disk space for model | Medium | Low | Check disk space (>2GB free) |
| Model download timeout | Medium | Medium | Use wget/curl with resume support |

---

## Success Criteria

### Functional Criteria
- [ ] `synapse --help` displays all 8 commands
- [ ] `synapse setup` creates `~/.synapse/` structure
- [ ] Model downloaded to `~/.synapse/models/bge-m3-q8_0.gguf`
- [ ] Server starts, health check returns `{"status":"ok"}`
- [ ] All CLI commands execute without errors

### Performance Criteria
- [ ] Server startup < 30 seconds
- [ ] Query response < 5 seconds
- [ ] Model load < 60 seconds
- [ ] Ingestion rate > 10 files/second

### Quality Criteria
- [ ] No hardcoded Linux paths
- [ ] Cross-platform config path resolution
- [ ] Clear error messages
- [ ] Progress indicators for long operations

---

## Out of Scope

1. **Docker deployment**: Using native Python server for easier development
2. **Multiple projects**: Single default project setup only
3. **Remote API**: All functionality local
4. **Web UI**: CLI-first approach
5. **User authentication**: Local system, no auth needed

---

## Timeline Estimate

| Phase | Tasks | Time |
|-------|-------|------|
| Phase 1: Environment Check | 4 tasks | 5 min |
| Phase 2: Install Dependencies | 5 tasks | 15 min |
| Phase 3: Run Setup | 4 tasks | 10 min |
| Phase 4: Start & Test | 4 tasks | 10 min |
| **Total** | **17 tasks** | **~40 minutes** |

---

## Next Steps

Awaiting approval to create:
1. `docs/specs/008-mac-local-rag-setup/` directory
2. `requirements.md` (this specification)
3. `plan.md` with detailed implementation steps
4. `tasks.md` with granular 17-task checklist
5. Update `docs/specs/index.md` with new feature

**Estimated completion time**: ~40 minutes

---

*Document created for SDD Protocol - Feature Scoping Phase*
