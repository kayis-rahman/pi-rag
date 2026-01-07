---
title: synapse query
description: Query SYNAPSE knowledge base
---

# synapse query

Query SYNAPSE knowledge base using natural language.

## Syntax

```bash
synapse query "<query>" [options]
```

## Options

| Flag | Short | Default | Description |
|-------|--------|-----------|-------------|
| `--project` | `-p` | `synapse` | Project to query |
| `--top-k` | `-k` | `3` | Number of results |
| `--memory-type` | `-m` | `all` | Memory type filter |
| `--format` | `-f` | `text` | Output format (text, json) |

## Examples

**Basic query:**

```bash
synapse query "How does memory system work?"
```

**Query specific project:**

```bash
synapse query "What are MCP tools?" --project my-knowledge --top-k 5
```

**Query only symbolic memory:**

```bash
synapse query "API configuration" --memory-type symbolic
```

**JSON output:**

```bash
synapse query "memory types" --format json
```

## Output Formats

**Text format:**

```
Based on retrieved RAG context:

The SYNAPSE memory system provides 7 MCP tools for:
- Project management (list_projects, list_sources)
- Context retrieval (get_context, search)
- Content ingestion (ingest_file)
- Memory updates (add_fact, add_episode)

Sources: Symbolic memory (3 facts), Episodic memory (2 episodes)
Confidence: High
```

**JSON format:**

```json
{
  "query": "API endpoints",
  "results": {
    "symbolic": [...],
    "episodic": [...],
    "semantic": [...]
  }
}
```

## Memory Types

| Memory Type | Description |
|-------------|-------------|
| `all` | Query all three memory types |
| `symbolic` | Query only symbolic memory (100% authority) |
| `episodic` | Query only episodic memory (85% authority) |
| `semantic` | Query only semantic memory (60% authority) |

## See Also

- [bulk-ingest](./bulk-ingest.md) - Ingest files into knowledge base
- [list-projects](./list-projects.md) - List available projects
- [MCP Protocol - get_context](../mcp-protocol/tools/get-context.md) - Get context via MCP
