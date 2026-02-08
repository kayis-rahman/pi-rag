# Automatic Learning System - Requirements

**Feature ID**: 002-auto-learning
**Created**: January 4, 2026
**Status**: [In Progress]

---

## Executive Summary

**Objective**: Implement aggressive automatic learning system that constantly adds to RAG memories after every MCP tool operation, code change, and task completion.

**Current State**: Memory addition is EXPLICIT (only when user says "remember").
**Target State**: Memory addition is AUTOMATIC (after every operation).

---

## User Stories

### US-1: Automatic Episode Storage
**As a developer using synapse**, I want episodes to be automatically stored after every task completion, so that opencode learns from its own experiences without manual intervention.

**Acceptance Criteria**:
- [ ] Episode is stored immediately after a multi-step operation completes
- [ ] Episode contains the abstracted strategy learned from the task
- [ ] Episode is stored with 0.7-0.85 confidence (not 1.0 for auto-generated)
- [ ] No user intervention required for episode creation

### US-2: Automatic Fact Extraction from Code Changes
**As a developer using synapse**, I want facts to be automatically extracted from code file ingestion and modifications, so that technical decisions are captured without manual fact entry.

**Acceptance Criteria**:
- [ ] Facts are extracted when code files are ingested via rag.ingest_file
- [ ] Facts capture: new dependencies, framework usage, architecture patterns
- [ ] Facts are stored with 1.0 confidence (technical facts from code)
- [ ] No manual fact entry required for code-related information

### US-3: Pattern Detection & Episode Creation
**As a developer using synapse**, I want episodes to be created when patterns are detected across operations (repeated failures, successful strategies), so that opencode can avoid mistakes and reuse successes.

**Acceptance Criteria**:
- [ ] Episodes are created when the same operation fails 2+ times
- [ ] Episodes are created when the same operation succeeds 3+ times
- [ ] Episodes contain the pattern that was detected
- [ ] Episodes contain the strategy to apply going forward

### US-4: Configuration Control
**As a developer using synapse**, I want to control automatic learning behavior via configuration, so that I can enable/disable or adjust aggressiveness based on my needs.

**Acceptance Criteria**:
- [ ] Configuration flag enables/disables automatic learning
- [ ] Three modes available: aggressive, moderate, minimal
- [ ] Can disable tracking for: tasks, code changes, operations individually
- [ ] Configuration is read from rag_config.json

### US-5: Manual Override
**As a developer using synapse**, I want to be able to disable automatic learning for specific operations via parameter, so that one-off tasks don't pollute memory.

**Acceptance Criteria**:
- [ ] Can pass `auto_learn=false` parameter to any MCP tool
- [ ] When disabled, no automatic episode/fact is added
- [ ] Manual add_fact/add_episode still works when auto_learn=false

---

## Functional Requirements

### FR-1: Operation Tracking
- The system MUST track all MCP tool calls with: tool name, arguments, result, timestamp, duration
- Tracking MUST be in-memory buffer (not persisted to disk)
- Buffer MUST be analyzed after each operation for pattern detection

### FR-2: Task Completion Detection
- The system MUST detect task completion from operation sequences
- Task completion patterns: multi-step operations, successful file ingestions, bug fix sequences
- Detection MUST trigger episode extraction

### FR-3: Episode Auto-Extraction
- Episodes MUST be extracted using LLM from task completion data
- Episode extraction MUST NOT require user input
- Episodes MUST be stored IMMEDIATELY (no batching)
- Episode storage MUST bypass manual add_episode tool

### FR-4: Fact Auto-Extraction from Code
- Facts MUST be extracted when code files are ingested
- Extraction patterns: imports, frameworks, architecture, APIs
- Facts MUST be stored with 1.0 confidence (authoritative from code)

### FR-5: Pattern Detection
- System MUST detect: repeated failures (2+ times), repeated successes (3+ times)
- Pattern detection MUST trigger episode creation
- Episode must contain: pattern description, strategy to apply

### FR-6: Configuration Support
- Configuration MUST be loaded from rag_config.json
- Configuration MUST support: enable/disable, mode (aggressive/moderate/minimal), granular toggles
- Default configuration: enabled=true, mode=aggressive

### FR-7: Manual Override
- All MCP tools MUST accept optional `auto_learn` parameter
- When `auto_learn=false`, no automatic memory addition occurs
- Manual add_fact/add_episode always works regardless of auto_learn

---

## Non-Functional Requirements

### NFR-1: Performance
- Episode extraction MUST complete within 2 seconds per task
- Fact extraction from code MUST complete within 1 second per file
- Operation tracking overhead MUST be < 50ms per tool call

### NFR-2: Storage
- Episodes MUST be stored immediately (no batching)
- Episodes MUST be deduplicated (check for similar existing episodes)
- Facts MUST be deduplicated (check for identical keys in same scope)

### NFR-3: Reliability
- System MUST NOT crash if LLM extraction fails
- Failed extraction MUST be logged but not block operations
- Configuration errors MUST have sensible defaults

### NFR-4: Observability
- All automatic learning operations MUST be logged
- Logs MUST include: operation type, extraction status, storage success/failure
- Metrics MUST track: episodes created, facts created, extraction failures

---

## Data Schema

### Auto-Learning Configuration (rag_config.json)
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

### Operation Tracking Schema
```json
{
  "tool_name": "rag.search",
  "project_id": "synapse",
  "arguments": {"query": "test"},
  "result": "success",
  "timestamp": "2026-01-04T19:00:00Z",
  "duration_ms": 123
}
```

### Auto-Generated Episode Schema
```json
{
  "situation": "User needed to find auth implementation",
  "action": "Searched semantic memory and located auth module",
  "outcome": "Found correct implementation in auth.py",
  "lesson": "Always search semantic memory before reading files",
  "confidence": 0.75,
  "lesson_type": "success",
  "auto_generated": true
}
```

---

## Dependencies

### System Dependencies
- `rag_config.json`: Configuration file (already exists)
- `core/episodic_store.py`: Episode storage (already exists)
- `core/memory_store.py`: Fact storage (already exists)
- `mcp_server/rag_server.py`: MCP server (modify to add tracking)

### New Dependencies
- `core/auto_learning_tracker.py`: New module for operation tracking and learning extraction
- `core/learning_extractor.py`: New module for LLM-based learning extraction

---

## Risk Assessment

### High Priority Risks

**Risk 1: Too Much Memory Bloat**
- **Description**: Auto-generating episodes for every operation could flood episodic memory
- **Impact**: Reduced retrieval quality, slower searches
- **Mitigation**: 
  - Confidence threshold (0.6-0.85) filters low-value episodes
  - Deduplication prevents repeated episodes
  - Configuration modes allow disabling (minimal mode)

**Risk 2: LLM Extraction Failures**
- **Description**: LLM may fail to extract episodes reliably
- **Impact**: Missed learning opportunities
- **Mitigation**:
  - Fallback to rule-based extraction if LLM fails
  - Error logging for failed extractions
  - Retry mechanism with exponential backoff

**Risk 3: Incorrect Fact Extraction**
- **Description**: Code analysis may extract wrong/confusing facts
- **Impact**: Polluted symbolic memory with incorrect information
- **Mitigation**:
  - Conservative extraction patterns (only high-confidence facts)
  - User can manually remove incorrect facts
  - Fact deduplication prevents repeated wrong facts

### Medium Priority Risks

**Risk 4: Performance Overhead**
- **Description**: Tracking every operation adds latency
- **Impact**: Slower MCP tool responses
- **Mitigation**:
  - In-memory buffer (no disk I/O)
  - Batch analysis after operation completes
  - Async operations don't block main flow

**Risk 5: Configuration Complexity**
- **Description**: Multiple configuration options confuse users
- **Impact**: Misconfiguration leads to unexpected behavior
- **Mitigation**:
  - Sensible defaults (aggressive mode enabled)
  - Clear documentation
  - Example configurations

---

## Success Metrics

### Quantitative Metrics
- Episodes per day: Target 5-10 (current: 0-2)
- Facts per day: Target 5-15 (current: 0-5)
- Pattern detection accuracy: Target 80%+ (detect real patterns, not noise)
- Episode quality score: Target 0.75+ average (from user feedback)

### Qualitative Metrics
- User perception: "opencode is constantly learning from my work"
- Retrieval quality: Memory still relevant and useful
- No manual intervention: User never needs to manually add episodes/facts for routine work

---

## Definition of Done

- [ ] All user stories implemented
- [ ] All functional requirements met
- [ ] All non-functional requirements met
- [ ] Configuration schema implemented and documented
- [ ] Risks mitigated (confidences, deduplication, error handling)
- [ ] Success metrics met (episodes per day, facts per day)
- [ ] Documentation updated (AGENTS.md, README.md)
- [ ] Tests created (unit tests for auto-learning modules)
- [ ] User acceptance: User confirms opencode is "constantly adding to RAG memories"

---

**Next Step**: Create Technical Plan (`plan.md`) with architecture, implementation details, and migration strategy.
