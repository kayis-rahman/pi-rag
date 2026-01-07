# HTTP File Upload Implementation - Quick Reference

## Overview
Added `/v1/upload` HTTP endpoint to MCP server (port 8002) for seamless file ingestion.

## Architecture

```
Client (LLM/Program)    MCP Server (Port 8002)         RAG Backend
─────────────────────────    ──────────────────────────    ─────────────
   POST /v1/upload    →    Upload file to               →
   (multipart/form)         /tmp/rag-uploads/         Ingest content
                           (unique filename)         Embed chunks
                                                    Store in DB
   Get file_path      ←    Returns file_path        ←
   rag.ingest_file(
     file_path="..."
   )                  →    Read & ingest          Auto-delete
                          file async              (non-blocking)
```

## Single Port Configuration
- **Port:** 8002
- **MCP Protocol:** `http://localhost:8002/mcp`
- **HTTP Upload:** `http://localhost:8002/v1/upload`
- **Health Check:** `http://localhost:8002/health`

## Workflow

### Step 1: Upload File (HTTP)
```bash
curl -X POST http://localhost:8002/v1/upload \
  -F "file=@document.txt"
```

**Response:**
```json
{
  "status": "success",
  "file_path": "/tmp/rag-uploads/abc123_document.txt",
  "original_filename": "document.txt",
  "file_size": 1234,
  "upload_directory": "/tmp/rag-uploads",
  "message": "File uploaded successfully. Use rag.ingest_file MCP tool with file_path='/tmp/rag-uploads/abc123_document.txt'. File will be auto-deleted after ingestion."
}
```

### Step 2: Ingest File (MCP Tool)
```python
rag.ingest_file(
    project_id="global",
    file_path="/tmp/rag-uploads/abc123_document.txt",
    source_type="file"
)
```

**Response:**
```json
{
  "status": "success",
  "file_path": "/tmp/rag-uploads/abc123_document.txt",
  "real_path": "/tmp/rag-uploads/abc123_document.txt",
  "chunk_count": 5,
  "doc_id": "abc123...",
  "authority": "non-authoritative",
  "message": "Successfully ingested 5 chunk(s)"
}
```

### Step 3: Auto-Delete (Automatic)
- File deleted 0.5s after successful ingestion (async, non-blocking)
- Only files in `/tmp/rag-uploads/` are auto-deleted (security)
- No manual cleanup needed

## Configuration

From `configs/rag_config.json`:
```json
{
  "remote_file_upload_enabled": true,
  "remote_upload_directory": "/tmp/rag-uploads",
  "remote_upload_max_age_seconds": 3600,
  "remote_upload_max_file_size_mb": 50
}
```

## Features

### ✅ Security
- **Path validation:** Only `/tmp/rag-uploads/` directory allowed
- **File size limit:** Max 50MB (configurable)
- **Realpath check:** Prevents symlink attacks
- **Permissions check:** Read-only access to uploaded files

### ✅ Auto-Delete
- **Async deletion:** Non-blocking after ingestion
- **Security check:** Only deletes files in upload directory
- **Delay:** 0.5s to ensure ingestion completes

### ✅ Validation
- **Empty file check:** Rejects 0-byte files
- **Size limit:** Returns 413 for files >50MB
- **Directory creation:** Auto-creates `/tmp/rag-uploads/`
- **Unique filenames:** UUID prefix prevents conflicts

## Testing

### Test 1: Upload & Ingest
```bash
# Upload file
curl -X POST http://localhost:8002/v1/upload \
  -F "file=@test.txt" \
  -s | jq

# Ingest via MCP tool (in LLM/program)
rag.ingest_file(
    project_id="global",
    file_path="/tmp/rag-uploads/abc123_test.txt"
)

# Verify file deleted
ls -la /tmp/rag-uploads/  # File should be gone
```

### Test 2: File Size Validation
```bash
# Create 51MB file
dd if=/dev/zero of=large.bin bs=1M count=51

# Upload (should fail with 413)
curl -X POST http://localhost:8002/v1/upload \
  -F "file=@large.bin" \
  -s | jq

# Expected: {"status": "error", "message": "File too large: 51.00MB (max: 50MB)"}
```

### Test 3: Search Uploaded Content
```python
# After ingestion, search for content
result = await backend.search(
    project_id="global",
    query="search terms from file",
    memory_type="semantic",
    top_k=5
)

# Should find uploaded content in results
```

## Comparison with Alternatives

### ❌ Original Two-Step Workflow (Before)
```bash
# Manual step 1
scp document.txt pi:/tmp/rag-uploads/

# Manual step 2
# Tell LLM about file path
rag.ingest_file(file_path="/tmp/rag-uploads/document.txt")
```
**Problems:**
- Requires SSH access
- Manual file copy
- Not LLM-friendly

### ✅ HTTP Upload (Now)
```python
# Single automated step
upload_response = http_post("/v1/upload", file=document.txt)
rag.ingest_file(file_path=upload_response["file_path"])
```
**Benefits:**
- LLM can automate
- No SSH needed
- Standard HTTP API
- Auto-cleanup

## Server Management

### Start Server
```bash
bash /home/dietpi/pi-rag/start_http_server.sh
```

### Stop Server
```bash
bash /home/dietpi/pi-rag/start_http_server.sh --stop
```

### Check Health
```bash
curl http://localhost:8002/health | jq
```

### View Logs
```bash
tail -f /tmp/mcp_server.log
```

## Summary

**What Changed:**
- ✅ Added `/v1/upload` HTTP endpoint to MCP server
- ✅ Added async auto-deletion after ingestion
- ✅ Port 8002 serves both MCP and HTTP upload
- ✅ File size validation (50MB limit)
- ✅ Security (path validation, symlink protection)

**What Works:**
- ✅ Upload file via HTTP multipart
- ✅ Ingest file via MCP tool `rag.ingest_file`
- ✅ Auto-delete after successful ingestion
- ✅ Search uploaded content via `rag.search`
- ✅ Single port (8002) for everything

**What Didn't Change:**
- ✓ MCP tool `ingest_file` with content mode (still works)
- ✓ Existing file path mode (still works)
- ✓ All other MCP tools (unchanged)

## Files Modified

1. `mcp_server/http_wrapper.py`
   - Added `os`, `shutil`, `uuid` imports
   - Added `/v1/upload` endpoint (~80 lines)
   - Updated root endpoint (tools count, upload info)
   - Updated health endpoint (upload directory check)

2. `mcp_server/rag_server.py`
   - Added `_delete_upload_file_async()` method
   - Enabled auto-deletion in `ingest_file()` tool

**Total:** ~100 lines added, minimal changes to existing code.

## End-to-End Example

```python
# Client code (LLM or program)
import requests

# Step 1: Upload file
response = requests.post(
    "http://localhost:8002/v1/upload",
    files={"file": open("document.txt", "rb")}
)
upload_data = response.json()

# Step 2: Ingest via MCP tool
ingest_result = await mcp_client.call_tool(
    "rag.ingest_file",
    {
        "project_id": "global",
        "file_path": upload_data["file_path"],
        "source_type": "file"
    }
)

# Step 3: Done! File auto-deleted, content searchable
search_result = await mcp_client.call_tool(
    "rag.search",
    {
        "project_id": "global",
        "query": "content from document",
        "memory_type": "semantic",
        "top_k": 5
    }
)
```

**Result:** File uploaded, ingested, deleted, and searchable in <2 seconds.
