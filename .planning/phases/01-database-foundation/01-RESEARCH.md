# Phase 1: Database Foundation - Research

**Gathered:** 2026-03-20
**Status:** Complete
**Phase Requirements:** DB-01, DB-02, DB-03, DB-04, DB-05

---

## Current State Analysis

### Build Configuration (`app/build.gradle`)

**Currently Active Dependencies:**
- Spring Boot 3.3.5
- Spring Boot WebFlux (reactive)
- Spring Boot Actuator + Prometheus metrics
- Qdrant client 1.17.0 (vector DB)
- Spring AI OpenAI + Anthropic
- LangChain4j (OpenAI + Anthropic)
- Resilience4j circuit breaker

**Commented Out Dependencies (need enabling):**
```gradle
//    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
//    implementation 'redis.clients:jedis:4.4.6'
//    implementation 'org.springframework.data:spring-data-redis:3.2.0'
//    implementation 'org.xerial:sqlite-jdbc:3.42.0.0'
//    implementation 'org.springframework.boot:spring-boot-starter-jdbc'
```

### Application Configuration (`application.yml`)

**Database Auto-configuration Disabled:**
```yaml
spring:
  autoconfigure:
    exclude:
      - org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
      - org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration
      - org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration
```

**Commented Database Configuration:**
```yaml
# datasource:
#   url: jdbc:postgresql://localhost:5432/synapse_memory
#   username: synapse_user
#   password: synapse_password
#   driver-class-name: org.postgresql.Driver
#   hikari:
#     maximum-pool-size: 10
#     connection-timeout: 30000
#
# redis:
#   host: localhost
#   port: 6379
#   timeout: 2000ms
#   lettuce:
#     pool:
#       max-active: 20
#       max-idle: 10
#       min-idle: 5
```

**Active Memory Configuration:**
```yaml
memory:
  episodic:
    redis:
      host: localhost
      port: 6379
      ttl: 3600  # 1 hour
  semantic:
    qdrant:
      host: localhost
      port: 6334
      api-key: ""
  knowledge:
    sqlite:
      path: /var/lib/synapse/knowledge.db
```

### Existing Service Classes

**`UnifiedMemoryService.java`** - Entire implementation commented out (lines 1-52)
- Injects `EpisodicMemoryService`, `SemanticMemoryService`, `KnowledgeGraphService`
- Implements `MemoryService` interface
- Provides unified API for all memory operations

**Memory Service Structure:**
- `com.synapse.memory.episodic.EpisodicMemoryService` - Redis-based session storage
- `com.synapse.memory.semantic.SemanticMemoryService` - Qdrant vector search
- `com.synapse.memory.knowledgegraph.KnowledgeGraphService` - SQLite graph storage

---

## Implementation Requirements

### DB-01: PostgreSQL with HikariCP Pooling

**What's Needed:**
1. Enable `spring-boot-starter-data-jpa` dependency
2. Enable `spring-boot-starter-jdbc` for HikariCP
3. Add PostgreSQL driver dependency
4. Configure `application.yml` with PostgreSQL datasource
5. Create `DataSource` configuration bean
6. Enable JPA auto-configuration

**Technical Details:**
- HikariCP default pool: 10 connections, 30s timeout (matches requirements)
- PostgreSQL driver: `org.postgresql:postgresql:42.7.3` or later
- Connection URL: `jdbc:postgresql://host:port/database`

### DB-02: Redis Client (Jedis) for Episodic Memory

**What's Needed:**
1. Enable `jedis` dependency
2. Enable `spring-data-redis` dependency
3. Configure Redis connection in `application.yml`
4. Create `RedisConfig` with JedisConnectionFactory
5. Update `EpisodicMemoryService` to use Redis template

**Technical Details:**
- Jedis vs Lettuce: Project currently has Lettuce commented out
- Jedis 4.4.6 compatible with Spring Data Redis 3.2.0
- TTL support via `RedisTemplate#expire()`

### DB-03: SQLite JDBC Driver for Knowledge Graph

**What's Needed:**
1. Enable `sqlite-jdbc` dependency
2. Update `KnowledgeGraphService` to use JDBC directly (no JPA needed)
3. Configure SQLite path in `application.yml`
4. Initialize database schema on startup

**Technical Details:**
- SQLite JDBC 3.42.0.0
- No connection pooling needed for SQLite (single-file DB)
- Schema initialization via Flyway or manual SQL scripts

### DB-04: Connection Pool Configuration

**PostgreSQL HikariCP Settings:**
```properties
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000
```

**Redis Pool Settings (if using Lettuce):**
```yaml
spring.redis.lettuce.pool.max-active=20
spring.redis.lettuce.pool.max-idle=10
spring.redis.lettuce.pool.min-idle=5
```

### DB-05: Database Migration Scripts

**Options:**
1. **Flyway** - Automated schema versioning
2. **Liquibase** - Alternative to Flyway
3. **Manual SQL scripts** - Simple approach for v1

**Recommendation:** Use Flyway for PostgreSQL, manual scripts for SQLite

---

## Validation Architecture

### Health Check Implementation

**Spring Boot Actuator + Custom Health Indicator:**
```java
@Component
public class DatabaseHealthIndicator implements HealthIndicator {
    private final DataSource dataSource;
    private final RedisConnectionFactory redisFactory;
    private final Connection sqliteConnection;

    @Override
    public Health health() {
        // Test PostgreSQL connection
        try (Connection conn = dataSource.getConnection()) {
            if (conn.isValid(5)) return Health.up().build();
        } catch (Exception e) {
            return Health.down(e).build();
        }
    }
}
```

### Success Criteria Verification

1. **PostgreSQL:** Application starts with valid connection, can execute `SELECT 1`
2. **Redis:** Can `SET` and `GET` values with TTL
3. **SQLite:** Can create table and insert/select data
4. **Migrations:** Schema updates apply automatically on startup
5. **Health Endpoint:** `/actuator/health` shows all databases healthy

---

## Technical Decisions

| Decision | Option | Selected | Rationale |
|----------|--------|----------|-----------|
| JPA vs JDBC | JPA (Spring Data) | JPA | Simplifies PostgreSQL operations |
| Redis Client | Jedis vs Lettuce | Jedis | Already in dependencies, matches requirements |
| SQLite Access | JDBC vs ORM | JDBC | Lightweight, no ORM overhead needed |
| Migrations | Flyway vs Liquibase vs Manual | Flyway | Simple, widely-used, good Spring Boot integration |
| Connection Pool | HikariCP default | Custom | Requirements specify 10 connections, 30s timeout |

---

## Risks and Considerations

1. **Reactive vs Imperative:** Project uses WebFlux (reactive), but Spring Data JPA is imperative
   - Solution: Use R2DBC for reactive PostgreSQL, or accept mixed paradigm

2. **Port Configuration:** SQLite path is `/var/lib/synapse/knowledge.db` (Linux path)
   - Solution: Make configurable via environment variable

3. **Development vs Production:** Current config uses localhost for all services
   - Solution: Create environment-specific profiles (dev, staging, prod)

4. **Docker Deployment:** Phase 9 roadmap item mentions Docker config
   - Solution: Design config to work with Docker networking

---

## Next Steps

1. Enable dependencies in `build.gradle`
2. Configure PostgreSQL datasource with HikariCP
3. Configure Redis with Jedis
4. Configure SQLite path
5. Create health indicators for all three databases
6. Add Flyway migration scripts (if needed)
7. Test application startup with all databases

---

*Research completed: 2026-03-20*
