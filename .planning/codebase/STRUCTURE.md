# Directory Structure

**Analysis Date:** 2026-03-09

## Project Root

```
synapse/
├── app/                    # Main Java application
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/synapse/
│   │   │   ├── proto/
│   │   │   └── resources/
│   │   └── test/
│   │       └── java/com/synapse/
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradlew
│   └── README.md
├── config/                 # Configuration files
│   ├── llm/
│   └── ngnix/
├── .planning/              # GSD planning artifacts
│   └── codebase/           # Codebase documentation
└── .git/
```

## Application Source Structure

### Main Source (`src/main/java/com/synapse/`)

```
com/synapse/
├── SynapseApplication.java              # Spring Boot entry point
├── agent/                               # AI Agent layer
│   ├── DeveloperAssistant.java          # Main agent implementation
│   └── tools/
│       └── CodeSearchTool.java          # Code search capability
├── ai/                                  # AI services
│   └── Qwen3EmbeddingService.java       # Embedding service
├── embedding/                           # Embedding configuration
│   ├── EmbeddingService.java            # Interface
│   ├── EmbeddingConfiguration.java      # Configuration class
│   ├── EmbeddingConfigurationType.java  # Environment types
│   ├── EmbeddingConfigurationFactory.java
│   ├── EmbeddingConfigurationManager.java
│   ├── EmbeddingConfigurationValidator.java
│   ├── EmbeddingConfigurationValidatorDemo.java
│   ├── DevelopmentConfiguration.java
│   ├── StagingConfiguration.java
│   └── ProductionConfiguration.java
├── llm/                                 # LLM layer
│   ├── config/
│   │   ├── LlmAutoConfiguration.java    # Auto-configuration
│   │   ├── LlmConfigurationProperties.java
│   │   ├── LlmSettings.java
│   │   ├── ModelConfiguration.java
│   │   └── ChatModel.java
│   │   └── MockChatModel.java
│   └── service/
│       ├── LlmModelRouter.java          # Model router
│       ├── ModelSelectionStrategy.java  # Strategy interface
│       └── impl/
│           └── RoundRobinModelSelector.java
├── memory/                              # Memory layer
│   ├── MemoryService.java               # Memory interface
│   ├── MemoryManager.java               # Memory coordinator
│   ├── UnifiedMemoryService.java        # Unified memory
│   ├── Episode.java                     # Memory episode entity
│   ├── EmbeddingRecord.java             # Embedding record entity
│   ├── CodeMatch.java                   # Code match entity
│   ├── config/
│   │   ├── MemoryConfigurationProperties.java
│   │   └── MemoryConfigurationService.java
│   ├── episodic/
│   │   └── EpisodicMemoryService.java   # Episodic memory
│   ├── knowledgegraph/
│   │   └── KnowledgeGraphService.java   # Knowledge graph
│   └── semantic/
│       └── SemanticMemoryService.java   # Semantic memory
└── workflow/                            # Workflow layer
    ├── SessionManager.java              # Session management
    ├── TaskContinuityService.java       # Task continuity
    └── TaskState.java                   # Task state
```

### Test Source (`src/test/java/com/synapse/`)

```
com/synapse/
├── SynapseMemoryAgentTest.java          # Agent test
├── MemoryIntegrationTest.java           # Integration test suite
├── agent/
│   └── DeveloperAssistantTest.java
├── agent/tools/
│   └── CodeSearchToolTest.java
├── embedding/
│   ├── EmbeddingConfigurationTypeTest.java
│   └── EmbeddingConfigurationValidatorTest.java
├── llm/
│   ├── config/
│   │   └── LlmConfigurationPropertiesTest.java
│   └── service/
│       ├── LlmModelRouterTest.java
│       └── impl/
│           └── RoundRobinModelSelectorTest.java
├── memory/
│   ├── EpisodeTest.java
│   ├── EmbeddingRecordTest.java
│   ├── CodeMatchTest.java
│   ├── config/
│   │   └── MemoryConfigurationServiceTest.java
│   ├── episodic/
│   │   └── EpisodicMemoryServiceTest.java
│   ├── knowledgegraph/
│   │   └── KnowledgeGraphServiceTest.java
│   ├── semantic/
│   │   └── SemanticMemoryServiceTest.java
│   └── UnifiedMemoryServiceTest.java
└── workflow/
    └── SessionManagerTest.java
```

### Resources (`src/main/resources/`)

```
resources/
├── application.yml                      # Main configuration
├── llm-models.yml                       # LLM model configuration
├── db/
│   └── migration/                       # Database migrations
└── (other resource files)
```

### Proto Files (`src/main/proto/`)

```
proto/
└── (gRPC service definitions)
```

## Configuration Structure

### Gradle Configuration
```
app/
├── build.gradle                         # Build configuration
├── settings.gradle                      # Project settings
├── gradle.properties                    # Gradle properties
├── gradlew                              # Unix wrapper script
├── gradlew.bat                          # Windows wrapper script
└── gradle/
    └── wrapper/
        └── gradle-wrapper.properties
```

### External Configuration
```
config/
├── llm/                                 # LLM configurations
│   └── (model configs)
└── ngnix/                               # Nginx configs
    └── (server configs)
```

## Naming Conventions

### Java Files
- **Classes:** PascalCase (e.g., `UnifiedMemoryService`, `SessionManager`)
- **Interfaces:** PascalCase with descriptive names (e.g., `MemoryService`, `EmbeddingService`)
- **Tests:** `*Test.java` suffix pattern

### Configuration Files
- **YAML:** snake_case keys (e.g., `api-key`, `model_list`)
- **Gradle:** Lowercase with hyphens (e.g., `spring-boot-starter-web`)

### Packages
- **Structure:** `com.synapse.[domain].[subdomain]`
- **Examples:**
  - `com.synapse.memory`
  - `com.synapse.llm.service`
  - `com.synapse.agent.tools`

## Key Locations Summary

| Purpose | Location |
|---------|----------|
| Application Entry | `app/src/main/java/com/synapse/SynapseApplication.java` |
| Main Configuration | `app/src/main/resources/application.yml` |
| LLM Configuration | `app/src/main/resources/llm-models.yml` |
| Build Config | `app/build.gradle` |
| Memory Services | `app/src/main/java/com/synapse/memory/` |
| LLM Services | `app/src/main/java/com/synapse/llm/` |
| Agent Code | `app/src/main/java/com/synapse/agent/` |
| Tests | `app/src/test/java/com/synapse/` |
