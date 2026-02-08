# Automatic Learning System - Technical Plan

**Feature ID**: 002-auto-learning
**Created**: January 4, 2026
**Status**: [In Progress]

---

## Architecture Overview

### High-Level Design

**Current Architecture (Explicit Learning):**
```
User Request → opencode → MCP Tool Call → Manual Memory Addition (if user says "remember")
                ↓
            Optional: rag.add_fact / rag.add_episode
```

**Target Architecture (Automatic Learning):**
```
User Request → opencode → MCP Tool Call → Operation Tracked
                ↓
                    Task Completion Detected?
                ↓
                    Yes → Auto-Extract Episode → Store Episode
                ↓
                    Code Change Detected?
                ↓
                    Yes → Auto-Extract Facts → Store Facts
                ↓
                    Pattern Detected?
                ↓
                    Yes → Auto-Extract Episode → Store Episode
                ↓
                Return Response to User
```

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                  MCP Server (rag_server.py)                │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │   AutoLearningTracker (NEW)                         │   │
│  │   - Tracks operations in buffer                        │   │
│  │   - Detects task completion                            │   │
│  │   - Detects patterns                                     │   │
│  │   - Extracts episodes/facts using LLM                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                         ↓                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │   LearningExtractor (NEW)                            │   │
│  │   - LLM-based episode extraction                      │   │
│  │   - LLM-based fact extraction                        │   │
│  │   - Confidence scoring                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                         ↓                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │   Existing Stores (REUSE)                             │   │
│  │   - EpisodicStore (episodic_store.py)             │   │
│  │   - MemoryStore (memory_store.py)                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Specifications

### Module 1: AutoLearningTracker (NEW)

**File**: `core/auto_learning_tracker.py`
**Purpose**: Track operations and trigger automatic learning

**Class Interface**:
```python
class AutoLearningTracker:
    def __init__(self, config: dict, model_manager: ModelManager)
    def track_operation(self, operation: dict) -> None
    def detect_task_completion(self, operations: List[dict]) -> Optional[dict]
    def detect_pattern(self, operations: List[dict]) -> Optional[dict]
    def should_auto_learn(self, operation: dict) -> bool
```

**Key Methods**:

#### track_operation()
**Input**: Operation dict with:
```python
{
    "tool_name": "rag.search",
    "project_id": "synapse",
    "arguments": {...},
    "result": "success" | "error",
    "timestamp": "2026-01-04T19:00:00Z",
    "duration_ms": 123
}
```
**Output**: None
**Side Effect**: Stores in in-memory buffer
**Behavior**:
- Append to `self.operation_buffer`
- Limit buffer size to 100 operations (rolling window)
- Check for immediate patterns after each addition

#### detect_task_completion()
**Algorithm**:
```python
def detect_task_completion(self, operations: List[dict]) -> Optional[dict]:
    """
    Detect completed task from operation sequence.
    
    Patterns:
    1. Multi-step operations (3+ tools used)
    2. Successful file ingestion (rag.ingest_file success)
    3. Bug fix sequence (search → read → edit)
    4. Deployment sequence (build → test → deploy)
    """
    # Check for multi-step operations
    if len(operations) >= 3:
        last_3 = operations[-3:]
        
        # Pattern: File ingestion success
        if all(op["tool_name"] == "rag.ingest_file" for op in last_3):
            if all(op["result"] == "success" for op in last_3):
                return {
                    "type": "task_completion",
                    "situation": "Multiple files were ingested",
                    "action": "File ingestion completed successfully",
                    "outcome": "All files processed without errors",
                    "confidence": 0.8
                }
        
        # Pattern: Search → Get Context → Code modification
        tools_used = [op["tool_name"] for op in last_3]
        if set(["rag.search", "rag.get_context", "read", "edit"]).intersection(tools_used):
            return {
                "type": "task_completion",
                "situation": "Information retrieval and code modification",
                "action": "Searched, retrieved context, and modified code",
                "outcome": "Task completed with updated codebase",
                "confidence": 0.75
            }
    
    return None
```

#### detect_pattern()
**Algorithm**:
```python
def detect_pattern(self, operations: List[dict]) -> Optional[dict]:
    """
    Detect repeated patterns across operations.
    
    Patterns:
    1. Same tool fails 2+ times consecutively
    2. Same operation succeeds 3+ times
    3. Specific query pattern repeats
    """
    if len(operations) < 3:
        return None
    
    # Check for repeated failures
    last_5 = operations[-5:]
    failures = [op for op in last_5 if op["result"] == "error"]
    
    if len(failures) >= 2:
        # Check if same tool failed
        failed_tools = [op["tool_name"] for op in failures]
        if len(set(failed_tools)) == 1:  # All same tool
            return {
                "type": "pattern",
                "situation": f"Repeated failures in {failed_tools[0]}",
                "action": f"Attempted {failed_tools[0]} multiple times without success",
                "outcome": "Pattern detected: operation failing repeatedly",
                "confidence": 0.85
            }
    
    # Check for repeated successes
    successes = [op for op in last_5 if op["result"] == "success"]
    if len(successes) >= 3:
        success_tools = [op["tool_name"] for op in successes]
        if len(set(success_tools)) == 1:
            return {
                "type": "pattern",
                "situation": f"Repeated success with {success_tools[0]}",
                "action": f"Successfully used {success_tools[0]} multiple times",
                "outcome": "Pattern detected: operation consistently succeeds",
                "confidence": 0.8
            }
    
    return None
```

---

### Module 2: LearningExtractor (NEW)

**File**: `core/learning_extractor.py`
**Purpose**: Use LLM to extract episodes/facts from operations

**Class Interface**:
```python
class LearningExtractor:
    def __init__(self, model_manager: ModelManager)
    def extract_episode_from_task(self, task: dict) -> Optional[dict]
    def extract_facts_from_code(self, file_path: str, file_content: str) -> List[dict]
    def extract_episode_from_pattern(self, pattern: dict) -> Optional[dict]
```

**Key Methods**:

#### extract_episode_from_task()
**Prompt Design**:
```python
PROMPT = """You are a Learning Extraction System for an AI agent.

Analyze this completed task and extract a learnable episode:

Task Information:
- Situation: {situation}
- Action: {action}
- Outcome: {outcome}

STRICT RULES:
1. Extract an episode ONLY if:
   - Task succeeded in a non-obvious way
   - A mistake was made and corrected
   - Strategy can be applied to future tasks
   
2. DO NOT extract if:
   - Task succeeded in an obvious/expected way
   - No lesson can be generalized
   - Only facts were learned (not strategies)

3. Lesson MUST be:
   - Abstract (not specific to this exact situation)
   - Actionable (what to do differently next time)
   - Concise (under 200 characters)

OUTPUT FORMAT (JSON only):
{
    "situation": "Brief description",
    "action": "Brief description",
    "outcome": "success/failure",
    "lesson": "Abstracted strategy (what to apply in future)",
    "lesson_type": "success|pattern|mistake|failure",
    "confidence": 0.75
}

If NO lesson qualifies, return: {"should_extract": false}"""
```

**Fallback Extraction (Rule-Based)**:
```python
def _extract_episode_rule_based(self, task: dict) -> Optional[dict]:
    """Fallback extraction if LLM fails."""
    if task["outcome"] == "success":
        return {
            "situation": task["situation"],
            "action": task["action"],
            "outcome": "success",
            "lesson": f"Strategy: {task['action']} leads to success",
            "lesson_type": "success",
            "confidence": 0.7
        }
    return None
```

#### extract_facts_from_code()
**Extraction Patterns**:
```python
def extract_facts_from_code(self, file_path: str, file_content: str) -> List[dict]:
    """Extract facts from code file using patterns."""
    facts = []
    
    # Pattern 1: Import statements
    import_pattern = re.compile(r'^\s*(import|from)\s+(\w+)')
    imports = import_pattern.findall(file_content)
    
    if imports:
        # Group by top-level package
        packages = [imp.split('.')[0] for imp in imports]
        unique_packages = list(set(packages))
        
        facts.append({
            "category": "fact",
            "key": "dependencies",
            "value": {"packages": unique_packages},
            "confidence": 1.0,
            "source": "code_analysis"
        })
    
    # Pattern 2: Framework usage
    framework_patterns = {
        r'@app\.route': 'fastapi',
        r'router\.': 'express',
        r'@Component': 'react/vue/angular',
        r'class Component': 'react/vue/angular'
    }
    
    for pattern, framework in framework_patterns.items():
        if pattern in file_content:
            facts.append({
                "category": "fact",
                "key": "framework",
                "value": {"framework": framework},
                "confidence": 1.0,
                "source": "code_analysis"
            })
    
    # Pattern 3: API endpoints
    api_pattern = re.compile(r'@\w+\.(get|post|put|delete|patch)\(')
    endpoints = api_pattern.findall(file_content)
    
    if endpoints:
        facts.append({
            "category": "fact",
            "key": "api_endpoints",
            "value": {"endpoints": endpoints},
            "confidence": 1.0,
            "source": "code_analysis"
        })
    
    return facts
```

---

### Module 3: Configuration Integration

**File**: `mcp_server/rag_server.py`
**Changes**:

#### Add Configuration Loading:
```python
def _load_auto_learning_config(self) -> dict:
    """Load automatic learning configuration from rag_config.json."""
    config_path = os.environ.get("SYNAPSE_CONFIG_PATH", "./configs/rag_config.json")
    
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
    except Exception as e:
        logger.warning(f"Failed to load config: {e}, using defaults")
        config = {}
    
    # Get auto_learning config or use defaults
    auto_config = config.get("automatic_learning", {
        "enabled": False,
        "mode": "moderate",
        "track_tasks": True,
        "track_code_changes": True,
        "track_operations": False,
        "min_episode_confidence": 0.6,
        "episode_deduplication": True
    })
    
    return auto_config
```

#### Initialize AutoLearningTracker in __init__:
```python
def __init__(self):
    # ... existing init code ...
    
    # Load configuration
    self.auto_learning_config = self._load_auto_learning_config()
    
    # Initialize AutoLearningTracker if enabled
    if self.auto_learning_config["enabled"]:
        self.auto_learning = AutoLearningTracker(
            config=self.auto_learning_config,
            model_manager=self._get_model_manager()  # Need to add model manager access
        )
    else:
        self.auto_learning = None
    
    # Operation buffer
    self.operation_buffer: List[dict] = []
```

#### Wrap All MCP Tools:
```python
async def search(self, project_id: str, query: str, ...):
    """Search semantic memory with automatic learning tracking."""
    start_time = datetime.now()
    
    # Track operation start
    operation = {
        "tool_name": "rag.search",
        "project_id": project_id,
        "arguments": {"query": query},
        "start_time": start_time
    }
    
    try:
        # Execute search
        result = await self._get_semantic_retriever().search(...)
        operation["result"] = "success"
        operation["outcome"] = "completed"
    except Exception as e:
        operation["result"] = "error"
        operation["outcome"] = "failed"
        operation["error"] = str(e)
    
    # Calculate duration
    operation["duration_ms"] = (datetime.now() - start_time).total_seconds() * 1000
    operation["timestamp"] = start_time
    
    # Track operation (if auto-learning enabled)
    if self.auto_learning and self._should_auto_track(operation):
        self.auto_learning.track_operation(operation)
        self.operation_buffer.append(operation)
        
        # Check for task completion
        task_completion = self.auto_learning.detect_task_completion(
            self.operation_buffer
        )
        
        if task_completion and self.auto_learning.config.get("track_tasks"):
            await self._auto_store_episode(project_id, task_completion)
        
        # Check for patterns
        pattern = self.auto_learning.detect_pattern(
            self.operation_buffer
        )
        
        if pattern and self.auto_learning.config.get("track_operations"):
            await self._auto_store_episode(project_id, pattern)
    
    return result

def _should_auto_track(self, operation: dict) -> bool:
    """Check if operation should be auto-tracked."""
    auto_learn = operation.get("arguments", {}).get("auto_learn", None)
    
    if auto_learn is not None:
        return auto_learn  # Respect explicit override
    
    return self.auto_learning.config.get("enabled", False)
```

---

## Data Flow

### Episode Storage Flow
```
1. MCP Tool Called (e.g., rag.ingest_file)
2. Operation tracked in AutoLearningTracker
3. Task completion detected
4. LearningExtractor.extract_episode_from_task()
5. Episode extracted (LLM or rule-based fallback)
6. Episode stored in EpisodicStore
7. Logged to metrics: episodes_created++
```

### Fact Storage Flow
```
1. File ingested via rag.ingest_file
2. Code analysis performed
3. Facts extracted using patterns
4. Facts stored in MemoryStore
5. Logged to metrics: facts_created++
```

---

## Implementation Strategy

### Phase 1: Foundation (1-2 hours)
- [ ] Create `core/auto_learning_tracker.py` module
- [ ] Create `core/learning_extractor.py` module
- [ ] Add configuration schema to `rag_config.json`
- [ ] Write unit tests for tracking logic
- [ ] Write unit tests for extraction logic

### Phase 2: Integration (2-3 hours)
- [ ] Modify `mcp_server/rag_server.py` __init__
- [ ] Add `_load_auto_learning_config()` method
- [ ] Add `_should_auto_track()` method
- [ ] Add `_auto_store_episode()` method
- [ ] Add `_auto_store_fact()` method
- [ ] Wrap all 7 MCP tools with tracking

### Phase 3: Testing (1-2 hours)
- [ ] Test episode extraction from task completion
- [ ] Test fact extraction from code ingestion
- [ ] Test pattern detection
- [ ] Test manual override (auto_learn=false)
- [ ] Test configuration modes (aggressive/moderate/minimal)
- [ ] Test deduplication logic

### Phase 4: Documentation (30 minutes)
- [ ] Update AGENTS.md with automatic learning section
- [ ] Update README.md with configuration examples
- [ ] Add inline code comments for new modules
- [ ] Create troubleshooting guide

---

## Dependencies

### New Files to Create
1. `core/auto_learning_tracker.py` - Operation tracking and pattern detection
2. `core/learning_extractor.py` - LLM-based learning extraction
3. `tests/test_auto_learning_tracker.py` - Unit tests
4. `tests/test_learning_extractor.py` - Unit tests

### Files to Modify
1. `configs/rag_config.json` - Add automatic_learning section
2. `mcp_server/rag_server.py` - Add tracking wrappers
3. `AGENTS.md` - Document automatic learning
4. `README.md` - Add configuration guide

### External Dependencies
- None (uses existing ModelManager, EpisodicStore, MemoryStore)

---

## Risk Mitigation Strategy

### Risk 1: Memory Bloat
**Implementation**:
- Confidence threshold filters low-quality episodes (min_episode_confidence: 0.6)
- Deduplication prevents repeated episodes (check for similarity before storing)
- Episode aging: Auto-delete episodes older than 90 days (future enhancement)

### Risk 2: LLM Failures
**Implementation**:
- Rule-based fallback for task completion episodes
- Error logging with full stack trace
- Retry with exponential backoff (3 attempts max)
- Graceful degradation: If LLM fails 3x, use rule-based only

### Risk 3: Performance Overhead
**Implementation**:
- In-memory buffer (no disk I/O during tracking)
- Async extraction doesn't block main operation
- Optional: Batch analysis every 10 operations instead of after each

### Risk 4: Incorrect Learning
**Implementation**:
- Conservative confidence thresholds (0.6-0.85)
- User can delete incorrect episodes via MCP tools
- Manual override allows disabling for one-off tasks
- Fact deduplication prevents repeated incorrect facts

---

## Migration Path

### No Migration Required
- New functionality is additive (doesn't break existing behavior)
- Existing explicit add_fact/add_episode tools still work
- Configuration defaults to `enabled: False` for backward compatibility
- Feature can be enabled by user via config change

### Deployment Steps
1. Update `configs/rag_config.json` with automatic_learning section
2. Deploy new modules (`auto_learning_tracker.py`, `learning_extractor.py`)
3. Deploy modified `mcp_server/rag_server.py`
4. Restart MCP server
5. Monitor logs for extraction events
6. Verify episodes/facts are being created

---

## Testing Strategy

### Unit Tests
```python
# test_auto_learning_tracker.py
def test_detect_task_completion_multi_step():
    """Test detection of multi-step operations."""
    operations = [
        {"tool_name": "rag.search", "result": "success"},
        {"tool_name": "rag.get_context", "result": "success"},
        {"tool_name": "read_file", "result": "success"}
    ]
    completion = tracker.detect_task_completion(operations)
    assert completion is not None
    assert completion["type"] == "task_completion"

def test_detect_pattern_repeated_failures():
    """Test detection of repeated failures."""
    operations = [
        {"tool_name": "rag.search", "result": "error"},
        {"tool_name": "rag.search", "result": "error"}
    ]
    pattern = tracker.detect_pattern(operations)
    assert pattern is not None
    assert "repeated" in pattern["situation"].lower()

def test_should_auto_track_with_explicit_override():
    """Test manual override of auto-tracking."""
    operation = {
        "arguments": {"auto_learn": false}
    }
    assert not tracker.should_auto_track(operation)
```

### Integration Tests
```python
# test_auto_learning_integration.py
async def test_episode_auto_storage_after_task():
    """Test episode is stored after task completion."""
    # Execute multi-step operation
    await backend.search("test")
    await backend.get_context("test")
    
    # Check episodic memory
    episodes = episodic_store.get_recent_episodes(1)
    assert len(episodes) > 0
    assert episodes[0].lesson_type == "success"

async def test_fact_extraction_from_code_ingestion():
    """Test facts extracted from code ingestion."""
    await backend.ingest_file(project_id, "test.py", ...)
    
    # Check symbolic memory
    facts = memory_store.get_facts_by_scope(project_id)
    assert any(f.key == "dependencies" for f in facts)
```

---

## Success Criteria

### Technical Success
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] No performance regression (<50ms overhead)
- [ ] No memory leaks (buffer size limited)
- [ ] Configuration validation works
- [ ] Error handling tested

### Functional Success
- [ ] Episodes stored immediately after task completion
- [ ] Facts extracted from code ingestion
- [ ] Patterns detected across operations
- [ ] Manual override works (auto_learn=false)
- [ ] Configuration modes work (aggressive/moderate/minimal)
- [ ] Deduplication prevents duplicates
- [ ] LLM failures fallback gracefully

### User Acceptance
- [ ] User confirms "opencode is constantly learning"
- [ ] Episodes are relevant and useful
- [ ] Facts are accurate
- [ ] No manual intervention needed for routine work
- [ ] Configuration is intuitive

---

## Open Questions

1. **Episode Deduplication Method**: Should we use exact text match or semantic similarity for deduplication?

2. **Pattern Buffer Size**: Should we analyze last 10 operations or last 100 for patterns?

3. **LLM Model**: Should episode extraction use the chat model or a faster small model?

4. **Confidence Thresholds**: Are the proposed thresholds (0.6-0.85) appropriate for your use case?

5. **Episode Aging**: Should we implement auto-deletion of old episodes to prevent memory bloat?

---

**Next Step**: Wait for user approval of this plan before creating tasks.md.
