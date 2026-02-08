# Phase 4 Plan: Model Management Testing

**Feature ID**: 005-cli-priority-testing
**Phase**: 4 - Model Management
**Priority**: P3 (Model Management)
**Status**: Planning
**Created**: February 8, 2026

---

## Overview

This plan details the testing strategy for P3 commands: `synapse models list`, `synapse models download`, `synapse models verify`, and `synapse models remove`. These commands manage the ML models used for embeddings and inference.

---

## Testing Strategy

### Approach: Semi-Automated Scripts with Assertions

Following the pattern established in Phases 1-3:
- **Test Scripts**: Python scripts with built-in assertions
- **Manual Execution**: Run scripts and observe results
- **Assertions**: Check exit codes, output format, and performance
- **Documentation**: Record pass/fail + metrics

### Test Environments: Native Mode (Primary)

Following Phase 1 pattern (Option 1-B - Simplified):
1. **Native Mode**: Direct execution on host system (primary)
2. Docker/User Home modes can be tested if issues arise

### Test Data: Existing Model Files

Following Phase 1 pattern (Option 2-No):
- Use existing models in `~/.synapse/models/`
- Use existing model config in `configs/models_config.json`
- No test fixtures required

---

## Architecture & Design

### Test Script Structure

```
tests/cli/
├── test_p3_models_list.py      # P3-1: models list tests
├── test_p3_models_download.py   # P3-2: models download tests
├── test_p3_models_verify.py    # P3-3: models verify tests
└── test_p3_models_remove.py    # P3-4: models remove tests
```

### Test Script Template

Each test script follows the established pattern from Phases 1-3:

```python
#!/usr/bin/env python3
"""
Phase 4 Test: P3-X <Command Name>

Tests <command> with assertions.
"""

import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, Tuple, List

# Test results storage
test_results: List[Dict[str, any]] = []

# Configuration
TIMEOUTS = {
    "models_list": 30,
    "models_download": 600,
    "models_verify": 60,
    "models_remove": 30,
}

def run_command(cmd, timeout):
    """Run command and return (exit_code, stdout, stderr, duration)."""
    # ... implementation

def assert_success(result, timeout, test_name):
    """Assert command succeeded within timeout."""
    # ... implementation

# Test functions
def test_models_list_installed():
    """List-1: List installed models."""
    # ... implementation

def test_models_download_new():
    """Download-1: Download new model."""
    # ... implementation
```

---

## Commands Under Test

### P3-1: `synapse models list`

List available and installed models.

**Usage**:
```
synapse models list
synapse models list --verbose
```

**Expected Behavior**:
- Display installed models with name, size, path
- Show download status (installed/downloaded)
- Support `--verbose` for detailed output

---

### P3-2: `synapse models download`

Download model from HuggingFace.

**Usage**:
```
synapse models download <model_id>
synapse models download <model_id> --force
```

**Expected Behavior**:
- Download specified model from HuggingFace
- Show download progress
- Support `--force` to re-download
- Validate model integrity after download

---

### P3-3: `synapse models verify`

Verify installed model integrity.

**Usage**:
```
synapse models verify
synapse models verify <model_id>
```

**Expected Behavior**:
- Check model file integrity (checksum)
- Report any corruption or missing files
- Support verifying specific model
- Return exit code 0 if valid, non-zero if issues found

---

### P3-4: `synapse models remove`

Remove installed model.

**Usage**:
```
synapse models remove <model_id>
synapse models remove <model_id> --force
```

**Expected Behavior**:
- Remove specified model from local storage
- Confirm removal or prompt for confirmation
- Support `--force` to skip confirmation
- Update model registry after removal

---

## Test Cases

### P3-1: Models List Tests

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| List-1 | List installed models | Exit 0, shows BGE-M3 |
| List-2 | List with verbose | Exit 0, shows detailed info |
| List-3 | List no models | Exit 0, shows "no models" |
| List-4 | Performance test | Exit 0, < 5s |

### P3-2: Models Download Tests

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| Download-1 | Download existing model | Exit 0, "already installed" |
| Download-2 | Download new model | Exit 0, progress shown |
| Download-3 | Download with force | Exit 0, re-downloads |
| Download-4 | Invalid model | Exit != 0, error shown |
| Download-5 | Performance | < 300s for 600MB model |

### P3-3: Models Verify Tests

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| Verify-1 | Verify installed model | Exit 0, "valid" |
| Verify-2 | Verify specific model | Exit 0, model status |
| Verify-3 | Verify corrupted model | Exit != 0, "invalid" |
| Verify-4 | Verify missing model | Exit != 0, error shown |

### P3-4: Models Remove Tests

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| Remove-1 | Remove with confirmation | Exit 0, removed |
| Remove-2 | Remove with force | Exit 0, removed |
| Remove-3 | Remove active model | Exit != 0, warning |
| Remove-4 | Remove missing model | Exit != 0, error shown |

---

## Performance Thresholds

| Command | Threshold | Notes |
|---------|-----------|-------|
| models list | < 5s | Quick registry read |
| models download | < 300s | 600MB model download |
| models verify | < 60s | Checksum verification |
| models remove | < 30s | File deletion |

---

## Dependencies

- MCP server running (for model registry access)
- Network connectivity (for downloads)
- Sufficient disk space (600MB+ for models)
- Write access to `~/.synapse/models/`

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Network timeout | High | Increase timeout for downloads |
| Disk space full | High | Check space before download |
| Model corruption | Medium | Verify checksums after download |
| Concurrent access | Low | Sequential testing |

---

## Completion Criteria

- All P3 test scripts created
- All test cases implemented
- 90%+ test pass rate
- Performance thresholds met
- Results documented in PHASE_4_RESULTS.md
- Central index updated

---

## Timeline Estimate

- **Phase 4.1**: Create test infrastructure (1 hour)
- **Phase 4.2**: Implement models list tests (1 hour)
- **Phase 4.3**: Implement models download tests (1 hour)
- **Phase 4.4**: Implement models verify tests (1 hour)
- **Phase 4.5**: Implement models remove tests (1 hour)
- **Phase 4.6**: Execute tests & fix bugs (2 hours)
- **Phase 4.7**: Documentation & completion (1 hour)

**Total**: ~8 hours (7 phases)
