# System Architecture

**Analysis Date:** 2026-03-09

## Architectural Pattern

- **Type:** Layered Architecture with Clean Architecture principles
- **Style:** Spring Boot microservices-ready monolith
- **Communication:** REST API + gRPC for inter-service

## System Layers

### 1. Presentation Layer
- **Entry Point:** `SynapseApplication.java` (Spring Boot main class)
- **API:** Spring Web (REST endpoints)
- **Port:** 8080 (configured in `application.yml`)

### 2. Application Layer
- **Session Management:** `SessionManager.java`
- **Task Orchestration:** `TaskContinuityService.java`
- **State Management:** `TaskState.java`

### 3. Business Logic Layer

#### Memory Services
| Service | Package | Responsibility |
|---------|---------|----------------|
| `UnifiedMemoryService` | `com.synapse.memory` | Memory orchestration |
| `SemanticMemoryService` | `com.synapse.memory.semantic` | Vector-based memory |
| `EpisodicMemoryService` | `com.synapse.memory.episodic` | Time-based memory |
| `KnowledgeGraphService` | `com.synapse.memory.knowledgegraph` | Graph-based knowledge |
| `MemoryManager` | `com.synapse.memory` | Memory coordination |

#### LLM Services
| Service | Package | Responsibility |
|---------|---------|----------------|
| `LlmModelRouter` | `com.synapse.llm.service` | Model selection/routing |
| `RoundRobinModelSelector` | `com.synapse.llm.service.impl` | Load balancing |
| `ModelSelectionStrategy` | `com.synapse.llm.service` | Selection algorithms |

#### AI Services
| Service | Package | Responsibility |
|---------|---------|----------------|
| `Qwen3EmbeddingService` | `com.synapse.ai` | Embedding generation |
| `EmbeddingService` | `com.synapse.embedding` | Embedding abstraction |

#### Agent Services
| Service | Package | Responsibility |
|---------|---------|----------------|
| `DeveloperAssistant` | `com.synapse.agent` | AI agent implementation |
| `CodeSearchTool` | `com.synapse.agent.tools` | Code search capability |

### 4. Infrastructure Layer
- **Configuration:** `LlmConfigurationProperties`, `MemoryConfigurationProperties`
- **Auto-configuration:** `LlmAutoConfiguration`
- **Database:** Qdrant, Redis, SQLite clients

## Data Flow

```
Client Request
    ↓
REST API (Spring Web)
    ↓
SessionManager / TaskContinuityService
    ↓
UnifiedMemoryService (Orchestration)
    ↓
┌─────────────┬─────────────┬──────────────┐
│ Semantic    │ Episodic    │ Knowledge    │
│ Memory      │ Memory      │ Graph        │
└─────────────┴─────────────┴──────────────┘
    ↓
LlmModelRouter → GPUHub/Anthropic API
    ↓
Response → Client
```

## Abstractions & Interfaces

### Memory Abstractions
- `MemoryService` - Base memory interface
- `MemoryManager` - Coordination layer
- `Episode` - Memory unit entity

### Embedding Abstractions
- `EmbeddingService` - Interface for embedding providers
- `EmbeddingConfiguration` - Configuration abstraction
- `EmbeddingConfigurationType` - Environment-based configuration

### Model Selection
- `ModelSelectionStrategy` - Strategy pattern for model selection
- `LlmModelRouter` - Router implementation

## Entry Points

### Application Entry
```java
com.synapse.SynapseApplication
```

### Configuration Entry
```java
com.synapse.llm.config.LlmAutoConfiguration
com.synapse.memory.config.MemoryConfigurationService
```

### Testing Entry
```java
com.synapse.MemoryIntegrationTest
com.synapse.SynapseMemoryAgentTest
```

## Configuration Patterns

### Environment-based Configuration
- `DevelopmentConfiguration` - Local development settings
- `StagingConfiguration` - Staging environment settings
- `ProductionConfiguration` - Production settings
- `EmbeddingConfigurationFactory` - Factory pattern for configuration

### Properties-Based Configuration
- `LlmConfigurationProperties` - LLM settings
- `MemoryConfigurationProperties` - Memory settings
- `ModelConfiguration` - Individual model config

## Design Patterns Used

| Pattern | Usage |
|---------|-------|
| **Strategy** | Model selection strategies |
| **Factory** | Configuration creation |
| **Singleton** | Service instances |
| **Dependency Injection** | Spring beans |
| **Template Method** | Service implementations |

## Module Structure

```
com.synapse
├── agent
│   ├── DeveloperAssistant
│   └── tools
│       └── CodeSearchTool
├── ai
│   └── Qwen3EmbeddingService
├── embedding
│   ├── EmbeddingService (interface)
│   ├── EmbeddingConfiguration
│   ├── EmbeddingConfigurationType
│   ├── EmbeddingConfigurationFactory
│   ├── EmbeddingConfigurationManager
│   ├── EmbeddingConfigurationValidator
│   └── [Environment configs]
├── llm
│   ├── config
│   │   ├── LlmAutoConfiguration
│   │   ├── LlmConfigurationProperties
│   │   ├── LlmSettings
│   │   ├── ModelConfiguration
│   │   └── ChatModel
│   └── service
│       ├── LlmModelRouter
│       ├── ModelSelectionStrategy
│       └── impl
│           └── RoundRobinModelSelector
├── memory
│   ├── MemoryService (interface)
│   ├── MemoryManager
│   ├── UnifiedMemoryService
│   ├── Episode
│   ├── EmbeddingRecord
│   ├── CodeMatch
│   ├── config
│   │   ├── MemoryConfigurationProperties
│   │   └── MemoryConfigurationService
│   ├── episodic
│   │   └── EpisodicMemoryService
│   ├── knowledgegraph
│   │   └── KnowledgeGraphService
│   └── semantic
│       └── SemanticMemoryService
└── workflow
    ├── SessionManager
    └── TaskContinuityService
    └── TaskState
```
