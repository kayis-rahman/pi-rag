# External Integrations

**Analysis Date:** 2026-03-09

## AI/LLM Providers

### GPUHub (Primary)
- **Endpoint:** `https://u425-u70w-e4420dcd.singapore-b.gpuhub.com:8443/v1`
- **Models:** Claude Sonnet 4.x, Haiku 4.x
- **Authentication:** Local API key (configured in `llm-models.yml`)
- **Purpose:** Hosted Anthropic model inference

### Anthropic API (Fallback)
- **Endpoint:** Standard Anthropic API
- **Authentication:** `ANTHROPIC_API_KEY` environment variable
- **Configuration:** Spring AI Anthropic starter
- **Purpose:** Direct Anthropic model access

### OpenAI Compatibility
- **Framework:** Spring AI OpenAI
- **Purpose:** OpenAI-compatible API interface for model routing

## Vector Databases

### Qdrant (Active)
- **Host:** `localhost:6334`
- **Client:** `io.qdrant:client:1.17.0`
- **Purpose:** Semantic memory storage
- **Configuration:** `memory.semantic.qdrant` in `application.yml`
- **Authentication:** API key configured in YAML

### ChromaDB (Previous)
- **Status:** Commented out / deprecated
- **Previous Purpose:** Vector store for RAG system
- **Migration:** Moved to Qdrant

## Caching & Session Storage

### Redis (Active)
- **Host:** `localhost:6379`
- **Purpose:** Episodic memory TTL-based caching
- **Configuration:** `memory.episodic.redis` in `application.yml`
- **TTL:** 1 hour default
- **Client:** Jedis (commented out in dependencies)

### SQLite (Active)
- **Path:** `/var/lib/synapse/knowledge.db`
- **Purpose:** Knowledge graph persistence
- **Configuration:** `memory.knowledge.sqlite` in `application.yml`
- **Driver:** SQLite JDBC (commented out)

### PostgreSQL (Commented)
- **Host:** `localhost:5432`
- **Database:** `synapse_memory`
- **User:** `synapse_user`
- **Purpose:** Primary relational database (not currently active)
- **Connection Pool:** HikariCP (10 max connections)

## gRPC Communication

### gRPC Libraries
```gradle
implementation 'io.grpc:grpc-netty-shaded:1.75.0'
implementation 'io.grpc:grpc-protobuf:1.58.0'
implementation 'io.grpc:grpc-stub:1.58.0'
```

- **Runtime:** Netty (shaded)
- **Protocol Buffers:** Used for service definition
- **Purpose:** Inter-service communication

## Database Migration

- **Location:** `src/main/resources/db/migration/`
- **Purpose:** Flyway/Liquibase migrations (if configured)

## File System Locations

| Path | Purpose |
|------|---------|
| `/var/lib/synapse/knowledge.db` | SQLite knowledge graph |
| `/Users/kayisrahman/Documents/workspace/ideas/synapse/config/llm` | LLM configuration files |
| `/Users/kayisrahman/Documents/workspace/ideas/synapse/config/ngnix` | Nginx configuration |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Anthropic API authentication |
| `QDRANT_API_KEY` | Qdrant vector database authentication |

## Build Tools

- **Gradle 9.3.1** - Dependency management and build automation
- **Spring Boot Maven Plugin** - Application packaging

## Testing Frameworks

- **JUnit Platform** - Test execution
- **Spring Boot Test** - Integration testing support
- **Mockito** - Mocking (via spring-boot-starter-test)
