# Coding Conventions

**Analysis Date:** 2026-03-09

## Naming Patterns

### Files
- **Java Classes:** PascalCase (`UnifiedMemoryService.java`, `SessionManager.java`)
- **Test Classes:** `*Test.java` suffix pattern (`EpisodeTest.java`, `LlmModelRouterTest.java`)
- **Configuration:** `application.yml`, `llm-models.yml`, `build.gradle`

### Classes
- **Services:** `*Service` suffix (`MemoryService`, `SemanticMemoryService`, `EpisodicMemoryService`)
- **Configuration:** `*Configuration` or `*Properties` (`LlmConfigurationProperties`, `ModelConfiguration`)
- **Models:** `*Model` suffix (`ChatModel`, `ModelConfiguration`)
- **Strategy/Selectors:** `*Strategy`, `*Selector` (`ModelSelectionStrategy`, `RoundRobinModelSelector`)
- **Managers:** `*Manager` suffix (`MemoryManager`, `SessionManager`)
- **Abstract/Base:** `*Base` or interface pattern (`MemoryService` interface)

### Functions/Methods
- **Service Methods:** Verb-based, PascalCase (`storeEpisode`, `getRecentEpisodes`, `searchSimilarCode`)
- **Getters/Setters:** Standard JavaBean pattern (`getId()`, `setId()`, `getSessionId()`)
- **Factory Methods:** `create*`, `create*ModelSelector`
- **Validation:** `*Validator`, `validate*`

### Variables
- **Instance Fields:** snake_case in YAML configs, PascalCase in Java getters
- **Local Variables:** camelCase (`modelName`, `chatModel`, `strategy`)
- **Constants:** UPPERCASE (not commonly used in this codebase)

### Packages
- **Structure:** `com.synapse.[domain].[subdomain]`
- **Examples:**
  - `com.synapse.memory`
  - `com.synapse.llm.service`
  - `com.synapse.agent.tools`

## Code Style

### Annotations
```java
@Service      // Spring service component
@Autowired    // Dependency injection
@Test         // JUnit test method
@BeforeEach   // JUnit setup method
```

### Logging
- **Framework:** SLF4J (`org.slf4j.Logger`, `org.slf4j.LoggerFactory`)
- **Pattern:**
```java
private static final Logger logger = LoggerFactory.getLogger(ClassName.class);
logger.info("Initializing {} with strategy: {}", ...);
logger.warn("Unknown strategy: {}, defaulting to round-robin", ...);
```

### Service Layer
```java
@Service
public class ServiceName implements InterfaceName {
    private static final Logger logger = LoggerFactory.getLogger(ServiceName.class);

    private final DependencyType dependency;

    @Autowired
    public ServiceName(DependencyType dependency) {
        this.dependency = dependency;
    }

    public ReturnType methodName(ParamType param) {
        logger.info("Executing {}", ...);
        // implementation
    }
}
```

### Configuration Classes
```java
public class ConfigurationProperties {
    private Settings settings;
    private List<ModelConfiguration> modelList;

    // Getters and setters
    public Settings getSettings() { return settings; }
    public void setSettings(Settings settings) { this.settings = settings; }
}
```

### Error Handling
- **Runtime Exceptions:** `IllegalStateException` for missing dependencies
- **Logging:** Log warnings before fallback behavior
- **Validation:** Fail fast with descriptive error messages

```java
if (chatModel == null) {
    throw new IllegalStateException("ChatModel not found for: " + modelName);
}
```

### Switch Expressions
- **Modern Java 21 style:** Switch with arrow (`->`) and yield
```java
return switch (strategy.toLowerCase()) {
    case "round-robin" -> new RoundRobinModelSelector(modelNames);
    default -> {
        logger.warn("Unknown strategy: {}, defaulting to round-robin", strategy);
        yield new RoundRobinModelSelector(modelNames);
    }
};
```

## Documentation

### JavaDoc
- Minimal JavaDoc in current codebase
- Class-level comments for services
- Method-level comments not consistently used

### YAML Configuration
- **Comments:** `#` style for disabled features
- **Structure:** Nested keys with clear hierarchy
- **Examples:**
```yaml
# Commented out features
# datasource:
#   url: jdbc:postgresql://localhost:5432/synapse_memory

# Active configuration
memory:
  episodic:
    redis:
      host: localhost
      port: 6379
```

## Design Patterns

### Strategy Pattern
```java
public interface ModelSelectionStrategy {
    String selectModel(List<String> modelNames);
}

@Service
public class RoundRobinModelSelector implements ModelSelectionStrategy {
    // implementation
}
```

### Factory Pattern
```java
public class EmbeddingConfigurationFactory {
    public static EmbeddingConfiguration create(Environment env) {
        // return appropriate configuration
    }
}
```

### Singleton (Spring-managed)
- All `@Service` beans are singletons by default in Spring
- Dependency injection via constructor

### Builder/Factory for Configuration
```java
public class EmbeddingConfigurationFactory {
    public EmbeddingConfiguration createConfiguration() {
        // Create configuration based on environment
    }
}
```

## Spring Boot Conventions

### Auto-Configuration
```java
@Configuration
public class LlmAutoConfiguration {
    @Bean
    public ChatModel claudeSonnet46ChatModel() {
        return new ChatModel(...);
    }
}
```

### Properties Binding
```java
@ConfigurationProperties(prefix = "llm")
public class LlmConfigurationProperties {
    // Fields bound from application.yml
}
```

### Component Scanning
- Packages under `com.synapse` are auto-scanned
- Services, configurations, and components detected automatically

## Testing Conventions

### JUnit 5 (Jupiter)
```java
@Test
void testMethodName() {
    // Arrange
    // Act
    // Assert
    assertEquals(expected, actual);
    assertNotNull(object);
    assertNull(value);
}
```

### Test Setup
```java
@BeforeEach
void setUp() {
    instance = new ClassName();
}
```

### Test Naming
- **Pattern:** `test*` prefix with descriptive method name
- **Examples:** `testDefaultConstructor`, `testGettersAndSetters`

## File Organization

### Package Structure
- **Domain-first:** Group by business domain (memory, llm, agent, embedding)
- **Sub-packages:** `config`, `service`, `impl`, `tools`
- **Test mirroring:** Test packages mirror main packages

### Layer Separation
```
com.synapse
├── agent/              # Business logic - agents
├── ai/                 # Business logic - AI services
├── embedding/          # Infrastructure - embedding
├── llm/                # Infrastructure - LLM
│   ├── config/         # Configuration
│   └── service/        # Service layer
│       └── impl/       # Implementation details
├── memory/             # Business logic - memory
│   ├── config/         # Configuration
│   ├── episodic/       # Specific memory type
│   ├── semantic/       # Specific memory type
│   └── knowledgegraph/ # Specific memory type
└── workflow/           # Business logic - workflow
```
