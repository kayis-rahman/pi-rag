---
title: CLI Commands Complete Reference
description: All SYNAPSE CLI commands with sy naming convention
---

# All SYNAPSE CLI Commands

Complete reference for all SYNAPSE command-line interface commands using the `sy` naming convention.

## Naming Convention

All CLI commands use the `sy` entry point:

```bash
# Syntax
sy <command> [options]

# Examples
sy start
sy status
sy query "your question"
```

## Available Commands

| Command | Description | Status |
|---------|-------------|--------|
| `sy start` | Start SYNAPSE MCP server | ✅ Working |
| `sy stop` | Stop SYNAPSE server | ✅ Working |
| `sy status` | Check system status | ✅ Working |
| `sy config` | Show configuration | ✅ Working |
| `sy ingest` | Ingest documents | ✅ Working |
| `sy query` | Query knowledge base | ✅ Working |
| `sy setup` | First-time setup | ✅ Working |
| `sy onboard` | Onboarding wizard | ✅ Working |
| `sy models` | Model management | ✅ Working |

## Quick Reference

```bash
# Initialize SYNAPSE
sy setup

# Start MCP server
sy start

# Check status
sy status

# Ingest files
sy ingest /path/to/docs

# Query knowledge base
sy query "How does system work?"

# Stop server
sy stop
```

## Command Details

### sy start

Starts the SYNAPSE MCP server.

```bash
sy start                    # Start on default port 8002
sy start --port 8080       # Custom port
sy start --docker          # Docker mode
sy start -d -p 9000       # Docker with custom port
```

**Options:**
- `--port, -p`: Port number (default: 8002)
- `--docker, -d`: Run in Docker mode

**Output:**
```
🚀 Starting SYNAPSE server...
  Port: 8002
  Environment: native
✓ SYNAPSE server started successfully
```

---

### sy stop

Stops the SYNAPSE server.

```bash
sy stop                    # Stop native server
sy stop --docker          # Stop Docker container
```

**Note:** Uses fallback mechanism if pkill is unavailable.

---

### sy status

Checks SYNAPSE system status.

```bash
sy status                  # Brief status
sy status --verbose       # Full details
```

**Output:**
```
🔍 SYNAPSE System Status Check
==================================================
Environment: native
Data Directory: /opt/synapse/data
📡 MCP Server Status: ✅ running
🧠 Model Status: Check with sy models list
📁 Configuration Status: ✓ Auto-detection enabled
```

---

### sy config

Shows SYNAPSE configuration.

```bash
sy config                 # Basic config
sy config --verbose       # Full config
```

**Output:**
```
🔧 SYNAPSE Configuration Summary
RAG Settings:
  Chunk Size: 500
  Chunk Overlap: 50
  Top K: 3
Models:
  Embedding: bge-m3-q8_0.gguf
  Chat: gemma-3-1b-it-UD-Q4_K_XL.gguf
Server:
  Host: 0.0.0.0
  Port: 8002
```

---

### sy ingest

Ingests documents into SYNAPSE knowledge base.

```bash
sy ingest file.txt                    # Single file
sy ingest /path/to/directory/        # Directory
sy ingest file.txt --chunk-size 1000  # Custom chunk size
sy ingest code/ -c                   # Code mode
sy ingest file.txt -p my-project     # Custom project
```

**Options:**
- `--chunk-size`: Chunk size (default: 500)
- `--code, -c`: Code mode
- `--project, -p`: Project ID

**Output:**
```
📄 Ingesting: /path/to/file.txt
  Project ID: synapse
  Chunk size: 500
✅ Ingestion complete!
```

---

### sy query

Queries SYNAPSE knowledge base.

```bash
sy query "your question"          # Simple query
sy query "test" -k 5             # Top-k results
sy query "test" -f json          # JSON format
sy query "test" -f text          # Text format
sy query "test" -m code          # Code mode
```

**Options:**
- `--top-k, -k`: Number of results (default: 3)
- `--format, -f`: Output format (json/text)
- `--mode, -m`: Query mode (default/code)

---

### sy setup

First-time SYNAPSE setup.

```bash
sy setup                    # Fresh setup
sy setup --force           # Force re-setup
sy setup --offline         # No downloads
sy setup --no-model-check  # Skip model check
```

**Options:**
- `--force, -f`: Force re-setup
- `--offline`: Offline mode
- `--no-model-check`: Skip model verification

---

### sy onboard

SYNAPSE Onboarding Wizard.

```bash
sy onboard                  # Interactive mode
sy onboard --quick         # Quick mode (defaults)
sy onboard --silent        # Silent mode (no prompts)
sy onboard --skip-test     # Skip test
sy onboard --skip-ingest    # Skip ingestion
sy onboard --offline       # Offline mode
sy onboard -p test-project # Custom project (silent)
```

---

### sy models

Model management commands.

```bash
sy models list             # List all models
sy models download bge-m3   # Download model
sy models verify           # Verify installed models
sy models remove bge-m3     # Remove model
```

**Subcommands:**
- `list`: List available models
- `download`: Download a model
- `verify`: Verify model integrity
- `remove`: Remove a model

---

## MCP Tools Reference

All MCP tools use the `sy.*` naming convention:

| Tool | Description |
|------|-------------|
| `sy.proj.list` | List all projects |
| `sy.src.list` | List document sources |
| `sy.ctx.get` | Get comprehensive context |
| `sy.mem.search` | Search semantic memory |
| `sy.mem.ingest` | Ingest documents |
| `sy.mem.fact.add` | Add symbolic fact |
| `sy.mem.ep.add` | Add episodic lesson |

---

## Examples

### Complete Workflow

```bash
# 1. Setup
sy setup

# 2. Start server
sy start

# 3. Ingest documentation
sy ingest /path/to/docs

# 4. Query
sy query "How does it work?"

# 5. Check status
sy status

# 6. Stop
sy stop
```

### Query with Filters

```bash
# Query only semantic memory
sy query "architecture" -k 5

# Query specific project
sy query "What are MCP tools?" -p my-project

# Query with JSON output
sy query "API configuration" -f json
```

---

## See Also

- [Getting Started](/getting-started/introduction) - Get started with SYNAPSE
- [MCP Protocol](/usage/mcp-tools.md) - MCP tools documentation
- [Querying](/usage/querying.md) - Query documentation
- [Ingestion](/usage/ingestion.md) - Ingestion documentation
- [API Reference - Server API](/api-reference/server-api.md) - HTTP API endpoints

---

*Last Updated: February 8, 2026*
*Feature: 007-cli-manual-testing-and-docs*
