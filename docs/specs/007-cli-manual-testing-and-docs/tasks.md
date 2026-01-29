# Task Breakdown: CLI Manual Testing, Bug Fixes, Test Coverage & VitePress Documentation

**Feature ID**: 007-cli-manual-testing-and-docs
**Created**: January 7, 2026
**Status**: [In Progress]

---

## Phase 1: Manual CLI Testing (2-3 hours)

### Phase 1.1: Test Environment Setup
- [x] 1.1.1 Create MANUAL_TEST_RESULTS.md template (Linked to FR1)
- [x] 1.1.2 Verify Python 3.8+ available (Linked to FR1)
- [x] 1.1.3 Verify typer and CLI dependencies installed (Linked to FR1)
- [x] 1.1.4 Set up test data directories (sample files for ingest) (Linked to FR1)

### Phase 1.2: Main Commands Testing (8 commands)

#### Command 1: `start`
- [ ] 1.2.1 Test native mode start: `python -m synapse.cli.main start` (Linked to US1)
- [ ] 1.2.2 Test native mode with custom port: `python -m synapse.cli.main start --port 8080` (Linked to US1)
- [ ] 1.2.3 Test Docker mode start: `python -m synapse.cli.main start --docker` (Linked to US1)
- [ ] 1.2.4 Test Docker mode with custom port: `python -m synapse.cli.main start -d -p 9000` (Linked to US1)
- [ ] 1.2.5 Verify server health endpoint: `curl http://localhost:8002/health` (Linked to US1)
- [ ] 1.2.6 Check process persistence (background execution) (Linked to US1)
- [ ] 1.2.7 Document start command test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 2: `stop`
- [ ] 1.2.8 Test stop running native server: `python -m synapse.cli.main stop` (Linked to US1)
- [ ] 1.2.9 Test stop running Docker server (Linked to US1)
- [ ] 1.2.10 Test stop when no server running (error handling) (Linked to US1)
- [ ] 1.2.11 Verify cleanup (no zombie processes) (Linked to US1)
- [ ] 1.2.12 Document stop command test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 3: `status`
- [ ] 1.2.13 Test brief status: `python -m synapse.cli.main status` (Linked to US1)
- [ ] 1.2.14 Test verbose status: `python -m synapse.cli.main status --verbose` (Linked to US1)
- [ ] 1.2.15 Test status with server stopped (Linked to US1)
- [ ] 1.2.16 Test status with server running (Linked to US1)
- [ ] 1.2.17 Check configuration display (Linked to US1)
- [ ] 1.2.18 Verify health check integration (Linked to US1)
- [ ] 1.2.19 Document status command test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 4: `ingest`
- [ ] 1.2.20 Test ingest single file: `python -m synapse.cli.main ingest /path/to/file.txt` (Linked to US1)
- [ ] 1.2.21 Test ingest directory: `python -m synapse.cli.main ingest /path/to/dir/` (Linked to US1)
- [ ] 1.2.22 Test with custom project: `python -m synapse.cli.main ingest file.txt -p test-project` (Linked to US1)
- [ ] 1.2.23 Test code mode: `python -m synapse.cli.main ingest code/ -c` (Linked to US1)
- [ ] 1.2.24 Test custom chunk size: `python -m synapse.cli.main ingest file.txt --chunk-size 1000` (Linked to US1)
- [ ] 1.2.25 Test ingest non-existent file (error handling) (Linked to US1)
- [ ] 1.2.26 Test ingest unsupported file type (error handling) (Linked to US1)
- [ ] 1.2.27 Document ingest command test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 5: `query`
- [ ] 1.2.28 Test simple query: `python -m synapse.cli.main query "test search"` (Linked to US1)
- [ ] 1.2.29 Test with top-k: `python -m synapse.cli.main query "test" -k 5` (Linked to US1)
- [ ] 1.2.30 Test JSON format: `python -m synapse.cli.main query "test" -f json` (Linked to US1)
- [ ] 1.2.31 Test text format: `python -m synapse.cli.main query "test" -f text` (Linked to US1)
- [ ] 1.2.32 Test different modes: `python -m synapse.cli.main query "test" -m code` (Linked to US1)
- [ ] 1.2.33 Test query with no results (edge case) (Linked to US1)
- [ ] 1.2.34 Document query command test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 6: `config`
- [ ] 1.2.35 Test basic config display: `python -m synapse.cli.main config` (Linked to US1)
- [ ] 1.2.36 Test verbose config: `python -m synapse.cli.main config --verbose` (Linked to US1)
- [ ] 1.2.37 Verify all settings shown (Linked to US1)
- [ ] 1.2.38 Check formatting readability (Linked to US1)
- [ ] 1.2.39 Document config command test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 7: `setup`
- [ ] 1.2.40 Test fresh setup: `python -m synapse.cli.main setup` (Linked to US1)
- [ ] 1.2.41 Test force setup: `python -m synapse.cli.main setup --force` (Linked to US1)
- [ ] 1.2.42 Test offline mode: `python -m synapse.cli.main setup --offline` (Linked to US1)
- [ ] 1.2.43 Test skip model check: `python -m synapse.cli.main setup --no-model-check` (Linked to US1)
- [ ] 1.2.44 Test setup when already configured (Linked to US1)
- [ ] 1.2.45 Verify directory creation (Linked to US1)
- [ ] 1.2.46 Verify config file generation (Linked to US1)
- [ ] 1.2.47 Document setup command test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 8: `onboard`
- [ ] 1.2.48 Test interactive mode: `python -m synapse.cli.main onboard` (Linked to US1)
- [ ] 1.2.49 Test quick mode: `python -m synapse.cli.main onboard --quick` (Linked to US1)
- [ ] 1.2.50 Test silent mode: `python -m synapse.cli.main onboard --silent -p test` (Linked to US1)
- [ ] 1.2.51 Test skip test: `python -m synapse.cli.main onboard --skip-test` (Linked to US1)
- [ ] 1.2.52 Test skip ingest: `python -m synapse.cli.main onboard --skip-ingest` (Linked to US1)
- [ ] 1.2.53 Test offline mode: `python -m synapse.cli.main onboard --offline` (Linked to US1)
- [ ] 1.2.54 Verify each step completes (Linked to US1)
- [ ] 1.2.55 Document onboard command test results in MANUAL_TEST_RESULTS.md (Linked to US1)

### Phase 1.3: Models Subcommands Testing (4 commands)

#### Command 9: `models list`
- [ ] 1.3.1 Test list all models: `python -m synapse.cli.main models list` (Linked to US1)
- [ ] 1.3.2 Verify embedding model shown (Linked to US1)
- [ ] 1.3.3 Check format (table or list) (Linked to US1)
- [ ] 1.3.4 Document models list test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 10: `models download`
- [ ] 1.3.5 Test download valid model: `python -m synapse.cli.main models download bge-m3` (Linked to US1)
- [ ] 1.3.6 Test download with force: `python -m synapse.cli.main models download bge-m3 --force` (Linked to US1)
- [ ] 1.3.7 Test download invalid model (error handling) (Linked to US1)
- [ ] 1.3.8 Document models download test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 11: `models verify`
- [ ] 1.3.9 Test verify installed model: `python -m synapse.cli.main models verify` (Linked to US1)
- [ ] 1.3.10 Test verify with corrupted model (error handling) (Linked to US1)
- [ ] 1.3.11 Document models verify test results in MANUAL_TEST_RESULTS.md (Linked to US1)

#### Command 12: `models remove`
- [ ] 1.3.12 Test remove existing model: `python -m synapse.cli.main models remove bge-m3` (Linked to US1)
- [ ] 1.3.13 Test remove non-existent model (error handling) (Linked to US1)
- [ ] 1.3.14 Verify cleanup (Linked to US1)
- [ ] 1.3.15 Document models remove test results in MANUAL_TEST_RESULTS.md (Linked to US1)

### Phase 1.4: Test Results Summary
- [ ] 1.4.1 Summarize all PASS/FAIL results in MANUAL_TEST_RESULTS.md (Linked to FR1)
- [ ] 1.4.2 Identify critical failures that block other tests (Linked to FR1)
- [ ] 1.4.3 Review test results with user (Linked to FR1)

---

## Phase 2: Bug Documentation & Fixes (1-2 hours)

### Phase 2.1: Bug Tracking Setup
- [ ] 2.1.1 Create BUG_TRACKER.md template (Linked to FR2)
- [ ] 2.1.2 Define bug severity levels (critical/high/medium/low) (Linked to FR2)
- [ ] 2.1.3 Define bug status workflow (new/investigating/fixed/can't reproduce) (Linked to FR2)

### Phase 2.2: Bug Documentation
- [ ] 2.2.1 For each FAIL in MANUAL_TEST_RESULTS.md, create bug entry (Linked to US2)
- [ ] 2.2.2 Document bug ID, command affected, description (Linked to US2)
- [ ] 2.2.3 Document reproduction steps (Linked to US2)
- [ ] 2.2.4 Document expected vs actual behavior (Linked to US2)
- [ ] 2.2.5 Assign severity to each bug (Linked to US2)

### Phase 2.3: Bug Analysis & Fixes
- [ ] 2.3.1 For each bug, analyze root cause (Linked to US2)
- [ ] 2.3.2 Prioritize bugs by severity (critical first) (Linked to US2)
- [ ] 2.3.3 Implement fix in production code (Linked to US2)
- [ ] 2.3.4 Test fix manually (Linked to US2)
- [ ] 2.3.5 Add regression test for fix (Linked to US3)
- [ ] 2.3.6 Update bug status to FIXED (Linked to US2)
- [ ] 2.3.7 Document any breaking changes (Linked to FR2)

### Phase 2.4: Bug Fix Validation
- [ ] 2.4.1 Re-test affected commands (Linked to US2)
- [ ] 2.4.2 Verify no regressions introduced (Linked to US2)
- [ ] 2.4.3 Update MANUAL_TEST_RESULTS.md with re-test results (Linked to US2)

---

## Phase 3: Test Coverage Enhancement (2-3 hours)

### Phase 3.1: Test Gap Analysis
- [ ] 3.1.1 Compare manual test coverage with existing tests (Linked to FR3)
- [ ] 3.1.2 Identify missing test cases (Linked to FR3)
- [ ] 3.1.3 Identify outdated tests (Linked to FR3)
- [ ] 3.1.4 Plan new test additions (Linked to FR3)

### Phase 3.2: Test Additions by Command

#### Start Command Tests
- [ ] 3.2.1 Add tests for missing start command functionality (Linked to FR3)
- [ ] 3.2.2 Update tests for start command bug fixes (Linked to FR3)
- [ ] 3.2.3 Add edge case tests for start command (Linked to FR3)
- [ ] 3.2.4 Add error handling tests for start command (Linked to FR3)

#### Stop Command Tests
- [ ] 3.2.5 Add tests for missing stop command functionality (Linked to FR3)
- [ ] 3.2.6 Update tests for stop command bug fixes (Linked to FR3)
- [ ] 3.2.7 Add edge case tests for stop command (Linked to FR3)
- [ ] 3.2.8 Add error handling tests for stop command (Linked to FR3)

#### Status Command Tests
- [ ] 3.2.9 Add tests for missing status command functionality (Linked to FR3)
- [ ] 3.2.10 Update tests for status command bug fixes (Linked to FR3)
- [ ] 3.2.11 Add edge case tests for status command (Linked to FR3)
- [ ] 3.2.12 Add error handling tests for status command (Linked to FR3)

#### Ingest Command Tests
- [ ] 3.2.13 Add tests for missing ingest command functionality (Linked to FR3)
- [ ] 3.2.14 Update tests for ingest command bug fixes (Linked to FR3)
- [ ] 3.2.15 Add edge case tests for ingest command (Linked to FR3)
- [ ] 3.2.16 Add error handling tests for ingest command (Linked to FR3)

#### Query Command Tests
- [ ] 3.2.17 Add tests for missing query command functionality (Linked to FR3)
- [ ] 3.2.18 Update tests for query command bug fixes (Linked to FR3)
- [ ] 3.2.19 Add edge case tests for query command (Linked to FR3)
- [ ] 3.2.20 Add error handling tests for query command (Linked to FR3)

#### Config Command Tests
- [ ] 3.2.21 Add tests for missing config command functionality (Linked to FR3)
- [ ] 3.2.22 Update tests for config command bug fixes (Linked to FR3)
- [ ] 3.2.23 Add edge case tests for config command (Linked to FR3)
- [ ] 3.2.24 Add error handling tests for config command (Linked to FR3)

#### Setup Command Tests
- [ ] 3.2.25 Add tests for missing setup command functionality (Linked to FR3)
- [ ] 3.2.26 Update tests for setup command bug fixes (Linked to FR3)
- [ ] 3.2.27 Add edge case tests for setup command (Linked to FR3)
- [ ] 3.2.28 Add error handling tests for setup command (Linked to FR3)

#### Onboard Command Tests
- [ ] 3.2.29 Add tests for missing onboard command functionality (Linked to FR3)
- [ ] 3.2.30 Update tests for onboard command bug fixes (Linked to FR3)
- [ ] 3.2.31 Add edge case tests for onboard command (Linked to FR3)
- [ ] 3.2.32 Add error handling tests for onboard command (Linked to FR3)

#### Models Subcommand Tests
- [ ] 3.2.33 Add tests for missing models subcommands functionality (Linked to FR3)
- [ ] 3.2.34 Update tests for models subcommands bug fixes (Linked to FR3)
- [ ] 3.2.35 Add edge case tests for models subcommands (Linked to FR3)
- [ ] 3.2.36 Add error handling tests for models subcommands (Linked to FR3)

### Phase 3.3: Integration Tests
- [ ] 3.3.1 Create Start → Status → Stop workflow test (Linked to FR3)
- [ ] 3.3.2 Create Setup → Ingest → Query workflow test (Linked to FR3)
- [ ] 3.3.3 Create Models list → download → verify → remove workflow test (Linked to FR3)
- [ ] 3.3.4 Create Onboard → Status → Start workflow test (Linked to FR3)

### Phase 3.4: Test Execution & Validation
- [ ] 3.4.1 Run all CLI unit tests: `pytest -v tests/unit/cli/` (Linked to FR3)
- [ ] 3.4.2 Run integration tests: `pytest -v tests/integration/test_cli_integration.py` (Linked to FR3)
- [ ] 3.4.3 Run e2e tests: `pytest -v tests/e2e/test_cli_workflows.py` (Linked to FR3)
- [ ] 3.4.4 Check coverage: `pytest --cov=synapse.cli tests/` (Linked to FR3)
- [ ] 3.4.5 Fix any failing tests (Linked to FR3)
- [ ] 3.4.6 Verify coverage reaches 80%+ (Linked to FR3)
- [ ] 3.4.7 Document test results in TEST_RESULTS.md (Linked to FR3)

---

## Phase 4: VitePress Documentation (1-2 hours)

### Phase 4.1: VitePress Setup
- [ ] 4.1.1 Install VitePress: `npm create vitepress@latest docs/vitepress` (Linked to US4)
- [ ] 4.1.2 Configure project: create docs/vitepress/.vitepress/config.ts (Linked to US4)
- [ ] 4.1.3 Set up theme (default or custom) (Linked to US4)
- [ ] 4.1.4 Configure navigation in config.ts (Linked to US4)
- [ ] 4.1.5 Create GitHub Actions workflow for auto-deploy (Linked to US4)
- [ ] 4.1.6 Test local build: `npm run docs:dev` (Linked to US4)

### Phase 4.2: Documentation Structure Creation
- [ ] 4.2.1 Create docs/vitepress/guide/cli/ directory (Linked to US4)
- [ ] 4.2.2 Create docs/vitepress/guide/getting-started/ directory (Linked to US4)
- [ ] 4.2.3 Create docs/vitepress/guide/api/ directory (Linked to US4)
- [ ] 4.2.4 Create docs/vitepress/index.md homepage (Linked to US4)

### Phase 4.3: Content Creation

#### CLI Installation Guide
- [ ] 4.3.1 Create guide/cli/installation.md with all 4 options (Linked to US4)
- [ ] 4.3.2 Emphasize Option 4 (python -m) for current use (Linked to US4)
- [ ] 4.3.3 Add pip install option for future PyPI (Linked to US4)
- [ ] 4.3.4 Add pip install -e option for development (Linked to US4)
- [ ] 4.3.5 Add Docker deployment option (Linked to US4)
- [ ] 4.3.6 Add verification steps (synapse --help) (Linked to US4)

#### CLI Commands Reference
- [ ] 4.3.7 Create guide/cli/commands.md complete command reference (Linked to US4)
- [ ] 4.3.8 Document start command with all options and examples (Linked to US4)
- [ ] 4.3.9 Document stop command with all options and examples (Linked to US4)
- [ ] 4.3.10 Document status command with all options and examples (Linked to US4)
- [ ] 4.3.11 Document ingest command with all options and examples (Linked to US4)
- [ ] 4.3.12 Document query command with all options and examples (Linked to US4)
- [ ] 4.3.13 Document config command with all options and examples (Linked to US4)
- [ ] 4.3.14 Document setup command with all options and examples (Linked to US4)
- [ ] 4.3.15 Document onboard command with all options and examples (Linked to US4)
- [ ] 4.3.16 Document models list subcommand with examples (Linked to US4)
- [ ] 4.3.17 Document models download subcommand with examples (Linked to US4)
- [ ] 4.3.18 Document models verify subcommand with examples (Linked to US4)
- [ ] 4.3.19 Document models remove subcommand with examples (Linked to US4)

#### Quick Start Guide
- [ ] 4.3.20 Create guide/getting-started/quick-start.md (Linked to US4)
- [ ] 4.3.21 Add minimal working example (Linked to US4)
- [ ] 4.3.22 Add common use cases (Linked to US4)

#### Troubleshooting Guide
- [ ] 4.3.23 Create guide/cli/troubleshooting.md (Linked to US4)
- [ ] 4.3.24 Add server won't start troubleshooting (Linked to US4)
- [ ] 4.3.25 Add port already in use troubleshooting (Linked to US4)
- [ ] 4.3.26 Add Docker issues troubleshooting (Linked to US4)
- [ ] 4.3.27 Add model download failures troubleshooting (Linked to US4)
- [ ] 4.3.28 Add permission errors troubleshooting (Linked to US4)

#### Architecture Overview
- [ ] 4.3.29 Create guide/getting-started/architecture.md (Linked to US4)
- [ ] 4.3.30 Document CLI structure and components (Linked to US4)
- [ ] 4.3.31 Document command execution flow (Linked to US4)

### Phase 4.4: Documentation Features
- [ ] 4.4.1 Verify search functionality works (Linked to US4)
- [ ] 4.4.2 Verify code syntax highlighting (Linked to US4)
- [ ] 4.4.3 Add copy-to-clipboard for code blocks (Linked to US4)
- [ ] 4.4.4 Verify mobile responsive design (Linked to US4)
- [ ] 4.4.5 Verify navigation sidebar works (Linked to US4)

### Phase 4.5: Documentation Testing
- [ ] 4.5.1 Test all code examples in documentation (Linked to US4)
- [ ] 4.5.2 Verify all internal links work (Linked to US4)
- [ ] 4.5.3 Verify all external links work (Linked to US4)
- [ ] 4.5.4 Test on different browsers (Chrome, Firefox, Safari) (Linked to US4)

---

## Phase 5: Deployment & Validation (1-2 hours)

### Phase 5.1: GitHub Pages Setup
- [ ] 5.1.1 Create .github/workflows/deploy-docs.yml (Linked to US4)
- [ ] 5.1.2 Configure deployment to gh-pages branch (Linked to US4)
- [ ] 5.1.3 Set repository settings to use GitHub Pages (Linked to US4)
- [ ] 5.1.4 Configure custom domain if needed (Linked to US4)

### Phase 5.2: Build & Deploy
- [ ] 5.2.1 Build documentation locally: `npm run docs:build` (Linked to US4)
- [ ] 5.2.2 Test build output (Linked to US4)
- [ ] 5.2.3 Push workflow to trigger deployment (Linked to US4)
- [ ] 5.2.4 Monitor deployment in GitHub Actions (Linked to US4)
- [ ] 5.2.5 Verify deployment success (Linked to US4)

### Phase 5.3: Final Validation
- [ ] 5.3.1 Access deployed documentation URL (Linked to US4)
- [ ] 5.3.2 Verify all pages load correctly (Linked to US4)
- [ ] 5.3.3 Verify all links work (internal and external) (Linked to US4)
- [ ] 5.3.4 Verify code examples render correctly (Linked to US4)
- [ ] 5.3.5 Verify search functionality works (Linked to US4)
- [ ] 5.3.6 Verify mobile responsive design (Linked to US4)
- [ ] 5.3.7 Get user approval for documentation (Linked to US4)

---

## Phase 6: Completion & Cleanup (1 hour)

### Phase 6.1: Update Documentation
- [ ] 6.1.1 Update docs/specs/index.md with feature status [Completed] (Linked to SDD Protocol)
- [ ] 6.1.2 Add final commit hash to index.md (Linked to SDD Protocol)
- [ ] 6.1.3 Update README.md with VitePress documentation link (Linked to US4)

### Phase 6.2: Summary & Reporting
- [ ] 6.2.1 Create SUMMARY.md in spec directory (Linked to FR1, FR2, FR3, FR4)
- [ ] 6.2.2 Document all bugs found and fixed (Linked to US2)
- [ ] 6.2.3 Document test coverage achieved (Linked to FR3)
- [ ] 6.2.4 Document documentation URL (Linked to US4)
- [ ] 6.2.5 List any remaining work or recommendations (Linked to FR1, FR2, FR3, FR4)

### Phase 6.3: Git Operations
- [ ] 6.3.1 Stage all changes: `git add .` (Linked to SDD Protocol)
- [ ] 6.3.2 Commit changes: `git commit -m "Complete CLI manual testing, bug fixes, test coverage, and VitePress documentation"` (Linked to SDD Protocol)
- [ ] 6.3.3 Push to remote: `git push` (Linked to SDD Protocol)
- [ ] 6.3.4 Verify CI/CD passes (Linked to SDD Protocol)

---

## Summary

**Total Tasks**: 147 tasks across 6 phases

**Estimated Time**: 7-12 hours

**Phases**:
1. **Phase 1**: Manual CLI Testing (52 tasks)
2. **Phase 2**: Bug Documentation & Fixes (11 tasks)
3. **Phase 3**: Test Coverage Enhancement (43 tasks)
4. **Phase 4**: VitePress Documentation (29 tasks)
5. **Phase 5**: Deployment & Validation (7 tasks)
6. **Phase 6**: Completion & Cleanup (5 tasks)

---

**Task Status Legend**:
- [ ] Pending
- [x] Completed

---

**Last Updated**: January 7, 2026
**Maintainer**: opencode
