# SYNAPSE Test Suite

This directory contains comprehensive pytest tests for the SYNAPSE RAG system.

## Directory Structure

```
tests/
├── __init__.py           # Test package initialization
├── conftest.py           # Pytest fixtures and configuration (Phase 1)
├── unit/                 # Unit tests - isolated module testing (Phase 2)
│   ├── test_memory_store.py       # Symbolic memory tests
│   ├── test_episodic_store.py     # Episodic memory tests
│   ├── test_semantic_store.py    # Semantic memory tests
│   ├── test_embedding.py          # Embedding service tests
│   ├── test_retriever.py          # Retrieval system tests
│   ├── test_orchestrator.py       # RAG orchestration tests
│   ├── test_model_manager.py      # Model management tests
│   ├── test_connection_pool.py    # Connection pool tests
│   ├── test_query_expander.py     # Query expansion tests
│   ├── test_prompt_builder.py     # Prompt builder tests
│   ├── test_memory_reader.py      # Memory reader tests
│   ├── test_memory_writer.py      # Memory writer tests
│   ├── test_chunking.py           # Text chunking tests
│   └── test_config.py            # Configuration tests
├── integration/          # Integration tests - cross-module testing (Phase 3)
│   ├── test_memory_integration.py  # 3-tier memory integration
│   ├── test_rag_pipeline.py       # Full RAG pipeline
│   ├── test_mcp_server.py        # MCP server integration
│   └── test_cli_integration.py    # CLI commands integration
├── e2e/                  # End-to-end tests - complete workflows (Phase 4)
│   ├── test_cli_workflows.py      # User workflows
│   └── test_mcp_integration.py   # MCP client integration
├── fixtures/             # Test fixtures and sample data
│   ├── sample_documents.py         # Sample documents for testing
│   └── sample_queries.py         # Sample queries for testing
└── utils/                # Test helper functions
    ├── __init__.py               # Utility functions
    └── assertions.py             # Custom assertion helpers
```

## Test Phases

### Phase 1: Foundation & Test Infrastructure (Week 1)
- Setup pytest configuration
- Create shared fixtures in `conftest.py`
- Set up test utilities and helpers
- Configure CI/CD pipeline

### Phase 2: Unit Tests (Weeks 2-4)
- Test individual modules in isolation
- Target: 100+ tests, 70%+ coverage
- Focus on critical modules (memory stores, embedding, orchestrator)

### Phase 3: Integration Tests (Weeks 5-6)
- Test cross-module interactions
- Verify 3-tier memory integration
- Test full RAG pipeline
- Test MCP server and CLI commands

### Phase 4: End-to-End Tests (Weeks 7-8)
- Test complete user workflows
- Performance benchmarking
- Test documentation

## Running Tests

### Basic Commands

```bash
# Run all tests
pytest

# Run unit tests only (fast)
pytest -m unit

# Run integration tests only
pytest -m integration

# Run e2e tests only (slowest)
pytest -m e2e

# Run with coverage report
pytest --cov=rag --cov=synapse --cov=mcp_server --cov-report=html

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/unit/test_memory_store.py

# Run specific test
pytest tests/unit/test_memory_store.py::test_add_fact

# Skip slow tests
pytest -m "not slow"
```

### Test Mode for Fast Execution

```bash
# Use mock embeddings for fast tests (no model loading)
SYNAPSE_TEST_MODE=true pytest
```

### Coverage Reports

```bash
# Generate HTML coverage report
pytest --cov=rag --cov=synapse --cov=mcp_server --cov-report=html

# View coverage report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
start htmlcov/index.html  # Windows
```

## Test Markers

Tests are categorized using pytest markers:

- `@pytest.mark.unit` - Fast, isolated unit tests
- `@pytest.mark.integration` - Cross-module integration tests
- `@pytest.mark.e2e` - End-to-end workflow tests
- `@pytest.mark.slow` - Tests taking >1 second
- `@pytest.mark.requires_model` - Tests requiring actual model files

## Test Fixtures

Key fixtures defined in `conftest.py`:

### Global Fixtures
- `temp_dir` - Temporary directory for test data
- `test_db_path` - Path to test SQLite database
- `test_config_path` - Path to test config file

### Service Fixtures
- `mock_embedding_service` - Mock embedding service for fast tests
- `memory_store` - Symbolic memory store instance
- `episodic_store` - Episodic memory store instance
- `semantic_store` - Semantic memory store instance

### Data Fixtures
- `test_documents` - Sample documents for testing
- `test_queries` - Sample queries for testing
- `test_facts` - Sample facts for testing
- `test_episodes` - Sample episodes for testing

## Coverage Targets

| Module Type | Target Coverage | Status |
|-------------|-----------------|--------|
| Symbolic Memory | 80%+ | ⏳ Pending |
| Episodic Memory | 80%+ | ⏳ Pending |
| Semantic Memory | 80%+ | ⏳ Pending |
| Embedding Service | 80%+ | ⏳ Pending |
| RAG Orchestrator | 80%+ | ⏳ Pending |
| Overall | 70%+ | ⏳ Pending |

## Test Data

### Sample Documents
- Markdown files (README, docs)
- Python source files
- JSON configuration files
- Plain text files

### Sample Queries
- Fact queries (configuration, settings)
- Code queries (functions, classes)
- Concept queries (architecture, design)
- Multi-hop queries (complex workflows)

## CI/CD Integration

Tests run automatically on:
- Push to `main` branch
- Pull requests
- Manual workflow dispatch

GitHub Actions workflow: `.github/workflows/test.yml`

## Writing New Tests

### Unit Test Template

```python
import pytest
from core.memory_store import MemoryStore, MemoryFact

@pytest.mark.unit
class TestMemoryStore:
    """Test MemoryStore class."""

    def test_add_fact(self, memory_store):
        """Test adding a fact."""
        fact = MemoryFact(
            scope="user",
            category="preference",
            key="theme",
            value="dark",
            confidence=0.9
        )
        result = memory_store.add_fact(fact)
        assert result is not None

    # ... more tests
```

### Integration Test Template

```python
import pytest
from core.orchestrator import Orchestrator

@pytest.mark.integration
class TestRAGPipeline:
    """Test RAG pipeline integration."""

    def test_ingest_retrieve_generate(self, temp_dir, mock_embedding_service):
        """Test full RAG workflow."""
        orchestrator = Orchestrator(config_path=str(temp_dir / "config.json"))
        # ... test implementation
```

### E2E Test Template

```python
import pytest
import subprocess

@pytest.mark.e2e
class TestCLIWorkflows:
    """Test complete CLI workflows."""

    def test_first_time_setup(self):
        """Test fresh install and setup."""
        result = subprocess.run(
            ["synapse", "setup", "--offline"],
            capture_output=True,
            timeout=30
        )
        assert result.returncode == 0
```

## Troubleshooting

### Tests failing with model loading errors
```bash
# Enable test mode to use mock embeddings
SYNAPSE_TEST_MODE=true pytest
```

### Coverage report not generating
```bash
# Install pytest-cov if missing
pip install pytest-cov
```

### Tests running slowly
```bash
# Run only unit tests (fastest)
pytest -m unit

# Skip slow tests
pytest -m "not slow"
```

### Database errors during tests
```bash
# Clean up test databases
rm -rf tests/test_dbs/
```

## Documentation

- Detailed implementation plan: `spec/test_implementation_plan.md`
- Test summary: `spec/TEST_SUMMARY.md`
- Problems and gaps: `spec/problems_and_gaps.md` (mentions missing tests)

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Pytest-Cov Documentation](https://pytest-cov.readthedocs.io/)
- [Python Testing Best Practices](https://docs.python-guide.org/writing/tests/)

---

**Status**: Infrastructure ready, awaiting Phase 1 implementation
**Last Updated**: January 4, 2026
