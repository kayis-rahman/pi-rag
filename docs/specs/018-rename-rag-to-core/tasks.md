# Tasks: Rename rag/ to core/

**Feature ID**: 018-rename-rag-to-core  
**Status**: ✅ COMPLETED  
**Date**: 2026-02-08

---

## Phase 1: Setup
- [x] Create feature branch `feature/018-rename-rag-to-core`
- [x] Verify clean working tree

## Phase 2: Rename Operations
- [x] Rename `rag/` directory to `core/`
- [x] Rename `rag_server.py` to `synapse_server.py`
- [x] Verify git tracks as rename (not delete+add)

## Phase 3: Python Import Updates
- [x] Update `from rag.` to `from core.` in all Python files
- [x] Update `import rag` to `import core`
- [x] Update `rag_server` references to `synapse_server`
- [x] Count: 41 files updated

## Phase 4: Documentation Updates
- [x] Update all `rag/` paths to `core/` in docs
- [x] Update inline code references
- [x] Update code block examples
- [x] Count: 94 files updated

## Phase 5: Configuration Updates
- [x] Update pyproject.toml entry points
- [x] Update setup.py console scripts
- [x] Verify no rag references in configs

## Phase 6: Verification
- [x] Verify imports work (tested core/logger)
- [x] Check git status (185 files staged)
- [x] Verify balanced changes (901 insertions, 901 deletions)

## Phase 7: Documentation
- [x] Update CHANGELOG.md with breaking change notice
- [x] Create requirements.md
- [x] Create plan.md
- [x] Create tasks.md (this file)

## Phase 8: Index Update
- [x] Update docs/specs/index.md
- [x] Mark Feature 018 as [Completed]

---

## Summary

| Metric | Value |
|--------|-------|
| Files renamed | 39 |
| Files modified | 185 |
| Import statements | ~200 |
| Documentation refs | ~500 |
| Git insertions | 901 |
| Git deletions | 901 |
| Time taken | ~30 minutes |

**Status**: ✅ MERGED to develop (commit 858e950)
