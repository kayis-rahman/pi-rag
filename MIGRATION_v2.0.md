# Migration Guide: v1.x to v2.0

## Overview

This guide helps you migrate from Synapse v1.x to v2.0. Version 2.0 includes a complete rebrand from RAG-centric naming to Synapse branding.

## Breaking Changes

### 1. Class Names Changed

| Old Name | New Name |
|----------|----------|
| `RAGOrchestrator` | `Orchestrator` |
| `RAGMemoryBackend` | `MemoryBackend` |

### 2. Environment Variables Renamed

| Old Variable | New Variable |
|--------------|--------------|
| `RAG_DATA_DIR` | `SYNAPSE_DATA_DIR` |
| `RAG_CONFIG_PATH` | `SYNAPSE_CONFIG_PATH` |
| `RAG_ENV` | `SYNAPSE_ENV` |
| `RAG_TEST_MODE` | `SYNAPSE_TEST_MODE` |
| `RAG_REMOTE_UPLOAD_ENABLED` | `SYNAPSE_REMOTE_UPLOAD_ENABLED` |
| `RAG_UPLOAD_DIR` | `SYNAPSE_UPLOAD_DIR` |
| `RAG_UPLOAD_MAX_AGE` | `SYNAPSE_UPLOAD_MAX_AGE` |
| `RAG_UPLOAD_MAX_SIZE` | `SYNAPSE_UPLOAD_MAX_SIZE` |

### 3. Configuration File Renamed (Breaking Change)

| Old File | New File |
|----------|----------|
| `configs/rag_config.json` | `configs/synapse_config.json` |

**All hardcoded references to `rag_config.json` must be updated.**

### Step 1: Update Environment Variables

#### Option A: Manual Update

Update your shell environment:

```bash
# Export new variables
export SYNAPSE_DATA_DIR="${RAG_DATA_DIR:-/opt/synapse/data}"
export SYNAPSE_CONFIG_PATH="${RAG_CONFIG_PATH:-./configs/rag_config.json}"
export SYNAPSE_ENV="${RAG_ENV:-dev}"
export SYNAPSE_TEST_MODE="${RAG_TEST_MODE:-false}"

# Unset old variables
unset RAG_DATA_DIR RAG_CONFIG_PATH RAG_ENV RAG_TEST_MODE
```

#### Option B: Docker Compose Update

Update your `docker-compose.yml`:

```yaml
services:
  synapse:
    environment:
      - SYNAPSE_DATA_DIR=/opt/synapse/data
      - SYNAPSE_CONFIG_PATH=/app/configs/rag_config.json
      - SYNAPSE_ENV=production
      # Remove old RAG_* variables
```

### Step 2: Update Code Imports

If you have custom scripts using Synapse classes:

```python
# Old (v1.x)
from core.orchestrator import RAGOrchestrator
from mcp_server.synapse_server import RAGMemoryBackend

# New (v2.0)
from core.orchestrator import Orchestrator
from mcp_server.synapse_server import MemoryBackend
```

### Step 3: Update Configuration Files

**If you have existing `rag_config.json` files:**

1. Rename the file:
```bash
mv configs/rag_config.json configs/synapse_config.json
```

2. Update all hardcoded references in your code:
```bash
# Replace all occurrences of rag_config.json with synapse_config.json
find . -type f -name "*.py" -exec sed -i 's/rag_config\.json/synapse_config\.json/g' {} +
find . -type f -name "*.yaml" -exec sed -i 's/rag_config\.json/synapse_config\.json/g' {} +
find . -type f -name "*.yml" -exec sed -i 's/rag_config\.json/synapse_config\.json/g' {} +
```

### Step 4: Update Shell Scripts

If you have shell scripts:

```bash
# Replace in all scripts
find . -name "*.sh" -exec sed -i 's/RAG_/SYNAPSE_/g' {} +
```

## Quick Migration Script

Save this as `migrate-to-v2.sh`:

```bash
#!/bin/bash

echo "Migrating to Synapse v2.0..."

# Update environment variables
export SYNAPSE_DATA_DIR="${RAG_DATA_DIR:-/opt/synapse/data}"
export SYNAPSE_CONFIG_PATH="${RAG_CONFIG_PATH:-./configs/rag_config.json}"
export SYNAPSE_ENV="${RAG_ENV:-dev}"
export SYNAPSE_TEST_MODE="${RAG_TEST_MODE:-false}"
export SYNAPSE_REMOTE_UPLOAD_ENABLED="${RAG_REMOTE_UPLOAD_ENABLED:-true}"
export SYNAPSE_UPLOAD_DIR="${RAG_UPLOAD_DIR:-/tmp/rag-uploads}"
export SYNAPSE_UPLOAD_MAX_AGE="${RAG_UPLOAD_MAX_AGE:-3600}"
export SYNAPSE_UPLOAD_MAX_SIZE="${RAG_UPLOAD_MAX_SIZE:-50}"

# Unset old variables
unset RAG_DATA_DIR RAG_CONFIG_PATH RAG_ENV RAG_TEST_MODE
unset RAG_REMOTE_UPLOAD_ENABLED RAG_UPLOAD_DIR RAG_UPLOAD_MAX_AGE RAG_UPLOAD_MAX_SIZE

echo "✓ Environment variables migrated"

# Update Python files if needed
if [ -d "your-python-project" ]; then
    find your-python-project -name "*.py" -exec sed -i 's/RAGOrchestrator/Orchestrator/g' {} +
    find your-python-project -name "*.py" -exec sed -i 's/RAGMemoryBackend/MemoryBackend/g' {} +
    echo "✓ Python files updated"
fi

echo "Migration complete!"
```

## Verification

After migration, verify:

```bash
# Check no old env vars remain
env | grep RAG_ | wc -l
# Expected: 0

# Check new env vars are set
env | grep SYNAPSE_ | wc -l
# Expected: 8 (or however many you use)

# Test imports
python -c "from core import Orchestrator; from mcp_server import MemoryBackend; print('✓ Imports work')"
```

## Rollback

If you need to rollback:

```bash
# Restore old environment variables
export RAG_DATA_DIR="$SYNAPSE_DATA_DIR"
export RAG_CONFIG_PATH="$SYNAPSE_CONFIG_PATH"
# ... etc for all variables

# Unset new variables
unset SYNAPSE_DATA_DIR SYNAPSE_CONFIG_PATH SYNAPSE_ENV SYNAPSE_TEST_MODE
unset SYNAPSE_REMOTE_UPLOAD_ENABLED SYNAPSE_UPLOAD_DIR SYNAPSE_UPLOAD_MAX_AGE SYNAPSE_UPLOAD_MAX_SIZE

# Downgrade to v1.x
pip install synapse==1.2.0
```

## Need Help?

- Check the [CHANGELOG](../CHANGELOG.md) for detailed changes
- Review [Feature 019 Spec](../docs/specs/019-complete-rag-rebrand/)
- Open an issue on GitHub

---

**Migration Date**: 2026-02-08  
**Target Version**: 2.0.0  
**Breaking Changes**: Yes (major version bump)
