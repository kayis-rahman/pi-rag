# Phase 2: Memory Core - Research

**Researched:** 2026-03-21
**Domain:** Multi-modal memory systems (episodic, semantic, knowledge graph) with Spring Data
**Confidence:** HIGH

## Summary

Phase 2 requires implementing a unified memory service orchestrating three distinct memory modalities: episodic (Redis-backed conversation history with TTL), semantic (Qdrant vector search, deferred until Phase 4), and knowledge graph (SQLite triple store). The architecture is driven by Spring Data Redis patterns for episodic storage, Spring Data JPA for PostgreSQL persistence, and direct JDBC for SQLite graph operations.

Key finding: The project has foundational infrastructure in place (dependencies, configs, database connections). Memory service classes are currently commented out and require uncommenting and completion. The episodic memory pattern (Redis ZSET for time-based queries + HSET for episode data + PostgreSQL fallback) is well-founded and widely supported in Spring Data Redis 3.2.x. Semantic memory deferral to Phase 4 is correct since embeddings are unavailable. Knowledge graph implementation can use SQLite's native relational model with indexed triple queries.

**Primary recommendation:** Uncomment and implement the three memory service classes following Spring Data patterns already established in RedisConfig and PostgresConfig. Use StreamMessageListenerContainer for async indexing via Redis Streams.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. **Episodic Memory on Redis** with HSET for data, ZSET for time-based queries, TTL-based cleanup
2. **Semantic Memory on Qdrant** with placeholder embeddings until Phase 4
3. **Knowledge Graph on SQLite** as triple store with edges (source_type, source_id, relation, target_type, target_id)
4. **Unified Facade Pattern** with UnifiedMemoryService orchestrating all three
5. **Async Indexing** via Redis Streams + background batch jobs (scheduled, not immediate)
6. **LLM-based Embeddings** deferred to Phase 4; Phase 2 uses mock/placeholder

### Claude's Discretion
- Configuration structure (will be defined in this phase)
- Transaction boundaries across multiple databases (recommend: per-modality commits with saga pattern consideration)
- Batch indexing frequency and sizing (recommend: nightly for codebase, on-demand for conversations)
- Circuit breaker/retry patterns for cross-database operations (recommend: per-modality with separate policies)

### Deferred Ideas (OUT OF SCOPE)
- Vector embedding generation
- Knowledge graph traversal algorithms
- Memory analytics/dashboards
- Memory versioning/snapshots
- Distributed multi-node memory
- Memory encryption
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MEM-01 | User conversation stored as episode with automatic indexing | Redis HSET + ZSET pattern established; PostgreSQL fallback via JPA; queuing via Redis Streams |
| MEM-02 | Recent episodes retrieved within last N interactions | ZSET reverseRange by score (timestamp); Redis operations.opsForZSet().reverseRange() provides O(log N) performance |
| MEM-03 | Codebase indexed and searchable via semantic memory | Placeholder implementation with mock embeddings; Qdrant client 1.17.0 available; deferred vector search to Phase 4 |
| MEM-04 | Query similar code with configurable similarity threshold | Qdrant threshold 0.7 configurable; Phase 4 adds actual embedding similarity |
| MEM-05 | Relationship edges stored in knowledge graph | SQLite relational schema with indexed source/target; triple (source, relation, target) pattern |
| MEM-06 | Traverse knowledge graph for related concepts | SQLite recursive queries or multi-hop traversal; indexed composite keys on (source_type, source_id) |
| MEM-07 | Unified memory service single interface | Spring @Service with three autowired modality services; facade pattern verified |
| MEM-08 | Async indexing without blocking requests | Redis Streams StreamMessageListenerContainer; @Scheduled for batch jobs; ThreadPoolTaskExecutor |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Spring Data Redis | 3.2.0 | Episodic memory (ZSET, HSET, TTL) | Official Spring abstraction; Jedis integration included |
| Spring Data JPA | 3.3.5 (transitively) | Episode persistence fallback to PostgreSQL | ORM for long-term storage; Hibernate dialect proven |
| Redis (Jedis client) | 4.4.6 | Direct Redis connection pooling | Project already configured; synchronous blocking model suitable |
| SQLite JDBC | 3.42.0.0 | Knowledge graph triple store | Lightweight embedded SQL; no server required; project-configured |
| Qdrant Java client | 1.17.0 | Semantic memory placeholder (Phase 4 integration point) | Official client; gRPC-based; supports metadata filtering |
| Spring Framework Async | 7.x (transitively) | @Async + @EnableAsync for background indexing | Thread pool management via @Scheduled + StreamMessageListenerContainer |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jakarta Persistence API | 3.x (transitive) | JPA annotations for episodes (@Entity, @Table) | Standard Spring Data pattern for schema mapping |
| Spring Framework Scheduling | 7.x (transitive) | @Scheduled for batch indexing jobs | Simpler than Quartz for v1; no persistence needed |
| Redis Streams (via Spring Data) | 3.2.0 | Async queue for indexing work | Persistent queue with consumer groups; automatic ACK |
| HikariCP | 5.x (transitive) | Connection pooling for PostgreSQL | Already configured in PostgresConfig; production-grade |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Spring Data Redis | Raw Jedis | Would lose Spring's serialization, exception translation, and template lifecycle |
| Redis Streams | RabbitMQ/Kafka | Would add external service complexity; Streams are native to Redis, already present |
| @Scheduled | Quartz Scheduler | Quartz adds complexity for v1; @Scheduled sufficient without persistence/clustering |
| PostgreSQL for episodes | Redis-only | Would eliminate fallback for cache miss; PostgreSQL provides durable audit trail |
| SQLite triples | Neo4j/RDF triple store | SQLite is file-based, no extra service; Phase 5 can upgrade if needed |

**Installation:**
```bash
# All dependencies already in build.gradle; verify:
# - implementation 'org.springframework.data:spring-data-redis:3.2.0'
# - implementation 'redis.clients:jedis:4.4.6'
# - implementation 'org.xerial:sqlite-jdbc:3.42.0.0'
# - implementation 'io.qdrant:client:1.17.0'
```

---

## Architecture Patterns

### Recommended Project Structure

```
src/main/java/com/synapse/memory/
├── UnifiedMemoryService.java           # Facade orchestrating three modalities
├── MemoryService.java                  # Interface defining contract
├── Episode.java                        # Episode data class (already present)
├── episodic/
│   └── EpisodicMemoryService.java      # Redis HSET/ZSET operations
├── semantic/
│   └── SemanticMemoryService.java      # Qdrant placeholder (Phase 4: embeddings)
├── knowledgegraph/
│   └── KnowledgeGraphService.java      # SQLite triple store queries
├── config/
│   ├── MemoryConfigurationProperties.java  # @ConfigurationProperties for all 3 modalities
│   └── MemoryConfigurationService.java     # Programmatic config access
└── indexing/
    └── AsyncIndexingService.java       # Redis Streams consumer + @Scheduled batch

src/main/resources/
└── application.yml                     # Memory config (already present)

src/test/java/com/synapse/memory/
├── UnifiedMemoryServiceTest.java
├── episodic/EpisodicMemoryServiceTest.java
├── semantic/SemanticMemoryServiceTest.java
└── knowledgegraph/KnowledgeGraphServiceTest.java
```

### Pattern 1: Episodic Memory with Redis ZSET + HSET

**What:** Store episodes in Redis with dual indexing (hash for content, sorted set for time-based queries) and PostgreSQL backup for durability.

**When to use:** All conversation episodes; TTL-based expiration; need for "recent N" retrieval in milliseconds.

**Example:**
```java
// Source: Spring Data Redis official docs
@Service
public class EpisodicMemoryService {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Autowired
    private DataSource dataSource;  // PostgreSQL fallback

    public void storeEpisode(Episode episode) {
        String episodeKey = "episode:" + episode.getId();

        // Store in PostgreSQL (durable)
        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                 "INSERT INTO episodes (id, session_id, content, timestamp, expires_at) " +
                 "VALUES (?, ?, ?, ?, ?)" )) {
            stmt.setString(1, episode.getId());
            stmt.setString(2, episode.getSessionId());
            stmt.setString(3, episode.getContent());
            stmt.setTimestamp(4, new Timestamp(episode.getTimestamp().getTime()));
            // Calculate expiration: now + configured TTL days
            LocalDateTime expiresAt = LocalDateTime.now()
                .plusDays(memoryConfig.getEpisodic().getRedis().getTtl() / 86400);
            stmt.setTimestamp(5, Timestamp.valueOf(expiresAt));
            stmt.executeUpdate();
        }

        // Store in Redis with TTL
        HashOperations<String, String, Object> hashOps = redisTemplate.opsForHash();
        hashOps.put(episodeKey, "sessionId", episode.getSessionId());
        hashOps.put(episodeKey, "content", episode.getContent());
        hashOps.put(episodeKey, "timestamp", episode.getTimestamp().toString());

        // Add to ZSET for time-based queries (score = timestamp)
        ZSetOperations<String, String> zsetOps = redisTemplate.opsForZSet();
        zsetOps.add("episodes:recent", episodeKey,
            episode.getTimestamp().getTime());

        // Set TTL on hash
        int ttlSeconds = memoryConfig.getEpisodic().getRedis().getTtl();
        redisTemplate.expire(episodeKey, Duration.ofSeconds(ttlSeconds));
    }

    public List<Episode> getRecentEpisodes(String sessionId, int limit) {
        List<Episode> episodes = new ArrayList<>();
        ZSetOperations<String, String> zsetOps = redisTemplate.opsForZSet();
        HashOperations<String, String, Object> hashOps = redisTemplate.opsForHash();

        // Get most recent episode keys from ZSET (reverse order = newest first)
        Set<String> recentKeys = zsetOps.reverseRange("episodes:recent", 0, limit - 1);

        for (String key : recentKeys) {
            // Check if hash still exists in cache
            Map<Object, Object> data = hashOps.getAll(key);
            if (!data.isEmpty()) {
                Episode episode = mapHashToEpisode(key, data);
                if (sessionId.equals(episode.getSessionId())) {
                    episodes.add(episode);
                }
            }
        }

        // If Redis miss, fetch from PostgreSQL
        if (episodes.isEmpty()) {
            String sql = "SELECT id, session_id, content, timestamp FROM episodes " +
                        "WHERE session_id = ? ORDER BY timestamp DESC LIMIT ?";
            try (Connection conn = dataSource.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, sessionId);
                stmt.setInt(2, limit);
                try (ResultSet rs = stmt.executeQuery()) {
                    while (rs.next()) {
                        episodes.add(new Episode(
                            rs.getString("id"),
                            rs.getString("session_id"),
                            rs.getString("content"),
                            rs.getTimestamp("timestamp").toLocalDateTime()
                        ));
                    }
                }
            }
        }

        return episodes;
    }

    private Episode mapHashToEpisode(String key, Map<Object, Object> data) {
        return new Episode(
            key.replace("episode:", ""),
            (String) data.get("sessionId"),
            (String) data.get("content"),
            LocalDateTime.parse((String) data.get("timestamp"))
        );
    }
}
```

### Pattern 2: Knowledge Graph with SQLite Triple Store

**What:** Store relationship edges (source_type, source_id, relation, target_type, target_id) in SQLite with composite indexes for fast multi-hop queries.

**When to use:** Relationship queries; concept linkage; path finding (future phases).

**Example:**
```java
// Source: Spring Boot SQLite integration pattern
@Service
public class KnowledgeGraphService {

    @Value("${memory.knowledge.sqlite.path:/var/lib/synapse/knowledge.db}")
    private String sqlitePath;

    private Supplier<Connection> connectionSupplier;  // From SQLiteConfig bean

    @PostConstruct
    public void initializeSchema() {
        try (Connection conn = connectionSupplier.get();
             Statement stmt = conn.createStatement()) {

            // Create triple store table
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS graph_edges (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    source_type TEXT NOT NULL,
                    source_id TEXT NOT NULL,
                    relation TEXT NOT NULL,
                    target_type TEXT NOT NULL,
                    target_id TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    metadata TEXT
                )
                """);

            // Composite indexes for efficient querying
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_source " +
                "ON graph_edges(source_type, source_id)");
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_target " +
                "ON graph_edges(target_type, target_id)");
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_relation " +
                "ON graph_edges(relation)");

        } catch (SQLException e) {
            throw new RuntimeException("Failed to initialize knowledge graph schema", e);
        }
    }

    public void addRelationship(String sourceId, String relation, String targetId) {
        String sql = """
            INSERT INTO graph_edges (source_type, source_id, relation, target_type, target_id)
            VALUES (?, ?, ?, ?, ?)
            """;

        try (Connection conn = connectionSupplier.get();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            // Infer types from ID format or explicit parameter
            String sourceType = inferType(sourceId);
            String targetType = inferType(targetId);

            stmt.setString(1, sourceType);
            stmt.setString(2, sourceId);
            stmt.setString(3, relation);
            stmt.setString(4, targetType);
            stmt.setString(5, targetId);

            stmt.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Failed to store relationship", e);
        }
    }

    public List<String> findConnectedConcepts(String entityId) {
        List<String> concepts = new ArrayList<>();

        String sql = """
            SELECT DISTINCT target_id FROM graph_edges
            WHERE source_id = ?
            UNION
            SELECT DISTINCT source_id FROM graph_edges
            WHERE target_id = ?
            """;

        try (Connection conn = connectionSupplier.get();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, entityId);
            stmt.setString(2, entityId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    concepts.add(rs.getString(1));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Failed to query graph", e);
        }

        return concepts;
    }

    private String inferType(String id) {
        // Placeholder: in real implementation, parse ID prefix or accept explicit type
        if (id.startsWith("file:")) return "file";
        if (id.startsWith("concept:")) return "concept";
        return "generic";
    }
}
```

### Pattern 3: Async Indexing with Redis Streams + @Scheduled

**What:** Queue indexing work to Redis Streams; consume asynchronously with StreamMessageListenerContainer; supplement with scheduled batch jobs for bulk codebase indexing.

**When to use:** On-demand conversation indexing (fast path); nightly codebase re-indexing (batch path); prevent indexing from blocking request handlers.

**Example:**
```java
// Source: Spring Data Redis Streams official docs
@Service
@EnableAsync
public class AsyncIndexingService {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Autowired
    private EpisodicMemoryService episodicMemoryService;

    private StreamMessageListenerContainer<String, MapRecord<String, String, String>> container;

    @PostConstruct
    public void initializeStreamListener() {
        StreamMessageListenerContainerOptions<String, MapRecord<String, String, String>> options =
            StreamMessageListenerContainerOptions.builder()
                .pollTimeout(Duration.ofMillis(100))
                .build();

        this.container = StreamMessageListenerContainer.create(
            redisTemplate.getConnectionFactory(),
            options
        );

        // Subscribe to indexing queue stream
        container.receive(
            StreamOffset.fromStart("memory:index:queue"),
            (message) -> {
                handleIndexingMessage(message);
                // Auto-ack after successful processing
                redisTemplate.opsForStream()
                    .acknowledge("indexing-group", message);
            }
        );

        container.start();
    }

    public void queueForIndexing(Episode episode) {
        // Queue episode for async indexing (non-blocking)
        StringRecord record = StreamRecords.string(
            Map.of(
                "episodeId", episode.getId(),
                "content", episode.getContent(),
                "timestamp", episode.getTimestamp().toString()
            )
        ).withStreamKey("memory:index:queue");

        redisTemplate.opsForStream().add(record);
    }

    private void handleIndexingMessage(MapRecord<String, String, String> message) {
        String episodeId = message.getValue().get("episodeId");
        String content = message.getValue().get("content");

        try {
            // Index to semantic memory (Phase 4: actual embeddings)
            indexToSemantic(episodeId, content);

            // Extract and index to knowledge graph
            indexToKnowledgeGraph(episodeId, content);
        } catch (Exception e) {
            // Log and dead-letter if indexing fails
            logFailedIndexing(episodeId, e);
        }
    }

    @Scheduled(cron = "0 2 * * *")  // Daily at 2 AM
    @Async
    public void batchIndexCodebase() {
        // Scan codebase and batch-index to semantic memory
        // This is deferred pending Phase 4 embeddings
        logger.info("Batch indexing codebase");
    }

    private void indexToSemantic(String episodeId, String content) {
        // Phase 4: will call embeddings endpoint and store in Qdrant
    }

    private void indexToKnowledgeGraph(String episodeId, String content) {
        // Extract concepts and relationships from content
        // Add edges to SQLite triple store
    }
}

@Configuration
@EnableAsync
public class AsyncExecutorConfig {

    @Bean(name = "taskExecutor")
    public TaskExecutor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("synapse-async-");
        executor.initialize();
        return executor;
    }
}
```

### Pattern 4: Unified Memory Service Facade

**What:** Single service coordinating episodic, semantic, and knowledge graph operations with transaction boundaries.

**When to use:** All memory operations go through this service; downstream code never calls modality services directly.

**Example:**
```java
// Source: Facade pattern + Spring @Service
@Service
@Transactional  // Applies to JPA operations only; Redis/SQLite handled per-method
public class UnifiedMemoryService implements MemoryService {

    @Autowired
    private EpisodicMemoryService episodicMemoryService;

    @Autowired
    private SemanticMemoryService semanticMemoryService;

    @Autowired
    private KnowledgeGraphService knowledgeGraphService;

    @Autowired
    private AsyncIndexingService asyncIndexingService;

    /**
     * Store a new episode and queue for async indexing.
     * Fast path: returns immediately after Redis store.
     * Background: queued for semantic/graph indexing.
     */
    public void storeEpisode(Episode episode) {
        // Synchronous: store to episodic memory (low latency)
        episodicMemoryService.storeEpisode(episode);

        // Asynchronous: queue for downstream indexing
        asyncIndexingService.queueForIndexing(episode);
    }

    /**
     * Retrieve recent episodes from cache or database.
     */
    public List<Episode> retrieveRecent(String sessionId, int limit) {
        return episodicMemoryService.getRecentEpisodes(sessionId, limit);
    }

    /**
     * Search semantic memory (Phase 4: actual embeddings).
     * For now: return empty with placeholder behavior.
     */
    public List<SemanticMatch> searchSemantic(String query, int limit) {
        return semanticMemoryService.search(query, limit);
    }

    /**
     * Query knowledge graph for related concepts.
     */
    public List<String> findRelated(String concept) {
        return knowledgeGraphService.findConnectedConcepts(concept);
    }

    /**
     * Add a relationship to knowledge graph.
     */
    public void addRelationship(String source, String relation, String target) {
        knowledgeGraphService.addRelationship(source, relation, target);
    }
}
```

### Anti-Patterns to Avoid
- **Blocking on indexing:** Never wait for Qdrant/SQLite writes in request handlers; use async queue instead
- **Mixing modality concerns:** Don't call EpisodicMemoryService directly from business logic; always use UnifiedMemoryService
- **Redis-only episodes:** Don't skip PostgreSQL fallback; cache misses will lose data
- **No TTL on Redis keys:** Always set expire() to prevent unbounded memory growth
- **Synchronous Qdrant searches:** Phase 4 will add async patterns; Phase 2 placeholder is fine
- **N+1 queries in graph traversal:** Use composite indexes; avoid fetching all edges then filtering in Java

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Redis connection pooling | Custom pool management | Spring Data Redis (uses Jedis internally) | Framework handles lifecycle, exception translation, serialization |
| ZSET time-based queries | Custom timestamp indexing | RedisTemplate.opsForZSet().reverseRange() | O(log N) native Redis operation vs O(N) in-memory sort |
| PostgreSQL ORM | SQL string concatenation | Spring Data JPA + Hibernate | Prevents SQL injection, handles NULL, date conversion, connection lifecycle |
| SQLite schema creation | Manual SQL string creation | @PostConstruct + Statement.execute() | Automated, testable, version-controlled schema |
| Async task execution | Manual Thread/Runnable | @Async + TaskExecutor bean | Thread pool management, exception handling, monitoring built-in |
| Redis message queue | Publish-Subscribe (Pub/Sub) | Redis Streams | Streams are persistent, support consumer groups, replay capability |
| Transaction coordination | Manual commit/rollback | Spring @Transactional (JPA) + per-modality commits | Framework handles savepoints, rollback, conflict detection |

**Key insight:** Spring Data abstractions exist because implementing correct pooling, serialization, exception handling, and lifecycle management is deceptively complex. Cross-database transactions (eventual consistency) require careful design—Phase 2 uses per-modality isolation (each writes independently); Phase 5+ can add saga patterns if needed.

---

## Common Pitfalls

### Pitfall 1: Unbounded Redis Memory (Missing TTL)
**What goes wrong:** Episodes accumulate indefinitely in Redis; memory fills up; Qdrant eviction policy kills random vectors; application crashes.

**Why it happens:** RedisTemplate doesn't auto-expire; developer must call .expire() after every write. Easy to forget on one operation.

**How to avoid:**
1. Always call `redisTemplate.expire(key, Duration.ofSeconds(ttl))` immediately after write
2. Use `redisTemplate.opsForValue().setIfPresent(key, value, Duration.ofSeconds(ttl))` for atomic set-with-ttl
3. Add unit test: verify TTL is set on all operations
4. Monitor Redis with `redis-cli --stat` and alert on memory usage

**Warning signs:**
- `redis-cli DBSIZE` grows unbounded
- `redis-cli INFO memory` shows memory_used_human > max_memory
- LRU eviction errors in logs

### Pitfall 2: PostgreSQL Fallback Corruption
**What goes wrong:** Redis cache expires, app tries to load from PostgreSQL, finds stale or missing data. User sees "episode lost."

**Why it happens:** Episodic memory writes to Redis (fast) then PostgreSQL (slow); network hiccup causes PostgreSQL write to fail silently; cache TTL expires; data gone.

**How to avoid:**
1. **Order matters:** Write to PostgreSQL first, then Redis (fail-fast if durability fails)
2. Wrap in transaction: `@Transactional` for PostgreSQL, manual try-catch for Redis
3. Log both writes: `logger.info("Stored episode {} to PostgreSQL and Redis", episodeId)`
4. Monitor: Alert if PostgreSQL write fails but Redis write succeeds

**Warning signs:**
- Logs show "Stored to Redis" but no "Stored to PostgreSQL" message
- SQL constraint violations on retry
- Timestamp mismatches between Redis and PostgreSQL

### Pitfall 3: Redis Streams Consumer Group Not Initialized
**What goes wrong:** Code tries to read from consumer group "indexing-group" but group doesn't exist; first message blocks indefinitely or throws error.

**Why it happens:** StreamMessageListenerContainer requires pre-existing consumer group created via `XGROUP CREATE`. Easy to forget in setup.

**How to avoid:**
1. Initialize consumer group in @PostConstruct or migration script:
   ```java
   redisTemplate.opsForStream().createGroup("memory:index:queue", "indexing-group");
   ```
2. Wrap in try-catch (group may already exist):
   ```java
   try {
       redisTemplate.opsForStream().createGroup("memory:index:queue", "indexing-group");
   } catch (Exception e) {
       // Group exists, continue
   }
   ```
3. Test: Verify container starts and processes messages

**Warning signs:**
- Container starts but never receives messages
- Logs: "ERR NOGROUP No such consumer group"

### Pitfall 4: SQLite Connection Deadlock
**What goes wrong:** Two threads write to same SQLite file; second thread blocks indefinitely; application hangs.

**Why it happens:** SQLite uses file-level locking; only one writer at a time. Unlike PostgreSQL's MVCC, SQLite serializes writes.

**How to avoid:**
1. Use connection supplier from SQLiteConfig (already handles DriverManager)
2. Keep transactions short: write and immediately close
3. Set busy timeout: `connection.createStatement().execute("PRAGMA busy_timeout = 5000");`
4. Batch writes when possible (reduce contention)
5. Monitor: Log transaction time; alert if > 1 second

**Warning signs:**
- `PRAGMA busy_timeout exceeded` errors
- Logs: "database is locked"
- Slow episodic memory operations during peak indexing

### Pitfall 5: Qdrant Client Not Thread-Safe (Phase 4)
**What goes wrong:** Multiple threads call QdrantClient.search() concurrently; gRPC channel closes unexpectedly; thread safety issues emerge in production.

**Why it happens:** Java gRPC clients require careful lifecycle management; shared client across threads can cause closure races.

**How to avoid:**
1. Create QdrantClient as singleton bean (Spring manages lifecycle)
2. Use thread-safe operations; never close client mid-request
3. Phase 4: Wrap Qdrant calls in CircuitBreaker (already in play via Resilience4j)
4. Test: Load test with concurrent searches

**Warning signs:**
- Occasional random "channel closed" errors in high load
- Phase 4 : Search latency variance (some calls fast, some slow)

### Pitfall 6: Serialization Mismatch Between Redis & PostgreSQL
**What goes wrong:** Episode stored in Redis as JSON, retrieved from PostgreSQL as HashMap, comparison fails; subtle data loss.

**Why it happens:** RedisTemplate uses GenericJacksonJsonRedisSerializer by default; PostgreSQL JDBC returns different types; no automatic bridge.

**How to avoid:**
1. Define canonical Episode class with consistent JSON schema
2. Serialize consistently: Use same ObjectMapper for Redis and application code
3. Test round-trip: Store in Redis, retrieve, verify equals original
4. PostgreSQL: Cast to Episode in SQL or in Java mapper (explicit)

**Warning signs:**
- Logs: "Cannot deserialize value of type Episode"
- Redis: `redis-cli GET episode:abc` returns unreadable binary
- Cache hit returns Episode, database hit returns different type

---

## Code Examples

Verified patterns from official sources:

### Spring Data Redis ZSET Time-Based Queries
```java
// Source: Spring Data Redis official docs + RedisConfig.java (project)
@Autowired
private RedisTemplate<String, Object> redisTemplate;

// Add episode with timestamp as score
public void indexByTime(String episodeId, long timestamp) {
    ZSetOperations<String, String> zsetOps = redisTemplate.opsForZSet();
    zsetOps.add("episodes:recent", episodeId, timestamp);
}

// Retrieve last 10 episodes (most recent first)
public Set<String> getRecentEpisodeIds(int limit) {
    ZSetOperations<String, String> zsetOps = redisTemplate.opsForZSet();
    return zsetOps.reverseRange("episodes:recent", 0, limit - 1);
}

// Query by time range (e.g., last 24 hours)
public Set<String> getEpisodesSince(long sinceTimestamp) {
    ZSetOperations<String, String> zsetOps = redisTemplate.opsForZSet();
    return zsetOps.rangeByScore("episodes:recent", sinceTimestamp, System.currentTimeMillis());
}
```

### Spring Data Redis HSET Episode Storage
```java
// Source: RedisConfig.java (project) + Spring Data Redis tutorials
@Autowired
private RedisTemplate<String, Object> redisTemplate;

public void storeEpisodeHash(Episode episode) {
    String key = "episode:" + episode.getId();
    HashOperations<String, String, Object> hashOps = redisTemplate.opsForHash();

    hashOps.put(key, "sessionId", episode.getSessionId());
    hashOps.put(key, "content", episode.getContent());
    hashOps.put(key, "timestamp", episode.getTimestamp().toString());
    hashOps.put(key, "ttlDays", episode.getTtlDays());

    redisTemplate.expire(key, Duration.ofSeconds(
        episode.getTtlDays() * 86400));
}

public Episode retrieveEpisodeHash(String episodeId) {
    String key = "episode:" + episodeId;
    HashOperations<String, String, Object> hashOps = redisTemplate.opsForHash();
    Map<Object, Object> data = hashOps.getAll(key);

    if (data.isEmpty()) return null;

    Episode episode = new Episode(
        episodeId,
        (String) data.get("sessionId"),
        (String) data.get("content")
    );
    episode.setTimestamp(LocalDateTime.parse((String) data.get("timestamp")));
    return episode;
}
```

### SQLite Triple Store Query
```java
// Source: SQLiteConfig.java (project) + Spring Boot SQLite patterns
private Supplier<Connection> connectionSupplier;  // Injected from SQLiteConfig

public List<String> queryRelationships(String sourceId, String relation) {
    List<String> targets = new ArrayList<>();

    String sql = "SELECT target_id FROM graph_edges " +
                 "WHERE source_id = ? AND relation = ?";

    try (Connection conn = connectionSupplier.get();
         PreparedStatement stmt = conn.prepareStatement(sql)) {

        stmt.setString(1, sourceId);
        stmt.setString(2, relation);

        try (ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                targets.add(rs.getString("target_id"));
            }
        }
    } catch (SQLException e) {
        throw new RuntimeException("Query failed", e);
    }

    return targets;
}
```

### Redis Streams Async Indexing
```java
// Source: Spring Data Redis Streams docs
@Service
public class IndexingQueueService {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    public void enqueueForIndexing(String episodeId, String content) {
        StringRecord record = StreamRecords.string(Map.of(
            "episodeId", episodeId,
            "content", content,
            "timestamp", Instant.now().toString()
        )).withStreamKey("memory:index:queue");

        redisTemplate.opsForStream().add(record);
    }
}

@Service
public class IndexingConsumer implements StreamListener<String, MapRecord<String, String, String>> {

    @Override
    public void onMessage(MapRecord<String, String, String> message) {
        String episodeId = message.getValue().get("episodeId");
        String content = message.getValue().get("content");

        // Process indexing
        logger.info("Indexing episode: {}", episodeId);
        // ... semantic + graph indexing
    }
}
```

### Spring @Async Batch Indexing Job
```java
// Source: Spring Framework @Async documentation
@Service
@EnableAsync
public class CodebaseIndexingService {

    @Autowired
    private SemanticMemoryService semanticMemoryService;

    // Nightly codebase indexing (background thread)
    @Scheduled(cron = "0 2 * * *")  // 2 AM daily
    @Async("taskExecutor")
    public void indexCodebase() {
        logger.info("Starting nightly codebase indexing");

        // Phase 4: Call embeddings endpoint
        // For Phase 2: Placeholder
        long startTime = System.currentTimeMillis();

        // Mock: simulate indexing 100 files
        for (int i = 0; i < 100; i++) {
            String filePath = "/src/main/java/File" + i + ".java";
            String content = "public class File" + i + " {}";

            // Phase 4: semanticMemoryService.index(filePath, content);
        }

        long elapsed = System.currentTimeMillis() - startTime;
        logger.info("Nightly indexing completed in {} ms", elapsed);
    }
}

@Configuration
@EnableAsync
public class AsyncConfig {

    @Bean(name = "taskExecutor")
    public TaskExecutor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);        // Minimum threads
        executor.setMaxPoolSize(10);        // Maximum threads
        executor.setQueueCapacity(100);     // Queue size
        executor.setThreadNamePrefix("synapse-indexing-");
        executor.initialize();
        return executor;
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual JDBC + Jedis | Spring Data Redis + Spring Data JPA | Spring 2.0+ (2018) | Standardized error handling, serialization, lifecycle |
| Pub/Sub only | Redis Streams | Redis 5.0+ (2018) | Persistent queues, consumer groups, message replay |
| Scheduled cron jobs | @Scheduled + @Async | Spring Framework 3.1+ (2011) | No Quartz needed for simple jobs; cleaner annotation model |
| Singleton Qdrant client | QdrantVectorStore bean | Spring AI 1.0 (2024) | Framework manages lifecycle, integrates with Spring ecosystem |
| Manual thread pools | TaskExecutor beans | Spring Framework 2.0+ (2010) | Auto-configured via spring.task.execution properties |
| SQL string building | PreparedStatement + JPA Criteria | Java 8+ | Type-safe, prevents injection, easier testing |

**Deprecated/outdated:**
- **org.springframework.data:spring-data-redis < 2.5:** Old JedisConnectionFactory API; use current 3.2.0
- **Raw JDBC without DataSource:** Don't pool connections manually; HikariCP in Spring Boot is standard
- **Redis Pub/Sub for persistence:** Use Streams instead; Pub/Sub is fire-and-forget, no replay
- **Singleton @Service without proper initialization:** Always use @PostConstruct for resource setup (e.g., StreamMessageListenerContainer)

---

## Open Questions

1. **Transaction Consistency Across Three Databases**
   - What we know: Phase 2 uses per-modality isolation (episodic writes to Redis+PostgreSQL independently; semantic deferred; graph writes to SQLite)
   - What's unclear: If PostgreSQL write fails after Redis succeeds, should we retry or accept eventual consistency? Current design accepts eventual consistency
   - Recommendation: For v1, accept—log failures and repair during Phase 5 if needed. Document this assumption in architecture decision record.

2. **Semantic Memory Placeholder Behavior (Phase 4 Dependency)**
   - What we know: Embeddings unavailable in Phase 2; Qdrant client available; Phase 4 adds actual embedding generation
   - What's unclear: Should Phase 2 pre-create Qdrant collection with schema, or defer entirely to Phase 4?
   - Recommendation: Create collection structure in Phase 2 (no data), add embeddings in Phase 4. Allows Phase 3 code to reference memory service without errors.

3. **Batch Indexing Frequency and Size**
   - What we know: Nightly codebase indexing suggested; on-demand conversation indexing via Streams
   - What's unclear: Optimal batch size for Qdrant bulk upsert? Frequency if codebase changes daily?
   - Recommendation: Start with 50-file batches, nightly 2 AM. Monitor Phase 4 and adjust based on embedding latency.

4. **Knowledge Graph Traversal Algorithm**
   - What we know: SQLite can execute recursive queries (WITH RECURSIVE); current implementation is 1-hop only
   - What's unclear: Should Phase 2 implement N-hop traversal, or defer to Phase 5 when graph becomes critical?
   - Recommendation: Defer to Phase 5. Phase 2 scope: implement 1-hop (direct neighbors only). Phase 5: add recursive traversal.

5. **Qdrant Initialization and Schema (Phase 4 Blocker)**
   - What we know: Qdrant collection name is configurable; vector dimension unknown until embeddings chosen
   - What's unclear: Who creates the collection? Spring AI auto-initialization or manual?
   - Recommendation: Phase 2 documents expected collection schema (name: "semantic_memory", auto-create enabled). Phase 4 implements actual client initialization.

---

## Validation Architecture

Test framework: **JUnit 5 + Mockito** (already in use; see existing test files)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | JUnit 5.x (via spring-boot-starter-test) + Mockito 4.x |
| Config file | app/build.gradle (test task configured, no separate config needed) |
| Quick run command | `gradle test -k "UnifiedMemoryService" --no-daemon` |
| Full suite command | `gradle test --no-daemon` (runs all unit + integration tests) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MEM-01 | Episode stored to Redis HSET and PostgreSQL | integration | `gradle test -k "storeEpisode" --no-daemon` | ✅ UnifiedMemoryServiceTest.java (commented) |
| MEM-02 | Recent episodes retrieved via ZSET reverseRange | unit | `gradle test -k "getRecentEpisodes" --no-daemon` | ✅ EpisodicMemoryServiceTest.java (commented) |
| MEM-03 | Semantic memory placeholder returns empty list | unit | `gradle test -k "searchSemantic" --no-daemon` | ✅ SemanticMemoryServiceTest.java (commented) |
| MEM-04 | Similarity threshold configurable in properties | unit | `gradle test -k "SemanticMemory" --no-daemon` | ✅ MemoryConfigurationPropertiesTest.java |
| MEM-05 | Knowledge graph edges inserted with composite key | integration | `gradle test -k "addRelationship" --no-daemon` | ✅ KnowledgeGraphServiceTest.java (commented) |
| MEM-06 | Related concepts queried via 1-hop SQL | unit | `gradle test -k "findRelatedConcepts" --no-daemon` | ✅ KnowledgeGraphServiceTest.java (commented) |
| MEM-07 | UnifiedMemoryService delegates to three modalities | unit | `gradle test -k "UnifiedMemory" --no-daemon` | ✅ UnifiedMemoryServiceTest.java (commented) |
| MEM-08 | Async indexing queued to Redis Streams | integration | `gradle test -k "AsyncIndexing" --no-daemon` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `gradle test -k "Memory" --no-daemon` (< 30s, unit tests only)
- **Per wave merge:** `gradle test --no-daemon` (full suite, includes integration tests with testcontainers)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `app/src/test/java/com/synapse/memory/AsyncIndexingServiceTest.java` — covers MEM-08 (Redis Streams consumer group integration test)
- [ ] `app/src/test/resources/application-test.yml` — Spring Boot test profile with embedded Redis, SQLite :memory:, Qdrant test container
- [ ] Framework install: Testcontainers dependency for Redis/Qdrant integration tests — already available in Spring Boot starter-test, may need explicit Redis testcontainer

*(Tests for MEM-01 through MEM-07 exist but are commented out; Wave 0 work includes uncommenting and verifying they pass. MEM-08 requires new test class for Streams consumer.)*

---

## Sources

### Primary (HIGH confidence)
- **Spring Data Redis 3.2.0 API docs** — ZSET operations, HSET, TTL patterns, RedisTemplate serialization
  - Verified: https://docs.spring.io/spring-data/redis/reference/redis/template.html
  - Topics: opsForZSet(), opsForHash(), expire(), serialization strategies

- **Spring Data Redis Streams docs** — StreamMessageListenerContainer, StreamReceiver, consumer groups
  - Verified: https://docs.spring.io/spring-data/redis/reference/redis/redis-streams.html
  - Topics: Async message consumption, manual/auto ACK, ReadOffset patterns

- **Spring Boot 3.3.5 reference** — @EnableAsync, @Scheduled, TaskExecutor auto-configuration
  - Verified: https://docs.spring.io/spring-boot/reference/features/task-execution-and-scheduling.html
  - Topics: thread pool sizing, spring.task.execution properties

- **Spring AI 1.0 Qdrant Integration** — QdrantVectorStore, collection initialization, Spring integration
  - Verified: https://docs.spring.io/spring-ai/reference/api/vectordbs/qdrant.html
  - Topics: Spring-managed bean lifecycle, configuration via properties

- **Project configuration files** — RedisConfig.java, PostgresConfig.java, SQLiteConfig.java, MemoryConfigurationProperties.java
  - Verified: In-codebase inspection
  - Topics: Jedis connection factory, HikariCP setup, JDBC DataSource patterns

### Secondary (MEDIUM confidence)
- **Baeldung Spring Data Redis tutorials** — ZSET/HSET patterns, serialization best practices
  - Source: https://www.baeldung.com/spring-data-redis-tutorial
  - Verified: Cross-referenced with official Spring docs

- **Spring Boot SQLite integration guides** — JDBC connection management, schema initialization
  - Source: https://www.baeldung.com/spring-boot-sqlite
  - Verified: Consistent with project's SQLiteConfig pattern

- **Redis Streams documentation** — Persistence guarantees, consumer group semantics
  - Source: https://redis.io/docs/latest/develop/data-types/streams/
  - Verified: Cross-referenced with Spring Data Streams wrapper

- **Spring Framework @Async best practices** — Thread safety, exception handling, pool configuration
  - Source: https://www.baeldung.com/spring-async
  - Verified: Consistent with official Spring scheduling docs

### Tertiary (LOW confidence - marked for validation)
- **Simple-graph SQLite triple store implementation** — Recursive query patterns for graph traversal
  - Source: https://github.com/dpapathanasiou/simple-graph
  - Status: Reference implementation only; Phase 2 uses simpler 1-hop queries; Phase 5 can adopt advanced patterns

- **WebSearch results on batch sizing and frequency** — Optimal Qdrant batch parameters for Spring Boot
  - Sources: Multiple Medium articles on Spring Batch optimization
  - Status: Heuristic starting points only; must validate against actual Qdrant performance in Phase 4

---

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — All libraries explicitly in build.gradle with versions pinned; Redis/PostgreSQL/SQLite configuration already in place
- Architecture: **HIGH** — Facade pattern, ZSET/HSET operations, Streams consumer groups all covered by official Spring Data docs
- Pitfalls: **MEDIUM-HIGH** — Common Redis/JDBC issues well-documented; Phase 4 (Qdrant thread safety) has limited public guidance but best practices from gRPC ecosystem apply
- Async indexing: **MEDIUM** — @Scheduled and @Async patterns standard; Redis Streams integration examples less common but official docs comprehensive

**Research date:** 2026-03-21
**Valid until:** 2026-04-20 (30 days; extends if Spring/Redis versions unchanged; shorten to 7 days if Phase 4 adds embeddings before review)

---

## Next Steps for Planning

1. **Uncomment the three memory service classes** (EpisodicMemoryService, SemanticMemoryService, KnowledgeGraphService) and complete implementations following patterns in this research
2. **Create AsyncIndexingService** with Redis Streams consumer group + @Scheduled batch job
3. **Implement UnifiedMemoryService** facade with transaction boundaries per research Pattern 4
4. **Enable @EnableAsync and configure TaskExecutor** bean in a new AsyncExecutorConfig
5. **Uncomment and verify test classes** — ensure they compile and pass
6. **Create application-test.yml** with embedded Redis and SQLite :memory: for unit tests
7. **Validate configuration** — run app, verify all three databases connect, memory service available
