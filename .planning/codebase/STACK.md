# Technology Stack

**Analysis Date:** 2026-03-09

## Languages

- **Java 21** - Primary language (LTS version)
- **Kotlin** - Not explicitly used but Spring Boot 3.x supports it
- **SQL** - Database queries (PostgreSQL, SQLite)
- **Shell/Bash** - Build and deployment scripts

## Frameworks & Runtime

- **Spring Boot 3.3.5** - Application framework
- **Spring AI 1.0.0** - AI integration layer
- **Gradle 9.3.1** - Build tool
- **Netty** - gRPC server runtime
- **Hibernate** - JPA implementation (commented out)

## Dependencies

### Core Spring Boot
```gradle
implementation 'org.springframework.boot:spring-boot-starter'
implementation 'org.springframework.boot:spring-boot-starter-web'
// implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
```

### gRPC Communication
```gradle
implementation 'io.grpc:grpc-netty-shaded:1.75.0'
implementation 'io.grpc:grpc-protobuf:1.58.0'
implementation 'io.grpc:grpc-stub:1.58.0'
```

### Database & Caching
```gradle
implementation 'io.qdrant:client:1.17.0'  // Vector database
// implementation 'redis.clients:jedis:4.4.6'
// implementation 'org.springframework.data:spring-data-redis:3.2.0'
// implementation 'org.xerial:sqlite-jdbc:3.42.0.0'
// implementation 'org.springframework.boot:spring-boot-starter-jdbc'
```

### AI/LLM Integration
```gradle
implementation platform("org.springframework.ai:spring-ai-bom:1.0.0")
implementation 'org.springframework.ai:spring-ai-openai'
implementation 'org.springframework.ai:spring-ai-starter-model-anthropic'
```

### Testing
```gradle
testImplementation 'org.springframework.boot:spring-boot-starter-test'
```

## Configuration Files

| File | Purpose |
|------|---------|
| `application.yml` | Main application configuration |
| `llm-models.yml` | LLM model routing configuration |
| `build.gradle` | Build dependencies and tasks |
| `settings.gradle` | Project name and settings |
| `gradle.properties` | Gradle properties |

## External APIs & Services

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **GPUHub** | Anthropic model hosting | `u425-u70w-e4420dcd.singapore-b.gpuhub.com:8443` |
| **Anthropic API** | Claude model access | `ANTHROPIC_API_KEY` env var |
| **Qdrant** | Vector database | `localhost:6334` |
| **Redis** | Episodic memory cache | `localhost:6379` |
| **PostgreSQL** | Primary database (commented) | `localhost:5432/synapse_memory` |
| **SQLite** | Knowledge graph storage | `/var/lib/synapse/knowledge.db` |

## Build Configuration

```gradle
plugins {
    id 'org.springframework.boot' version '3.3.5'
    id 'io.spring.dependency-management' version '1.1.7'
    id 'java'
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}
```

## Maven Repositories

- `mavenCentral()` - Primary repository
- `jitpack.io` - Qdrant client (if needed)
- `repo.spring.io/milestone` - Spring milestones
- `repo.spring.io/snapshot` - Spring snapshots
- `central.sonatype.com` - Central Portal snapshots

## Database Configuration (Commented Out)

```yaml
datasource:
  url: jdbc:postgresql://localhost:5432/synapse_memory
  username: synapse_user
  password: synapse_password
  driver-class-name: org.postgresql.Driver
  hikari:
    maximum-pool-size: 10
    connection-timeout: 30000

redis:
  host: localhost
  port: 6379
  timeout: 2000ms
  lettuce:
    pool:
      max-active: 20
      max-idle: 10
      min-idle: 5
```

## Active Memory Configuration

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

## LLM Models Configured

| Model Name | LiteLLM Model |
|------------|---------------|
| claude-sonnet-4-6 | openai/claude-sonnet-4-6 |
| claude-sonnet-4-5-20251022 | openai/claude-sonnet-4-5-20251022 |
| claude-sonnet-4-5 | openai/claude-sonnet-4-5 |
| claude-haiku-4-5-20251001 | openai/claude-haiku-4-5-20251001 |
| claude-haiku-4-5 | openai/claude-haiku-4-5 |

## Logging

```yaml
logging:
  level:
    com.synapse.memory: DEBUG
```
