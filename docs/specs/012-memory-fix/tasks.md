# Memory Fix - Task Breakdown

**Feature ID**: 012-memory-fix
**Status**: [In Progress]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026

---

## Task Statistics

| Phase | Tasks | Duration |
|-------|-------|----------|
| 1. Configuration | 8 | 1-2 hours |
| 2. MCP Renaming | 10 | 1 hour |
| 3. CLI Renaming | 6 | 1 hour |
| 4. Memory Fix | 12 | 2-3 hours |
| 5. Tests | 8 | 1-2 hours |
| 6. Validation | 4 | 1 hour |
| **Total** | **48 tasks** | **7-10 hours** |

---

## Phase 1: OS-Aware Configuration (8 tasks)

### 1.1 Create config module
- [ ] 1.1.1 Create `synapse/config/config.py` with `SHORTNAME = "sy"` (Linked to FR-1.1, FR-1.2)
- [ ] 1.1.2 Implement `SynapseConfig` class with OS detection (Linked to FR-1.3)
- [ ] 1.1.3 Add `config_dir` property with OS-specific paths (Linked to FR-1.3)
- [ ] 1.1.4 Add `data_dir`, `database_path`, `index_dir` properties (Linked to FR-1.3)

### 1.2 Config loading
- [ ] 1.2.1 Implement `_load_os_defaults()` method (Linked to FR-1.3)
- [ ] 1.2.2 Implement `_load_project_config()` method (Linked to FR-1.3)
- [ ] 1.2.3 Implement `_load_user_config()` method (Linked to FR-1.3)
- [ ] 1.2.4 Implement `_load_env_overrides()` method (Linked to FR-1.4)

### 1.3 Export config
- [ ] 1.3.1 Update `synapse/config/__init__.py` exports (Linked to FR-1.5)
- [ ] 1.3.2 Add `get_config()`, `get_data_dir()`, `get_database_path()` (Linked to FR-1.5)

**Phase 1 Exit Criteria:** Config module created, exports work, OS detection functional

---

## Phase 2: MCP Tool Renaming (10 tasks)

### 2.1 Read current tools
- [ ] 2.1.1 Read `mcp_server/rag_server.py` tool registration section (Linked to FR-2)
- [ ] 2.1.2 Identify all 8 tool definitions (Linked to FR-2)

### 2.2 Rename tools
- [ ] 2.2.1 Rename `rag.list_projects` → `sy.list_projects` (Linked to FR-2.1)
- [ ] 2.2.2 Rename `rag.list_sources` → `sy.list_sources` (Linked to FR-2.2)
- [ ] 2.2.3 Rename `rag.search` → `sy.search` (Linked to FR-2.3)
- [ ] 2.2.4 Rename `rag.get_context` → `sy.get_context` (Linked to FR-2.4)
- [ ] 2.2.5 Rename `rag.ingest_file` → `sy.ingest_file` (Linked to FR-2.5)
- [ ] 2.2.6 Rename `rag.add_fact` → `sy.add_fact` (Linked to FR-2.6)
- [ ] 2.2.7 Rename `rag.add_episode` → `sy.add_episode` (Linked to FR-2.7)
- [ ] 2.2.8 Rename `rag.analyze_conversation` → `sy.analyze_conversation` (Linked to FR-2.8)

**Phase 2 Exit Criteria:** All MCP tools use `sy.*` prefix

---

## Phase 3: CLI Renaming (6 tasks)

### 3.1 Update main CLI
- [ ] 3.1.1 Import `get_shortname()` from synapse.config (Linked to FR-3)
- [ ] 3.1.2 Change Typer app name from "rag" to `get_shortname()` (Linked to FR-3.1)
- [ ] 3.1.3 Update help text to reflect new command names (Linked to FR-3.4)

### 3.2 Update commands
- [ ] 3.2.1 Update `synapse/cli/commands/start.py` imports if needed (Linked to FR-3.2)
- [ ] 3.2.2 Update `synapse/cli/commands/stop.py` imports if needed (Linked to FR-3.2)
- [ ] 3.2.3 Update `synapse/cli/commands/status.py` imports if needed (Linked to FR-3.2)

**Phase 3 Exit Criteria:** CLI uses `sy` instead of `rag`

---

## Phase 4: Memory Bug Fix (12 tasks)

### 4.1 Update MCP server config
- [ ] 4.1.1 Import `get_data_dir()` in `mcp_server/rag_server.py` (Linked to FR-4.1)
- [ ] 4.1.2 Update `_get_data_dir()` to use `get_data_dir()` (Linked to FR-4.2)
- [ ] 4.1.3 Add `_ensure_data_dir()` method to create directories (Linked to FR-4.3)
- [ ] 4.1.4 Add path validation before writes (Linked to FR-4.5)

### 4.2 Add logging
- [ ] 4.2.1 Add logging for data directory path (Linked to FR-4.6)
- [ ] 4.2.2 Add logging for write operations (Linked to FR-4.6)
- [ ] 4.2.3 Add logging for database path resolution (Linked to FR-4.6)

### 4.3 Fix semantic store
- [ ] 4.3.1 Verify `rag/semantic_store.py` search method signature (Linked to FR-4.4)
- [ ] 4.3.2 Fix any API compatibility issues (Linked to FR-4.4)
- [ ] 4.3.3 Add type hints to search method (Linked to FR-4.4)

### 4.4 Test path resolution
- [ ] 4.4.1 Test data directory creation (Linked to FR-4.3)
- [ ] 4.4.2 Test database path resolution (Linked to FR-4.2)

**Phase 4 Exit Criteria:** Memory operations work, paths validated

---

## Phase 5: Tests (8 tasks)

### 5.1 Create test files
- [ ] 5.1.1 Create `tests/unit/test_memory_paths.py` (Linked to FR-5.1)
- [ ] 5.1.2 Create `tests/unit/test_semantic_api.py` (Linked to FR-5.2)

### 5.2 Add test cases
- [ ] 5.2.1 Add Mac data directory test (Linked to FR-5.1)
- [ ] 5.2.2 Add Linux data directory test (Linked to FR-5.1)
- [ ] 5.2.3 Add environment variable override test (Linked to FR-5.1)
- [ ] 5.2.4 Add semantic API signature test (Linked to FR-5.2)

### 5.3 Run tests
- [ ] 5.3.1 Run `pytest tests/unit/test_memory_paths.py -v` (Linked to FR-5.3)
- [ ] 5.3.2 Run `pytest tests/unit/test_semantic_api.py -v` (Linked to FR-5.3)

**Phase 5 Exit Criteria:** All tests pass, 90%+ coverage

---

## Phase 6: Validation (4 tasks)

### 6.1 Manual testing
- [ ] 6.1.1 Test `sy.list_projects` via MCP (Linked to Must Have)
- [ ] 6.1.2 Test `sy.add_fact` and `sy.search` (Linked to Must Have)

### 6.2 Integration test
- [ ] 6.2.1 Test CLI `sy start/stop/status` (Linked to Must Have)
- [ ] 6.2.2 Verify no errors in logs (Linked to Must Have)

**Phase 6 Exit Criteria:** All functionality verified

---

## Testing Commands

```bash
# Run configuration tests
pytest tests/unit/test_memory_paths.py -v

# Run API tests
pytest tests/unit/test_semantic_api.py -v

# Run all new tests
pytest tests/unit/test_memory_paths.py tests/unit/test_semantic_api.py -v

# Run with coverage
pytest tests/unit/test_memory_paths.py tests/unit/test_semantic_api.py --cov=synapse.config --cov=rag.semantic_store
```

---

**Last Updated**: February 1, 2026
**Status**: Ready for implementation
**Next Phase**: Phase 1 - Configuration
