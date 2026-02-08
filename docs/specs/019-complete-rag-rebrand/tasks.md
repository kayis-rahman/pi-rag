# Tasks: Complete RAG to Synapse Rebrand

**Feature ID**: 019-complete-rag-rebrand  
**Status**: In Progress  
**Date**: 2026-02-08  
**Total Tasks**: 45  
**Completed**: 0  
**Progress**: 0%

---

## Phase 1: Class Renames (6 tasks)

- [ ] **Task 1.1**: Rename `RAGOrchestrator` → `Orchestrator` in `core/orchestrator.py`
- [ ] **Task 1.2**: Rename `RAGMemoryBackend` → `MemoryBackend` in `mcp_server/synapse_server.py`
- [ ] **Task 1.3**: Update exports in `core/__init__.py`
- [ ] **Task 1.4**: Update exports in `mcp_server/__init__.py`
- [ ] **Task 1.5**: Update import in `mcp_server/http_wrapper.py`
- [ ] **Task 1.6**: Rename `RAG_HEADER` → `CONTEXT_HEADER` in `core/prompt_builder.py`

**Verification:**
- [ ] Task 1.7: Test import `from core import Orchestrator`
- [ ] Task 1.8: Test import `from mcp_server import MemoryBackend`

---

## Phase 2: Class Reference Updates (8 tasks)

- [ ] **Task 2.1**: Update `tests/unit/rag/test_orchestrator.py` - all RAGOrchestrator references
- [ ] **Task 2.2**: Update `tests/integration/test_rag_pipeline.py` - class references
- [ ] **Task 2.3**: Update `tests/test_infrastructure.py` - import and usage
- [ ] **Task 2.4**: Update `tests/test_conversation_analyzer.py` - MemoryBackend references
- [ ] **Task 2.5**: Update `tests/unit/test_mcp_data_directory.py` - MemoryBackend references
- [ ] **Task 2.6**: Rename test classes: `TestRAGOrchestrator*` → `TestOrchestrator*`
- [ ] **Task 2.7**: Update any docstring references
- [ ] **Task 2.8**: Verify no RAGOrchestrator/RAGMemoryBackend references remain

---

## Phase 3: Environment Variables - Core (8 tasks)

- [ ] **Task 3.1**: Replace `RAG_DATA_DIR` → `SYNAPSE_DATA_DIR` in all Python files
- [ ] **Task 3.2**: Replace `RAG_CONFIG_PATH` → `SYNAPSE_CONFIG_PATH` in all Python files
- [ ] **Task 3.3**: Replace `RAG_ENV` → `SYNAPSE_ENV` in all Python files
- [ ] **Task 3.4**: Replace `RAG_TEST_MODE` → `SYNAPSE_TEST_MODE` in all Python files
- [ ] **Task 3.5**: Update `core/embedding.py` - RAG_TEST_MODE reference
- [ ] **Task 3.6**: Update `tests/conftest.py` - RAG_TEST_MODE
- [ ] **Task 3.7**: Update `tests/unit/test_embedding.py` - RAG_TEST_MODE
- [ ] **Task 3.8**: Update `synapse/cli/commands/start.py` - RAG_ENV, RAG_DATA_DIR, RAG_CONFIG_PATH

---

## Phase 4: Environment Variables - Upload (8 tasks)

- [ ] **Task 4.1**: Replace `RAG_REMOTE_UPLOAD_ENABLED` → `SYNAPSE_REMOTE_UPLOAD_ENABLED`
- [ ] **Task 4.2**: Replace `RAG_UPLOAD_DIR` → `SYNAPSE_UPLOAD_DIR`
- [ ] **Task 4.3**: Replace `RAG_UPLOAD_MAX_AGE` → `SYNAPSE_UPLOAD_MAX_AGE`
- [ ] **Task 4.4**: Replace `RAG_UPLOAD_MAX_SIZE` → `SYNAPSE_UPLOAD_MAX_SIZE`
- [ ] **Task 4.5**: Update `mcp_server/synapse_server.py` - 7 env var references
- [ ] **Task 4.6**: Update `mcp_server/project_manager.py` - RAG_DATA_DIR, RAG_CONFIG_PATH
- [ ] **Task 4.7**: Update `mcp_server/metrics.py` - RAG_DATA_DIR
- [ ] **Task 4.8**: Verify no RAG_* env vars remain in Python files

---

## Phase 5: Documentation Updates (10 tasks)

- [ ] **Task 5.1**: Update `README.md` - all env var references
- [ ] **Task 5.2**: Update `AGENTS.md` - class and env var references
- [ ] **Task 5.3**: Update `CHANGELOG.md` - document breaking changes
- [ ] **Task 5.4**: Update all spec documents in `docs/specs/`
- [ ] **Task 5.5**: Update VitePress docs in `docs/app/md/`
- [ ] **Task 5.6**: Update Starlight docs in `docs/content/docs/`
- [ ] **Task 5.7**: Update archive documents (if needed)
- [ ] **Task 5.8**: Update development guides
- [ ] **Task 5.9**: Update API reference docs
- [ ] **Task 5.10**: Verify no RAG references in documentation

---

## Phase 6: Configuration Files (5 tasks)

- [ ] **Task 6.1**: Update `docker-compose.yml` - all RAG_* env vars
- [ ] **Task 6.2**: Update `docker-compose.override.yml` - if exists
- [ ] **Task 6.3**: Update `pyproject.toml` - any RAG references
- [ ] **Task 6.4**: Update `configs/*.json` - if any hardcoded
- [ ] **Task 6.5**: Update any shell scripts in `scripts/`

---

## Phase 7: Migration Guide & Version (3 tasks)

- [ ] **Task 7.1**: Create `MIGRATION_v2.0.md` with comprehensive guide
- [ ] **Task 7.2**: Update `CHANGELOG.md` with v2.0.0 breaking changes
- [ ] **Task 7.3**: Update version in `pyproject.toml` to 2.0.0

---

## Phase 8: Testing & Validation (5 tasks)

- [ ] **Task 8.1**: Verify no `RAGOrchestrator` references: `grep -r "RAGOrchestrator" --include="*.py" .`
- [ ] **Task 8.2**: Verify no `RAGMemoryBackend` references: `grep -r "RAGMemoryBackend" --include="*.py" .`
- [ ] **Task 8.3**: Verify no `RAG_` env vars: `grep -r "RAG_" --include="*.py" . | grep -v "RAG_HEADER"`
- [ ] **Task 8.4**: Run test suite: `pytest tests/ -v`
- [ ] **Task 8.5**: Test imports work: `python -c "from core import Orchestrator; from mcp_server import MemoryBackend"`

---

## Phase 9: Finalization (2 tasks)

- [ ] **Task 9.1**: Update `docs/specs/index.md` - mark Feature 019 as complete
- [ ] **Task 9.2**: Create comprehensive commit message and push

---

## Progress Summary

| Phase | Tasks | Complete | Status |
|-------|-------|----------|--------|
| Phase 1: Class Renames | 8 | 0 | ⏳ Pending |
| Phase 2: Class References | 8 | 0 | ⏳ Pending |
| Phase 3: Env Vars - Core | 8 | 0 | ⏳ Pending |
| Phase 4: Env Vars - Upload | 8 | 0 | ⏳ Pending |
| Phase 5: Documentation | 10 | 0 | ⏳ Pending |
| Phase 6: Config Files | 5 | 0 | ⏳ Pending |
| Phase 7: Migration Guide | 3 | 0 | ⏳ Pending |
| Phase 8: Testing | 5 | 0 | ⏳ Pending |
| Phase 9: Finalization | 2 | 0 | ⏳ Pending |
| **Total** | **57** | **0** | **0%** |

---

**Notes:**
- Each task should be verified after completion
- Run grep commands to verify no old references remain
- This is a MAJOR breaking change (v2.0.0)
- Coordinate with team before merging
