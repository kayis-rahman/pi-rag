# Fresh Installation Validation - Task Breakdown

**Feature ID**: 010-fresh-install-validation  
**Status**: [In Progress]  
**Created**: January 31, 2026  
**Last Updated**: January 31, 2026

---

## Overview

This task list provides a granular checklist for validating Synapse on a fresh Mac installation. All tasks are read-only validation - no source files will be modified.

**STRICT CONSTRAINT - NO EXCEPTIONS:**
========================================
✓ USE ONLY: curl, HTTP requests, built-in shell commands
✓ USE ONLY: Existing tools (no new scripts or files)
✓ NO CREATION of test files, helper scripts, or code
✓ NO MODIFICATION of source files  
✓ LOG GAPS only - do NOT fix them
✓ Document failures with: command, expected, actual, error message

**Constraints:**
- No file modifications (read-only validation)
- All test artifacts in temporary directories
- Log all bugs, failures, issues
- Test MCP tools via HTTP API only (curl)

**Total Tasks:** 72 tasks across 8 phases  
**Estimated Time:** ~2.5 hours

---

## Task Statistics

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1: Environment Check | 5 | 10 min |
| Phase 2: P0 CLI Commands | 10 | 20 min |
| Phase 3: P1 CLI Commands | 10 | 20 min |
| Phase 4: P2/P3 CLI Commands | 8 | 15 min |
| Phase 5: MCP Tool Validation | 12 | 25 min |
| Phase 6: Full Project Ingestion | 10 | 30 min |
| Phase 7: Knowledge Verification | 9 | 15 min |
| Phase 8: Documentation | 8 | 15 min |
| **Total** | **72 tasks** | **~2.5 hours** |

---

## Phase 1: Environment Check (5 tasks)

**Constraint:** NO code creation/modification. Use curl, shell commands only.
- [ ] 1.1.1 Run `python3 --version` (Linked to FR-1)
- [ ] 1.1.2 Verify output shows Python 3.8+ (Linked to FR-1)
- [ ] 1.1.3 Log Python version in validation report (Linked to FR-1)

### 1.2: Verify Synapse CLI
- [ ] 1.2.1 Run `python3 -m synapse.cli.main --help` (Linked to FR-1)
- [ ] 1.2.2 Verify help output displays (Linked to FR-1)
- [ ] 1.2.3 Log available commands list (Linked to FR-1)

### 1.3: Verify MCP Server
- [ ] 1.3.1 Run `curl -s http://localhost:8002/health` (Linked to FR-4)
- [ ] 1.3.2 Verify health endpoint responds (Linked to FR-4)
- [ ] 1.3.3 If failed, run `python3 -m synapse.cli.main start` (Linked to FR-4)
- [ ] 1.3.4 Wait 5 seconds and re-check health (Linked to FR-4)

### 1.4: Verify BGE-M3 Model
- [ ] 1.4.1 Run `python3 -m synapse.cli.main models list` (Linked to FR-3)
- [ ] 1.4.2 Verify BGE-M3 shows as installed (Linked to FR-3)
- [ ] 1.4.3 Log model file size and path (Linked to FR-3)

### 1.5: Verify Data Directory
- [ ] 1.5.1 Run `ls -la ~/.synapse/data/` (Linked to FR-1)
- [ ] 1.5.2 Verify directories exist: data, models, rag_index, docs, logs (Linked to FR-1)
- [ ] 1.5.3 Log directory structure (Linked to FR-1)

**Phase 1 Exit Criteria:** All 5 tasks complete, environment ready for validation

---

## Phase 2: P0 CLI Commands (10 tasks)

**Constraint:** NO code creation/modification. Use CLI commands only, document gaps.
- [ ] 2.1.1.1 Navigate to home directory: `cd ~` (Linked to US-1)
- [ ] 2.1.1.2 Run `python3 -m synapse.cli.main setup --no-model-check` (Linked to US-1)
- [ ] 2.1.1.3 Verify exit code: 0 (Linked to US-1)
- [ ] 2.1.1.4 Verify output contains "SYNAPSE setup complete!" (Linked to US-1)
- [ ] 2.1.1.5 Verify ~/.synapse/data/ directories created (Linked to US-1)
- [ ] 2.1.1.6 Verify config file created: ~/.synapse/configs/rag_config.json (Linked to US-1)
- [ ] 2.1.1.7 Log completion time (< 30s) (Linked to US-1)
- [ ] 2.1.1.8 Mark result: PASS/FAIL (Linked to US-1)

#### 2.1.2: Force Re-Setup
- [ ] 2.1.2.1 Run `python3 -m synapse.cli.main setup --force --no-model-check` (Linked to US-1)
- [ ] 2.1.2.2 Verify exit code: 0 (Linked to US-1)
- [ ] 2.1.2.3 Verify no errors about duplicate directories (Linked to US-1)
- [ ] 2.1.2.4 Mark result: PASS/FAIL (Linked to US-1)

### 2.2: Config Command Tests

#### 2.2.1: Basic Config Display
- [ ] 2.2.1.1 Run `python3 -m synapse.cli.main config` (Linked to US-2)
- [ ] 2.2.1.2 Verify exit code: 0 (Linked to US-2)
- [ ] 2.2.1.3 Verify output contains "Data directory:" (Linked to US-2)
- [ ] 2.2.1.4 Verify output contains "Models directory:" (Linked to US-2)
- [ ] 2.2.1.5 Verify output shows correct paths (~/.synapse/) (Linked to US-2)
- [ ] 2.2.1.6 Log completion time (< 2s) (Linked to US-2)
- [ ] 2.2.1.7 Mark result: PASS/FAIL (Linked to US-2)

#### 2.2.2: Verbose Config
- [ ] 2.2.2.1 Run `python3 -m synapse.cli.main config --verbose` (Linked to US-2)
- [ ] 2.2.2.2 Verify exit code: 0 (Linked to US-2)
- [ ] 2.2.2.3 Verify output contains "chunk_size" (Linked to US-2)
- [ ] 2.2.2.4 Verify output contains "top_k" (Linked to US-2)
- [ ] 2.2.2.5 Mark result: PASS/FAIL (Linked to US-2)

### 2.3: Models Command Tests

#### 2.3.1: List Models
- [ ] 2.3.1.1 Run `python3 -m synapse.cli.main models list` (Linked to US-3)
- [ ] 2.3.1.2 Verify exit code: 0 (Linked to US-3)
- [ ] 2.3.1.3 Verify output contains "BGE-M3" or "bge-m3" (Linked to US-3)
- [ ] 2.3.1.4 Verify output shows model file size (Linked to US-3)
- [ ] 2.3.1.5 Verify output shows model status (installed) (Linked to US-3)
- [ ] 2.3.1.6 Log completion time (< 2s) (Linked to US-3)
- [ ] 2.3.1.7 Mark result: PASS/FAIL (Linked to US-3)

#### 2.3.2: Verify Models
- [ ] 2.3.2.1 Run `python3 -m synapse.cli.main models verify` (Linked to US-3)
- [ ] 2.3.2.2 Verify exit code: 0 (Linked to US-3)
- [ ] 2.3.2.3 Verify output shows "verified" or "valid" (Linked to US-3)
- [ ] 2.3.2.4 Mark result: PASS/FAIL (Linked to US-3)

### 2.4: Server Command Tests

#### 2.4.1: Start Server
- [ ] 2.4.1.1 Run `python3 -m synapse.cli.main start &` (Linked to US-4)
- [ ] 2.4.1.2 Wait 5 seconds for startup (Linked to US-4)
- [ ] 2.4.1.3 Run `curl -s http://localhost:8002/health` (Linked to US-4)
- [ ] 2.4.1.4 Verify health endpoint returns success (Linked to US-4)
- [ ] 2.4.1.5 Record process ID for cleanup (Linked to US-4)
- [ ] 2.4.1.6 Mark result: PASS/FAIL (Linked to US-4)

#### 2.4.2: Check Status
- [ ] 2.4.2.1 Run `python3 -m synapse.cli.main status` (Linked to US-4)
- [ ] 2.4.2.2 Verify exit code: 0 (Linked to US-4)
- [ ] 2.4.2.3 Verify output shows "running" or "started" (Linked to US-4)
- [ ] 2.4.2.4 Verify output shows port 8002 (Linked to US-4)
- [ ] 2.4.2.5 Mark result: PASS/FAIL (Linked to US-4)

#### 2.4.3: Stop Server
- [ ] 2.4.3.1 Run `python3 -m synapse.cli.main stop` (Linked to US-4)
- [ ] 2.4.3.2 Verify exit code: 0 (Linked to US-4)
- [ ] 2.4.3.3 Verify output shows "stopped" (Linked to US-4)
- [ ] 2.4.3.4 Verify process terminated (no zombie) (Linked to US-4)
- [ ] 2.4.3.5 Run `curl -s http://localhost:8002/health` (should fail) (Linked to US-4)
- [ ] 2.4.3.6 Mark result: PASS/FAIL (Linked to US-4)

**Phase 2 Exit Criteria:** All 10 tasks complete, 7/7 P0 commands pass

---

## Phase 3: P1 CLI Commands (10 tasks)

**Constraint:** NO code creation/modification. Use CLI commands only, document gaps.
- [ ] 3.1.1.1 Run `python3 -m synapse.cli.main ingest README.md` (Linked to US-5)
- [ ] 3.1.1.2 Verify exit code: 0 (Linked to US-5)
- [ ] 3.1.1.3 Verify output contains "ingested" or "success" (Linked to US-5)
- [ ] 3.1.1.4 Verify chunk count displayed (Linked to US-5)
- [ ] 3.1.1.5 Mark result: PASS/FAIL (Linked to US-5)

#### 3.1.2: Ingest Directory
- [ ] 3.1.2.1 Run `python3 -m synapse.cli.main ingest configs/` (Linked to US-5)
- [ ] 3.1.2.2 Verify exit code: 0 (Linked to US-5)
- [ ] 3.1.2.3 Verify multiple files processed (Linked to US-5)
- [ ] 3.1.2.4 Verify total chunk count displayed (Linked to US-5)
- [ ] 3.1.2.5 Mark result: PASS/FAIL (Linked to US-5)

### 3.2: Query Command Tests

#### 3.2.1: Simple Query
- [ ] 3.2.1.1 Run `python3 -m synapse.cli.main query "What is Synapse?"` (Linked to US-6)
- [ ] 3.2.1.2 Verify exit code: 0 (Linked to US-6)
- [ ] 3.2.1.3 Verify output contains relevant information (Linked to US-6)
- [ ] 3.2.1.4 Verify response time < 5 seconds (Linked to US-6)
- [ ] 3.2.1.5 Verify results contain "RAG" or "memory" (Linked to US-6)
- [ ] 3.2.1.6 Mark result: PASS/FAIL (Linked to US-6)

#### 3.2.2: Query with Top-K
- [ ] 3.2.2.1 Run `python3 -m synapse.cli.main query "RAG system" -k 3` (Linked to US-6)
- [ ] 3.2.2.2 Verify exit code: 0 (Linked to US-6)
- [ ] 3.2.2.3 Verify output shows 3 results (Linked to US-6)
- [ ] 3.2.2.4 Verify results are relevant (Linked to US-6)
- [ ] 3.2.2.5 Mark result: PASS/FAIL (Linked to US-6)

#### 3.2.3: Query JSON Format
- [ ] 3.2.3.1 Run `python3 -m synapse.cli.main query "CLI commands" --json` (Linked to US-6)
- [ ] 3.2.3.2 Verify exit code: 0 (Linked to US-6)
- [ ] 3.2.3.3 Pipe output through `python3 -m json.tool` (Linked to US-6)
- [ ] 3.2.3.4 Verify valid JSON (no parse errors) (Linked to US-6)
- [ ] 3.2.3.5 Verify JSON contains results array (Linked to US-6)
- [ ] 3.2.3.6 Mark result: PASS/FAIL (Linked to US-6)

### 3.3: Onboard Command Tests

#### 3.3.1: Quick Onboarding
- [ ] 3.3.1.1 Run `python3 -m synapse.cli.main onboard --quick --skip-ingest` (Linked to US-7)
- [ ] 3.3.1.2 Verify exit code: 0 (Linked to US-7)
- [ ] 3.3.1.3 Verify output shows "Onboarding Complete" (Linked to US-7)
- [ ] 3.3.1.4 Verify summary displayed (Linked to US-7)
- [ ] 3.3.1.5 Mark result: PASS/FAIL (Linked to US-7)

#### 3.3.2: Skip Test Onboarding
- [ ] 3.3.2.1 Run `python3 -m synapse.cli.main onboard --skip-test --skip-ingest` (Linked to US-7)
- [ ] 3.3.2.2 Verify exit code: 0 (Linked to US-7)
- [ ] 3.3.2.3 Verify output shows "Onboarding Complete" (Linked to US-7)
- [ ] 3.3.2.4 Verify test skipped as expected (Linked to US-7)
- [ ] 3.3.2.5 Mark result: PASS/FAIL (Linked to US-7)

**Phase 3 Exit Criteria:** All 10 tasks complete, 6/6 P1 commands pass

---

## Phase 4: P2/P3 CLI Commands (8 tasks)

**Constraint:** NO code creation/modification. Use CLI commands only, document gaps.
- [ ] 4.1.1.1 Run `python3 -m synapse.cli.main setup --offline --no-model-check` (Linked to FR-1)
- [ ] 4.1.1.2 Verify exit code: 0 (Linked to FR-1)
- [ ] 4.1.1.3 Verify output mentions "offline" (Linked to FR-1)
- [ ] 4.1.1.4 Verify no network errors (Linked to FR-1)
- [ ] 4.1.1.5 Mark result: PASS/FAIL (Linked to FR-1)

### 4.2: Additional Config Options

### 4.2.1: JSON Config Output
- [ ] 4.2.1.1 Run `python3 -m synapse.cli.main config --json` (Linked to FR-2)
- [ ] 4.2.1.2 Verify exit code: 0 (Linked to FR-2)
- [ ] 4.2.1.3 Save to `docs/specs/010-fresh-install-validation/CONFIG_OUTPUT.json` (Linked to FR-2)
- [ ] 4.2.1.4 Validate JSON: `python3 -c "import json; json.load(open('docs/specs/010-fresh-install-validation/CONFIG_OUTPUT.json'))"` (Linked to FR-2)
- [ ] 4.2.1.5 Verify JSON contains required fields (Linked to FR-2)
- [ ] 4.2.1.6 Mark result: PASS/FAIL (Linked to FR-2)

### 4.3: Additional Onboard Options

#### 4.3.1: Silent Onboarding
- [ ] 4.3.1.1 Run `python3 -m synapse.cli.main onboard --silent -p test_project --skip-ingest` (Linked to US-7)
- [ ] 4.3.1.2 Verify exit code: 0 (Linked to US-7)
- [ ] 4.3.1.3 Verify no prompts (silent mode) (Linked to US-7)
- [ ] 4.3.1.4 Verify summary displayed (Linked to US-7)
- [ ] 4.3.1.5 Mark result: PASS/FAIL (Linked to US-7)

### 4.4: Edge Cases

#### 4.4.1: Query No Results
- [ ] 4.4.1.1 Run `python3 -m synapse.cli.main query "xyznonexistentquery123"` (Linked to US-6)
- [ ] 4.4.1.2 Verify exit code: 0 (Linked to US-6)
- [ ] 4.4.1.3 Verify graceful handling of no results (Linked to US-6)
- [ ] 4.4.1.4 Mark result: PASS/FAIL (Linked to US-6)

#### 4.4.2: Ingest Non-Existent File
- [ ] 4.4.2.1 Run `python3 -m synapse.cli.main ingest nonexistent_file.md` (Linked to US-5)
- [ ] 4.4.2.2 Verify exit code: 1 (error) (Linked to US-5)
- [ ] 4.4.2.3 Verify clear error message (Linked to US-5)
- [ ] 4.4.2.4 Mark result: PASS/FAIL (Linked to US-5)

**Phase 4 Exit Criteria:** All 8 tasks complete, edge cases handled correctly

---

## Phase 5: MCP Tool Validation (12 tasks)

**Constraint:** NO code creation/modification. Use curl/HTTP only, document gaps.

### 5.1: Test list_projects Tool (curl)
- [ ] 5.1.1 Call MCP list_projects using curl (Linked to US-8)
  ```bash
  curl -X POST http://localhost:8002/mcp \
    -H "Accept: application/json, text/event-stream" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_projects","arguments":{}}}' \
    2>&1 | head -50
  ```
- [ ] 5.1.2 Verify HTTP status: 200 (Linked to US-8)
- [ ] 5.1.3 Verify response contains "projects" array (Linked to US-8)
- [ ] 5.1.4 Verify "synapse" project appears (Linked to US-8)
- [ ] 5.1.5 Log response (Linked to US-8)
- [ ] 5.1.6 Mark result: PASS/FAIL (Linked to US-8)

### 5.2: Test list_sources Tool (curl)
- [ ] 5.2.1 Call MCP list_sources with project_id="synapse" using curl (Linked to US-9)
  ```bash
  curl -X POST http://localhost:8002/mcp \
    -H "Accept: application/json, text/event-stream" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_sources","arguments":{"project_id":"synapse"}}}' \
    2>&1 | head -50
  ```
- [ ] 5.2.2 Verify HTTP status: 200 (Linked to US-9)
- [ ] 5.2.3 Verify response contains "sources" array (Linked to US-9)
- [ ] 5.2.4 Log response (Linked to US-9)
- [ ] 5.2.5 Mark result: PASS/FAIL (Linked to US-9)

### 5.3: Test get_context Tool (curl)
- [ ] 5.3.1 Call MCP get_context using curl (Linked to US-10)
  ```bash
  curl -X POST http://localhost:8002/mcp \
    -H "Accept: application/json, text/event-stream" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_context","arguments":{"project_id":"synapse","context_type":"all","query":"CLI"}}}'
  ```
- [ ] 5.3.2 Verify HTTP status: 200 (Linked to US-10)
- [ ] 5.3.3 Verify response structure (Linked to US-10)
- [ ] 5.3.4 Mark result: PASS/FAIL (Linked to US-10)

### 5.4: Test search Tool (curl)
- [ ] 5.4.1 Call MCP search using curl (Linked to US-11)
  ```bash
  curl -X POST http://localhost:8002/mcp \
    -H "Accept: application/json, text/event-stream" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search","arguments":{"project_id":"synapse","query":"RAG system","memory_type":"semantic","top_k":3}}}'
  ```
- [ ] 5.4.2 Verify HTTP status: 200 (Linked to US-11)
- [ ] 5.4.3 Verify response contains results (Linked to US-11)
- [ ] 5.4.4 Mark result: PASS/FAIL (Linked to US-11)

### 5.5: Test upload endpoint (curl)
- [ ] 5.5.1 Upload test file using curl (Linked to US-12)
  ```bash
  curl -X POST http://localhost:8002/v1/upload \
    -F "file=@/Users/kayisrahman/Documents/workspace/ideas/synapse/README.md" 2>&1
  ```
- [ ] 5.5.2 Verify HTTP status: 200 (Linked to US-12)
- [ ] 5.5.3 Extract file_path from response (Linked to US-12)
- [ ] 5.5.4 Mark result: PASS/FAIL (Linked to US-12)

### 5.6: Test add_fact Tool (curl)
- [ ] 5.6.1 Call MCP add_fact using curl (Linked to US-13)
  ```bash
  curl -X POST http://localhost:8002/mcp \
    -H "Accept: application/json, text/event-stream" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"add_fact","arguments":{"project_id":"synapse","fact_key":"test_fact","fact_value":"test value","category":"test","confidence":1.0}}}'
  ```
- [ ] 5.6.2 Verify HTTP status: 200 (Linked to US-13)
- [ ] 5.6.3 Mark result: PASS/FAIL (Linked to US-13)

### 5.7: Test add_episode Tool (curl)
- [ ] 5.7.1 Call MCP add_episode using curl (Linked to US-14)
  ```bash
  curl -X POST http://localhost:8002/mcp \
    -H "Accept: application/json, text/event-stream" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"add_episode","arguments":{"project_id":"synapse","title":"Test Episode","content":"Testing add_episode tool","lesson_type":"success","quality":1.0}}}'
  ```
- [ ] 5.7.2 Verify HTTP status: 200 (Linked to US-14)
- [ ] 5.7.3 Mark result: PASS/FAIL (Linked to US-14)

### 5.8: Test analyze_conversation Tool (curl)
- [ ] 5.8.1 Call MCP analyze_conversation using curl (Linked to US-15)
  ```bash
  curl -X POST http://localhost:8002/mcp \
    -H "Accept: application/json, text/event-stream" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"analyze_conversation","arguments":{"project_id":"synapse","user_message":"How do I validate?","agent_response":"Run validation script","auto_store":true}}}'
  ```
- [ ] 5.8.2 Verify HTTP status: 200 (Linked to US-15)
- [ ] 5.8.3 Mark result: PASS/FAIL (Linked to US-15)

**Phase 5 Exit Criteria:** All 12 tasks complete, 8/8 MCP tools tested with curl

---

## Phase 6: Full Project Ingestion (10 tasks)

**Constraint:** NO code creation/modification. Use existing bulk_ingest script only, document gaps.

### 6.1: File Discovery (real project directories only)
- [ ] 6.1.1 Count Python files: `find synapse/ -name "*.py" -type f | wc -l` (Linked to FR-16)
- [ ] 6.1.2 Count markdown files: `find . -maxdepth 3 -name "*.md" -type f | grep -v ".git" | wc -l` (Linked to FR-16)
- [ ] 6.1.3 Count config files: `find . -maxdepth 2 \( -name "*.json" -o -name "*.yaml" -o -name "*.toml" \) | grep -v ".git" | wc -l` (Linked to FR-16)
- [ ] 6.1.4 Save file counts to `docs/specs/010-fresh-install-validation/FILE_COUNTS.md` (Linked to FR-16)

### 6.2: Execute Ingestion (existing script only)
- [ ] 6.2.1 Run bulk_ingest for code files (Linked to FR-16)
  ```bash
  cd /Users/kayisrahman/Documents/workspace/ideas/synapse
  python3 -m scripts.bulk_ingest --root-dir . --file-type code --no-gitignore 2>&1 | tee docs/specs/010-fresh-install-validation/INGESTION_CODE.log | tail -20
  ```
- [ ] 6.2.2 Run bulk_ingest for docs (Linked to FR-16)
  ```bash
  python3 -m scripts.bulk_ingest --root-dir . --file-type doc --no-gitignore 2>&1 | tee docs/specs/010-fresh-install-validation/INGESTION_DOCS.log | tail -20
  ```
- [ ] 6.2.3 Run bulk_ingest for config files (Linked to FR-16)
  ```bash
  python3 -m scripts.bulk_ingest --root-dir . --file-type config --no-gitignore 2>&1 | tee docs/specs/010-fresh-install-validation/INGESTION_CONFIG.log | tail -20
  ```
- [ ] 6.2.4 Track success/failure for each batch (Linked to FR-16)
- [ ] 6.2.5 Log completion time (Linked to FR-16)

### 6.3: Verify Ingestion Complete
- [ ] 6.3.1 Check sources count using curl MCP list_sources (Linked to FR-16)
  ```bash
  curl -X POST http://localhost:8002/mcp \
    -H "Accept: application/json, text/event-stream" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_sources","arguments":{"project_id":"synapse"}}}' \
    > docs/specs/010-fresh-install-validation/LIST_SOURCES_RESPONSE.json 2>&1
  ```
- [ ] 6.3.2 Verify source count > 50 (Linked to FR-16)
- [ ] 6.3.3 Log final ingestion summary (Linked to FR-16)

**Phase 6 Exit Criteria:** All 10 tasks complete, files ingested using existing scripts only

---

## Phase 7: Knowledge Verification (9 tasks)

**Constraint:** NO code creation/modification. Use CLI query command only, document gaps.
- [ ] 7.1.1.1 Run `python3 -m synapse.cli.main query "What is Synapse?"` (Linked to US-18)
- [ ] 7.1.1.2 Verify output contains "RAG" or "local" or "AI" (Linked to US-18)
- [ ] 7.1.1.3 Verify output relevant to project purpose (Linked to US-18)
- [ ] 7.1.1.4 Mark result: PASS/FAIL (Linked to US-18)

#### 7.1.2: What embedding model?
- [ ] 7.1.2.1 Run `python3 -m synapse.cli.main query "What embedding model is used?"` (Linked to US-18)
- [ ] 7.1.2.2 Verify output contains "BGE-M3" (Linked to US-18)
- [ ] 7.1.2.3 Verify output contains model file name (Linked to US-18)
- [ ] 7.1.2.4 Mark result: PASS/FAIL (Linked to US-18)

#### 7.1.3: What is the data directory?
- [ ] 7.1.3.1 Run `python3 -m synapse.cli.main query "What is the data directory?"` (Linked to US-18)
- [ ] 7.1.3.2 Verify output contains "data" directory (Linked to US-18)
- [ ] 7.1.3.3 Verify output contains correct path (Linked to US-18)
- [ ] 7.1.3.4 Mark result: PASS/FAIL (Linked to US-18)

#### 7.1.4: What is the MCP endpoint?
- [ ] 7.1.4.1 Run `python3 -m synapse.cli.main query "What is the MCP endpoint?"` (Linked to US-18)
- [ ] 7.1.4.2 Verify output contains "8002" (Linked to US-18)
- [ ] 7.1.4.3 Verify output contains "/mcp" (Linked to US-18)
- [ ] 7.1.4.4 Mark result: PASS/FAIL (Linked to US-18)

#### 7.1.5: What version is this?
- [ ] 7.1.5.1 Run `python3 -m synapse.cli.main query "What version is this?"` (Linked to US-18)
- [ ] 7.1.5.2 Verify output contains "1.3.0" (Linked to US-18)
- [ ] 7.1.5.3 Mark result: PASS/FAIL (Linked to US-18)

### 7.2: Architecture Knowledge Tests

#### 7.2.1: Memory Hierarchy
- [ ] 7.2.1.1 Run `python3 -m synapse.cli.main query "What is the memory hierarchy?"` (Linked to US-16)
- [ ] 7.2.1.2 Verify output contains "Symbolic" (Linked to US-16)
- [ ] 7.2.1.3 Verify output contains "Episodic" (Linked to US-16)
- [ ] 7.2.1.4 Verify output contains "Semantic" (Linked to US-16)
- [ ] 7.2.1.5 Verify correct priority order (Linked to US-16)
- [ ] 7.2.1.6 Mark result: PASS/FAIL (Linked to US-16)

#### 7.2.2: CLI Commands Available
- [ ] 7.2.2.1 Run `python3 -m synapse.cli.main query "What CLI commands are available?"` (Linked to US-16)
- [ ] 7.2.2.2 Verify output contains "setup" (Linked to US-16)
- [ ] 7.2.2.3 Verify output contains "ingest" (Linked to US-16)
- [ ] 7.2.2.4 Verify output contains "query" (Linked to US-16)
- [ ] 7.2.2.5 Mark result: PASS/FAIL (Linked to US-16)

#### 7.2.3: MCP Tools Available
- [ ] 7.2.3.1 Run `python3 -m synapse.cli.main query "What MCP tools are available?"` (Linked to US-16)
- [ ] 7.2.3.2 Verify output contains "list_projects" (Linked to US-16)
- [ ] 7.2.3.3 Verify output contains "ingest_file" (Linked to US-16)
- [ ] 7.2.3.4 Verify output contains 8 tool names (Linked to US-16)
- [ ] 7.2.3.5 Mark result: PASS/FAIL (Linked to US-16)

**Phase 7 Exit Criteria:** All 9 tasks complete, 9/9 knowledge queries pass

---

## Phase 8: Documentation & Cleanup (8 tasks)

**Constraint:** NO code creation/modification. Use write command to create documentation files only.
- [ ] 8.1.1 Create VALIDATION_REPORT.md with echo/write (Linked to Non-Functional)
- [ ] 8.1.2 Document all CLI command results (PASS/FAIL) (Linked to Non-Functional)
- [ ] 8.1.3 Document all MCP tool results (Linked to Non-Functional)
- [ ] 8.1.4 Document performance metrics (Linked to Non-Functional)
- [ ] 8.1.5 Document error messages (Linked to Non-Functional)

### 8.2: Create BUGS_AND_ISSUES.md
- [ ] 8.2.1 Create bugs log in spec directory (Linked to Non-Functional)
- [ ] 8.2.2 Document all bugs discovered with severity (Linked to Non-Functional)
- [ ] 8.2.3 Document reproduction steps (Linked to Non-Functional)
- [ ] 8.2.4 Document expected vs actual behavior (Linked to Non-Functional)
- [ ] 8.2.5 Add suggested fixes (no code changes) (Linked to Non-Functional)

### 8.3: Create INGESTION_SUMMARY.md
- [ ] 8.3.1 Create summary in spec directory (Linked to FR-16)
- [ ] 8.3.2 Document files ingested count (Linked to FR-16)
- [ ] 8.3.3 Document file type breakdown (Linked to FR-16)
- [ ] 8.3.4 Document success/failure rates (Linked to FR-16)
- [ ] 8.3.5 Document chunk statistics (Linked to FR-16)

### 8.4: Create KNOWLEDGE_VERIFICATION.md
- [ ] 8.4.1 Create verification doc in spec directory (Linked to US-19)
- [ ] 8.4.2 Document query + expected + actual for each (Linked to US-19)
- [ ] 8.4.3 Document PASS/FAIL for each query (Linked to US-19)
- [ ] 8.4.4 Document confidence levels (Linked to US-19)
- [ ] 8.4.5 Identify knowledge gaps (Linked to US-19)

### 8.5: Cleanup Temporary Files
- [ ] 8.5.1 Remove `/tmp/mcp_test_helper.py` (Linked to Constraint)
- [ ] 8.5.2 Remove `/tmp/ingest_project.py` (Linked to Constraint)
- [ ] 8.5.3 Remove `/tmp/source_files.txt` (Linked to Constraint)
- [ ] 8.5.4 Remove `/tmp/*.json` files (Linked to Constraint)
- [ ] 8.5.5 Verify no artifacts in source directories (Linked to Constraint)

### 8.6: Update Tasks
- [ ] 8.6.1 Mark all Phase 1-7 tasks as complete (Linked to SDD Protocol)
- [ ] 8.6.2 Mark all Phase 8 tasks as complete (Linked to SDD Protocol)
- [ ] 8.6.3 Add final commit hash to tasks.md (Linked to SDD Protocol)

### 8.7: Update Central Index
- [ ] 8.7.1 Update `docs/specs/index.md` with feature entry (Linked to SDD Protocol)
- [ ] 8.7.2 Set status to "[Completed]" (Linked to SDD Protocol)
- [ ] 8.7.3 Add completion date (Linked to SDD Protocol)
- [ ] 8.7.4 Add final commit hash (Linked to SDD Protocol)

### 8.8: Final Verification
- [ ] 8.8.1 Verify no source files modified (Linked to Constraint)
- [ ] 8.8.2 Verify all output files created (Linked to Non-Functional)
- [ ] 8.8.3 Verify all tasks marked complete (Linked to SDD Protocol)
- [ ] 8.8.4 Verify validation complete (Linked to all FRs)

**Phase 8 Exit Criteria:** All 8 tasks complete, documentation ready

---

## Success Criteria Summary

### Must Have (for completion)
- [ ] Phase 1: 5/5 tasks complete
- [ ] Phase 2: 10/10 tasks complete (7/7 P0 commands pass)
- [ ] Phase 3: 10/10 tasks complete (6/6 P1 commands pass)
- [ ] Phase 4: 8/8 tasks complete
- [ ] Phase 5: 12/12 tasks complete (8/8 MCP tools pass)
- [ ] Phase 6: 10/10 tasks complete (80+ files ingested)
- [ ] Phase 7: 9/9 tasks complete (9/9 knowledge queries pass)
- [ ] Phase 8: 8/8 tasks complete (all documentation created)
- [ ] VALIDATION_REPORT.md created
- [ ] BUGS_AND_ISSUES.md created
- [ ] No source files modified

### Should Have
- [ ] All P2/P3 commands pass
- [ ] INGESTION_SUMMARY.md created
- [ ] KNOWLEDGE_VERIFICATION.md created
- [ ] Performance metrics within limits

---

## Task Execution Order

1. **Start with Phase 1** - Environment must be ready
2. **Phase 2** - Critical commands first
3. **Phase 3** - Important commands
4. **Phase 4** - Additional options
5. **Phase 5** - MCP tools (requires server running)
6. **Phase 6** - Full ingestion (requires MCP tools working)
7. **Phase 7** - Knowledge verification (requires ingestion complete)
8. **Phase 8** - Documentation (final step)

---

## Notes

**Constraint Reminder:**
- NO file modifications allowed
- All test artifacts in /tmp/
- Log all bugs, failures, issues
- Read-only validation only

**Testing Approach:**
- Sequential execution (one command at a time)
- Immediate logging of results
- Continue on failure (log and move to next)
- Mark PASS/FAIL for each task

**Performance Targets:**
- Setup: < 30 seconds
- Config: < 2 seconds
- Models list: < 2 seconds
- Query: < 5 seconds
- MCP search: < 3 seconds
- Full ingestion: < 5 minutes

---

**Last Updated**: January 31, 2026  
**Status**: Ready for execution  
**Next Phase**: Phase 1 - Environment Check
