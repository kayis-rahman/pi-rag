# Changelog

All notable changes to SYNAPSE will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

#### Breaking Change: MCP Tool Renaming (Feature 016)

All MCP tools have been renamed to use compact hierarchical naming for optimal context usage:

| Old Name | New Name |
|----------|----------|
| `list_projects` | `sy.proj.list` |
| `list_sources` | `sy.src.list` |
| `get_context` | `sy.ctx.get` |
| `search` | `sy.mem.search` |
| `ingest_file` | `sy.mem.ingest` |
| `add_fact` | `sy.mem.fact.add` |
| `add_episode` | `sy.mem.ep.add` |

**Migration Required**: Update all MCP tool calls in your:
- Agent configurations (AGENTS.md)
- MCP client configurations
- Scripts and automation
- Documentation and guides

**Benefits**:
- **Token Efficiency**: ~15% reduction in context usage
- **Categorical Structure**: Clear grouping (proj, src, ctx, mem)
- **LLM-Friendly**: Helps with tool selection reasoning
- **Self-Documenting**: Hierarchy embedded in names

**No Backward Compatibility**: Old bare tool names will not work. Update all references before upgrading.

### Files Changed

- `mcp_server/http_wrapper.py` - All 7 tools renamed with `name=` parameter
- `configs/rag_config.json` - universal_hooks section updated
- `synapse/cli/main.py` - CLI integration updated
- `AGENTS.md` - All 40+ tool references updated
- All documentation files updated with new names

