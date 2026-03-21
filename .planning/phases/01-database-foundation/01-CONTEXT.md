# Phase 1: Database Foundation - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

---

## Phase Boundary

Enable all three database layers (PostgreSQL, Redis, SQLite) with connection pooling and health checks, making them ready for use by memory services.

---

## Implementation Decisions

### Database Technology Selection

**PostgreSQL + JPA**
- Use Spring Data JPA for PostgreSQL operations
- Leverage existing entity/repository patterns
- HikariCP connection pooling (10 connections, 30s timeout)

**Redis + Jedis**
- Enable Jedis client for episodic memory
- TTL-based caching for session data
- Spring Data Redis template for operations

**SQLite + JDBC**
- Direct JDBC access for knowledge graph
- No ORM overhead needed
- Single-file database, no pooling required

### Migration Strategy

**Flyway for PostgreSQL**
- Automated schema versioning
- Spring Boot integration
- Version-controlled migration scripts

**Manual for SQLite**
- Simple schema initialization on startup
- No versioning complexity for v1

### Reactive vs Imperative

**Mixed Paradigm Acceptance**
- Project uses WebFlux (reactive)
- Spring Data JPA is imperative
- Accept mixed paradigm for Phase 1
- Consider R2DBC for future phases

---

## Specific Ideas

### Configuration Structure

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/synapse_memory
    username: synapse_user
    password: ${DB_PASSWORD:default_password}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000

  redis:
    host: localhost
    port: 6379
    password: ${REDIS_PASSWORD:}
    timeout: 2000ms
    jedis:
      pool:
        max-active: 20
        max-idle: 10
        min-idle: 5

memory:
  knowledge:
    sqlite:
      path: ${SQLITE_PATH:/var/lib/synapse/knowledge.db}
```

### Health Check Implementation

```java
@Component
public class MultiDatabaseHealthIndicator implements HealthIndicator {
    private final DataSource postgresDataSource;
    private final RedisConnectionFactory redisFactory;
    private final String sqlitePath;

    @Override
    public Health health() {
        Map<String, Object> details = new HashMap<>();

        // PostgreSQL health
        try (Connection conn = postgresDataSource.getConnection()) {
            if (conn.isValid(5)) {
                details.put("postgres", Health.up().build());
            }
        } catch (Exception e) {
            details.put("postgres", Health.down(e).build());
        }

        // Redis health
        try {
            redisFactory.getConnection().getConnection();
            details.put("redis", Health.up().build());
        } catch (Exception e) {
            details.put("redis", Health.down(e).build());
        }

        // SQLite health
        try (Connection conn = DriverManager.getConnection("jdbc:sqlite:" + sqlitePath)) {
            if (conn.isValid(5)) {
                details.put("sqlite", Health.up().build());
            }
        } catch (Exception e) {
            details.put("sqlite", Health.down(e).build());
        }

        return Health.up().withDetails(details).build();
    }
}
```

### Dependency Changes

**Enable in build.gradle:**
```gradle
implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
implementation 'org.springframework.boot:spring-boot-starter-jdbc'
implementation 'org.postgresql:postgresql:42.7.3'
implementation 'redis.clients:jedis:4.4.6'
implementation 'org.springframework.data:spring-data-redis:3.2.0'
implementation 'org.xerial:sqlite-jdbc:3.42.0.0'
implementation 'org.flywaydb:flyway-core:10.5.0'
```

**Remove from autoconfigure exclude:**
```yaml
spring:
  autoconfigure:
    exclude:
      # - org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
      # - org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration
      # - org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration
```

---

## Deferred Ideas

- R2DBC for reactive PostgreSQL (consider in Phase 7)
- Multi-tenant database support (out of scope for v1)
- Database encryption at rest (Phase 7 security)
- Connection pool monitoring dashboards (Phase 7 monitoring)

---

*Phase: 01-database-foundation*
*Context gathered: 2026-03-20*
