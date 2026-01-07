# GitHub Pages Deployment - Requirements Specification

## Executive Summary

**Feature ID**: 006-github-pages-deployment
**Status**: Planning Phase
**Created**: January 7, 2026

**Objective**: Update the GitHub Pages deployment workflow to use the self-hosted piworm runner, fix build path configuration, and ensure reliable automated deployment of VitePress documentation.

---

## Problem Statement

### Current State

**Workflow Issues:**
1. ❌ Uses GitHub-hosted runner (`ubuntu-latest`) instead of self-hosted `piworm` runner
2. ❌ Incorrect build path: `./docs/out` (actual path is `./docs/app/.vitepress/dist`)
3. ❌ Wrong working directory: `./docs` (should be `./docs/app`)
4. ❌ Missing required `actions/configure-pages@v4` step
5. ❌ Unnecessary "Generate source map" step that doesn't contribute to production build
6. ❌ Uses `--legacy-peer-deps` flag unnecessarily

**Runner Constraints:**
- Self-hosted runner `piworm` has nothing installed (no Node.js, npm, etc.)
- Runner is registered and active in repository
- GitHub Pages is enabled for repository with GitHub Actions as source

**Impact:**
- Deployment workflow fails due to incorrect paths
- Cannot leverage self-hosted runner for faster builds
- Workflow not following VitePress best practices
- Unnecessary build steps wasting runner resources

### Solution

Update `.github/workflows/deploy-docs.yml` to:
1. Use `[self-hosted, piworm]` runner
2. Fix all directory paths to match actual VitePress structure
3. Add `actions/configure-pages@v4` step
4. Remove unnecessary steps
5. Handle Node.js installation on self-hosted runner

---

## User Stories

### US-1: Developer Wants Self-Hosted Runner for Cost Savings

**As a** developer maintaining SYNAPSE documentation
**I want** the deployment workflow to use the self-hosted piworm runner
**So that** I can save GitHub Actions minutes and leverage local build resources

**Acceptance Criteria:**
- [ ] Workflow uses `runs-on: [self-hosted, piworm]`
- [ ] Both build and deploy jobs use self-hosted runner
- [ ] Workflow completes successfully on piworm runner
- [ ] No dependency on GitHub-hosted ubuntu-latest runner

**Priority:** High

---

### US-2: Developer Wants Correct Build Configuration

**As a** developer
**I want** the workflow to use correct paths matching the VitePress structure
**So that** builds complete successfully without errors

**Acceptance Criteria:**
- [ ] Working directory set to `./docs/app`
- [ ] Build artifacts path set to `./docs/app/.vitepress/dist`
- [ ] Package cache path set to `docs/app/package-lock.json`
- [ ] Build command uses `npm run docs:build` matching package.json
- [ ] No path-related build errors

**Priority:** High

---

### US-3: Developer Wants Standard VitePress Deployment

**As a** developer
**I want** the workflow to follow VitePress deployment best practices
**So that** I can rely on official VitePress recommendations and community support

**Acceptance Criteria:**
- [ ] Includes `actions/configure-pages@v4` step
- [ ] Uses standard VitePress build command
- [ ] Uses `npm ci` instead of `npm install`
- [ ] No unnecessary or experimental steps
- [ ] Follows official VitePress deployment guide

**Priority:** High

---

### US-4: Developer Wants Automated Deployment on Push

**As a** developer pushing documentation updates
**I want** the workflow to automatically deploy to GitHub Pages
**So that** I don't need to manually deploy after each change

**Acceptance Criteria:**
- [ ] Workflow triggers on push to `main` branch
- [ ] Workflow triggers on changes to `docs/**` directory
- [ ] Workflow triggers on workflow dispatch (manual)
- [ ] Workflow runs successfully on every push
- [ ] Documentation updates are live within 5 minutes

**Priority:** Medium

---

### US-5: Developer Wants Reliable Build Process

**As a** developer
**I want** the build to complete reliably every time
**So that** I don't have to debug workflow failures

**Acceptance Criteria:**
- [ ] Build succeeds with 100% success rate
- [ ] No intermittent failures
- [ ] Clear error messages if build fails
- [ ] Build completes in under 3 minutes
- [ ] Artifacts upload and deploy successfully

**Priority:** High

---

## Functional Requirements

### FR-1: Self-Hosted Runner Configuration
- Workflow must specify `runs-on: [self-hosted, piworm]` for all jobs
- Build job must run on piworm runner
- Deploy job must run on piworm runner
- Both jobs must depend on previous step completion

### FR-2: Path Configuration
- Working directory: `./docs/app` (not `./docs`)
- Build output path: `./docs/app/.vitepress/dist` (not `./docs/out`)
- Cache path: `docs/app/package-lock.json`
- Artifact upload path: `./docs/app/.vitepress/dist`

### FR-3: Node.js Setup
- Use `actions/setup-node@v4` action
- Specify Node.js version 20 (matching current config)
- Configure npm cache with correct package-lock.json path

### FR-4: Build Steps
- Checkout code using `actions/checkout@v4`
- Setup Node.js using `actions/setup-node@v4`
- Configure Pages using `actions/configure-pages@v4`
- Install dependencies using `npm ci`
- Build docs using `npm run docs:build`
- Upload artifacts using `actions/upload-pages-artifact@v3`

### FR-5: Deployment Steps
- Deploy using `actions/deploy-pages@v4`
- Configure environment: `github-pages`
- Expose page URL in outputs
- Depend on build job completion

### FR-6: Workflow Triggers
- Trigger on push to `main` branch
- Trigger on changes to `docs/**` directory
- Trigger on changes to `.github/workflows/deploy-docs.yml`
- Allow manual trigger via `workflow_dispatch`

### FR-7: Permissions and Concurrency
- Set `contents: read` permission
- Set `pages: write` permission
- Set `id-token: write` permission
- Configure concurrency group: "pages"
- Disable concurrent cancellation: `cancel-in-progress: false`

---

## Non-Functional Requirements

### NFR-1: Performance
- Build time: < 3 minutes on piworm runner
- Artifact upload: < 30 seconds
- Deployment time: < 2 minutes
- Total workflow time: < 5 minutes

### NFR-2: Reliability
- 100% successful builds (no failures due to configuration)
- Zero false-positive failures
- Clear error messages for genuine failures
- Automatic retry on transient failures (if applicable)

### NFR-3: Maintainability
- Workflow follows standard VitePress deployment pattern
- Well-commented YAML
- Clear step names
- No custom or experimental actions

### NFR-4: Security
- Uses official GitHub Actions (no third-party custom actions)
- Minimal required permissions
- No secrets or credentials exposed
- Follows GitHub Pages security best practices

### NFR-5: Compatibility
- Compatible with Node.js 20
- Compatible with VitePress 1.6.4
- Compatible with GitHub Pages static site deployment
- Compatible with self-hosted runner architecture

---

## Out of Scope

The following are explicitly OUT OF SCOPE for this feature:

- Installing Node.js on piworm runner (assumes manual installation or prerequisite)
- Runner maintenance or monitoring
- Multi-environment deployment (only GitHub Pages)
- Custom deployment scripts or actions
- CDN configuration or optimization
- Custom domain configuration for GitHub Pages
- Analytics integration for documentation
- Automated testing of deployed documentation
- Preview deployments for pull requests

---

## Constraints

### Technical Constraints
- Must use existing GitHub Actions: checkout@v4, setup-node@v4, configure-pages@v4, upload-pages-artifact@v3, deploy-pages@v4
- Must use VitePress standard build output directory (`.vitepress/dist`)
- Must use Node.js 20 (matching package.json)
- Must use piworm self-hosted runner (no ubuntu-latest fallback)

### Runner Constraints
- Self-hosted runner `piworm` requires Node.js 20 to be pre-installed and added to PATH
- Runner has no dependencies installed (assumes manual setup)
- Runner resources may differ from GitHub-hosted runners
- Runner may have different network connectivity

### Time Constraints
- Target completion: 2 hours (quick fix)
- Maximum phases: 3 (Plan, Implement, Test)

### Workflow Constraints
- Cannot use ubuntu-latest runner (must use piworm)
- Cannot create multiple deployment targets
- Cannot add complex conditional logic

---

## Dependencies

### Internal Dependencies
- Existing VitePress configuration in `/docs/app/.vitepress/config.mts`
- Package configuration in `/docs/app/package.json`
- Current workflow file at `.github/workflows/deploy-docs.yml`
- GitHub Pages repository settings (already configured)

### External Dependencies
- Node.js 20 (must be installed on piworm runner)
- npm package manager
- GitHub Actions infrastructure
- GitHub Pages service

### Prerequisites
- Node.js 20 installed on piworm runner and added to PATH
- piworm runner registered and active in repository
- GitHub Pages enabled for repository with GitHub Actions as source
- Repository has write permissions for Pages deployment

---

## Risks

### Risk 1: Node.js Not Installed on piworm Runner

**Description**: piworm runner has nothing installed, including Node.js

**Probability**: High
**Impact**: High (workflow will fail immediately)

**Mitigation**:
- Document Node.js installation as prerequisite
- Provide instructions for manual installation on piworm
- Consider adding Node.js installation step in workflow (fallback)
- Test workflow after Node.js is installed

### Risk 2: Path Configuration Issues

**Description**: Incorrect paths may still exist after update

**Probability**: Medium
**Impact**: High (build fails)

**Mitigation**:
- Verify paths with local build test
- Double-check all path references in workflow
- Test workflow manually before relying on auto-trigger

### Risk 3: Self-Hosted Runner Resource Limitations

**Description**: piworm runner may have limited CPU/memory affecting build time

**Probability**: Medium
**Impact**: Medium (slower builds or timeouts)

**Mitigation**:
- Monitor build time on first run
- Adjust timeouts if necessary
- Document expected build time variance

### Risk 4: GitHub Pages Permissions Issues

**Description**: Permissions may be incorrectly configured for self-hosted runner

**Probability**: Low
**Impact**: High (deployment fails)

**Mitigation**:
- Verify repository settings allow self-hosted runner Pages deployment
- Check Actions permissions in repository settings
- Use official GitHub documentation for permissions

### Risk 5: Workflow Syntax Errors

**Description**: YAML syntax errors in updated workflow

**Probability**: Low
**Impact**: High (workflow doesn't run)

**Mitigation**:
- Validate YAML syntax using online validator
- Test workflow with manual dispatch
- Review changes carefully before committing

---

## Acceptance Criteria Summary

### Must Have (High Priority)
- [ ] Workflow uses `[self-hosted, piworm]` runner for both jobs
- [ ] All paths corrected to match VitePress structure (`docs/app/.vitepress/dist`)
- [ ] Includes `actions/configure-pages@v4` step
- [ ] Uses `npm ci` instead of `npm install --legacy-peer-deps`
- [ ] Removes unnecessary "Generate source map" step
- [ ] Workflow completes successfully
- [ ] Documentation deploys to GitHub Pages

### Should Have (Medium Priority)
- [ ] Workflow triggers on push to main branch
- [ ] Workflow allows manual trigger via workflow_dispatch
- [ ] Workflow completes in under 5 minutes
- [ ] Clear step names and comments in YAML

### Could Have (Low Priority)
- [ ] Build time metrics logged
- [ ] Custom success/failure notifications
- [ ] Deployment URL exposed in workflow summary

---

## Definition of Done

A task is considered complete when:
1. All acceptance criteria for the task are met
2. Workflow YAML is syntactically valid
3. Workflow runs successfully on piworm runner
4. Documentation is deployed to GitHub Pages
5. Changes are committed to git
6. Workflow is tested with both manual and auto-trigger

The feature is complete when:
1. All user stories have their acceptance criteria met
2. Workflow runs successfully on piworm runner
3. Documentation deploys correctly to GitHub Pages
4. All FRs and NFRs are satisfied
5. Feature is tracked in `docs/specs/index.md`

---

## Success Metrics Dashboard

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Workflow uses self-hosted runner | Yes | No | 🔴 Not Started |
| Correct build path configuration | docs/app/.vitepress/dist | docs/out | 🔴 Not Started |
| Includes configure-pages step | Yes | No | 🔴 Not Started |
| Workflow success rate | 100% | Unknown | 🔴 Not Started |
| Build time | < 3 min | Unknown | 🔴 Not Started |
| Documentation deployed | Yes | No | 🔴 Not Started |

---

## Related Features

- **005-vitepress-simple-docs**: VitePress documentation system (documentation to be deployed)
- **001-comprehensive-test-suite**: Test suite (may include documentation tests)
- **002-auto-learning**: Automatic learning (referenced in documentation)

---

## Notes

### Key Decisions
1. **Self-Hosted Runner Only**: No fallback to ubuntu-latest, must use piworm exclusively
2. **Standard VitePress Pattern**: Follow official VitePress deployment guide exactly
3. **Minimal Changes**: Only fix what's broken, don't add unnecessary complexity
4. **Node.js Prerequisite**: Assume Node.js 20 is installed on piworm, document as prerequisite

### Workflow Structure
- Keep two-job structure (build + deploy) for clarity
- Maintain permissions configuration
- Keep concurrency settings
- Preserve workflow triggers

### Testing Strategy
- Test local build first to verify paths
- Test manual workflow dispatch
- Monitor first auto-triggered build on push
- Verify documentation is accessible after deployment

---

**Document Status**: Ready for Technical Planning Phase

**Next Step**: Create `plan.md` with technical architecture and implementation details
