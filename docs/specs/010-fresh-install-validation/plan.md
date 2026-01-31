# Fresh Installation Validation - Technical Plan

**Feature ID**: 010-fresh-install-validation  
**Status**: [Planning]  
**Created**: January 31, 2026  
**Last Updated**: January 31, 2026

---

## Implementation Strategy

This plan outlines the step-by-step approach to validate Synapse on a fresh Mac installation. The validation is **non-destructive** - no source files will be modified. All test artifacts will be stored in temporary directories.

**Key Approach:**
1. Sequential execution of CLI commands (P0 → P1 → P2 → P3)
2. HTTP-based testing of MCP tools via curl/requests
3. Full project ingestion using file scanner
4. Knowledge verification queries
5. Comprehensive documentation of all results

---

## Phase 1: Environment Check (10 minutes)

### Objective
Verify the environment is ready for validation.

### Tasks
1. **Check Python Installation**
   ```bash
   python3 --version
   # Expected: Python 3.8+
   ```

2. **Check Synapse CLI Installation**
   ```bash
   python3 -m synapse.cli.main --help
   # Expected: Help output with command list
   ```

3. **Check MCP Server Status**
   ```bash
   curl -s http://localhost:8002/health
   # Expected: {"status": "healthy"} or similar
   ```

4. **Check BGE-M3 Model**
   ```bash
   python3 -m synapse.cli.main models list
   # Expected: BGE-M3 model shown as installed
   ```

5. **Check Data Directory**
   ```bash
   ls -la ~/.synapse/data/
   # Expected: Directories created (data, models, rag_index, docs, logs)
   ```

### Success Criteria
- Python 3.8+ installed
- Synapse CLI accessible
- MCP server running on port 8002
- BGE-M3 model installed
- Data directories exist

### Output
- Environment check results logged
- Any missing dependencies documented

---

## Phase 2: P0 CLI Commands (20 minutes)

### Objective
Validate all critical commands that must work.

### 2.1: Setup Command Tests

**Test 2.1.1: Fresh Setup**
```bash
cd ~  # Ensure running from home directory
python3 -m synapse.cli.main setup --no-model-check
```
**Expected:** Creates ~/.synapse/ directory structure
**Validation:**
- [ ] Exit code: 0
- [ ] Directories created: data, models, rag_index, docs, logs
- [ ] Config file created: ~/.synapse/configs/rag_config.json
- [ ] Output contains "SYNAPSE setup complete!"

**Test 2.1.2: Setup with Force**
```bash
python3 -m synapse.cli.main setup --force --no-model-check
```
**Expected:** Re-runs setup without errors
**Validation:**
- [ ] Exit code: 0
- [ ] No errors about duplicate directories
- [ ] Output contains "SYNAPSE setup complete!"

### 2.2: Config Command Tests

**Test 2.2.1: Basic Config**
```bash
python3 -m synapse.cli.main config
```
**Expected:** Displays configuration
**Validation:**
- [ ] Exit code: 0
- [ ] Output contains "Data directory:"
- [ ] Output contains "Models directory:"
- [ ] Output shows correct paths (~/.synapse/)
- [ ] Completion time: < 2 seconds

**Test 2.2.2: Verbose Config**
```bash
python3 -m synapse.cli.main config --verbose
```
**Expected:** Shows all configuration details
**Validation:**
- [ ] Exit code: 0
- [ ] Output contains "chunk_size"
- [ ] Output contains "top_k"
- [ ] Output shows all settings

### 2.3: Models Command Tests

**Test 2.3.1: List Models**
```bash
python3 -m synapse.cli.main models list
```
**Expected:** Shows installed models
**Validation:**
- [ ] Exit code: 0
- [ ] Output contains "BGE-M3" or "bge-m3"
- [ ] Output shows model file size
- [ ] Output shows model status (installed)
- [ ] Completion time: < 2 seconds

**Test 2.3.2: Verify Models**
```bash
python3 -m synapse.cli.main models verify
```
**Expected:** Verifies model integrity
**Validation:**
- [ ] Exit code: 0
- [ ] Output shows "verified" or "valid"
- [ ] No errors about missing model

### 2.4: Server Command Tests

**Test 2.4.1: Start Server**
```bash
python3 -m synapse.cli.main start &
sleep 5
curl -s http://localhost:8002/health
```
**Expected:** Server starts successfully
**Validation:**
- [ ] Process starts without errors
- [ ] Health endpoint returns success
- [ ] Output contains "Server started" or similar
- [ ] Process ID recorded for cleanup

**Test 2.4.2: Check Status**
```bash
python3 -m synapse.cli.main status
```
**Expected:** Shows server is running
**Validation:**
- [ ] Exit code: 0
- [ ] Output shows "running" or "started"
- [ ] Output shows port number (8002)

**Test 2.4.3: Stop Server**
```bash
python3 -m synapse.cli.main stop
```
**Expected:** Server stops cleanly
**Validation:**
- [ ] Exit code: 0
- [ ] Output shows "stopped" or "stopping"
- [ ] Process terminated (no zombie)
- [ ] Health endpoint returns error after stop

### Success Criteria
- All P0 commands pass (7/7)
- Exit codes all 0
- No errors or warnings
- Performance within limits

---

## Phase 3: P1 CLI Commands (20 minutes)

### Objective
Validate important commands that should work.

### 3.1: Ingest Command Tests

**Test 3.1.1: Ingest Single File**
```bash
python3 -m synapse.cli.main ingest README.md
```
**Expected:** File ingested to semantic memory
**Validation:**
- [ ] Exit code: 0
- [ ] Output contains "ingested" or "success"
- [ ] Chunk count displayed
- [ ] No errors about file type

**Test 3.1.2: Ingest Directory**
```bash
python3 -m synapse.cli.main ingest configs/
```
**Expected:** All config files ingested
**Validation:**
- [ ] Exit code: 0
- [ ] Multiple files processed
- [ ] Total chunk count displayed
- [ ] No errors about unsupported files

### 3.2: Query Command Tests

**Test 3.2.1: Simple Query**
```bash
python3 -m synapse.cli.main query "What is Synapse?"
```
**Expected:** Returns relevant results
**Validation:**
- [ ] Exit code: 0
- [ ] Output contains relevant information
- [ ] Response time: < 5 seconds
- [ ] Results contain "RAG" or "memory"

**Test 3.2.2: Query with Top-K**
```bash
python3 -m synapse.cli.main query "RAG system" -k 3
```
**Expected:** Returns top 3 results
**Validation:**
- [ ] Exit code: 0
- [ ] Output shows 3 results
- [ ] Results are relevant

**Test 3.2.3: Query JSON Format**
```bash
python3 -m synapse.cli.main query "CLI commands" --json
```
**Expected:** Returns JSON output
**Validation:**
- [ ] Exit code: 0
- [ ] Output is valid JSON
- [ ] JSON contains results array
- [ ] JSON contains confidence scores

### 3.3: Onboard Command Tests

**Test 3.3.1: Quick Onboarding**
```bash
python3 -m synapse.cli.main onboard --quick --skip-ingest
```
**Expected:** Quick onboarding completes
**Validation:**
- [ ] Exit code: 0
- [ ] Output shows "Onboarding Complete"
- [ ] Summary displayed
- [ ] No prompts (quick mode)

**Test 3.3.2: Skip Test Onboarding**
```bash
python3 -m synapse.cli.main onboard --skip-test --skip-ingest
```
**Expected:** Onboarding skips test query
**Validation:**
- [ ] Exit code: 0
- [ ] Output shows "Onboarding Complete"
- [ ] Test skipped as expected

### Success Criteria
- All P1 commands pass (6/6)
- Exit codes all 0
- No errors or warnings
- Performance within limits

---

## Phase 4: P2/P3 CLI Commands (15 minutes)

### Objective
Validate additional options and edge cases.

### 4.1: Additional Setup Options

**Test 4.1.1: Offline Setup**
```bash
python3 -m synapse.cli.main setup --offline --no-model-check
```
**Expected:** Setup completes without network
**Validation:**
- [ ] Exit code: 0
- [ ] Output mentions "offline"
- [ ] No network errors

### 4.2: Additional Config Options

**Test 4.2.1: JSON Config Output**
```bash
python3 -m synapse.cli.main config --json > /tmp/config.json
cat /tmp/config.json | python3 -m json.tool > /dev/null
```
**Expected:** Valid JSON output
**Validation:**
- [ ] Exit code: 0
- [ ] Valid JSON (no parse errors)
- [ ] Contains required fields

### Success Criteria
- P2 commands pass
- Edge cases handled correctly
- No crashes or hangs

---

## Phase 5: MCP Tool Validation (25 minutes)

### Objective
Validate all 8 MCP tools via HTTP API.

### 5.1: Helper Script
Create a Python helper for MCP calls:
```python
#!/usr/bin/env python3
# mcp_test_helper.py

import requests
import json

MCP_URL = "http://localhost:8002/mcp"

def mcp_call(tool_name, arguments=None):
    """Call MCP tool and return result."""
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": tool_name,
            "arguments": arguments or {}
        }
    }
    response = requests.post(MCP_URL, json=payload)
    return response.json()
```

### 5.2: Test Tool: list_projects

```bash
python3 mcp_test_helper.py list_projects
```
**Expected:** Returns list of projects
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains "projects" array
- [ ] "synapse" project appears in list
- [ ] Response time: < 2 seconds

### 5.3: Test Tool: list_sources

```bash
python3 mcp_test_helper.py list_sources '{"project_id": "synapse"}'
```
**Expected:** Returns list of ingested sources
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains "sources" array
- [ ] Files appear as sources
- [ ] Metadata included (file path, type)

### 5.4: Test Tool: get_context

```bash
python3 mcp_test_helper.py get_context '{
  "project_id": "synapse",
  "context_type": "all",
  "query": "CLI commands"
}'
```
**Expected:** Returns comprehensive context
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains symbolic, episodic, semantic sections
- [ ] Query results relevant
- [ ] Authority hierarchy respected

### 5.5: Test Tool: search

```bash
python3 mcp_test_helper.py search '{
  "project_id": "synapse",
  "query": "RAG system",
  "memory_type": "semantic",
  "top_k": 3
}'
```
**Expected:** Returns search results
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains results array
- [ ] Results have confidence scores
- [ ] Results relevant to query
- [ ] Response time: < 3 seconds

### 5.6: Test Tool: ingest_file

**Step 1: Upload File**
```bash
curl -X POST http://localhost:8002/v1/upload \
  -F "file=@/Users/kayisrahman/Documents/workspace/ideas/synapse/README.md"
```
**Expected:** File uploaded successfully
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains file_path
- [ ] File ready for ingestion

**Step 2: Ingest via MCP**
```bash
python3 mcp_test_helper.py ingest_file '{
  "project_id": "synapse",
  "file_path": "<from_upload_response>",
  "source_type": "file"
}'
```
**Expected:** File ingested to semantic memory
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains chunk count
- [ ] File auto-deleted after ingestion

### 5.7: Test Tool: add_fact

```bash
python3 mcp_test_helper.py add_fact '{
  "project_id": "synapse",
  "fact_key": "test_fact_validation",
  "fact_value": "This is a test fact from validation",
  "category": "test",
  "confidence": 1.0
}'
```
**Expected:** Fact added to symbolic memory
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains fact creation result
- [ ] Fact retrievable via search

### 5.8: Test Tool: add_episode

```bash
python3 mcp_test_helper.py add_episode '{
  "project_id": "synapse",
  "title": "Test Episode Validation",
  "content": "Testing add_episode tool - situation, action, outcome, lesson",
  "lesson_type": "success",
  "quality": 1.0
}'
```
**Expected:** Episode added to episodic memory
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains episode creation result
- [ ] Episode retrievable via search

### 5.9: Test Tool: analyze_conversation

```bash
python3 mcp_test_helper.py analyze_conversation '{
  "project_id": "synapse",
  "user_message": "How do I validate the system?",
  "agent_response": "Run the validation script which tests all CLI commands and MCP tools.",
  "auto_store": true
}'
```
**Expected:** Extracts facts and episodes from conversation
**Validation:**
- [ ] HTTP status: 200
- [ ] Response contains extracted facts
- [ ] Response contains extracted episodes
- [ ] Auto-store worked if enabled

### Success Criteria
- All 8 MCP tools tested
- All tools return valid responses
- All tools complete within time limits
- No tool crashes or errors

---

## Phase 6: Full Project Ingestion (30 minutes)

### Objective
Ingest all project files (except tests/) to build complete knowledge base.

### 6.1: File Discovery

**Step 1: Find all source files**
```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse

# Find all Python files (excluding tests/)
find synapse/ -name "*.py" -type f > /tmp/source_files.txt

# Find all markdown files
find . -maxdepth 3 -name "*.md" -type f | grep -v ".git" | grep -v "__pycache__" > /tmp/md_files.txt

# Find all config files
find . -maxdepth 2 -name "*.json" -o -name "*.yaml" -o -name "*.toml" | grep -v ".git" | grep -v "__pycache__" > /tmp/config_files.txt
```

**Step 2: Count files**
```bash
wc -l /tmp/source_files.txt /tmp/md_files.txt /tmp/config_files.txt
# Expected: ~80-100 total files
```

### 6.2: Ingestion Strategy

**Approach:** Batch ingestion using MCP upload + ingest_file

**Step 1: Upload each file**
For each file in the lists:
```bash
# Upload file
UPLOAD_RESPONSE=$(curl -s -X POST http://localhost:8002/v1/upload \
  -F "file=@$FILE_PATH")

# Extract file_path from response
FILE_PATH_MCP=$(echo $UPLOAD_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['file_path'])")

# Ingest file
curl -s -X POST http://localhost:8002/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "ingest_file",
      "arguments": {
        "project_id": "synapse",
        "file_path": "'$FILE_PATH_MCP'",
        "source_type": "code"
      }
    }
  }'
```

### 6.3: Automation Script

Create automated ingestion script:
```python
#!/usr/bin/env python3
# ingest_project.py

import os
import requests
import json
from pathlib import Path

MCP_URL = "http://localhost:8002/mcp"
UPLOAD_URL = "http://localhost:8002/v1/upload"
PROJECT_ID = "synapse"

def upload_and_ingest(file_path):
    """Upload file and ingest via MCP."""
    # Upload file
    with open(file_path, 'rb') as f:
        files = {'file': (os.path.basename(file_path), f)}
        upload_response = requests.post(UPLOAD_URL, files=files)
    
    if upload_response.status_code != 200:
        print(f"❌ Upload failed: {file_path}")
        return False
    
    file_path_mcp = upload_response.json()['file_path']
    
    # Ingest file
    ingest_payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "ingest_file",
            "arguments": {
                "project_id": PROJECT_ID,
                "file_path": file_path_mcp,
                "source_type": "code"
            }
        }
    }
    
    ingest_response = requests.post(MCP_URL, json=ingest_payload)
    
    if ingest_response.status_code == 200:
        print(f"✅ Ingested: {file_path}")
        return True
    else:
        print(f"❌ Ingest failed: {file_path}")
        return False

def main():
    # Collect all files
    files_to_ingest = []
    
    # Source files
    for py_file in Path('/Users/kayisrahman/Documents/workspace/ideas/synapse/synapse').rglob("*.py"):
        if "test" not in str(py_file):
            files_to_ingest.append(str(py_file))
    
    # Config files
    for config_file in Path('/Users/kayisrahman/Documents/workspace/ideas/synapse').glob("*.json"):
        files_to_ingest.append(str(config_file))
    for config_file in Path('/Users/kayisrahman/Documents/workspace/ideas/synapse').glob("*.toml"):
        files_to_ingest.append(str(config_file))
    
    # Markdown files
    for md_file in Path('/Users/kayisrahman/Documents/workspace/ideas/synapse').glob("*.md"):
        files_to_ingest.append(str(md_file))
    for md_file in Path('/Users/kayisrahman/Documents/workspace/ideas/synapse/docs').rglob("*.md"):
        files_to_ingest.append(str(md_file))
    
    # Ingest all files
    success_count = 0
    fail_count = 0
    
    for file_path in files_to_ingest:
        if upload_and_ingest(file_path):
            success_count += 1
        else:
            fail_count += 1
    
    print(f"\n📊 Ingestion Summary:")
    print(f"   Success: {success_count}")
    print(f"   Failed: {fail_count}")
    print(f"   Total: {len(files_to_ingest)}")

if __name__ == "__main__":
    main()
```

### 6.4: Execute Ingestion
```bash
chmod +x ingest_project.py
python3 ingest_project.py
```

### Success Criteria
- All source files ingested (~50 files)
- All config files ingested (~10 files)
- All documentation files ingested (~20 files)
- Total: ~80-100 files ingested
- Success rate: 95%+
- Completion time: < 5 minutes

---

## Phase 7: Knowledge Verification (15 minutes)

### Objective
Verify the system has complete knowledge about itself.

### 7.1: System Self-Awareness Tests

**Test 7.1.1: What is Synapse?**
```bash
python3 -m synapse.cli.main query "What is Synapse?"
```
**Expected Answer:** "Local RAG system using llama-cpp-python for AI assistance"
**Validation:**
- [ ] Output contains "RAG" or "local" or "AI"
- [ ] Output relevant to project purpose
- [ ] Confidence: High

**Test 7.1.2: What embedding model is used?**
```bash
python3 -m synapse.cli.main query "What embedding model is used?"
```
**Expected Answer:** "BGE-M3 (bge-m3-q8_0.gguf)"
**Validation:**
- [ ] Output contains "BGE-M3"
- [ ] Output contains model file name
- [ ] Confidence: High

**Test 7.1.3: What is the data directory?**
```bash
python3 -m synapse.cli.main query "What is the data directory?"
```
**Expected Answer:** "/opt/synapse/data or ~/.synapse/data"
**Validation:**
- [ ] Output contains "data" directory
- [ ] Output contains correct path
- [ ] Confidence: High

**Test 7.1.4: What is the MCP endpoint?**
```bash
python3 -m synapse.cli.main query "What is the MCP endpoint?"
```
**Expected Answer:** "http://localhost:8002/mcp"
**Validation:**
- [ ] Output contains "8002"
- [ ] Output contains "/mcp"
- [ ] Confidence: High

**Test 7.1.5: What version is this?**
```bash
python3 -m synapse.cli.main query "What version is this?"
```
**Expected Answer:** "1.3.0"
**Validation:**
- [ ] Output contains "1.3.0"
- [ ] Confidence: High

### 7.2: Architecture Knowledge Tests

**Test 7.2.1: Memory Hierarchy**
```bash
python3 -m synapse.cli.main query "What is the memory hierarchy?"
```
**Expected Answer:** "Symbolic > Episodic > Semantic"
**Validation:**
- [ ] Output contains "Symbolic"
- [ ] Output contains "Episodic"
- [ ] Output contains "Semantic"
- [ ] Correct priority order

**Test 7.2.2: CLI Commands**
```bash
python3 -m synapse.cli.main query "What CLI commands are available?"
```
**Expected Answer:** List of commands (setup, config, models, start, stop, status, ingest, query, onboard)
**Validation:**
- [ ] Output contains "setup"
- [ ] Output contains "ingest"
- [ ] Output contains "query"
- [ ] Output contains "onboard"

**Test 7.2.3: MCP Tools**
```bash
python3 -m synapse.cli.main query "What MCP tools are available?"
```
**Expected Answer:** List of 8 tools (list_projects, list_sources, get_context, search, ingest_file, add_fact, add_episode, analyze_conversation)
**Validation:**
- [ ] Output contains "list_projects"
- [ ] Output contains "ingest_file"
- [ ] Output contains 8 tool names
- [ ] Confidence: High

### 7.3: Documentation Knowledge Tests

**Test 7.3.1: SDD Protocol**
```bash
python3 -m synapse.cli.main query "What is the SDD protocol?"
```
**Expected Answer:** "Spec-Driven Development protocol for feature development"
**Validation:**
- [ ] Output contains "Spec" or "SDD"
- [ ] Output relevant to protocol description

**Test 7.3.2: Current Features**
```bash
python3 -m synapse.cli.main query "What features are currently in progress?"
```
**Expected Answer:** List of in-progress features (001-comprehensive-test-suite, 002-auto-learning, etc.)
**Validation:**
- [ ] Output contains feature numbers
- [ ] Output shows "In Progress" status

### Success Criteria
- 9/9 knowledge verification queries pass
- All answers correct and relevant
- Confidence level: High (>90%)

---

## Phase 8: Documentation & Cleanup (15 minutes)

### 8.1: Create VALIDATION_REPORT.md
Document all test results:
- CLI command results (PASS/FAIL)
- MCP tool results
- Performance metrics
- Error messages
- Exit codes

### 8.2: Create BUGS_AND_ISSUES.md
Log all bugs discovered:
- Bug description
- Severity level
- Reproduction steps
- Expected vs actual behavior
- Suggested fixes (no code changes)

### 8.3: Create INGESTION_SUMMARY.md
Document ingestion results:
- Files ingested count
- File type breakdown
- Success/failure rates
- Chunk statistics
- Any errors encountered

### 8.4: Create KNOWLEDGE_VERIFICATION.md
Document knowledge test results:
- Query + Expected Answer + Actual Answer
- Pass/Fail for each query
- Confidence levels
- Knowledge gaps identified

### 8.5: Cleanup
- Remove temporary test files
- Remove helper scripts
- Stop any running server
- Ensure no artifacts left in source directories

### 8.6: Update Tasks
- Mark all tasks complete in tasks.md
- Update central index.md with [Completed]
- Add final commit hash

---

## Output Files

### Required Outputs
1. **VALIDATION_REPORT.md** - Complete validation results
2. **BUGS_AND_ISSUES.md** - All bugs logged
3. **INGESTION_SUMMARY.md** - Ingestion statistics
4. **KNOWLEDGE_VERIFICATION.md** - Knowledge test results

### Optional Outputs
5. **Screen recording** - Visual validation walkthrough
6. **Automated script** - Reusable validation script
7. **Performance metrics** - Timing data

---

## Risk Mitigation

### Risk: MCP Server Not Running
**Mitigation:** Check health endpoint first, start server if needed
```bash
# Check health
curl -s http://localhost:8002/health || python3 -m synapse.cli.main start

# Wait for startup
sleep 5

# Verify health
curl -s http://localhost:8002/health
```

### Risk: Port 8002 in Use
**Mitigation:** Use custom port, log conflict
```bash
# Check what's using port 8002
lsof -i :8002

# Use different port if needed
python3 -m synapse.cli.main start --port 8080
```

### Risk: Large File Timeout
**Mitigation:** Increase timeout, log partial results
```bash
# Increase timeout for large files
timeout 120 python3 -m synapse.cli.main ingest large_file.md
```

### Risk: Network Errors
**Mitigation:** Use --offline flags, log errors
```bash
# Use offline mode for setup
python3 -m synapse.cli.main setup --offline
```

---

## Success Metrics

### Must Have
- [ ] 7/7 P0 CLI commands pass (100%)
- [ ] 8/8 MCP tools validated (100%)
- [ ] 80+ files ingested (100%)
- [ ] VALIDATION_REPORT.md created
- [ ] BUGS_AND_ISSUES.md created
- [ ] No source files modified

### Should Have
- [ ] 6/6 P1 CLI commands pass (100%)
- [ ] 9/9 knowledge queries pass (100%)
- [ ] INGESTION_SUMMARY.md created
- [ ] KNOWLEDGE_VERIFICATION.md created

### Nice to Have
- [ ] P2/P3 commands pass
- [ ] Performance metrics < limits
- [ ] Automated validation script
- [ ] Screen recording

---

## Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| 1. Environment Check | 10 min | 10 min |
| 2. P0 CLI Commands | 20 min | 30 min |
| 3. P1 CLI Commands | 20 min | 50 min |
| 4. P2/P3 CLI Commands | 15 min | 65 min |
| 5. MCP Tool Validation | 25 min | 90 min |
| 6. Full Project Ingestion | 30 min | 120 min |
| 7. Knowledge Verification | 15 min | 135 min |
| 8. Documentation | 15 min | 150 min |
| **Total** | **~2.5 hours** | |

---

## Validation Script

Create automated validation script for reproducibility:
```bash
#!/bin/bash
# validate_synapse.sh

echo "=== Synapse Fresh Installation Validation ==="
echo "Date: $(date)"
echo ""

# Phase 1: Environment Check
echo "Phase 1: Environment Check"
python3 --version
python3 -m synapse.cli.main --help
curl -s http://localhost:8002/health || echo "MCP server not running"
python3 -m synapse.cli.main models list

# Phase 2-8: Run all validations
# (Full script in validation_script.sh)

echo ""
echo "=== Validation Complete ==="
```

---

## Next Steps

1. **Create tasks.md** with granular checklist
2. **Update central index.md** with feature entry
3. **Execute validation** following tasks.md
4. **Document results** in output files
5. **Mark complete** and update index.md

---

**Plan Status**: Ready for implementation  
**Created**: January 31, 2026  
**Last Updated**: January 31, 2026
