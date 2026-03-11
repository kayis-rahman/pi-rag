# Synapse Memory Agent

## What This Is

A Java/Spring Boot AI memory agent with unified episodic, semantic, and knowledge graph storage. Uses GPUHub-hosted Claude models via Spring AI and Qdrant for vector-based semantic memory.

## Core Value

Users can store, retrieve, and reason about conversation history and knowledge through multiple memory modalities (episodic, semantic, knowledge graph) powered by LLM interactions.

## Requirements

### Validated

- ✓ Spring Boot 3.3.5 application with Java 21 — existing
- ✓ LLM model routing with GPUHub-hosted Claude models — existing
- ✓ Qdrant vector database integration for semantic memory — existing
- ✓ Episodic memory with Redis TTL-based caching — existing
- ✓ SQLite knowledge graph storage — existing
- ✓ Round-robin model selection strategy — existing
- ✓ Embedding configuration system (development/staging/production) — existing
- ✓ gRPC communication setup — existing
- ✓ JUnit 5 testing framework — existing

### Active

- [ ] **MEM-01**: Complete `UnifiedMemoryService` implementation (currently commented out)
- [ ] **MEM-02**: Implement `MemoryService` interface with all three memory types
- [ ] **MEM-03**: Add database connection pooling (PostgreSQL/HikariCP)
- [ ] **MEM-04**: Enable Redis client (Jedis) for episodic memory
- [ ] **MEM-05**: Enable SQLite JDBC driver for knowledge graph
- [ ] **MEM-06**: Implement session continuity across conversations
- [ ] **MEM-07**: Add model selection strategies beyond round-robin
- [ ] **MEM-08**: Enable SSL certificate verification for LLM API calls
- [ ] **MEM-09**: Create Docker deployment configuration
- [ ] **MEM-10**: Add comprehensive integration tests

### Out of Scope

- Mobile app — Web-first, mobile later
- Real-time chat — Not core to memory value
- OAuth login — Email/password sufficient for v1 (if auth needed)
- Multiple LLM providers beyond GPUHub/Anthropic — Focus on Claude integration

## Context

This is a brownfield project with an existing Java/Spring Boot codebase. The architecture is in place but several key components are commented out or incomplete:

- `UnifiedMemoryService` - Entire implementation commented out (lines 1-52)
- Database dependencies commented out in `build.gradle`
- Configuration exists but databases not fully enabled
- gRPC dependencies added but unclear usage

The codebase follows clean architecture with clear separation between:
- Agent layer (`com.synapse.agent`)
- AI services (`com.synapse.ai`)
- Memory layer (`com.synapse.memory`)
- LLM infrastructure (`com.synapse.llm`)
- Workflow layer (`com.synapse.workflow`)

## Constraints

- **Tech Stack**: Java 21, Spring Boot 3.3.5, Spring AI 1.0.0 — already established
- **LLM Provider**: GPUHub for Claude models — existing configuration
- **Vector DB**: Qdrant — active, must maintain compatibility
- **Build Tool**: Gradle 9.3.1 — established build system

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Unified memory architecture | Single interface for multiple memory types | ✓ Good |
| Qdrant for vector storage | Modern vector DB with good Java client | ✓ Good |
| GPUHub for Claude hosting | Cost-effective, reliable hosting | ✓ Good |
| Round-robin model selection | Simple load balancing | ⚠️ Revisit — consider weighted/performance-based |
| gRPC communication | High-performance inter-service | — Pending verification |

---
*Last updated: 2026-03-09 after codebase mapping and project initialization*
