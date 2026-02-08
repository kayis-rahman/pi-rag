# Requirements: Rename rag/ to core/ (Feature 018)

**Feature ID**: 018-rename-rag-to-core  
**Status**: Completed  
**Date**: 2026-02-08

---

## Overview

Rename the `rag/` directory to `core/` to better reflect the system's architecture. This aligns with the MCP tool renaming (Feature 016) which uses `sy.*` naming convention.

## User Stories

### US1: Developer Clarity
**As a** developer  
**I want** the package name to reflect its purpose  
**So that** I understand it's the core system, not just RAG functionality

### US2: Consistent Naming
**As a** contributor  
**I want** the codebase to use consistent naming  
**So that** MCP tools (`sy.*`) match the package structure (`core/`)

### US3: Clear Architecture
**As a** new team member  
**I want** clear package organization  
**So that** I can quickly locate core functionality

## Functional Requirements

### FR1: Directory Rename
- Rename `rag/` directory to `core/`
- Preserve git history (use `git mv`)

### FR2: Import Updates
- Update all `from rag.X` imports to `from core.X`
- Update all `import rag` to `import core`
- Update documentation code examples

### FR3: Server Rename
- Rename `rag_server.py` to `synapse_server.py`
- Update entry points in pyproject.toml

### FR4: Documentation Updates
- Update all README references
- Update all spec documents
- Update inline code documentation

## Non-Functional Requirements

### NFR1: No Functionality Changes
- Pure refactoring, no behavior changes
- All existing tests should pass

### NFR2: Clear Migration Path
- Document all changes in CHANGELOG
- Provide migration guide

## Acceptance Criteria

- [x] `rag/` directory renamed to `core/`
- [x] `rag_server.py` renamed to `synapse_server.py`
- [x] All 41 Python files updated with new imports
- [x] All 94 documentation files updated
- [x] pyproject.toml entry points updated
- [x] setup.py console scripts updated
- [x] CHANGELOG.md updated with breaking change notice
- [x] Git tracks renames (not delete+add)

---

**Breaking Change**: Yes - All imports must be updated
