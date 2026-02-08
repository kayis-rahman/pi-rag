# Scripts Directory

This directory contains utility scripts for the pi-rag project.

## Main Scripts

### Bulk Ingestion
- **`bulk_ingest.py`** - Main bulk ingestion tool with .gitignore support
  - Usage: `python scripts/bulk_ingest.py`
  - Docs: `scripts/BULK_INJECT_README.md`
  - Features:
    - .gitignore pattern parsing
    - Checksum-based incremental ingestion
    - Retry mechanism for failed files
    - Rich progress bar with sticky logging
    - File type filtering (code, config, doc, web, data, devops)
    - Custom exclusion patterns

### System Management
- **`rag_status.sh`** - RAG system status checker
  - Usage: `./scripts/rag_status.sh`
  - Shows: System health, RAG status, memory statistics

- **`start_http_server.sh`** - HTTP server control with error logging
  - Usage: `./scripts/start_http_server.sh [option]`
  - Options:
    - (no args) - Start server
    - `--restart` - Restart server
    - `--stop` - Stop server
    - `--status` - Show server status
    - `--errors` - Show error log (last 50 lines)
    - `--clear-errors` - Clear error log file
    - `--help` - Show help message
  - Features:
    - Error logging to `/var/log/pi-core/error.log` (persistent)
    - Main logging to `/tmp/mcp_server.log` (temporary)
    - PID file at `/tmp/mcp_server.pid`
    - Auto-creation of error log directory

## Legacy Scripts (Archived)

The following scripts have been moved to `scripts/legacy/` directory for historical reference:

- `baseline_performance.py` - Performance baseline testing
- `mcp_bulk_ingest.py` - MCP-based bulk ingestion (superseded by `bulk_ingest.py`)
- `quickref.sh` - Quick reference documentation
- `deploy.sh` - Old deployment script
- `manage.sh` - Old management script
- `start_rag_api.sh` - Old API start script

## Testing Scripts (Removed)

The following test scripts have been removed (development only, not production):

- `test_mcp_connection.py`
- `test_mcp_integration.py`
- `test_mcp_server.py`
- `test_mcp_tools.py`
- `test_retrieval_quality.py`
- `test_config_toggles.py`
- `test_query_expansion.py`
- `test_query_expansion_benchmark.py`
- `test_query_expansion_improvement.py`
- `test_remote_ingestion.py`
- `validate_remote_ingestion.py`

## Quick Start

### Bulk Ingestion
```bash
# Preview before ingestion
python scripts/bulk_ingest.py --dry-run

# Ingest all supported files
python scripts/bulk_ingest.py

# Ingest specific file types
python scripts/bulk_ingest.py --file-type code --file-type doc

# Ingest different project
python scripts/bulk_ingest.py --project-id myapp --root-dir /path/to/project
```

### System Management
```bash
# Check RAG status
./scripts/rag_status.sh

# Start HTTP server
./scripts/start_http_server.sh

# View server status
./scripts/start_http_server.sh --status

# View error log
./scripts/start_http_server.sh --errors

# Clear error log
./scripts/start_http_server.sh --clear-errors
```

## Project Structure

```
scripts/
├── bulk_ingest.py              # Main ingestion tool
├── rag_status.sh               # System status checker
├── start_http_server.sh        # HTTP server control
├── BULK_INJECT_README.md      # Ingestion documentation
├── BULK_INJECT_IMPLEMENTATION.md # Implementation details
├── legacy/                    # Archived scripts
│   ├── baseline_performance.py
│   ├── mcp_bulk_ingest.py
│   ├── quickref.sh
│   ├── deploy.sh
│   ├── manage.sh
│   └── start_rag_api.sh
└── README.md                  # This file
```

## Migration Notes

### Script Rename (January 2026)
The main ingestion script was renamed from `bulk_inject_with_gitignore.py` to `bulk_ingest.py` for better package naming and easier installation.

**Old usage:**
```bash
python scripts/bulk_inject_with_gitignore.py
```

**New usage:**
```bash
python scripts/bulk_ingest.py
```

If you have cron jobs or automation scripts using the old name, please update them.

## Support

For issues or questions about the scripts:

1. Check documentation: `scripts/BULK_INJECT_README.md`
2. Check logs:
   - Error log: `tail -f /var/log/pi-core/error.log`
   - Server log: `tail -f /tmp/mcp_server.log`
3. Review implementation details: `scripts/BULK_INJECT_IMPLEMENTATION.md`
