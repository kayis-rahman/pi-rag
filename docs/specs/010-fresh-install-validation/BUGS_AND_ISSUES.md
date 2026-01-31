# Fresh Installation Validation - Bugs and Issues

**Feature ID**: 010-fresh-install-validation  
**Created**: January 31, 2026  
**Status**: In Progress

---

## Bugs Discovered

### BUG-001: Status Command Shows Wrong State
**Severity**: Medium  
**Status**: Confirmed

**Description:**
The `synapse status` command incorrectly reports the server as "stopped" even when the server is actually running and responding to health checks.

**Reproduction Steps:**
1. Start MCP server (or verify it's running): `curl http://localhost:8002/health`
2. Run status command: `python3 -m synapse.cli.main status`
3. Observe output: "Status: ❌ stopped"
4. Verify server is actually running: `curl http://localhost:8002/health` returns `{"status": "ok"}`

**Expected Behavior:**
- Status should show "running" when server responds to health checks
- Status should accurately reflect actual server state

**Actual Behavior:**
- Status shows "stopped" even when server is healthy
- Health endpoint responds correctly

**Root Cause:**
The status command likely checks for process existence or port binding, but the check is not finding the existing process correctly. The server was started via `python3 -m mcp_server.http_wrapper` which might not match the expected process pattern.

**Impact:**
- Users may think the server is not running when it actually is
- Could lead to confusion and duplicate server starts
- Affects CLI credibility

**Suggested Fix (No Code Changes Made):**
- Investigate process detection logic in status command
- Add fallback to check health endpoint as verification
- Add more robust process finding (check for "mcp_server" or "rag_server" in process args)

---

### BUG-002: Stop Command Doesn't Stop Server
**Severity**: High  
**Status**: Confirmed

**Description:**
The `synapse stop` command doesn't actually stop the running server. The command reports "Stopping..." but the server continues running.

**Reproduction Steps:**
1. Verify server is running: `curl http://localhost:8002/health`
2. Run stop command: `python3 -m synapse.cli.main stop`
3. Check output: "Stopping SYNAPSE native server..."
4. Verify server status: `curl http://localhost:8002/health`
5. Observe: Server still responds (status: ok)

**Expected Behavior:**
- Stop command should terminate the server process
- Server should no longer respond to health checks
- Port 8002 should be released

**Actual Behavior:**
- Stop command runs without error
- Server continues running
- Port remains in use
- No error or warning about failure to stop

**Root Cause:**
The stop command likely uses `lsof -i :8002` or similar to find and kill the process, but either:
- The process detection fails
- The kill signal is not sent correctly
- The process is being restarted automatically

**Impact:**
- Users cannot stop the server via CLI
- Port conflicts when trying to restart
- Server runs indefinitely
- Resource leak (memory, CPU)

**Suggested Fix (No Code Changes Made):**
- Add better process detection (check for exact PID in known locations)
- Add verification step after kill attempt
- Add error message if stop fails
- Try multiple kill signals (SIGTERM, then SIGKILL)
- Check if port is still bound after stop attempt

---

### BUG-003: Runtime Warning on CLI Import
**Severity**: Low  
**Status**: Low Priority

**Description:**
Running `python3 -m synapse.cli.main` produces a RuntimeWarning about module import order.

**Reproduction Steps:**
1. Run any CLI command: `python3 -m synapse.cli.main --help`
2. Observe warning: "RuntimeWarning: 'synapse.cli.main' found in sys.modules after import of package 'synapse.cli'"

**Expected Behavior:**
- No warnings or errors on CLI execution
- Clean startup

**Actual Behavior:**
- RuntimeWarning displayed before command output
- Doesn't affect functionality but looks unprofessional

**Impact:**
- Minor cosmetic issue
- May confuse users
- Could mask real errors

**Suggested Fix (No Code Changes Made):**
- Reorder imports in main.py to avoid circular dependencies
- Use lazy imports for CLI commands
- Suppress warning if not critical

---

### BUG-004: Config Verbose Mode Doesn't Show All Settings
**Severity**: Low  
**Status**: Low Priority

**Description:**
The `--verbose` flag for `synapse config` doesn't show significantly more information than the basic mode.

**Reproduction Steps:**
1. Run basic config: `python3 -m synapse.cli.main config`
2. Run verbose config: `python3 -m synapse.cli.main config --verbose`
3. Compare outputs: Very similar, verbose doesn't add much

**Expected Behavior:**
- Verbose mode should show all configuration values
- Should show configuration source (default, file, environment)
- Should show hidden settings not displayed in basic mode

**Actual Behavior:**
- Both outputs look nearly identical
- Verbose adds only Host and Port info
- Missing: chunk_size source, environment variables, defaults vs overrides

**Impact:**
- Verbose mode not very useful
- Users can't debug configuration issues easily
- Missing troubleshooting information

**Suggested Fix (No Code Changes Made):**
- Add more settings to verbose output
- Show configuration sources (file path, defaults, env vars)
- Show derived values and calculations
- Add system information (Python version, OS, etc.)

---

## Issues Found (Non-Bugs)

### ISSUE-001: Server Already Running on Port 8002
**Type**: Expected Behavior  
**Status**: Documented

**Description:**
The MCP server was already running on port 8002 when validation started. This prevented `synapse start` from starting a new server.

**Resolution:**
- Verified server was already running via health check
- Proceeded with validation using existing server
- Documented as expected behavior (not a bug)

**Impact:**
- None - server functionality works correctly
- `synapse start` command correctly detects running server
- Minor confusion with `synapse status` (see BUG-001)

---

## Summary

| Bug ID | Severity | Status | Impact |
|--------|----------|--------|--------|
| BUG-001 | Medium | Confirmed | Users see wrong server status |
| BUG-002 | High | Confirmed | Cannot stop server via CLI |
| BUG-003 | Low | Low Priority | Cosmetic warning on startup |
| BUG-004 | Low | Low Priority | Verbose mode not very verbose |

**Total Bugs**: 4 (2 medium/high priority, 2 low priority)

**Recommendation:**
- Fix BUG-002 (stop command) should be high priority as it prevents server management
- Fix BUG-001 (status command) should be medium priority for accurate reporting
- BUG-003 and BUG-004 are cosmetic and can be addressed later

---

## Validation Notes

All bugs were discovered during validation testing. No source code was modified per requirements. All bugs are documented here for future fixes.

**Validation Status:**
- CLI commands work correctly (except start/stop/status logic bugs)
- MCP server is functional
- All features are usable despite bugs
- Workarounds exist for all issues

---

**Last Updated**: January 31, 2026
