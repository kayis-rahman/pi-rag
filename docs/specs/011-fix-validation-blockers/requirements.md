# Fix Validation Blockers - Requirements

**Feature ID**: 011-fix-validation-blockers  
**Status**: [In Progress]  
**Created**: January 31, 2026  
**Last Updated**: January 31, 2026

---

## Overview

Fix the 4 critical bugs identified during fresh installation validation (010-fresh-install-validation) that are blocking full validation completion. Implement OS-aware data directory detection and proper server management.

**Testing Strategy:**
- OpenCode: Manual interactive testing via MCP tools
- Pytest: Automated regression prevention tests

---

## User Stories

### US-1: Fix MCP Data Directory (BUG-010)
**As a** Mac user,  
**I want** MCP server to use `~/.synapse/data`,  
**So that** all 8 MCP tools work correctly.

**Acceptance Criteria:**
- [ ] MCP server starts without permission errors
- [ ] `core.list_projects` returns project list
- [ ] `core.list_sources` returns source list
- [ ] `core.search` returns results
- [ ] `core.ingest_file` ingests files
- [ ] `core.add_fact` adds symbolic facts
- [ ] `core.add_episode` adds episodic lessons
- [ ] `core.analyze_conversation` extracts learning
- [ ] Linux users maintain `/opt/synapse/data` default (if writable)

### US-2: Fix Server Management (BUG-001, 002, 003)
**As a** user,  
**I want** `start/stop/status` commands to work correctly,  
**So that** I can manage the server properly.

**Acceptance Criteria:**
- [ ] `synapse start` starts server successfully
- [ ] `synapse stop` stops server completely
- [ ] `synapse status` shows accurate state (running/stopped)
- [ ] No zombie processes after stop
- [ ] Health endpoint reflects actual state

### US-3: Automated Testing
**As a** CI/CD system,  
**I want** pytest tests for all fixes,  
**So that** bugs don't reoccur.

**Acceptance Criteria:**
- [ ] Pytest tests for MCP data directory detection
- [ ] Pytest tests for server management
- [ ] Pytest tests pass in CI/CD
- [ ] No regression for Linux users

---

## Functional Requirements

### FR-1: MCP Data Directory (CRITICAL)
The MCP server must:
- [ ] FR-1.1 Use environment variable `RAG_DATA_DIR` if set
- [ ] FR-1.2 Detect OS type (Darwin/Linux/Windows)
- [ ] FR-1.3 Use `~/.synapse/data` on Mac
- [ ] FR-1.4 Use `/opt/synapse/data` on Linux (if writable)
- [ ] FR-1.5 Use appropriate path on Windows
- [ ] FR-1.6 Return consistent path from `_get_data_dir()`

### FR-2: Server Management (CRITICAL)
The CLI must:
- [ ] FR-2.1 Check health endpoint before start
- [ ] FR-2.2 Find correct process PID (not just port-based)
- [ ] FR-2.3 Send proper kill signal (SIGTERM, then SIGKILL)
- [ ] FR-2.4 Verify server stopped after kill
- [ ] FR-2.5 Check health endpoint for status
- [ ] FR-2.6 Show accurate state (not cached/incorrect)

### FR-3: Automated Tests (REQUIRED)
The test suite must:
- [ ] FR-3.1 Test data directory on different OS (mocked)
- [ ] FR-3.2 Test server start with mock process
- [ ] FR-3.3 Test server stop with mock process
- [ ] FR-3.4 Test status with mock health endpoint
- [ ] FR-3.5 All tests pass in CI/CD

---

## Non-Functional Requirements

### NFR-1: Performance
- Data directory detection: < 10ms
- Server start: < 5 seconds
- Server stop: < 3 seconds
- Status check: < 1 second

### NFR-2: Compatibility
- Works on macOS (Darwin)
- Works on Linux (with backward compatibility)
- Works on Windows
- No breaking changes for existing Linux users

### NFR-3: Reliability
- Idempotent directory detection
- Graceful fallback if path not writable
- Clear error messages
- No crashes or hangs

### NFR-4: Test Coverage
- 90%+ coverage for modified code
- All edge cases tested
- Mock external dependencies (OS detection, file system)

---

## Files to Modify

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `mcp_server/rag_server.py` | OS-aware data directory | CRITICAL | ~30 |
| `synapse/cli/commands/start.py` | Fix start logic | HIGH | ~20 |
| `synapse/cli/commands/stop.py` | Fix stop logic | HIGH | ~30 |
| `synapse/cli/commands/status.py` | Fix status logic | HIGH | ~15 |
| `tests/unit/test_mcp_data_directory.py` | New test file | REQUIRED | ~100 |
| `tests/unit/test_server_management.py` | New test file | REQUIRED | ~100 |

**Total: 6 files (4 modified, 2 new)**

---

## Testing Strategy

### OpenCode Testing (Manual)
After implementing fixes, test with OpenCode:
```
/rag list_projects
/rag search project_id="synapse" query="What is Synapse?" memory_type="all" top_k=5
/rag add_fact project_id="synapse" fact_key="opencode_test" fact_value="Testing from OpenCode" category="validation"
/rag add_episode project_id="synapse" title="OpenCode Testing" content="Verified MCP tools work" lesson_type="success"
```

### Pytest Testing (Automated)
```
pytest tests/unit/test_mcp_data_directory.py -v
pytest tests/unit/test_server_management.py -v
pytest tests/unit/ -v --cov=mcp_server --cov=synapse.cli.commands
```

---

## Success Criteria

### Must Have (Go Live)
- [ ] BUG-010 fixed: All MCP tools work on Mac
- [ ] BUG-003 fixed: `stop` stops server
- [ ] BUG-001 fixed: `start` starts server
- [ ] BUG-002 fixed: `status` shows correct state
- [ ] OpenCode tests pass
- [ ] Pytest tests pass
- [ ] No Linux regression

### Should Have (Quality)
- [ ] 90%+ pytest coverage for modified code
- [ ] Documentation comments updated
- [ ] Error messages improved

---

## Timeline Estimate

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| 1. Fix MCP Data Directory | 2-3 hours | Modified `rag_server.py` |
| 2. Fix Server Management | 2-3 hours | Modified `start.py`, `stop.py`, `status.py` |
| 3. Write Pytest Tests | 2-3 hours | 2 new test files |
| 4. OpenCode Testing | 1-2 hours | Manual verification |
| 5. CI/CD Integration | 1 hour | Tests in CI pipeline |
| **Total** | **8-12 hours** | **Complete fix package** |

---

## Related Documentation

- `docs/specs/010-fresh-install-validation/VALIDATION_REPORT.md` - Original validation findings
- `docs/specs/010-fresh-install-validation/BUGS_AND_ISSUES.md` - Bug tracking
- `docs/specs/010-fresh-install-validation/MCP_TEST_RESULTS.md` - MCP tool results

---

**Created**: January 31, 2026  
**Status**: Ready for implementation
