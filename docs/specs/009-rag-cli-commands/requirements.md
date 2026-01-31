# Requirements: RAG CLI Commands

**Feature ID**: 009-rag-cli-commands
**Created**: January 29, 2026
**Updated**: January 29, 2026
**Status**: [In Progress]

---

## Overview

Implement CLI commands for local RAG ingestion and query operations. RAG server running on localhost:8002.

---

## User Stories

1. **As a user**, I want to ingest single files so I can query them
2. **As a user**, I want a `synapse bulk-ingest` CLI command so I don't need to run scripts
3. **As a user**, I want to query RAG memory so I can get answers
4. **As an OpenCode user**, I want documented MCP tools so I can integrate with RAG

---

## Functional Requirements

### FR-1: Single File Ingestion

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-1.1 | Command: `synapse ingest <file>` | P0 | ⏳ |
| FR-1.2 | Method A: Direct local path ingestion | P0 | ⏳ |
| FR-1.3 | Method B: HTTP upload + MCP | P1 | ⏳ |
| FR-1.4 | Stdin support: `echo "text" | synapse ingest -` | P1 | ⏳ |
| FR-1.5 | URL support: `synapse ingest <url>` | P2 | ⏳ |
| FR-1.6 | Flag: `--project-id <id>` | P0 | ⏳ |
| FR-1.7 | Error handling | P0 | ⏳ |

### FR-2: Bulk Ingestion CLI

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-2.1 | Command: `synapse bulk-ingest <dir>` | P0 | ⏳ |
| FR-2.2 | Wrapper: Call `scripts/bulk_ingest.py` | P0 | ⏳ |
| FR-2.3 | Pass through all options | P1 | ⏳ |
| FR-2.4 | Help text | P1 | ⏳ |

### FR-3: Query Command

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-3.1 | Command: `synapse query "<question>"` | P0 | ⏳ |
| FR-3.2 | MCP tool: `rag.get_context()` | P0 | ⏳ |
| FR-3.3 | Flag: `--json` output | P1 | ⏳ |
| FR-3.4 | Flag: `--memory-type <type>` | P2 | ⏳ |
| FR-3.5 | Flag: `--top-k <n>` | P2 | ⏳ |

---

## Non-Functional Requirements

| ID | Requirement | Target | Status |
|----|-------------|--------|--------|
| NFR-1 | Ingestion speed | < 1s per file | ⏳ |
| NFR-2 | Query response time | < 2s | ⏳ |
| NFR-3 | Error messages | Actionable | ⏳ |
| NFR-4 | CLI help | Complete | ⏳ |

---

## Existing Features (Reuse)

| Feature | Location | Usage |
|---------|----------|-------|
| Bulk ingest script | `scripts/bulk_ingest.py` | Call via subprocess |
| MCP server | localhost:8002 | rag.ingest_file, rag.get_context |
| OpenCode MCP tools | 7 tools available | Document usage |

---

## Acceptance Criteria

### AC-1: Single File Ingestion
- [ ] `synapse ingest file.md` works
- [ ] `--project-id` flag works
- [ ] Stdin support works
- [ ] Error messages are clear

### AC-2: Bulk Ingestion CLI
- [ ] `synapse bulk-ingest /path` works
- [ ] Calls scripts/bulk_ingest.py correctly
- [ ] Help text displays

### AC-3: Query Command
- [ ] `synapse query "?"` returns context
- [ ] `--json` output works
- [ ] Results are accurate

### AC-4: OpenCode Documentation
- [ ] MCP tools documented
- [ ] Usage examples provided
- [ ] Workflow diagram included

---

## Out of Scope

- GUI interface
- New bulk ingest logic (reuse existing)
- Performance optimization beyond baseline
- Multi-user authentication

---

**Requirements Status**: ⏳ In Progress (0/14 requirements complete)
