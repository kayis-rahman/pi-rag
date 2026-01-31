# Tasks: RAG CLI Commands

**Feature ID**: 009-rag-cli-commands
**Phase**: All
**Created**: January 29, 2026
**Updated**: January 29, 2026
**Status**: [In Progress]

---

## Task Breakdown

**ORDERING STRATEGY:**
1. Implement single file ingestion in main.py
2. Create bulk_ingest.py wrapper
3. Implement query command in main.py
4. Test all commands
5. Document OpenCode integration

---

## Phase 1: CLI Commands (12 tasks)

### 1.1 Implement `synapse ingest` in main.py
- [ ] Replace stub in main.py:157-204
- [ ] Add HTTP upload flow (POST /v1/upload)
- [ ] Add direct local path ingestion
- [ ] Add stdin support (`echo "text" | synapse ingest -`)
- [ ] Add `--project-id` flag
- [ ] Add `--json` output option
- [ ] Add error handling

### 1.2 Add `ingest-url` subcommand
- [ ] Add new typer command for URL ingestion
- [ ] Use requests to fetch URL content
- [ ] Ingest fetched content
- [ ] Pass `--project-id` flag

### 1.3 Implement `synapse bulk-ingest` wrapper
- [ ] Create `synapse/cli/commands/bulk_ingest.py`
- [ ] Call `scripts/bulk_ingest.py` via subprocess
- [ ] Pass through all arguments
- [ ] Display help text

### 1.4 Register bulk_ingest in main.py
- [ ] Import bulk_ingest command
- [ ] Add typer subcommand
- [ ] Update help text

### 1.5 Implement `synapse query` in main.py
- [ ] Replace stub in main.py:207-250
- [ ] Add MCP call to `rag.get_context()`
- [ ] Add `--project-id` flag
- [ ] Add `--json` output option
- [ ] Add `--memory-type` flag (all/symbolic/episodic/semantic)
- [ ] Add `--top-k` flag
- [ ] Format output for console

### 1.6 Test `synapse ingest`
- [ ] Test: `synapse ingest README.md`
- [ ] Test: `synapse ingest file.md --project-id test`
- [ ] Test: `echo "text" | synapse ingest -`
- [ ] Test: Error handling (file not found)
- [ ] Verify upload + ingestion flow

### 1.7 Test `synapse ingest-url`
- [ ] Test: `synapse ingest-url https://example.com`
- [ ] Test: `synapse ingest-url https://url --project-id myapp`
- [ ] Test: Error handling (invalid URL)

### 1.8 Test `synapse bulk-ingest`
- [ ] Test: `synapse bulk-ingest . --help`
- [ ] Test: `synapse bulk-ingest . --dry-run`
- [ ] Test: `synapse bulk-ingest . --file-type code`
- [ ] Verify calls scripts/bulk_ingest.py correctly

### 1.9 Test `synapse query`
- [ ] Test: `synapse query "what is SYNAPSE?"`
- [ ] Test: `synapse query "?" --json`
- [ ] Test: `synapse query "?" --memory-type symbolic`
- [ ] Test: `synapse query "?" --top-k 5`
- [ ] Verify results are accurate

### 1.10 Test Error Handling
- [ ] Test: Server down scenario
- [ ] Test: Invalid file
- [ ] Test: Network timeout
- [ ] Verify error messages are clear

### 1.11 Verify All Commands
- [ ] Run: `synapse --help`
- [ ] Verify: `ingest`, `bulk-ingest`, `query` displayed
- [ ] Verify: Each command has help text

### 1.12 Performance Check
- [ ] Measure: `synapse ingest` time (< 1s)
- [ ] Measure: `synapse query` time (< 2s)
- [ ] Verify: Performance targets met

---

## Phase 2: OpenCode Integration Documentation (5 tasks)

### 2.1 Document MCP Tools
- [ ] Document: `rag.ingest_file()` usage
- [ ] Document: `rag.get_context()` usage
- [ ] Document: `rag.search()` usage
- [ ] Document: `rag.add_fact()` usage
- [ ] Document: `rag.add_episode()` usage

### 2.2 Create OpenCode Workflow Guide
- [ ] Document: How to connect OpenCode to MCP
- [ ] Document: Example ingestion workflow
- [ ] Document: Example query workflow
- [ ] Document: Example learning workflow

### 2.3 Create Command Reference
- [ ] Create: `docs/cli-ingest.md`
- [ ] Create: `docs/cli-bulk-ingest.md`
- [ ] Create: `docs/cli-query.md`
- [ ] Add examples for each command
- [ ] Document all flags

### 2.4 Update Central Index
- [ ] Add feature 009 entry to index.md
- [ ] Set status to "[In Progress]"
- [ ] Mark phases as complete

### 2.5 Final Review
- [ ] Review all commands work correctly
- [ ] Review documentation is complete
- [ ] Review error messages are clear

---

## Task Statistics

- **Total Tasks**: 17 tasks
- **Total Phases**: 2
- **Estimated Time**: 3 hours

**Task Breakdown by Phase:**
- Phase 1: CLI Commands (12 tasks)
- Phase 2: OpenCode Documentation (5 tasks)

---

## Commands Implemented

| Command | Location | Status |
|---------|----------|--------|
| `synapse ingest <file>` | main.py:157-204 | ⏳ |
| `synapse ingest-url <url>` | main.py (new) | ⏳ |
| `synapse bulk-ingest <dir>` | commands/bulk_ingest.py | ⏳ |
| `synapse query "<question>"` | main.py:207-250 | ⏳ |

---

## Usage Examples

### Single File Ingestion
```bash
synapse ingest README.md
synapse ingest file.md --project-id myapp
echo "content" | synapse ingest - --project-id test
synapse ingest-url https://example.com/docs
```

### Bulk Ingestion
```bash
synapse bulk-ingest /path/to/project
synapse bulk-ingest . --dry-run
synapse bulk-ingest . --file-type code
synapse bulk-ingest . --exclude "*.log" "*.tmp"
```

### Query
```bash
synapse query "what is the project structure?"
synapse query "logging configuration" --project-id synapse
synapse query "auth flow" --memory-type symbolic --top-k 5
synapse query "?" --json
```

---

## Notes

**TESTING APPROACH:**
- Test each command individually
- Test integration with local MCP server
- Use actual files for testing

**ERROR HANDLING:**
- Clear, actionable error messages
- Exit codes (0=success, 1-6=errors)
- Network timeout handling
- Validation before execution

---

**Last Updated**: January 29, 2026
**Phase 1 Status**: ⏳ In Progress
**Next Task**: 1.1 - Implement `synapse ingest` in main.py
