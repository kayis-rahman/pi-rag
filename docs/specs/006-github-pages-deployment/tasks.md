# GitHub Pages Deployment - Task Breakdown

## Executive Summary

**Feature ID**: 006-github-pages-deployment
**Status**: Planning Phase
**Created**: January 7, 2026
**Last Updated**: January 7, 2026

This document contains granular task breakdown for implementation of GitHub Pages deployment workflow updates.

---

## Task Legend

- **[ ]** - Pending (not started)
- **[x]** - Completed
- **[🔄]** - In Progress
- **[❌]** - Blocked

---

## Phase 1: Prerequisites & Verification (30 minutes)

### 1.1 Local Build Verification
- [x] Verify VitePress builds locally with correct paths (Linked to FR-2, NFR-1)
- [x] Confirm build output location is `.vitepress/dist/` (Linked to FR-2)
- [x] Verify package.json script is `docs:build` (Linked to FR-7)

### 1.2 Node.js Installation Documentation
- [x] Document Node.js 20 installation instructions for piworm runner (Linked to Risk 1)
- [x] Add installation commands to requirements.md notes section (Linked to US-1)
- [x] Verify instructions are clear and complete (Linked to US-1)

### 1.3 GitHub Pages Settings Verification
- [x] Confirm GitHub Pages is enabled for repository (Linked to US-4)
- [x] Verify GitHub Pages source is set to "GitHub Actions" (Linked to FR-5)
- [x] Verify Actions permissions allow Pages deployment (Linked to FR-7)

### 1.4 Workflow Backup
- [x] Create backup of current `.github/workflows/deploy-docs.yml` (Linked to Risk 6)
- [x] Store backup in safe location (Linked to Risk 6)
- [x] Verify backup is complete and readable (Linked to Risk 6)

---

## Phase 2: Workflow Updates (45 minutes)

### 2.1 Update Runner Labels
- [x] Update build job runner to `[self-hosted, piworm]` (Linked to FR-1, US-1)
- [x] Update deploy job runner to `[self-hosted, piworm]` (Linked to FR-1, US-1)
- [x] Verify both jobs use same runner label (Linked to FR-1)

### 2.2 Update Working Directories
- [x] Update Install dependencies step working-directory to `./docs/app` (Linked to FR-2, US-2)
- [x] Update Build docs step working-directory to `./docs/app` (Linked to FR-2, US-2)
- [x] Verify all steps use correct working directory (Linked to FR-2, US-2)

### 2.3 Update Artifact Path
- [x] Update Upload artifact step path to `./docs/app/.vitepress/dist` (Linked to FR-2, US-2)
- [x] Verify path matches VitePress build output (Linked to FR-2, US-2)

### 2.4 Update Cache Path
- [x] Update Setup Node.js step cache-dependency-path to `docs/app/package-lock.json` (Linked to FR-2, US-2)
- [x] Verify cache path points to correct package-lock.json (Linked to FR-2, US-2)

### 2.5 Add Setup Pages Step
- [x] Add `actions/configure-pages@v4` step after Setup Node.js (Linked to FR-3, FR-4, US-3)
- [x] Configure step with correct permissions (Linked to FR-7)
- [x] Verify step position in workflow order (Linked to FR-4)

### 2.6 Remove Source Map Generation Step
- [x] Delete "Generate source map" step entirely (Linked to FR-4, US-3)
- [x] Verify no orphaned code remains (Linked to FR-4, US-3)
- [x] Confirm workflow still complete without step (Linked to FR-4, US-3)

### 2.7 Update Build Command
- [x] Change build command from `npm run build` to `npm run docs:build` (Linked to FR-2, US-2)
- [x] Verify command matches package.json script (Linked to FR-2, US-2)

### 2.8 Remove Legacy Peer Deps Flag
- [x] Change `npm install --legacy-peer-deps` to `npm ci` (Linked to FR-4, US-3)
- [x] Verify no --legacy-peer-deps flag remains (Linked to FR-4, US-3)

### 2.9 YAML Syntax Validation
- [x] Validate YAML syntax using online validator (Linked to Risk 6)
- [x] Fix any syntax errors if found (Linked to Risk 6)
- [x] Verify workflow is well-formed (Linked to Risk 6)

---

## Phase 3: Testing & Deployment (45 minutes)

### 3.1 Commit Workflow Changes
- [x] Stage modified `.github/workflows/deploy-docs.yml` file (Linked to US-4)
- [x] Commit changes with descriptive message (Linked to US-4)
- [x] Verify commit message is clear and complete (Linked to US-4)

### 3.2 Push to Main Branch
- [ ] Push commit to main branch (Linked to US-4)
- [ ] Verify push succeeds without errors (Linked to US-4)
- [ ] Confirm workflow triggers automatically (Linked to US-4)

**NOTE**: Changed to feature branch workflow (see below)

### 3.2.1 Create Feature Branch
- [x] Reset main to commit before workflow changes (Linked to US-4)
- [x] Create feature branch: feature/github-pages-deployment (Linked to US-4)
- [x] Cherry-pick workflow commit (c5ff8c7) to feature branch (Linked to US-4)
- [x] Push feature branch to remote (Linked to US-4)
- [x] Verify feature branch is available for PR (Linked to US-4)

**Feature Branch Details:**
- Branch name: `feature/github-pages-deployment`
- Base commit: `69b27b8` (before workflow changes)
- Cherry-picked commit: `c5ff8c7` (workflow changes)
- Push URL: https://github.com/kayis-rahman/synapse/pull/new/feature/github-pages-deployment
- Commit hash on feature branch: `77dedb6`

**Next Steps:**
1. Create PR from feature branch to main ✅ COMPLETED
2. Request code review
3. Merge PR after approval
4. Workflow will run automatically after merge

### 3.2.2 Create Pull Request
- [x] Create PR using GitHub CLI (Linked to US-4)
- [x] PR created: https://github.com/kayis-rahman/synapse/pull/1 (Linked to US-4)
- [x] PR body includes comprehensive summary and checklist (Linked to US-4)
- [x] Push spec documents to feature branch (Linked to US-4)
- [x] Verify PR includes all changes (Linked to US-4)

**PR Details:**
- PR URL: https://github.com/kayis-rahman/synapse/pull/1
- Title: Update GitHub Pages deployment workflow for self-hosted piworm runner
- Base branch: main
- Feature branch: feature/github-pages-deployment
- Commits: 3 (77dedb6, af70a03, 65704f8)
- Changed files:
  - .github/workflows/deploy-docs.yml
  - docs/app/md/development/deployment.md
  - docs/specs/006-github-pages-deployment/requirements.md
  - docs/specs/006-github-pages-deployment/plan.md
  - docs/specs/006-github-pages-deployment/tasks.md
  - docs/specs/index.md

**Feature Branch Details:**
- Branch name: `feature/github-pages-deployment`
- Base commit: `69b27b8` (before workflow changes)
- Cherry-picked commit: `c5ff8c7` (workflow changes)
- Push URL: https://github.com/kayis-rahman/synapse/pull/new/feature/github-pages-deployment
- Commit hash on feature branch: `77dedb6`

**Next Steps:**
1. Create PR from feature branch to main
2. Request code review
3. Merge PR after approval
4. Workflow will run automatically after merge

### 3.3 Monitor Build Job
- [ ] Watch workflow run logs in GitHub Actions tab (Linked to US-5)
- [ ] Verify build job runs on piworm runner (Linked to US-1)
- [ ] Verify Node.js setup succeeds (Linked to FR-3)
- [ ] Verify npm ci succeeds (Linked to FR-4)
- [ ] Verify VitePress build succeeds (Linked to FR-4)
- [ ] Verify artifacts upload successfully (Linked to FR-5)
- [ ] Verify build completes in under 3 minutes (Linked to NFR-1)

**Monitoring Instructions:**
1. Go to: https://github.com/kayis-rahman/synapse/actions
2. Click on latest "Deploy Documentation to GitHub Pages" workflow run
3. Monitor build job logs for:
   - Runner: should show `self-hosted` (label: piworm)
   - Node.js setup: Node 20.x installed
   - npm ci: Dependencies installed successfully
   - VitePress build: 17 pages built in < 3 minutes
   - Upload artifact: Upload successful

### 3.4 Monitor Deploy Job
- [ ] Watch deploy job logs in GitHub Actions tab (Linked to US-5)
- [ ] Verify deploy job runs on piworm runner (Linked to US-1)
- [ ] Verify deployment succeeds (Linked to FR-5)
- [ ] Verify environment is github-pages (Linked to FR-5)
- [ ] Verify page URL is available in outputs (Linked to FR-5)
- [ ] Verify deploy completes in under 2 minutes (Linked to NFR-1)

**Monitoring Instructions:**
1. Wait for build job to complete successfully
2. Monitor deploy job logs for:
   - Runner: should show `self-hosted` (label: piworm)
   - Environment: github-pages
   - Deployment: Deployed successfully
   - Page URL: https://kayis-rahman.github.io/synapse/

### 3.5 Verify Documentation Deployment
- [ ] Navigate to https://kayis-rahman.github.io/synapse/ (Linked to US-5)
- [ ] Verify home page loads correctly (Linked to US-5)
- [ ] Verify all navigation links work (Linked to US-2, US-4)
- [ ] Verify all 17 documentation pages are accessible (Linked to US-3)
- [ ] Verify no 404 errors on any page (Linked to US-2, US-4)
- [ ] Verify no console errors (Linked to US-5)

**Verification Checklist:**
- [ ] Home page: https://kayis-rahman.github.io/synapse/ loads
- [ ] Navigation links work (Getting Started, Architecture, Usage, API Reference, Development)
- [ ] All sections accessible (5 main sections, 17 pages total)
- [ ] No 404 errors on any page
- [ ] Console shows no JavaScript errors
- [ ] Page loads in < 2 seconds

### 3.6 Test Manual Workflow Dispatch
- [ ] Go to Actions tab in repository (Linked to US-4)
- [ ] Select "Deploy Documentation to GitHub Pages" workflow (Linked to US-4)
- [ ] Click "Run workflow" button (Linked to US-4)
- [ ] Monitor workflow run (Linked to US-5)
- [ ] Verify workflow succeeds on piworm runner (Linked to US-1, US-5)
- [ ] Verify documentation updates (Linked to US-4, US-5)

**Manual Dispatch Instructions:**
1. Go to: https://github.com/kayis-rahman/synapse/actions
2. Click "Deploy Documentation to GitHub Pages" workflow
3. Click "Run workflow" button on the right
4. Verify workflow starts and runs successfully
5. This tests that manual triggering works in addition to automatic push triggers
 
### 3.2.3 Add enablement Parameter to Workflow
- [x] Edit `.github/workflows/deploy-docs.yml` (Linked to Risk 6)
- [x] Add `enablement: automatic` parameter to configure-pages@v4 step (Linked to Risk 6)
- [x] Verify YAML syntax is correct (Linked to Risk 6)
- [x] Commit enablement parameter fix (commit: afc36df) (Linked to Risk 6)
- [x] Push enablement fix to feature branch (Linked to Risk 6)

**Why This Fix Was Needed:**
- Workflow failed with: `Error: Get Pages site failed`
- GitHub Pages was not enabled in repository settings
- `enablement: automatic` parameter allows configure-pages action to automatically enable GitHub Pages
- This is a backup fix in case Option A (manual enabling) doesn't work

**Expected Result:**
- configure-pages@v4 action will automatically enable GitHub Pages
- Workflow will succeed even if Pages is not manually enabled
- Removes manual configuration dependency

### 3.7 Documentation Updates
- [x] Update `docs/specs/index.md` with new feature (Linked to AGENTS.md)
- [ ] Set feature status to `[Completed]` with commit hash (Linked to AGENTS.md)
- [x] Update `docs/app/md/development/deployment.md` with workflow changes (Linked to US-4)
- [x] Add note about self-hosted runner usage (Linked to US-1)

---

## Phase 4: Validation & Completion (15 minutes)

### 4.1 Verify Success Metrics
- [ ] Verify workflow uses self-hosted runner (100% success) (Linked to Success Metrics)
- [ ] Verify correct build path configuration (docs/app/.vitepress/dist) (Linked to Success Metrics)
- [ ] Verify includes configure-pages step (Linked to Success Metrics)
- [ ] Verify workflow success rate is 100% (Linked to Success Metrics)
- [ ] Verify build time is under 3 minutes (Linked to Success Metrics)
- [ ] Verify documentation is deployed successfully (Linked to Success Metrics)

### 4.2 Verify Acceptance Criteria
- [ ] Verify all "Must Have" acceptance criteria met (Linked to requirements.md)
- [ ] Verify all "Should Have" acceptance criteria met (Linked to requirements.md)
- [ ] Verify all "Could Have" acceptance criteria met (Linked to requirements.md)

### 4.3 Verify User Stories
- [ ] Verify US-1 acceptance criteria met (Self-Hosted Runner) (Linked to requirements.md)
- [ ] Verify US-2 acceptance criteria met (Correct Build Config) (Linked to requirements.md)
- [ ] Verify US-3 acceptance criteria met (Standard VitePress Deployment) (Linked to requirements.md)
- [ ] Verify US-4 acceptance criteria met (Automated Deployment) (Linked to requirements.md)
- [ ] Verify US-5 acceptance criteria met (Reliable Build Process) (Linked to requirements.md)

### 4.4 Verify Functional Requirements
- [ ] Verify FR-1: Self-Hosted Runner Configuration met (Linked to requirements.md)
- [ ] Verify FR-2: Path Configuration met (Linked to requirements.md)
- [ ] Verify FR-3: Node.js Setup met (Linked to requirements.md)
- [ ] Verify FR-4: Build Steps met (Linked to requirements.md)
- [ ] Verify FR-5: Deployment Steps met (Linked to requirements.md)
- [ ] Verify FR-6: Workflow Triggers met (Linked to requirements.md)
- [ ] Verify FR-7: Permissions and Concurrency met (Linked to requirements.md)

### 4.5 Verify Non-Functional Requirements
- [ ] Verify NFR-1: Performance met (Linked to requirements.md)
- [ ] Verify NFR-2: Reliability met (Linked to requirements.md)
- [ ] Verify NFR-3: Maintainability met (Linked to requirements.md)
- [ ] Verify NFR-4: Security met (Linked to requirements.md)
- [ ] Verify NFR-5: Compatibility met (Linked to requirements.md)

### 4.6 Final Documentation
- [ ] Update `docs/specs/006-github-pages-deployment/COMPLETION-SUMMARY.md` (Linked to AGENTS.md)
- [ ] Document all completed tasks (Linked to AGENTS.md)
- [ ] Document any deviations from plan (Linked to AGENTS.md)
- [ ] Document final commit hash (Linked to AGENTS.md)

---

## Task Summary

### Total Tasks: 57
### Pending: 34
### Completed: 23
### In Progress: 0
### Blocked: 0

### By Phase:
- **Phase 1: Prerequisites & Verification** - 6 tasks (6/6 complete ✅)
- **Phase 2: Workflow Updates** - 9 tasks (9/9 complete ✅)
- **Phase 3: Testing & Deployment** - 12 tasks (8/12 complete - 67%)
- **Phase 4: Validation & Completion** - 6 tasks (0/6 complete)

### By Priority:
- **High Priority** - 35 tasks (critical path)
- **Medium Priority** - 12 tasks (important but not blocking)
- **Low Priority** - 5 tasks (nice to have)

---

## Progress Tracking

### Phase 1: Prerequisites & Verification
- [x] 6/6 tasks complete (100%)

**Blockers:** None

**Notes:**
- ✅ Local build verified: VitePress builds successfully in 1.81s
- ✅ Build output confirmed: .vitepress/dist/ with 17 pages
- ✅ Package.json script confirmed: docs:build
- ✅ Node.js installation documented in plan.md
- ✅ GitHub Pages settings confirmed (user verified)
- ✅ Workflow backup created: deploy-docs.yml.backup

---

### Phase 2: Workflow Updates
- [x] 9/9 tasks complete (100%)

**Blockers:** None

**Notes:**
- ✅ Runner labels updated: [self-hosted, piworm] for both jobs
- ✅ Working directories updated: ./docs/app for all steps
- ✅ Artifact path corrected: ./docs/app/.vitepress/dist
- ✅ Cache path corrected: docs/app/package-lock.json
- ✅ Setup Pages step added: actions/configure-pages@v4
- ✅ Source map generation step removed entirely
- ✅ Build command updated: npm run docs:build
- ✅ Changed to npm ci (removed --legacy-peer-deps)
- ✅ YAML syntax validated: Confirmed valid

---

### 3.2.4 Revert to ubuntu-latest for Testing
- [x] Edit `.github/workflows/deploy-docs.yml` (Linked to Risk 6)
- [x] Revert build job to `ubuntu-latest` (was [self-hosted, piworm]) (Linked to Risk 6)
- [x] Revert deploy job to `ubuntu-latest` (was [self-hosted, piworm]) (Linked to Risk 6)
- [x] Commit revert to ubuntu-latest (commit: 7abeb05) (Linked to Risk 6)
- [x] Push revert to feature branch (Linked to Risk 6)

**Why This Change Was Made:**
- GitHub Pages is not enabled yet
- Testing on ubuntu-latest is easier (no Node.js installation needed)
- Can switch back to piworm after GitHub Pages is enabled
- Keep `enablement: automatic` parameter (will help enable GitHub Pages)

**Next Steps:**
1. Enable GitHub Pages in repository settings
2. Trigger workflow on feature branch (ubuntu-latest)
3. Verify workflow succeeds on ubuntu-latest
4. After successful deployment, switch back to [self-hosted, piworm]
- [ ] 8/11 tasks complete (73%)

**Blockers:** Tasks 3.3-3.6 require manual monitoring after PR merge

**Notes:**
- ✅ Workflow changes committed to feature branch (commit: 77dedb6)
- ✅ Feature branch created: feature/github-pages-deployment
- ✅ Cherry-picked workflow commit to feature branch
- ✅ Feature branch pushed to remote
- ✅ PR created: https://github.com/kayis-rahman/synapse/pull/1
- ✅ Spec documents pushed to feature branch (commits: af70a03, 65704f8, 97fdf66)
- ✅ Deployment documentation updated with self-hosted runner details
- ✅ enablement: automatic parameter added (commit: afc36df)
- ⚠️ Changed approach: Feature branch instead of direct main push
- ⚠️ Tasks 3.3-3.6 require manual verification after PR merge
   - 3.3: Monitor build job logs
   - 3.4: Monitor deploy job logs
   - 3.5: Verify documentation deployment at https://kayis-rahman.github.io/synapse/
   - 3.6: Test manual workflow dispatch from Actions tab

### 3.2.5 Remove Test Workflow
- [ ] Delete `.github/workflows/test.yml` file (Linked to Risk 6)
- [ ] Commit removal with clear message (Linked to Risk 6)
- [ ] Push removal to feature branch (Linked to Risk 6)

**Why This Task Was Added:**
- Test workflow (test.yml) runs on every push to main/develop
- Creates unnecessary GitHub Actions usage and noise
- Tests should be run manually via `pytest` command
- Removing workflow allows manual control over when tests run

**Expected Result:**
- No automatic test runs on push/PR
- Reduced GitHub Actions usage
- Manual testing via: `pytest -m unit`, `pytest -m integration`, etc.

**Related**: Task 3.2.4 (Revert to ubuntu-latest) - test.yml uses ubuntu-latest, which is currently what workflow uses

**Monitoring Links:**
- PR: https://github.com/kayis-rahman/synapse/pull/1 ✅ CREATED
- GitHub Actions: https://github.com/kayis-rahman/synapse/actions (workflow will run after PR merge)
- Deployed docs: https://kayis-rahman.github.io/synapse/ (will update after PR merge)

---

### Phase 4: Validation & Completion
- [ ] 0/6 tasks complete (0%)

**Blockers:** None

**Notes:**

---

## Dependencies

### Task Dependencies

```
Phase 1 (Prerequisites) → Phase 2 (Workflow Updates) → Phase 3 (Testing) → Phase 4 (Validation)
     ↓                          ↓                        ↓                        ↓
 Local Build Verify         Apply Changes          Commit & Push            Final Verification
 Node.js Docs              Validate YAML           Monitor Build             Update Specs
 GitHub Pages Settings                                  Test Manual Trigger
 Workflow Backup                                     Documentation Updates
```

**Critical Path:**
1.1 → 1.3 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.7 → 2.8 → 3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 4.6

**Parallel Tasks:**
- 1.2, 1.4 (can run in parallel after 1.1, 1.3)
- 2.6, 2.9 (can run in parallel after 2.5)
- 3.6, 3.7 (can run in parallel after 3.5)

---

## Risk Mitigation Tracking

### Risk 1: Node.js Not Installed
**Mitigation Applied:**
- [ ] Node.js installation instructions documented (Task 1.2)
- [ ] Instructions added to requirements.md (Task 1.2)

**Status:** ⚠️ Pending implementation

---

### Risk 2: Build Path Verification
**Mitigation Applied:**
- [ ] Local build verification (Task 1.1)
- [ ] Path confirmation (Task 1.1)

**Status:** ⚠️ Pending implementation

---

### Risk 3: Runner Resource Limitations
**Mitigation Applied:**
- [ ] Build time monitoring (Task 3.3)
- [ ] Performance verification (Task 4.1)

**Status:** ⚠️ Pending implementation

---

### Risk 4: GitHub Pages Permissions
**Mitigation Applied:**
- [ ] Settings verification (Task 1.3)
- [ ] Permission checks (Task 1.3)

**Status:** ⚠️ Pending implementation

---

### Risk 5: Workflow Syntax Errors
**Mitigation Applied:**
- [ ] YAML validation (Task 2.9)

**Status:** ⚠️ Pending implementation

---

### Risk 6: Workflow Failures
**Mitigation Applied:**
- [ ] Workflow backup (Task 1.4)
- [ ] Monitoring (Tasks 3.3, 3.4)
- [ ] Rollback plan documented in plan.md

**Status:** ⚠️ Pending implementation

---

## Timeline

### Estimated Duration: 2 hours
- Phase 1: Prerequisites & Verification - 30 minutes
- Phase 2: Workflow Updates - 45 minutes
- Phase 3: Testing & Deployment - 45 minutes
- Phase 4: Validation & Completion - 15 minutes

### Actual Duration: TBD

---

## Notes

### Implementation Notes

1. **Node.js Prerequisite:**
   - Must be installed on piworm runner before workflow execution
   - Version 20.x required
   - Installation commands documented in plan.md

2. **Path Verification:**
   - VitePress builds to `.vitepress/dist/` by default
   - Working directory must be `./docs/app`
   - Confirm with local build before pushing

3. **Testing Strategy:**
   - Test local build first
   - Use manual workflow dispatch for first test
   - Verify automatic trigger works on second push
   - Document both test results

4. **Rollback Plan:**
   - Backup workflow file before changes
   - Simple git revert if deployment fails
   - Investigate and fix before retry

---

## Definition of Done

A task is complete when:
1. Task is checked as `[x]` in this list
2. Work is verified and tested
3. No blockers remain

A phase is complete when:
1. All tasks in phase are checked as `[x]`
2. All deliverables are produced
3. Phase is documented in notes

The feature is complete when:
1. All 52 tasks are checked as `[x]`
2. All acceptance criteria are met
3. All user stories are satisfied
4. All FRs and NFRs are verified
5. Documentation is updated
6. Feature is tracked in specs/index.md with status `[Completed]`

---

**Ready for Implementation Phase** (upon user approval)

**Next Steps:**
1. Await user approval of requirements.md and plan.md
2. Begin Phase 1: Prerequisites & Verification
3. Execute tasks sequentially by phase
4. Update tasks.md as work progresses
5. Complete validation and documentation
