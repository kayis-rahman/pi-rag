# Fix Validation Blockers - Task Breakdown

**Feature ID**: 011-fix-validation-blockers  
**Status**: [In Progress]  
**Created**: January 31, 2026  
**Last Updated**: January 31, 2026

---

## Task Statistics

| Phase | Tasks | Duration |
|-------|-------|----------|
| Phase 1: Fix MCP Data Directory | 8 | 2-3 hours |
| Phase 2: Fix Server Management | 12 | 2-3 hours |
| Phase 3: Write Pytest Tests | 16 | 2-3 hours |
| Phase 4: OpenCode Testing | 8 | 1-2 hours |
| Phase 5: Validation Re-run | 8 | 2-3 hours |
| **Total** | **52 tasks** | **9-12 hours** |

---

## Phase 1: Fix MCP Data Directory (8 tasks)

### 1.1: Analyze Current Code
- [ ] 1.1.1 Read `mcp_server/rag_server.py` lines 110-130 (Linked to FR-1)
- [ ] 1.1.2 Identify `_get_data_dir()` method (Linked to FR-1)
- [ ] 1.1.3 Document current hardcoded path (Linked to FR-1)
- [ ] 1.1.4 Read `mcp_server/project_manager.py` registry logic (Linked to FR-1)

### 1.2: Implement OS-Aware Data Directory
- [x] 1.2.1 Modify `_get_data_dir()` in `rag_server.py` (Linked to FR-1.1)
  - Add environment variable check (RAG_DATA_DIR)
- [x] 1.2.2 Add config file parsing (Linked to FR-1.2)
- [x] 1.2.3 Add OS detection (Darwin/Linux/Windows) (Linked to FR-1.3-1.5)
- [x] 1.2.4 Implement Mac logic: `~/.synapse/data` (Linked to FR-1.3)
- [x] 1.2.5 Implement Linux logic: writable check + fallback (Linked to FR-1.4)
- [x] 1.2.6 Implement Windows logic: user home (Linked to FR-1.5)
- [x] 1.2.7 Add logging for data directory selection (Linked to FR-1.6)

### 1.3: Update Related Files
- [x] 1.3.1 Update `project_manager.py` to use `_get_data_dir()` (Linked to FR-1)
- [ ] 1.3.2 Update `scripts/bulk_ingest.py` if needed (Linked to FR-1)

**Phase 1 Exit Criteria:** MCP data directory OS-aware, code compiles

---

## Phase 2: Fix Server Management (12 tasks)

### 2.1: Fix Start Command
- [x] 2.1.1 Read `synapse/cli/commands/start.py` (Linked to FR-2)
- [x] 2.1.2 Add health endpoint check before start (Linked to FR-2.1)
- [x] 2.1.3 Add process detection (look for mcp_server) (Linked to FR-2.2)
- [x] 2.1.4 Handle "already running" case gracefully (Linked to FR-2.1)
- [x] 2.1.5 Add requests import (Linked to FR-2)

### 2.2: Fix Stop Command
- [x] 2.2.1 Read `synapse/cli/commands/stop.py` (Linked to FR-2)
- [x] 2.2.2 Improve process detection (by cmdline, not port) (Linked to FR-2.2)
- [x] 2.2.3 Implement SIGTERM → wait → SIGKILL logic (Linked to FR-2.3)
- [x] 2.2.4 Add health endpoint verification (Linked to FR-2.4)
- [x] 2.2.5 Improve error messages (Linked to FR-2)

### 2.3: Fix Status Command
- [x] 2.3.1 Read `synapse/cli/commands/status.py` (Linked to FR-2)
- [x] 2.3.2 Primary check: health endpoint (Linked to FR-2.5)
- [x] 2.3.3 Fallback: process list (Linked to FR-2.5)
- [x] 2.3.4 Show accurate state (running/stopped) (Linked to FR-2.6)
- [x] 2.3.5 Add verbose mode for detailed info (Linked to FR-2)
- [x] 2.3.6 Fix main.py status implementation (Linked to FR-2)

**Phase 2 Exit Criteria:** All 3 server commands work correctly

---

## Phase 3: Write Pytest Tests (16 tasks)

### 3.1: Create Test Files
- [x] 3.1.1 Create `tests/unit/test_mcp_data_directory.py` (Linked to FR-3)
- [x] 3.1.2 Create `tests/unit/test_server_management.py` (Linked to FR-3)
- [ ] 3.1.3 Add test fixtures directory `tests/fixtures/` (Linked to FR-3)

### 3.2: Data Directory Tests
- [ ] 3.2.1 Test Mac data directory (mock Darwin) (Linked to FR-3.1)
- [ ] 3.2.2 Test Linux data directory writable (mock Linux, writable) (Linked to FR-3.1)
- [ ] 3.2.3 Test Linux data directory not writable (mock Linux, not writable) (Linked to FR-3.1)
- [ ] 3.2.4 Test Windows data directory (mock Windows) (Linked to FR-3.1)
- [ ] 3.2.5 Test environment variable override (Linked to FR-3.1)
- [ ] 3.2.6 Test config file override (Linked to FR-3.1)
- [ ] 3.2.7 Test config with index_path (Linked to FR-3.1)

### 3.3: Server Management Tests
- [ ] 3.3.1 Test start when already running (mock health check) (Linked to FR-3.2)
- [ ] 3.3.2 Test start when not running (Linked to FR-3.2)
- [ ] 3.3.3 Test stop finds process (Linked to FR-3.3)
- [ ] 3.3.4 Test stop sends SIGTERM (Linked to FR-3.3)
- [ ] 3.3.5 Test stop sends SIGKILL if needed (Linked to FR-3.3)
- [ ] 3.3.6 Test status running (mock health check success) (Linked to FR-3.4)
- [ ] 3.3.7 Test status stopped (mock health check failure) (Linked to FR-3.4)

### 3.4: Run Tests
- [ ] 3.4.1 Run data directory tests: `pytest tests/unit/test_mcp_data_directory.py -v` (Linked to FR-3)
- [ ] 3.4.2 Run server management tests: `pytest tests/unit/test_server_management.py -v` (Linked to FR-3)
- [ ] 3.4.3 Run all unit tests with coverage (Linked to FR-3)
- [ ] 3.4.4 Fix any failing tests (Linked to FR-3)

**Phase 3 Exit Criteria:** All pytest tests pass, 90%+ coverage

---

## Phase 4: OpenCode Testing (8 tasks)

### 4.1: Test MCP Data Directory Fix
- [x] 4.1.1 Restart MCP server (Linked to US-1)
- [x] 4.1.2 Test `/rag list_projects` (Linked to US-1)
- [x] 4.1.3 Test `/rag list_sources` (Linked to US-1)
- [x] 4.1.4 Test `/rag search` (Linked to US-1)

### 4.2: Test Server Management Fix
- [x] 4.2.1 Test `synapse start` (Linked to US-2)
- [x] 4.2.2 Test `synapse status` (Linked to US-2)
- [x] 4.2.3 Test `synapse stop` (Linked to US-2)
- [x] 4.2.4 Verify no zombie processes (Linked to US-2)

### 4.3: Test MCP Memory Operations
- [x] 4.3.1 Test `/rag add_fact` (Linked to US-1)
- [x] 4.3.2 Test `/rag add_episode` (Linked to US-1)
- [ ] 4.3.3 Test `/rag analyze_conversation` (Linked to US-1)
- [x] 4.3.4 Test `/rag get_context` (Linked to US-1)

**Phase 4 Exit Criteria:** All 8 OpenCode tests pass

---

## Phase 5: Validation Re-run (8 tasks)

### 5.1: Re-run Phase 2 (Server Commands)
- [ ] 5.1.1 Re-test `synapse setup` (Linked to original validation)
- [ ] 5.1.2 Re-test `synapse config` (Linked to original validation)
- [ ] 5.1.3 Re-test `synapse models list` (Linked to original validation)
- [ ] 5.1.4 Re-test `synapse start` (should work now) (Linked to original validation)
- [ ] 5.1.5 Re-test `synapse status` (should show correct state) (Linked to original validation)
- [ ] 5.1.6 Re-test `synapse stop` (should stop server) (Linked to original validation)

### 5.2: Re-run Phase 5 (MCP Tools)
- [ ] 5.2.1 Re-test all 8 MCP tools (should all work now) (Linked to original validation)
- [ ] 5.2.2 Document results (Linked to original validation)

### 5.3: Completion
- [ ] 5.3.1 Update `docs/specs/index.md` with completion (Linked to SDD Protocol)
- [ ] 5.3.2 Create completion summary (Linked to SDD Protocol)

**Phase 5 Exit Criteria:** All validation phases pass, documentation complete

---

## Success Criteria Checklist

### Must Have (Go Live)
- [ ] BUG-010 fixed: All MCP tools work on Mac
- [ ] BUG-003 fixed: `stop` stops server
- [ ] BUG-001 fixed: `start` starts server
- [ ] BUG-002 fixed: `status` shows correct state
- [ ] Phase 4: All 8 OpenCode tests pass
- [ ] Phase 3: All pytest tests pass
- [ ] No Linux regression

### Should Have (Quality)
- [ ] 90%+ pytest coverage for modified code
- [ ] Documentation comments updated
- [ ] Error messages improved

### Nice to Have (Polish)
- [ ] Progress output during server start
- [ ] Colored output for status
- [ ] Configuration validation

---

## Testing Commands Reference

### Pytest Commands
```bash
# Run data directory tests
pytest tests/unit/test_mcp_data_directory.py -v

# Run server management tests
pytest tests/unit/test_server_management.py -v

# Run all unit tests with coverage
pytest tests/unit/ -v --cov=mcp_server --cov=synapse.cli.commands

# Run with detailed output
pytest tests/unit/ -vv --tb=short
```

### OpenCode Commands
```bash
# MCP Tool Tests
/rag list_projects
/rag list_sources project_id="synapse"
/rag search project_id="synapse" query="What is Synapse?" memory_type="all" top_k=5
/rag get_context project_id="synapse" context_type="all" query="CLI commands"
/rag add_fact project_id="synapse" fact_key="test_fix" fact_value="Testing MCP fix" category="validation"
/rag add_episode project_id="synapse" title="Fix Verification" content="Testing server management fixes" lesson_type="success"
/rag analyze_conversation project_id="synapse" user_message="Is it working?" agent_response="Yes, all tests pass" auto_store=true
```

### CLI Commands
```bash
# Server Management
synapse start
synapse status
synapse stop
synapse status --verbose
```

---

## Notes

**Constraint Reminder:**
- NO source files modified except those listed
- NO temporary files in project root
- NO hardcoded paths (use configuration)
- Test with mocks where possible

**Execution Order:**
1. Phase 1: MCP Data Directory (highest priority)
2. Phase 2: Server Management
3. Phase 3: Pytest Tests
4. Phase 4: OpenCode Testing
5. Phase 5: Validation Re-run

**Expected Issues:**
- Mocking platform.system() may require careful patching
- Process detection may vary across OS
- Health endpoint may take time to respond

**Workarounds:**
- Use longer timeouts in tests
- Add multiple fallback detection methods
- Document platform-specific behavior

---

**Last Updated**: January 31, 2026  
**Status**: Ready for implementation  
**Next Phase**: Phase 1 - Fix MCP Data Directory
