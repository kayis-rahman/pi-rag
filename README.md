# SYNAPSE

> Your Data Meets Intelligence

A local-first RAG (Retrieval-Augmented Generation) system where your stored knowledge (neurons) fires into intelligent processing (synaptic firing) to connect with AI neural networks.

---

## Features

### 🧠 Neural Storage (Three Memory Types)

**1. Dendrites (Semantic Memory)** - Vector-based document storage
- Grounded retrieval, zero hallucinations
- BGE-M3 embeddings, local model
- Project-based organization

**2. Synapses (Episodic Memory)** - Lessons learned from experience
- Success/failure analysis
- Pattern recognition (85% confidence)
- Advisory intelligence for your system

**3. Cell Bodies (Symbolic Memory)** - Authoritative facts
- Configuration (100% accuracy)
- Technical specifications
- System-wide settings
- API endpoints, version numbers

### ⚡ Synaptic Transmission (MCP Protocol)
- **7 MCP Tools**: `sy.proj.list`, `sy.src.list`, `sy.ctx.get`, `sy.mem.search`, `sy.mem.ingest`, `sy.mem.fact.add`, `sy.mem.ep.add`
- **HTTP Upload**: Remote file ingestion with auto-cleanup

### 🔄 Neural Plasticity (Smart Ingestion & Sync)
- **Bulk Ingestion**: .gitignore-aware file ingestion with incremental updates
- **Auto-Sync**: Git hooks for continuous updates
- **Retry Mechanism**: Failed files auto-retried

---

## Quick Start

### Installation

```bash
# Install SYNAPSE
pip install synapse

# With MCP Server
pip install synapse[mcp]

# Development
pip install synapse[dev]
```

### Configuration

Create `.env` file:
```bash
# Server configuration
HOST=0.0.0.0
PORT=8002

# RAG configuration
PROJECT_ROOT=/opt/synapse/data
CHUNK_SIZE=500
CHUNK_OVERLAP=50
```

### Usage

```bash
# Start SYNAPSE MCP Server
synapse-mcp-server

# Check system status
synapse-system-status

# Bulk ingest project files
synapse-bulk-ingest --dry-run

# Query your knowledge base
synapse query "How does RAG system work?"

# List available projects
synapse list-projects
```

### Automatic Learning Configuration

Synapse includes an automatic learning system that tracks operations and learns from task completions, code changes, and patterns. Enable it in `configs/rag_config.json`:

```json
{
  "automatic_learning": {
    "enabled": true,
    "mode": "aggressive",
    "track_tasks": true,
    "track_code_changes": true,
    "track_operations": true,
    "min_episode_confidence": 0.6,
    "episode_deduplication": true
  }
}
```

**What gets learned automatically:**
- **Task Completions**: Multi-step workflows (search → context → code), file ingestion batches
- **Code Changes**: Dependencies, frameworks (FastAPI, Express, React), API endpoints
- **Patterns**: Repeated failures (2+ same tool errors), repeated successes (aggressive mode)
- **Episodes**: Stored to episodic memory with 0.6-0.85 confidence threshold
- **Facts**: Stored to symbolic memory with deduplication

**Modes:**
- `aggressive`: Detects repeated successes + all other patterns
- `moderate`: Task completion + repeated failures only
- `minimal`: Only explicit manual additions

**Manual Override:**
Add `auto_learn: false` to any tool call to disable auto-learning for that specific operation.

---

## MCP Tools

### Tool 1: `sy.proj.list`
List all registered projects.

### Tool 2: `sy.src.list`
List all document sources in a project.

### Tool 3: `sy.ctx.get`
Get comprehensive context from all memory types (dendrites, synapses, cell bodies).

### Tool 4: `sy.mem.search`
Search dendrites (semantic memory) for relevant documents.

### Tool 5: `sy.mem.ingest`
Ingest a file into dendrites (semantic memory).

### Tool 6: `sy.mem.fact.add`
Add symbolic fact to cell bodies (100% accuracy).

### Tool 7: `sy.mem.ep.add`
Add episodic lesson to synapses (85% confidence).

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Your Knowledge (Neurons)                │
└────────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────────┴─────────────────────────────────┐
│         Dendrites (Semantic Memory)                  │
└────────────────────────┬───────────────────────────────┘
                     │
┌────────────────────────┴─────────────────────────────────┐
│         Synapses (Episodic Memory)                   │
└────────────────────────┬───────────────────────────────┘
                     │
┌────────────────────────┴─────────────────────────────────┐
│         Cell Bodies (Symbolic Memory)                │
└────────────────────────┬───────────────────────────────┘
                     │
             SYNAPSE Server (MCP)                │
└────────────────────────┬───────────────────────────────┘
                     │
          LLMs (AI Agents)              │
└────────────────────────┬───────────────────────────────┘
```

---

## Documentation

- 📚 [Full Documentation](https://kayis-rahman.github.io/synapse/docs)
- 🚀 [Installation Guide](https://kayis-rahman.github.io/synapse/docs/getting-started/installation)
- 🧠 [Memory System](https://kayis-rahman.github.io/synapse/docs/architecture/memory-system)
- 🔧 [MCP Tools Reference](https://kayis-rahman.github.io/synapse/docs/usage/mcp-tools)

---

## License

MIT License - see LICENSE file for details

---

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Roadmap

### v1.2.0 (Current) - ✅
- ✅ Core rebranding to SYNAPSE
- ✅ Packaging files (setup.py, pyproject.toml)
- ✅ Documentation update with SYNAPSE branding
- ✅ MCP tool descriptions with neurobiological metaphor

### v1.3.0 (Next)
- ⏳ Update branding in bulk_ingest.py and start_http_server.sh
- ⏳ Create synapse-bulk-ingest and synapse-system-status CLI tools
- ⏳ Fumadocs documentation system

### v1.4.0 (Future)
- ⏳ Register in MCP registry
- ⏳ Create installation guide
- ⏳ Add docker-compose.yml
- ⏳ Create performance benchmarks

---

## Docker Deployment (Multi-Environment)

SYNAPSE supports multi-environment Docker deployment with separate development and production configurations.

### Quick Start

```bash
# Start both environments
docker compose up -d

# Development only (port 8003)
docker compose up -d synapse-dev

# Production only (port 8002)
docker compose up -d synapse-prod
```

### Environment Switching

Use the interactive script to switch environments:

```bash
./scripts/switch_env.sh              # Interactive mode
./scripts/switch_env.sh dev          # Switch to development
./scripts/switch_env.sh prod         # Switch to production
./scripts/switch_env.sh both        # Run both environments
./scripts/switch_env.sh status       # Show current status
```

### Environment Details

| Environment | Port | Image | Use Case |
|-------------|------|-------|----------|
| Development | 8003 | `synapse:latest` | Testing new features, debugging |
| Production | 8002 | `synapse:v1.0.0` | Stable, daily use |

### Configuration

| Setting | Development | Production |
|---------|-------------|------------|
| Logging | DEBUG | INFO |
| Auto-learn Mode | aggressive | moderate |
| Restart Policy | manual | always |

### Shared Memory

Both environments share the same data volume at `/opt/synapse/data`:
- Semantic index
- Episodic database
- Symbolic memory

This enables seamless switching between environments without data loss.

### Release Management

```bash
# Create a new release
./scripts/release.sh patch  # bump patch version (1.0.0 -> 1.0.1)
./scripts/release.sh minor  # bump minor version (1.0.0 -> 1.1.0)
./scripts/release.sh major  # bump major version (1.0.0 -> 2.0.0)

# Build and push images
./scripts/build_and_push.sh
```

### Migration from Old Setup

If you were using the old `docker-compose.mcp.yml`:

```bash
# Backup existing data
cp -r /opt/synapse/data /opt/synapse/data.backup

# Stop old containers
docker-compose -f docker-compose.mcp.yml down

# Start new services
docker compose up -d
```

See [release-notes.md](release-notes.md) for complete migration guide.
