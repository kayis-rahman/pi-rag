# Technical Plan: Complete RAG to Synapse Rebrand

**Feature ID**: 019-complete-rag-rebrand  
**Status**: In Progress  
**Date**: 2026-02-08

---

## Architecture Changes

```
Before:
├── Classes:
│   ├── Orchestrator
│   ├── MemoryBackend
│   └── TestOrchestrator*
│
├── Environment Variables:
│   ├── SYNAPSE_DATA_DIR
│   ├── SYNAPSE_CONFIG_PATH
│   ├── SYNAPSE_ENV
│   ├── SYNAPSE_TEST_MODE
│   ├── SYNAPSE_REMOTE_UPLOAD_ENABLED
│   ├── SYNAPSE_UPLOAD_DIR
│   ├── SYNAPSE_UPLOAD_MAX_AGE
│   └── SYNAPSE_UPLOAD_MAX_SIZE
│
└── Constants:
    └── SYNAPSE_HEADER

After:
├── Classes:
│   ├── Orchestrator
│   ├── MemoryBackend
│   └── TestOrchestrator*
│
├── Environment Variables:
│   ├── SYNAPSE_DATA_DIR
│   ├── SYNAPSE_CONFIG_PATH
│   ├── SYNAPSE_ENV
│   ├── SYNAPSE_TEST_MODE
│   ├── SYNAPSE_REMOTE_UPLOAD_ENABLED
│   ├── SYNAPSE_UPLOAD_DIR
│   ├── SYNAPSE_UPLOAD_MAX_AGE
│   └── SYNAPSE_UPLOAD_MAX_SIZE
│
└── Constants:
    └── CONTEXT_HEADER
```

## Implementation Strategy

### Phase 1: Class Renames (Atomic)

**Files to modify:**
1. `core/orchestrator.py` - Class definition + docstrings
2. `core/__init__.py` - Export update
3. `mcp_server/synapse_server.py` - Class definition
4. `mcp_server/__init__.py` - Export update
5. `mcp_server/http_wrapper.py` - Import update
6. `core/prompt_builder.py` - Constant rename

**Commands:**
```bash
# Class definitions
sed -i '' 's/class Orchestrator:/class Orchestrator:/g' core/orchestrator.py
sed -i '' 's/class MemoryBackend:/class MemoryBackend:/g' mcp_server/synapse_server.py

# Update all references in codebase
find . -name "*.py" -exec sed -i '' 's/Orchestrator/Orchestrator/g' {} +
find . -name "*.py" -exec sed -i '' 's/MemoryBackend/MemoryBackend/g' {} +
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_HEADER/CONTEXT_HEADER/g' {} +
```

### Phase 2: Environment Variable Renames

**Priority 1: Core env vars (used everywhere)**
```bash
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_DATA_DIR/SYNAPSE_DATA_DIR/g' {} +
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_CONFIG_PATH/SYNAPSE_CONFIG_PATH/g' {} +
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_ENV/SYNAPSE_ENV/g' {} +
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_TEST_MODE/SYNAPSE_TEST_MODE/g' {} +
```

**Priority 2: Upload-related env vars**
```bash
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_REMOTE_UPLOAD_ENABLED/SYNAPSE_REMOTE_UPLOAD_ENABLED/g' {} +
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_UPLOAD_DIR/SYNAPSE_UPLOAD_DIR/g' {} +
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_UPLOAD_MAX_AGE/SYNAPSE_UPLOAD_MAX_AGE/g' {} +
find . -name "*.py" -exec sed -i '' 's/SYNAPSE_UPLOAD_MAX_SIZE/SYNAPSE_UPLOAD_MAX_SIZE/g' {} +
```

### Phase 3: Documentation Updates

**Update all markdown files:**
```bash
find docs/ -name "*.md" -o -name "*.mdx" | xargs sed -i '' 's/SYNAPSE_DATA_DIR/SYNAPSE_DATA_DIR/g'
find docs/ -name "*.md" -o -name "*.mdx" | xargs sed -i '' 's/SYNAPSE_CONFIG_PATH/SYNAPSE_CONFIG_PATH/g'
# ... repeat for all env vars

# Update class references in docs
find docs/ -name "*.md" -o -name "*.mdx" | xargs sed -i '' 's/Orchestrator/Orchestrator/g'
find docs/ -name "*.md" -o -name "*.mdx" | xargs sed -i '' 's/MemoryBackend/MemoryBackend/g'
```

### Phase 4: Configuration Files

**Docker Compose:**
```bash
sed -i '' 's/SYNAPSE_/SYNAPSE_/g' docker-compose.yml
sed -i '' 's/SYNAPSE_/SYNAPSE_/g' docker-compose.override.yml
```

**Config JSONs (if any hardcoded):**
```bash
sed -i '' 's/SYNAPSE_/SYNAPSE_/g' configs/*.json
```

**pyproject.toml:**
```bash
sed -i '' 's/SYNAPSE_/SYNAPSE_/g' pyproject.toml
```

### Phase 5: Test Class Renames

```bash
# Update test class names
sed -i '' 's/TestOrchestrator/TestOrchestrator/g' tests/unit/rag/test_orchestrator.py
sed -i '' 's/TestOrchestrator/TestOrchestrator/g' tests/integration/test_rag_pipeline.py
```

## Files Modified Summary

| Category | Count | Examples |
|----------|-------|----------|
| Core implementation | 6 | orchestrator.py, synapse_server.py, etc. |
| Exports/imports | 3 | __init__.py files |
| CLI | 1 | start.py |
| Tests | 8 | test_orchestrator.py, etc. |
| Documentation | 20+ | README.md, AGENTS.md, specs |
| Config files | 5 | docker-compose.yml, etc. |
| **Total** | **45+** | |

## Testing Strategy

### After Phase 1:
```bash
python -c "from core import Orchestrator; print('✓ Orchestrator import works')"
python -c "from mcp_server import MemoryBackend; print('✓ MemoryBackend import works')"
```

### After Phase 2:
```bash
# Test env var access
python -c "import os; os.environ['SYNAPSE_DATA_DIR'] = '/test'; print('✓ Env vars work')"
```

### Final Validation:
```bash
# Check no old references remain
grep -r "Orchestrator\|MemoryBackend" --include="*.py" . | grep -v ".git" | wc -l
# Expected: 0

grep -r "SYNAPSE_DATA_DIR\|SYNAPSE_CONFIG_PATH" --include="*.py" . | grep -v ".git" | wc -l
# Expected: 0

# Run tests
pytest tests/ -v --tb=short 2>&1 | tail -20
```

## Rollback Plan

If issues discovered:
```bash
# Revert all changes
git checkout -- .
git clean -fd
```

## Migration Guide

Create `MIGRATION_v2.0.md`:

```markdown
# Migration Guide: v1.x to v2.0

## Environment Variables

Update your environment files:

```bash
# Old → New
SYNAPSE_DATA_DIR → SYNAPSE_DATA_DIR
SYNAPSE_CONFIG_PATH → SYNAPSE_CONFIG_PATH
SYNAPSE_ENV → SYNAPSE_ENV
SYNAPSE_TEST_MODE → SYNAPSE_TEST_MODE
```

## Docker Compose

Update your `docker-compose.yml`:

```yaml
environment:
  - SYNAPSE_DATA_DIR=/opt/synapse/data
  - SYNAPSE_CONFIG_PATH=/app/configs/rag_config.json
```

## Code Imports

Update your Python code:

```python
# Old
from core.orchestrator import Orchestrator
from mcp_server.synapse_server import MemoryBackend

# New
from core.orchestrator import Orchestrator
from mcp_server.synapse_server import MemoryBackend
```

## Quick Migration Script

```bash
# Update environment variables
export SYNAPSE_DATA_DIR="$SYNAPSE_DATA_DIR"
export SYNAPSE_CONFIG_PATH="$SYNAPSE_CONFIG_PATH"
unset SYNAPSE_DATA_DIR SYNAPSE_CONFIG_PATH

# Update your scripts
find . -name "*.py" -exec sed -i '' 's/Orchestrator/Orchestrator/g' {} +
find . -name "*.py" -exec sed -i '' 's/MemoryBackend/MemoryBackend/g' {} +
```
```

---

**Result**: Complete rebrand from RAG to Synapse naming
