# SYNAPSE CODEBASE ANALYSIS REPORT
## Coding Standards, Folder Structure, Modules & Naming Conventions

---

## 1. FOLDER STRUCTURE

### Top-Level Directory Organization

```
synapse/
├── rag/                    # Core RAG system (30+ Python modules)
├── mcp_server/            # MCP server implementation (7 modules)
├── synapse/               # CLI application (Typer-based)
├── tests/                 # Comprehensive test suite (30+ test files)
├── docs/                  # Documentation with specs subdirectory
├── configs/               # Configuration files (JSON)
├── interfaces/            # Interface definitions (TypeScript)
├── scripts/               # Utility scripts
├── spec/                  # Specification and planning documents
├── pyproject.toml         # Poetry project configuration
├── pytest.ini             # Pytest configuration
├── requirements.txt       # Dependencies
└── VERSION                # Version file
```

### Core Directories Breakdown

#### **rag/** - Main RAG System
- `orchestrator.py` - Main coordinator (442 lines)
- `memory_store.py` - Symbolic memory (SQLite)
- `episodic_store.py` - Episodic memory (SQLite)
- `semantic_store.py` - Vector-based semantic memory
- `retriever.py` - Document retrieval
- `embedding.py` - Embedding service
- `model_manager.py` - LLM model management
- `logger.py` - Standardized logging
- `ingest.py` / `semantic_ingest.py` - Document ingestion
- `query_expander.py` - Query expansion
- `memory_reader.py` / `memory_writer.py` - Memory operations
- `memory_selector.py` - Memory type selection
- `conversation_analyzer.py` - Conversation analysis
- `learning_extractor.py` - Learning extraction
- `auto_learning_tracker.py` - Auto-learning patterns
- `universal_hook.py` - Agent integration hooks
- `prompt_builder.py` - Prompt construction
- `memory_formatter.py` - Memory formatting
- `query_cache.py` - Query caching
- `semantic_injector.py` - Semantic injection
- `episode_extractor.py` - Episode extraction
- `episodic_reader.py` - Episodic reading
- `metrics_collector.py` - Metrics collection
- `chroma_vectorstore.py` / `chroma_semantic_store.py` - ChromaDB
- `vectorstore.py` / `vectorstore_factory.py` - Abstract vector store
- `adapters/` - Adapter implementations

#### **mcp_server/** - MCP Server
- `rag_server.py` - Main server (1400+ lines)
- `project_manager.py` - Multi-project management
- `chroma_manager.py` - ChromaDB management
- `metrics.py` - Metrics collection
- `production_logger.py` - Production logging
- `http_wrapper.py` - HTTP transport wrapper

#### **synapse/** - CLI Application
- `main.py` - Main entry point (Typer app)
- `cli/commands/` - Command implementations:
  - `start.py`, `stop.py`, `status.py`
  - `ingest.py`, `query.py`
  - `setup.py`, `onboard.py`, `models.py`
- `config/` - Configuration module:
  - `defaults.py` - Default configuration

#### **tests/** - Test Suite
- `unit/` - Unit tests (organized by module)
- `integration/` - Integration tests
- `e2e/` - End-to-end tests
- `fixtures/` - Pytest fixtures
- `utils/` - Test utilities
- `conftest.py` - Global test configuration

#### **configs/** - Configuration Files
- `rag_config.json` - Main RAG configuration
- `logging_config.json` - Logging settings
- `models_config.json` - Model configurations
- `metrics_config.json` - Metrics settings
- `llama_config.json` - Llama.cpp settings

---

## 2. MODULE ORGANIZATION PATTERNS

### RAG Module Structure (Layered Architecture)

**Store Layer** (Data Persistence):
- `memory_store.py` - SQLite symbolic memory
- `episodic_store.py` - SQLite episodic memory
- `semantic_store.py` - Vector-based semantic memory
- `vectorstore.py` - Abstract base class

**Service Layer** (Business Logic):
- `retriever.py` - Retrieval operations
- `ingest.py` / `semantic_ingest.py` - Ingestion
- `embedding.py` - Embedding generation
- `model_manager.py` - Model lifecycle

**Integration Layer** (System Integration):
- `orchestrator.py` - Main coordinator
- `conversation_analyzer.py` - Conversation processing
- `auto_learning_tracker.py` - Learning system
- `universal_hook.py` - Agent hooks

**Utility Layer** (Supporting Functions):
- `logger.py` - Logging
- `query_expander.py` - Query enhancement
- `prompt_builder.py` - Prompt construction

### MCP Server Module Pattern

**Backend Layer**:
- `rag_server.py` - Main server
- `project_manager.py` - Project isolation

**Infrastructure Layer**:
- `chroma_manager.py` - ChromaDB management
- `http_wrapper.py` - HTTP transport
- `metrics.py` - Metrics
- `production_logger.py` - Logging

### CLI Module Pattern

**Entry Point**:
- `synapse/main.py` - Typer app definition

**Commands**:
- `synapse/cli/commands/*.py` - Individual commands

---

## 3. CODING PATTERNS

### Import Conventions

**Pattern 1: Relative Imports for Internal Modules**
```python
from .logger import get_logger
from .model_manager import get_model_manager, ModelConfig
```

**Pattern 2: Absolute Imports for RAG System**
```python
from rag import (
    MemoryStore, MemoryFact, get_memory_store,
    EpisodicStore, Episode, get_episodic_store,
    SemanticStore, get_semantic_store
)
```

**Pattern 3: Absolute Imports for External Packages**
```python
import json
import os
from typing import List, Dict, Any, Optional, Generator
import asyncio
import logging
```

**Pattern 4: Alias Imports to Avoid Conflicts**
```python
from synapse.cli.commands import start as start_cmd, stop as stop_cmd
```

### Type Annotation Usage

**Basic Type Hints**:
```python
def __init__(self, config_path: str = "./configs/rag_config.json") -> None:
def _load_config(self) -> None:
```

**Complex Types**:
```python
def chat(
    self,
    messages: List[Dict[str, str]],
    model_name: Optional[str] = None,
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None,
    metadata_filters: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
```

**Generators for Streaming**:
```python
def chat_stream(
    self,
    messages: List[Dict[str, str]]
) -> Generator[str, None, None]:
```

### Error Handling Patterns

**Try-Except with Logging**:
```python
try:
    if os.path.exists(self.config_path):
        with open(self.config_path, 'r') as f:
            config = json.load(f)
except Exception as e:
    logger.warning(f"Failed to load orchestrator config: {e}")
```

**Exception Re-raising with Context**:
```python
try:
    response = self._manager.chat_completion(...)
except Exception as e:
    logger.error(f"Error generating response: {e}")
    return {"content": f"Error: {str(e)}", "error": str(e)}
```

**Validation with Early Return**:
```python
def _validate_remote_file_path(self, file_path: str) -> tuple:
    abs_path = os.path.abspath(file_path)
    if not self._upload_config["enabled"]:
        return (False, "Remote file upload is disabled")
    if not abs_path.startswith(upload_dir):
        return (False, f"File path must be within upload directory: {upload_dir}")
    return (True, "")
```

### Logging Patterns

**Module-Level Logger**:
```python
from .logger import get_logger
logger = get_logger(__name__)
```

**Logger Manager**:
```python
def setup_logging(
    self,
    level: Optional[str] = None,
    log_file: Optional[str] = None,
    debug_flag: bool = False,
    config_file: Optional[str] = None
) -> None:
```

**Format Specification**:
```python
formatter = logging.Formatter(
    '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
```

### Async/Await Patterns

**Async Methods for I/O**:
```python
async def list_projects(
    self,
    scope_type: Optional[str] = None
) -> Dict[str, Any]:
```

**Parallel Execution**:
```python
results = await asyncio.gather(*storage_tasks, return_exceptions=True)
```

**Non-blocking Async**:
```python
asyncio.create_task(self._delete_upload_file_async(real_path))
```

---

## 4. NAMING CONVENTIONS

### File Naming Conventions

| Type | Convention | Examples |
|------|------------|----------|
| Python Modules | snake_case | `orchestrator.py`, `memory_reader.py` |
| Shell Scripts | kebab-case | `rag_status.sh` |
| Directories | snake_case | `mcp_server/`, `rag/`, `tests/` |
| Configuration | snake_case | `rag_config.json` |

### Class Naming Conventions

- **PascalCase** for all classes
- Descriptive names with business domain terms

```python
class RAGOrchestrator:
class MemoryStore:
class EpisodicStore:
class SemanticStore:
class ModelConfig:
class LoggerManager:
class ConversationAnalyzer:
class AutoLearningTracker:
class ProjectManager:
```

### Function Naming Conventions

**snake_case** for all functions:

```python
def _load_config(self) -> None:
def _get_symbolic_store(self) -> MemoryStore:
def _register_chat_model(self) -> None:
def set_chat_model(self, model_path: str, model_name: str = "chat") -> None:
def get_orchestrator(config_path: str = "./configs/rag_config.json") -> RAGOrchestrator:
def store_memory(self, fact: MemoryFact) -> MemoryFact:
def analyze_conversation(self, user_message: str, agent_response: str):
```

**Verb-Noun Pattern**:
- Getters: `get_model_manager()`, `get_memory_store()`
- Actions: `store_memory()`, `query_memory()`, `ingest_file()`
- Validators: `_validate_remote_file_path()`

**Private Methods**:
- Underscore prefix: `_load_config()`, `_register_chat_model()`

### Variable Naming Conventions

**snake_case** for all variables:

```python
# Instance variables
self.config_path = config_path
self._manager = get_model_manager()
self._retriever = get_retriever(config_path)

# Local variables
config = json.load(f)
facts = symbolic_store.query_memory(...)
context_parts = []
operation = {...}
```

**Descriptive Names**:
```python
rag_enabled = True
top_k = 3
memory_db_path = "./data/memory.db"
memory_scope = "session"
```

**Avoid single letters** (except in loops):
```python
for chunk in semantic_store.chunks:
for filename in os.listdir(upload_dir):
```

### Constants Naming Conventions

**UPPER_SNAKE_CASE** for constants:

```python
DEFAULT_CONFIG: Dict[str, Any] = {
    "chunk_size": 500,
    "chunk_overlap": 50,
    "top_k": 3,
    "min_retrieval_score": 0.3,
    "embedding_model": "bge-m3-q8_0.gguf",
    "chat_model": "gemma-3-1b-it-UD-Q4_K_XL.gguf",
    "mcp_port": 8002,
}
```

---

## 5. DOCSTRING & COMMENT STYLE

### Module Docstring Pattern
```python
"""
RAG Orchestrator - Coordinates retrieval and LLM generation using llama-cpp-python.

Features:
- Automatic context injection from retrieved documents
- Support for disabling RAG via system message keyword
- Multi-model support (separate embedding and chat models)
- Streaming and non-streaming responses
- Symbolic memory integration (deterministic, auditable)
"""
```

### Class Docstring Pattern
```python
class RAGOrchestrator:
    """
    Orchestrates RAG pipeline: retrieval + LLM generation.
    
    Usage:
        orchestrator = RAGOrchestrator(config_path="./configs/rag_config.json")
        response = orchestrator.chat(
            messages=[{"role": "user", "content": "How does auth work?"}]
        )
    """
```

### Method Docstring Pattern
```python
def setup_logging(
    self,
    level: Optional[str] = None,
    log_file: Optional[str] = None,
    debug_flag: bool = False,
    config_file: Optional[str] = None
) -> None:
    """
    Configure root logging with environment detection.

    Log Level Priority:
    1. debug_flag (if True, always DEBUG)
    2. LOG_LEVEL environment variable
    3. Config file (if provided)
    4. Environment detection (dev: DEBUG, prod: INFO)
    5. Default: INFO

    Args:
        level: Optional explicit log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_file: Optional path to log file
        debug_flag: If True, force DEBUG level
        config_file: Optional path to logging config JSON file
    """
```

### Inline Comments
```python
# Priority 1: Debug flag (always wins)
if debug_flag:
    log_level = logging.DEBUG

# Validate numeric ranges
if config.get("chunk_size", 0) < 100:
    config["chunk_size"] = 100
```

---

## 6. CONFIGURATION MANAGEMENT

### Configuration Priority (Lowest to Highest)
1. **Defaults** (`synapse/config/defaults.py`)
2. **User config** (`~/.synapse/config.json`)
3. **Project config** (`.synapse/config.json`)
4. **Environment variables** (`SYNDROME_*`)
5. **CLI arguments** (Highest priority)

### Configuration File Pattern
```json
{
  "logging": {
    "enabled": true,
    "level": "INFO",
    "format": "standard"
  },
  "rag_enabled": true,
  "chunk_size": 500,
  "chunk_overlap": 50,
  "top_k": 3,
  "embedding_model_path": "/path/to/model.gguf",
  "chat_model_path": "/path/to/chat.gguf",
  "mcp_port": 8002
}
```

### Environment Variable Pattern
```bash
SYNDROME_DATA_DIR
SYNDROME_MODELS_DIR
SYNDROME_MCP_PORT
SYNDROME_CHUNK_SIZE
SYNDROME_TOP_K
LOG_LEVEL
```

---

## 7. KEY PATTERNS & CONVENTIONS SUMMARY

| Aspect | Convention |
|--------|-----------|
| Python Files | snake_case |
| Class Names | PascalCase |
| Functions/Variables | snake_case |
| Constants | UPPER_SNAKE_CASE |
| Private Members | Leading underscore `_` |
| Imports | Relative for internal, absolute for external |
| Type Hints | Full typing with `typing` module |
| Docstrings | Google/NumPy style with Features list |
| Error Handling | Try-except with logging |
| Logging | Module-level logger via `get_logger(__name__)` |
| Async | `async`/`await` with `asyncio.gather()` |
| Configuration | JSON files + environment overrides |

---

## 8. TESTING PATTERNS

### Test File Naming
- Unit tests: `tests/unit/rag/test_retriever.py`
- Integration tests: `tests/integration/test_*.py`
- Fixtures: `tests/fixtures/`
- Global config: `tests/conftest.py`

### Test Patterns
```python
@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """Global test environment setup."""
    os.environ["RAG_TEST_MODE"] = "true"
    yield
    # Cleanup
    pass
```

---

## 9. MEMORY SYSTEM CONCEPTS

### Memory Authority Hierarchy (ENFORCED)
1. **SYMBOLIC MEMORY** - Authoritative (Highest Priority)
   - SQLite-based facts
   - Deterministic, auditable
   - Stored in `memory_store.py`

2. **EPISODIC MEMORY** - Advisory (Medium Priority)
   - SQLite-based episodes
   - Lessons learned from experience
   - Stored in `episodic_store.py`

3. **SEMANTIC MEMORY** - Non-authoritative (Lowest Priority)
   - Vector-based embeddings
   - Document chunks for retrieval
   - Stored in `semantic_store.py`

---

## 10. PROJECT-SPECIFIC TERMINOLOGY

| Term | Definition |
|------|------------|
| **SYNAPSE** | Main project name - "Your Data Meets Intelligence" |
| **RAG** | Retrieval-Augmented Generation |
| **MCP** | Model Context Protocol |
| **SDD** | Spec-Driven Development |
| **Orchestrator** | Main coordinator for RAG pipeline |
| **Memory Backend** | Stateless wrapper for memory operations |
| **Project** | Isolated memory namespace |
| **Auto-Learning** | Automatic extraction of facts/episodes |

---

*Report generated for RAG MCP memory ingestion*
*Project: synapse v1.3.0*
