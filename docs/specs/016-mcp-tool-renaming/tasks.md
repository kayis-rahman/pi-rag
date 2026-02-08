# Feature 016: MCP Tool Renaming - Tasks

**Feature ID**: 016-mcp-tool-renaming  
**Status**: [In Progress]  
**Total Tasks**: 52  
**Completed**: 0  
**Progress**: 0%

---

## Phase 1: Core Server Changes (P0)
**Objective**: Update active MCP server with compact tool names

### 1.1 Update Tool Decorators
- [ ] Add `name="sy.proj.list"` to list_projects decorator (FR-001)
- [ ] Add `name="sy.src.list"` to list_sources decorator (FR-002)
- [ ] Add `name="sy.ctx.get"` to get_context decorator (FR-003)
- [ ] Add `name="sy.mem.search"` to search decorator (FR-004)
- [ ] Add `name="sy.mem.ingest"` to ingest_file decorator (FR-005)
- [ ] Add `name="sy.mem.fact.add"` to add_fact decorator (FR-006)
- [ ] Add `name="sy.mem.ep.add"` to add_episode decorator (FR-007)

### 1.2 Update Documentation in Code
- [ ] Update list_projects docstring with new tool name
- [ ] Update list_sources docstring with new tool name
- [ ] Update get_context docstring with new tool name
- [ ] Update search docstring with new tool name
- [ ] Update ingest_file docstring with new tool name
- [ ] Update add_fact docstring with new tool name
- [ ] Update add_episode docstring with new tool name

### 1.3 Update Endpoint Metadata
- [ ] Update root_endpoint to show new tool names (line 338)
- [ ] Update health_endpoint to list new tool names (line 358)
- [ ] Update upload_file example comment (lines 373-386)

### 1.4 Update Server Startup Logs
- [ ] Update "Available Tools" log section (lines 531-539)
- [ ] Update startup banner with new naming info
- [ ] Verify all startup messages are consistent

---

## Phase 2: AGENTS.md Documentation (P1)
**Objective**: Update primary documentation with new tool names

### 2.1 Update RAG Strict Mandate Section
- [ ] Update MANDATORY TOOL 1 example (get_context)
- [ ] Update MANDATORY TOOL 2 example (search)
- [ ] Update MANDATORY TOOL 3 example (list_projects)
- [ ] Update MANDATORY TOOL 4 example (list_sources)

### 2.2 Update Memory Authority Hierarchy Examples
- [ ] Update Scenario 1 example (search → sy.mem.search)
- [ ] Update Scenario 2 example (get_context → sy.ctx.get)
- [ ] Update Scenario 3 example (get_context → sy.ctx.get)
- [ ] Update Scenario 4 example (ingest_file → sy.mem.ingest)
- [ ] Update Scenario 5 example (search → sy.mem.search)

### 2.3 Update Memory Update Mandates
- [ ] Update add_fact example (add_fact → sy.mem.fact.add)
- [ ] Update add_episode example (add_episode → sy.mem.ep.add)

### 2.4 Update Tool Reference Section
- [ ] Update sy.list_projects to sy.proj.list
- [ ] Update sy.list_sources to sy.src.list
- [ ] Update sy.get_context to sy.ctx.get
- [ ] Update sy.search to sy.mem.search
- [ ] Update sy.ingest_file to sy.mem.ingest
- [ ] Update sy.add_fact to sy.mem.fact.add
- [ ] Update sy.add_episode to sy.mem.ep.add

### 2.5 Update Project Context Section
- [ ] Update all 7 tool references in PROJECT CONTEXT
- [ ] Update memory type descriptions if needed

### 2.6 Update All Inline Examples
- [ ] Search for all "rag.*" references and update
- [ ] Search for all bare tool names and update
- [ ] Verify no old names remain in AGENTS.md

---

## Phase 3: Integration Updates (P2)
**Objective**: Update CLI and configuration

### 3.1 Update CLI Integration
- [ ] Update synapse/cli/main.py line 305 (search → sy.mem.search)
- [ ] Verify CLI help text doesn't reference old names
- [ ] Test CLI command execution

### 3.2 Update Configuration
- [ ] Update configs/rag_config.json universal_hooks section
- [ ] Change rag.add_fact → sy.mem.fact.add
- [ ] Change rag.add_episode → sy.mem.ep.add
- [ ] Change rag.search → sy.mem.search
- [ ] Verify config loads correctly on server start

---

## Phase 4: Deprecation (P3)
**Objective**: Mark old server as deprecated

### 4.1 Deprecate rag_server.py
- [ ] Add deprecation notice to module docstring
- [ ] Add DeprecationWarning on module import
- [ ] Document http_wrapper.py as active server
- [ ] Add timestamp of deprecation

### 4.2 Update Imports (if any)
- [ ] Check for imports of rag_server
- [ ] Redirect imports to http_wrapper where appropriate
- [ ] Verify no circular dependencies

---

## Phase 5: Testing (P0)
**Objective**: Verify all changes work correctly

### 5.1 Server Startup Tests
- [ ] Test server starts without errors
- [ ] Test server loads new configuration
- [ ] Verify no deprecation warnings from http_wrapper

### 5.2 Tool Discovery Tests
- [ ] Test tool enumeration shows 7 compact names
- [ ] Verify no old bare names in discovery
- [ ] Test health endpoint shows correct info

### 5.3 Functional Tests
- [ ] Test sy.proj.list returns projects
- [ ] Test sy.src.list returns sources
- [ ] Test sy.ctx.get returns context
- [ ] Test sy.mem.search returns results
- [ ] Test sy.mem.ingest ingests files
- [ ] Test sy.mem.fact.add adds facts
- [ ] Test sy.mem.ep.add adds episodes

### 5.4 Integration Tests
- [ ] Test CLI query command works end-to-end
- [ ] Test MCP HTTP endpoint with each tool
- [ ] Test with OpenCode integration

---

## Phase 6: Documentation Cleanup (P4)
**Objective**: Update remaining documentation

### 6.1 Update README.md
- [ ] Update tool list in README (7 references)
- [ ] Update quick start examples
- [ ] Add note about naming change

### 6.2 Update docs/content/ (Starlight)
- [ ] Update docs/content/docs/usage/mcp-tools.mdx (14 refs)
- [ ] Update docs/content/docs/usage/ingestion.mdx (1 ref)
- [ ] Update docs/content/docs/usage/querying.mdx (1 ref)
- [ ] Update docs/content/docs/architecture/mcp-protocol.mdx (7 refs)
- [ ] Update docs/content/docs/api-reference/server-api.mdx (2 refs)

### 6.3 Update docs/app/ (VitePress)
- [ ] Update docs/app/md/usage/mcp-tools.md (14 refs)
- [ ] Update docs/app/md/usage/ingestion.md (1 ref)
- [ ] Update docs/app/md/usage/querying.md (1 ref)
- [ ] Update docs/app/md/architecture/mcp-protocol.md (7 refs)
- [ ] Update docs/app/md/api-reference/server-api.md (2 refs)
- [ ] Update docs/app/md/api-reference/cli-commands.md (2 refs)

### 6.4 Create Migration Guide
- [ ] Document old → new name mapping
- [ ] Provide search/replace commands
- [ ] Add to docs/content/docs/
- [ ] Add to docs/app/md/

---

## Phase 7: Verification & Completion (P0)
**Objective**: Final checks and documentation

### 7.1 Code Verification
- [ ] Run grep for any remaining "rag.list_projects" etc.
- [ ] Run grep for bare tool names in active code
- [ ] Verify http_wrapper.py has all name= parameters
- [ ] Verify AGENTS.md has 0 old references

### 7.2 Test Suite
- [ ] Run full pytest suite
- [ ] Verify no test failures related to tool names
- [ ] Check test coverage

### 7.3 Final Documentation
- [ ] Update CHANGELOG.md with breaking changes
- [ ] Update docs/specs/index.md (Central Progress Index)
- [ ] Mark feature as [Completed] with commit hash
- [ ] Create COMPLETION_SUMMARY.md

### 7.4 Handoff
- [ ] Verify all files committed
- [ ] Verify git push successful
- [ ] Document any known issues
- [ ] Provide context for next session

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
| Phase 1: Core Changes | 18 | 0 | ⏳ Not Started |
| Phase 2: AGENTS.md | 24 | 0 | ⏳ Not Started |
| Phase 3: Integration | 5 | 0 | ⏳ Not Started |
| Phase 4: Deprecation | 4 | 0 | ⏳ Not Started |
| Phase 5: Testing | 13 | 0 | ⏳ Not Started |
| Phase 6: Documentation | 14 | 0 | ⏳ Not Started |
| Phase 7: Completion | 5 | 0 | ⏳ Not Started |
| **TOTAL** | **83** | **0** | **0%** |

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
