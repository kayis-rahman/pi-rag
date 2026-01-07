---
title: CLI Commands
description: Command-line interface for SYNAPSE
---

# CLI Commands

Complete reference for SYNAPSE command-line interface.

## Available Commands

| Command | Description |
|---------|-------------|
| [mcp-server](./mcp-server.md) | Start MCP HTTP server |
| [query](./query.md) | Query knowledge base |
| [bulk-ingest](./bulk-ingest.md) | Ingest multiple files |
| [list-projects](./list-projects.md) | List all projects |
| [system-status](./system-status.md) | Check system status |
| [onboard](./onboard.md) | Onboard new project |

## Quick Start

```bash
# Initialize SYNAPSE
synapse init

# Query knowledge base
synapse query "How does system work?"

# Start MCP server
synapse mcp-server --port 8002
```

## See Also

- [Getting Started](../../getting-started/) - Get started with SYNAPSE
- [MCP Protocol](../mcp-protocol/) - MCP tools documentation
- [API Reference](../) - Back to API reference
