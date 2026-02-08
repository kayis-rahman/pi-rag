# Feature 016: MCP Tool Renaming - Tasks

**Feature ID**: 016-mcp-tool-renaming  
**Status**: [Completed]  
**Total Tasks**: 83  
**Completed**: 83  
**Progress**: 100%

---

## Phase 1: Core Server Changes (P0)
**Objective**: Update active MCP server with compact tool names

### 1.1 Update Tool Decorators
- [x] Add `name="sy.proj.list"` to list_projects decorator (FR-001) ✅
- [x] Add `name="sy.src.list"` to list_sources decorator (FR-002) ✅
- [x] Add `name="sy.ctx.get"` to get_context decorator (FR-003) ✅
- [x] Add `name="sy.mem.search"` to search decorator (FR-004) ✅
- [x] Add `name="sy.mem.ingest"` to ingest_file decorator (FR-005) ✅
- [x] Add `name="sy.mem.fact.add"` to add_fact decorator (FR-006) ✅
- [x] Add `name="sy.mem.ep.add"` to add_episode decorator (FR-007) ✅

### 1.2 Update Documentation in Code
- [x] Update list_projects docstring with new tool name
- [x] Update list_sources docstring with new tool name
- [x] Update get_context docstring with new tool name
- [x] Update search docstring with new tool name
- [x] Update ingest_file docstring with new tool name
- [x] Update add_fact docstring with new tool name
- [x] Update add_episode docstring with new tool name

### 1.3 Update Endpoint Metadata
- [x] Update root_endpoint to show new tool names (line 338)
- [x] Update health_endpoint to list new tool names (line 358)
- [x] Update upload_file example comment (lines 373-386)

### 1.4 Update Server Startup Logs
- [x] Update "Available Tools" log section (lines 531-539)
- [x] Update startup banner with new naming info
- [x] Verify all startup messages are consistent

---

## Phase 2: AGENTS.md Documentation (P1)
**Objective**: Update primary documentation with new tool names

### 2.1 Update RAG Strict Mandate Section
- [x] Update MANDATORY TOOL 1 example (get_context)
- [x] Update MANDATORY TOOL 2 example (search)
- [x] Update MANDATORY TOOL 3 example (list_projects)
- [x] Update MANDATORY TOOL 4 example (list_sources)

### 2.2 Update Memory Authority Hierarchy Examples
- [x] Update Scenario 1 example (search → sy.mem.search)
- [x] Update Scenario 2 example (get_context → sy.ctx.get)
- [x] Update Scenario 3 example (get_context → sy.ctx.get)
- [x] Update Scenario 4 example (ingest_file → sy.mem.ingest)
- [x] Update Scenario 5 example (search → sy.mem.search)

### 2.3 Update Memory Update Mandates
- [x] Update add_fact example (add_fact → sy.mem.fact.add)
- [x] Update add_episode example (add_episode → sy.mem.ep.add)

### 2.4 Update Tool Reference Section
- [x] Update sy.list_projects to sy.proj.list
- [x] Update sy.list_sources to sy.src.list
- [x] Update sy.get_context to sy.ctx.get
- [x] Update sy.search to sy.mem.search
- [x] Update sy.ingest_file to sy.mem.ingest
- [x] Update sy.add_fact to sy.mem.fact.add
- [x] Update sy.add_episode to sy.mem.ep.add

### 2.5 Update Project Context Section
- [x] Update all 7 tool references in PROJECT CONTEXT
- [x] Update memory type descriptions if needed

### 2.6 Update All Inline Examples
- [x] Search for all "rag.*" references and update
- [x] Search for all bare tool names and update
- [x] Verify no old names remain in AGENTS.md

---

## Phase 3: Integration Updates (P2)
**Objective**: Update CLI and configuration

### 3.1 Update CLI Integration
- [x] Update synapse/cli/main.py line 305 (search → sy.mem.search)
- [x] Verify CLI help text doesn't reference old names
- [x] Test CLI command execution

### 3.2 Update Configuration
- [x] Update configs/rag_config.json universal_hooks section
- [x] Change rag.add_fact → sy.mem.fact.add
- [x] Change rag.add_episode → sy.mem.ep.add
- [x] Change rag.search → sy.mem.search
- [x] Verify config loads correctly on server start

---

## Phase 4: Deprecation (P3)
**Objective**: Mark old server as deprecated

### 4.1 Deprecate rag_server.py
- [x] Add deprecation notice to module docstring
- [x] Add DeprecationWarning on module import
- [x] Document http_wrapper.py as active server
- [x] Add timestamp of deprecation

### 4.2 Update Imports (if any)
- [x] Check for imports of rag_server
- [x] Redirect imports to http_wrapper where appropriate
- [x] Verify no circular dependencies

---

## Phase 5: Testing (P0)
**Objective**: Verify all changes work correctly

### 5.1 Server Startup Tests
- [x] Test server starts without errors
- [x] Test server loads new configuration
- [x] Verify no deprecation warnings from http_wrapper

### 5.2 Tool Discovery Tests
- [x] Test tool enumeration shows 7 compact names
- [x] Verify no old bare names in discovery
- [x] Test health endpoint shows correct info

### 5.3 Functional Tests
- [x] Test sy.proj.list returns projects
- [x] Test sy.src.list returns sources
- [x] Test sy.ctx.get returns context
- [x] Test sy.mem.search returns results
- [x] Test sy.mem.ingest ingests files
- [x] Test sy.mem.fact.add adds facts
- [x] Test sy.mem.ep.add adds episodes

### 5.4 Integration Tests
- [x] Test CLI query command works end-to-end
- [x] Test MCP HTTP endpoint with each tool
- [x] Test with OpenCode integration

---

## Phase 6: Documentation Cleanup (P4)
**Objective**: Update remaining documentation

### 6.1 Update README.md
- [x] Update tool list in README (7 references)
- [x] Update quick start examples
- [x] Add note about naming change

### 6.2 Update docs/content/ (Starlight)
- [x] Update docs/content/docs/usage/mcp-tools.mdx (14 refs)
- [x] Update docs/content/docs/usage/ingestion.mdx (1 ref)
- [x] Update docs/content/docs/usage/querying.mdx (1 ref)
- [x] Update docs/content/docs/architecture/mcp-protocol.mdx (7 refs)
- [x] Update docs/content/docs/api-reference/server-api.mdx (2 refs)

### 6.3 Update docs/app/ (VitePress)
- [x] Update docs/app/md/usage/mcp-tools.md (14 refs)
- [x] Update docs/app/md/usage/ingestion.md (1 ref)
- [x] Update docs/app/md/usage/querying.md (1 ref)
- [x] Update docs/app/md/architecture/mcp-protocol.md (7 refs)
- [x] Update docs/app/md/api-reference/server-api.md (2 refs)
- [x] Update docs/app/md/api-reference/cli-commands.md (2 refs)

### 6.4 Create Migration Guide
- [x] Document old → new name mapping
- [x] Provide search/replace commands
- [x] Add to docs/content/docs/
- [x] Add to docs/app/md/

---

## Phase 7: Verification & Completion (P0)
**Objective**: Final checks and documentation

### 7.1 Code Verification
- [x] Run grep for any remaining "rag.list_projects" etc.
- [x] Run grep for bare tool names in active code
- [x] Verify http_wrapper.py has all name= parameters
- [x] Verify AGENTS.md has 0 old references

### 7.2 Test Suite
- [x] Run full pytest suite
- [x] Verify no test failures related to tool names
- [x] Check test coverage

### 7.3 Final Documentation
- [x] Update CHANGELOG.md with breaking changes
- [x] Update docs/specs/index.md (Central Progress Index)
- [x] Mark feature as [Completed] with commit hash
- [x] Create COMPLETION_SUMMARY.md

### 7.4 Handoff
- [x] Verify all files committed
- [x] Verify git push successful
- [x] Document any known issues
- [x] Provide context for next session

---

## Task Dependencies

```
Phase 1 (Core Changes)
    ↓
Phase 2 (AGENTS.md) ← Can start after 1.1 complete
    ↓
Phase 3 (Integration) ← Needs Phase 1 complete
    ↓
Phase 4 (Deprecation) ← Can parallel with Phase 3
    ↓
Phase 5 (Testing) ← Needs Phases 1-3 complete
    ↓
Phase 6 (Documentation) ← Can start after Phase 2
    ↓
Phase 7 (Completion) ← Needs all previous phases
```

---

## Progress Tracking

| Phase | Tasks | Complete | Status |
|-------|-------|----------|--------|
| Phase 1: Core Changes | 18 | 18 | ✅ Complete |
| Phase 2: AGENTS.md | 24 | 24 | ✅ Complete |
| Phase 3: Integration | 5 | 5 | ✅ Complete |
| Phase 4: Deprecation | 4 | 4 | ✅ Complete |
| Phase 5: Testing | 13 | 13 | ✅ Complete |
| Phase 6: Documentation | 14 | 14 | ✅ Complete |
| Phase 7: Completion | 5 | 5 | ✅ Complete |
| **TOTAL** | **83** | **83** | **100%** | |

---

## Quick Reference

### New Tool Names
```
sy.proj.list      # List projects
sy.src.list       # List sources
sy.ctx.get        # Get context
sy.mem.search     # Search memory
sy.mem.ingest     # Ingest document
sy.mem.fact.add   # Add fact
sy.mem.ep.add     # Add episode
```

### Old Names (to be removed)
```
list_projects     → sy.proj.list
list_sources      → sy.src.list
get_context       → sy.ctx.get
search            → sy.mem.search
ingest_file       → sy.mem.ingest
add_fact          → sy.mem.fact.add
add_episode       → sy.mem.ep.add
```

---

**Task Owner**: Synapse Development Team  
**Last Updated**: 2026-02-08
