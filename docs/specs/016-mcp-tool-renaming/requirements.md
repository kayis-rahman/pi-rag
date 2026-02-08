# Feature 016: MCP Tool Renaming with Compact Names

**Feature ID**: 016-mcp-tool-renaming  
**Status**: [In Progress]  
**Priority**: High  
**Created**: 2026-02-08  
**Last Updated**: 2026-02-08

---

## Overview

Rename all MCP tools to use compact hierarchical naming (Option C) for optimal context usage while maintaining clarity. This change affects the active MCP server (http_wrapper.py) and deprecates the old rag_server.py implementation.

## Problem Statement

Current MCP tools use bare function names without the `sy.*` prefix:
- `list_projects` instead of `sy.proj.list`
- `search` instead of `sy.mem.search`

This causes:
1. **Inconsistency**: Documentation says tools should be `sy.*` but actual tools lack prefix
2. **Poor discoverability**: No categorical grouping for LLM tool selection
3. **Token inefficiency**: Full names like `sy.list_projects` consume more context

## Solution

Implement compact hierarchical naming (Option C):
- `sy.proj.list` (projects category)
- `sy.src.list` (sources category)
- `sy.ctx.get` (context category)
- `sy.mem.search`, `sy.mem.ingest`, `sy.mem.fact.add`, `sy.mem.ep.add` (memory category)

**Benefits**:
- 15% less token usage than full names
- Clear categorical structure for LLM reasoning
- Self-documenting hierarchy
- Easy to discover related tools

---

## User Stories

### US-001: As an LLM, I want compact tool names
**So that** I can fit more tool calls within context window limits

**Acceptance Criteria**:
- [ ] All 7 tools use compact naming (avg 12 chars vs 18 chars = 33% reduction)
- [ ] Tool names follow `{category}.{action}` pattern
- [ ] Names remain human-readable (proj, src, ctx, mem are standard abbreviations)

### US-002: As a developer, I want consistent tool naming
**So that** documentation matches actual implementation

**Acceptance Criteria**:
- [ ] AGENTS.md shows correct compact tool names
- [ ] All examples use new names
- [ ] No references to old bare names remain in primary docs

### US-003: As a system maintainer, I want deprecated code marked
**So that** I know which server implementation is active

**Acceptance Criteria**:
- [ ] rag_server.py has deprecation warning
- [ ] Clear comment indicating http_wrapper.py is active
- [ ] No imports use deprecated server by default

### US-004: As a CLI user, I want tool names to match
**So that** CLI integration works seamlessly with MCP tools

**Acceptance Criteria**:
- [ ] synapse/cli/main.py uses new compact names
- [ ] CLI commands reference correct tool names
- [ ] No bare tool names in CLI code

---

## Requirements

### Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Rename `list_projects` to `sy.proj.list` | P0 |
| FR-002 | Rename `list_sources` to `sy.src.list` | P0 |
| FR-003 | Rename `get_context` to `sy.ctx.get` | P0 |
| FR-004 | Rename `search` to `sy.mem.search` | P0 |
| FR-005 | Rename `ingest_file` to `sy.mem.ingest` | P0 |
| FR-006 | Rename `add_fact` to `sy.mem.fact.add` | P0 |
| FR-007 | Rename `add_episode` to `sy.mem.ep.add` | P0 |
| FR-008 | Deprecate rag_server.py with warnings | P1 |
| FR-009 | Update AGENTS.md with all new names | P0 |
| FR-010 | Update CLI to use new names | P0 |
| FR-011 | Update configs/rag_config.json | P1 |

### Non-Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-001 | No backward compatibility (clean break) | P0 |
| NFR-002 | All tests pass after renaming | P0 |
| NFR-003 | Server restart works correctly | P0 |
| NFR-004 | MCP tool discovery shows new names | P0 |
| NFR-005 | Documentation consistent across all files | P1 |

---

## Acceptance Criteria

### AC-001: Tool Renaming Complete
**Given** the MCP server is running  
**When** I query available tools  
**Then** I see only the 7 compact names:
- sy.proj.list
- sy.src.list
- sy.ctx.get
- sy.mem.search
- sy.mem.ingest
- sy.mem.fact.add
- sy.mem.ep.add

### AC-002: AGENTS.md Updated
**Given** I open AGENTS.md  
**When** I search for tool references  
**Then** all 40+ references use new compact names

### AC-003: Deprecated Code Marked
**Given** I open rag_server.py  
**When** I read the header comments  
**Then** I see clear deprecation warning

### AC-004: CLI Integration Updated
**Given** I use synapse CLI  
**When** it makes MCP calls  
**Then** it uses new compact tool names

### AC-005: Configuration Updated
**Given** I open configs/rag_config.json  
**When** I check universal_hooks section  
**Then** all tool names use compact format

---

## Constraints

1. **No Backward Compatibility**: Old bare names will not work after this change
2. **Breaking Change**: All MCP clients must update tool names
3. **Single Source of Truth**: Only http_wrapper.py is active, rag_server.py deprecated
4. **Token Optimization**: Prioritize short but readable names

---

## Out of Scope

- Updating archive/ directory (legacy docs)
- Updating old spec files (historical documentation)
- Creating migration scripts for external tools
- Supporting both old and new names simultaneously

---

## Success Metrics

- [ ] All 7 tools renamed to compact format
- [ ] AGENTS.md has 0 references to old names
- [ ] Server starts without errors
- [ ] All MCP tool calls work with new names
- [ ] 15% reduction in average tool name length

---

## References

- [AGENTS.md](/AGENTS.md) - RAG Strict Mandate documentation
- [mcp_server/http_wrapper.py](/mcp_server/http_wrapper.py) - Active MCP server
- [mcp_server/rag_server.py](/mcp_server/rag_server.py) - Server to deprecate
- [Feature 012](/docs/specs/012-memory-fix/) - Previous renaming work (incomplete)

---

**Feature Owner**: Synapse Development Team  
**Reviewers**: TBD  
**Approval**: Pending
