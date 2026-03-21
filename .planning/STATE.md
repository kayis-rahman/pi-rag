# Synapse Memory Agent - Project State

## Project Reference

**Name**: Synapse Memory Agent
**Core Value**: Users can store, retrieve, and reason about conversation history and knowledge through multiple memory modalities (episodic, semantic, knowledge graph) powered by LLM interactions.
**Current Phase**: 03-session-management
**Next Action**: Plan Phase 3 (Session Management) or continue with Phase 2 execution

---

## Current Position

| Attribute | Value |
|-----------|-------|
| Phase | 03-session-management |
| Plan | Pending |
| Status | Context gathered |
| Progress | `██` 28% |

---

## Performance Metrics

| Metric | Value | Target |
|--------|-------|--------|
| v1 Requirements | 34 total | - |
| Phases | 7 | - |
| Database Layers | PostgreSQL + Redis + SQLite | Enabled |
| LLM Provider | GPUHub (Claude models) | Active |
| Vector DB | Qdrant | Active |

---

## Accumulated Context

### Decisions

| Decision | Rationale | Status |
|----------|-----------|--------|
| Unified memory architecture | Single interface for multiple memory types | Approved |
| Qdrant for vector storage | Modern vector DB with good Java client | Approved |
| GPUHub for Claude hosting | Cost-effective, reliable hosting | Approved |
| Round-robin model selection | Simple load balancing (v1) | Pending enhancement |
| gRPC communication | High-performance inter-service | Pending verification |

### Key Files

| File | Purpose | Location |
|------|---------|----------|
| SynapseApplication.java | Application entry point | `com.synapse` |
| UnifiedMemoryService.java | Memory orchestration | `com.synapse.memory` |
| LlmModelRouter.java | Model selection/routing | `com.synapse.llm.service` |
| DeveloperAssistant.java | AI agent implementation | `com.synapse.agent` |
| TaskContinuityService.java | Multi-step task management | `com.synapse.workflow` |
| SessionManager.java | Conversation tracking | `com.synapse.workflow` |

### Technical Stack

| Category | Technology |
|----------|------------|
| Language | Java 21 |
| Framework | Spring Boot 3.3.5 |
| AI Layer | Spring AI 1.0.0 |
| Build Tool | Gradle 9.3.1 |
| Vector DB | Qdrant 1.17.0 |
| Session DB | Redis |
| Knowledge DB | SQLite |
| Primary DB | PostgreSQL (enabled) |

---

## Sessions

| Date | Topic | Key Outcomes |
|------|-------|--------------|
| 2026-03-09 | Project initialization | Requirements defined, roadmap created |
| 2026-03-21 | Phase 3 context gathering | Session identification via implicit detection (message array patterns), Redis TTL cleanup, episodic memory storage |

---

## Blockers

None at this time.

---

## Notes

- Brownfield project with existing architecture; key components commented out
- Database dependencies need enabling in build.gradle
- UnifiedMemoryService implementation needs completion
- Configuration exists but databases not fully enabled

---

*Last updated: 2026-03-21*
