---
phase: 01-database-foundation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - build.gradle.kts
  - src/main/resources/application.yml
  - src/main/java/com/synapse/config/PostgresConfig.java
  - src/main/java/com/synapse/config/RedisConfig.java
  - src/main/java/com/synapse/config/SQLiteConfig.java
  - src/main/java/com/synapse/health/MultiDatabaseHealthIndicator.java
autonomous: true
requirements:
  - DB-01
  - DB-02
  - DB-03
  - DB-04
  - DB-05
user_setup:
  - service: postgresql
    why: "Primary database for JPA entities"
    env_vars:
      - name: DB_PASSWORD
        source: "User must provide PostgreSQL credentials"
    dashboard_config:
      - task: "Create database named synapse_memory"
        location: "PostgreSQL server"

  - service: redis
    why: "Episodic memory storage with TTL"
    env_vars:
      - name: REDIS_PASSWORD
        source: "Redis dashboard if authentication enabled"
    dashboard_config:
      - task: "Ensure Redis is running on localhost:6379"
        location: "Redis server"

  - service: sqlite
    why: "Knowledge graph storage"
    env_vars:
      - name: SQLITE_PATH
        source: "User can set custom path, defaults to /var/lib/synapse/knowledge.db"
    dashboard_config: []

---

## Phase Goal

Enable all three database layers (PostgreSQL, Redis, SQLite) with connection pooling and health checks, making them ready for use by memory services.

## Success Criteria

- [ ] PostgreSQL connected via HikariCP with 10 connections, 30s timeout
- [ ] Redis connected via Jedis with connection pooling (max 20, min idle 5)
- [ ] SQLite JDBC driver initializes database at configured path
- [ ] Health endpoint `/actuator/health` shows all three databases
- [ ] Application starts successfully with all databases healthy

---

## Task Breakdown

### Task 1: Enable Database Dependencies

**Description:** Enable all required database dependencies in `build.gradle.kts`

**Files:**
- `build.gradle.kts`

**Dependencies:** None

**Implementation:**
1. Uncomment and enable the following dependencies in `build.gradle.kts`:
   - `spring-boot-starter-data-jpa` - for PostgreSQL JPA operations
   - `spring-boot-starter-jdbc` - for HikariCP connection pooling
   - `org.postgresql:postgresql:42.7.3` - PostgreSQL driver
   - `redis.clients:jedis:4.4.6` - Redis client
   - `org.springframework.data:spring-data-redis:3.2.0` - Spring Data Redis
   - `org.xerial:sqlite-jdbc:3.42.0.0` - SQLite JDBC
   - `org.flywaydb:flyway-core:10.5.0` - Database migrations

**Verification:**
```xml
<verify>
  <automated>./gradlew dependencies --configuration implementation | grep -E "(postgresql|jedis|sqlite|flyway)"</automated>
  <manual>Verify all 7 dependencies appear in the output</manual>
</verify>
```

**Done:** All 7 database dependencies enabled and verified in build configuration

---

### Task 2: Configure PostgreSQL with HikariCP

**Description:** Enable PostgreSQL datasource configuration with HikariCP connection pooling

**Files:**
- `src/main/resources/application.yml`
- `src/main/java/com/synapse/config/PostgresConfig.java`

**Dependencies:** Task 1 (dependencies must be enabled first)

**Implementation:**
1. In `application.yml`:
   - Remove PostgreSQL from `spring.autoconfigure.exclude` list
   - Uncomment and configure `spring.datasource` section with:
     - URL: `jdbc:postgresql://localhost:5432/synapse_memory`
     - Username: `synapse_user`
     - Password: `${DB_PASSWORD:default_password}`
     - Driver: `org.postgresql.Driver`
     - HikariCP pool settings (max 10, min idle 5, timeout 30000ms)
   - Add `spring.jpa` configuration:
     - Hibernate DDL auto: `none` (Flyway handles migrations)
     - Show SQL: `${SHOW_SQL:false}`
     - Database platform: `org.hibernate.dialect.PostgreSQLDialect`

2. Create `PostgresConfig.java` with:
   - `@Configuration` class
   - `@Bean` DataSource with HikariCP configuration
   - `@Bean` EntityManagerFactory configured for PostgreSQL
   - `@Bean` TransactionManager for JPA transactions

**Verification:**
```xml
<verify>
  <automated>./gradlew compileJava</automated>
</verify>
```

**Done:** PostgreSQL configured with HikariCP pool (10 connections, 30s timeout), JPA enabled, auto-configuration not excluded

---

### Task 3: Configure Redis with Jedis

**Description:** Enable Redis connection using Jedis client with connection pooling

**Files:**
- `src/main/resources/application.yml`
- `src/main/java/com/synapse/config/RedisConfig.java`

**Dependencies:** Task 1 (dependencies must be enabled first)

**Implementation:**
1. In `application.yml`:
   - Remove Redis from `spring.autoconfigure.exclude` list (if present)
   - Uncomment and configure `spring.redis` section:
     - Host: `localhost`
     - Port: `6379`
     - Password: `${REDIS_PASSWORD:}` (optional)
     - Timeout: `2000ms`
     - Jedis pool settings (max active 20, max idle 10, min idle 5)

2. Create `RedisConfig.java` with:
   - `@Configuration` class
   - `@Bean` JedisConnectionFactory configured with pool settings
   - `@Bean` RedisTemplate using JedisConnectionFactory
   - Configure key/value serializers (StringRedisSerializer for both)

**Verification:**
```xml
<verify>
  <automated>./gradlew compileJava</automated>
</verify>
```

**Done:** Redis configured with Jedis connection pooling (max 20, min idle 5), RedisTemplate bean available for injection

---

### Task 4: Configure SQLite JDBC

**Description:** Enable SQLite JDBC driver and configure knowledge graph database path

**Files:**
- `src/main/resources/application.yml`
- `src/main/java/com/synapse/config/SQLiteConfig.java`

**Dependencies:** Task 1 (dependencies must be enabled first)

**Implementation:**
1. In `application.yml`:
   - Add `memory.knowledge.sqlite` section:
     - Path: `${SQLITE_PATH:/var/lib/synapse/knowledge.db}`
   - Note: No autoconfigure exclusion needed for SQLite (no auto-config)

2. Create `SQLiteConfig.java` with:
   - `@Configuration` class
   - `@Bean` DataSource or Connection provider for SQLite
   - Use `DriverManager.getConnection("jdbc:sqlite:" + sqlitePath)`
   - Add `@PostConstruct` method to ensure database file/directory exists
   - Optionally create basic table if needed (can be done in Phase 2)

**Verification:**
```xml
<verify>
  <automated>./gradlew compileJava</automated>
</verify>
```

**Done:** SQLite configured with configurable path, database directory created on startup

---

### Task 5: Create Multi-Database Health Indicator

**Description:** Implement health indicator that checks all three database connections

**Files:**
- `src/main/java/com/synapse/health/MultiDatabaseHealthIndicator.java`

**Dependencies:** Task 2, Task 3, Task 4 (all configs must exist first)

**Implementation:**
1. Create `MultiDatabaseHealthIndicator.java`:
   - Implement `HealthIndicator` interface
   - Inject: `DataSource postgresDataSource`, `RedisConnectionFactory redisFactory`, `String sqlitePath`
   - In `health()` method:
     - Test PostgreSQL connection via `DataSource.getConnection()` and `conn.isValid(5)`
     - Test Redis connection via `redisFactory.getConnection()`
     - Test SQLite connection via `DriverManager.getConnection()`
     - Return `Health.up().withDetails(Map)` with individual health status for each DB
   - Include individual `postgresql`, `redis`, `sqlite` health details in response

2. Verify Actuator health endpoint is enabled (check `application.yml`):
   - `management.endpoints.web.exposure.include=health,info`

**Verification:**
```xml
<verify>
  <automated>./gradlew compileJava</automated>
</verify>
```

**Done:** Health indicator created that reports status of all three databases via `/actuator/health` endpoint

---

## Integration Notes

### Cross-Phase Dependencies

- **Phase 2 (Memory Core):** Will use these database configurations to implement `EpisodicMemoryService`, `SemanticMemoryService`, and `KnowledgeGraphService`
- **Phase 7 (Configuration Polish):** Will add environment-specific profiles (dev/staging/prod) for database URLs

### Data Flow

1. **PostgreSQL:** JPA repositories store entities (used by semantic memory for vector metadata)
2. **Redis:** RedisTemplate stores episodic memory with TTL expiration
3. **SQLite:** JDBC stores knowledge graph edges and nodes

### Connection Pool Considerations

- PostgreSQL: HikariCP managed via Spring Boot auto-configuration
- Redis: Jedis pool managed by `JedisConnectionFactory`
- SQLite: Single connection, no pooling needed (single-file DB)

---

## Verification Checklist

**Before marking phase complete:**

- [ ] `./gradlew build` succeeds with no errors
- [ ] All 7 database dependencies present in `build.gradle.kts`
- [ ] PostgreSQL datasource configured in `application.yml`
- [ ] Redis configuration present in `application.yml`
- [ ] SQLite path configured in `application.yml`
- [ ] Auto-configuration exclusions removed for JPA and DataSource
- [ ] `PostgresConfig.java` created with DataSource, EntityManagerFactory, TransactionManager beans
- [ ] `RedisConfig.java` created with JedisConnectionFactory and RedisTemplate beans
- [ ] `SQLiteConfig.java` created with SQLite DataSource/Connection bean
- [ ] `MultiDatabaseHealthIndicator.java` created
- [ ] Application starts without errors (dry-run without actual DB connections)
- [ ] `/actuator/health` endpoint accessible (will show DOWN if DBs not running)

---

## Next Steps

After this phase completes:

1. Run application to verify database connections (requires PostgreSQL, Redis, SQLite running)
2. Proceed to Phase 2 (Memory Core) to implement memory services using these configurations
3. Test health endpoint with all three databases running

---

*Phase: 01-database-foundation*
*Plan: 01*
*Created: 2026-03-20*
