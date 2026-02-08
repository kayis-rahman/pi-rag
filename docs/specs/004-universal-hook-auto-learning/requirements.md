# Requirements: Universal Multi-Agent Hook-Based Auto-Learning System

**Feature ID**: 004-universal-hook-auto-learning
**Version**: 1.0
**Status**: In Progress
**Created**: January 4, 2026

---

## Overview

Implement a universal hook-based auto-learning system that automatically extracts facts and episodes from agent conversations and stores them in RAG memory. The system must support multiple AI coding agents (OpenCode, Claude Code, Gemini, Aider, etc.) through a standard hook interface.

**Key Design Decisions**:
- Extraction mode: **heuristic only** (no LLM, using regex patterns)
- Async processing: Enabled for non-blocking behavior
- Deduplication: Per-day strategy (allow 1 fact/episode per day, reinforce over time)
- Implementation priority: OpenCode adapter first, then other agents

---

## User Stories

### US-1: Automatic Fact Extraction
**As** a developer using an AI coding agent,
**I want** facts (configuration values, decisions, preferences) automatically extracted from my conversations,
**So that** I don't have to manually document project details.

**Acceptance Criteria**:
- Facts extracted using regex patterns (heuristics only)
- Confidence scores assigned to each fact (0.7-0.9 range)
- Duplicate detection per day (allow 1 fact per day)
- Facts stored in symbolic memory (authoritative)

### US-2: Automatic Episode Extraction
**As** a developer using an AI coding agent,
**I want** episodes (workarounds, lessons, mistakes) automatically extracted from my conversations,
**So that** I can learn from past experiences.

**Acceptance Criteria**:
- Episodes extracted using regex patterns (heuristics only)
- Lesson types classified (pattern, mistake, success, failure)
- Confidence scores assigned to each episode (0.6-0.8 range)
- Episodes stored in episodic memory (advisory)

### US-3: OpenCode Integration
**As** a developer using OpenCode,
**I want** an OpenCode plugin that automatically analyzes my conversations,
**So that** I don't have to manually trigger learning.

**Acceptance Criteria**:
- OpenCode plugin uses `tool.execute.before` and `tool.execute.after` hooks
- Calls `core.analyze_conversation` tool after configured tools execute
- Configurable skip patterns and min message length
- Non-blocking (hooks complete in <50ms)
- Graceful degradation (RAG server offline shouldn't crash agent)

### US-4: Non-Blocking Behavior
**As** a developer using an AI coding agent,
**I want** the learning system to never block or slow down the agent,
**So that** my coding workflow remains fast and responsive.

**Acceptance Criteria**:
- All hooks execute asynchronously
- Heuristic extraction completes in <10ms
- No LLM calls (heuristics only)
- Agent continues executing even if RAG server is offline
- Errors logged but never thrown

### US-5: Per-Day Deduplication
**As** a developer using an AI coding agent,
**I want** the system to allow reinforcement of learnings across sessions,
**So that** important facts and episodes aren't lost while avoiding spam.

**Acceptance Criteria**:
- Allow 1 fact per day within 7-day window
- Reinforce learning if added on different days (update timestamp)
- Skip if already added today
- Track timestamps for deduplication

### US-6: Configuration Management
**As** a developer,
**I want** to configure the learning system via `rag_config.json`,
**So that** I can tune behavior for my workflow.

**Acceptance Criteria**:
- `universal_hooks` section in `rag_config.json`
- Per-adapter configuration (enabled, priority, tools to analyze)
- Conversation analyzer configuration (extraction mode, confidence thresholds)
- Performance tuning options (async, timeout)
- All options have sensible defaults

### US-7: RAG MCP Tool
**As** an OpenCode plugin,
**I want** to call a `core.analyze_conversation` tool via MCP protocol,
**So that** I can analyze conversations and store learnings.

**Acceptance Criteria**:
- Tool accepts user_message, agent_response, context
- Tool returns extracted facts and episodes
- Tool stores learnings in RAG memory (auto_store mode)
- Configurable extraction_mode parameter (heuristic/llm/hybrid)
- Parallel storage of facts and episodes

### US-8: Graceful Degradation
**As** a developer,
**I want** the system to work even if components are unavailable,
**So that** I don't experience crashes or blocking behavior.

**Acceptance Criteria**:
- If RAG server offline: Log error, continue without learning
- If config invalid: Use sensible defaults
- If extraction fails: Log error, return empty results
- If storage fails: Log error, don't crash

---

## Non-Functional Requirements

### NFR-1: Performance
- Hook execution time: <50ms (95th percentile)
- Heuristic extraction time: <10ms
- Memory usage: <100MB baseline
- No blocking operations on agent thread

### NFR-2: Reliability
- Uptime: 99%+ (no crashes)
- Error handling: All exceptions caught and logged
- Graceful degradation: System works with partial failures
- Data consistency: No memory leaks, no orphaned data

### NFR-3: Compatibility
- OpenCode SDK: v1.1.4 (TypeScript hooks)
- RAG MCP server: 8 tools (including rag.analyze_conversation)
- Python: 3.8+
- No external LLM API required (heuristics only)

### NFR-4: Security
- No sensitive data logged
- No PII extracted (user email, passwords, etc.)
- Validation of all inputs
- No code injection vulnerabilities

### NFR-5: Maintainability
- Clear separation of concerns (hooks, analyzer, adapters)
- Comprehensive logging for debugging
- Type hints throughout codebase
- Documented interfaces and contracts

### NFR-6: Extensibility
- Easy to add new agent adapters
- Plugin architecture for hooks
- Configurable extraction strategies
- Modular design allows independent component updates

---

## Technical Requirements

### TR-1: Universal Hook Interface
- Python: `UniversalHookInterface` abstract base class (5 methods)
- TypeScript: `UniversalHookInterface` interface (5 optional methods)
- Methods: `pre_tool_use`, `post_tool_use`, `session_start`, `session_end`, `user_prompt_submit`
- Type hints and JSDoc for all methods

### TR-2: Conversation Analyzer
- Class: `ConversationAnalyzer` in `core/conversation_analyzer.py`
- Extraction mode: Heuristic only (regex patterns, no LLM)
- Heuristic patterns: 5 fact patterns, 5 episode patterns
- Confidence scoring: 0.7-0.9 for facts, 0.6-0.8 for episodes
- Per-day deduplication: 7-day window, allow 1 per day
- Async support: `analyze_conversation_async()` method

### TR-3: MCP Server Integration
- New tool: `core.analyze_conversation`
- Parameters: project_id, user_message, agent_response, context, auto_store, return_only
- Returns: facts_stored, episodes_stored, facts, episodes
- Parallel storage: Use `asyncio.gather()` for facts and episodes
- Config: Load conversation_analyzer settings from rag_config.json

### TR-4: OpenCode Plugin
- File: `.opencode/plugins/synapse-auto-learning.ts`
- Hooks: `tool.execute.before`, `tool.execute.after`
- Configuration: enabled, priority, analyze_after_tools, min_message_length, skip_patterns
- RAG tool call: `client.tools.call("rag.analyze_conversation", args)`
- Logging: Detailed console.log with [Synapse] prefix
- Error handling: Try-catch all errors, log but never throw

### TR-5: Configuration Schema
- Section: `universal_hooks` in `rag_config.json`
- Subsections: adapters, conversation_analyzer, performance
- Defaults: extraction_mode="heuristic", use_llm=false, min_fact_confidence=0.7
- Validation: JSON schema validation on load

### TR-6: Testing
- Unit tests: pytest for ConversationAnalyzer, deduplication, confidence scoring
- Integration tests: OpenCode plugin → RAG tool → storage
- Performance tests: Hook execution time <50ms, heuristic extraction <10ms
- Acceptance tests: US-1 to US-8 validated

---

## Out of Scope

- LLM-based extraction (deferred until chat model available)
- Claude Code adapter (deferred to Phase 3.2)
- Gemini, Aider, other adapters (deferred to Phase 3.3)
- REST API adapter (deferred)
- Advanced deduplication strategies (semantic similarity)
- Reinforcement learning or feedback loops
- UI/dashboard for viewing learnings
- Export/import of memories

---

## Dependencies

- **Existing**: RAG MCP server (7 tools)
- **Existing**: RAG memory system (symbolic, episodic, semantic)
- **Existing**: OpenCode SDK @opencode-ai/plugin@1.1.4
- **Existing**: Python asyncio for async processing
- **Existing**: regex module for heuristic patterns
- **New**: ConversationAnalyzer class
- **New**: OpenCode plugin file
- **New**: rag.analyze_conversation MCP tool

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| OpenCode SDK changes breaking hooks | Medium | High | Follow SDK examples closely, version-lock to 1.1.4 |
| Heuristic extraction misses learnings | High | Medium | Monitor precision, add more patterns iteratively |
| Deduplication too aggressive | Medium | Medium | Make window configurable, allow tuning |
| RAG server downtime | Low | High | Graceful degradation, cache in memory if needed |
| Performance overhead | Low | Medium | Async processing, timeouts, benchmarks |
| Regex patterns false positives | Medium | Low | Test with real conversations, adjust patterns |

---

## Success Metrics

- **Performance**: 95% of hooks complete in <50ms
- **Extraction Quality**: >75% fact precision, >70% episode precision
- **Reliability**: 99%+ uptime, <1% error rate
- **Coverage**: Support OpenCode (Phase 1), other agents (Phase 3)
- **User Satisfaction**: <5 complaints about blocking behavior
- **Storage**: Facts/episodes stored correctly with proper deduplication

---

## Questions & Open Items

1. **LLM Extraction**: Deferred until chat model is available in rag_config.json
2. **Embedding Model**: Currently not used for extraction (heuristics only)
3. **Other Adapters**: Deferred until OpenCode adapter tested and approved
4. **Advanced Features**: Deferred (semantic deduplication, feedback loops)

---

**Status**: Ready for implementation (Phase 1: Foundation complete, Phase 3.1: OpenCode adapter)
