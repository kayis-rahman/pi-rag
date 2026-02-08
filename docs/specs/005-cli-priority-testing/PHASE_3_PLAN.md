# Phase 3 Plan: Data Operations Testing

**Feature ID**: 005-cli-priority-testing
**Phase**: 3 - Data Operations
**Priority**: P2 (Data Operations)
**Status**: Planning
**Created**: February 7, 2026

---

## Overview

This plan details the testing strategy for P2 commands: `synapse ingest`, `synapse query`, and bulk ingestion functionality. These commands are critical for the core RAG (Retrieval-Augmented Generation) functionality.

---

## Testing Strategy

### Approach: Semi-Automated Scripts with Assertions

Following the pattern established in Phases 1 and 2:
- **Test Scripts**: Python scripts with built-in assertions
- **Manual Execution**: Run scripts and observe results
- **Assertions**: Check exit codes, output format, and performance
- **Documentation**: Record pass/fail + metrics

### Test Environments: All Three Modes

Following Phase 1 pattern (Option 1-A):
1. **Docker Mode**: Running inside `rag-mcp` container
2. **Native Mode**: Direct execution on host system
3. **User Home Mode**: Execution using `~/.synapse/data`

**Order of Testing**:
1. Native mode (primary deployment)
2. Docker mode (if container available)
3. User home mode (fallback/cross-platform)

### Test Data: Existing Project Files

Following Phase 1 pattern (Option 2-No):
- Use existing project files in `docs/specs/`
- Use existing code files in `synapse/`
- No test fixtures required

---

## Architecture & Design

### Test Script Structure

```
tests/cli/
├── test_p2_ingest.py         # P2-1: Ingest command tests
├── test_p2_query.py           # P2-2: Query command tests
└── test_p2_bulk_ingest.py     # P2-3: Bulk ingest tests
```

### Test Script Template

Each test script follows the established pattern from Phases 1-2:

```python
#!/usr/bin/env python3
"""
Phase 3 Test: P2-X <Command Name>

Tests <command> in multiple environments with assertions.
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
    "ingest": 300,  # 5 minutes for large directories
    "query": 10,    # 10 seconds for query
    "bulk": 600,    # 10 minutes for bulk
}

def assert_success(result, timeout, test_name):
    """Assert command succeeded within timeout."""
    # ... implementation

def run_test(test_name, command, timeout, assertions):
    """Run a single test with assertions."""
    # ... implementation

# Test functions
def test_ingest_single_file():
    # ... implementation

def test_ingest_directory():
    # ... implementation

# Main execution
if __name__ == "__main__":
    main()
```

---

## Test Coverage

### P2-1: Ingest Command Tests (8 tests × 2 environments = 16 tests)

| Test | Description | Assertions |
|------|-------------|------------|
| Ingest-1 | Single file | Exit code 0, chunks created > 0 |
| Ingest-2 | Directory recursive | Exit code 0, processes N files |
| Ingest-3 | Skip binary files | Exit code 0, binary files skipped |
| Ingest-4 | Skip hidden files | Exit code 0, hidden files skipped |
| Ingest-5 | Invalid path | Exit code != 0, clear error |
| Ingest-6 | Permission error | Exit code != 0, permission message |
| Ingest-7 | Progress output | Progress indicator shown |
| Ingest-8 | Statistics output | Files/chunks count shown |

### P2-2: Query Command Tests (8 tests × 2 environments = 16 tests)

| Test | Description | Assertions |
|------|-------------|------------|
| Query-1 | Simple query | Exit code 0, results returned |
| Query-2 | JSON format | Exit code 0, valid JSON output |
| Query-3 | Text format | Exit code 0, readable text output |
| Query-4 | Top-k parameter | Exit code 0, N results returned |
| Query-5 | No results query | Exit code 0, empty results |
| Query-6 | Citations included | Results include source/citation |
| Query-7 | Performance | Returns within 5 seconds |
| Query-8 | MCP unavailable | Exit code != 0, helpful message |

### P2-3: Bulk Ingest Tests (6 tests × 2 environments = 12 tests)

| Test | Description | Assertions |
|------|-------------|------------|
| Bulk-1 | Process directory | Exit code 0, files processed |
| Bulk-2 | .gitignore | Exit code 0, .git files skipped |
| Bulk-3 | Progress indicator | Progress shown during processing |
| Bulk-4 | Statistics | Exit code 0, stats reported |
| Bulk-5 | Chunk size config | Exit code 0, custom chunk size used |
| Bulk-6 | Partial failure | Exit code 0, errors logged, continues |

---

## Performance Requirements

| Operation | Time Limit | Measurement |
|-----------|------------|-------------|
| Single file ingest | < 5 seconds | Per file |
| Directory ingest (10 files) | < 30 seconds | Total |
| Query (simple) | < 5 seconds | Per query |
| Bulk ingest (100 files) | < 5 minutes | Total |

---

## Error Handling Tests

### Expected Errors

1. **Invalid Path**: Command exits with code 1, shows "Path does not exist"
2. **Permission Denied**: Command exits with code 1, shows "Permission denied"
3. **MCP Unavailable**: Command exits with code 1, shows "MCP server not running"
4. **Encoding Error**: Command logs warning, skips file, continues
5. **Partial Failure**: Command continues, logs errors, exits 0 with stats

### Error Recovery

- Ingest: Failed files logged, rest continue
- Query: Clean error, no partial output
- Bulk: Full retry logic, checkpoint on failure

---

## Dependencies

| Dependency | Status | Notes |
|------------|---------|-------|
| MCP Server | Required | Must be running for ingest/query |
| BGE-M3 Model | Required | Must be installed |
| Semantic Memory | Required | Must be initialized |
| Test Files | Available | docs/specs/, synapse/ |

---

## Risks & Mitigations

### Risk-1: MCP Server Dependency
**Risk**: Ingest/query require running MCP server
**Mitigation**: Add `synapse start` to test setup, verify server health before tests

### Risk-2: Long Test Durations
**Risk**: Bulk ingest tests may take 5+ minutes
**Mitigation**: Add timeout handling, progress indicators, allow Ctrl+C

### Risk-3: Data Persistence
**Risk**: Tests may leave data in semantic memory
**Mitigation**: Add cleanup step after tests, use unique project IDs

### Risk-4: Model Loading
**Risk**: First query may be slow (model loading)
**Mitigation**: Add warm-up query before performance tests

---

## Test Execution Plan

### Phase 3.1: Test Infrastructure
1. Create test directory: `tests/cli/`
2. Create test files: `test_p2_ingest.py`, `test_p2_query.py`, `test_p2_bulk_ingest.py`
3. Add shared utilities to `conftest.py`

### Phase 3.2: P2-1 Ingest Tests
1. Implement test functions for ingest
2. Test in native mode
3. Test in Docker mode (if available)
4. Document results

### Phase 3.3: P2-2 Query Tests
1. Implement test functions for query
2. Test in native mode
3. Test in Docker mode (if available)
4. Document results

### Phase 3.4: P2-3 Bulk Ingest Tests
1. Implement test functions for bulk ingest
2. Test in native mode
3. Test in Docker mode (if available)
4. Document results

### Phase 3.5: Documentation
1. Create PHASE_3_RESULTS.md
2. Update central index.md
3. Mark Phase 3 complete

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Tests Created | 44 tests | Count |
| Tests Passing | 90%+ | Pass rate |
| Performance | 95%+ | Within time limits |
| Error Handling | 100% | Clear error messages |
| Coverage | 100% | All FRs tested |

---

## Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| 3.1 Infrastructure | 30 min | 3 tasks |
| 3.2 Ingest Tests | 1 hour | 8 tests |
| 3.3 Query Tests | 1 hour | 8 tests |
| 3.4 Bulk Tests | 1 hour | 6 tests |
| 3.5 Documentation | 30 min | 3 tasks |
| **Total** | **4 hours** | **~45 tasks** |

---

## Next Steps

1. Review and approve this plan
2. Create PHASE_3_TASKS.md with granular task breakdown
3. Begin Phase 3.1: Test Infrastructure setup
4. Execute tests following the plan

---

**Status**: Ready for User Review
**Created**: February 7, 2026
