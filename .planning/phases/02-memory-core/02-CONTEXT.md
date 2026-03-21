# Phase 2: Memory Core - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

---

## Phase Boundary

Implement unified memory service that stores and retrieves memories across three modalities: episodic (conversation history), semantic (vector-searchable code/concepts), and knowledge graph (relationship edges). Provide single interface for all memory operations used by downstream services.

---

## Implementation Decisions

### Memory Architecture

**Episodic Memory (Redis)**
- Store conversation episodes with timestamp and metadata
- Redis HSET for episode data, ZSET for time-based queries
- TTL-based automatic cleanup (configurable retention)
- Fast retrieval for "recent N conversations"

**Semantic Memory (Qdrant)**
- Vector embeddings for code, documentation, conversations
- Similarity search with configurable threshold (default 0.7)
- Metadata storage for source tracking (file path, line numbers, timestamp)
- Batch indexing for performance

**Knowledge Graph (SQLite)**
- Triple store: (source, relation, target)
- Edge types: file_contains, references, depends_on, documents, mentions
- Query by entity to find all connected concepts
- Path queries for multi-hop relationships

### Unified Memory Service Interface

**Single Facade Pattern**
- `UnifiedMemoryService` orchestrates all three modalities
- Methods: `storeEpisode()`, `retrieveRecent()`, `searchSemantic()`, `queryGraph()`
- Background threads for indexing without blocking requests
- Transaction boundaries across writes to multiple databases

### Embedding Strategy

**LLM-based Embeddings (Phase 4 dependency)**
- Defer actual embedding generation to Phase 4 (LLM Integration)
- For now: Use mock embeddings or placeholder implementation
- Interface designed to accept external embeddings
- Will integrate with Claude embeddings endpoint in Phase 4

### Indexing Timing

**Async Indexing**
- On-demand indexing for user conversations (synchronous for low latency)
- Background batch indexing for codebase (nightly or scheduled)
- Queue-based system (Redis Streams) for deferred work
- Configurable batch size and frequency

---

## Specific Ideas

### Episodic Memory Data Structure

```java
@Entity
@Table(name = "episodes")
public class Episode {
    @Id
    private String episodeId;
    private String userId;
    private String conversationId;
    private LocalDateTime timestamp;
    @Column(columnDefinition = "TEXT")
    private String content;  // Serialized conversation
    @ElementCollection
    private Map<String, String> metadata;  // Tags, keywords, etc.
    private LocalDateTime expiresAt;
}
```

**Redis Operations:**
```java
// Store episode
redisTemplate.opsForHash().put("episode:" + id, "data", episode);
redisTemplate.opsForZSet().add("episodes:recent", id, System.currentTimeMillis());
redisTemplate.expire("episode:" + id, Duration.ofDays(30));

// Retrieve recent
Set<String> recent = redisTemplate.opsForZSet()
    .reverseRange("episodes:recent", 0, 9);  // Last 10
```

### Semantic Memory Structure (Qdrant)

```java
public class SemanticMemory {
    private String id;
    private String content;
    private float[] embedding;  // Placeholder for now
    private Map<String, String> metadata;  // source, timestamp, etc.
    private double similarity;  // Set after search
}
```

**Search Implementation:**
```java
// Defer to Phase 4 when embeddings available
public List<SemanticMemory> searchSemantic(String query, double threshold) {
    // For now: return all with placeholder similarity
    // Phase 4: Convert query to embedding, run vector search
    return new ArrayList<>();
}
```

### Knowledge Graph Schema (SQLite)

```sql
CREATE TABLE IF NOT EXISTS graph_edges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_type TEXT NOT NULL,  -- file, concept, conversation
    source_id TEXT NOT NULL,
    relation TEXT NOT NULL,      -- contains, references, documents, etc.
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT  -- JSON
);

CREATE INDEX idx_source ON graph_edges(source_type, source_id);
CREATE INDEX idx_target ON graph_edges(target_type, target_id);
```

### Unified Memory Service Interface

```java
@Service
public class UnifiedMemoryService {

    // Episodic operations
    public void storeEpisode(Episode episode) {
        episodeRepository.save(episode);
        redisEpisodeStore.save(episode);
    }

    public List<Episode> retrieveRecent(int limit) {
        return redisEpisodeStore.getRecent(limit);
    }

    // Semantic operations (Phase 4)
    public List<SemanticMemory> searchSemantic(String query, int limit) {
        // Deferred until embeddings available
        return new ArrayList<>();
    }

    // Knowledge graph operations
    public void addRelationship(String sourceId, String relation, String targetId) {
        knowledgeGraphDao.addEdge(sourceId, relation, targetId);
    }

    public List<String> queryGraph(String entityId) {
        return knowledgeGraphDao.findConnected(entityId);
    }
}
```

### Configuration Structure

```yaml
memory:
  episodic:
    retention-days: 30
    batch-size: 100

  semantic:
    enabled: false  # Phase 4
    similarity-threshold: 0.7
    index-batch-size: 50

  knowledge-graph:
    sqlite-path: ${SQLITE_PATH:/var/lib/synapse/knowledge.db}
    vacuum-enabled: true
    vacuum-interval-days: 7

  unified:
    async-indexing: true
    index-queue-name: memory:index:queue
```

### Dependency Changes

**Enable in build.gradle:**
```gradle
// Already enabled from Phase 1:
// - Spring Data JPA (PostgreSQL)
// - Spring Data Redis (episodic)
// - SQLite JDBC (knowledge graph)

// May add for Phase 2:
// implementation 'io.qdrant:qdrant-client:1.10.0'  // Defer to Phase 4
```

---

## Deferred Ideas

- Vector embedding generation (Phase 4: LLM Integration)
- Semantic search implementation (Phase 4: LLM Integration)
- Knowledge graph traversal algorithms (Phase 5 or 6)
- Memory cleanup policies beyond simple TTL (Phase 7)
- Memory analytics/usage dashboards (Phase 7)
- Distributed memory across multiple nodes (beyond v1)
- Encryption of stored memories (Phase 7 security)
- Memory versioning/snapshots (beyond v1)

---

*Phase: 02-memory-core*
*Context gathered: 2026-03-21*
