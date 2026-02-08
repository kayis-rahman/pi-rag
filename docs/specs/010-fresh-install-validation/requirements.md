# Fresh Installation Validation - Requirements

**Feature ID**: 010-fresh-install-validation  
**Status**: [In Progress]  
**Created**: January 31, 2026  
**Last Updated**: January 31, 2026

---

## Overview

Validate all Synapse functionality by executing CLI commands and MCP tools as a fresh user would on a new Mac installation with BGE-M3 already running on port 8002. This validation ensures the system works correctly out-of-the-box and has complete knowledge about itself after onboarding.

**Key Constraints:**
- ZERO file modifications (read-only validation only)
- Log all bugs, failures, and issues discovered
- Test MCP tools via HTTP API on port 8002
- Full project ingestion for self-knowledge
- Project ID for ingestion: `synapse`
- Ingest all project files except `tests/` directory

**MCP Endpoint:** `http://localhost:8002/mcp` (already running)

---

## User Stories

### Phase 1: CLI Commands Validation

#### US-1: Fresh Setup Validation
**As a** new user with BGE-M3 already running,  
**I want** to run `synapse setup` to initialize the system,  
**So that** I can verify the setup process works correctly on fresh Mac.

**Acceptance Criteria:**
- [ ] Setup auto-detects user home directory (`~/.synapse/`)
- [ ] Setup creates all required directories
- [ ] Setup validates existing BGE-M3 model
- [ ] Setup completes without errors
- [ ] Exit code: 0 (success)

#### US-2: Configuration Display
**As a** user,  
**I want** to run `synapse config` to view system state,  
**So that** I can verify configuration is correct.

**Acceptance Criteria:**
- [ ] Config command displays data directory path
- [ ] Config command displays models directory path
- [ ] Config command displays environment mode
- [ ] Verbose mode (`--verbose`) shows all settings
- [ ] Completion time: < 2 seconds

#### US-3: Model Management
**As a** user,  
**I want** to run `synapse models list` to see available models,  
**So that** I can verify BGE-M3 model is installed correctly.

**Acceptance Criteria:**
- [ ] Models list shows BGE-M3 embedding model as installed
- [ ] Models list shows model file size
- [ ] Models list shows model file path
- [ ] Models verify command confirms model integrity
- [ ] Completion time: < 2 seconds

#### US-4: Server Operations
**As a** user,  
**I want** to start, stop, and check status of the MCP server,  
**So that** I can verify server operations work correctly.

**Acceptance Criteria:**
- [ ] Server starts successfully on default port
- [ ] Server stops cleanly without errors
- [ ] Status shows accurate server state (running/stopped)
- [ ] Health endpoint responds correctly
- [ ] No zombie processes after stop

#### US-5: Document Ingestion
**As a** user,  
**I want** to run `synapse ingest <path>` to add documents to RAG,  
**So that** I can verify ingestion works correctly.

**Acceptance Criteria:**
- [ ] Ingest single file successfully
- [ ] Ingest directory successfully
- [ ] Multiple file types supported (.py, .md, .json, .txt)
- [ ] Custom chunk size parameter works
- [ ] Non-existent file handled gracefully

#### US-6: RAG Query
**As a** user,  
**I want** to run `synapse query "<text>"` to search knowledge,  
**So that** I can verify RAG queries work correctly.

**Acceptance Criteria:**
- [ ] Simple query returns relevant results
- [ ] JSON format output works (`--json`)
- [ ] Top-k parameter works (`-k 5`)
- [ ] Query with no results handled gracefully
- [ ] Response time: < 5 seconds

#### US-7: Onboarding Workflow
**As a** new user,  
**I want** to run the onboarding process,  
**So that** I can verify the complete setup workflow works.

**Acceptance Criteria:**
- [ ] Interactive onboarding runs successfully
- [ ] Quick mode (`--quick`) uses all defaults
- [ ] Skip test option works (`--skip-test`)
- [ ] Skip ingest option works (`--skip-ingest`)
- [ ] Summary displayed at completion

---

### Phase 2: MCP Tool Validation (NEW)

#### US-8: List Projects
**As a** user,  
**I want** to call `list_projects()` MCP tool,  
**So that** I can verify project listing works.

**Acceptance Criteria:**
- [ ] HTTP POST to `/mcp` with correct JSON-RPC request
- [ ] Response contains project list
- [ ] Synapse project appears in list
- [ ] Response time: < 2 seconds

#### US-9: List Sources
**As a** user,  
**I want** to call `list_sources(project_id="synapse")` MCP tool,  
**So that** I can verify document listing works.

**Acceptance Criteria:**
- [ ] HTTP POST to `/mcp` with project_id parameter
- [ ] Response contains list of ingested sources
- [ ] File types and metadata displayed correctly
- [ ] Empty list if no files ingested yet

#### US-10: Get Context
**As a** user,  
**I want** to call `get_context(project_id, context_type, query)` MCP tool,  
**So that** I can verify comprehensive context retrieval works.

**Acceptance Criteria:**
- [ ] Can retrieve symbolic memory context
- [ ] Can retrieve episodic memory context
- [ ] Can retrieve semantic memory context
- [ ] Query parameter filters results correctly
- [ ] Authority hierarchy respected in results

#### US-11: Semantic Search
**As a** user,  
**I want** to call `search(project_id, query, memory_type)` MCP tool,  
**So that** I can verify semantic search works.

**Acceptance Criteria:**
- [ ] Search returns relevant results
- [ ] Can search specific memory type (all, symbolic, episodic, semantic)
- [ ] Top-k parameter controls result count
- [ ] Confidence scores in results
- [ ] Response time: < 3 seconds

#### US-12: File Ingestion via MCP
**As a** user,  
**I want** to call `ingest_file(project_id, file_path)` MCP tool,  
**So that** I can verify remote file ingestion works.

**Acceptance Criteria:**
- [ ] Upload file via HTTP POST to `/v1/upload`
- [ ] Ingest file via MCP with file_path from upload
- [ ] File added to semantic memory
- [ ] Chunks created correctly
- [ ] Auto-cleanup after ingestion

#### US-13: Add Symbolic Fact
**As a** user,  
**I want** to call `add_fact(project_id, fact_key, fact_value)` MCP tool,  
**So that** I can verify symbolic memory creation works.

**Acceptance Criteria:**
- [ ] Fact added to symbolic memory
- [ ] Fact key and value stored correctly
- [ ] Category parameter supported
- [ ] Confidence score configurable
- [ ] Fact retrievable via search

#### US-14: Add Episodic Lesson
**As a** user,  
**I want** to call `add_episode(project_id, title, content)` MCP tool,  
**So that** I can verify episodic memory creation works.

**Acceptance Criteria:**
- [ ] Episode added to episodic memory
- [ ] Title and content stored correctly
- [ ] Lesson type configurable (success, pattern, mistake, failure)
- [ ] Quality score supported
- [ ] Episode retrievable via search

#### US-15: Conversation Analysis
**As a** user,  
**I want** to call `analyze_conversation(project_id, user_message, agent_response)` MCP tool,  
**So that** I can verify automatic learning extraction works.

**Acceptance Criteria:**
- [ ] Facts extracted from conversation
- [ ] Episodes extracted from conversation
- [ ] Auto-store option works
- [ ] Extraction mode configurable
- [ ] Results returned as structured data

---

### Phase 3: Knowledge Base Readiness (NEW)

#### US-16: Full Code Knowledge
**As a** user,  
**I want** to query the system about its own code,  
**So that** I can verify all source files were ingested correctly.

**Acceptance Criteria:**
- Query "What CLI commands are available?" returns accurate list
- Query "How does the RAG system work?" returns accurate explanation
- Query "What is the memory hierarchy?" returns correct priority order
- Query "What MCP tools are available?" returns all 8 tools
- Confidence level: High (>90%)

#### US-17: Full Documentation Knowledge
**As a** user,  
**I want** to query the system about its documentation,  
**So that** I can verify all docs were ingested correctly.

**Acceptance Criteria:**
- Query "What is the SDD protocol?" returns accurate description
- Query "How do I add a new feature?" returns setup instructions
- Query "What is Spec-Driven Development?" returns comprehensive answer
- Query "What is the current project status?" returns feature list
- Confidence level: High (>90%)

#### US-18: System Self-Awareness
**As a** user,  
**I want** to query the system about its own architecture,  
**So that** I can verify the system knows itself completely.

**Acceptance Criteria:**
- Query "What is Synapse?" returns: "Local RAG system using llama-cpp-python"
- Query "What embedding model is used?" returns: "BGE-M3 (bge-m3-q8_0.gguf)"
- Query "What is the data directory?" returns correct path
- Query "What is the MCP endpoint?" returns: "http://localhost:8002/mcp"
- Query "What version is this?" returns: "1.3.0"
- All answers match symbolic memory facts

#### US-19: Project Context
**As a** user,  
**I want** to query for comprehensive project information,  
**So that** I can verify the knowledge base is complete.

**Acceptance Criteria:**
- Can retrieve complete project context via `get_context`
- Can search across all memory types
- Can retrieve facts and episodes
- Can find recent operations and patterns
- System ready for production use

---

## Functional Requirements

### FR-1: Setup Command
The `synapse setup` command must:
- Auto-detect user home directory (`~/.synapse/`)
- Create required directories (data, models, rag_index, docs, logs)
- Validate existing BGE-M3 model
- Support `--force`, `--offline`, `--no-model-check` flags
- Complete within 30 seconds

### FR-2: Config Command
The `synapse config` command must:
- Display all configuration settings
- Support `--verbose` flag for detailed output
- Support `--json` flag for JSON format
- Complete within 2 seconds

### FR-3: Models Command
The `synapse models` command must:
- List all installed models with status
- Verify model integrity
- Download new models (if needed)
- Remove models (if needed)
- Complete within 2 seconds

### FR-4: Server Commands
The `synapse start/stop/status` commands must:
- Start server on specified port (default: 8002)
- Stop server cleanly
- Report accurate server status
- Provide health endpoint at `/health`
- Handle port conflicts gracefully

### FR-5: Ingest Command
The `synapse ingest` command must:
- Process single files and directories
- Support multiple file types (.py, .md, .json, .txt, .rst, .yaml)
- Create chunks with configurable size (default: 500 chars)
- Support overlap (default: 50 chars)
- Handle errors gracefully

### FR-6: Query Command
The `synapse query` command must:
- Search semantic memory for relevant results
- Support JSON output format (`--json`)
- Support top-k parameter (`-k 5`)
- Return results with confidence scores
- Complete within 5 seconds

### FR-7: Onboard Command
The `synapse onboard` command must:
- Run interactive wizard with system checks
- Support `--quick`, `--silent`, `--skip-test`, `--skip-ingest` flags
- Ingest current project files
- Display summary and next steps
- Complete within 60 seconds (excluding downloads)

### FR-8: MCP List Projects
The `list_projects()` tool must:
- Accept no parameters
- Return list of all registered projects
- Include project metadata (ID, created, last accessed)
- Complete within 2 seconds

### FR-9: MCP List Sources
The `list_sources(project_id)` tool must:
- Accept project_id parameter
- Return list of all ingested sources
- Include source metadata (file path, type, chunks)
- Complete within 2 seconds

### FR-10: MCP Get Context
The `get_context(project_id, context_type, query)` tool must:
- Accept project_id, context_type, query parameters
- Return comprehensive context from all memory types
- Respect authority hierarchy (symbolic > episodic > semantic)
- Support max_results parameter
- Complete within 3 seconds

### FR-11: MCP Search
The `search(project_id, query, memory_type, top_k)` tool must:
- Accept project_id, query, memory_type, top_k parameters
- Return search results with confidence scores
- Support searching specific memory types
- Complete within 3 seconds

### FR-12: MCP Ingest File
The `ingest_file(project_id, file_path, source_type)` tool must:
- Accept project_id, file_path, source_type parameters
- Upload file via HTTP POST to `/v1/upload`
- Ingest file to semantic memory
- Auto-cleanup uploaded file
- Return ingestion result with chunk count

### FR-13: MCP Add Fact
The `add_fact(project_id, fact_key, fact_value, category, confidence)` tool must:
- Accept all parameters
- Store fact in symbolic memory
- Return fact creation result
- Fact retrievable via search
- Complete within 2 seconds

### FR-14: MCP Add Episode
The `add_episode(project_id, title, content, lesson_type, quality)` tool must:
- Accept all parameters
- Store episode in episodic memory
- Return episode creation result
- Episode retrievable via search
- Complete within 2 seconds

### FR-15: MCP Analyze Conversation
The `analyze_conversation(project_id, user_message, agent_response, context, auto_store, extraction_mode)` tool must:
- Accept all parameters
- Extract facts and episodes from conversation
- Optionally auto-store extracted learning
- Return structured analysis results
- Complete within 3 seconds

### FR-16: Full Project Ingestion (NEW)
The system must:
- Ingest all source code files (.py files in synapse/, scripts/)
- Ingest all documentation files (.md files in docs/, root)
- Ingest all configuration files (.json, .yaml, .toml, .env.example)
- Create searchable chunks for all files
- Support project_id "synapse"
- Complete within 5 minutes

### FR-17: Knowledge Verification (NEW)
The system must:
- Answer "What is Synapse?" correctly
- Answer "How does RAG work?" correctly
- Answer "What are the MCP tools?" correctly
- Answer "What is the memory hierarchy?" correctly
- Answer "What embedding model is used?" correctly
- All answers with confidence >90%

---

## Non-Functional Requirements

### NFR-1: Performance
- Setup: < 30 seconds (excluding model download)
- Config: < 2 seconds
- Models list: < 2 seconds
- Query: < 5 seconds
- MCP search: < 3 seconds
- Full ingestion: < 5 minutes
- Memory usage: < 500MB additional

### NFR-2: Error Handling
- Clear error messages for all failures
- Proper exit codes (0=success, 1=error)
- Graceful handling of missing dependencies
- Network error handling for MCP calls
- No crashes or hangs

### NFR-3: User Experience
- Consistent output formatting
- Helpful usage information (`--help` flag)
- Progress indicators for long operations
- Summary display on completion
- Next steps guidance

### NFR-4: Reliability
- Idempotent operations (running twice is safe)
- Atomic operations where possible
- Clean error recovery
- No data corruption
- No file modifications (read-only validation)

### NFR-5: Documentation Quality
- All commands tested and documented
- All MCP tools validated
- All bugs logged with severity
- Knowledge verification results captured
- Clear pass/fail status for each requirement

---

## Files to Ingest

### Source Code (~50 files)
```
synapse/cli/main.py
synapse/cli/commands/*.py (11 files)
synapse/core/*.py (15 files)
synapse/core/**/*.py (10+ files)
synapse/mcp_server/*.py (10 files)
scripts/*.py (5 files)
```

### Configuration Files (~10 files)
```
configs/rag_config.json
pyproject.toml
AGENTS.md
.env.example
README.md
```

### Documentation Files (~20 files)
```
README.md
docs/**/*.md (all spec files)
AGENTS.md
any other .md files in root
```

### Total: ~80-100 files

**Excluded:**
- `tests/` directory (per user request)
- `__pycache__/` directories
- `.git/` directory
- `.venv/` directory
- Any temporary files

---

## MCP Endpoint Configuration

**URL:** `http://localhost:8002/mcp`  
**Method:** HTTP POST  
**Content-Type:** application/json  
**Format:** JSON-RPC 2.0

**Example Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "list_projects",
    "arguments": {}
  }
}
```

**Example Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"projects\": [{\"id\": \"synapse\", ...}]}"
      }
    ]
  }
}
```

---

## Success Criteria

### CLI Commands
- [ ] All P0 commands pass (100%): setup, config, models list, start, stop, status
- [ ] All P1 commands pass (90%+): setup --force, ingest, query, onboard
- [ ] All P2 commands pass (80%+): additional flags and options
- [ ] Overall pass rate: 90%+

### MCP Tools
- [ ] All 8 MCP tools tested
- [ ] All tools return valid responses
- [ ] All tools complete within time limits
- [ ] No tool crashes or errors

### Knowledge Base
- [ ] All source code files ingested
- [ ] All documentation files ingested
- [ ] All config files ingested
- [ ] All knowledge verification queries pass
- [ ] Self-awareness test: 100% accuracy

### Documentation
- [ ] VALIDATION_REPORT.md created with all results
- [ ] BUGS_AND_ISSUES.md created with all bugs logged
- [ ] INGESTION_SUMMARY.md created with ingestion stats
- [ ] KNOWLEDGE_VERIFICATION.md created with test results
- [ ] Central index.md updated

### Non-Destructive Testing
- [ ] No source files modified
- [ ] No temporary files left in source directories
- [ ] All test artifacts in temporary directories
- [ ] System state unchanged after validation

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| MCP server not running | High | Check and start if needed |
| BGE-M3 model missing | Medium | Verify with `synapse models list` |
| Port 8002 in use | Medium | Use custom port for testing |
| Permission issues | Medium | Use user home directory (~/.synapse/) |
| Network errors | Low | Use `--offline` flags |
| Large file ingestion timeout | Low | Increase timeout, log partial results |
| MCP tool errors | Medium | Log errors, continue with other tools |

---

## Dependencies

### Required
- Python 3.8+ installed
- BGE-M3 model running on port 8002
- Terminal access for CLI commands
- HTTP client for MCP testing (curl or requests)

### Optional
- Docker (not required for Mac native mode)
- jq (for JSON parsing)

---

## Timeline Estimate

| Phase | Tasks | Time |
|-------|-------|------|
| 1. Environment Check | 5 | 10 min |
| 2. P0 CLI Commands | 10 | 20 min |
| 3. P1 CLI Commands | 10 | 20 min |
| 4. P2/P3 CLI Commands | 8 | 15 min |
| 5. MCP Tool Validation | 12 | 25 min |
| 6. Full Project Ingestion | 10 | 30 min |
| 7. Knowledge Verification | 8 | 15 min |
| 8. Documentation | 5 | 15 min |
| **Total** | **~68 tasks** | **~2.5 hours** |

---

## Acceptance Criteria Summary

### Must Have (for completion)
- [ ] All P0 CLI commands pass (7/7)
- [ ] MCP server running and accessible
- [ ] Full project ingestion completed
- [ ] VALIDATION_REPORT.md created
- [ ] BUGS_AND_ISSUES.md created
- [ ] No source files modified

### Should Have
- [ ] All P1 CLI commands pass (6/6)
- [ ] All MCP tools validated (8/8)
- [ ] Knowledge verification queries pass (5/5)
- [ ] INGESTION_SUMMARY.md created
- [ ] KNOWLEDGE_VERIFICATION.md created

### Nice to Have
- [ ] All P2/P3 CLI commands pass
- [ ] Performance metrics collected
- [ ] Screen recording of validation
- [ ] Automated validation script

---

## Related Documentation

- `AGENTS.md` - Spec-Driven Development (SDD) Protocol
- `pyproject.toml` - CLI entry points
- `docs/specs/005-cli-priority-testing/` - Previous CLI testing
- `docs/specs/007-cli-manual-testing-and-docs/` - Manual testing spec
- MCP Server: `mcp_server/rag_server.py`

---

**Created**: January 31, 2026  
**Last Updated**: January 31, 2026  
**Status**: Ready for planning
