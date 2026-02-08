# Phase 5 Plan: Advanced Features Testing

**Feature ID**: 005-cli-priority-testing
**Phase**: 5 - Advanced Features
**Priority**: P4 (Advanced Features)
**Status**: Planning
**Created**: February 8, 2026

---

## Overview

This plan details the testing strategy for P4/P5 commands: `synapse onboard` (Onboarding Wizard) and any remaining commands. The onboarding wizard is the primary interactive command that guides users through initial setup.

---

## Testing Strategy

### Approach: Semi-Automated Scripts with Assertions

Following the pattern established in Phases 1-4:
- **Test Scripts**: Python scripts with built-in assertions
- **Manual Execution**: Run scripts and observe results
- **Assertions**: Check exit codes, output format, and help output
- **Documentation**: Record pass/fail + metrics

### Test Environments: Native Mode Only

Following Phase 4 pattern:
- **Native Mode**: Direct execution on host system (primary)

### Test Data: No Fixtures Required

Following established pattern:
- Use existing configuration
- No test fixtures required

---

## Architecture & Design

### Test Script Structure

```
tests/cli/
├── test_p4_onboard.py    # P4: Onboarding Wizard tests
└── test_p5_remaining.py  # P5: Any remaining command tests
```

### Test Script Template

Each test script follows the established pattern:

```python
#!/usr/bin/env python3
"""
Phase 5 Test: P4-X <Command Name>

Tests <command> with assertions.
"""

import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, Tuple, List

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from conftest import (
    run_command,
    record_test_result,
    run_onboard_command,
    verify_onboard_output,
    ONBOARD_TIMEOUTS,
    ONBOARD_THRESHOLDS
)

# Test results storage
test_results: List[Dict[str, any]] = []

# Configuration
ONBOARD_TIMEOUTS = {
    "onboard_quick": 120,
    "onboard_help": 30,
    "onboard_silent": 60,
}

def test_onboard_help():
    """Test-1: Help output."""
    # ... implementation
```

---

## Commands Under Test

### P4-1: `synapse onboard`

SYNAPSE Onboarding Wizard - Interactive first-time setup.

**Usage**:
```
synapse onboard                    # Interactive mode
synapse onboard --quick            # Quick mode (all defaults)
synapse onboard --silent           # Silent mode (no prompts)
synapse onboard --skip-test        # Skip quick test
synapse onboard --skip-ingest      # Skip file ingestion
synapse onboard --offline          # Offline mode (no downloads)
synapse onboard --project-id XXX   # Project ID (silent mode only)
```

**Expected Behavior**:
- Interactive mode: Guides through environment config, model download, project init
- Quick mode: Uses all defaults, runs quickly
- Silent mode: No prompts, uses command line args
- Skip options: Can skip specific steps
- Offline mode: Skips downloads

---

## Test Cases

### P4-1: Onboarding Wizard Tests

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| Onboard-1 | Help output | Exit 0, shows options |
| Onboard-2 | Quick mode | Exit 0, quick execution |
| Onboard-3 | Silent mode | Exit 0, no prompts |
| Onboard-4 | Skip test | Exit 0, skips test |
| Onboard-5 | Skip ingest | Exit 0, skips ingestion |
| Onboard-6 | Offline mode | Exit 0, no downloads |
| Onboard-7 | Project ID | Exit 0, uses provided ID |

---

## Performance Thresholds

| Command | Threshold | Notes |
|---------|-----------|-------|
| onboard --help | < 5s | Quick help display |
| onboard --quick | < 120s | Quick mode execution |
| onboard --silent | < 60s | Silent mode execution |

---

## Dependencies

- MCP server running (for some operations)
- Network connectivity (unless --offline)
- Write access to `~/.synapse/`
- Sufficient disk space

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Interactive prompts | High | Use --quick or --silent modes |
| Long execution time | Medium | Set appropriate timeouts |
| Network dependency | Medium | Test with --offline flag |

---

## Completion Criteria

- All P4 test scripts created
- All test cases implemented
- 90%+ test pass rate
- Results documented in PHASE_5_RESULTS.md
- Central index updated

---

## Timeline Estimate

- **Phase 5.1**: Create test infrastructure (1 hour)
- **Phase 5.2**: Implement onboard tests (2 hours)
- **Phase 5.3**: Execute tests & fix bugs (1 hour)
- **Phase 5.4**: Documentation & completion (1 hour)

**Total**: ~5 hours (4 phases)
