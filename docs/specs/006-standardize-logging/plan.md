# Technical Plan: Standardize Logging System

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Application                       │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐              │
│  │  CLI Scripts │  │  RAG Modules │              │
│  │   (Rich)     │  │   (logger)   │              │
│  └──────┬───────┘  └──────┬───────┘              │
│         │                  │                         │
│         │ console.print()  │ logger.*()             │
│         │ logger.info()    │                         │
│         └────────┬─────────┘                         │
│                  │                                   │
│         ┌────────▼─────────┐                         │
│         │  core/logger.py   │                         │
│         │  setup_logging() │                         │
│         │  get_logger()    │                         │
│         └────────┬─────────┘                         │
│                  │                                   │
│         ┌────────▼─────────┐                         │
│         │  logging (std)  │                         │
│         │  StreamHandler  │                         │
│         │  FileHandler    │                         │
│         └────────┬─────────┘                         │
└──────────────────┼───────────────────────────────────┘
                   │
        ┌──────────▼───────────┐
        │  /opt/synapse/logs/  │
        │  rag.log             │
        └──────────────────────┘
```

## Component Design

### 1. Logging Utility (`core/logger.py`)

```python
class LoggerManager:
    """Manages logging configuration and logger instances."""

    def __init__(self):
        self._loggers: Dict[str, logging.Logger] = {}
        self._configured = False

    def setup_logging(
        self,
        level: Optional[str] = None,
        log_file: Optional[str] = None,
        debug_flag: bool = False
    ) -> None:
        """Configure root logging with environment detection."""

        # Priority 1: Debug flag
        if debug_flag:
            log_level = logging.DEBUG
        # Priority 2: Environment variable
        elif os.environ.get("LOG_LEVEL"):
            log_level = getattr(
                logging,
                os.environ["LOG_LEVEL"].upper(),
                logging.INFO
            )
        # Priority 3: Default from config
        else:
            log_level = logging.INFO

        # Environment detection
        env = os.environ.get("ENV", "dev")
        if env == "production":
            default_level = logging.INFO
        else:
            default_level = logging.DEBUG

        # Use configured or default level
        final_level = log_level or default_level

        # Setup handlers
        formatter = logging.Formatter(
            '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(final_level)
        console_handler.setFormatter(formatter)

        # File handler (if configured)
        file_handler = None
        if log_file:
            from logging.handlers import RotatingFileHandler
            file_handler = RotatingFileHandler(
                log_file,
                maxBytes=10485760,  # 10MB
                backupCount=5
            )
            file_handler.setLevel(final_level)
            file_handler.setFormatter(formatter)

        # Configure root logger
        root_logger = logging.getLogger()
        root_logger.setLevel(final_level)
        root_logger.handlers.clear()
        root_logger.addHandler(console_handler)

        if file_handler:
            root_logger.addHandler(file_handler)

        self._configured = True

    def get_logger(self, name: str) -> logging.Logger:
        """Get or create logger instance."""
        if not self._configured:
            self.setup_logging()

        if name not in self._loggers:
            self._loggers[name] = logging.getLogger(name)

        return self._loggers[name]
```

### 2. Configuration (`configs/logging_config.json`)

```json
{
  "version": "1.0",
  "environment": "dev",
  "default_level": {
    "dev": "DEBUG",
    "production": "INFO"
  },
  "file_logging": {
    "enabled": true,
    "path": "/opt/synapse/logs/rag.log",
    "max_bytes": 10485760,
    "backup_count": 5
  },
  "module_overrides": {
    "rag.orchestrator": "INFO",
    "rag.model_manager": "INFO",
    "rag.embedding": "INFO"
  }
}
```

### 3. CLI Integration Pattern

```python
# scripts/bulk_ingest.py
from rich.console import Console
from core.logger import get_logger
import argparse

console = Console()
logger = get_logger(__name__)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--debug', '-d', action='store_true',
                       help='Enable DEBUG logging')
    args = parser.parse_args()

    # Setup logging with debug flag
    if args.debug:
        os.environ["LOG_LEVEL"] = "DEBUG"

    # Rich output + logger duplication
    console.print(f"Ingesting directory: {directory}")
    logger.info(f"Ingesting directory: {directory}")

    # Progress bar (Rich only, logger tracks completion)
    with console.console.status("[bold green]Processing..."):
        # ... process files ...
        logger.info(f"Completed: {len(files)} files processed")
```

## Data Schema

### Log Entry Format
```
2025-01-07 14:30:45 | INFO     | rag.orchestrator | Ingesting 10 files
2025-01-07 14:30:46 | WARNING  | rag.embedding    | Model not found, using mock
2025-01-07 14:30:47 | ERROR    | rag.ingest      | Failed to ingest file.txt
```

### Module-Level Overrides
- `core.orchestrator`: INFO (reduce noise from orchestrator)
- `core.model_manager`: INFO (important lifecycle events)
- `core.embedding`: INFO (model loading status)
- `core.memory_writer`: WARNING (only errors, no debug noise)

## Dependencies

### Internal
- `mcp_server/production_logger.py` - No changes (MCP uses it)
- Existing logging setup in 17 modules

### External
- Python `logging` (standard library, always available)
- `rich` (for CLI scripts, already used in bulk_ingest.py)

## Migration Strategy

### Print → Logger Mapping

| Pattern | Log Level | Example |
|----------|-----------|---------|
| `print("Warning: ...")` | `logger.warning()` | Warnings, deprecations |
| `print("Error: ...")` | `logger.error()` | Errors, exceptions |
| `print("⚠️ ...")` | `logger.warning()` | Warnings (emoji removed) |
| `print("Loading ...")` | `logger.info()` | Status updates |
| `print(results)` | `logger.debug()` | Debug output |
| `print("="*50)` | Skip | Visual separators (Rich handles) |
| `print("Usage: ...")` | Keep as `print()` | CLI help messages |

### File-by-File Migration Order

1. **Core Infrastructure** (Week 1)
   - `core/logger.py` - NEW
   - `configs/logging_config.json` - NEW
   - Update `configs/rag_config.json`

2. **Core Modules** (Week 1-2)
   - `core/orchestrator.py` (6 prints)
   - `core/model_manager.py` (6 prints)
   - `core/embedding.py` (6 prints)
   - `core/semantic_store.py` (2 prints)
   - `core/vectorstore.py` (3 prints)

3. **Tool Scripts** (Week 2)
   - `scripts/bulk_ingest.py` (20 prints) - Rich + logger
   - `core/ingest.py` (5 prints)
   - `core/semantic_ingest.py` (5 prints)

4. **Memory Modules** (Week 2-3)
   - `core/retriever.py` (2 prints)
   - `core/memory_writer.py` (8 prints)
   - `core/episode_extractor.py` (3 prints)

5. **Docstrings** (Week 3)
   - Update all 6 files with `>>> print()` examples

## Risk Assessment

### High Risk
- **Risk**: Breaking existing tests that expect print output
  - **Mitigation**: Update tests to mock or assert logger calls
  - **Contingency**: Keep print for test fixtures if needed

### Medium Risk
- **Risk**: Rich + logger duplication causes performance issues
  - **Mitigation**: Measure performance overhead before merge
  - **Contingency**: Optimize with conditional logging

### Low Risk
- **Risk**: Developer confusion about log level configuration
  - **Mitigation**: Document priority (flag > env > config)
  - **Contingency**: Add debug logging to show effective level

## Testing Strategy

### Unit Tests
- `tests/test_logging.py` - Logger setup, configuration, singleton
- Mock logger calls in existing tests

### Integration Tests
- Verify log file creation and rotation
- Test environment detection (dev vs prod)
- Test `--debug` flag behavior
- Test Rich + logger output consistency

### Manual Testing
- Run ingestion scripts with `--debug`
- Verify log file contains all output
- Check no print statements in production
- Test log rotation (fill 10MB file)

## Rollback Plan

If issues discovered after merge:
1. Revert feature branch: `git revert <commit-hash>`
2. Restore original print statements
3. Document rollback reason

Rollback criteria:
- Production logs grow too large (>100MB/day)
- Performance regression >10%
- User experience degradation in CLI scripts

## Success Criteria

- ✅ All 75+ print statements replaced (except CLI help)
- ✅ All emojis removed from log messages
- ✅ CLI scripts keep Rich output
- ✅ File logging working with rotation
- ✅ `--debug` flag overrides log level
- ✅ Dev: DEBUG logs, Prod: INFO logs
- ✅ No tests broken
- ✅ Documentation updated
