# Tasks: Phase 4 - Model Management

**Feature ID**: 005-cli-priority-testing
**Phase**: 4 - Model Management
**Priority**: P3 (Model Management)
**Status**: In Progress
**Created**: February 8, 2026
**Last Updated**: February 8, 2026

---

## Phase 4.1: Test Infrastructure Setup (3 tasks)

### 4.1.1 Create Test Directory Structure
- [ ] Create `phase-4-model-management/` directory
- [ ] Verify `tests/cli/` directory exists
- [ ] Verify `tests/cli/__init__.py` exists

### 4.1.2 Add Shared Utilities
- [ ] Add `run_models_command()` function to conftest.py
- [ ] Add `verify_models_list()` function to conftest.py
- [ ] Add `MODEL_TEST_CASES` list to conftest.py
- [ ] Add `MODELS_TIMEOUTS` dictionary to conftest.py
- [ ] Add `MODELS_THRESHOLDS` dictionary to conftest.py

### 4.1.3 Add Test Configuration
- [ ] Add `INSTALLED_MODELS` dictionary (existing models)
- [ ] Add `MODEL_INFO` dictionary (model details)
- [ ] Add `MODELS_ERROR_MESSAGES` dictionary

---

## Phase 4.2: P3-1 Models List Tests (10 tasks)

### 4.2.1 Create Test Script
- [ ] Create `tests/cli/test_p3_models_list.py` file
- [ ] Add imports (subprocess, sys, time, pathlib, json)
- [ ] Define `MODELS_TIMEOUTS` dictionary
- [ ] Implement test result storage
- [ ] Add main() function

### 4.2.2 Implement: List-1 List Installed Models
- [ ] Define `test_list_1_installed_models()`
- [ ] Implement command: `synapse models list`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: output contains "bge" or model name
- [ ] Record test result

### 4.2.3 Implement: List-2 Verbose Mode
- [ ] Define `test_list_2_verbose()`
- [ ] Implement command: `synapse models list --verbose`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: output shows size/path/details
- [ ] Record test result

### 4.2.4 Implement: List-3 Empty List
- [ ] Define `test_list_3_empty()`
- [ ] Create mock scenario (no models installed)
- [ ] Implement command: `synapse models list`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: output shows "no models" message
- [ ] Record test result

### 4.2.5 Implement: List-4 JSON Format
- [ ] Define `test_list_4_json_format()`
- [ ] Implement command: `synapse models list --format json`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: output is valid JSON
- [ ] Add assertion: JSON contains expected fields
- [ ] Record test result

### 4.2.6 Implement: List-5 Performance Test
- [ ] Define `test_list_5_performance()`
- [ ] Run warm-up query
- [ ] Implement command: `synapse models list`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: duration < 5s threshold
- [ ] Record test result

### 4.2.7 Add Docker Mode Support
- [ ] Add function to run list in Docker mode
- [ ] Add Docker-specific assertions
- [ ] Add Docker timeout handling
- [ ] Add Docker result recording

### 4.2.8 Add User Home Mode Support
- [ ] Add function to run list in user home mode
- [ ] Add home-specific assertions
- [ ] Add home timeout handling
- [ ] Add home result recording

### 4.2.9 Execute List Tests
- [ ] Run `python3 tests/cli/test_p3_models_list.py` (native)
- [ ] Record all test results (pass/fail)
- [ ] Record performance metrics
- [ ] Document any failures

---

## Phase 4.3: P3-2 Models Download Tests (10 tasks)

### 4.3.1 Create Test Script
- [ ] Create `tests/cli/test_p3_models_download.py` file
- [ ] Add imports (subprocess, sys, time, pathlib, json)
- [ ] Define `MODELS_TIMEOUTS` dictionary (download: 600s)
- [ ] Implement test result storage
- [ ] Add main() function

### 4.3.2 Implement: Download-1 Existing Model
- [ ] Define `test_download_1_existing()`
- [ ] Implement command: `synapse models download bge-m3`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: output shows "already installed"
- [ ] Record test result

### 4.3.3 Implement: Download-2 New Model
- [ ] Define `test_download_2_new()`
- [ ] Identify a test model (small, safe to download)
- [ ] Implement command: `synapse models download <test_model>`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: progress indicator shown
- [ ] Record test result

### 4.3.4 Implement: Download-3 Force Re-download
- [ ] Define `test_download_3_force()`
- [ ] Implement command: `synapse models download bge-m3 --force`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: output shows re-download
- [ ] Record test result

### 4.3.5 Implement: Download-4 Invalid Model
- [ ] Define `test_download_4_invalid()`
- [ ] Implement command: `synapse models download invalid-model-xyz`
- [ ] Add assertion: exit_code != 0
- [ ] Add assertion: error message shown
- [ ] Record test result

### 4.3.6 Implement: Download-5 Network Error
- [ ] Define `test_download_5_network()`
- [ ] Simulate offline mode or invalid URL
- [ ] Implement command: `synapse models download <model>`
- [ ] Add assertion: exit_code != 0
- [ ] Add assertion: network error message
- [ ] Record test result

### 4.3.7 Implement: Download-6 Performance
- [ ] Define `test_download_6_performance()`
- [ ] Note: Only run on small test models
- [ ] Implement command: `synapse models download <small_model>`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: duration < 300s threshold
- [ ] Record test result

### 4.3.8 Add Docker Mode Support
- [ ] Add function to run download in Docker mode
- [ ] Add Docker-specific assertions
- [ ] Add Docker timeout handling
- [ ] Add Docker result recording

### 4.3.9 Add User Home Mode Support
- [ ] Add function to run download in user home mode
- [ ] Add home-specific assertions
- [ ] Add home timeout handling
- [ ] Add home result recording

### 4.3.10 Execute Download Tests
- [ ] Run `python3 tests/cli/test_p3_models_download.py` (native)
- [ ] Record all test results (pass/fail)
- [ ] Record performance metrics
- [ ] Document any failures

---

## Phase 4.4: P3-3 Models Verify Tests (10 tasks)

### 4.4.1 Create Test Script
- [ ] Create `tests/cli/test_p3_models_verify.py` file
- [ ] Add imports (subprocess, sys, time, pathlib, json)
- [ ] Define `MODELS_TIMEOUTS` dictionary (verify: 60s)
- [ ] Implement test result storage
- [ ] Add main() function

### 4.4.2 Implement: Verify-1 Valid Model
- [ ] Define `test_verify_1_valid()`
- [ ] Implement command: `synapse models verify bge-m3`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: output shows "valid" or "OK"
- [ ] Record test result

### 4.4.3 Implement: Verify-2 All Models
- [ ] Define `test_verify_2_all()`
- [ ] Implement command: `synapse models verify`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: all models verified
- [ ] Record test result

### 4.4.4 Implement: Verify-3 Specific Model
- [ ] Define `test_verify_3_specific()`
- [ ] Implement command: `synapse models verify <model_id>`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: specific model status shown
- [ ] Record test result

### 4.4.5 Implement: Verify-4 Invalid Model
- [ ] Define `test_verify_4_invalid()`
- [ ] Implement command: `synapse models verify invalid-model`
- [ ] Add assertion: exit_code != 0
- [ ] Add assertion: error message shown
- [ ] Record test result

### 4.4.6 Implement: Verify-5 Verbose Output
- [ ] Define `test_verify_5_verbose()`
- [ ] Implement command: `synapse models verify --verbose`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: detailed output shown
- [ ] Record test result

### 4.4.7 Implement: Verify-6 Performance
- [ ] Define `test_verify_6_performance()`
- [ ] Run warm-up verify
- [ ] Implement command: `synapse models verify bge-m3`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: duration < 60s threshold
- [ ] Record test result

### 4.4.8 Add Docker Mode Support
- [ ] Add function to run verify in Docker mode
- [ ] Add Docker-specific assertions
- [ ] Add Docker timeout handling
- [ ] Add Docker result recording

### 4.4.9 Add User Home Mode Support
- [ ] Add function to run verify in user home mode
- [ ] Add home-specific assertions
- [ ] Add home timeout handling
- [ ] Add home result recording

### 4.4.10 Execute Verify Tests
- [ ] Run `python3 tests/cli/test_p3_models_verify.py` (native)
- [ ] Record all test results (pass/fail)
- [ ] Record performance metrics
- [ ] Document any failures

---

## Phase 4.5: P3-4 Models Remove Tests (10 tasks)

### 4.5.1 Create Test Script
- [ ] Create `tests/cli/test_p3_models_remove.py` file
- [ ] Add imports (subprocess, sys, time, pathlib, json)
- [ ] Define `MODELS_TIMEOUTS` dictionary (remove: 30s)
- [ ] Implement test result storage
- [ ] Add main() function

### 4.5.2 Implement: Remove-1 Force Remove
- [ ] Define `test_remove_1_force()`
- [ ] Create test model file first (safe to remove)
- [ ] Implement command: `synapse models remove <test_model> --force`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: model removed from disk
- [ ] Record test result

### 4.5.3 Implement: Remove-2 Interactive Confirmation
- [ ] Define `test_remove_2_interactive()`
- [ ] Create test model file
- [ ] Simulate interactive input (y + Enter)
- [ ] Implement command with echo "y" | `synapse models remove <test_model>`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: model removed
- [ ] Record test result

### 4.5.4 Implement: Remove-3 Missing Model
- [ ] Define `test_remove_3_missing()`
- [ ] Implement command: `synapse models remove nonexistent-model`
- [ ] Add assertion: exit_code != 0
- [ ] Add assertion: error message shown
- [ ] Record test result

### 4.5.5 Implement: Remove-4 Dry Run
- [ ] Define `test_remove_4_dry_run()`
- [ ] Implement command: `synapse models remove <model> --dry-run`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: shows what would be removed
- [ ] Add assertion: model not actually removed
- [ ] Record test result

### 4.5.6 Implement: Remove-5 Safety Check
- [ ] Define `test_remove_5_safety()`
- [ ] Try to remove active model (bge-m3)
- [ ] Implement command: `synapse models remove bge-m3`
- [ ] Add assertion: exit_code != 0
- [ ] Add assertion: safety warning shown
- [ ] Add assertion: model NOT removed
- [ ] Record test result

### 4.5.7 Implement: Remove-6 Performance
- [ ] Define `test_remove_6_performance()`
- [ ] Create test model file
- [ ] Implement command: `synapse models remove <test_model> --force`
- [ ] Add assertion: exit_code == 0
- [ ] Add assertion: duration < 30s threshold
- [ ] Record test result

### 4.5.8 Add Docker Mode Support
- [ ] Add function to run remove in Docker mode
- [ ] Add Docker-specific assertions
- [ ] Add Docker timeout handling
- [ ] Add Docker result recording

### 4.5.9 Add User Home Mode Support
- [ ] Add function to run remove in user home mode
- [ ] Add home-specific assertions
- [ ] Add home timeout handling
- [ ] Add home result recording

### 4.5.10 Execute Remove Tests
- [ ] Run `python3 tests/cli/test_p3_models_remove.py` (native)
- [ ] Record all test results (pass/fail)
- [ ] Record performance metrics
- [ ] Document any failures

---

## Phase 4.6: Test Execution & Bug Fixes (3 tasks)

### 4.6.1 Run All Phase 4 Tests
- [ ] Run `python3 tests/cli/test_p3_models_list.py`
- [ ] Run `python3 tests/cli/test_p3_models_download.py`
- [ ] Run `python3 tests/cli/test_p3_models_verify.py`
- [ ] Run `python3 tests/cli/test_p3_models_remove.py`
- [ ] Record all results

### 4.6.2 Document Failures
- [ ] Identify failing tests
- [ ] Document error messages
- [ ] Create bug reports for failures
- [ ] Prioritize fixes

### 4.6.3 Fix Bugs
- [ ] Fix any CLI command bugs
- [ ] Fix any test assertion bugs
- [ ] Re-run failing tests
- [ ] Achieve 90%+ pass rate

---

## Phase 4.7: Documentation & Completion (3 tasks)

### 4.7.1 Create Test Results Document
- [ ] Create `PHASE_4_RESULTS.md`
- [ ] Document all test results (P3-1, P3-2, P3-3, P3-4)
- [ ] Document pass/fail status for each test
- [ ] Document performance metrics
- [ ] Document any errors or issues
- [ ] Calculate overall success rate

### 4.7.2 Update Central Index
- [ ] Update `docs/specs/index.md` with Phase 4 entry
- [ ] Set Phase 4 status to "[Completed]"
- [ ] Add completion date
- [ ] Add final commit hash
- [ ] Update overall progress

### 4.7.3 Mark Tasks Complete
- [ ] Mark all Phase 4.1 tasks as complete
- [ ] Mark all Phase 4.2 tasks as complete
- [ ] Mark all Phase 4.3 tasks as complete
- [ ] Mark all Phase 4.4 tasks as complete
- [ ] Mark all Phase 4.5 tasks as complete
- [ ] Mark all Phase 4.6 tasks as complete
- [ ] Mark all Phase 4.7 tasks as complete
- [ ] Update this file with final commit hash

---

## Task Statistics

| Phase | Tasks | Status |
|-------|-------|--------|
| 4.1 Infrastructure | 3 | ⏳ Pending |
| 4.2 Models List | 10 | ⏳ Pending |
| 4.3 Models Download | 10 | ⏳ Pending |
| 4.4 Models Verify | 10 | ⏳ Pending |
| 4.5 Models Remove | 10 | ⏳ Pending |
| 4.6 Test & Fix | 3 | ⏳ Pending |
| 4.7 Documentation | 3 | ⏳ Pending |
| **Total** | **49** | **0%** |

---

## Test Coverage Summary

**Total Tests**: 20 tests
- P3-1 (list): 5 tests
- P3-2 (download): 5 tests
- P3-3 (verify): 5 tests
- P3-4 (remove): 5 tests

**Coverage Metrics**:
- Functional requirements: 100% (all FRs tested)
- Non-functional requirements: 100% (performance, error handling)
- Error scenarios: 100% (all error paths tested)
- Cross-platform coverage: 100% (native mode primary)

---

## Dependencies

- MCP server running
- Network connectivity (for downloads)
- Disk space: 600MB+ free
- Write access: `~/.synapse/models/`

---

## Notes

**TESTING APPROACH (Following Phases 1-3 Pattern):**
- Environments: Native mode (primary) - Option 1-B
- Test Data: Existing model files (no fixtures) - Option 2-No
- Failure Criteria: Error, wrong output, OR performance degradation - Option 3-C
- Automation: Semi-automated scripts with assertions - Option 4-C
- Documentation: Pass/fail + metrics

---

## Completion Checklist

Phase 4 is complete when:
- [ ] All 49 tasks marked as complete
- [ ] All 20 tests passing (90%+ pass rate)
- [ ] Performance compliance: 90%+
- [ ] Test results documented
- [ ] Central index updated
- [ ] All changes committed to git
- [ ] Final commit hash added to this file

---

**Last Updated**: February 8, 2026
**Status**: Ready to Start - Phase 4.1 Infrastructure
**Next Action**: Begin Phase 4.1 task implementation
