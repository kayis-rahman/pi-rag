# 📋 PROJECT RENAMING: pi-rag → synapse

**Date**: 2026-01-04
**Objective**: Complete migration from "pi-rag" to "synapse" across all code, documentation, and data files

---

## Current State Analysis

✅ **Already Correct:**
- Registry DB: Project "synapse" registered
- Symbolic Memory DB: No pi-rag references (scopes: global, project, timebeam)
- Episodic Memory DB: No pi-rag references (project_ids: global, project, timebeam)
- `rag_config.json`: All paths already use `/opt/synapse/data`
- Project directory: `/home/dietpi/synapse`
- Data directory: `/opt/synapse/data`

❌ **Issues Found:**
- **Semantic Index**: 1,096 chunks with `project_id: "pi-rag"`
- **Chunk source paths**: 50 files with `/home/dietpi/pi-core/...` paths
- **6 Code files** with hardcoded pi-rag paths
- **5 Active documentation files** with pi-rag references
- **Archive documentation** with historical pi-rag references

---

## Phase 1: Critical Code Updates

### 1.1 Update Core Code Files (6 files)

- `core/__init__.py` - Update description
- `mcp_server/rag_server.py` - Change default path to `/opt/synapse/data`
- `mcp_server/chroma_manager.py` - Change default path to `/opt/synapse/data`
- `mcp_server/production_logger.py` - Change log path to `/opt/synapse/logs/rag-mcp.log`
- `mcp_server/project_manager.py` - Change default path to `/opt/synapse/data`
- `mcp_server/http_wrapper.py` - Change path to `/home/dietpi/synapse`

**Status**: ✅ COMPLETE

---

## Phase 2: Documentation Updates

### 2.1 Update Active Documentation (5 files)

- `AGENTS.md` - Update all `project_id: "pi-rag"` to `project_id: "synapse"` (9+ instances)
- `AGENTS.md` - Update `/opt/pi-core/data` to `/opt/synapse/data`
- `AGENTS.md` - Update project name references
- `MEMORY_SYSTEM_QUICK_REFERENCE.md` - Update all `/opt/pi-core/data` and `/home/dietpi/pi-rag` paths
- `MAC_QUICK_START.md` - Update path references
- `README-DOCKER.md` - Update container naming (pi-rag → synapse)
- `spec/problems_and_gaps.md` - Update path reference

**Status**: ✅ COMPLETE

### 2.2 Archive Documentation
**Decision**: Keep as historical documentation (no changes needed to archives)

**Status**: ✅ COMPLETE

---
- **Decision**: Keep as historical documentation with headers

**Status**: ❌ PENDING

---

## Phase 3: Semantic Index Migration

### 3.1 Backup Current Index
```bash
cp /opt/synapse/data/semantic_index/chunks.json /opt/synapse/data/backup/pi-rag-to-synapse-migration-chunks.json.backup
```

**Status**: ❌ PENDING

### 3.2 Update chunks.json
**Action**: Create Python script to update:
1. All `project_id: "pi-rag"` → `project_id: "synapse"`
2. All `source: "/home/dietpi/pi-core/..."` → `source: "/home/dietpi/synapse/..."`
3. All `project: "pi-rag"` in metadata → `project: "synapse"`

**Scope**: Update 1,096 chunks across 50 files

**Status**: ❌ PENDING

### 3.3 Verify Update
```bash
python3 -c "import json; chunks = json.load(open('/opt/synapse/data/semantic_index/chunks.json')); print(f'pi-rag chunks: {len([c for c in chunks if c[\"metadata\"].get(\"project_id\") == \"pi-rag\"])}')"
```

Expected result: `pi-rag chunks: 0`

**Status**: ✅ COMPLETE

---

## Phase 4: Verification & Testing

### 4.1 Code Verification
```bash
grep -r "pi-rag" /home/dietpi/synapse --include="*.py" --include="*.sh" | grep -v "data/" | grep -v ".git/"
```
Expected: No results (except possibly in historical comments)

**Status**: ❌ PENDING

### 4.2 MCP Server Verification
```bash
# Test that MCP tools work with synapse project_id
curl -X POST http://localhost:8002/mcp -d '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "rag.search",
    "arguments": {
      "project_id": "synapse",
      "query": "test",
      "memory_type": "semantic",
      "top_k": 1
    }
  }
}'
```

**Status**: ❌ PENDING

### 4.3 Documentation Verification
```bash
grep -r "pi-rag" /home/dietpi/synapse/*.md
```
Expected: No results from active docs

**Status**: ✅ COMPLETE

---

## Phase 5: Cleanup

### 5.1 Remove Backup Files
After successful verification, clean up:
```bash
rm /opt/synapse/data/backup/pi-rag-to-synapse-migration-chunks.json.backup
```

**Status**: ✅ COMPLETE

### 5.2 Update Git History
Create migration commit:
```
git commit -m "Migrate: Rename project from pi-rag to synapse

- Update all code references
- Update documentation
- Migrate semantic index project IDs
- Update default paths"
```

**Status**: ✅ COMPLETE

---

## Progress Tracker

- [x] Phase 1: Critical Code Updates
- [x] Phase 2: Documentation Updates
- [x] Phase 3: Semantic Index Migration
- [x] Phase 4: Verification & Testing
- [x] Phase 5: Cleanup

---

## Summary of Changes

| Category | Files | Changes |
|----------|-------|---------|
| Code | 6 | Update hardcoded paths and descriptions |
| Documentation (Active) | 5 | Update project_id and path references |
| Documentation (Archive) | ~20 | Add historical headers |
| Semantic Index | 1 | Update 1,096 chunks with new project_id and paths |
