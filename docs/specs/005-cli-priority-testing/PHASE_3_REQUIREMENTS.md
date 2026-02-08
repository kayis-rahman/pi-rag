# Phase 3 Requirements: Data Operations

**Feature ID**: 005-cli-priority-testing
**Phase**: 3 - Data Operations
**Priority**: P2 (Data Operations)
**Status**: Planning
**Created**: February 7, 2026

---

## Overview

This phase validates data operations commands: `synapse ingest`, `synapse query`, and bulk ingestion functionality. These commands are critical for the core RAG functionality.

---

## User Stories

### US-1: Document Ingestion
**As a** user,
**I want** to run `synapse ingest <path>` to add documents to the knowledge base,
**So that** I can build my RAG knowledge base from existing documents.

**Acceptance Criteria:**
- Ingest accepts file path or directory path
- Ingest processes text files (.txt, .md, .py, .json, etc.)
- Ingest creates semantic memory chunks
- Ingest reports number of files processed and chunks created
- Ingest works in all three modes: Docker, native, user home

### US-2: Knowledge Query
**As a** user,
**I want** to run `synapse query "<question>"` to search my knowledge base,
**So that** I can find relevant information from my ingested documents.

**Acceptance Criteria:**
- Query accepts natural language question
- Query searches semantic, episodic, and symbolic memory
- Query returns relevant results with citations
- Query supports `--top-k` parameter for result count
- Query supports JSON and text output formats

### US-3: Bulk Ingestion
**As a** system administrator,
**I want** to run bulk ingestion to process large document collections,
**So that** I can efficiently index hundreds or thousands of files at once.

**Acceptance Criteria:**
- Bulk ingest processes all files in a directory recursively
- Bulk ingest respects .gitignore patterns
- Bulk ingest shows progress during processing
- Bulk ingest reports statistics (files, chunks, errors)
- Bulk ingest supports chunk size configuration

---

## Functional Requirements

### FR-1: Ingest Command (P2-1)
The `synapse ingest <path>` command must:

**FR-1.1 Path Processing**
- Accept file path or directory path
- Process directories recursively
- Validate path exists before processing
- Handle relative and absolute paths

**FR-1.2 File Type Support**
- Process text files: .txt, .md, .py, .js, .html, .json, .yaml, .yml, .xml, .csv
- Skip binary files: .pdf, .docx, .png, .jpg, .zip (no errors)
- Skip hidden files and directories (starting with .)
- Handle file encoding (UTF-8, UTF-8-sig, latin-1, cp1252)

**FR-1.3 Chunking**
- Split documents into chunks of configured size (default: 500 chars)
- Add overlap between chunks (default: 50 chars)
- Respect paragraph boundaries when possible
- Create metadata for each chunk (file path, chunk index, etc.)

**FR-1.4 Progress and Feedback**
- Display progress during ingestion
- Show files processed count
- Show chunks created count
- Show errors (if any) without stopping

### FR-2: Query Command (P2-2)
The `synapse query "<text>"` command must:

**FR-2.1 Query Processing**
- Accept query text as argument
- Support quoted strings for multi-word queries
- Generate query embeddings using BGE-M3 model
- Search semantic memory for similar chunks

**FR-2.2 Multi-Memory Search**
- Search semantic memory (document chunks)
- Search episodic memory (past experiences)
- Search symbolic memory (facts and configurations)
- Combine results from all memory types

**FR-2.3 Result Formatting**
- Support `--format json` for structured output
- Support `--format text` for human-readable output
- Include citations (source file, chunk ID)
- Include similarity scores
- Include relevant metadata

**FR-2.4 Result Control**
- Support `--top-k N` parameter (default: 3)
- Support `--mode default|verbose` for detail level
- Return within 5 seconds for typical queries

### FR-3: Bulk Ingest Command (P2-3)
The `synapse bulk-ingest <directory>` command must:

**FR-3.1 Recursive Processing**
- Process all files in directory tree
- Apply .gitignore patterns to skip unwanted files
- Skip build artifacts (node_modules, __pycache__, .venv, etc.)
- Skip version control directories (.git, .svn)

**FR-3.2 Batch Processing**
- Process files in batches (default: 100 files per batch)
- Show progress indicator (percentage or file count)
- Handle partial failures gracefully
- Continue processing after individual file errors

**FR-3.3 Statistics**
- Report total files processed
- Report total chunks created
- Report total embedding operations
- Report errors (count and examples)

---

## Non-Functional Requirements

### NFR-1: Performance
- Ingest: 10 files/second minimum
- Query: < 5 seconds for typical query
- Chunking: < 100ms per file
- Embedding: < 500ms per chunk

### NFR-2: Error Handling
- Invalid path: Clear error message with suggestions
- Permission denied: Clear error message
- Encoding errors: Skip file with warning
- MCP unavailable: Clear error with server start suggestion

### NFR-3: User Experience
- Progress indicators for long operations
- Clear summary statistics
- Color-coded output (success/warning/error)
- Support Ctrl+C for graceful cancellation

### NFR-4: Reliability
- Idempotent: Re-ingesting same files doesn't duplicate
- Atomic: Failed files don't corrupt index
- Persistent: Ingested data survives server restart

---

## Test Environments

### TE-1: Docker Mode
- Target: Docker container running synapse
- Data directory: `/app/data`
- MCP endpoint: `http://localhost:8002/mcp`

### TE-2: Native Mode
- Target: Native Linux installation
- Data directory: `/opt/synapse/data`
- MCP endpoint: `http://localhost:8002/mcp`

### TE-3: User Home Mode
- Target: User's home directory
- Data directory: `~/.synapse/data`
- MCP endpoint: `http://localhost:8002/mcp`

---

## Exit Criteria

Phase 3 is complete when ALL of the following are met:

1. **Ingest Command (P2-1)**
   - [ ] Ingests single file successfully
   - [ ] Ingests directory recursively
   - [ ] Skips binary files without error
   - [ ] Shows progress and statistics
   - [ ] Works in all 3 modes

2. **Query Command (P2-2)**
   - [ ] Returns results from semantic memory
   - [ ] Returns results from episodic memory
   - [ ] Returns results from symbolic memory
   - [ ] Supports --top-k parameter
   - [ ] Supports JSON and text formats
   - [ ] Works in all 3 modes

3. **Bulk Ingest (P2-3)**
   - [ ] Processes 10+ files in directory
   - [ ] Respects .gitignore patterns
   - [ ] Shows progress indicator
   - [ ] Reports statistics
   - [ ] Works in all 3 modes

4. **Error Handling**
   - [ ] Invalid path produces clear error
   - [ ] Permission errors handled gracefully
   - [ ] Encoding errors skip file with warning
   - [ ] MCP unavailable gives helpful message

5. **Test Artifacts**
   - [ ] Test scripts created for P2-1, P2-2, P2-3
   - [ ] Test results documented
   - [ ] All tests passing
   - [ ] Central index updated

---

## Dependencies

- MCP server must be running for ingest/query to work
- BGE-M3 model must be installed
- Semantic memory must be initialized
- Test files available in `docs/specs/` directory

---

## Success Metrics

- **Ingest Success Rate**: 100% (all file types handled)
- **Query Success Rate**: 100% (returns results for valid queries)
- **Bulk Ingest Success Rate**: 100% (all files processed)
- **Performance Compliance**: 100% (all operations within time limits)
- **Error Handling**: 100% (all errors produce clear messages)

---

## Related Documentation

- `scripts/bulk_ingest.py` - Bulk ingestion script
- `synapse/cli/commands/ingest.py` - Ingest command
- `synapse/cli/commands/query.py` - Query command
- `core/semantic_store.py` - Semantic memory storage
- `AGENTS.md` - SDD Protocol

---

**Created**: February 7, 2026
**Status**: Ready for Planning Review
