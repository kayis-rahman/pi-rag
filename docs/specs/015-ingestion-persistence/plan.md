# Ingestion Persistence Fix - Technical Plan

**Feature ID**: 015-ingestion-persistence
**Status**: [In Progress] - Phase 1 Complete
**Created**: February 1, 2026
**Last Updated**: February 7, 2026

---

## Implementation Strategy

This plan covers diagnosing and fixing BUG-INGEST-01: Ingestion completes but data is not persisted.

---

## Plan 1: Diagnosis

### Step 1.1: Reproduce the Issue
```bash
# Run ingestion
synapse ingest docs/specs --dry-run  # Check what would be ingested
synapse ingest docs/specs             # Actual ingestion

# Check if data was persisted
sy list_sources --project-id synapse  # Should return > 0, currently returns 0

# Check directories
ls -la ~/.synapse/semantic_index/     # Should have files, currently empty
```

### Step 1.2: Trace the Code Flow
1. `synapse ingest` → calls `scripts/bulk_ingest.py`
2. `bulk_ingest.py` → calls `core/semantic_ingestor.py`
3. `semantic_ingestor.py` → calls `core/semantic_store.py`
4. `semantic_store.py` → writes to `core/vectorstore.py`

### Step 1.3: Identify Root Cause
- Check if `semantic_index` directory is created
- Check if files are written to directory
- Check if vectorstore commit() is called
- Check for exceptions during write

---

## DIAGNOSIS RESULTS (Completed Feb 7, 2026)

### Findings

**Data IS Persisted**: Found 12MB of data at `/home/dietpi/synapse/data/semantic_index/`:
- `chunks.json` (12MB) - Contains 1000+ document chunks with embeddings
- `metadata/documents.json` (8KB) - Contains 20+ document records
- `checksums.json` (50KB) - Incremental ingestion checksums

**Actual Bug**: Singleton pattern in `get_semantic_store()`

```python
# core/semantic_store.py lines 571-584
_global_semantic_store = None

def get_semantic_store(index_path: str = "./data/semantic_index") -> SemanticStore:
    global _global_semantic_store
    if _global_semantic_store is None:
        _global_semantic_store = SemanticStore(index_path)  # Uses path only on first call
    return _global_semantic_store  # Returns same instance regardless of path parameter
```

**Impact**: 
- First call to `get_semantic_store()` creates instance with its path
- Subsequent calls with different paths return the first instance
- MCP server and CLI tools use different paths but get same store
- Data appears "lost" because it's stored in one location but queried from another

### Root Cause Confirmed
The issue is NOT that data isn't persisted - it's that the **singleton ignores the index_path parameter** after first initialization.

### Fix Options
1. **Remove singleton pattern** - Create new instance each time (simplest)
2. **Cache by path** - Store instances in dict keyed by path
3. **Use consistent config** - Ensure all code uses same path from config

**Recommended**: Option 1 (remove singleton) for immediate fix, then Option 3 for long-term.

---

## Plan 2: Fix Storage Backend

### File: `core/semantic_store.py`

**Current Issue**: Data may be written but not committed to disk.

```python
# Check if save/commit is called
def add_document(self, document: Document) -> str:
    # ... processing ...
    chunk_id = self._store_chunk(document)
    # BUG: May not call self.save() or self._commit()
    return chunk_id
```

**Fix**: Ensure commit is called after batch operations.

```python
def add_document(self, document: Document) -> str:
    chunk_id = self._store_chunk(document)
    self.save()  # Ensure data is persisted
    return chunk_id

def add_documents(self, documents: List[Document]) -> List[str]:
    chunk_ids = []
    for doc in documents:
        chunk_ids.append(self._store_chunk(doc))
    self.save()  # Commit after batch
    return chunk_ids
```

---

## Plan 3: Fix VectorStore

### File: `core/vectorstore.py`

**Check**: Verify `save()` and `load()` methods work correctly.

```python
def save(self, index_path: str) -> None:
    """Save index to disk."""
    import json
    import os
    
    os.makedirs(index_path, exist_ok=True)
    
    # Save metadata
    metadata = {
        "documents": self.documents,
        "embeddings": self.embeddings,
        "chunk_map": self.chunk_map
    }
    
    # Write to file
    with open(os.path.join(index_path, "index.json"), 'w') as f:
        json.dump(metadata, f)
    
    logger.info(f"Index saved to {index_path}")

def load(self, index_path: str) -> None:
    """Load index from disk."""
    import json
    
    with open(os.path.join(index_path, "index.json"), 'r') as f:
        data = json.load(f)
    
    self.documents = data["documents"]
    self.embeddings = data["embeddings"]
    self.chunk_map = data["chunk_map"]
```

---

## Plan 4: Fix Bulk Ingest Script

### File: `scripts/bulk_ingest.py`

**Add Verification**:
```python
def main():
    # ... existing code ...
    
    # Add verification step
    logger.info("Verifying ingestion...")
    sources = list_sources(project_id)
    logger.info(f"Found {len(sources)} sources after ingestion")
    
    if len(sources) == 0:
        logger.error("WARNING: No sources found after ingestion!")
        logger.error("Data may not have been persisted correctly.")
        return 1
    
    logger.info(f"Successfully ingested {len(sources)} sources")
    return 0
```

---

## Plan 5: Create Tests

### File: `tests/test_ingestion_persistence.py`

```python
"""Test ingestion persistence."""

import pytest
import tempfile
import shutil
from pathlib import Path

def test_persistence(tmp_path):
    """Test that ingested data persists to disk."""
    from core.semantic_store import SemanticStore
    
    store = SemanticStore(str(tmp_path / "index"))
    
    # Add document
    doc_id = store.add_document({
        "content": "Test document",
        "metadata": {"source": "test"}
    })
    
    # Verify data was persisted
    assert doc_id is not None
    
    # Create new store instance (simulates restart)
    store2 = SemanticStore(str(tmp_path / "index"))
    
    # Data should still be there
    results = store2.search("test")
    assert len(results) > 0
```

---

## Execution Order

1. Reproduce BUG-INGEST-01
2. Trace code flow to identify root cause
3. Fix storage backend commit logic
4. Add verification to bulk_ingest.py
5. Create persistence tests
6. Validate fix works

---

**Plan Status**: Ready for implementation
**Created**: February 1, 2026
