# Folder Cleanup - Technical Plan

**Feature ID**: 013-folder-cleanup
**Status**: [Planning]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026

---

## Implementation Strategy

Use `git mv` to preserve history, create target directories, and move files.

---

## Plan 1: Create Directories

```bash
# Create directories if they don't exist
mkdir -p tests/manual/
mkdir -p docs/decisions/
mkdir -p docs/archive/
```

---

## Plan 2: Move Test Files

Use `git mv` to preserve git history:

```bash
# Move test files to tests/manual/
git mv test_analyze_conversation.py tests/manual/
git mv test_auto_learning_config.py tests/manual/
git mv test_models.py tests/manual/
git mv test_onboard.py tests/manual/
git mv test_phase3.py tests/manual/
git mv rewrite_cli_tests.py tests/manual/
```

---

## Plan 3: Move Decision Documents

```bash
# Create docs/decisions/ and move ChromaDB documents
mkdir -p docs/decisions/
git mv chromadb_decision_required.md docs/decisions/
git mv chromadb_fix_plan.md docs/decisions/
git mv chromadb_production_issues.md docs/decisions/
```

---

## Plan 4: Move Planning Documents

```bash
# Move to existing feature spec folder
git mv BEADS_REMOVAL_SDD_PLAN.md docs/specs/007-remove-beads/
git mv FEATURE_007_COMPLETION_SUMMARY.md docs/specs/007-remove-beads/
```

---

## Plan 5: Archive Documents

```bash
# Create docs/archive/ and move session documents
mkdir -p docs/archive/
git mv SESSION_SUMMARY.md docs/archive/

# Move to docs/reference/
git mv GEMINI.md docs/reference/
```

---

## Post-Move Verification

After moving files, verify:

1. **Git status shows only renames (not delete + add):**
   ```bash
   git status --short
   ```

2. **No broken links in markdown files:**
   ```bash
   # Check for references to moved files
   grep -r "test_analyze_conversation.py" --include="*.md" .
   grep -r "chromadb_decision_required.md" --include="*.md" .
   ```

3. **Root directory count reduced:**
   ```bash
   ls -1 | wc -l
   # Before: 46
   # After: ~34
   ```

---

## Files to Keep (Not Moved)

| File | Reason |
|------|--------|
| `AGENTS.md` | Critical for AI agent behavior |
| `README.md` | Standard documentation |
| `CONTRIBUTING.md` | Standard documentation |
| `Dockerfile` | Docker configuration |
| `docker-compose.mcp.yml` | Docker configuration |
| `pyproject.toml` | Poetry project configuration |
| `requirements.txt` | Dependencies |
| `pytest.ini` | Pytest configuration |
| `VERSION` | Version file |
| `start_http_server.sh` | Startup script |
| `pyproject.toml` | Poetry project configuration |

---

## Rollback Plan

If something goes wrong, revert with:

```bash
# Undo all moves
git reset --hard HEAD
```

Or undo specific moves:

```bash
# Example: Undo moving a test file
git mv tests/manual/test_analyze_conversation.py .
```

---

**Plan Status**: Ready for implementation
**Created**: February 1, 2026
