# Feature: CLI Manual Testing, Bug Fixes, Test Coverage & VitePress Documentation

**Feature ID**: 007-cli-manual-testing-and-docs
**Created**: January 7, 2026
**Status**: [In Progress]

---

## User Stories

### US1: Manual CLI Testing
**As a developer**, I want to manually test each CLI command using `python -m synapse.cli.main` so that I can verify they work correctly without installation.

**Acceptance Criteria**:
- [ ] All 8 main commands tested manually (start, stop, status, ingest, query, config, setup, onboard)
- [ ] All 4 models subcommands tested (list, download, verify, remove)
- [ ] Each command tested with various options/flags
- [ ] Commands tested in both native and Docker modes (where applicable)
- [ ] Test results documented with success/failure status

---

### US2: Production Code Bug Fixes
**As a developer**, I want to fix any bugs found during manual testing so that CLI commands work as expected.

**Acceptance Criteria**:
- [ ] Each bug found is documented with description and reproduction steps
- [ ] Root cause identified for each bug
- [ ] Fix implemented in production code
- [ ] Fix tested manually to confirm resolution
- [ ] No regressions introduced

---

### US3: Test Coverage Enhancement
**As a developer**, I want to add/update test cases for all CLI commands so that automated tests match manual testing coverage.

**Acceptance Criteria**:
- [ ] Test cases added for any missing command functionality
- [ ] Existing test cases updated to reflect bug fixes
- [ ] Test coverage for CLI commands reaches 80%+
- [ ] All tests passing (pytest -v tests/unit/cli/)
- [ ] Integration tests added for multi-command workflows

---

### US4: VitePress Documentation
**As a developer**, I want to update VitePress documentation to reflect the latest CLI changes and usage patterns.

**Acceptance Criteria**:
- [ ] VitePress project initialized (if not exists)
- [ ] CLI reference documentation created
- [ ] Installation guide updated with Option 4 (python -m)
- [ ] Usage examples added for each command
- [ ] Migration guide from old scripts to new CLI
- [ ] Code examples and troubleshooting sections
- [ ] Documentation deployed to GitHub Pages

---

## Functional Requirements

### FR1: Manual Test Execution
- Execute each CLI command using `python -m synapse.cli.main <command> [options]`
- Verify command output matches expectations
- Test all command options and flags
- Test error handling and edge cases
- Document results in test results file

### FR2: Bug Tracking and Fixes
- Create issue tracker for each bug discovered
- Categorize bugs by severity (critical, high, medium, low)
- Implement fixes following existing code patterns
- Add regression tests for each fix
- Update documentation if behavior changes

### FR3: Test Suite Updates
- Add unit tests for untested command paths
- Add integration tests for command sequences
- Ensure tests are idempotent and repeatable
- Use pytest fixtures for shared test data
- Mock external dependencies (Docker, network, etc.)

### FR4: VitePress Documentation Structure
```
docs/
├── vitepress/
│   ├── .vitepress/
│   │   ├── config.ts
│   │   └── theme/
│   ├── guide/
│   │   ├── cli/
│   │   │   ├── installation.md
│   │   │   ├── commands.md
│   │   │   └── troubleshooting.md
│   │   ├── getting-started.md
│   │   └── architecture.md
│   └── index.md
└── package.json
```

---

## Non-Functional Requirements

### NFR1: Performance
- Manual tests complete within 2 hours
- Bug fixes don't degrade performance
- Test suite runs within 5 minutes

### NFR2: Code Quality
- Follow existing code style (black formatting)
- Maintain type hints (mypy passing)
- Add docstrings to new/modified code
- No print statements (use logging module)

### NFR3: Documentation Quality
- Clear, concise, and accurate
- Code examples are tested and working
- Screenshots for complex workflows (optional)
- Troubleshooting section covers common issues

### NFR4: Test Reliability
- Tests are deterministic (no flaky tests)
- Tests don't depend on external state
- Tests can run in any order
- Tests cleanup after themselves

---

## Dependencies

### Required
- Python 3.8+
- pytest >= 7.0.0
- typer (for CLI testing)
- Node.js 16+ (for VitePress)

### Optional
- Docker (for Docker mode testing)
- docker-compose (for Docker mode testing)

### External Dependencies
- None (self-contained testing)

---

## Constraints

### Time Constraints
- Manual testing: 2-3 hours
- Bug fixes: 1-2 hours (depends on bugs found)
- Test updates: 2-3 hours
- VitePress setup: 1-2 hours
- Documentation creation: 2-3 hours
- **Total Estimated Time**: 8-13 hours

### Resource Constraints
- Must test on current machine (DietPi)
- Cannot install additional system packages without approval
- Must use existing test infrastructure

### Technical Constraints
- Must use pytest for tests
- Must follow AGENTS.md SDD protocol
- Must update docs/specs/index.md when complete
- Must not break existing functionality

---

## Success Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Commands Tested | 12 (8 main + 4 models) | 0 | ⏳ |
| Bugs Found | Unknown | 0 | ⏳ |
| Bugs Fixed | 100% of found | 0 | ⏳ |
| Test Coverage | 80%+ | Unknown | ⏳ |
| Tests Passing | 100% | Unknown | ⏳ |
| VitePress Docs | Complete | Not started | ⏳ |
| GitHub Pages | Deployed | Not started | ⏳ |

---

## Risk Assessment

### High Risk
- **Risk**: Manual testing may miss edge cases
- **Mitigation**: Complement with automated tests, use test matrix

### Medium Risk
- **Risk**: Bug fixes may introduce regressions
- **Mitigation**: Add regression tests, run full test suite after each fix

### Low Risk
- **Risk**: VitePress setup may be unfamiliar
- **Mitigation**: Use official docs, create minimal setup first

---

## Out of Scope

- Performance optimization (only bug fixes)
- New features or enhancements
- Refactoring beyond bug fixes
- Integration with external services (unless bugs found)
- Video tutorials or interactive demos

---

## Sign-off

**Requirements approved by**: opencode
**Date**: January 7, 2026

---

## Changes Log

| Date | Change | Author |
|------|--------|---------|
| 2026-01-07 | Initial requirements document | opencode |
