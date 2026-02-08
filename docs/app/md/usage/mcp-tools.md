---
title: MCP Tools
description: Complete reference of SYNAPSE MCP tools
---

# MCP Tools

SYNAPSE provides 7 MCP tools for interacting with the memory system.

## Tool 1: `sy.proj.list`

List all registered projects.

### Parameters

```json
{}
```

### Example

```json
{
  "method": "tools/call",
  "params": {
    "name": "sy.proj.list",
    "arguments": {}
  }
}
```

---

## Tool 2: `sy.src.list`

List all document sources in a project.

### Parameters

```json
{
  "project_id": "synapse"
}
```

### Example

```json
{
  "method": "tools/call",
  "params": {
    "name": "sy.src.list",
    "arguments": {
      "project_id": "synapse"
    }
  }
}
```

---

## Tool 3: `sy.ctx.get`

Get comprehensive context from all memory types (dendrites, synapses, cell bodies).

### Parameters

```json
{
  "project_id": "synapse",
  "context_type": "all",
  "query": "your question here",
  "max_results": 10
}
```

### Example

```json
{
  "method": "tools/call",
  "params": {
    "name": "sy.ctx.get",
    "arguments": {
      "project_id": "synapse",
      "context_type": "all",
      "query": "How does SYNAPSE work?",
      "max_results": 10
    }
  }
}
```

---

## Tool 4: `sy.mem.search`

Search dendrites (semantic memory) for relevant documents.

### Parameters

```json
{
  "project_id": "synapse",
  "query": "search term",
  "memory_type": "semantic",
  "top_k": 3
}
```

### Example

```json
{
  "method": "tools/call",
  "params": {
    "name": "sy.mem.search",
    "arguments": {
      "project_id": "synapse",
      "query": "architecture",
      "memory_type": "semantic",
      "top_k": 3
    }
  }
}
```

---

## Tool 5: `sy.mem.ingest`

Ingest files into semantic memory.

### Parameters

```json
{
  "file_path": "/path/to/file",
  "project_id": "synapse",
  "metadata": {
    "type": "code"
  }
}
```

### Example

```json
{
  "method": "tools/call",
  "params": {
    "name": "sy.mem.ingest",
    "arguments": {
      "file_path": "/path/to/file.py",
      "project_id": "synapse",
      "metadata": {
        "type": "code"
      }
    }
  }
}
```

---

## Tool 6: `sy.mem.fact.add`

Add authoritative facts to cell bodies (symbolic memory).

### Parameters

```json
{
  "project_id": "synapse",
  "fact_key": "system_version",
  "fact_value": "1.3.0",
  "confidence": 1.0,
  "category": "system"
}
```

### Example

```json
{
  "method": "tools/call",
  "params": {
    "name": "sy.mem.fact.add",
    "arguments": {
      "project_id": "synapse",
      "fact_key": "system_version",
      "fact_value": "1.3.0",
      "confidence": 1.0,
      "category": "system"
    }
  }
}
```

---

## Tool 7: `sy.mem.ep.add`

Add episodic lessons to synapses (episodic memory).

### Parameters

```json
{
  "project_id": "synapse",
  "title": "Successful pattern",
  "content": "Situation: ..., Action: ..., Outcome: ..., Lesson: ...",
  "lesson_type": "pattern",
  "quality": 0.9
}
```

### Example

```json
{
  "method": "tools/call",
  "params": {
    "name": "sy.mem.ep.add",
    "arguments": {
      "project_id": "synapse",
      "title": "Successful ingestion pattern",
      "content": "Situation: Bulk ingestion completed. Action: Used synapse-bulk-ingest command. Outcome: All 500 files processed successfully. Lesson: Dry-run before actual ingestion prevents errors.",
      "lesson_type": "success",
      "quality": 0.9
    }
  }
}
```
