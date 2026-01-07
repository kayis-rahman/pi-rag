---
title: synapse mcp-server
description: Start MCP HTTP server
---

# synapse mcp-server

Start SYNAPSE MCP HTTP server for AI integration.

## Syntax

```bash
synapse mcp-server [options]
```

## Options

| Flag | Short | Default | Description |
|-------|--------|-----------|-------------|
| `--host` | `-h` | `127.0.0.1` | Host to bind server |
| `--port` | `-p` | `8002` | Port to run server on |
| `--data-dir` | `-d` | `/opt/synapse/data` | Custom data directory |

## Examples

**Start on default port:**

```bash
synapse mcp-server
# Server runs on http://127.0.0.1:8002/mcp
```

**Start on custom host and port:**

```bash
synapse mcp-server --host 0.0.0.0 --port 8003
# Server runs on http://0.0.0.0:8003/mcp
```

**Start with custom data directory:**

```bash
synapse mcp-server --data-dir /custom/path/to/data
```

**Development mode:**

```bash
synapse mcp-server --host 0.0.0.0 --port 8002 --data-dir ./data
```

## Server Details

Once started, the MCP server:

- Accepts JSON-RPC 2.0 requests
- Provides 7 MCP tools
- Runs on configured host:port
- Serves at `/mcp` endpoint

## MCP Tools Provided

The server provides these 7 tools:

1. `list_projects` - List all projects
2. `list_sources` - List project sources
3. `get_context` - Get comprehensive context
4. `search` - Search memory type
5. `ingest_file` - Add content to memory
6. `add_fact` - Add authoritative fact
7. `add_episode` - Add lesson learned

## See Also

- [MCP Protocol](../mcp-protocol/) - MCP tools documentation
- [system-status](./system-status.md) - Check system status
