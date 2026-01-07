# Requirements: Standardize Logging System

## User Stories

### US1: Developer Wants Structured Logs
**As a** developer working on Synapse,
**I want** all modules to use Python's standard logging module,
**So that** I can configure log levels, formats, and output destinations consistently.

**Acceptance Criteria:**
- All `print()` statements replaced with `logger.*()` calls
- Logging level configurable via environment variable
- Dev environment: DEBUG level enabled
- Prod environment: INFO level enabled

### US2: Production Team Wants Minimal Logs
**As a** production operator,
**I want** production logs to be concise (INFO and above only),
**So that** log files don't fill with debug output.

**Acceptance Criteria:**
- Production environment logs only INFO, WARNING, ERROR, CRITICAL
- Can override with `--debug` flag for troubleshooting
- No DEBUG output in production by default

### US3: User Wants Rich CLI Output
**As a** user running ingestion scripts,
**I want** colorful progress bars and formatted output,
**So that** I can track progress visually.

**Acceptance Criteria:**
- CLI scripts (bulk_ingest.py, ingest.py) keep Rich output
- Rich progress bars unchanged
- File logging captures all output for debugging

### US4: Operations Team Wants File Logs
**As an** operations team member,
**I want** logs written to file,
**So that** I can review historical activity and debug issues.

**Acceptance Criteria:**
- Logs written to `/opt/synapse/logs/rag.log`
- Log rotation configured (10MB max, 5 backups)
- Timestamped, structured format

### US5: Developer Wants Debug Override
**As a** developer troubleshooting production issues,
**I want** to enable DEBUG logging with `--debug` flag,
**So that** I can see detailed execution flow.

**Acceptance Criteria:**
- `--debug` flag overrides log level to DEBUG
- Works in both dev and prod environments
- Flag recognized by all CLI scripts

## Functional Requirements

### FR1: Logging Utility Module
- Create `rag/logger.py` with unified logging setup
- Functions: `setup_logging()`, `get_logger()`
- Singleton pattern for logger instances

### FR2: Configuration System
- Create `configs/logging_config.json`
- Support environment variable overrides (`LOG_LEVEL`)
- Support command-line debug flag (`--debug`)
- Priority: `--debug` > `LOG_LEVEL` > config file

### FR3: Environment-Specific Behavior
- Development: `LOG_LEVEL=DEBUG` by default
- Production: `LOG_LEVEL=INFO` by default
- Detect environment via `ENV` variable or config

### FR4: Rich + Logger Integration
- CLI scripts: Keep Rich for user-facing output
- Duplicate all Rich output to logger for file logs
- Maintain backward-compatible user experience

### FR5: Print Statement Replacement
- Replace 75+ `print()` statements across codebase
- Remove all emojis from log messages
- Use appropriate log levels:
  - `print("Warning: ...")` → `logger.warning()`
  - `print("Error: ...")` → `logger.error()`
  - `print("Loading ...")` → `logger.info()`
  - `print(results)` (debug) → `logger.debug()`

## Non-Functional Requirements

### NFR1: Performance
- Logging overhead < 5% of execution time
- No blocking I/O operations in critical paths
- Asynchronous file writing where possible

### NFR2: Maintainability
- Consistent log format across all modules
- Clear module names in log entries
- Easy to configure and customize

### NFR3: Reliability
- Logging failures should not crash application
- Graceful degradation if log file unavailable
- Thread-safe logger instances

## Technical Constraints

- Use Python standard `logging` module only
- No external logging libraries
- Keep `mcp_server/production_logger.py` unchanged (MCP uses it)
- Backward compatibility not required (strict replacement)

## Out of Scope

- Logging metrics/analytics (handled by existing metrics system)
- Distributed tracing (not required for this feature)
- Log aggregation/Loki integration (existing functionality)
