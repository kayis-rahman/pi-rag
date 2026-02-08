# Technical Plan: Rename rag/ to core/

**Feature ID**: 018-rename-rag-to-core  
**Status**: Completed  
**Date**: 2026-02-08

---

## Architecture Changes

```
Before:
├── rag/
│   ├── __init__.py
│   ├── logger.py
│   ├── orchestrator.py
│   └── ... (36 more files)
└── mcp_server/
    └── rag_server.py

After:
├── core/
│   ├── __init__.py
│   ├── logger.py
│   ├── orchestrator.py
│   └── ... (36 more files)
└── mcp_server/
    └── synapse_server.py
```

## Implementation Steps

### Phase 1: Directory Rename
```bash
git mv rag/ core/
```

### Phase 2: Server File Rename
```bash
git mv mcp_server/rag_server.py mcp_server/synapse_server.py
```

### Phase 3: Import Updates
Update all Python files:
- `from rag.X` → `from core.X`
- `import rag` → `import core`
- `rag_server` → `synapse_server`

Commands:
```bash
find . -name "*.py" -exec sed -i '' 's/from rag\./from core./g' {} +
find . -name "*.py" -exec sed -i '' 's/import rag$/import core/g' {} +
find . -name "*.py" -exec sed -i '' 's/rag_server/synapse_server/g' {} +
```

### Phase 4: Documentation Updates
Update all markdown files:
```bash
find . -name "*.md" -o -name "*.mdx" -exec sed -i '' 's|rag/|core/|g' {} +
find . -name "*.md" -o -name "*.mdx" -exec sed -i '' 's|`rag\.|`core.|g' {} +
```

### Phase 5: Configuration Updates
Update pyproject.toml:
- Change entry point: `mcp_server.rag_server:main` → `mcp_server.synapse_server:main`

Update setup.py:
- Change console scripts to use new paths

## Files Modified

| Category | Count | Examples |
|----------|-------|----------|
| Python files (imports) | 41 | All modules importing from rag |
| Documentation files | 94 | README, specs, guides |
| Configuration files | 2 | pyproject.toml, setup.py |
| **Total** | **185** | |

## Statistics

- **Files renamed**: 39 (rag/ → core/)
- **Files modified**: 185
- **Lines changed**: 901 insertions, 901 deletions
- **Import statements updated**: ~200
- **Documentation references updated**: ~500

## Testing

### Verification Commands
```bash
# Test imports work
python -c "from core import *; print('✓ Core imports work')"
python -c "from core.logger import get_logger; print('✓ Logger import works')"

# Check no rag references remain
find . -name "*.py" -exec grep -l "from rag\." {} \; | wc -l
# Expected: 0
```

## Migration Guide

### For Developers

Update your imports:
```python
# Before
from rag.logger import get_logger
from rag.orchestrator import RAGOrchestrator
import rag

# After
from core.logger import get_logger
from core.orchestrator import RAGOrchestrator
import core
```

### Automated Migration
```bash
# Run in your project directory
find . -name "*.py" -exec sed -i '' 's/from rag\./from core./g' {} +
find . -name "*.py" -exec sed -i '' 's/import rag$/import core/g' {} +
```

---

**Result**: Clean rename with preserved git history
