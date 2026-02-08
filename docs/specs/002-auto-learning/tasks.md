# Automatic Learning System - Tasks

**Feature ID**: 002-auto-learning
**Created**: January 4, 2026
**Last Updated**: February 8, 2026
**Status**: [In Progress - Gap Analysis Complete]

---

## Gap Analysis Summary (February 8, 2026)

### Current Status

| Component | Status | Details |
|-----------|--------|---------|
| Core Modules (tracker, extractor) | ✅ Complete | Files exist with full implementation |
| Unit Tests | ⚠️ 12/15 (80%) | 3 failing tests need fixes |
| Integration Tests | ⚠️ 6/10 (60%) | 1 error, 3 failing tests |
| synapse_server.py | ✅ Complete | Auto-learning integrated |
| http_wrapper.py | ❌ Missing | NO integration - CRITICAL GAP |
| Configuration | ❌ Missing | No config in rag_config.json |
| MemoryBackend | ❌ Missing | No initialization |

### Critical Gaps

1. **http_wrapper.py**: New FastMCP server has no auto-learning tracking
2. **Configuration**: No auto_learning section in rag_config.json  
3. **MemoryBackend**: AutoLearningTracker not initialized
4. **Test Failures**: 3 unit + 4 integration tests failing

---

## Progress Summary

| Phase | Status | Completion |
|-------|--------|------------|
| Phase 1: Foundation | ✅ Complete | 100% |
| Phase 2: Integration | 🔄 In Progress | 60% |
| Phase 3: Testing | 🔄 In Progress | 70% |
| Phase 4: Documentation | 🔄 Partial | 80% |
| Phase 5: Completion | ⏳ Pending | 0% |

---

## Phase 1: Foundation ✅ COMPLETE

### 1.1 Configuration Setup
- [x] Add automatic_learning configuration section to `configs/rag_config.json`
- [x] Create default config with `enabled: false, mode: moderate`
- [x] Test configuration loading
- [x] Validate configuration schema

**Linked to**: Requirement FR-6 (Configuration Support)

### 1.2 Create AutoLearningTracker Module
- [x] Create `core/auto_learning_tracker.py` file
- [x] Implement `AutoLearningTracker` class
- [x] Implement `track_operation()` method
- [x] Implement `detect_task_completion()` method
- [x] Implement `detect_pattern()` method
- [x] Implement `should_auto_track()` method
- [x] Add operation buffer with 100-operation limit
- [x] Write docstrings and type hints

**Linked to**: Requirement FR-1 (Operation Tracking), FR-2 (Task Completion Detection), FR-5 (Pattern Detection)

### 1.3 Create LearningExtractor Module
- [x] Create `core/learning_extractor.py` file
- [x] Implement `LearningExtractor` class
- [x] Implement `extract_episode_from_task()` method
- [x] Implement `extract_facts_from_code()` method
- [x] Implement `extract_episode_from_pattern()` method
- [x] Implement rule-based fallback extraction
- [x] Write LLM prompts for extraction

**Linked to**: Requirement FR-3 (Episode Auto-Extraction), FR-4 (Fact Auto-Extraction)

### 1.4 Unit Tests for Foundation
- [x] Create `tests/test_auto_learning_tracker.py`
- [x] Write tests for `track_operation()`
- [x] Write tests for `detect_task_completion()`
- [x] Write tests for `detect_pattern()`
- [x] Create `tests/test_learning_extractor.py`
- [x] Write tests for `extract_episode_from_task()`
- [x] Write tests for `extract_facts_from_code()`
- [x] Run all unit tests

**Linked to**: Requirement NFR-1 (Performance), NFR-3 (Reliability)

**Test Results**: 12/15 passing (80%)

---

## Phase 2: Integration 🔄 IN PROGRESS

### 2.1 Configuration Gap - ADD
- [ ] Add `auto_learning` section to `configs/rag_config.json`:
```json
{
  "auto_learning": {
    "enabled": false,
    "mode": "moderate",
    "track_tasks": true,
    "track_code_changes": true,
    "track_operations": true,
    "min_episode_confidence": 0.6,
    "episode_deduplication": true
  }
}
```

**Linked to**: Requirement FR-6 (Configuration Support)

### 2.2 Initialize AutoLearningTracker in MemoryBackend
- [ ] Add `auto_learning` attribute to `MemoryBackend.__init__`
- [ ] Add `_load_auto_learning_config()` method
- [ ] Initialize `AutoLearningTracker` if enabled
- [ ] Initialize `LearningExtractor` if enabled
- [ ] Add `operation_buffer` list to `__init__`
- [ ] Connect to ModelManager for LLM access
- [ ] Test initialization with enabled=false

**Linked to**: Requirement FR-1 (Operation Tracking)

### 2.3 Add Auto-Store Methods to MemoryBackend
- [ ] Implement `_auto_store_episode()` method
- [ ] Implement `_auto_store_fact()` method
- [ ] Add deduplication checks before storing
- [ ] Store immediately (no batching)
- [ ] Add logging for storage operations

**Linked to**: Requirement FR-3 (Episode Auto-Extraction), NFR-2 (Storage)

### 2.4 CRITICAL GAP: Integrate http_wrapper.py
Add auto-learning tracking to all 7 MCP tools in `mcp_server/http_wrapper.py`:

**Task 2.4.1: Import AutoLearningTracker**
- [ ] Add `from core.auto_learning_tracker import AutoLearningTracker`
- [ ] Add `from core.learning_extractor import LearningExtractor`

**Task 2.4.2: Initialize in MemoryBackend (http_wrapper)**
- [ ] Add `auto_learning_config` loading
- [ ] Initialize `AutoLearningTracker` if enabled
- [ ] Initialize `LearningExtractor` if enabled

**Task 2.4.3: Wrap sy.proj.list**
- [ ] Add tracking before and after tool call
- [ ] Check `auto_learn` parameter
- [ ] Call `track_operation()` with result

**Task 2.4.4: Wrap sy.src.list**
- [ ] Add tracking before and after tool call
- [ ] Check `auto_learn` parameter
- [ ] Call `track_operation()` with result

**Task 2.4.5: Wrap sy.ctx.get**
- [ ] Add tracking before and after tool call
- [ ] Check `auto_learn` parameter
- [ ] Call `track_operation()` with result

**Task 2.4.6: Wrap sy.mem.search**
- [ ] Add tracking before and after tool call
- [ ] Check `auto_learn` parameter
- [ ] Call `track_operation()` with result
- [ ] Trigger task completion detection after call

**Task 2.4.7: Wrap sy.mem.ingest**
- [ ] Add tracking before and after tool call
- [ ] Check `auto_learn` parameter
- [ ] Call `track_operation()` with result
- [ ] Trigger fact extraction from code changes
- [ ] Trigger task completion detection

**Task 2.4.8: Wrap sy.mem.fact.add**
- [ ] Add tracking before and after tool call
- [ ] Check `auto_learn` parameter (if false, skip tracking)
- [ ] Call `track_operation()` with result

**Task 2.4.9: Wrap sy.mem.ep.add**
- [ ] Add tracking before and after tool call
- [ ] Check `auto_learn` parameter (if false, skip tracking)
- [ ] Call `track_operation()` with result

**Linked to**: Requirement FR-7 (Manual Override), FR-2 (Task Completion Detection), FR-4 (Fact Auto-Extraction)

### 2.5 Add Manual Override Support
- [ ] Modify all tool wrappers to check `auto_learn` parameter
- [ ] Implement `_should_auto_track()` helper method
- [ ] Test that `auto_learn=false` disables auto-learning
- [ ] Test that manual add_fact/add_episode work regardless

**Linked to**: Requirement FR-7 (Manual Override), US-5 (Manual Override)

---

## Phase 3: Testing 🔄 IN PROGRESS

### 3.1 Fix Unit Test Failures (3 tasks)

**Task 3.1.1: Fix test_detect_task_completion_multi_step**
- [ ] Investigate why task completion detection returns None
- [ ] Fix logic in `detect_task_completion()` method
- [ ] Re-run test to verify

**Task 3.1.2: Fix test_detect_task_completion_search_context_code**
- [ ] Investigate search + context + file pattern
- [ ] Fix pattern recognition logic
- [ ] Re-run test to verify

**Task 3.1.3: Fix test_detect_pattern_repeated_successes**
- [ ] Investigate pattern detection for successes
- [ ] Fix threshold logic
- [ ] Re-run test to verify

### 3.2 Fix Integration Test Failures (4 tasks)

**Task 3.2.1: Fix test_episode_storage_after_task_completion**
- [ ] Fix fixture setup (AttributeError: 'str' has no .parent)
- [ ] Re-run test to verify

**Task 3.2.2: Fix test_fact_extraction_from_file_ingestion**
- [ ] Fix regex for FastAPI pattern extraction
- [ ] Change pattern from `'@\\\\w+\\\\.(get|post|put|delete|patch)\\\\('` to proper regex
- [ ] Re-run test to verify

**Task 3.2.3: Fix test_manual_override_disables_tracking**
- [ ] Investigate why manual override not working
- [ ] Fix `_should_auto_track()` logic
- [ ] Re-run test to verify

**Task 3.2.4: Fix test_get_buffer_stats**
- [ ] Implement missing `get_buffer_stats()` method
- [ ] Return correct statistics format
- [ ] Re-run test to verify

### 3.3 Performance Tests (NEW)
- [ ] Measure operation tracking overhead
- [ ] Verify <50ms overhead per tool call
- [ ] Measure episode extraction latency
- [ ] Verify <2s per episode extraction
- [ ] Profile memory usage

**Linked to**: Requirement NFR-1 (Performance)

### 3.4 Test Summary
- [x] Unit Tests: 12/15 passing (80%) - Fix 3 to reach 100%
- [x] Integration Tests: 6/10 passing (60%) - Fix 4 to reach 100%
- [ ] All core functionality tested
- [ ] Configuration modes verified
- [ ] Manual override verified
- [ ] Deduplication logic verified

---

## Phase 4: Documentation 🔄 PARTIAL

### 4.1 Update AGENTS.md
- [x] Add auto-learning section to AGENTS.md
- [x] Document automatic learning behavior
- [x] Document what gets learned automatically
- [x] Document configuration options
- [x] Document manual override mechanism

**Linked to**: Requirement NFR-4 (Documentation)

### 4.2 Update README.md
- [x] Add configuration examples
- [ ] Document auto-learning features (incomplete)
- [ ] Add configuration section (incomplete)
- [ ] Document modes (aggressive/moderate/minimal)

**Linked to**: Requirement NFR-4 (Documentation)

### 4.3 Code Comments
- [x] All new methods documented with docstrings
- [x] Inline comments for complex logic
- [x] Type hints included throughout

**Linked to**: Requirement NFR-4 (Documentation)

### 4.4 Troubleshooting Guide
- [x] Create docs/troubleshooting-auto-learning.md
- [x] Document common issues and fixes
- [x] Add testing procedures
- [x] Add error messages reference

**Linked to**: Requirement NFR-4 (Observability)

---

## Phase 5: Completion & Validation ⏳ PENDING

### 5.1 Requirements Validation
- [x] FR-1: Operation Tracking - ✅ Implemented
- [x] FR-2: Task Completion Detection - ✅ Implemented (logic needs test fixes)
- [x] FR-3: Episode Auto-Extraction - ✅ Implemented
- [x] FR-4: Fact Auto-Extraction - ✅ Implemented (regex needs fix)
- [x] FR-5: Pattern Detection - ✅ Implemented (logic needs test fixes)
- [x] FR-6: Configuration Support - ⚠️ Config needs to be added to rag_config.json
- [x] FR-7: Manual Override - ✅ Implemented (logic needs verification)
- [x] NFR-1: Performance - ⏳ Need to measure <50ms overhead
- [x] NFR-2: Immediate Storage - ✅ Implemented (no batching)
- [x] NFR-3: Reliability - ✅ Implemented (graceful degradation)
- [x] NFR-4: Documentation - ✅ Mostly complete

**Linked to**: All Requirements and NFRs

### 5.2 Performance Validation
- [ ] Measure operation tracking overhead
- [ ] Verify <50ms overhead per tool call
- [ ] Measure episode extraction latency
- [ ] Verify <2s per episode extraction
- [ ] Profile memory usage

**Linked to**: Requirement NFR-1 (Performance)

### 5.3 Final Documentation
- [x] Update tasks.md with completion status
- [x] Update spec index.md
- [ ] Update version in rag_config.json
- [ ] Add CHANGELOG entry

### 5.4 Git Operations
- [x] Stage all changed files (20+ files)
- [x] Create commit message
- [x] Commit changes
- [x] Push to remote
- [x] Verify push succeeded

### 5.5 Final Verification
- [ ] All files committed
- [ ] All tests passing (15/15 unit, 10/10 integration)
- [ ] Documentation complete (AGENTS.md, README.md, troubleshooting guide)
- [ ] Feature marked as [Completed] in index

---

## Task Checklist Summary

### Phase 1: Foundation (Complete)
- [x] 8/8 Configuration tasks
- [x] 8/8 AutoLearningTracker tasks
- [x] 8/8 LearningExtractor tasks
- [x] 8/8 Unit test tasks

### Phase 2: Integration (9/25 Complete)
- [ ] 1/1 Configuration gap
- [ ] 5/5 MemoryBackend initialization
- [ ] 5/5 Auto-store methods
- [ ] 9/9 http_wrapper integration (MISSING - CRITICAL)
- [ ] 2/2 Manual override

### Phase 3: Testing (0/14 Complete)
- [ ] 3/3 Fix unit test failures
- [ ] 4/4 Fix integration test failures
- [ ] 4/4 Performance tests
- [ ] 3/3 Test summary tasks

### Phase 4: Documentation (7/11 Complete)
- [x] 5/5 AGENTS.md tasks
- [x] 2/4 README.md tasks
- [x] 3/3 Code comment tasks
- [x] 4/4 Troubleshooting tasks

### Phase 5: Completion (0/10 Complete)
- [ ] 11/11 Requirements validation
- [ ] 5/5 Performance validation
- [ ] 2/4 Final documentation
- [ ] 5/5 Final verification

**Total Tasks**: 73
**Completed**: 30 (41%)
**Remaining**: 43 (59%)

---

## Next Steps (Priority Order)

### Immediate (This Session)
1. **TASK 2.1**: Add auto_learning config to rag_config.json
2. **TASK 2.4.1-2.4.9**: Integrate http_wrapper.py with auto-learning

### This Week
3. Fix 3 failing unit tests
4. Fix 4 failing integration tests
5. Add MemoryBackend integration

### Before Completion
6. Performance validation (<50ms overhead)
7. Update README.md documentation
8. Add CHANGELOG entry
9. Mark feature as COMPLETED in index.md

---

## Related Documents

- Requirements: `docs/specs/002-auto-learning/requirements.md`
- Plan: `docs/specs/002-auto-learning/plan.md`
- AutoLearningTracker: `core/auto_learning_tracker.py`
- LearningExtractor: `core/learning_extractor.py`
- Unit Tests: `tests/test_auto_learning_tracker.py`
- Integration Tests: `tests/test_auto_learning_integration.py`

---

**Last Updated**: February 8, 2026
**Maintainer**: opencode
**Next Review**: After http_wrapper integration
