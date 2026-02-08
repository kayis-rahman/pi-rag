# Bulk Injection Script with .gitignore Support

## Overview

`bulk_ingest.py` is a comprehensive script for bulk injecting project files into the SYNAPSE semantic memory system via local file path ingestion mode. It features intelligent exclusion patterns, incremental ingestion with checksum verification, and retry capabilities.

## Features

- ✅ **.gitignore Pattern Parsing** - Automatically reads and applies `.gitignore` exclusion patterns
- ✅ **Custom Exclusions** - Support for additional exclusion patterns beyond `.gitignore`
- ✅ **Dry-Run Mode** - Preview what would be ingested without actually processing
- ✅ **Incremental Ingestion** - Skip files that haven't changed (checksum-based)
- ✅ **File Type Filtering** - Filter by file type (code, config, doc, web, data, devops)
- ✅ **Comprehensive Extension Support** - Covers all major programming languages and dev-related files
- ✅ **Retry Mechanism** - Failed files are saved and retried on subsequent runs
- ✅ **Progress Tracking** - Visual progress bar with detailed statistics
- ✅ **Project-Based** - Reusable for any project with configurable project ID
- ✅ **Checksum Verification** - Uses MD5 checksums to detect file changes

## Quick Start

### Basic Usage (Current Project)

```bash
# Preview what will be ingested
python scripts/bulk_ingest.py --dry-run

# Actually ingest the files
python scripts/bulk_ingest.py
```

### Different Project

```bash
# Ingest another project
python scripts/bulk_ingest.py \
    --project-id "myproject" \
    --root-dir /path/to/myproject
```

## Usage Examples

### 1. Dry-Run Mode

Preview what would be ingested without actually processing:

```bash
python scripts/bulk_ingest.py --dry-run
```

### 2. Filter by File Type

Ingest only specific file types:

```bash
# Only code and documentation files
python scripts/bulk_ingest.py \
    --file-type code \
    --file-type doc

# Only configuration files
python scripts/bulk_ingest.py --file-type config
```

**Available File Types:**
- `code` - Programming language files (.py, .js, .ts, .java, .cpp, .go, .rs, etc.)
- `config` - Configuration files (.json, .yaml, .toml, .ini, .env, etc.)
- `doc` - Documentation files (.md, .txt, .rst, .pdf, etc.)
- `web` - Web files (.html, .css, .scss, .vue, etc.)
- `data` - Data files (.csv, .sql, .tsv, etc.)
- `devops` - DevOps files (Dockerfile, Makefile, Jenkinsfile, etc.)

### 3. Custom Exclusions Only

Disable `.gitignore` parsing and use only custom patterns:

```bash
python scripts/bulk_ingest.py \
    --no-gitignore \
    --exclude "*.log" \
    --exclude "*.tmp" \
    --exclude "dist/"
```

### 4. Force Full Re-Ingestion

Disable incremental mode and re-ingest all files:

```bash
python scripts/bulk_ingest.py --no-incremental
```

### 5. Specific Directory

Ingest only a specific subdirectory:

```bash
python scripts/bulk_ingest.py \
    --root-dir /path/to/project \
    --file-type code
```

### 6. Verbose Output

Show detailed information about each file:

```bash
python scripts/bulk_ingest.py --verbose
```

### 7. Custom Chunking

Change chunk size and overlap:

```bash
python scripts/bulk_ingest.py \
    --chunk-size 400 \
    --chunk-overlap 60
```

## Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--project-id` | Project ID for metadata | `SYNAPSE` |
| `--root-dir` | Root directory to scan | `.` (current) |
| `--chunk-size` | Chunk size in characters | `500` |
| `--chunk-overlap` | Chunk overlap in characters | `50` |
| `--no-gitignore` | Disable `.gitignore` parsing | `False` |
| `--exclude` | Custom exclusion patterns (repeatable) | `[]` |
| `--file-type` | Filter by file type (repeatable) | `None` |
| `--dry-run` | Dry-run mode - preview only | `False` |
| `--no-incremental` | Disable incremental mode | `False` |
| `--config` | Path to RAG config file | `./configs/rag_config.json` |
| `--verbose` | Verbose output | `False` |

## Supported File Extensions

The script supports a comprehensive set of file extensions:

### Programming Languages
`.py`, `.js`, `.ts`, `.jsx`, `.tsx`, `.java`, `.cpp`, `.c`, `.h`, `.hpp`,
`.cs`, `.go`, `.rs`, `.rb`, `.php`, `.swift`, `.kt`, `.scala`, `.dart`,
`.lua`, `.r`, `.m`, `.mm`, `.pl`, `.pm`, `.sh`, `.bash`, `.zsh`, `.fish`,
`.ps1`, `.bat`, `.cmd`, `.groovy`, `.fs`, `.fsx`, `.ex`, `.exs`, `.erl`,
`.hrl`, `.elm`, `.purs`

### Configuration Files
`.json`, `.yaml`, `.yml`, `.toml`, `.ini`, `.cfg`, `.conf`, `.env`,
`.env.example`, `.properties`, `.xml`, `.config`

### Documentation
`.md`, `.mdx`, `.txt`, `.rst`, `.adoc`, `.tex`, `.pdf`, `.docx`, `.doc`, `.wiki`

### Web Files
`.html`, `.htm`, `.css`, `.scss`, `.sass`, `.less`, `.styl`, `.vue`, `.svelte`

### Data Files
`.csv`, `.tsv`, `.sql`, `.parquet`, `.avro`

### DevOps
`Dockerfile`, `dockerfile`, `.dockerignore`, `Makefile`, `makefile`,
`.gitignore`, `.gitattributes`, `.editorconfig`, `Jenkinsfile`, `.gitlab-ci.yml`,
`.travis.yml`, `azure-pipelines.yml`, `cloudbuild.yaml`

## .gitignore Pattern Support

The script supports standard `.gitignore` patterns:

- `*.log` - wildcard pattern
- `**/node_modules` - matches any subdirectory
- `/dist` - root directory only (anchored)
- `!important.txt` - negation pattern
- `build/` - directory pattern
- `*.pyc` - extension pattern
- `# comment` - comments (ignored)
- Blank lines are ignored

**Example `.gitignore`:**
```
# Dependencies
node_modules/
vendor/
__pycache__/

# Build outputs
dist/
build/
*.egg-info/

# Logs
*.log
logs/

# IDE
.vscode/
.idea/

# Temporary files
*.tmp
*.bak
*~
```

## Incremental Ingestion

The script uses checksum-based incremental ingestion:

1. **First Run**: All files are ingested and checksums are saved
2. **Subsequent Runs**:
   - Files with matching checksums are skipped
   - Files with different checksums are re-ingested
   - New files are ingested

**Checksum Persistence:**
- Checksums are stored per-project in: `{index_path}/checksums.json`
- Format: `{project_id: {file_path: checksum}}`

**Force Re-Ingestion:**
```bash
python scripts/bulk_ingest.py --no-incremental
```

## Retry Mechanism

Failed ingestions are automatically retried on subsequent runs:

1. **Failed files** are saved to: `{index_path}/failed_ingestions.json`
2. **Next run**: Failed files are automatically included in the scan
3. **Successful retry**: File is removed from the failure list

**Failure Record Format:**
```json
{
  "file_path": "/path/to/file.py",
  "error": "Error message",
  "timestamp": "2026-01-03T18:30:00"
}
```

**Clear Failed Files:**
To clear all failed files, delete the retry file:
```bash
rm /opt/SYNAPSE/data/semantic_index/failed_ingestions.json
```

## Output Format

### Normal Run
```
======================================================================
BULK INJECTION STARTED
======================================================================
Project: SYNAPSE
Root: /home/dietpi/SYNAPSE
Incremental mode: Enabled
.gitignore parsing: Enabled

Scanning files...
Found 452 files

Processing: 100%|██████████| 452/452 [01:30<00:00, 5.02file/s]

======================================================================
BULK INJECTION COMPLETE
======================================================================
Total files found: 452
Files processed: 452
  - New documents: 287
  - Updated documents: 32
  - Skipped (unchanged): 22
  - Retried from failures: 5
Total chunks created: 1847
Errors: 0
Time: 1m 30s

✅ ALL FILES INGESTED SUCCESSFULLY!
======================================================================
```

### Dry-Run Output
```
======================================================================
BULK INJECTION - DRY RUN
======================================================================
Project: SYNAPSE
Root: /home/dietpi/SYNAPSE
Incremental mode: Enabled
.gitignore parsing: Enabled

Processing: 100%|██████████| 452/452 [00:01<00:00, 423.51file/s]

======================================================================
BULK INJECTION COMPLETE (DRY RUN)
======================================================================
Total files found: 452
Files processed: 452
  - New documents: 287
  - Updated documents: 32
  - Skipped (unchanged): 22
Total chunks to create: 1847

NO FILES WERE INGESTED (dry-run mode)
To ingest, run without --dry-run flag
======================================================================
```

## Metadata

Each file is ingested with the following metadata:

```json
{
  "source": "/absolute/path/to/file.py",
  "type": "code",
  "filename": "file.py",
  "relative_path": "src/module/file.py",
  "extension": ".py",
  "project_id": "SYNAPSE",
  "ingested_at": "2026-01-03T18:30:00.000Z"
}
```

## Progress Bar and Logging

The script uses **Rich** for beautiful progress tracking and logging with sticky progress bar:

### Rich Features
- **Sticky Progress Bar**: Progress bar stays at bottom while logs scroll above
- **Colored Output**: Rich formatting with colors and emojis
- **Time Remaining**: Shows estimated time to completion
- **Multiple Progress Columns**: Description, percentage, count, time remaining

### Output Example
```
2026-01-03 18:30:00 - INFO     Scanning files...
2026-01-03 18:30:00 - INFO     Found 452 files
2026-01-03 18:30:01 - INFO     Ingested file1.py: 12 chunks
2026-01-03 18:30:02 - INFO     Ingested file2.py: 8 chunks
                                                  ↑ Logs scroll above
Processing files  ████████████████████████ 75% (340/452) [00:01<00:00]
                                                  ↑ Progress bar stays sticky at bottom
```

### Requirements
Rich is already installed in the SYNAPSE environment. If needed:

```bash
pip install rich
```

## Error Handling

- **Continue on Error**: Failed files are logged but processing continues
- **Retry on Next Run**: Failed files are saved and automatically retried
- **Error Summary**: All errors are displayed at the end with details
- **Exit Code**: Returns 0 on success, 1 on errors

## Architecture

### Main Components

1. **BulkInjectConfig** - Configuration management
2. **GitignoreParser** - Parse and match .gitignore patterns
3. **FileScanner** - Discover and filter files
4. **IncrementalIngestor** - Handle checksums and retry logic
5. **BulkInjector** - Main orchestrator

### Data Flow

```
Scan Files → Filter by Extension → Check .gitignore → Calculate Checksum
     ↓
Check Incremental (Skip if unchanged)
     ↓
Generate Metadata → Ingest File → Record Checksum → Update Stats
     ↓
Handle Errors → Save to Retry File → Continue
```

## Advanced Usage

### Multi-Project Setup

Ingest multiple projects with different IDs:

```bash
# Project 1
python scripts/bulk_ingest.py \
    --project-id frontend \
    --root-dir /home/user/frontend-app

# Project 2
python scripts/bulk_ingest.py \
    --project-id backend \
    --root-dir /home/user/backend-api
```

### CI/CD Integration

```bash
#!/bin/bash
# Ingest project files in CI pipeline

# Step 1: Dry-run
python scripts/bulk_ingest.py --dry-run

# Step 2: Ingest (only in production)
if [ "$ENV" = "production" ]; then
    python scripts/bulk_ingest.py
fi
```

### Scheduled Updates

```bash
# Cron job to re-ingest daily (catch changes)
0 2 * * * cd /home/user/SYNAPSE && python scripts/bulk_ingest.py >> /var/log/bulk_ingest.log 2>&1
```

## Troubleshooting

### Issue: Too many files ingested

**Solution**: Use `.gitignore` or custom exclusions:

```bash
python scripts/bulk_ingest.py \
    --exclude "*.test.js" \
    --exclude "coverage/" \
    --exclude ".next/"
```

### Issue: Files not being skipped (incremental)

**Solution**: Check that files have different checksums:

```bash
# Force re-ingest to verify
python scripts/bulk_ingest.py --no-incremental
```

### Issue: Progress bar not showing

**Solution**: Install tqdm:

```bash
pip install tqdm
```

### Issue: Files always re-ingested

**Solution**: Check that checksums are being saved:

```bash
# Check checksum file
cat /opt/SYNAPSE/data/semantic_index/checksums.json
```

## Files Created

The script creates/updates the following files:

- **`/opt/SYNAPSE/data/semantic_index/checksums.json`** - Per-project checksums
- **`/opt/SYNAPSE/data/semantic_index/failed_ingestions.json`** - Retry list
- **`/opt/SYNAPSE/data/semantic_index/chunks.json`** - Ingested chunks (semantic store)
- **`/opt/SYNAPSE/data/semantic_index/metadata/documents.json`** - Document metadata (semantic store)

## Requirements

### Python Dependencies
- `pathlib` (built-in)
- `hashlib` (built-in)
- `json` (built-in)
- `argparse` (built-in)
- `tqdm` (optional, for progress bar)
- SYNAPSE modules: `rag`, `core.semantic_store`, `core.semantic_ingest`

### System Requirements
- Write access to semantic store directory
- Read access to project files

## Best Practices

1. **Always Dry-Run First**: Preview before ingesting
2. **Use File Type Filters**: Ingest only what you need
3. **Keep .gitignore Updated**: Maintain good exclusion patterns
4. **Check Retry List**: Review failed files after each run
5. **Use Verbose Mode**: For debugging specific files
6. **Project-Specific IDs**: Use different project IDs for different codebases

## License

This script is part of the SYNAPSE project.
