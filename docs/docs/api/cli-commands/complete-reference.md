---
title: CLI Commands Complete Reference
description: All SYNAPSE CLI commands
---

# All SYNAPSE CLI Commands

Complete reference for all SYNAPSE command-line interface commands.

## Available Commands

| Command | Description | Documentation |
|---------|-------------|----------------|
| `synapse mcp-server` | Start MCP HTTP server | [View Details](./mcp-server.md) |
| `synapse query` | Query knowledge base | [View Details](./query.md) |
| `synapse bulk-ingest` | Ingest multiple files | (Coming Soon) |
| `synapse list-projects` | List all projects | (Coming Soon) |
| `synapse system-status` | Check system status | (Coming Soon) |
| `synapse onboard` | Onboard new project | (Coming Soon) |

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
Starts MCP HTTP server for AI integration. See [mcp-server.md](./mcp-server.md) for full documentation.

### synapse query
Queries SYNAPSE knowledge base using natural language. See [query.md](./query.md) for full documentation.

### synapse bulk-ingest
Ingests multiple files into knowledge base. Supports file patterns and metadata.

### synapse list-projects
Lists all registered projects in SYNAPSE.

### synapse system-status
Checks SYNAPSE system status, server state, and memory statistics.

### synapse onboard
Onboards a new project with initial configuration.

---

## Note

Individual command documentation for bulk-ingest, list-projects, system-status, and onboard will be added in a future update. For now, refer to the MCP Protocol documentation for the underlying functionality:

- [MCP Protocol - list_projects](../mcp-protocol/tools/list-projects.md)
- [MCP Protocol - ingest_file](../mcp-protocol/tools/ingest-file.md)

---

## See Also

- [Getting Started](../../getting-started/) - Get started with SYNAPSE
- [MCP Protocol](../mcp-protocol/) - MCP tools documentation
- [API Reference](../) - Back to API reference
