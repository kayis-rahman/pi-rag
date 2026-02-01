# Folder Cleanup - Requirements

**Feature ID**: 013-folder-cleanup
**Status**: [Planning]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026

---

## Overview

Organize scattered files in the project root into proper directories. Currently the root has:
- 13 markdown files (MD)
- 6 Python test files
- Various configuration and script files

This cleanup follows the existing project structure and SDD patterns.

---

## User Stories

### US-1: Organize Test Files
**As a** developer,
**I want** test files in `tests/` directory,
**So that** the project root is clean.

**Acceptance Criteria:**
- [ ] `test_analyze_conversation.py` → `tests/manual/`
- [ ] `test_auto_learning_config.py` → `tests/manual/`
- [ ] `test_models.py` → `tests/manual/`
- [ ] `test_onboard.py` → `tests/manual/`
- [ ] `test_phase3.py` → `tests/manual/`
- [ ] `rewrite_cli_tests.py` → `tests/manual/`

### US-2: Organize Documentation
**As a** documentation maintainer,
**I want** decision documents in `docs/decisions/`,
**So that** documentation is organized by purpose.

**Acceptance Criteria:**
- [ ] `chromadb_decision_required.md` → `docs/decisions/`
- [ ] `chromadb_fix_plan.md` → `docs/decisions/`
- [ ] `chromadb_production_issues.md` → `docs/decisions/`

### US-3: Organize Planning Documents
**As a** project manager,
**I want** planning documents in appropriate spec folders,
**So that** all feature work is self-contained.

**Acceptance Criteria:**
- [ ] `BEADS_REMOVAL_SDD_PLAN.md` → `docs/specs/007-remove-beads/`
- [ ] `FEATURE_007_COMPLETION_SUMMARY.md` → `docs/specs/007-remove-beads/`

### US-4: Archive Old Documents
**As a** archivist,
**I want** session summaries in `docs/archive/`,
**So that** old work doesn't clutter the root.

**Acceptance Criteria:**
- [ ] `SESSION_SUMMARY.md` → `docs/archive/`
- [ ] `GEMINI.md` → `docs/reference/`

---

## Files to Move

| Current Location | New Location | Priority |
|-----------------|--------------|----------|
| `test_analyze_conversation.py` | `tests/manual/` | HIGH |
| `test_auto_learning_config.py` | `tests/manual/` | HIGH |
| `test_models.py` | `tests/manual/` | HIGH |
| `test_onboard.py` | `tests/manual/` | HIGH |
| `test_phase3.py` | `tests/manual/` | HIGH |
| `rewrite_cli_tests.py` | `tests/manual/` | HIGH |
| `chromadb_decision_required.md` | `docs/decisions/` | MEDIUM |
| `chromadb_fix_plan.md` | `docs/decisions/` | MEDIUM |
| `chromadb_production_issues.md` | `docs/decisions/` | MEDIUM |
| `BEADS_REMOVAL_SDD_PLAN.md` | `docs/specs/007-remove-beads/` | MEDIUM |
| `FEATURE_007_COMPLETION_SUMMARY.md` | `docs/specs/007-remove-beads/` | MEDIUM |
| `SESSION_SUMMARY.md` | `docs/archive/` | LOW |
| `GEMINI.md` | `docs/reference/` | LOW |

**Total: 12 files to move**

---

## Files to Keep in Root

These essential files should remain in the root:

| File | Reason |
|------|--------|
| `AGENTS.md` | Critical for AI agent behavior |
| `README.md` | Standard practice |
| `CONTRIBUTING.md` | Standard practice |
| `Dockerfile` | Docker configuration |
| `docker-compose.mcp.yml` | Docker configuration |
| `pyproject.toml` | Poetry project configuration |
| `requirements.txt` | Dependencies |
| `pytest.ini` | Pytest configuration |
| `VERSION` | Version file |
| `start_http_server.sh` | Startup script |

---

## Directories to Create

| Directory | Purpose |
|-----------|---------|
| `tests/manual/` | Manual test scripts (not automated) |
| `docs/decisions/` | Architecture decision records |
| `docs/archive/` | Archived session documents |

---

## Success Criteria

### Must Have
- [ ] All 12 files moved to proper directories
- [ ] Root folder has < 35 items (currently 46)
- [ ] No broken links after moves
- [ ] Git history preserved (mv, not cp+rm)

### Should Have
- [ ] Update any relative paths in moved files
- [ ] Update any documentation referencing moved files

---

## Timeline

| Phase | Duration |
|-------|----------|
| 1. Create directories | 5 minutes |
| 2. Move test files | 10 minutes |
| 3. Move decision docs | 10 minutes |
| 4. Move planning docs | 10 minutes |
| 5. Move archive docs | 5 minutes |
| 6. Verify and test | 10 minutes |
| **Total** | **~50 minutes** |

---

**Created**: February 1, 2026
**Status**: Ready for implementation
