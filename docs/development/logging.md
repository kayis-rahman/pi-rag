# Logging Configuration Guide

## Overview

Synapse uses Python's standard `logging` module with a unified logger system. All production code should use `logger` instead of `print()`.

## Quick Start

### Basic Usage

```python
from rag.logger import get_logger

logger = get_logger(__name__)
logger.info("Application started")
logger.warning("Something unusual happened")
logger.error("An error occurred")
```

### CLI Scripts with Debug Flag

```python
import os
import argparse
from rag.logger import setup_logging, get_logger

parser = argparse.ArgumentParser()
parser.add_argument('--debug', '-d', action='store_true',
                   help='Enable DEBUG logging')
args = parser.parse_args()

# Setup logging with debug flag
if args.debug:
    os.environ["LOG_LEVEL"] = "DEBUG"

setup_logging(log_file="/opt/synapse/logs/rag.log")
logger = get_logger(__name__)

logger.info("Starting application")
```

## Log Levels

### Priority (from highest to lowest)

1. **CRITICAL**: Application cannot continue
2. **ERROR**: Error occurred, but application continues
3. **WARNING**: Something unusual or deprecated
4. **INFO**: Normal informational messages
5. **DEBUG**: Detailed diagnostic information

### When to Use Each Level

| Level | Use Case | Example |
|-------|-----------|---------|
| `logger.critical()` | Application crash, cannot continue | `logger.critical("Database connection lost, shutting down")` |
| `logger.error()` | Error that needs investigation | `logger.error(f"Failed to load model: {e}")` |
| `logger.warning()` | Deprecation, fallback, unusual behavior | `logger.warning("Model not found, using mock embeddings")` |
| `logger.info()` | Normal operation, status updates | `logger.info(f"Ingested {count} files")` |
| `logger.debug()` | Detailed diagnostics, variable values | `logger.debug(f"Processing {len(items)} items")` |

## Configuration

### Log Level Priority

The logging level is determined by this priority order:

1. **`--debug` flag** (highest priority)
   - Forces DEBUG level regardless of environment
   - Used for troubleshooting

2. **`LOG_LEVEL` environment variable**
   - Overrides config file and environment detection
   - Values: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`

3. **Config file** (`configs/logging_config.json`)
   - Default level based on environment
   - Values: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`

4. **Environment detection** (lowest priority)
   - Dev environment: `DEBUG`
   - Production environment: `INFO`

### Configuration File

`configs/logging_config.json`:

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

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `LOG_LEVEL` | Override log level | `LOG_LEVEL=DEBUG` |
| `ENV` | Environment for auto-detection | `ENV=production` |

### Command-Line Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--debug`, `-d` | Force DEBUG level | `python scripts/bulk_ingest.py --debug` |

## File Logging

### Configuration

File logging is controlled by `configs/logging_config.json`:

```json
{
  "file_logging": {
    "enabled": true,
    "path": "/opt/synapse/logs/rag.log",
    "max_bytes": 10485760,
    "backup_count": 5
  }
}
```

### Log Rotation

- **Max size**: 10MB per file
- **Backups**: Up to 5 rotated files
- **Naming**: `rag.log`, `rag.log.1`, `rag.log.2`, etc.
- **Automatic**: Rotates when reaching max size

### Log File Location

- **Default**: `/opt/synapse/logs/rag.log`
- **Configurable**: Via `file_logging.path` in config

### File Logging in Code

```python
from rag.logger import setup_logging, get_logger

# Setup with file logging
setup_logging(
    log_file="/opt/synapse/logs/rag.log",
    level="INFO"
)

logger = get_logger(__name__)
logger.info("This goes to both console and file")
```

## Module-Level Overrides

You can set different log levels for specific modules:

```json
{
  "module_overrides": {
    "rag.orchestrator": "INFO",
    "rag.model_manager": "INFO",
    "rag.embedding": "INFO",
    "rag.memory_writer": "WARNING"
  }
}
```

This is useful for:
- Reducing noise from verbose modules
- Focusing on specific components during debugging
- Production environments where only errors matter

## Environment-Specific Behavior

### Development

**Default**: DEBUG level

```bash
# Development (default)
python my_script.py

# Force debug
python my_script.py --debug

# Set specific level
LOG_LEVEL=INFO python my_script.py
```

**What you'll see**:
- All log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Detailed diagnostic information
- Variable values and flow tracking

### Production

**Default**: INFO level

```bash
# Production
ENV=production python my_script.py

# Override for troubleshooting
ENV=production LOG_LEVEL=DEBUG python my_script.py --debug
```

**What you'll see**:
- INFO, WARNING, ERROR, CRITICAL only
- No DEBUG output
- Concise logs for operations

## Log Format

### Standard Format

```
2025-01-07 14:30:45 | INFO     | rag.orchestrator | Ingesting 10 files
2025-01-07 14:30:46 | WARNING  | rag.embedding    | Model not found, using mock
2025-01-07 14:30:47 | ERROR    | rag.ingest      | Failed to ingest file.txt
```

Format breakdown:
- **Timestamp**: `YYYY-MM-DD HH:MM:SS`
- **Level**: 8-character padding (left-aligned)
- **Module**: Python module name
- **Message**: Log message

### MCP Server Logs (ProductionLogger)

MCP server uses `ProductionLogger` with pipe-delimited format:

```
2025-12-29T16:00:00.000Z | INFO | rag-mcp-server | tool=create_project | status=success | latency_ms=45
```

This is intentional - MCP has different logging requirements.

## Best Practices

### DO ✅

```python
# Use appropriate log levels
logger.info("Starting ingestion")
logger.warning("File not found, using fallback")
logger.error(f"Failed to process: {e}")

# Use f-strings for variable interpolation
logger.info(f"Processed {count} files in {duration}s")

# Use structured messages
logger.error(f"Failed to connect to {host}:{port}")

# Keep messages concise and actionable
logger.warning("Rate limit approaching, consider throttling")
```

### DON'T ❌

```python
# Don't use print() in production code
print("This should be logger.info()")

# Don't use emojis in log messages
logger.warning("⚠️ Error occurred")  # Remove emojis

# Don't include sensitive data
logger.info(f"Password: {password}")  # Never log secrets!

# Don't use excessive DEBUG logging
logger.debug("Processing item 1")
logger.debug("Processing item 2")
logger.debug("Processing item 3")
# ... 100 lines ...
# Use log level instead or batch logging
```

## Troubleshooting

### Logs Not Appearing

**Problem**: Log messages not showing up

**Solution**: Check log level configuration
```python
# Force DEBUG level
LOG_LEVEL=DEBUG python script.py

# Or use debug flag
python script.py --debug
```

### Log File Not Created

**Problem**: `/opt/synapse/logs/rag.log` not created

**Solution**:
1. Check directory exists: `ls -la /opt/synapse/logs/`
2. Check permissions: `chmod 755 /opt/synapse/logs/`
3. Verify config: Check `file_logging.enabled` in `configs/logging_config.json`

### Too Much Debug Output

**Problem**: Logs overwhelming with DEBUG messages

**Solution**:
```bash
# Increase log level
LOG_LEVEL=INFO python script.py

# Or use module overrides
# Edit configs/logging_config.json
{
  "module_overrides": {
    "rag.verbose_module": "INFO"
  }
}
```

### Missing Logs from Specific Module

**Problem**: Not seeing logs from a module

**Solution**: Check module name
```python
# Should be __name__ (not hardcoded)
from rag.logger import get_logger
logger = get_logger(__name__)  # ✅ Correct
logger = get_logger("rag.module")  # ✅ Also correct
logger = get_logger("custom_name")  # ⚠️ Might not match expected
```

## Advanced Usage

### Custom Formatter

```python
from rag.logger import setup_logging
import logging

class CustomFormatter(logging.Formatter):
    def format(self, record):
        # Custom formatting
        return f"[{record.levelname}] {record.getMessage()}"

setup_logging(log_file="/opt/synapse/logs/rag.log")

# Apply custom formatter
root_logger = logging.getLogger()
for handler in root_logger.handlers:
    handler.setFormatter(CustomFormatter())
```

### Multiple Log Files

```python
# Setup for different components
from rag.logger import LoggerManager

manager = LoggerManager()
manager.setup_logging(log_file="/opt/synapse/logs/rag.log")

# Add additional handler for errors only
from logging.handlers import RotatingFileHandler
error_handler = RotatingFileHandler(
    "/opt/synapse/logs/errors.log",
    maxBytes=10485760,
    backupCount=5
)
error_handler.setLevel(logging.ERROR)

root_logger = logging.getLogger()
root_logger.addHandler(error_handler)
```

### Async Logging

For high-performance applications:

```python
import logging
from logging.handlers import QueueHandler, QueueListener
import queue

# Setup queue handler
log_queue = queue.Queue(-1)
queue_handler = QueueHandler(log_queue)

# Setup listener
file_handler = logging.FileHandler('/opt/synapse/logs/rag.log')
listener = QueueListener(log_queue, file_handler)
listener.start()

# Configure root logger
root_logger = logging.getLogger()
root_logger.addHandler(queue_handler)

# Use normally
logger = get_logger(__name__)
logger.info("Async logging works!")
```

## References

- Python logging documentation: https://docs.python.org/3/library/logging.html
- Log record attributes: https://docs.python.org/3/library/logging.html#logrecord-attributes
- Best practices: https://docs.python.org/3/howto/logging.html#configuring-logging-for-a-library
