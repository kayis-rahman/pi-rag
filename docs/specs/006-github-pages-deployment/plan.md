# GitHub Pages Deployment - Technical Plan

## Executive Summary

**Feature ID**: 006-github-pages-deployment
**Status**: Planning Phase
**Created**: January 7, 2026

This document defines the technical architecture and implementation details for updating the GitHub Pages deployment workflow to use the self-hosted piworm runner and fixing all configuration issues.

---

## Architecture Overview

### Current Workflow Structure

```
.github/workflows/deploy-docs.yml
├── on: push (main branch, docs/** paths)
├── permissions: contents:read, pages:write, id-token:write
├── concurrency: group: pages, cancel-in-progress: false
├── jobs:
│   ├── build: (ubuntu-latest) ❌
│   │   ├── Checkout
│   │   ├── Setup Node.js
│   │   ├── Install dependencies (wrong dir) ❌
│   │   ├── Generate source map (unnecessary) ❌
│   │   ├── Build docs (wrong command) ❌
│   │   └── Upload artifact (wrong path) ❌
│   └── deploy: (ubuntu-latest) ❌
│       └── Deploy to GitHub Pages
```

### Target Workflow Structure

```
.github/workflows/deploy-docs.yml
├── on: push (main branch, docs/** paths)
├── permissions: contents:read, pages:write, id-token:write
├── concurrency: group: pages, cancel-in-progress: false
├── jobs:
│   ├── build: ([self-hosted, piworm]) ✅
│   │   ├── Checkout
│   │   ├── Setup Node.js (Node 20, cache to docs/app/package-lock.json) ✅
│   │   ├── Setup Pages ✅ (NEW)
│   │   ├── Install dependencies (docs/app directory, npm ci) ✅
│   │   ├── Build docs (npm run docs:build) ✅
│   │   └── Upload artifact (docs/app/.vitepress/dist) ✅
│   └── deploy: ([self-hosted, piworm]) ✅
│       └── Deploy to GitHub Pages
```

---

## Technical Changes

### Change 1: Update Runner Labels (High Priority)

**Location:** Lines 22 and 55 in `.github/workflows/deploy-docs.yml`

**Current:**
```yaml
runs-on: ubuntu-latest
```

**New:**
```yaml
runs-on: [self-hosted, piworm]
```

**Rationale:**
- Reduces reliance on GitHub-hosted runners
- Leverages existing self-hosted infrastructure
- Saves GitHub Actions minutes
- Required by user

**Risk:**
- Runner must have Node.js 20 installed
- Runner resources may differ from ubuntu-latest

---

### Change 2: Update Working Directory (High Priority)

**Location:** Lines 35, 36, 39, 42, 44, 48 in `.github/workflows/deploy-docs.yml`

**Current:**
```yaml
- name: Install dependencies
  working-directory: ./docs
  run: npm install --legacy-peer-deps

- name: Build docs
  working-directory: ./docs
  run: npm run build
```

**New:**
```yaml
- name: Install dependencies
  working-directory: ./docs/app
  run: npm ci

- name: Build docs
  working-directory: ./docs/app
  run: npm run docs:build
```

**Rationale:**
- Matches actual VitePress app location (`docs/app/`)
- Uses package.json scripts correctly (`docs:build` instead of `build`)
- Removes unnecessary `--legacy-peer-deps` flag

---

### Change 3: Update Artifact Path (High Priority)

**Location:** Line 49 in `.github/workflows/deploy-docs.yml`

**Current:**
```yaml
- name: Upload artifact
  uses: actions/upload-pages-artifact@v3
  with:
    path: ./docs/out
```

**New:**
```yaml
- name: Upload artifact
  uses: actions/upload-pages-artifact@v3
  with:
    path: ./docs/app/.vitepress/dist
```

**Rationale:**
- Matches VitePress build output directory
- VitePress builds to `.vitepress/dist/` by default
- Corrects path mismatch

---

### Change 4: Update Node.js Cache Path (High Priority)

**Location:** Line 31 in `.github/workflows/deploy-docs.yml`

**Current:**
```yaml
cache-dependency-path: docs/package-lock.json
```

**New:**
```yaml
cache-dependency-path: docs/app/package-lock.json
```

**Rationale:**
- Points to actual package-lock.json location
- Enables dependency caching for faster builds
- Matches working directory structure

---

### Change 5: Add Setup Pages Step (High Priority)

**Location:** After line 32 in `.github/workflows/deploy-docs.yml`

**Current:**
```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'
    cache-dependency-path: docs/package-lock.json

- name: Install dependencies
```

**New:**
```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'
    cache-dependency-path: docs/app/package-lock.json

- name: Setup Pages
  uses: actions/configure-pages@v4  # NEW STEP

- name: Install dependencies
```

**Rationale:**
- Required step for GitHub Pages deployment
- Configures metadata for Pages
- Follows VitePress best practices
- Required by `actions/deploy-pages@v4`

---

### Change 6: Remove Source Map Generation Step (Medium Priority)

**Location:** Lines 38-40 in `.github/workflows/deploy-docs.yml`

**Current:**
```yaml
- name: Generate source map
  working-directory: ./docs
  run: timeout 10 npm run dev || true
```

**Action:** Delete this entire step

**Rationale:**
- Not required for production deployment
- Wastes runner resources
- Unnecessary timeout pattern
- Not part of standard VitePress deployment

---

### Change 7: Update Build Command (High Priority)

**Location:** Line 43 in `.github/workflows/deploy-docs.yml`

**Current:**
```yaml
run: npm run build
```

**New:**
```yaml
run: npm run docs:build
```

**Rationale:**
- Matches package.json script name
- Standard VitePress build command
- Prevents script not found errors

---

## Data Flow

### Build Job Flow

```
Trigger → Checkout → Setup Node.js → Setup Pages → npm ci → docs:build → Upload Artifact
    ↓              ↓              ↓              ↓         ↓          ↓            ↓
  main/          .github/workflows  configures    installs    builds       uploads .vitepress/
  docs/**        download        Pages         dependencies HTML/CSS/JS    dist/
  deploy-docs.yml
```

### Deploy Job Flow

```
Build Job Success → Deploy to GitHub Pages
                      ↓
                Uploads artifacts
                      ↓
                GitHub Pages publishes
                      ↓
                Live at https://kayis-rahman.github.io/synapse/
```

---

## Dependencies

### Internal Dependencies

| Dependency | Status | Location |
|-----------|---------|----------|
| VitePress config | ✅ Existing | `/docs/app/.vitepress/config.mts` |
| Package.json scripts | ✅ Existing | `/docs/app/package.json` |
| GitHub Pages settings | ✅ Configured | Repository settings |
| Self-hosted runner | ✅ Registered | piworm |

### External Dependencies

| Dependency | Required Version | Status | Installation |
|-----------|------------------|---------|---------------|
| Node.js | 20.x | ❌ Manual | Must install on piworm |
| npm | Latest | ❌ Manual | Included with Node.js |
| GitHub Actions | Latest | ✅ Cloud | Official GitHub service |

---

## Risk Mitigation Strategy

### Risk 1: Node.js Not Installed on piworm

**Impact:** High
**Probability:** High

**Mitigation:**
1. Document Node.js installation as prerequisite in requirements
2. Provide installation instructions in plan
3. Test workflow after Node.js is installed
4. Consider adding Node.js installation step as fallback (optional)

**Installation Instructions:**
```bash
# On piworm runner
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version  # Verify: v20.x.x
npm --version
```

---

### Risk 2: Build Path Verification

**Impact:** High
**Probability:** Medium

**Mitigation:**
1. Verify local build produces output in `.vitepress/dist/`
2. Test workflow with manual dispatch before committing
3. Check artifact upload logs for correct path
4. Verify deployment serves correct files

**Verification Steps:**
```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/docs/app
npm ci
npm run docs:build
ls -la .vitepress/dist/  # Verify output
```

---

### Risk 3: Runner Resource Limitations

**Impact:** Medium
**Probability:** Medium

**Mitigation:**
1. Monitor first build time on piworm
2. Adjust timeouts if necessary (add `timeout-minutes: 10`)
3. Document expected build time variance
4. Keep build simple (no unnecessary steps)

**Expected Metrics:**
- ubuntu-latest: ~2-3 minutes
- piworm: ~3-5 minutes (estimated)

---

### Risk 4: GitHub Pages Permissions

**Impact:** High
**Probability:** Low

**Mitigation:**
1. Verify repository settings allow Pages deployment
2. Check Actions permissions (Settings → Actions → General)
3. Ensure workflow has required permissions (pages:write, id-token:write)
4. Test manual workflow dispatch first

**Permission Checklist:**
- [ ] Repository: Settings → Pages → Source: GitHub Actions
- [ ] Repository: Settings → Actions → General: Workflow permissions: Read and write permissions
- [ ] Workflow: Permissions block correctly set

---

## Implementation Phases

### Phase 1: Prerequisites & Verification (30 minutes)

**Tasks:**
1. Verify VitePress builds locally with correct paths
2. Confirm build output location (`.vitepress/dist/`)
3. Document Node.js installation for piworm runner
4. Verify GitHub Pages settings in repository
5. Backup current workflow file

**Deliverables:**
- Local build verified working
- Node.js installation instructions documented
- GitHub Pages settings confirmed
- Workflow file backed up

---

### Phase 2: Workflow Updates (45 minutes)

**Tasks:**
1. Update runner labels to `[self-hosted, piworm]` (2 locations)
2. Update working directory to `./docs/app` (4 locations)
3. Update artifact path to `./docs/app/.vitepress/dist`
4. Update cache path to `docs/app/package-lock.json`
5. Add `actions/configure-pages@v4` step
6. Remove "Generate source map" step
7. Update build command to `npm run docs:build`
8. Verify YAML syntax

**Deliverables:**
- Updated `.github/workflows/deploy-docs.yml`
- All changes applied
- YAML validated

---

### Phase 3: Testing & Deployment (45 minutes)

**Tasks:**
1. Commit workflow changes to git
2. Push to main branch (triggers auto-build)
3. Monitor workflow run logs
4. Verify build succeeds on piworm runner
5. Verify artifact upload succeeds
6. Verify deployment to GitHub Pages succeeds
7. Test documentation URL: https://kayis-rahman.github.io/synapse/
8. Verify all pages load correctly

**Deliverables:**
- Workflow tested and passing
- Documentation deployed successfully
- All pages accessible via GitHub Pages

---

## Testing Strategy

### Unit Testing (Manual)

**Test Case 1: Local Build Verification**
```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/docs/app
npm ci
npm run docs:build
# Expected: Build succeeds, output in .vitepress/dist/
```

**Test Case 2: YAML Syntax Validation**
```bash
# Use online YAML validator
# Upload deploy-docs.yml to https://www.yamllint.com/
# Expected: No syntax errors
```

### Integration Testing

**Test Case 3: Manual Workflow Dispatch**
1. Go to repository Actions tab
2. Select "Deploy Documentation to GitHub Pages"
3. Click "Run workflow"
4. Monitor build job logs
5. Expected: Build succeeds on piworm runner

**Test Case 4: Automatic Trigger on Push**
1. Make minor documentation change (e.g., edit README.md)
2. Commit and push to main
3. Expected: Workflow triggers automatically
4. Expected: Build and deploy succeed

### System Testing

**Test Case 5: Deployment Verification**
1. Navigate to https://kayis-rahman.github.io/synapse/
2. Expected: Home page loads
3. Click on navigation links
4. Expected: All pages load without 404 errors
5. Check console for errors
6. Expected: No console errors

**Test Case 6: Build Time Verification**
1. Check workflow run duration
2. Expected: < 5 minutes total
3. Expected: Build job < 3 minutes
4. Expected: Deploy job < 2 minutes

---

## Monitoring & Validation

### Success Indicators

**Build Job:**
- ✅ Runner: `self-hosted` (label: piworm)
- ✅ Node.js version: 20.x
- ✅ npm ci succeeds (no --legacy-peer-deps warnings)
- ✅ VitePress build succeeds (17 pages built)
- ✅ Artifacts uploaded successfully

**Deploy Job:**
- ✅ Runner: `self-hosted` (label: piworm)
- ✅ Environment: github-pages
- ✅ Deployment succeeds
- ✅ Page URL available in outputs

**Documentation:**
- ✅ URL accessible: https://kayis-rahman.github.io/synapse/
- ✅ All pages load (17 pages)
- ✅ No 404 errors
- ✅ No console errors
- ✅ Responsive design works

### Failure Indicators

**Build Job Failures:**
- ❌ Runner: `ubuntu-latest` (didn't use piworm)
- ❌ Node.js installation fails
- ❌ npm ci fails
- ❌ VitePress build fails
- ❌ Path errors ("no such file or directory")

**Deploy Job Failures:**
- ❌ Runner: `ubuntu-latest` (didn't use piworm)
- ❌ Artifact upload fails
- ❌ Deployment fails
- ❌ Permissions errors

**Documentation Failures:**
- ❌ URL returns 404
- ❌ Pages return errors
- ❌ Broken links
- ❌ Console errors

---

## Rollback Plan

If deployment fails after changes:

1. **Revert Workflow Changes:**
   ```bash
   git checkout HEAD~1 .github/workflows/deploy-docs.yml
   git commit -m "Rollback: Revert deploy-docs.yml"
   git push
   ```

2. **Verify Old Workflow:**
   - Ensure workflow uses ubuntu-latest
   - Verify build path (even if incorrect)
   - Confirm deployment still works (even with issues)

3. **Investigate Failure:**
   - Check workflow logs
   - Identify specific error
   - Document issue in requirements.md notes

4. **Retry After Fix:**
   - Apply fix based on error analysis
   - Test with manual dispatch
   - Push to trigger auto-build

---

## Documentation Updates

### Files to Update

1. **`docs/specs/index.md`**
   - Add new feature: 006-github-pages-deployment
   - Set status: `[In Progress]`

2. **`docs/app/md/development/deployment.md`**
   - Update GitHub Pages deployment section
   - Add note about self-hosted runner
   - Update workflow trigger description

3. **`docs/specs/006-github-pages-deployment/tasks.md`**
   - Track task completion
   - Mark tasks as `[x]` when done

---

## Performance Targets

| Metric | Target | Rationale |
|--------|---------|-----------|
| Build time | < 3 minutes | Fast feedback loop |
| Deploy time | < 2 minutes | Quick availability |
| Total workflow | < 5 minutes | Efficient CI/CD |
| Success rate | 100% | Zero failures |
| Runner usage | Self-hosted only | Cost savings |

---

## Security Considerations

### Permissions (Minimal Required)

```yaml
permissions:
  contents: read        # Read repository code
  pages: write        # Deploy to GitHub Pages
  id-token: write     # OIDC authentication
```

**No additional permissions needed.**

### Secrets

**No secrets required for this workflow.**

All authentication uses GitHub's built-in OIDC (OpenID Connect) via `id-token: write` permission.

### Best Practices

- ✅ Uses official GitHub Actions only
- ✅ No third-party custom actions
- ✅ Minimal permissions (principle of least privilege)
- ✅ No hardcoded credentials
- ✅ No secrets in workflow files

---

## Troubleshooting Guide

### Issue 1: "Job not found" or "Runner offline"

**Diagnosis:**
```bash
# Check runner status in GitHub
# Repository → Settings → Actions → Runners
```

**Solution:**
1. Verify piworm runner is online
2. Check runner labels: `self-hosted`, `piworm`
3. Restart runner service on piworm if offline

### Issue 2: "node: command not found"

**Diagnosis:**
```bash
# Check runner logs for Node.js installation error
```

**Solution:**
1. Install Node.js 20 on piworm runner (see Prerequisites section)
2. Add Node.js to PATH
3. Verify installation: `node --version`

### Issue 3: "no such file or directory: .vitepress/dist"

**Diagnosis:**
```bash
# Check workflow logs for build output
```

**Solution:**
1. Verify VitePress build succeeded
2. Check working directory path in workflow
3. Ensure artifact path matches build output
4. Test local build to confirm output location

### Issue 4: "Permission denied: pages:write"

**Diagnosis:**
```bash
# Check repository Actions permissions
# Settings → Actions → General
```

**Solution:**
1. Update workflow permissions to "Read and write permissions"
2. Ensure GitHub Pages is enabled
3. Verify workflow has `pages: write` permission

### Issue 5: "Deployment failed: 404"

**Diagnosis:**
```bash
# Check deployment job logs
# Check GitHub Pages settings
```

**Solution:**
1. Verify GitHub Pages source is set to "GitHub Actions"
2. Check deployment URL
3. Ensure artifact upload succeeded
4. Retry deployment

---

## Success Criteria

### Phase 1 Completion
- [ ] Local build verified working
- [ ] Node.js installation instructions documented
- [ ] GitHub Pages settings confirmed
- [ ] Workflow file backed up

### Phase 2 Completion
- [ ] All workflow changes applied
- [ ] YAML syntax validated
- [ ] Changes committed to git

### Phase 3 Completion
- [ ] Workflow runs successfully on piworm runner
- [ ] Build succeeds without errors
- [ ] Artifacts upload successfully
- [ ] Deployment succeeds to GitHub Pages
- [ ] Documentation accessible at URL
- [ ] All pages load correctly

### Feature Completion
- [ ] All acceptance criteria met
- [ ] All user stories satisfied
- [ ] All FRs and NFRs satisfied
- [ ] Success metrics achieved
- [ ] Feature tracked in specs/index.md
- [ ] Documentation updated

---

## Next Steps

1. **Review and Approve Plan**
   - User reviews this technical plan
   - User approves or requests changes
   - Plan finalized

2. **Create Tasks Breakdown**
   - Create `tasks.md` with granular task list
   - Link tasks to requirements
   - Organize by phase

3. **Begin Implementation**
   - Start Phase 1: Prerequisites
   - Follow task checklist
   - Update tasks.md as work progresses

4. **Testing & Validation**
   - Execute Phase 3 testing
   - Verify all success criteria
   - Document results

---

**Document Status**: Ready for Task Breakdown Phase (after approval)

**Next Step**: Awaiting user approval of requirements and plan
