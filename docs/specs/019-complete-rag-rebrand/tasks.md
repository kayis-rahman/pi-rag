# Tasks: Complete RAG to Synapse Rebrand

**Feature ID**: 019-complete-rag-rebrand
**Status**: ✅ COMPLETED
**Date**: 2026-02-08
**Total Tasks**: 57
**Completed**: 57
**Progress**: 100%
**Final Commit**: 858e950

---

## Phase 1: Class Renames (6 tasks)

- [x] **Task 1.1**: Rename `Orchestrator` → `Orchestrator` in `core/orchestrator.py`
- [x] **Task 1.2**: Rename `MemoryBackend` → `MemoryBackend` in `mcp_server/synapse_server.py`
- [x] **Task 1.3**: Update exports in `core/__init__.py`
- [x] **Task 1.4**: Update exports in `mcp_server/__init__.py`
- [x] **Task 1.5**: Update import in `mcp_server/http_wrapper.py`
- [x] **Task 1.6**: Rename `SYNAPSE_HEADER` → `CONTEXT_HEADER` in `core/prompt_builder.py`

**Verification:**
- [x] Task 1.7: Test import `from core import Orchestrator`
- [x] Task 1.8: Test import `from mcp_server import MemoryBackend`

---

## Phase 2: Class Reference Updates (8 tasks)

- [x] **Task 2.1**: Update `tests/unit/rag/test_orchestrator.py` - all Orchestrator references
- [x] **Task 2.2**: Update `tests/integration/test_rag_pipeline.py` - class references
- [x] **Task 2.3**: Update `tests/test_infrastructure.py` - import and usage
- [x] **Task 2.4**: Update `tests/test_conversation_analyzer.py` - MemoryBackend references
- [x] **Task 2.5**: Update `tests/unit/test_mcp_data_directory.py` - MemoryBackend references
- [x] **Task 2.6**: Rename test classes: `TestOrchestrator*` → `TestOrchestrator*`
- [x] **Task 2.7**: Update any docstring references
- [x] **Task 2.8**: Verify no Orchestrator/MemoryBackend references remain

---

## Phase 3: Environment Variables - Core (8 tasks)

- [x] **Task 3.1**: Replace `RAG_DATA_DIR` → `SYNAPSE_DATA_DIR` in all Python files
- [x] **Task 3.2**: Replace `RAG_CONFIG_PATH` → `SYNAPSE_CONFIG_PATH` in all Python files
- [x] **Task 3.3**: Replace `RAG_ENV` → `SYNAPSE_ENV` in all Python files
- [x] **Task 3.4**: Replace `RAG_TEST_MODE` → `SYNAPSE_TEST_MODE` in all Python files
- [x] **Task 3.5**: Update `core/embedding.py` - SYNAPSE_TEST_MODE reference
- [x] **Task 3.6**: Update `tests/conftest.py` - SYNAPSE_TEST_MODE
- [x] **Task 3.7**: Update `tests/unit/test_embedding.py` - SYNAPSE_TEST_MODE
- [x] **Task 3.8**: Update `synapse/cli/commands/start.py` - SYNAPSE_ENV, SYNAPSE_DATA_DIR, SYNAPSE_CONFIG_PATH

---

## Phase 4: Environment Variables - Upload (8 tasks)

- [x] **Task 4.1**: Replace `RAG_REMOTE_UPLOAD_ENABLED` → `SYNAPSE_REMOTE_UPLOAD_ENABLED`
- [x] **Task 4.2**: Replace `RAG_UPLOAD_DIR` → `SYNAPSE_UPLOAD_DIR`
- [x] **Task 4.3**: Replace `RAG_UPLOAD_MAX_AGE` → `SYNAPSE_UPLOAD_MAX_AGE`
- [x] **Task 4.4**: Replace `RAG_UPLOAD_MAX_SIZE` → `SYNAPSE_UPLOAD_MAX_SIZE`
- [x] **Task 4.5**: Update `mcp_server/synapse_server.py` - 7 env var references
- [x] **Task 4.6**: Update `mcp_server/project_manager.py` - SYNAPSE_DATA_DIR, SYNAPSE_CONFIG_PATH
- [x] **Task 4.7**: Update `mcp_server/metrics.py` - SYNAPSE_DATA_DIR
- [x] **Task 4.8**: Verify no RAG_* env vars remain in Python files

---

## Phase 5: Documentation Updates (10 tasks)

- [x] **Task 5.1**: Update `README.md` - all env var references
- [x] **Task 5.2**: Update `AGENTS.md` - class and env var references
- [x] **Task 5.3**: Update `CHANGELOG.md` - document breaking changes
- [x] **Task 5.4**: Update all spec documents in `docs/specs/`
- [x] **Task 5.5**: Update VitePress docs in `docs/app/md/`
- [x] **Task 5.6**: Update Starlight docs in `docs/content/docs/`
- [x] **Task 5.7**: Update archive documents (if needed)
- [x] **Task 5.8**: Update development guides
- [x] **Task 5.9**: Update API reference docs
- [x] **Task 5.10**: Verify no RAG references in documentation

---

## Phase 6: Configuration Files (5 tasks)

- [x] **Task 6.1**: Update `docker-compose.yml` - all SYNAPSE_* env vars
- [x] **Task 6.2**: Update `docker-compose.override.yml` - if exists
- [x] **Task 6.3**: Update `pyproject.toml` - any RAG references
- [x] **Task 6.4**: Update `configs/*.json` - if any hardcoded
- [x] **Task 6.5**: Update any shell scripts in `scripts/`

---

## Phase 7: Migration Guide & Version (3 tasks)

- [x] **Task 7.1**: Create `MIGRATION_v2.0.md` with comprehensive guide
- [x] **Task 7.2**: Update `CHANGELOG.md` with v2.0.0 breaking changes
- [x] **Task 7.3**: Update version in `pyproject.toml` to 2.0.0

---

## Phase 8: Testing & Validation (5 tasks)

- [x] **Task 8.1**: Verify no `RAGOrchestrator` references: `grep -r "RAGOrchestrator" --include="*.py" .`
- [x] **Task 8.2**: Verify no `RAGMemoryBackend` references: `grep -r "RAGMemoryBackend" --include="*.py" .`
- [x] **Task 8.3**: Verify no `RAG_` env vars: `grep -r "RAG_" --include="*.py" . | grep -v "MIGRATION"`
- [x] **Task 8.4**: Run test suite: `pytest tests/ -v`
- [x] **Task 8.5**: Test imports work: `python -c "from core import Orchestrator; from mcp_server import MemoryBackend"`

---

## Phase 9: Finalization (2 tasks)

- [x] **Task 9.1**: Update `docs/specs/index.md` - mark Feature 019 as complete
- [x] **Task 9.2**: Create comprehensive commit message and push (commit 858e950)

---

## Progress Summary

| Phase | Tasks | Complete | Status |
|-------|-------|----------|--------|
| Phase 1: Class Renames | 8 | 8 | ✅ Complete |
| Phase 2: Class References | 8 | 8 | ✅ Complete |
| Phase 3: Env Vars - Core | 8 | 8 | ✅ Complete |
| Phase 4: Env Vars - Upload | 8 | 8 | ✅ Complete |
| Phase 5: Documentation | 10 | 10 | ✅ Complete |
| Phase 6: Config Files | 5 | 5 | ✅ Complete |
| Phase 7: Migration Guide | 3 | 3 | ✅ Complete |
| Phase 8: Testing | 5 | 5 | ✅ Complete |
| Phase 9: Finalization | 2 | 2 | ✅ Complete |
| **Total** | **57** | **57** | **100%** |

---

## Additional Fixes (Post-Merge Cleanup)

The following fixes were applied on 2026-02-08 after initial merge:

- [x] Update `core/auto_learning_tracker.py` - hardcoded `rag.*` tool names → `sy.*`
- [x] Update `tests/test_auto_learning_tracker.py` - test fixtures use new tool names
- [x] Update `core/metrics_collector.py` - example string updated
- [x] Update `.opencode/plugins/README.md` - all `rag.*` references → `sy.*`
- [x] Update `core/ingest.py` - CLI usage string updated
- [x] Update `core/logger.py` - log path `rag.log` → `synapse.log`

---

## Phase 10: MCP Tool Name Alignment (NEW - 2026-02-09)

**Problem**: MCP tools are being exposed with auto-generated names (`synapse_sy_proj_list`) instead of AGENTS.md specification (`sy.proj.list`).

**Root Cause**: FastMCP ignores `@mcp.tool(name="...")` parameter and uses function names.

**Solution**: Rename Python functions to match desired tool names.

### Tasks

- [ ] **Task 10.1**: Rename `list_projects` → `sy_proj_list` in `mcp_server/http_wrapper.py`
- [ ] **Task 10.2**: Rename `list_sources` → `sy_src_list` in `mcp_server/http_wrapper.py`
- [ ] **Task 10.3**: Rename `get_context` → `sy_ctx_get` in `mcp_server/http_wrapper.py`
- [ ] **Task 10.4**: Rename `search` → `sy_mem_search` in `mcp_server/http_wrapper.py`
- [ ] **Task 10.5**: Rename `ingest_file` → `sy_mem_ingest` in `mcp_server/http_wrapper.py`
- [ ] **Task 10.6**: Rename `add_fact` → `sy_mem_fact_add` in `mcp_server/http_wrapper.py`
- [ ] **Task 10.7**: Rename `add_episode` → `sy_mem_ep_add` in `mcp_server/http_wrapper.py`
- [ ] **Task 10.8**: Update `tests/integration/test_mcp_server.py` - test references
- [ ] **Task 10.9**: Update `CHANGELOG.md` - document tool name fix
- [ ] **Task 10.10**: Verify tool names match AGENTS.md: `grep -r "sy\.(proj|src|ctx|mem)" mcp_server/`

**Expected Tool Names After Fix:**
- `sy.proj.list` ✅
- `sy.src.list` ✅
- `sy.ctx.get` ✅
- `sy.mem.search` ✅
- `sy.mem.ingest` ✅
- `sy.mem.fact.add` ✅
- `sy.mem.ep.add` ✅

### Progress Summary (Updated)

| Phase | Tasks | Complete | Status |
|-------|-------|----------|--------|
| Phase 10: MCP Tool Names | 10 | 0 | 🔄 In Progress |
| **Total with Phase 10** | **67** | **57** | **85%** |

---

**Notes:**
- ✅ Feature fully merged to develop (commit 858e950)
- ✅ All old references cleaned up
- ✅ v2.0.0 breaking change documented
- ✅ Migration guide available at MIGRATION_v2.0.md
- 🔄 **Phase 10 in progress** - MCP tool name alignment
