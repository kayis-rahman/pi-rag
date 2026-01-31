# Technical Plan: CLI Manual Testing, Bug Fixes, Test Coverage & VitePress Documentation

**Feature ID**: 007-cli-manual-testing-and-docs
**Created**: January 7, 2026
**Status**: [In Progress]

---

## Architecture Overview

### Current State
```
CLI Structure:
synapse/
└── cli/
    ├── main.py           # Entry point (typer app)
    └── commands/
        ├── start.py      # Server operations
        ├── stop.py       # Server operations
        ├── status.py     # Health checks
        ├── ingest.py     # Data ingestion
        ├── query.py      # Search operations
        ├── setup.py      # Initialization
        ├── onboard.py    # Interactive setup
        └── models.py     # Model management
```

### Test Structure
```
tests/
├── unit/
│   └── cli/
│       ├── test_cli_start.py    # 8 tests
│       ├── test_cli_stop.py     # 6 tests
│       ├── test_cli_status.py   # 8 tests
│       ├── test_cli_models.py   # 10 tests
│       ├── test_cli_setup.py    # 10 tests
│       ├── test_cli_onboard.py  # 10 tests
│       ├── test_cli_ingest.py   # ? tests
│       └── test_cli_query.py    # ? tests
├── integration/
│   └── test_cli_integration.py
└── e2e/
    └── test_cli_workflows.py
```

---

## Phase 1: Manual CLI Testing (2-3 hours)

### 1.1 Test Environment Setup
**Tasks**:
- Create test results tracking file
- Verify Python 3.8+ available
- Verify typer and CLI dependencies installed
- Set up test data directories (sample files for ingest)

**Artifacts**:
- `docs/specs/007-cli-manual-testing-and-docs/MANUAL_TEST_RESULTS.md`

### 1.2 Main Commands Testing (8 commands)

#### Command 1: `start`
**Test Cases**:
1. Native mode start: `python -m synapse.cli.main start`
2. Native mode with custom port: `python -m synapse.cli.main start --port 8080`
3. Docker mode start: `python -m synapse.cli.main start --docker`
4. Docker mode with custom port: `python -m synapse.cli.main start -d -p 9000`
5. Verify server health endpoint: `curl http://localhost:8002/health`
6. Check process persistence (background execution)

**Expected Behavior**:
- Server starts without errors
- Port is correctly configured
- Health endpoint returns 200
- Process runs in background
- Appropriate error messages for failures

#### Command 2: `stop`
**Test Cases**:
1. Stop running native server: `python -m synapse.cli.main stop`
2. Stop running Docker server
3. Stop when no server running
4. Verify cleanup (no zombie processes)

**Expected Behavior**:
- Server stops gracefully
- Docker container stopped
- Clean exit when already stopped
- No errors in logs

#### Command 3: `status`
**Test Cases**:
1. Brief status: `python -m synapse.cli.main status`
2. Verbose status: `python -m synapse.cli.main status --verbose`
3. Status with server stopped
4. Status with server running
5. Check configuration display
6. Verify health check integration

**Expected Behavior**:
- Shows environment, data dirs, models status
- Server status detected (running/stopped)
- Verbose mode shows full config
- Clear output formatting

#### Command 4: `ingest`
**Test Cases**:
1. Ingest single file: `python -m synapse.cli.main ingest /path/to/file.txt`
2. Ingest directory: `python -m synapse.cli.main ingest /path/to/dir/`
3. With custom project: `python -m synapse.cli.main ingest file.txt -p test-project`
4. Code mode: `python -m synapse.cli.main ingest code/ -c`
5. Custom chunk size: `python -m synapse.cli.main ingest file.txt --chunk-size 1000`
6. Ingest non-existent file (error handling)
7. Ingest unsupported file type (error handling)

**Expected Behavior**:
- Files processed correctly
- Project ID applied
- Chunk size respected
- Appropriate error messages
- Progress feedback shown

#### Command 5: `query`
**Test Cases**:
1. Simple query: `python -m synapse.cli.main query "test search"`
2. With top-k: `python -m synapse.cli.main query "test" -k 5`
3. JSON format: `python -m synapse.cli.main query "test" -f json`
4. Text format: `python -m synapse.cli.main query "test" -f text`
5. Different modes: `python -m synapse.cli.main query "test" -m code`
6. Query with no results (edge case)

**Expected Behavior**:
- Returns relevant results
- Top-k limit respected
- Format output correctly (JSON or text)
- Mode applied appropriately
- Clear message for no results

#### Command 6: `config`
**Test Cases**:
1. Basic config display: `python -m synapse.cli.main config`
2. Verbose config: `python -m synapse.cli.main config --verbose`
3. Verify all settings shown
4. Check formatting readability

**Expected Behavior**:
- Shows current configuration
- Verbose mode shows all details
- Structured and readable output

#### Command 7: `setup`
**Test Cases**:
1. Fresh setup: `python -m synapse.cli.main setup`
2. Force setup: `python -m synapse.cli.main setup --force`
3. Offline mode: `python -m synapse.cli.main setup --offline`
4. Skip model check: `python -m synapse.cli.main setup --no-model-check`
5. Setup when already configured
6. Verify directory creation
7. Verify config file generation

**Expected Behavior**:
- Directories created
- Config file generated
- Model download (if needed)
- Appropriate messages for each step
- Skips correctly when already set up

#### Command 8: `onboard`
**Test Cases**:
1. Interactive mode: `python -m synapse.cli.main onboard`
2. Quick mode: `python -m synapse.cli.main onboard --quick`
3. Silent mode: `python -m synapse.cli.main onboard --silent -p test`
4. Skip test: `python -m synapse.cli.main onboard --skip-test`
5. Skip ingest: `python -m synapse.cli.main onboard --skip-ingest`
6. Offline mode: `python -m synapse.cli.main onboard --offline`
7. Verify each step completes

**Expected Behavior**:
- Interactive prompts in interactive mode
- All defaults in quick mode
- No prompts in silent mode
- Appropriate skips with flags
- Complete workflow execution

### 1.3 Models Subcommands Testing (4 commands)

#### Command 9: `models list`
**Test Cases**:
1. List all models: `python -m synapse.cli.main models list`
2. Verify embedding model shown
3. Check format (table or list)

#### Command 10: `models download`
**Test Cases**:
1. Download valid model: `python -m synapse.cli.main models download bge-m3`
2. Download with force: `python -m synapse.cli.main models download bge-m3 --force`
3. Download invalid model (error handling)

#### Command 11: `models verify`
**Test Cases**:
1. Verify installed model: `python -m synapse.cli.main models verify`
2. Verify with corrupted model (error handling)

#### Command 12: `models remove`
**Test Cases**:
1. Remove existing model: `python -m synapse.cli.main models remove bge-m3`
2. Remove non-existent model (error handling)
3. Verify cleanup

---

## Phase 2: Bug Documentation & Fixes (1-2 hours)

### 2.1 Bug Tracking
**Tasks**:
- Create `BUG_TRACKER.md` in spec directory
- Document each bug found:
  - Bug ID (BUG-001, BUG-002, ...)
  - Command affected
  - Description
  - Reproduction steps
  - Expected vs Actual behavior
  - Severity (critical/high/medium/low)
  - Status (new/investigating/fixed/can't reproduce)

**Artifact**: `docs/specs/007-cli-manual-testing-and-docs/BUG_TRACKER.md`

### 2.2 Bug Fix Process
**For each bug**:
1. Analyze root cause
2. Implement fix in production code
3. Test fix manually
4. Add regression test
5. Update bug tracker
6. Document any breaking changes

**Fix Categories**:
- **Critical**: Server crashes, data loss, security issues
- **High**: Major functionality broken, bad UX
- **Medium**: Minor functionality issues, edge cases
- **Low**: Cosmetic issues, documentation errors

---

## Phase 3: Test Coverage Enhancement (2-3 hours)

### 3.1 Test Gap Analysis
**Tasks**:
- Compare manual test coverage with existing tests
- Identify missing test cases
- Identify outdated tests
- Plan new test additions

### 3.2 Test Additions
**For each command**:
1. Add tests for missing functionality
2. Update tests for bug fixes
3. Add edge case tests
4. Add error handling tests
5. Ensure proper fixtures and mocks

**Test Standards**:
- Use pytest fixtures for shared setup
- Use typer.testing.CliRunner for CLI tests
- Mock external dependencies (subprocess, network)
- Clean up after tests
- Add docstrings to test functions
- Mark tests with @pytest.mark.unit or @pytest.mark.integration

### 3.3 Integration Tests
**New integration tests**:
1. Start → Status → Stop workflow
2. Setup → Ingest → Query workflow
3. Models list → download → verify → remove workflow
4. Onboard → Status → Start workflow

### 3.4 Test Execution & Validation
**Tasks**:
- Run all CLI tests: `pytest -v tests/unit/cli/`
- Run integration tests: `pytest -v tests/integration/test_cli_integration.py`
- Run e2e tests: `pytest -v tests/e2e/test_cli_workflows.py`
- Check coverage: `pytest --cov=synapse.cli tests/`
- Fix any failing tests
- Document test results

**Target Coverage**: 80%+

---

## Phase 4: VitePress Documentation (1-2 hours)

### 4.1 VitePress Setup
**Tasks**:
- Install VitePress: `npm create vitepress@latest docs/vitepress`
- Configure project: `docs/vitepress/.vitepress/config.ts`
- Set up theme (default or custom)
- Configure GitHub Actions for auto-deploy
- Test local build: `npm run docs:dev`

**Dependencies**:
- Node.js 16+
- npm or yarn

### 4.2 Documentation Structure

```
docs/vitepress/
├── guide/
│   ├── cli/
│   │   ├── installation.md        # All 4 installation options
│   │   ├── commands.md           # Complete CLI reference
│   │   ├── quick-start.md        # Getting started guide
│   │   └── troubleshooting.md   # Common issues
│   ├── getting-started/
│   │   ├── overview.md
│   │   └── architecture.md
│   └── api/
│       └── reference.md
├── .vitepress/
│   ├── config.ts
│   └── theme/
│       └── index.ts
└── index.md
```

### 4.3 Content Creation

**CLI Installation Guide** (`guide/cli/installation.md`):
```markdown
# Installation Options

## Option 1: pip install (After PyPI publication)
```bash
pip install synapse
```

## Option 2: pip install -e (Development mode)
```bash
cd /path/to/synapse
pip install -e .
```

## Option 3: Docker Deployment
```bash
docker compose -f docker-compose.mcp.yml up -d
```

## Option 4: Python Module (No installation)
```bash
python -m synapse.cli.main <command> [options]
```

### Quick Verification
```bash
python -m synapse.cli.main --help
```
```

**CLI Commands Reference** (`guide/cli/commands.md`):
- Complete documentation for all 12 commands
- Usage examples for each command
- Option/flag descriptions
- Error handling information

**Troubleshooting Guide** (`guide/cli/troubleshooting.md`):
- Server won't start
- Port already in use
- Docker issues
- Model download failures
- Permission errors

### 4.4 Documentation Features
- Search functionality (VitePress built-in)
- Code syntax highlighting
- Copy-to-clipboard for code blocks
- Mobile responsive design
- Navigation sidebar
- Version selector (if needed)

---

## Phase 5: Deployment & Validation (1-2 hours)

### 5.1 GitHub Pages Setup
**Tasks**:
- Create `.github/workflows/deploy-docs.yml`
- Configure deployment to `gh-pages` branch
- Set repository settings to use GitHub Pages
- Verify automatic deployment on push

**Workflow Example**:
```yaml
name: Deploy Docs

on:
  push:
    branches: [main]
    paths: ['docs/vitepress/**']

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npm run docs:build
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: docs/vitepress/.vitepress/dist
```

### 5.2 Final Validation
**Tasks**:
- Deploy documentation to GitHub Pages
- Verify all links work
- Test code examples
- Check mobile responsiveness
- Verify search functionality
- Get user approval

---

## Data Flow

### Manual Testing Workflow
```
1. Execute command
2. Verify output
3. Check behavior
4. Document result (PASS/FAIL)
5. If FAIL → Document in BUG_TRACKER.md
6. Move to next command
```

### Bug Fix Workflow
```
1. Analyze bug from BUG_TRACKER.md
2. Identify root cause
3. Implement fix in production code
4. Test fix manually
5. Add regression test
6. Update bug status to FIXED
7. Move to next bug
```

### Test Coverage Workflow
```
1. Analyze manual test results
2. Identify test gaps
3. Add missing tests
4. Update existing tests
5. Run full test suite
6. Fix any failures
7. Verify coverage 80%+
```

### Documentation Workflow
```
1. Create VitePress structure
2. Write content based on latest CLI
3. Test code examples
4. Build documentation
5. Deploy to GitHub Pages
6. Verify deployment
```

---

## Technical Decisions

### Decision 1: Test Framework
**Choice**: pytest with typer.testing.CliRunner
**Rationale**:
- Industry standard for Python testing
- Native typer integration
- Easy mocking and fixtures
- Good IDE support

### Decision 2: Documentation Platform
**Choice**: VitePress
**Rationale**:
- Modern and fast
- Vue.js ecosystem (familiar to frontend devs)
- Built-in search
- GitHub Actions support
- Markdown-based (easy to maintain)

### Decision 3: Test Organization
**Choice**: Separate unit, integration, and e2e tests
**Rationale**:
- Clear separation of concerns
- Faster test runs (run subsets)
- Better failure isolation
- Standard practice in Python projects

### Decision 4: Bug Tracking
**Choice**: Markdown file in spec directory
**Rationale**:
- Simple and version-controlled
- No external dependencies
- Easy to update with agent
- Integrated with SDD workflow

---

## Dependencies & Integration Points

### Internal Dependencies
- `synapse/cli/main.py` - Main entry point
- `synapse/cli/commands/*.py` - Individual command implementations
- `tests/unit/cli/*.py` - Existing unit tests
- `synapse/config.py` - Configuration management

### External Dependencies
- **pytest**: Test framework
- **typer**: CLI framework
- **Node.js/npm**: VitePress build
- **GitHub Actions**: CI/CD for docs

### Integration Points
- MCP server (for start/stop commands)
- Model downloads (HuggingFace)
- Docker (for Docker mode)
- File system (for ingest/setup commands)

---

## Risk Mitigation

### Risk 1: Manual Testing Incomplete Coverage
**Mitigation**:
- Use systematic test matrix
- Test all options and flags
- Test error paths explicitly
- Document edge cases encountered

### Risk 2: Bug Fixes Cause Regressions
**Mitigation**:
- Add regression tests for each fix
- Run full test suite after each fix
- Code review before committing
- Keep bug tracker updated

### Risk 3: Test Coverage Misses Critical Paths
**Mitigation**:
- Use coverage report to identify gaps
- Add integration tests for workflows
- Test error paths explicitly
- Focus on high-risk areas

### Risk 4: VitePress Deployment Issues
**Mitigation**:
- Test local build first
- Use minimal VitePress config
- Follow official documentation
- Create deployment workflow early

---

## Performance Considerations

### Manual Testing
- Target: 2-3 hours for all 12 commands
- Each command: ~10-15 minutes (including variations)

### Test Suite
- Target: 5 minutes full run
- Unit tests: < 2 minutes
- Integration tests: < 2 minutes
- E2E tests: < 1 minute

### Documentation Build
- Target: < 30 seconds
- VitePress build time: < 10 seconds
- GitHub Pages deployment: < 2 minutes

---

## Security Considerations

### Manual Testing
- Don't expose sensitive data in test commands
- Use mock data for ingest tests
- Verify no hardcoded credentials

### Bug Fixes
- Review security implications of fixes
- Don't add new security vulnerabilities
- Validate input handling

### Documentation
- Don't include secrets or API keys
- Verify code examples are safe
- Document security best practices

---

## Acceptance Criteria Summary

**Phase 1: Manual Testing**
- [ ] All 12 commands tested manually
- [ ] Test results documented
- [ ] Bugs found documented in BUG_TRACKER.md

**Phase 2: Bug Fixes**
- [ ] All documented bugs fixed
- [ ] Regression tests added for each fix
- [ ] No new bugs introduced

**Phase 3: Test Coverage**
- [ ] Test coverage reaches 80%+
- [ ] All tests passing
- [ ] Integration tests added for workflows

**Phase 4: VitePress Documentation**
- [ ] VitePress project initialized
- [ ] All commands documented
- [ ] Installation guide complete
- [ ] Troubleshooting guide complete
- [ ] Code examples tested

**Phase 5: Deployment**
- [ ] Documentation deployed to GitHub Pages
- [ ] All links verified
- [ ] User approval received

---

## Timeline Estimate

| Phase | Estimated Time | Dependencies |
|--------|---------------|--------------|
| Phase 1: Manual Testing | 2-3 hours | None |
| Phase 2: Bug Fixes | 1-2 hours | Phase 1 |
| Phase 3: Test Coverage | 2-3 hours | Phase 2 |
| Phase 4: VitePress Setup | 1-2 hours | None (can parallel) |
| Phase 5: Deployment | 1-2 hours | Phase 4 |
| **Total** | **7-12 hours** | - |

---

## Success Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Commands Manually Tested | 12/12 | 0 | ⏳ |
| Bugs Found & Fixed | 100% | N/A | ⏳ |
| Test Coverage | 80%+ | N/A | ⏳ |
| Tests Passing | 100% | N/A | ⏳ |
| VitePress Docs Complete | 100% | 0% | ⏳ |
| Docs Deployed | Yes | No | ⏳ |

---

## Sign-off

**Plan approved by**: opencode
**Date**: January 7, 2026

---

## Changes Log

| Date | Change | Author |
|------|--------|---------|
| 2026-01-07 | Initial technical plan | opencode |
