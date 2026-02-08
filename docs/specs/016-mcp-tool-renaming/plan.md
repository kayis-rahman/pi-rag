# Feature 016: MCP Tool Renaming - Technical Plan

**Feature ID**: 016-mcp-tool-renaming  
**Status**: [In Progress]  
**Created**: 2026-02-08

---

## Architecture Overview

### Current State
```
MCP Server Architecture:
├── mcp_server/rag_server.py      [DEPRECATED - old implementation]
├── mcp_server/http_wrapper.py    [ACTIVE - FastMCP implementation]
└── synapse/cli/main.py           [CLI integration]
```

### Target State
```
MCP Server Architecture:
├── mcp_server/rag_server.py      [DEPRECATED - marked with warnings]
├── mcp_server/http_wrapper.py    [ACTIVE - with compact tool names]
└── synapse/cli/main.py           [updated to use new names]
```

---

## Technical Design

### 1. Tool Name Mapping

| Function Name | New Tool Name | Category | Action |
|---------------|---------------|----------|--------|
| `list_projects` | `sy.proj.list` | proj | list |
| `list_sources` | `sy.src.list` | src | list |
| `get_context` | `sy.ctx.get` | ctx | get |
| `search` | `sy.mem.search` | mem | search |
| `ingest_file` | `sy.mem.ingest` | mem | ingest |
| `add_fact` | `sy.mem.fact.add` | mem.fact | add |
| `add_episode` | `sy.mem.ep.add` | mem.ep | add |

**Naming Convention**:
- `sy` - Project shortname (constant)
- `{category}` - Logical grouping (proj, src, ctx, mem)
- `{action}` - Operation (list, get, search, ingest, add)
- Sub-categories for memory types: `mem.fact`, `mem.ep`

### 2. Implementation Approach

#### 2.1 FastMCP Tool Registration

Current (http_wrapper.py line 89-90):
```python
@mcp.tool()
async def list_projects(scope_type: Optional[str] = None) -> dict:
```

New:
```python
@mcp.tool(name="sy.proj.list")
async def list_projects(scope_type: Optional[str] = None) -> dict:
```

**Implementation**:
- Add `name=` parameter to all 7 `@mcp.tool()` decorators
- Function names remain unchanged (for code readability)
- Only the MCP-exposed name changes

#### 2.2 Deprecation Strategy for rag_server.py

Add at top of file:
```python
"""
DEPRECATED: This module is deprecated and will be removed in a future version.

Use mcp_server.http_wrapper instead - it provides the active MCP server
implementation with FastMCP and HTTP transport.

Last Updated: 2026-02-08
"""

import warnings
warnings.warn(
    "rag_server.py is deprecated. Use http_wrapper.py instead.",
    DeprecationWarning,
    stacklevel=2
)
```

### 3. Files to Modify

#### P0 - Critical Path

| File | Changes | Lines |
|------|---------|-------|
| `mcp_server/http_wrapper.py` | Add name= to 7 @mcp.tool() decorators | 89, 102, 116, 147, 182, 265, 294 |
| `mcp_server/http_wrapper.py` | Update docstrings with new names | All function docs |
| `mcp_server/http_wrapper.py` | Update root_endpoint metadata | 327-343 |
| `mcp_server/http_wrapper.py` | Update health_endpoint metadata | 346-370 |
| `mcp_server/http_wrapper.py` | Update upload_file example comment | 373-386 |
| `mcp_server/http_wrapper.py` | Update server startup logs | 515-552 |

#### P1 - Documentation

| File | Changes | Count |
|------|---------|-------|
| `AGENTS.md` | Update tool references | 40+ |
| `AGENTS.md` | Update examples | 10+ |
| `AGENTS.md` | Update TOOL REFERENCE section | 1 section |

#### P2 - Integration

| File | Changes | Details |
|------|---------|---------|
| `synapse/cli/main.py` | Line 305 | `"search"` → `"sy.mem.search"` |
| `configs/rag_config.json` | universal_hooks section | `rag.*` → `sy.mem.*` |

#### P3 - Deprecation

| File | Changes | Details |
|------|---------|---------|
| `mcp_server/rag_server.py` | Module docstring | Add deprecation notice |
| `mcp_server/rag_server.py` | Import warning | Add DeprecationWarning |

---

## Data Flow

### Before
```
OpenCode → MCP Request → http_wrapper.py
                          ↓
                    @mcp.tool()  [bare name]
                          ↓
                    backend.search()
```

### After
```
OpenCode → MCP Request → http_wrapper.py
                          ↓
                    @mcp.tool(name="sy.mem.search")
                          ↓
                    backend.search()
```

---

## Dependencies

### External
- FastMCP library (already installed)
- Starlette (already installed)

### Internal
- `mcp_server.rag_server.RAGMemoryBackend`
- `synapse.config.config.get_shortname()`

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking existing MCP clients | High | High | Document migration path, no backward compat by design |
| Tool discovery fails | Low | High | Test tool enumeration endpoint |
| Server fails to start | Low | High | Verify FastMCP accepts name= parameter |
| Documentation inconsistencies | Medium | Medium | Update AGENTS.md completely |
| CLI integration breaks | Medium | High | Update CLI before testing |

---

## Testing Strategy

### Unit Tests
- [ ] Verify all 7 tools register with correct names
- [ ] Verify tool discovery returns compact names
- [ ] Verify function implementations unchanged

### Integration Tests
- [ ] Test MCP HTTP endpoint with new names
- [ ] Test CLI commands work end-to-end
- [ ] Test server restart with new configuration

### Documentation Tests
- [ ] AGENTS.md has 0 old references
- [ ] All examples use compact names
- [ ] Migration guide is clear

---

## Migration Path

### For Users

**Old names (will NOT work)**:
```python
# ❌ These will fail
await mcp.list_projects()
await mcp.search(project_id="synapse", query="test")
```

**New names (required)**:
```python
# ✅ Use these instead
await mcp.sy_proj_list()
await mcp.sy_mem_search(project_id="synapse", query="test")
```

### Search/Replace Commands

```bash
# In your codebase, replace:
# rag.list_projects → sy.proj.list
# rag.list_sources → sy.src.list
# rag.get_context → sy.ctx.get
# rag.search → sy.mem.search
# rag.ingest_file → sy.mem.ingest
# rag.add_fact → sy.mem.fact.add
# rag.add_episode → sy.mem.ep.add
```

---

## Implementation Phases

### Phase 1: Core Changes (P0)
- Update http_wrapper.py with new names
- Test server starts
- Verify tool registration

### Phase 2: Documentation (P1)
- Update AGENTS.md
- Update inline documentation
- Update examples

### Phase 3: Integration (P2)
- Update CLI
- Update config
- Test end-to-end

### Phase 4: Deprecation (P3)
- Mark rag_server.py deprecated
- Add warnings

### Phase 5: Cleanup (P4)
- Update README
- Update docs/content/
- Archive old references

---

## Success Criteria

1. **Functional**: All 7 tools respond to compact names
2. **Performance**: 15% reduction in average name length
3. **Documentation**: AGENTS.md fully updated
4. **Integration**: CLI works with new names
5. **Deprecation**: rag_server.py marked clearly

---

**Technical Lead**: Synapse Development Team  
**Review Date**: TBD
