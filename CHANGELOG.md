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
- `configs/synapse_config.json` - universal_hooks section updated
- `synapse/cli/main.py` - CLI integration updated
- `AGENTS.md` - All 40+ tool references updated
- All documentation files updated with new names

#### Breaking Change: Package Rename (Feature 018)

**Major structural reorganization for cleaner architecture:**

| Old Location | New Location |
|--------------|--------------|
| `rag/` directory | `core/` directory |
| `rag_server.py` | `synapse_server.py` |
| `from rag.X import` | `from core.X import` |
| `import rag` | `import core` |

**Files Changed**:
- 39 core modules moved from `rag/` to `core/`
- `mcp_server/rag_server.py` → `mcp_server/synapse_server.py`
- 41 Python files updated with new imports
- 94 documentation files updated
- `pyproject.toml` entry points updated
- `setup.py` console scripts updated

**Migration Required**:

Update your imports:
```python
# Old (will NOT work)
from rag.logger import get_logger
from rag.orchestrator import Orchestrator
import rag

# New
from core.logger import get_logger
from core.orchestrator import Orchestrator
import core
```

**No Backward Compatibility**: The `rag` package no longer exists. Update all imports before upgrading.

#### Breaking Change: Complete RAG to Synapse Rebrand (Feature 019)

**Complete rebrand from RAG-centric naming to Synapse branding:**

| Old | New |
|-----|-----|
| `RAGOrchestrator` | `Orchestrator` |
| `RAGMemoryBackend` | `MemoryBackend` |
| `RAG_DATA_DIR` | `SYNAPSE_DATA_DIR` |
| `RAG_CONFIG_PATH` | `SYNAPSE_CONFIG_PATH` |
| `RAG_ENV` | `SYNAPSE_ENV` |
| `RAG_TEST_MODE` | `SYNAPSE_TEST_MODE` |
| `RAG_REMOTE_UPLOAD_ENABLED` | `SYNAPSE_REMOTE_UPLOAD_ENABLED` |
| `RAG_UPLOAD_DIR` | `SYNAPSE_UPLOAD_DIR` |
| `RAG_UPLOAD_MAX_AGE` | `SYNAPSE_UPLOAD_MAX_AGE` |
| `RAG_UPLOAD_MAX_SIZE` | `SYNAPSE_UPLOAD_MAX_SIZE` |

**Files Changed:**
- `core/orchestrator.py` - Class renamed to Orchestrator
- `mcp_server/synapse_server.py` - Class renamed to MemoryBackend
- All Python files - Environment variables updated
- All documentation - References updated
- `docker-compose.yml` - Environment variables updated

**Breaking Change:**
- `configs/rag_config.json` renamed to `configs/synapse_config.json`
- All hardcoded references to `rag_config.json` must be updated

**Migration Required:**
See `MIGRATION_v2.0.md` for complete migration guide.

**Version:** v2.0.0 (major breaking change)

