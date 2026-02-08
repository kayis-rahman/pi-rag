---
title: Server API
description: HTTP API endpoints for SYNAPSE
---

# Server API

SYNAPSE provides an HTTP API for remote access to MCP tools.

## Base URL

```
http://localhost:8002/mcp
```

## JSON-RPC Format

All requests use JSON-RPC 2.0 format:

```json
{
  "jsonrpc": "2.0",
  "method": "tool_name",
  "params": { ... },
  "id": 1
}
```

## Endpoints

### Tools List

```bash
POST /mcp
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 1
}
```

Response:
```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [...]
  },
  "id": 1
}
```

### Tool Call

```bash
POST /mcp
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "sy.mem.search",
    "arguments": {
      "query": "memory system",
      "top_k": 3
    }
  },
  "id": 1
}
```

### Context Query

```bash
POST /mcp
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "sy.ctx.get",
    "arguments": {
      "query": "architecture",
      "context_type": "all",
      "max_results": 10
    }
  },
  "id": 1
}
```

## Authentication

SYNAPSE HTTP API does not implement authentication by default.

To add authentication:

1. Configure reverse proxy (nginx, traefik)
2. Use API keys or JWT tokens
3. Implement authentication middleware

## CORS

SYNAPSE allows cross-origin requests by default. Configure CORS in your proxy or firewall if needed.

## Error Handling

All errors are returned with proper JSON-RPC error codes:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32601,
    "message": "Project not found"
  },
  "id": 1
}
```
