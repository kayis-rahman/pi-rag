# Memory Fix - Requirements

**Feature ID**: 012-memory-fix
**Status**: [Completed]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026
**Completion Date**: February 1, 2026
**Commit**: 7941a10

---

## Overview

Fix the critical bug where RAG memory ingestion reports success but content is not searchable. This includes:
- OS-aware configuration system with shortname "sy"
- MCP tool renaming (rag.* → sy.*)
- CLI command renaming (rag → sy)
- Database path unification
- Semantic store API compatibility

**Testing Strategy:**
- Pytest: Automated tests for paths and API
- Manual: OpenCode MCP tool verification

**Status**: ✅ COMPLETED - All objectives met

## User Stories

### US-1: OS-Aware Configuration
**As a** Mac user,
**I want** synapse to use `~/.synapse/data` on Mac,
**So that** I don't have permission issues.

**Acceptance Criteria:**
- [x] `synapse.config` auto-detects OS
- [x] Mac uses `~/.synapse/data`
- [x] Linux uses `/opt/synapse/data` (if writable) or `~/.synapse/data`
- [x] `shortname = "sy"` in config

### US-2: MCP Tool Renaming
**As a** user,
**I want** cleaner MCP tool names,
**So that** they're easier to type.

**Acceptance Criteria:**
- [x] `core.list_projects` → `sy.list_projects`
- [x] `core.search` → `sy.search`
- [x] `core.add_fact` → `sy.add_fact`
- [x] All 8 MCP tools renamed

### US-3: CLI Renaming
**As a** user,
**I want** shorter CLI command,
**So that** it's faster to type.

**Acceptance Criteria:**
- [x] `rag list-projects` → `sy list-projects`
- [x] `rag start` → `sy start`
- [x] `rag stop` → `sy stop`
- [x] `rag status` → `sy status`

### US-4: Memory Persistence Fix
**As a** user,
**I want** ingested content to be searchable,
**So that** the RAG system actually works.

**Acceptance Criteria:**
- [x] `sy.add_fact` stores facts in queryable location
- [x] `sy.ingest_file` creates searchable chunks
- [x] `sy.search` returns results for ingested content
- [x] No discrepancy between success and actual storage

---

## Functional Requirements

### FR-1: Configuration System
- [x] FR-1.1 Create `synapse/config/config.py` with OS detection
- [x] FR-1.2 Add `shortname = "sy"` to config
- [x] FR-1.3 Implement OS-specific data directories
- [x] FR-1.4 Add environment variable override support
- [x] FR-1.5 Export from `synapse/config/__init__.py`

### FR-2: MCP Tool Renaming
- [x] FR-2.1 Rename `core.list_projects` → `sy.list_projects`
- [x] FR-2.2 Rename `core.list_sources` → `sy.list_sources`
- [x] FR-2.3 Rename `core.search` → `sy.search`
- [x] FR-2.4 Rename `core.get_context` → `sy.get_context`
- [x] FR-2.5 Rename `core.ingest_file` → `sy.ingest_file`
- [x] FR-2.6 Rename `core.add_fact` → `sy.add_fact`
- [x] FR-2.7 Rename `core.add_episode` → `sy.add_episode`
- [x] FR-2.8 Rename `core.analyze_conversation` → `sy.analyze_conversation`

### FR-3: CLI Renaming
- [x] FR-3.1 Update Typer app name from "rag" to "sy"
- [x] FR-3.2 Update `synapse start/stop/status` commands
- [x] FR-3.3 Update `synapse ingest` command
- [x] FR-3.4 Update help text

### FR-4: Memory Bug Fix
- [x] FR-4.1 Update `mcp_server/rag_server.py` to use new config
- [x] FR-4.2 Fix database path to use `synapse.config`
- [x] FR-4.3 Create data directory if missing
- [x] FR-4.4 Fix semantic store API signature
- [x] FR-4.5 Add path validation before writes
- [x] FR-4.6 Add logging for write operations

### FR-5: Automated Tests
- [x] FR-5.1 Create `tests/unit/test_memory_paths.py`
- [x] FR-5.2 Create `tests/unit/test_semantic_api.py`
- [x] FR-5.3 Update existing tests for new tool names
- [x] FR-5.4 All tests pass with 90%+ coverage

---

## Files to Modify

| File | Change | Priority |
|------|--------|----------|
| `synapse/config/config.py` | NEW - OS-aware config | CRITICAL |
| `synapse/config/__init__.py` | Update exports | HIGH |
| `mcp_server/rag_server.py` | Rename MCP tools | CRITICAL |
| `synapse/main.py` | Rename CLI | CRITICAL |
| `tests/unit/test_memory_paths.py` | NEW - Path tests | REQUIRED |
| `tests/unit/test_semantic_api.py` | NEW - API tests | REQUIRED |
| `tests/**/*.py` | Update tool references | MEDIUM |

---

## Success Criteria

### Must Have
- [x] `shortname = "sy"` in config
- [x] All 8 MCP tools renamed to `sy.*`
- [x] CLI uses `sy` instead of `rag`
- [x] `sy.add_fact` stores queryable facts
- [x] `sy.search` returns results
- [x] All pytest tests pass

### Should Have
- [x] 90%+ test coverage
- [x] Clear logging of database paths
- [x] Updated documentation

**Status**: ✅ ALL CRITERIA MET

## Timeline

| Phase | Duration |
|-------|----------|
| 1. Configuration | 1-2 hours |
| 2. MCP Renaming | 1 hour |
| 3. CLI Renaming | 1 hour |
| 4. Memory Fix | 2-3 hours |
| 5. Tests | 1-2 hours |
| 6. Validation | 1 hour |
| **Total** | **7-10 hours** |

---

**Created**: February 1, 2026
**Status**: Ready for implementation
