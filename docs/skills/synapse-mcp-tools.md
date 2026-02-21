---
name: synapse-mcp-tools
description: Use when implementing or using the 7 MCP tools in SYNAPSE RAG system
---

# SYNAPSE MCP Tools

## Overview
The SYNAPSE RAG system implements a comprehensive set of 7 MCP (Model Context Protocol) tools that enable AI agents to interact with the cognitive memory system. These tools provide access to three-tier memory architecture with symbolic, episodic, and semantic memory types.

## When to Use
- When building AI agents that need to query or update memory systems
- When implementing MCP-compatible tools for RAG systems
- When working with Claude Code, OpenCode, or other MCP clients
- When needing to ingest documents, query knowledge bases, or store facts/lessons

## Tool Specifications

### 1. `sy.proj.list` - Project Listing Tool
**Description:** List all projects in RAG memory system
**Arguments:**
- `scope_type` (optional): Filter by scope type (user, project, org, session)
**Returns:** Dictionary with projects list and metadata

### 2. `sy.src.list` - Source Listing Tool
**Description:** List document sources for a project in semantic memory
**Arguments:**
- `project_id`: Project identifier
- `source_type` (optional): Filter by source type (file, code, web)
**Returns:** Dictionary with sources list and metadata

### 3. `sy.ctx.get` - Context Retrieval Tool
**Description:** Get comprehensive project context with authority hierarchy
**Arguments:**
- `project_id`: Project identifier
- `context_type`: Type of context to retrieve (all, symbolic, episodic, semantic)
- `query` (optional): Query for semantic retrieval
- `max_results`: Maximum results per memory type
**Returns:** Dictionary with context from each memory type

### 4. `sy.mem.search` - Semantic Search Tool
**Description:** Semantic search across all memory types
**Arguments:**
- `project_id`: Project identifier
- `query`: Search query
- `memory_type`: Type of memory to search (all, symbolic, episodic, semantic)
- `top_k`: Number of results
**Returns:** Dictionary with search results

### 5. `sy.mem.ingest` - File Ingestion Tool
**Description:** Ingest file or text content into semantic memory
**Arguments:**
- `project_id`: Project identifier
- `file_path` (optional): Path to file in upload directory
- `content` (optional): Text content to ingest
- `filename` (optional): Filename for content mode
- `source_type`: Type of source (file, code, web)
- `metadata` (optional): Metadata to attach
**Returns:** Dictionary with ingestion results

### 6. `sy.mem.fact.add` - Symbolic Memory Fact Tool
**Description:** Add a symbolic memory fact (authoritative)
**Arguments:**
- `project_id`: Project identifier
- `fact_key`: The fact key
- `fact_value`: The fact value (any JSON-serializable type)
- `confidence`: Confidence level (0.0-1.0)
- `category`: Fact category (preference, constraint, decision, fact)
**Returns:** Dictionary with fact creation result

### 7. `sy.mem.ep.add` - Episodic Memory Episode Tool
**Description:** Add an episodic memory episode (advisory)
**Arguments:**
- `project_id`: Project identifier
- `title`: Episode title
- `content`: Episode content (situation, action, outcome, lesson)
- `lesson_type`: Type of lesson (general, pattern, mistake, success, failure)
- `quality`: Quality score (0.0-1.0)
**Returns:** Dictionary with episode creation result

## Memory Authority Hierarchy
The MCP tools respect the three-tier memory authority hierarchy:

1. **Symbolic Memory** (100% - Absolute Truth)
   - Authoritative facts explicitly stored
   - Configuration, API endpoints, technical specs
   - Never question or override
   - Managed by `sy.mem.fact.add`

2. **Episodic Memory** (85% - High Priority Guidance)
   - Lessons learned from experience
   - Best practices and advisory guidance
   - Managed by `sy.mem.ep.add`

3. **Semantic Memory** (60% - Reference Suggestions)
   - Document embeddings, code chunks
   - Suggestions that can be inaccurate
   - Managed by `sy.mem.ingest` and `sy.mem.search`

## Usage Examples
### Using curl to call MCP tools:
```bash
# List projects
curl -X POST http://localhost:8003/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"sy.proj.list"},"id":1}

# Get project context
curl -X POST http://localhost:8003/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"sy.ctx.get","arguments":{"project_id":"global"}},"id":1}

# Search memory
curl -X POST http://localhost:8003/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"sy.mem.search","arguments":{"project_id":"global","query":"test query"}},"id":1}
```

## Implementation Details
The system supports two ingestion modes:
1. **HTTP Upload Flow** (Recommended)
   - Upload file via POST to `/v1/upload`
   - Call `sy.mem.ingest` with returned file_path
   - Example:
   ```
   curl -X POST http://localhost:8003/v1/upload -F "file=@document.txt"
   # Then ingest using the returned file_path
   ```

2. **Direct Ingestion**
   - Use `sy.mem.ingest` with file_path parameter
   - Only works when files are accessible to server filesystem

## Common Mistakes
- Using semantic memory as authoritative source
- Not respecting the memory authority hierarchy
- Incorrectly handling file ingestion flows
- Not understanding the difference between symbolic and episodic memory
- Attempting to use content mode when it's disabled

## Real-World Impact
Agents using these MCP tools can:
- Persist knowledge across sessions
- Learn from experiences and store lessons
- Access structured information with high reliability
- Integrate with various MCP-compatible clients like Claude Code
- Maintain a comprehensive knowledge base with proper authority levels