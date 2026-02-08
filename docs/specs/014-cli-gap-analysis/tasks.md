# Task Breakdown: CLI Gap Analysis & Missing Features

**Feature ID**: 014-cli-gap-analysis  
**Status**: [In Progress]  
**Created**: February 1, 2026  
**Objective**: Implement missing CLI commands (ingest, query) and fix model path

---

## Phase 1: Analysis (15 minutes)

### Phase 1.1: Model Path Analysis
- [ ] 1.1.1 Analyze MCP server code for model path resolution (Linked to US-003)
- [ ] 1.1.2 Document current model path in config (Linked to US-003)
- [ ] 1.1.3 Identify files that need model path fix (Linked to US-003)

---

## Phase 2: Implement Ingest (45 minutes)

### Phase 2.1: Update Ingest Function
- [ ] 2.1.1 Modify `synapse/cli/main.py` ingest function (Linked to US-001)
- [ ] 2.1.2 Add subprocess call to `scripts/bulk_ingest.py` (Linked to US-001)
- [ ] 2.1.3 Add error handling for subprocess (Linked to US-001)

### Phase 2.2: Test Ingest
- [ ] 2.2.1 Test `synapse ingest .` (Linked to US-001)
- [ ] 2.2.2 Test `synapse ingest /path` (Linked to US-001)
- [ ] 2.2.3 Test options: `--project-id`, `--file-type`, `--exclude` (Linked to US-001)

---

## Phase 3: Implement Query (45 minutes)

### Phase 3.1: Update Query Function
- [ ] 3.1.1 Modify `synapse/cli/main.py` query function (Linked to US-002)
- [ ] 3.1.2 Add HTTP call to MCP server (Linked to US-002)
- [1.3 Add error ] 3. handling for server not running (Linked to US-002)

### Phase 3.2: Test Query
- [ ] 3.2.1 Test `synapse query "text"` (Linked to US-002)
- [ ] 3.2.2 Test options: `--top-k`, `--format json` (Linked to US-002)
- [ ] 3.2.3 Test error handling (Linked to US-002)

---

## Phase 4: Fix Model Path (30 minutes)

### Phase 4.1: Update Configuration
- [ ] 4.1.1 Fix model path in `synapse/config.py` (Linked to US-003)
- [ ] 4.1.2 Fix model path in `core/embedding.py` if needed (Linked to US-003)
- [ ] 4.1.3 Verify no hardcoded paths (Linked to US-003)

### Phase 4.2: Verify Model Path
- [ ] 4.2.1 Run `synapse ingest .` (Linked to US-003)
- [ ] 4.2.2 Check for mock embedding warnings (Linked to US-003)
- [ ] 4.2.3 Verify real embeddings are created (Linked to US-003)

---

## Phase 5: Validation & Completion (15 minutes)

### Phase 5.1: Final Testing
- [ ] 5.1.1 Test all 10 CLI commands (Linked to all)
- [ ] 5.1.2 Verify no stub messages (Linked to all)
- [ ] 5.1.3 Check documentation accuracy (Linked to all)

### Phase 5.2: Git Operations
- [ ] 5.2.1 Update docs/specs/index.md (Linked to SDD Protocol)
- [ ] 5.2.2 Commit changes (Linked to SDD Protocol)
- [ ] 5.2.3 Push to remote (Linked to SDD Protocol)

---

## Summary

**Total Tasks**: 24 tasks across 5 phases

**Estimated Time**: ~2.5 hours

**Phases**:
1. **Phase 1**: Analysis (3 tasks)
2. **Phase 2**: Implement Ingest (6 tasks)
3. **Phase 3**: Implement Query (6 tasks)
4. **Phase 4**: Fix Model Path (6 tasks)
5. **Phase 5**: Validation & Completion (3 tasks)

---

**Task Status Legend**:
- [ ] Pending
- [x] Completed

---

**Last Updated**: February 1, 2026  
**Maintainer**: opencode
