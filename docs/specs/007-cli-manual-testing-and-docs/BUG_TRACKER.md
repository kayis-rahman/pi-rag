# Bug Tracker - CLI Commands

**Feature ID**: 007-cli-manual-testing-and-docs
**Created**: January 7, 2026
**Updated**: February 8, 2026
**Status**: [In Progress]
**Naming Convention**: `sy` (updated from `python -m synapse.cli.main`)

---

## Severity Levels

- **Critical**: Server crashes, data loss, security issues
- **High**: Major functionality broken, bad UX
- **Medium**: Minor functionality issues, edge cases
- **Low**: Cosmetic issues, documentation errors

## Bug Status

- **New**: Bug discovered, not investigated
- **Investigating**: Root cause analysis in progress
- **Fixed**: Bug resolved and tested
- **Acknowledged**: Known issue, will fix later
- **Enhancement**: Feature request, not a bug
- **Can't Reproduce**: Unable to reproduce bug

---

## Bugs Summary (February 8, 2026 Session)

| Bug ID | Command | Severity | Description | Status |
|--------|---------|----------|-------------|--------|
| BUG-001 | start | High | TypeError in CalledProcessError | Fixed |
| BUG-002 | start | High | Config path hardcoded | Fixed |
| BUG-003 | models | Medium | Model name registry incomplete | Fixed |
| BUG-007-001 | query | Medium | Intermittent HTTP 500 errors | Investigating |
| BUG-007-002 | stop | Low | Permission warning | Acknowledged |
| BUG-007-003 | status/config | Low | Verbose mode identical | Enhancement |
| BUG-007-004 | ingest | Low | DeprecationWarning | Acknowledged |
| BUG-007-005 | ingest | Low | Llama context overflow | Investigating |
| BUG-007-006 | ingest | Low | Embedding override warnings | Investigating |
| BUG-007-007 | ingest | Medium | Semantic store chunk load | Investigating |

---

## New Bugs (February 8, 2026 Session)

### BUG-007-001: Intermittent HTTP 500 Errors on Server Endpoints

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-007-001 |
| **Command** | `sy query`, `sy status` |
| **Severity** | Medium |
| **Status** | [Investigating] |
| **Found Date** | February 8, 2026 |
| **Tester** | opencode |

**Description**:
Server occasionally returns HTTP 500 Internal Server Error on query and status endpoints, even though health check shows the server is healthy.

**Reproduction Steps**:
1. Start server: `sy start`
2. Wait 2-3 seconds
3. Run query: `sy query "test"`
4. Sometimes returns HTTP 500 error
5. Retry 2-3 times, server stabilizes

**Expected Behavior**:
Server should consistently return 200 OK on all endpoints.

**Actual Behavior**:
Intermittent HTTP 500 errors on query/status endpoints, health endpoint remains healthy.

**Error Message**:
```
❌ MCP server is not running properly (HTTP 500)
   Start it with: synapse start
```

**Workaround**:
Retry the command 2-3 times. Server stabilizes after initial startup.

---

### BUG-007-002: Stop Command Permission Warning

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-007-002 |
| **Command** | `sy stop` |
| **Severity** | Low |
| **Status** | [Acknowledged] |
| **Found Date** | February 8, 2026 |
| **Tester** | opencode |

**Description**:
The `sy stop` command fails to use `pkill` due to permission issues, showing a warning message even though the fallback mechanism works correctly.

**Output**:
```
🛑 Stopping SYNAPSE server...
🚀 Stopping SYNAPSE native server...
pkill: killing pid failed: Operation not permitted
ℹ️  Note: lsof not available
✓ SYNAPSE native server stopped (fallback)
```

**Impact**:
- Cosmetic issue only
- Fallback mechanism works correctly
- No functional impact on users

---

### BUG-007-003: Verbose Mode Identical to Brief Mode

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-007-003 |
| **Command** | `sy status --verbose`, `sy config --verbose` |
| **Severity** | Low |
| **Status** | [Enhancement] |
| **Found Date** | February 8, 2026 |
| **Tester** | opencode |

**Description**:
The `--verbose` flag for `sy status` and `sy config` commands produces identical output to the brief mode, providing no additional information.

**Expected Behavior**:
Verbose mode should show additional details such as:
- Full configuration values
- Server uptime
- Memory usage
- Connection statistics
- Detailed model information

---

### BUG-007-004: DeprecationWarning in Bulk Ingest

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-007-004 |
| **Command** | `sy ingest` |
| **Severity** | Low |
| **Status** | [Acknowledged] |
| **Found Date** | February 8, 2026 |
| **Tester** | opencode |

**Description**:
Bulk ingest process shows DeprecationWarning for datetime.datetime.utcnow() usage.

**Warning**:
```
/home/dietpi/synapse/scripts/bulk_ingest.py:767: DeprecationWarning: datetime.datetime.utcnow() is deprecated and scheduled for removal in a future version. Use timezone-aware objects to represent datetimes in UTC: datetime.datetime.now(datetime.UTC).
```

**Fix Plan**:
- Update bulk_ingest.py line 767
- Replace datetime.utcnow() with datetime.now(UTC)

---

### BUG-007-005: Llama Context Overflow Warning

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-007-005 |
| **Command** | `sy ingest` |
| **Severity** | Low |
| **Status** | [Investigating] |
| **Found Date** | February 8, 2026 |
| **Tester** | opencode |

**Description**:
Ingest process shows multiple "llama_context: n_ctx_per_seq (8194) > n_ctx_train (512)" warnings during embedding generation.

**Warning**:
```
llama_context: n_ctx_per_seq (8194) > n_ctx_train (512) -- possible training context overflow
```

**Impact**:
- Cosmetic issue
- No functional impact observed
- May indicate embedding model configuration issue

---

### BUG-007-006: Embedding Output Override Warnings

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-007-006 |
| **Command** | `sy ingest` |
| **Severity** | Low |
| **Status** | [Investigating] |
| **Found Date** | February 8, 2026 |
| **Tester** | opencode |

**Description**:
Ingest process shows multiple "init: embeddings required but some input tokens were not marked as outputs" override warnings during embedding generation.

**Warning**:
```
init: embeddings required but some input tokens were not marked as outputs -> overriding
```

**Impact**:
- Cosmetic issue
- No functional impact observed

---

### BUG-007-007: Semantic Store Chunk Load Warning

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-007-007 |
| **Command** | `sy ingest` |
| **Severity** | Medium |
| **Status** | [Investigating] |
| **Found Date** | February 8, 2026 |
| **Tester** | opencode |

**Description**:
Semantic store shows warning about failed chunk loading due to JSON parsing error.

**Warning**:
```
WARNING | rag.semantic_store | Failed to load chunks: Expecting ',' delimiter: line 72576 column 26 (char 2062995)
```

**Impact**:
- Existing chunks not loaded during incremental ingestion
- May cause duplicate chunk creation
- Increases processing time

---

## Previously Fixed Bugs (January 7, 2026 Session)

### BUG-001: TypeError in start command error handling

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-001 |
| **Command** | start |
| **Severity** | High |
| **Status** | Fixed |
| **Discovered** | January 7, 2026 |

**Description**:
When native mode server fails to start, error handling code raises a `TypeError` because `subprocess.CalledProcessError` is called with incorrect arguments.

**Fix**: Updated error handling in `synapse/cli/commands/start.py:134-136`

---

### BUG-002: Config path hardcoded causing FileNotFoundError

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-002 |
| **Command** | start |
| **Severity** | High |
| **Status** | Fixed |
| **Discovered** | January 7, 2026 |

**Description**:
Config path was hardcoded to `Path.cwd() / "configs" / "rag_config.json"` which doesn't resolve correctly in all execution contexts.

**Fix**: Added path resolution logic with multiple fallback locations in `synapse/cli/commands/start.py:100-122`

---

### BUG-003: Model name registry incomplete

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-003 |
| **Command** | models |
| **Severity** | Medium |
| **Status** | Fixed |
| **Discovered** | January 7, 2026 |

**Description**:
Model name `bge-m3` is not recognized by `models download/verify/remove` commands, even though it's shown in config and `models list`.

**Fix**: Added `find_model_by_name_or_type()` helper function and updated model registry in `synapse/cli/commands/models.py`

---

## Bug Statistics

| Severity | Count | Fixed | Open | Acknowledged | Enhancement |
|----------|-------|-------|------|--------------|-------------|
| Critical | 0 | 0 | 0 | 0 | 0 |
| High | 2 | 2 | 0 | 0 | 0 |
| Medium | 3 | 1 | 1 | 0 | 0 |
| Low | 5 | 0 | 0 | 2 | 1 |
| **Total** | **10** | **3** | **1** | **2** | **1** |

---

## Bugs by Command

| Command | Bugs Found | Fixed | Open | Notes |
|---------|------------|-------|------|-------|
| start | 2 | 2 | 0 | Fixed Jan 7 |
| stop | 1 | 0 | 0 | Permission warning |
| status | 1 | 0 | 0 | Verbose mode |
| config | 1 | 0 | 0 | Verbose mode |
| ingest | 4 | 0 | 4 | Various warnings |
| query | 1 | 0 | 1 | HTTP 500 errors |
| models | 1 | 1 | 0 | Fixed Jan 7 |
| setup | 0 | 0 | 0 | Not tested |
| onboard | 0 | 0 | 0 | Not tested |

---

## Test Results Summary

**Date**: February 8, 2026
**Tester**: opencode
**Commands Tested**: 8/12 (67%)

| Command | Status | Tests |
|---------|--------|-------|
| `sy --help` | ✅ PASS | 1/1 |
| `sy status` | ✅ PASS | 2/2 |
| `sy config` | ✅ PASS | 2/2 |
| `sy models list` | ✅ PASS | 1/1 |
| `sy start` | ✅ PASS | 2/2 |
| `sy stop` | ✅ PASS | 1/1 |
| `sy query` | ✅ PASS | 1/1 |
| `sy ingest` | ✅ PASS | 1/1 |

**Ingestion Results**: 11 files processed, 380 chunks created

---

## Related Documents

- **Test Results**: MANUAL_TEST_RESULTS.md
- **Tasks**: tasks.md
- **Requirements**: requirements.md
- **Plan**: plan.md

---

## Change Log

| Date | Bug ID | Change | Author |
|------|--------|--------|---------|
| 2026-01-07 | BUG-001,002,003 | Initial bug tracker created | opencode |
| 2026-02-08 | BUG-007-001 to 007-007 | Added 7 new bugs from sy testing | opencode |
| 2026-02-08 | All | Added to RAG memory via sy.mem.ep.add | opencode |

---

**Last Updated**: February 8, 2026
**Maintainer**: opencode
