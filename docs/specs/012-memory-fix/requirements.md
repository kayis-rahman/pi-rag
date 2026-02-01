# Memory Fix - Requirements

**Feature ID**: 012-memory-fix
**Status**: [In Progress]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026

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

---

## User Stories

### US-1: OS-Aware Configuration
**As a** Mac user,
**I want** synapse to use `~/.synapse/data` on Mac,
**So that** I don't have permission issues.

**Acceptance Criteria:**
- [ ] `synapse.config` auto-detects OS
- [ ] Mac uses `~/.synapse/data`
- [ ] Linux uses `/opt/synapse/data` (if writable) or `~/.synapse/data`
- [ ] `shortname = "sy"` in config

### US-2: MCP Tool Renaming
**As a** user,
**I want** cleaner MCP tool names,
**So that** they're easier to type.

**Acceptance Criteria:**
- [ ] `rag.list_projects` → `sy.list_projects`
- [ ] `rag.search` → `sy.search`
- [ ] `rag.add_fact` → `sy.add_fact`
- [ ] All 8 MCP tools renamed

### US-3: CLI Renaming
**As a** user,
**I want** shorter CLI command,
**So that** it's faster to type.

**Acceptance Criteria:**
- [ ] `rag list-projects` → `sy list-projects`
- [ ] `rag start` → `sy start`
- [ ] `rag stop` → `sy stop`
- [ ] `rag status` → `sy status`

### US-4: Memory Persistence Fix
**As a** user,
**I want** ingested content to be searchable,
**So that** the RAG system actually works.

**Acceptance Criteria:**
- [ ] `sy.add_fact` stores facts in queryable location
- [ ] `sy.ingest_file` creates searchable chunks
- [ ] `sy.search` returns results for ingested content
- [ ] No discrepancy between success and actual storage

---

## Functional Requirements

### FR-1: Configuration System
- [ ] FR-1.1 Create `synapse/config/config.py` with OS detection
- [ ] FR-1.2 Add `shortname = "sy"` to config
- [ ] FR-1.3 Implement OS-specific data directories
- [ ] FR-1.4 Add environment variable override support
- [ ] FR-1.5 Export from `synapse/config/__init__.py`

### FR-2: MCP Tool Renaming
- [ ] FR-2.1 Rename `rag.list_projects` → `sy.list_projects`
- [ ] FR-2.2 Rename `rag.list_sources` → `sy.list_sources`
- [ ] FR-2.3 Rename `rag.search` → `sy.search`
- [ ] FR-2.4 Rename `rag.get_context` → `sy.get_context`
- [ ] FR-2.5 Rename `rag.ingest_file` → `sy.ingest_file`
- [ ] FR-2.6 Rename `rag.add_fact` → `sy.add_fact`
- [ ] FR-2.7 Rename `rag.add_episode` → `sy.add_episode`
- [ ] FR-2.8 Rename `rag.analyze_conversation` → `sy.analyze_conversation`

### FR-3: CLI Renaming
- [ ] FR-3.1 Update Typer app name from "rag" to "sy"
- [ ] FR-3.2 Update `synapse start/stop/status` commands
- [ ] FR-3.3 Update `synapse ingest` command
- [ ] FR-3.4 Update help text

### FR-4: Memory Bug Fix
- [ ] FR-4.1 Update `mcp_server/rag_server.py` to use new config
- [ ] FR-4.2 Fix database path to use `synapse.config`
- [ ] FR-4.3 Create data directory if missing
- [ ] FR-4.4 Fix semantic store API signature
- [ ] FR-4.5 Add path validation before writes
- [ ] FR-4.6 Add logging for write operations

### FR-5: Automated Tests
- [ ] FR-5.1 Create `tests/unit/test_memory_paths.py`
- [ ] FR-5.2 Create `tests/unit/test_semantic_api.py`
- [ ] FR-5.3 Update existing tests for new tool names
- [ ] FR-5.4 All tests pass with 90%+ coverage

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
- [ ] `shortname = "sy"` in config
- [ ] All 8 MCP tools renamed to `sy.*`
- [ ] CLI uses `sy` instead of `rag`
- [ ] `sy.add_fact` stores queryable facts
- [ ] `sy.search` returns results
- [ ] All pytest tests pass

### Should Have
- [ ] 90%+ test coverage
- [ ] Clear logging of database paths
- [ ] Updated documentation

---

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
