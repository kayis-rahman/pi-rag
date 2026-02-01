# Ingestion Persistence Fix - Requirements

**Feature ID**: 015-ingestion-persistence
**Status**: [In Progress]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026

---

## Overview

Fix BUG-INGEST-01: Ingestion completes but data is not persisted to semantic memory.

**Problem**: Running `synapse ingest` or `bulk_ingest.py` reports success but `sy.list_sources` returns 0 sources.

**Root Cause**: Storage backend not committing data to disk.

**Impact**: Semantic memory is always empty, making the RAG system non-functional for document search.

---

## User Stories

### US-1: Verify Ingested Data Persists
**As a** user,
**I want** ingested documents to be searchable,
**So that** the RAG system actually works.

**Acceptance Criteria:**
- [ ] After `synapse ingest .`, `sy.list_sources` returns > 0
- [ ] After `sy.search`, results include ingested content
- [ ] Data persists across server restarts
- [ ] No silent failures during ingestion

### US-2: Clear Error Messages
**As a** user,
**I want** to know if ingestion fails,
**So that** I can fix the issue.

**Acceptance Criteria:**
- [ ] Errors are logged with clear messages
- [ ] Success includes summary of what was ingested
- [ ] No silent failures

---

## Functional Requirements

### FR-1: Persistence Verification
- [ ] FR-1.1 Verify bulk_ingest.py writes data to semantic_index directory
- [ ] FR-1.2 Verify data survives server restart
- [ ] FR-1.3 Add post-ingestion verification step
- [ ] FR-1.4 Log verification results

### FR-2: Storage Backend Fix
- [ ] FR-2.1 Identify why data is not being committed
- [ ] FR-2.2 Fix storage backend commit logic
- [ ] FR-2.3 Add transaction support for atomic writes
- [ ] FR-2.4 Add error handling for write failures

### FR-3: Error Handling
- [ ] FR-3.1 Log errors during ingestion
- [ ] FR-3.2 Provide success summary with counts
- [ ] FR-3.3 Handle permission errors
- [ ] FR-3.4 Handle disk full scenarios

### FR-4: Testing
- [ ] FR-4.1 Create test for persistence
- [ ] FR-4.2 Create test for error handling
- [ ] FR-4.3 Create integration test with MCP tools
- [ ] FR-4.4 All tests pass

---

## Files to Modify

| File | Change | Priority |
|------|--------|----------|
| `scripts/bulk_ingest.py` | Add persistence verification | CRITICAL |
| `rag/semantic_store.py` | Fix commit logic | CRITICAL |
| `rag/vectorstore.py` | Verify write operations | HIGH |
| `tests/test_ingestion_persistence.py` | NEW - Persistence tests | REQUIRED |

---

## Success Criteria

### Must Have
- [ ] `synapse ingest docs/specs` creates searchable data
- [ ] `sy.list_sources` returns correct count
- [ ] `sy.search` returns results from ingested content
- [ ] Data persists after server restart
- [ ] Clear logs for success/failure

### Should Have
- [ ] Error recovery for partial failures
- [ ] Performance metrics for ingestion
- [ ] Progress indicators during ingestion

---

## Timeline

| Phase | Duration |
|-------|----------|
| 1. Diagnosis | 1-2 hours |
| 2. Fix | 2-3 hours |
| 3. Testing | 1-2 hours |
| 4. Validation | 1 hour |
| **Total** | **5-8 hours** |

---

**Created**: February 1, 2026
**Status**: Ready for implementation
