# Requirements: Complete RAG to Synapse Rebrand (Feature 019)

**Feature ID**: 019-complete-rag-rebrand  
**Status**: In Progress  
**Date**: 2026-02-08  
**Version**: 2.0.0 (Breaking Changes)

---

## Overview

Complete rebrand of the codebase from RAG-centric naming to Synapse branding. This includes renaming classes, environment variables, and all references to align with the new `core/` package structure and `sy.*` MCP tool naming convention.

## User Stories

### US1: Consistent Branding
**As a** developer  
**I want** consistent naming throughout the codebase  
**So that** there is no confusion between RAG (the technique) and Synapse (the product)

### US2: Clear Environment Configuration
**As a** DevOps engineer  
**I want** environment variables prefixed with SYNAPSE_  
**So that** I can easily identify and configure Synapse-specific settings

### US3: Clean Class Names
**As a** contributor  
**I want** class names without redundant prefixes  
**So that** the code is cleaner and more readable

## Functional Requirements

### FR1: Class Renames
- Rename `Orchestrator` → `Orchestrator`
- Rename `MemoryBackend` → `MemoryBackend`
- Rename `TestOrchestrator*` → `TestOrchestrator*`
- Rename `SYNAPSE_HEADER` → `CONTEXT_HEADER`

### FR2: Environment Variable Renames
| Old | New |
|-----|-----|
| `SYNAPSE_DATA_DIR` | `SYNAPSE_DATA_DIR` |
| `SYNAPSE_CONFIG_PATH` | `SYNAPSE_CONFIG_PATH` |
| `SYNAPSE_ENV` | `SYNAPSE_ENV` |
| `SYNAPSE_TEST_MODE` | `SYNAPSE_TEST_MODE` |
| `SYNAPSE_REMOTE_UPLOAD_ENABLED` | `SYNAPSE_REMOTE_UPLOAD_ENABLED` |
| `SYNAPSE_UPLOAD_DIR` | `SYNAPSE_UPLOAD_DIR` |
| `SYNAPSE_UPLOAD_MAX_AGE` | `SYNAPSE_UPLOAD_MAX_AGE` |
| `SYNAPSE_UPLOAD_MAX_SIZE` | `SYNAPSE_UPLOAD_MAX_SIZE` |

### FR3: File Updates
- Update all Python files with class references
- Update all Python files with environment variable references
- Update documentation
- Update configuration files
- Update Docker Compose files

## Non-Functional Requirements

### NFR1: Breaking Change Documentation
- Clear migration guide required
- All breaking changes documented in CHANGELOG
- Version bump to 2.0.0

### NFR2: No Functionality Changes
- Pure renaming, no behavior changes
- All tests must pass after rename

## Acceptance Criteria

- [ ] All classes renamed (2 classes)
- [ ] All environment variables renamed (8 variables)
- [ ] All 23+ env var references updated
- [ ] All 8+ files with class references updated
- [ ] Documentation updated (20+ files)
- [ ] Configuration files updated
- [ ] Migration guide created
- [ ] CHANGELOG updated
- [ ] Version bumped to 2.0.0
- [ ] All tests pass

---

**Breaking Change**: Yes - Major version bump required
