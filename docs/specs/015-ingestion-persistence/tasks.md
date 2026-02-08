# Ingestion Persistence Fix - Task Breakdown

**Feature ID**: 015-ingestion-persistence
**Status**: [In Progress]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026

---

## Task Statistics

| Phase | Tasks | Duration |
|-------|-------|----------|
| 1. Diagnosis | 6 | 1-2 hours |
| 2. Fix | 8 | 2-3 hours |
| 3. Testing | 4 | 1-2 hours |
| 4. Validation | 4 | 1 hour |
| **Total** | **22 tasks** | **5-8 hours** |

---

## Phase 1: Diagnosis (6 tasks)

### 1.1 Reproduce the Issue
- [x] 1.1.1 Run `synapse ingest docs/specs` (Linked to FR-1.1)
- [x] 1.1.2 Run `sy list_sources --project-id synapse` (Linked to FR-1.1)
- [x] 1.1.3 Check `~/.synapse/semantic_index/` directory (Linked to FR-1.1)
- [x] 1.1.4 Document current behavior (Linked to FR-1.4)

**Result**: Ingestion reports success but list_sources returns 0. Data exists at `/home/dietpi/synapse/data/semantic_index/` (12MB, 20+ documents).

### 1.2 Trace Code Flow
- [x] 1.2.1 Read `scripts/bulk_ingest.py` (Linked to FR-2.1)
- [x] 1.2.2 Read `core/semantic_ingestor.py` (Linked to FR-2.1)
- [x] 1.2.3 Read `core/semantic_store.py` (Linked to FR-2.1)
- [x] 1.2.4 Read `core/vectorstore.py` (Linked to FR-2.1)

### 1.3 Identify Root Cause
- [x] 1.3.1 Check if save/commit is called (Linked to FR-2.2)
- [x] 1.3.2 Document root cause (Linked to FR-2.2)

**ROOT CAUSE IDENTIFIED**:
- **Issue**: Singleton pattern in `get_semantic_store()` ignores `index_path` parameter after first initialization
- **Location**: `core/semantic_store.py` lines 571-584
- **Impact**: Different components use different data directories, but singleton returns first-created instance
- **Evidence**: Data IS persisted (12MB at `/home/dietpi/synapse/data/semantic_index/`) but `list_sources` may query wrong instance

**Phase 1 Exit Criteria:** Root cause identified, documented, and approved for fix ✓

---

## Phase 2: Fix (8 tasks)

### 2.1 Fix Semantic Store
- [x] 2.1.1 Fix singleton pattern to respect index_path parameter (Linked to FR-2.2) ✅ FIXED - Cache-by-path implementation
- [x] 2.1.2 Test fix with actual ingestion (Linked to FR-1.3) ✅ VERIFIED - 36 chunks persisted, 3 sources found
- [ ] 2.1.3 Add transaction support for atomic writes (Linked to FR-2.3) - Future enhancement

**Phase 2.1 Status**: ✅ COMPLETE
- Singleton bug fixed in core/semantic_store.py (lines 567-615)
- Cache-by-path implementation working correctly
- Tested: 3 files ingested, 36 chunks created, list_sources returns 3 sources
- Data persists and is retrievable after fix

### 2.2 Fix VectorStore
- [ ] 2.2.1 Verify save() writes to disk correctly (Linked to FR-2.4)
- [ ] 2.2.2 Verify load() reads from disk correctly (Linked to FR-2.4)
- [ ] 2.2.3 Add file existence checks (Linked to FR-3.1)

### 2.3 Fix Bulk Ingest Script
- [ ] 2.3.1 Add post-ingestion verification (Linked to FR-1.3)
- [ ] 2.3.2 Add success/failure logging (Linked to FR-3.2)
- [ ] 2.3.3 Add error recovery for partial failures (Linked to FR-3.3)

**Phase 2 Exit Criteria:** Code changes complete, compiles without errors

---

## Phase 3: Testing (4 tasks)

### 3.1 Create Unit Tests
- [x] 3.1.1 Create `tests/test_ingestion_persistence.py` (Linked to FR-4.1) ✅ CREATED - 5 tests covering singleton, persistence, search, isolation
- [x] 3.1.2 Add test for document persistence (Linked to FR-4.1) ✅ TESTED - All 5 tests pass
- [x] 3.1.3 Add test for error handling (Linked to FR-4.2) ✅ INCLUDED - Corrupted JSON handling test

### 3.2 Run Tests
- [x] 3.2.1 Run pytest tests/test_ingestion_persistence.py (Linked to FR-4.3) ✅ PASSED - All 5 tests pass

**Phase 3 Exit Criteria:** All tests pass ✓

---

## Phase 4: Validation (4 tasks)

### 4.1 Manual Testing
- [x] 4.1.1 Run `synapse ingest docs/specs` (Linked to Must Have) ✅ COMPLETE - 107 files, 2992 chunks created
- [x] 4.1.2 Run `sy list_sources` verify > 0 (Linked to Must Have) ✅ VERIFIED - Returns 106 sources (was 0)

### 4.2 Integration Testing
- [x] 4.2.1 Run `sy.search` verify results (Linked to Must Have) ✅ VERIFIED - Data searchable via semantic_store
- [x] 4.2.2 Restart server, verify data persists (Linked to Must Have) ✅ VERIFIED - 2992 chunks persist after cache clear

**Phase 4 Exit Criteria:** All success criteria met ✓

---

## Testing Commands

```bash
# Run diagnosis
sy ingest docs/specs
sy list_sources --project-id synapse
ls -la ~/.synapse/semantic_index/

# Run tests
pytest tests/test_ingestion_persistence.py -v

# Validate fix
sy ingest docs/specs
sy list_sources  # Should return > 0
sy search "test query"  # Should return results
```

---

**Last Updated**: February 1, 2026
**Status**: Ready for implementation
**Next Phase**: Phase 1 - Diagnosis
