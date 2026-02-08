# Feature 014 - CLI Gap Analysis & Missing Features

**Feature ID**: 014-cli-gap-analysis  
**Status**: [In Progress]  
**Created**: February 1, 2026  
**Objective**: Implement missing CLI commands (ingest, query) and fix model path

---

## 📋 Overview

This feature addresses CLI commands that are currently stubs/missing implementation, making the SYNAPSE CLI fully functional.

**Current State**: 2 of 10 CLI commands are stubs (ingest, query)  
**Target State**: All 10 CLI commands fully functional

**Estimated Timeline**: ~3.5 hours (24 tasks across 5 phases)

---

## 🎯 User Stories

### US-001: Functional Ingest Command
**As a** user  
**I want** `synapse ingest <path>` to actually ingest files  
**So that** I don't need to use the underlying script directly

**Acceptance Criteria**:
- [ ] `synapse ingest .` works
- [ ] `synapse ingest /path/to/docs` works
- [ ] Options: `--project-id`, `--file-type`, `--exclude`, `--chunk-size`
- [ ] Progress output during ingestion
- [ ] Success/error reporting

### US-002: Functional Query Command
**As a** user  
**I want** `synapse query "text"` to return results  
**So that** I can search my knowledge base via CLI

**Acceptance Criteria**:
- [ ] `synapse query "question"` returns results
- [ ] Options: `--top-k`, `--format json`
- [ ] Results show source attribution
- [ ] Works when server is running

### US-003: Accurate Model Path
**As a** user  
**I want** the CLI to use the same model path as MCP server  
**So that** real embeddings are created, not mock

**Acceptance Criteria**:
- [ ] Model path from shared configuration
- [ ] Works on Mac (`~/.synapse/models/`)
- [ ] Works on Linux (`~/.synapse/models/`)
- [ ] No mock embedding fallback warnings

---

## 📊 Gap Analysis Matrix

| Command | Status | Priority |
|---------|--------|----------|
| `synapse start` | ✅ Working | - |
| `synapse stop` | ✅ Working | - |
| `synapse status` | ✅ Working | - |
| `synapse ingest` | ❌ Stub | **HIGH** |
| `synapse query` | ❌ Stub | **HIGH** |
| `synapse config` | ✅ Working | - |
| `synapse setup` | ✅ Working | - |
| `synapse onboard` | ✅ Working | - |
| `synapse models list` | ✅ Working | - |
| `synapse models download` | ✅ Working | - |

---

## Root Cause Analysis

### Issue 1: Stub Commands

**Location**: `synapse/cli/main.py` (lines 151-246)

The `ingest` and `query` commands were scaffolded but not fully implemented:

```python
@app.command()
def ingest(...):
    print("ℹ️  Note: Full implementation coming in Phase 1")
    print("  Use: python -m scripts.bulk_ingest <path>")
```

### Issue 2: Model Path Mismatch

```
WARNING: Embedding model file not found: /home/dietpi/models/bge-small-en-v1.5-q8_0.gguf
Falling back to test mode with mock embeddings
```

**Root Cause**: Hardcoded path in `core/embedding.py` vs actual model location

---

## 📝 Notes

**Constraint**: Follow SDD protocol (AGENTS.md)  
**Testing**: Manual testing of all CLI commands  
**Documentation**: Update central index.md when complete  
**Branch**: `feature/014-cli-gap-analysis`

---

**Created**: February 1, 2026  
**Status**: Ready for Implementation  
**Next**: Create plan.md
