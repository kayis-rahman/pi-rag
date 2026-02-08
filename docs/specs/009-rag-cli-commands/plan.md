# Plan: RAG CLI Commands

**Feature ID**: 009-rag-cli-commands
**Created**: January 29, 2026
**Updated**: January 29, 2026
**Status**: [In Progress]

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLI Layer                                │
│  synapse ingest | bulk-ingest | query                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Local MCP Server (localhost:8002)               │
│  HTTP POST /v1/upload (file upload)                         │
│  HTTP POST /mcp (MCP tool calls)                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Memory System (Local)                           │
│  ├── Semantic Store (embeddings)                            │
│  ├── Episodic Store (SQLite episodes)                       │
│  └── Symbolic Store (SQLite facts)                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Command Design

### 1. Single File Ingestion

```bash
synapse ingest <FILE> [--project-id ID]

# Examples
synapse ingest README.md                                    # Default project
synapse ingest file.md --project-id myapp                   # Custom project
echo "content" | synapse ingest - --project-id test         # stdin
synapse ingest https://url --project-id myapp               # URL
```

**Implementation**:
1. Method A: Direct local path (backend.ingest_file with file_path)
2. Method B: HTTP upload + MCP (for consistency)
3. Support stdin with `-`
4. Support URL with `ingest-url` subcommand

### 2. Bulk Ingestion CLI

```bash
synapse bulk-ingest <DIR> [--options]

# Examples
synapse bulk-ingest /path/to/project                        # Default
synapse bulk-ingest . --dry-run                             # Preview
synapse bulk-ingest . --file-type code                      # Code only
synapse bulk-ingest . --exclude "*.log" "*.tmp"             # Exclude
synapse bulk-ingest . --incremental                         # Skip unchanged
```

**Implementation**:
- Wrapper: Call `scripts/bulk_ingest.py` via subprocess
- Pass through all options from bulk_ingest.py
- No re-implementation needed

### 3. Query Command

```bash
synapse query "<question>" [--project-id ID] [--json] \
    [--memory-type TYPE] [--top-k N]

# Examples
synapse query "what is the project structure?"
synapse query "logging configuration" --project-id synapse
synapse query "auth flow" --memory-type symbolic --top-k 5
synapse query "?" --json                                      # Machine-readable
```

**Implementation**:
1. Call MCP tool `core.get_context()`
2. Filter by memory_type if specified
3. Limit results by top_k
4. Format output (console or JSON)

---

## File Structure

```
synapse/cli/commands/
├── bulk_ingest.py      # NEW: Wrapper for scripts/bulk_ingest.py

synapse/cli/main.py     # MODIFIED: Implement ingest() and query()

docs/specs/009-rag-cli-commands/
├── requirements.md     # User stories & requirements
├── plan.md             # This file
└── tasks.md            # Task breakdown
```

---

## Dependencies

### Python Libraries
- `requests` - HTTP client for MCP calls
- `pathlib` (stdlib) - File path handling

### Existing Code to Reuse
- `scripts/bulk_ingest.py` - Bulk ingestion logic (call via subprocess)
- `mcp_server/http_wrapper.py` - MCP tool definitions

---

## Configuration

### MCP Server
- Default: `http://localhost:8002/mcp`
- Override: `SYNAPSE_MCP_URL` environment variable

### Upload Endpoint
- Default: `http://localhost:8002/v1/upload`
- Override: `SYNAPSE_UPLOAD_URL` environment variable

---

## Error Handling

| Scenario | Exit Code | Message |
|----------|-----------|---------|
| File not found | 1 | "Error: File not found: <path>" |
| Upload failed | 2 | "Error: Upload failed: <reason>" |
| Ingestion failed | 3 | "Error: Ingestion failed: <reason>" |
| Server unreachable | 4 | "Error: Cannot connect to RAG server" |
| Invalid project ID | 5 | "Error: Invalid project ID" |
| Permission denied | 6 | "Error: Permission denied: <path>" |

---

## Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| Phase 1: CLI Commands | 2 hours | 12 tasks |
| Phase 2: OpenCode Docs | 1 hour | 5 tasks |
| **Total** | **3 hours** | **17 tasks** |

---

## Success Criteria

- [ ] `synapse ingest <file>` works
- [ ] `synapse bulk-ingest <dir>` works
- [ ] `synapse query "<question>"` works
- [ ] OpenCode MCP tools documented
- [ ] Error messages are actionable

---

**Plan Status**: ⏳ Ready for Implementation
