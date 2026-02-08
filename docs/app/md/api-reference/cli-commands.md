---
title: CLI Commands Complete Reference
description: All SYNAPSE CLI commands
---

# All SYNAPSE CLI Commands

Complete reference for all SYNAPSE command-line interface commands.

## Available Commands

| Command | Description | Documentation |
|---------|-------------|----------------|
| `synapse mcp-server` | Start MCP HTTP server | See [MCP Tools](/usage/mcp-tools.md) |
| `synapse query` | Query knowledge base | See [Querying](/usage/querying.md) |
| `synapse bulk-ingest` | Ingest multiple files | See [Bulk Ingest](/usage/ingestion.md) |
| `sy proj list` | List all projects | See [MCP: sy.proj.list](/usage/mcp-tools.md) |
| `synapse system-status` | Check system status | See [System Status](/usage/querying.md) |

## Quick Reference

```bash
# Initialize SYNAPSE
synapse init

# Query knowledge base
synapse query "How does system work?"

# Start MCP server
synapse mcp-server --port 8002

# Ingest files
synapse bulk-ingest /path/to/docs --project my-knowledge
```

## Command Summary

### synapse mcp-server
Starts MCP HTTP server for AI integration. See [MCP Tools](/usage/mcp-tools.md) for full documentation.

### synapse query
Queries SYNAPSE knowledge base using natural language. See [Querying](/usage/querying.md) for full documentation.

### synapse bulk-ingest
Ingests multiple files into knowledge base. Supports file patterns and metadata. See [Ingestion](/usage/ingestion.md) for full documentation.

### sy proj list
Lists all registered projects in SYNAPSE. See [MCP Protocol - list_projects](/usage/mcp-tools.md) for details.

### synapse system-status
Checks SYNAPSE system status, server state, and memory statistics. See [Querying](/usage/querying.md) for details.

### synapse onboard
Onboards a new project with initial configuration.

## Examples

### Query with Filters

```bash
# Query only semantic memory
synapse query "architecture" --memory-type semantic

# Query specific project
synapse query "What are MCP tools?" --project my-knowledge --top-k 5

# Query with JSON output
synapse query "API configuration" --format json
```

### Bulk Ingest with Options

```bash
# Ingest only code files
synapse bulk-ingest --file-type code

# Ingest documentation only
synapse bulk-ingest --file-type doc

# Custom exclusions
synapse bulk-ingest --exclude "*.log" --exclude "*.tmp"
```

---

## See Also

- [Getting Started](/getting-started/introduction) - Get started with SYNAPSE
- [MCP Protocol](/usage/mcp-tools.md) - MCP tools documentation
- [API Reference - Server API](/api-reference/server-api.md) - HTTP API endpoints
- [API Reference - Memory Tools](/api-reference/memory-tools.md) - Python memory APIs
- [Development](/development/contributing.md) - Contributing, testing, and deployment
