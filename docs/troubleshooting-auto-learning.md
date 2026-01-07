# Auto-Learning Troubleshooting Guide

This guide helps you troubleshoot issues with the automatic learning system in Synapse.

---

## Table of Contents

1. [Auto-learning not working](#auto-learning-not-working)
2. [Episodes not being stored](#episodes-not-being-stored)
3. [Facts not being extracted](#facts-not-being-extracted)
4. [Performance issues](#performance-issues)
5. [Configuration problems](#configuration-problems)
6. [Manual override not respected](#manual-override-not-respected)

---

## Auto-Learning Not Working

### Symptom
Auto-learning is enabled but no episodes/facts are being created automatically.

### Diagnostics

**Step 1: Check configuration**
```bash
cat configs/rag_config.json | grep -A 10 "automatic_learning"
```

**Expected:**
```json
{
  "automatic_learning": {
    "enabled": true,
    "mode": "aggressive",
    ...
  }
}
```

**Fix**: Set `"enabled": true` if currently `false`.

**Step 2: Check server logs**
```bash
journalctl -u synapse-mcp -n 50 --no-pager | grep -i "auto-learning"
```

**Expected**: `AutoLearningTracker initialized: enabled=True, mode=aggressive`

**Fix**: If not present, check if MCP server restarted after config change.

**Step 3: Verify integration**
Check that operations are being tracked:

```python
# In MCP server logs, look for:
# "Tracking operation: rag.search"
# "Auto-stored episode: Test learned strategy..."
# "Auto-stored fact: dependencies"
```

**Fix**: If no tracking messages, verify `rag_server.py` includes integration code.

---

## Episodes Not Being Stored

### Symptom
Task completions are detected but episodes are not stored to episodic memory.

### Diagnostics

**Step 1: Check confidence threshold**
Episodes with confidence < `min_episode_confidence` are filtered out.

```json
{
  "min_episode_confidence": 0.6  // Episodes below this are rejected
}
```

**Fix**: Lower threshold temporarily to test:
```json
{
  "min_episode_confidence": 0.0  // Accept all episodes
}
```

**Step 2: Check deduplication**
Similar episodes may be filtered as duplicates (Jaccard similarity > 0.85).

```json
{
  "episode_deduplication": true
}
```

**Fix**: Disable deduplication temporarily to test:
```json
{
  "episode_deduplication": false
}
```

**Step 3: Check episodic database**
```bash
sqlite3 /opt/synapse/data/episodic_memory.db "SELECT COUNT(*) FROM episodes;"
```

**Expected**: Count > 0 after task completions.

**Fix**: If count is 0, check database permissions:
```bash
ls -l /opt/synapse/data/
chmod 666 /opt/synapse/data/episodic_memory.db
```

---

## Facts Not Being Extracted

### Symptom
Files are ingested but no facts about dependencies/framework/endpoints are created.

### Diagnostics

**Step 1: Check track_code_changes setting**
```json
{
  "track_code_changes": true  // Must be true
}
```

**Fix**: Set to `true` if currently `false`.

**Step 2: Check file content**
Facts are extracted from:
- Import statements (python, javascript, etc.)
- Framework patterns (FastAPI, Express, React, etc.)
- API endpoints (@app.get, @app.post, etc.)

**Example of extractable code:**
```python
from fastapi import FastAPI  # ✅ Extracts framework
import numpy as np           # ✅ Extracts dependency

@app.get("/users")            # ✅ Extracts endpoint
@app.post("/users")           # ✅ Extracts endpoint
```

**Fix**: Ensure ingested files contain these patterns.

**Step 3: Check fact deduplication**
Duplicate fact keys are rejected.

```bash
sqlite3 /opt/synapse/data/memory.db "SELECT key, COUNT(*) FROM facts GROUP BY key HAVING COUNT(*) > 1;"
```

**Expected**: No duplicate keys.

**Fix**: If duplicates exist, check:
```python
# Facts should have unique keys
# Example: "dependencies", "framework", "api_endpoints"
```

---

## Performance Issues

### Symptom
High latency (>100ms) on MCP tool calls after enabling auto-learning.

### Diagnostics

**Step 1: Measure overhead**
```python
import time

start = time.time()
result = await tool.call(...)
overhead = (time.time() - start) * 1000  # ms

print(f"Overhead: {overhead}ms")  # Should be <50ms
```

**Fix**: If overhead > 50ms, check for blocking operations.

**Step 2: Check LLM extraction**
Episode extraction uses LLM (if available).

```bash
# Check model loading time in logs
grep "Loading model" /var/log/synapse.log
```

**Fix**: Use lighter model or disable LLM extraction:
```json
{
  "mode": "minimal"  // Uses rule-based fallback only
}
```

**Step 3: Check buffer size**
Buffer is limited to 100 operations (LRU eviction).

```bash
# Check if buffer is at capacity
grep "Buffer at capacity" /var/log/synapse.log
```

**Fix**: Buffer automatically evicts old operations. If frequent eviction, check usage patterns.

---

## Configuration Problems

### Symptom
Configuration file is not loaded or contains errors.

### Diagnostics

**Step 1: Validate JSON syntax**
```bash
python3 -m json.tool configs/rag_config.json
```

**Expected**: No syntax errors.

**Fix**: Correct any JSON syntax errors (missing commas, brackets, etc.).

**Step 2: Check config path**
```bash
echo $RAG_CONFIG_PATH  # Should be ./configs/rag_config.json
```

**Fix**: Set environment variable if missing:
```bash
export RAG_CONFIG_PATH=/home/dietpi/synapse/configs/rag_config.json
```

**Step 3: Verify auto-learning section exists**
```bash
jq '.automatic_learning' configs/rag_config.json
```

**Expected**: Non-null object returned.

**Fix**: If `null`, add the section:
```json
{
  "automatic_learning": {
    "enabled": true,
    "mode": "aggressive",
    "track_tasks": true,
    "track_code_changes": true,
    "track_operations": true,
    "min_episode_confidence": 0.6,
    "episode_deduplication": true
  }
}
```

---

## Manual Override Not Respected

### Symptom
Setting `auto_learn: false` in tool arguments does not disable auto-learning.

### Diagnostics

**Step 1: Check implementation**
Verify `_should_auto_track()` method in `mcp_server/rag_server.py`:

```python
def _should_auto_track(self, operation: Dict[str, Any]) -> bool:
    auto_learn = operation.get("arguments", {}).get("auto_learn", None)

    if auto_learn is not None:
        return auto_learn  # Explicit override

    return self.auto_learning_config.get("enabled", False)
```

**Expected**: Explicit override checked before global config.

**Fix**: If override not implemented, add the check.

**Step 2: Test with explicit override**
```python
# This should NOT track
result = await mcp_tool(
    tool="rag.search",
    arguments={"query": "test", "auto_learn": false}
)
```

**Expected**: No tracking messages in logs.

**Fix**: Verify override parameter is passed through MCP layer.

---

## Common Error Messages

### "AutoLearningTracker initialized: enabled=False"
**Cause**: Auto-learning is disabled in config.

**Fix**: Set `enabled: true` in `automatic_learning` section.

### "Episode extraction returned None, skipping storage"
**Cause**: Episode confidence below threshold or obvious success/failure.

**Fix**: Lower `min_episode_confidence` or verify task complexity.

### "Duplicate episode detected (similarity: 0.92), skipping"
**Cause**: High similarity (>0.85) with existing episode.

**Fix**: This is expected behavior for duplicates. To force storage, disable `episode_deduplication`.

### "Fact tracking disabled, skipping fact storage"
**Cause**: `track_code_changes` is `false`.

**Fix**: Set `track_code_changes: true` in config.

### "LLM extraction failed, using rule-based fallback"
**Cause**: ModelManager returned error (model not loaded, LLM unavailable).

**Fix**: This is expected - rule-based fallback handles extraction. No action needed.

---

## Testing Auto-Learning

### Manual Test Script

```python
import asyncio
from mcp_server.rag_server import RAGMemoryBackend

async def test_auto_learning():
    backend = RAGMemoryBackend()

    # Test 1: Task completion (3+ operations)
    print("Test 1: Task completion detection...")
    await backend.search(project_id="test", query="test1")
    await backend.get_context(project_id="test", query="test2")
    # Check if episode was created in episodic memory

    # Test 2: Pattern detection (repeated failures)
    print("Test 2: Pattern detection...")
    for i in range(3):
        try:
            await backend.search(project_id="test", query="bad_query")
        except Exception:
            pass
    # Check if pattern episode was created

    print("Tests complete!")

asyncio.run(test_auto_learning())
```

### Integration Test Suite

```bash
# Run auto-learning integration tests
python3 -m pytest tests/test_auto_learning_integration.py -v

# Expected: 10 tests, most passing
# - Episode storage after task completion
# - Fact extraction from file ingestion
# - Pattern detection (repeated failures/successes)
# - Manual override (auto_learn=false)
# - Configuration modes
# - Deduplication logic
```

---

## Getting Help

If you still have issues:

1. **Check logs**: `journalctl -u synapse-mcp -n 100`
2. **Enable debug logging**: Set `RAG_LOG_LEVEL=DEBUG`
3. **Report issues**: Include:
   - Configuration (`configs/rag_config.json`)
   - Relevant logs (last 100 lines)
   - Steps to reproduce
   - Expected vs actual behavior

---

## Related Documentation

- [Auto-learning Feature Spec](docs/specs/002-auto-learning/requirements.md)
- [Technical Plan](docs/specs/002-auto-learning/plan.md)
- [Implementation Tasks](docs/specs/002-auto-learning/tasks.md)
- [AGENTS.md - Auto-Learning Section](AGENTS.md#automatic-learning-system)
