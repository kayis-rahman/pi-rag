# Synapse Memory Agent - Project State

## Project Reference

**Name**: Synapse Memory Agent
**Core Value**: Users can store, retrieve, and reason about conversation history and knowledge through multiple memory modalities (episodic, semantic, knowledge graph) powered by LLM interactions.
**Current Phase**: Not started
**Next Action**: Awaiting roadmap approval

---

## Current Position

| Attribute | Value |
|-----------|-------|
| Phase | None (awaiting approval) |
| Plan | None (no active phase) |
| Status | Not started |
| Progress | `||||||||||||||||||||||||||||||||||` 0% |

---

## Performance Metrics

| Metric | Value | Target |
|--------|-------|--------|
| v1 Requirements | 34 total | - |
| Phases | 7 | - |
| Database Layers | PostgreSQL + Redis + SQLite | Complete |
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
| Primary DB | PostgreSQL (pending enablement) |

---

## Sessions

| Date | Topic | Key Outcomes |
|------|-------|--------------|
| 2026-03-09 | Project initialization | Requirements defined, roadmap created |

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

*Last updated: 2026-03-09*
