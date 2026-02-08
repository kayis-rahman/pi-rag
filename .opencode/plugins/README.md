# Synapse Auto-Learning Plugin for OpenCode

## Overview

Automatically extracts facts and episodes from agent conversations and stores them in Synapse memory.

## Configuration

Configure via `configs/rag_config.json` -> `universal_hooks` -> `adapters` -> `opencode`:

```json
{
  "universal_hooks": {
    "enabled": true,
    "default_project_id": "synapse",
    "adapters": {
      "opencode": {
        "enabled": true,
        "priority": 1,
        "analyze_after_tools": ["sy.mem.fact.add", "sy.mem.ep.add", "sy.mem.search", "sy.ctx.get", "sy.mem.ingest"],
        "min_message_length": 10,
        "skip_patterns": ["^test$", "^hello$", "^help$"],
        "async_processing": true,
        "extraction_mode": "heuristic"
      }
    }
  }
}
```

## Configuration Options

### OpenCode Adapter

| Option | Type | Default | Description |
|---------|------|----------|-------------|
| `enabled` | boolean | `true` | Enable/disable the plugin |
| `priority` | integer | `1` | Adapter execution order (lower = earlier) |
| `analyze_after_tools` | array | `["sy.mem.fact.add", ...]` | Synapse tools that trigger conversation analysis |
| `min_message_length` | integer | `10` | Minimum message length to analyze (shorter messages skipped) |
| `skip_patterns` | array | `["^test$", ...]` | Regex patterns to skip (routine conversations) |
| `async_processing` | boolean | `true` | Non-blocking async execution |
| `extraction_mode` | string | `"heuristic"` | `"heuristic"` \| `"llm"` \| `"hybrid"` |

### Conversation Analyzer

| Option | Type | Default | Description |
|---------|------|----------|-------------|
| `extraction_mode` | string | `"heuristic"` | Extraction strategy (heuristic/llm/hybrid) |
| `use_llm` | boolean | `false` | Enable LLM extraction (requires model) |
| `min_fact_confidence` | float | `0.7` | Minimum confidence for facts (0.0-1.0) |
| `min_episode_confidence` | float | `0.6` | Minimum confidence for episodes (0.0-1.0) |
| `deduplicate_facts` | boolean | `true` | Enable fact deduplication |
| `deduplicate_episodes` | boolean | `true` | Enable episode deduplication |
| `deduplication_mode` | string | `"per_day"` | Deduplication strategy (`per_day`/`per_session`/`global`) |
| `deduplication_window_days` | integer | `7` | Days to track for per-day deduplication |

---

## Performance Benchmarks

```json
{
  "universal_hooks": {
    "adapters": {
      "opencode": {
        "enabled": true,
        "priority": 1,
        "analyze_after_tools": ["sy.mem.fact.add", "sy.mem.ep.add"],
        "min_message_length": 10,
        "skip_patterns": ["^test$", "^hello$"],
        "extraction_mode": "heuristic"
      }
    },
    "conversation_analyzer": {
      "extraction_mode": "heuristic",
      "min_fact_confidence": 0.7,
      "min_episode_confidence": 0.6,
      "deduplication_mode": "per_day",
      "deduplication_window_days": 7
    }
  }
}
```

## Extraction Mode

- **heuristic**: Fast regex patterns (no LLM, <10ms)
- **llm**: Prompt-based extraction (not yet implemented)
- **hybrid**: Heuristics + LLM (not yet implemented)

## Hooks

- `tool.execute.before`: Analyzes conversation after configured tools
- `tool.execute.after`: Logs tool execution for debugging

## Requirements

- OpenCode CLI
- Synapse MCP server running
- Configured `rag_config.json`

## Troubleshooting

**Plugin not loading**: Check `.opencode/plugins/` directory exists
**Analysis not working**: Check Synapse MCP server is running
**Too many false positives**: Increase `min_fact_confidence` and `min_episode_confidence`

## Testing

1. Start Synapse MCP server: `python -m mcp_server.synapse_server`
2. Start OpenCode with plugins enabled
3. Run Synapse tools (sy.mem.fact.add, sy.mem.ep.add, etc.)
4. Check console for `[Synapse]` log messages

## Usage

### Start OpenCode with Plugin

```bash
opencode --plugins-dir=/home/dietpi/synapse/.opencode/plugins
```

**Expected console output**:
```
[Synapse] Plugin initialized (mode=heuristic, enabled=true, ...)
[Synapse] Plugin: synapse-auto-learning v1.0 loaded
```

### Testing with Synapse Tools

1. **Test: List projects**
    ```
    You: List all Synapse projects
    Expected: OpenCode calls sy.proj.list
    Expected logs: [Synapse] Tool sy.proj.list matched analysis list
    ```

2. **Test: Store a fact**
    ```
    You: Store that API endpoint is https://api.example.com/v1
    Expected: OpenCode calls sy.mem.fact.add
    Expected logs: [Synapse] Processing message (45 chars)
                 [Synapse] Tool sy.mem.fact.add matched analysis list
                 [Synapse] Analyzed conversation: 1 facts, 0 episodes
    Verify: Check /opt/synapse/data/memory.db for stored fact
    ```

3. **Test: Store an episode**
    ```
    You: I found a workaround for the login timeout issue
    Expected: OpenCode calls sy.mem.ep.add
    Expected logs: [Synapse] Tool sy.mem.ep.add matched analysis list
                 [Synapse] Analyzed conversation: 0 facts, 1 episodes
    Verify: Check /opt/synapse/data/memory.db for stored episode
    ```

4. **Test: Search memories**
    ```
    You: Search for "workaround" in episodes
    Expected: OpenCode calls sy.mem.search
    Expected logs: [Synapse] Tool sy.mem.search matched analysis list
                 [Synapse] Analyzed conversation: 0 facts, 1 episodes
    Verify: Results returned with workaround episodes
    ```

### Verifying Stored Memories

```bash
# Query symbolic memory for stored facts
sqlite3 /opt/synapse/data/memory.db "SELECT key, value FROM facts WHERE scope='user' ORDER BY created_at DESC LIMIT 5;"

# Query episodic memory for stored episodes
sqlite3 /opt/synapse/data/memory.db "SELECT title, lesson_type FROM episodes ORDER BY created_at DESC LIMIT 5;"
```

### Troubleshooting

**Plugin doesn't load**:
1. Check `.opencode/plugins/synapse-auto-learning.ts` exists
2. Check TypeScript compilation: `tsc .opencode/plugins/synapse-auto-learning.ts`
3. Check OpenCode logs for errors

**No analysis happens**:
1. Check `[Synapse] Plugin initialized` message appears
2. Check Synapse server is running: `curl http://localhost:8002/health`
3. Check configuration: `configs/rag_config.json` has `universal_hooks.enabled=true`

**Extractions are incorrect**:
1. Check `extraction_mode` in config (heuristic/llm/hybrid)
2. Review test logs: `python3 scripts/test_accuracy.py`
3. Adjust patterns in `core/conversation_analyzer.py` if needed

**Performance issues**:
1. Check execution time logs (should be <50ms)
2. Enable `async_processing: true` (already enabled by default)
3. Reduce `min_message_length` to filter more messages

**Synapse server errors**:
1. Check Synapse server logs: `tail -50 /tmp/synapse_server.log`
2. Check configuration paths: `/app/configs/` vs `/home/dietpi/synapse/configs/`
3. Verify Synapse server is running on expected port (8002)

### Debug Mode

Enable verbose logging by updating `rag_config.json`:
```json
{
  "universal_hooks": {
    "enabled": true,
    "adapters": {
      "opencode": {
        "skip_patterns": [],  // Don't skip anything
        "min_message_length": 1,  // Analyze everything
      }
    }
  }
}
```
