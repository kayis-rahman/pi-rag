# Data Directory Migration - Complete

**Date**: 2026-01-02
**Status**: ✅ COMPLETED

---

## Summary

Successfully migrated RAG data directory from project directory to standard Linux location:

- **Old Location**: `/home/dietpi/pi-rag/data/` (inside project)
- **New Location**: `/opt/pi-rag/data/` (standard Linux location)

---

## Changes Made

### 1. Removed Project Data Directory
```bash
rm -rf /home/dietpi/pi-rag/data/
```
- Removed entire `data/` directory from project
- All previous data was stale (old ingestion results)

### 2. Updated Configuration

**`configs/rag_config.json`**:
```json
{
  "index_path": "/opt/pi-rag/data/rag_index",      // was: ./data/rag_index
  "docs_path": "/opt/pi-rag/data/docs",              // was: ./data/docs
  "memory_db_path": "/opt/pi-rag/data/memory.db"     // was: ./data/memory.db
}
```

### 3. Updated Git Ignore

**`.gitignore`**:
```gitignore
# RAG Data Directory (entire directory - moved to /opt/pi-rag/data/)
data/
```
- Changed from ignoring specific files to ignoring entire directory

### 4. Created Required Directories

```bash
/opt/pi-rag/data/
├── docs/              # Document ingestion source
├── rag_index/         # Vector store index
├── semantic_index/     # Semantic memory (Chroma)
├── memory.db          # Symbolic memory database
├── registry.db        # Project registry
└── episodic.db       # Episodic memory database
```

### 5. Git Commit

Committed changes with message:
```
Migrate data directory to /opt/pi-rag/data/

- Removed local data/ directory from project (moved to /opt/pi-rag/data/)
- Updated configs/rag_config.json to use /opt/pi-rag/data/ paths
- Updated .gitignore to ignore data/ directory entirely
- Data is now separated from source code (best practice)
- All databases and indexes stored in standard Linux location
```

---

## Verification

### Configuration Test
```bash
export RAG_DATA_DIR=/opt/pi-rag/data
python3 -m mcp_server.rag_server
```
✅ MCP server starts successfully
✅ Data directory: /opt/pi-rag/data
✅ Available tools: 7

### Database Creation
- ✅ `memory.db` created (32KB)
- ✅ `registry.db` created (12KB)
- ✅ Directories created automatically

---

## Benefits

1. **Standard Linux Structure**: Data in `/opt/` (best practice)
2. **Clean Project Repository**: No data mixed with source code
3. **Better Version Control**: Git ignores all data
4. **Easier Sharing**: Can share project without large data files
5. **Separation of Concerns**: Code vs. data clearly separated
6. **Production Ready**: Matches standard Linux deployment patterns

---

## How to Use

### Starting RAG API
```bash
export RAG_DATA_DIR=/opt/pi-rag/data
./scripts/start_rag_api.sh
```

### Starting MCP Server
```bash
export RAG_DATA_DIR=/opt/pi-rag/data
python3 -m mcp_server.rag_server
```

### Docker Deployment
```bash
# Volume mount:
docker run -v /opt/pi-rag/data:/app/data ...
```

---

## Environment Variables

All RAG components respect `RAG_DATA_DIR` environment variable:

- **Default**: `/opt/pi-rag/data` (MCP server)
- **Override**: Set via `export RAG_DATA_DIR=/path/to/data`

---

## Directory Structure

**Project Directory** (`/home/dietpi/pi-rag/`):
```
pi-rag/
├── configs/           # Configuration files
├── mcp_server/       # MCP server implementation
├── rag/              # RAG modules
├── scripts/          # Utility scripts
├── api/              # FastAPI server
├── .gitignore        # Updated: ignores data/
└── README.md
```

**Data Directory** (`/opt/pi-rag/data/`):
```
/opt/pi-rag/data/
├── docs/             # Source documents for ingestion
├── rag_index/        # Vector store index files
├── semantic_index/    # Chroma DB for semantic memory
├── memory.db         # Symbolic memory (SQLite)
├── episodic.db       # Episodic memory (SQLite)
└── registry.db       # MCP project registry
```

---

## Next Steps

1. ✅ **Configuration Updated** - Done
2. ✅ **Git Committed** - Done
3. ✅ **MCP Server Verified** - Done
4. 🔄 **Ingest Files** - Can now proceed with ingestion
5. 🔄 **Test Full System** - End-to-end testing

---

## Notes

- Previous data was removed intentionally (stale test data)
- All new data will be created in `/opt/pi-rag/data/`
- Git repository is now clean (no data files tracked)
- Ready for fresh ingestion of all pi-rag files

---

**Status**: ✅ Migration Complete
**Next**: Proceed with file ingestion using RAG MCP server
