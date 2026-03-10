# Java-Based Memory-Agentic Development System

This project implements a memory-based agentic system using Java as the primary language, following the specifications outlined in the CLAUDE.md file.

## System Architecture

### Core Components

1. **Memory Layers**
   - **Episodic Memory**: Stores temporal events using Redis-like storage
   - **Semantic Memory**: Stores code embeddings using Qdrant vector database
   - **Knowledge Graph**: Stores relationships using Kuzu graph database

2. **Agent Orchestration**
   - Developer Assistant for task-based assistance
   - Tool integration for code search and retrieval

3. **Workflow Management**
   - Session Management for tracking developer workflows
   - Task Continuity for preserving state across sessions

### Technology Stack

- **Primary Language**: Java 17+
- **Framework**: Spring Boot 3.x
- **Build System**: Gradle
- **Memory Systems**:
  - Redis (for session memory)
  - Qdrant (for semantic memory)
  - Kuzu (for knowledge graphs)
- **Communication**: gRPC with Protocol Buffers
- **LLM Integration**: HTTP clients for Ollama and TEI

## Directory Structure

```
app/
├── src/
│   ├── main/
│   │   └── java/com/synapse/
│   │       ├── memory/                 # Core memory models
│   │       ├── memory/episodic/        # Episodic memory implementation
│   │       ├── memory/semantic/        # Semantic memory implementation
│   │       ├── memory/knowledgegraph/  # Knowledge graph implementation
│   │       ├── agent/                  # Agent components
│   │       ├── agent/tools/            # Tool integrations
│   │       ├── workflow/               # Workflow management
│   │       └── grpc/                   # gRPC service definitions
│   └── proto/                          # Protocol Buffer definitions
├── build.gradle                        # Gradle configuration
├── settings.gradle                     # Gradle settings
└── README.md                           # This documentation
```

## Key Features Implemented

### 1. Memory Data Models
- `Episode`: Represents temporal memory events
- `EmbeddingRecord`: Stores vector representations of code
- `CodeMatch`: SearchResult for code similarity queries

### 2. Memory Services
- `UnifiedMemoryService`: Coordinates all memory layers
- `EpisodicMemoryService`: Manages session-based memory
- `SemanticMemoryService`: Handles codebase indexing and search
- `KnowledgeGraphService`: Manages semantic relationships

### 3. Agent Components
- `DeveloperAssistant`: Main agent for developer assistance
- `CodeSearchTool`: Tool for searching similar code

### 4. Workflow Management
- `SessionManager`: Handles session lifecycle
- `TaskContinuityService`: Manages task state persistence

### 5. gRPC Communication
- `memory_service.proto`: Defines service contracts for inter-system communication

## Implementation Details

### Memory Layer Implementation
Each memory layer follows the specification:
- **Episodic**: In-memory storage with timestamp-based retrieval
- **Semantic**: Vector-based search using simulated Qdrant integration
- **Knowledge Graph**: Relationship storage with simulated Kuzu integration

### Agent Architecture
- Spring Boot components for agent orchestration
- Tool integration for code search capabilities
- Context-aware response generation

### Workflow Features
- Session management with UUID-based identifiers
- Task state persistence (simulated)
- Continuity across system interactions

## Future Enhancements

1. **Complete gRPC Implementation** - Full service definitions and client implementations
2. **Real Database Integration** - Redis, Qdrant, and Kuzu client implementations
3. **LLM Integration** - HTTP clients for Ollama and TEI services
4. **Reactive Programming** - Spring WebFlux support for asynchronous operations
5. **Security Features** - Authentication and authorization for distributed systems

## Building and Running

```bash
# Build the project
./gradlew clean build

# Run the application
./gradlew bootRun

# Run tests
./gradlew test
```

## Testing

Unit tests verify the core functionality of all implemented components:
- Memory data models
- Service implementations
- Agent components
- Workflow management