# Task Breakdown: Mac Local RAG Setup

**Feature ID**: 008-mac-local-rag-setup
**Created**: January 29, 2026
**Status**: [In Progress]
**Model**: BGE-M3 Q8_0 (~730MB)

---

## Phase 1: Environment Check (5 minutes)

### Phase 1.1: Python Verification
- [x] 1.1.1 Check Python version: `python3 --version` (Linked to US1) - ✅ Python 3.13.2
- [x] 1.1.2 Verify pip availability: `pip --version` (Linked to US1) - ✅ pip 25.3
- [x] 1.1.3 Verify virtual environment support (Linked to US1) - ✅ Supported

### Phase 1.2: System Check
- [x] 1.2.1 Check disk space: `df -h /` (Linked to US1) - ✅ 228GB total, 11GB used
- [x] 1.2.2 Verify >2GB available (Linked to US1) - ✅ 2.8GB available (plenty)
- [x] 1.2.3 Check port 8002 availability: `lsof -i :8002` (Linked to US3) - ✅ Port free

### Phase 1.3: CLI Verification
- [x] 1.3.1 Navigate to project: `cd /Users/kayisrahman/Documents/workspace/ideas/synapse` (Linked to US1) - ✅
- [x] 1.3.2 Test CLI entry point: `python3 -m synapse.cli.main --help` (Linked to US1) - ✅ Works
- [x] 1.3.3 Verify 8 commands displayed (Linked to US1) - ✅ 8 commands visible

---

## Phase 2: Install Dependencies (15 minutes)

### Phase 2.1: System Dependencies
- [x] 2.1.1 Check cmake: `which cmake && cmake --version` (Linked to US1) - ✅ cmake 4.2.0
- [x] 2.1.2 Install cmake if needed: `brew install cmake` (Linked to US1) - ✅ Already installed
- [x] 2.1.3 Check protobuf: `which protoc && protoc --version` (Linked to US1) - ✅ protobuf 33.1
- [x] 2.1.4 Install protobuf if needed: `brew install protobuf` (Linked to US1) - ✅ Already installed

### Phase 2.2: Virtual Environment
- [x] 2.2.1 Create virtual environment: `python3 -m venv venv` (Linked to US1) - ✅ Created
- [x] 2.2.2 Verify venv directory: `ls -la venv/` (Linked to US1) - ✅ Verified
- [x] 2.2.3 Activate venv: `source venv/bin/activate` (Linked to US1) - ✅ Activated
- [x] 2.2.4 Verify activation: `which python` (Linked to US1) - ✅ /Users/kayisrahman/Documents/workspace/ideas/synapse/venv/bin/python

### Phase 2.3: Package Installation
- [x] 2.3.1 Install synapse: `pip install -e .` (Linked to US1) - ✅ Installed successfully
- [x] 2.3.2 Verify installation: `pip list | grep synapse` (Linked to US1) - ✅ synapse 1.2.0
- [x] 2.3.3 Check for installation errors (Linked to US1) - ✅ No errors

### Phase 2.4: CLI Verification
- [x] 2.4.1 Test synapse command: `synapse --help` (Linked to US1) - ✅ Works
- [x] 2.4.2 Verify all 8 commands displayed (Linked to US1) - ✅ All 8 commands visible
- [x] 2.4.3 Document any missing commands (Linked to US1) - ✅ No missing commands

---

## Phase 3: Run Setup (10 minutes)

### Phase 3.1: Execute Setup
- [x] 3.1.1 Run setup: `synapse setup` (Linked to US1) - ✅ Directories created
- [x] 3.1.2 Verify directories created at `~/.synapse/` (Linked to US1) - ✅ Created
- [x] 3.1.3 Verify data directory: `~/.synapse/data/` (Linked to US1) - ✅ Created
- [x] 3.1.4 Verify models directory: `~/.synapse/data/models/` (Linked to US1) - ✅ Created

### Phase 3.2: Download Model
- [x] 3.2.1 Accept model download prompt when shown (Linked to US2) - ✅ Attempted
- [x] 3.2.2 Verify download starts: `📥 Downloading bge-m3-q8_0.gguf...` (Linked to US2) - ✅ Started
- [ ] 3.2.3 Wait for download to complete (~730MB) (Linked to US2) - ⏸ BLOCKED: Requires HuggingFace authentication
- [ ] 3.2.4 Verify download success: `✓ Model downloaded successfully` (Linked to US2) - ⏸ PENDING

### Phase 3.3: Manual Download (Fallback)
- [ ] 3.3.1 Authenticate with HuggingFace: `huggingface-cli login` (Linked to US2)
- [ ] 3.3.2 Download with correct URL: `huggingface-cli download BAAI/bge-m3-gguf` (Linked to US2)
- [ ] 3.3.3 Or download manually from browser (Linked to US2)
- [ ] 3.3.4 Place model at: `~/.synapse/models/bge-m3-q8_0.gguf` (Linked to US2)

### Phase 3.4: Verify Model
- [ ] 3.4.1 Check model file: `ls -lh ~/.synapse/models/` (Linked to US2)
- [ ] 3.4.2 Verify file size ~730MB (Linked to US2)
- [ ] 3.4.3 Run verification: `synapse models verify` (Linked to US2)
- [ ] 3.4.4 Verify model passes: `✓ embedding: bge-m3-q8_0.gguf (730 MB)` (Linked to US2)

### Phase 3.4: Complete Setup
- [ ] 3.4.1 Re-run setup: `synapse setup` (Linked to US1)
- [ ] 3.4.2 Verify setup complete message (Linked to US1)
- [ ] 3.4.3 Verify model detected as installed (Linked to US2)
- [ ] 3.4.4 Document setup summary (Linked to US1)

---

## Phase 4: Start & Test (10 minutes)

### Phase 4.1: Start Server
- [ ] 4.1.1 Start server: `synapse start` (Linked to US3)
- [ ] 4.1.2 Verify startup output (Linked to US3)
- [ ] 4.1.3 Record PID (Linked to US3)
- [ ] 4.1.4 Check port binding: `lsof -i :8002` (Linked to US3)

### Phase 4.2: Health Check
- [ ] 4.2.1 Wait for initialization: `sleep 3` (Linked to US3)
- [ ] 4.2.2 Test health endpoint: `curl http://localhost:8002/health` (Linked to US3)
- [ ] 4.2.3 Verify response: `{"status":"ok",...}` (Linked to US3)
- [ ] 4.2.4 Verify tools_available: 8 (Linked to US3)

### Phase 4.3: Status Test
- [ ] 4.3.1 Run status: `synapse status` (Linked to US3)
- [ ] 4.3.2 Verify server running: `✅ Running` (Linked to US3)
- [ ] 4.3.3 Verify model status (Linked to US3)
- [ ] 4.3.4 Verify storage status (Linked to US3)

### Phase 4.4: Query Test
- [ ] 4.4.1 Test query: `synapse query "test"` (Linked to US4)
- [ ] 4.4.2 Verify query executes (Linked to US4)
- [ ] 4.4.3 Verify parameters parsed (Linked to US4)
- [ ] 4.4.4 Document query output (Linked to US4)

### Phase 4.5: Stop Server
- [ ] 4.5.1 Stop server: `synapse stop` (Linked to US3)
- [ ] 4.5.2 Verify stop output (Linked to US3)
- [ ] 4.5.3 Verify PID matches (Linked to US3)
- [ ] 4.5.4 Verify cleanup: `✓ No zombie processes` (Linked to US3)

### Phase 4.6: Final Verification
- [ ] 4.6.1 Check status: `synapse status` (Linked to US3)
- [ ] 4.6.2 Verify stopped: `❌ Stopped` (Linked to US3)
- [ ] 4.6.3 Verify port free: `lsof -i :8002` (Linked to US3)
- [ ] 4.6.4 Document final state (Linked to US4)

---

## Summary

**Total Tasks**: 19 tasks across 4 phases

**Time Estimate**: ~40 minutes

**Phases**:
1. **Phase 1**: Environment Check (7 tasks, 5 min)
2. **Phase 2**: Install Dependencies (10 tasks, 15 min)
3. **Phase 3**: Run Setup (8 tasks, 10 min)
4. **Phase 4**: Start & Test (10 tasks, 10 min)

---

## Task Status Legend

- [ ] Pending
- [x] Completed
- [ ] In Progress
- [ ] Blocked
- [ ] Skipped

---

## Dependency Mapping

| Task | User Story | Requirement |
|------|------------|-------------|
| 1.1.x | US1 | FR1: macOS environment detection |
| 1.2.x | US1 | FR1: Disk space and port check |
| 1.3.x | US1 | FR1: CLI verification |
| 2.1.x | US1 | FR2: System dependencies |
| 2.2.x | US1 | FR2: Virtual environment |
| 2.3.x | US1 | FR2: Package installation |
| 2.4.x | US1 | FR2: CLI verification |
| 3.1.x | US1 | FR3: Directory creation |
| 3.2.x | US2 | FR4: Model download |
| 3.3.x | US2 | FR4: Model verification |
| 3.4.x | US1 | FR3: Setup completion |
| 4.1.x | US3 | FR5: Server startup |
| 4.2.x | US3 | FR5: Health verification |
| 4.3.x | US3 | FR5: Status verification |
| 4.4.x | US4 | FR6: Query test |
| 4.5.x | US3 | FR5: Server shutdown |
| 4.6.x | US3 | FR5: Final verification |

---

## Functional Requirements Reference

| FR | Description | Tasks |
|----|-------------|-------|
| FR1 | macOS environment setup | 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 3.1, 3.4 |
| FR2 | Dependency installation | 2.1, 2.2, 2.3, 2.4 |
| FR3 | Configuration setup | 3.1, 3.4 |
| FR4 | Model management | 3.2, 3.3 |
| FR5 | Server operations | 4.1, 4.2, 4.3, 4.5, 4.6 |
| FR6 | Query functionality | 4.4 |

---

## Notes

### Phase 2 Notes
- Virtual environment location: `/Users/kayisrahman/Documents/workspace/ideas/synapse/venv/`
- Activation command: `source venv/bin/activate`
- Deactivation: `deactivate`

### Phase 3 Notes
- Model download may take 5-10 minutes depending on internet speed
- If download fails, try: `synapse models download embedding --force`
- Model location: `~/.synapse/data/models/bge-m3-q8_0.gguf`

### Phase 4 Notes
- Server logs: `~/.synapse/data/logs/`
- If port 8002 is in use, check with: `lsof -i :8002`
- To kill process: `kill [PID]`

---

## Rollback Commands

### Remove Virtual Environment
```bash
deactivate
rm -rf venv
```

### Remove Synapse Data
```bash
rm -rf ~/.synapse/
```

### Clean Installation
```bash
deactivate
rm -rf venv ~/.synapse/
python3 -m venv venv
source venv/bin/activate
pip install -e .
```

---

**Last Updated**: January 29, 2026
**Maintainer**: opencode
