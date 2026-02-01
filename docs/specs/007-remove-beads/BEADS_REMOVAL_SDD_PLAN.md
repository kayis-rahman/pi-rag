# SDD Plan Created: Remove Beads & GitHub Fork/PR Workflow

**Feature ID**: 007-remove-beads
**Status**: Planning Complete, Waiting for Approval
**Branch**: `feature/007-remove-beads`
**Created**: January 7, 2026

---

## Overview

I have created a comprehensive Spec-Driven Development (SDD) plan for removing beads (local CLI issue tracking) from the synapse repository and transitioning to standard GitHub Issues + fork/PR workflow.

**Total Tasks**: 66 tasks across 5 phases
**Estimated Effort**: 3-4.5 hours
**Risk Level**: Low to Medium (all operations reversible from backup branch)

---

## What Was Created

### 1. Feature Directory Structure
```
docs/specs/007-remove-beads/
├── requirements.md  (User stories, FRs, NFRs, success criteria)
├── plan.md         (Technical plan, architecture, phases, risks)
└── tasks.md        (66 granular tasks with checkboxes)
```

### 2. SDD Documents

#### requirements.md
- 3 User Stories (contributor, maintainer, GitHub user)
- 6 Functional Requirements (beads removal, migration, documentation)
- 3 Non-Functional Requirements (backwards compatibility, safety, minimal prefixes)
- 4 Constraints (NO history rewrite, minimal prefixes, minimal CONTRIBUTING.md)
- 10 Success Criteria
- Open questions and decisions

#### plan.md
- High-level architecture with 5 phases
- Phase-by-phase implementation plan with commands
- Risk assessment (High/Medium/Low)
- Testing strategy (integration, manual, smoke)
- Rollback plan for each phase
- Timeline estimates (3-4.5 hours total)

#### tasks.md
- 66 tasks organized by phase:
  - Phase 0: Preparation (6 tasks)
  - Phase 1: Issue Migration (5 tasks - deferred)
  - Phase 2: Documentation Updates (14 tasks)
  - Phase 3: Beads Removal (8 tasks)
  - Phase 4: Cleanup & Verification (21 tasks)
  - Final Verification (12 tasks)
- All tasks linked to requirements (FR-XXX)
- Progress tracking checkboxes

### 3. Branch Setup
- ✅ Created `develop` branch from `main`
- ✅ Pushed `develop` to remote
- ✅ Created `feature/007-remove-beads` from `develop`
- ✅ Pushed feature branch to remote
- ✅ Committed SDD plan files (commit `c8deae0`)

### 4. Updated Central Index
- ✅ Added feature 007 to `docs/specs/index.md`
- ✅ Updated "Last Updated" date to January 7, 2026
- ✅ Resolved merge conflicts in index.md

---

## Key Decisions Incorporated

### From User Requirements
1. ✅ **NO git history rewrite** - Keep beads-related commits (C-001 constraint)
2. ✅ **Wait for GitHub Issues** - Deferred until repository is public
3. ✅ **MINIMAL CONTRIBUTING.md** - ~40-45 lines, quick start only
4. ✅ **MINIMAL branch prefixes** - Only `feature/`, `bug/`, `hotfix/`
5. ✅ **DELETE backup files** - Remove after verification (not redundant)

### Branch Workflow
```
main (production) ← develop (integration) ← feature/bug/hotfix (wip)
```

- `main`: Production releases
- `develop`: Integration branch
- `feature/*`: Feature development
- `bug/*`: Bug fixes
- `hotfix/*`: Critical production fixes

### What's NOT Included (Out of Scope)
- Removing beads-related commits from git history
- Creating GitHub Issues now (deferred until public)
- Configuring branch protection rules (future)
- GitHub automation (issue/PR templates, future)

---

## Phase Breakdown

### Phase 0: Preparation & Backup (30 min)
- Export all 86 beads issues to JSON (84 closed + 2 open)
- Create backup branch `backup-before-beads-removal-YYYYMMDD`
- Verify git sync status

### Phase 1: Issue Migration (30 min, Deferred)
- Document 2 open issues for GitHub migration
- Create migration log (beads ID → GitHub Issue mapping)
- Archive all issues in `docs/archive/`
- **NOTE**: Actual GitHub Issues creation deferred until repository is public

### Phase 2: Documentation Updates (1-1.5 hours)
- Update AGENTS.md (remove beads sections, update workflow)
- Update GEMINI.md (remove beads from tech stack)
- Create root CONTRIBUTING.md (minimal, ~40 lines)
- Document branch workflow (minimal prefixes)
- Update all session summaries and spec files

### Phase 3: Beads Removal (30-60 min)
- Stop beads daemon (if running)
- Remove `.beads/` from git tracking
- Delete `.beads/` directory from filesystem
- Delete `beads-sync` remote branch
- Commit removal with descriptive message

### Phase 4: Cleanup & Verification (30-60 min)
- Search for remaining beads references
- Verify documentation builds (`npm run docs:build`)
- Verify CI/CD workflows (no beads errors)
- Test fork + PR workflow with test PR
- Move exports to `docs/archive/`
- Remove backup files
- Final commit and push

---

## Risk Assessment

### Medium Risk
- Removing `.beads/` from git (reversible from backup branch)
- Deleting `beads-sync` branch (reversible from issue exports)

### Low Risk
- Documentation updates (safe, reversible with git revert)
- Deleting backup files (backup branch remains)

**Overall Risk**: Low to Medium - All operations are reversible from backup branch or git history.

---

## Success Criteria

The feature will be successful when:
1. ✅ `.beads/` directory removed from git and filesystem
2. ✅ `beads-sync` remote branch deleted
3. ✅ All beads references removed from documentation
4. ✅ Root CONTRIBUTING.md created with minimal content (~40 lines)
5. ✅ Branch workflow documented with minimal prefixes (feature/, bug/, hotfix/)
6. ✅ Issue export files archived in `docs/archive/`
7. ✅ No beads commands in contribution workflow
8. ✅ Git history preserved (no history rewrite)
9. ✅ Backup files removed after verification
10. ✅ All changes committed and pushed to remote
11. ✅ Documentation builds successfully
12. ✅ CI/CD workflows run without beads errors

---

## What You Need to Do

### 1. Review and Approve Plan
- Review `docs/specs/007-remove-beads/requirements.md` (user stories, FRs)
- Review `docs/specs/007-remove-beads/plan.md` (technical plan)
- Review `docs/specs/007-remove-beads/tasks.md` (66 tasks)
- **Reply to this message**: "Approve" to begin implementation

### 2. Confirm Ready to Proceed
- Are you ready for 3-4.5 hours of implementation?
- Do you want me to execute all phases automatically?
- Or would you prefer to approve each phase individually?

### 3. After Approval
I will:
- Execute Phase 0 (Preparation & Backup)
- Execute Phase 1 (Issue Migration - deferred)
- Execute Phase 2 (Documentation Updates)
- Execute Phase 3 (Beads Removal)
- Execute Phase 4 (Cleanup & Verification)
- Mark tasks complete in `tasks.md` as I go
- Commit and push changes after each phase
- Provide final report with all changes

---

## File Locations

| File | Path | Purpose |
|-------|-------|---------|
| Requirements | `docs/specs/007-remove-beads/requirements.md` | User stories, FRs, success criteria |
| Technical Plan | `docs/specs/007-remove-beads/plan.md` | Implementation phases, commands, risks |
| Task List | `docs/specs/007-remove-beads/tasks.md` | 66 granular tasks with checkboxes |
| SDD Index | `docs/specs/index.md` | Central progress tracking (updated) |
| Feature Branch | `feature/007-remove-beads` | Implementation branch (pushed to remote) |

---

## Next Steps

**WAITING FOR YOUR APPROVAL** to begin implementation.

**Please review the plan documents and reply with one of:**

1. **"Approve"** - Begin all phases automatically (I'll execute everything)
2. **"Approve Phase 0"** - I'll execute Phase 0 (Preparation & Backup), then wait for your approval to continue
3. **"Approve [specific phases]"** - I'll execute only the phases you specify (e.g., "Approve Phase 0, 2")
4. **"Make changes to..."** - I'll update the plan based on your feedback, then await approval

---

## References

- SDD Protocol: `AGENTS.md` - Spec-Driven Development (SDD) Protocol section
- Feature Details: `docs/specs/007-remove-beads/` (requirements.md, plan.md, tasks.md)
- Current Branch: `feature/007-remove-beads` (commit `c8deae0`)

---

**Status**: ✅ Planning Complete, ⏳ Waiting for Approval
**Created By**: AI Assistant
**Date**: January 7, 2026
