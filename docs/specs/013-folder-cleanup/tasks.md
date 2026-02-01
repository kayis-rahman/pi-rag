# Folder Cleanup - Task Breakdown

**Feature ID**: 013-folder-cleanup
**Status**: [Completed]
**Created**: February 1, 2026
**Last Updated**: February 1, 2026

---

## Task Statistics

| Phase | Tasks | Duration |
|-------|-------|----------|
| 1. Create directories | 3 | 5 minutes |
| 2. Move test files | 6 | 10 minutes |
| 3. Move decision docs | 3 | 10 minutes |
| 4. Move planning docs | 2 | 10 minutes |
| 5. Move archive docs | 2 | 5 minutes |
| 6. Verify | 4 | 10 minutes |
| **Total** | **20/20 tasks (100%)** | **~45 minutes** |

---

## Phase 1: Create Directories (3 tasks)

- [x] 1.1 Create `tests/manual/` directory (Linked to US-1)
- [x] 1.2 Create `docs/decisions/` directory (Linked to US-2)
- [x] 1.3 Create `docs/archive/` directory (Linked to US-3)

**Phase 1 Exit Criteria:** All 3 directories exist

---

## Phase 2: Move Test Files (6 tasks)

- [x] 2.1 `git mv test_analyze_conversation.py tests/manual/` (Linked to US-1)
- [x] 2.2 `git mv test_auto_learning_config.py tests/manual/` (Linked to US-1)
- [x] 2.3 `git mv test_models.py tests/manual/` (Linked to US-1)
- [x] 2.4 `git mv test_onboard.py tests/manual/` (Linked to US-1)
- [x] 2.5 `git mv test_phase3.py tests/manual/` (Linked to US-1)
- [x] 2.6 `git mv rewrite_cli_tests.py tests/manual/` (Linked to US-1)

**Phase 2 Exit Criteria:** All test files moved, git shows renames

---

## Phase 3: Move Decision Documents (3 tasks)

- [x] 3.1 `git mv chromadb_decision_required.md docs/decisions/` (Linked to US-2)
- [x] 3.2 `git mv chromadb_fix_plan.md docs/decisions/` (Linked to US-2)
- [x] 3.3 `git mv chromadb_production_issues.md docs/decisions/` (Linked to US-2)

**Phase 3 Exit Criteria:** All decision documents moved

---

## Phase 4: Move Planning Documents (2 tasks)

- [x] 4.1 `git mv BEADS_REMOVAL_SDD_PLAN.md docs/specs/007-remove-beads/` (Linked to US-3)
- [x] 4.2 `git mv FEATURE_007_COMPLETION_SUMMARY.md docs/specs/007-remove-beads/` (Linked to US-3)

**Phase 4 Exit Criteria:** Planning documents in feature folder

---

## Phase 5: Move Archive Documents (2 tasks)

- [x] 5.1 `git mv SESSION_SUMMARY.md docs/archive/` (Linked to US-4)
- [x] 5.2 `git mv GEMINI.md docs/reference/` (Linked to US-4)

**Phase 5 Exit Criteria:** Archive and reference documents moved

---

## Phase 6: Verification (4 tasks)

- [x] 6.1 Run `git status --short` to verify renames (Linked to Must Have)
- [x] 6.2 Count root files: `ls -1 | wc -l` (should be ~34) (Linked to Must Have)
- [x] 6.3 Check for broken references (Linked to Should Have)
- [x] 6.4 Document final root file count (Linked to Must Have)

**Phase 6 Exit Criteria:** All verifications pass

---

## Verification Commands

```bash
# Check git status (should show R for renames)
git status --short

# Count files in root
ls -1 | wc -l

# Before: 46 files
# After: ~34 files

# Check for broken links to moved files
grep -r "test_analyze_conversation.py\|chromadb_decision_required\|BEADS_REMOVAL" --include="*.md" .

# Verify directories exist
ls -la tests/manual/
ls -la docs/decisions/
ls -la docs/archive/
```

---

**Last Updated**: February 1, 2026
**Status**: Ready for implementation
**Next Phase**: Phase 1 - Create directories
