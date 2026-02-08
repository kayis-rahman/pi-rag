# MCP Tool Validation Results

**Date**: January 31, 2026  
**Method**: curl HTTP requests only (NO code modifications)

---

## Test Results Summary

| Tool | Status | Error |
|------|--------|-------|
| list_projects | ❌ FAIL | Permission denied: '/opt/synapse' |
| list_sources | ❌ FAIL | Permission denied: '/opt/synapse' |
| get_context | ❌ FAIL | Permission denied: '/opt/synapse' |
| search | ❌ FAIL | Permission denied: '/opt/synapse' |
| ingest_file | ❌ FAIL | Permission denied: '/opt/synapse' |
| add_fact | ❌ FAIL | Permission denied: '/opt/synapse' |
| add_episode | ❌ FAIL | Permission denied: '/opt/synapse' |
| analyze_conversation | ❌ FAIL | Permission denied: '/opt/synapse' |
| upload (v1/upload) | ✅ PASS | File uploaded successfully |

**Success Rate**: 1/9 tools (11%)

---

## Detailed Test Commands

### 5.1: list_projects
```bash
curl -X POST http://localhost:8002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_projects","arguments":{}}}'
```
**Result**: ❌ FAIL
```
Error: [Errno 13] Permission denied: '/opt/synapse'
```

### 5.2: list_sources
```bash
curl -X POST http://localhost:8002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_sources","arguments":{"project_id":"synapse"}}}'
```
**Result**: ❌ FAIL
```
Error: [Errno 13] Permission denied: '/opt/synapse'
```

### 5.3: get_context
```bash
curl -X POST http://localhost:8002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_context","arguments":{"project_id":"synapse","context_type":"all","query":"CLI"}}}'
```
**Result**: ❌ FAIL
```
Error: [Errno 13] Permission denied: '/opt/synapse'
```

### 5.4: search
```bash
curl -X POST http://localhost:8002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search","arguments":{"project_id":"synapse","query":"RAG system","memory_type":"semantic","top_k":3}}}'
```
**Result**: ❌ FAIL
```
Error: [Errno 13] Permission denied: '/opt/synapse'
```

### 5.5: upload (v1/upload) ✅ WORKING
```bash
curl -X POST http://localhost:8002/v1/upload \
  -F "file=@/Users/kayisrahman/Documents/workspace/ideas/synapse/README.md"
```
**Result**: ✅ PASS
```json
{
    "status": "success",
    "file_path": "/tmp/rag-uploads/3f32ff93_README.md",
    "original_filename": "README.md",
    "file_size": 7166,
    "message": "File uploaded successfully."
}
```

### 5.6: ingest_file
```bash
curl -X POST http://localhost:8002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"ingest_file","arguments":{"project_id":"synapse","file_path":"/tmp/rag-uploads/3f32ff93_README.md","source_type":"code"}}}'
```
**Result**: ❌ FAIL
```
Error: [Errno 13] Permission denied: '/opt/synapse'
```

### 5.7: add_fact
```bash
curl -X POST http://localhost:8002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"add_fact","arguments":{"project_id":"synapse","fact_key":"test_fact","fact_value":"test value","category":"test","confidence":1.0}}}'
```
**Result**: ❌ FAIL
```
Error: [Errno 13] Permission denied: '/opt/synapse'
```

### 5.8: add_episode
```bash
curl -X POST http://localhost:8002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"add_episode","arguments":{"project_id":"synapse","title":"Test Episode","content":"Testing add_episode tool","lesson_type":"success","quality":1.0}}}'
```
**Result**: ❌ FAIL
```
Error: [Errno 13] Permission denied: '/opt/synapse'
```

### 5.9: analyze_conversation
```bash
curl -X POST http://localhost:8002/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"analyze_conversation","arguments":{"project_id":"synapse","user_message":"How do I validate?","agent_response":"Run validation script","auto_store":true}}}'
```
**Result**: ❌ FAIL
```
Error: [Errno 13] Permission denied: '/opt/synapse'
```

---

## Root Cause Analysis

All MCP tools fail with the same error:
```
[Errno 13] Permission denied: '/opt/synapse'
```

**Cause**: The MCP server is configured to look for data in `/opt/synapse/data` (Linux default), but on Mac, the data directory is `~/.synapse/data` (user home).

**Impact**: 
- All 8 MCP memory tools are non-functional on Mac
- Only the upload endpoint works (it uses /tmp for temporary uploads)
- Cannot ingest, search, or query via MCP tools
- Cannot add facts or episodes to memory
- Cannot analyze conversations

**Recommended Fix**:
- Configure MCP server to use `~/.synapse/data` on Mac
- OR set environment variable `SYNAPSE_DATA_DIR` to user home path
- OR detect OS and use appropriate data directory

---

## Conclusion

**8/9 MCP tools FAIL** due to permission error on `/opt/synapse`

**Only working tool**: `upload` (v1/upload endpoint)

This is a critical blocker - the MCP server cannot perform any memory operations on Mac.

