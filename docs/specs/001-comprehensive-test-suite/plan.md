# Comprehensive Test Suite - Technical Plan

## Executive Summary

**Feature ID**: 001-comprehensive-test-suite
**Status**: Planning Phase
**Created**: January 4, 2026

This document defines the technical architecture and implementation details for building a comprehensive pytest test suite for SYNAPSE RAG system.

---

## Architecture Overview

### Test Suite Structure

```
tests/
├── conftest.py                 # Global pytest fixtures (already exists)
├── pytest.ini                   # Pytest configuration (already exists)
├── README.md                    # Test suite documentation
│
├── unit/                       # Unit tests - isolated module testing
│   ├── core/                    # RAG module tests (24 files)
│   │   ├── test_orchestrator.py
│   │   ├── test_vectorstore_factory.py
│   │   ├── test_memory_selector.py
│   │   ├── test_bulk_ingest.py
│   │   ├── test_memory_formatter.py
│   │   ├── test_query_cache.py
│   │   ├── test_episode_extractor.py
│   │   ├── test_episodic_reader.py
│   │   ├── test_semantic_ingest.py
│   │   ├── test_semantic_injector.py
│   │   ├── test_semantic_retriever.py
│   │   ├── test_chroma_vectorstore.py
│   │   ├── test_chroma_semantic_store.py
│   │   ├── test_vectorstore.py
│   │   └── test_vectorstore_base.py
│   │
│   ├── cli/                    # CLI command tests (8 files)
│   │   ├── test_cli_ingest.py
│   │   ├── test_cli_query.py
│   │   ├── test_cli_start.py
│   │   ├── test_cli_stop.py
│   │   ├── test_cli_status.py
│   │   ├── test_cli_models.py
│   │   ├── test_cli_setup.py
│   │   └── test_cli_onboard.py
│   │
│   ├── mcp_server/             # MCP server tests (6 files)
│   │   ├── test_mcp_rag_server.py
│   │   ├── test_mcp_http_wrapper.py
│   │   ├── test_mcp_project_manager.py
│   │   ├── test_mcp_chroma_manager.py
│   │   ├── test_mcp_metrics.py
│   │   └── test_mcp_logger.py
│   │
│   └── scripts/               # Script tests (2 files)
│       ├── test_script_bulk_ingest.py
│       └── test_script_migrate_chunks.py
│
├── integration/                # Integration tests - cross-module testing
│   ├── test_memory_integration.py      # (already exists)
│   ├── test_rag_pipeline.py            # (needs fixing)
│   ├── test_mcp_server.py             # (already exists)
│   ├── test_cli_integration.py          # (already exists)
│   ├── test_cross_module_rag_cli.py
│   ├── test_cross_module_mcp_rag.py
│   └── test_cross_module_memory_rag.py
│
├── e2e/                        # End-to-end tests - complete workflows
│   ├── workflows/
│   │   ├── test_first_time_setup.py       # (already exists)
│   │   ├── test_daily_development.py
│   │   └── test_mcp_client.py         # (already exists)
│   ├── performance/
│   │   ├── test_ingestion_performance.py
│   │   ├── test_query_performance.py
│   │   ├── test_memory_performance.py
│   │   └── test_server_performance.py
│   └── edge_cases/
│       ├── test_empty_state.py
│       ├── test_boundary_values.py
│       └── test_error_scenarios.py
│
├── fixtures/                   # Test fixtures and sample data
│   ├── documents/
│   │   ├── large_codebase/
│   │   ├── small_project/
│   │   └── edge_cases/
│   └── models/
│       └── mock_models/
│
└── utils/                      # Test helper functions
    ├── assertions.py
    ├── mocks.py
    └── generators.py
```

### Test Execution Flow

```
Developer commits code
         ↓
GitHub Actions triggered
         ↓
┌─────────────────────────────────────┐
│ Phase 1: Unit Tests (fast)      │
│ - pytest -m unit                 │
│ - Duration: <5 seconds           │
│ - Parallel execution enabled       │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ Phase 2: Integration Tests        │
│ - pytest -m integration           │
│ - Duration: <30 seconds         │
│ - Sequential execution            │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ Phase 3: E2E Tests (slow)       │
│ - pytest -m e2e                 │
│ - Duration: <60 seconds         │
│ - Sequential execution            │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ Coverage Report                   │
│ - pytest --cov                   │
│ - Upload to Codecov              │
│ - Block PR if coverage <70%      │
└─────────────────────────────────────┘
```

---

## Technology Stack

### Testing Framework
- **pytest**: Test framework (version 7.0+)
  - Features: Fixtures, parametrization, markers, plugins
  - Configuration: pytest.ini

### Coverage Tools
- **pytest-cov**: Coverage plugin (version 4.0+)
  - Features: Coverage tracking, HTML reports, threshold enforcement
  - Integration: Codecov upload

### Async Testing
- **pytest-asyncio**: Async test support (version 0.21+)
  - Features: async test functions, fixtures, event loop management

### Parallel Execution
- **pytest-xdist**: Parallel test execution (optional)
  - Features: Multi-process execution, load balancing
  - Configuration: `-n auto` flag

### Mocking Framework
- **unittest.mock**: Python built-in mocking
  - Features: Mock objects, patch decorators, side effects

### HTTP Testing
- **httpx**: HTTP client for testing
  - Features: Async HTTP requests, mock responses

### CLI Testing
- **typer.testing.CliRunner**: CLI testing framework
  - Features: Command invocation, output capture, exit code checking

---

## Data Schemas

### Test Factories

```python
# tests/utils/generators.py
class FactGenerator:
    """Generate test facts for memory store tests."""

    @staticmethod
    def create_test_fact(
        scope: str = "project",
        category: str = "fact",
        key: str = "test_key",
        value: Any = "test_value",
        confidence: float = 0.9,
        source: str = "test"
    ) -> MemoryFact:
        """Create a test fact with default values."""
        return MemoryFact(
            scope=scope,
            category=category,
            key=key,
            value=value,
            confidence=confidence,
            source=source
        )

    @staticmethod
    def create_random_facts(count: int = 10) -> List[MemoryFact]:
        """Create multiple random test facts."""
        return [FactGenerator.create_test_fact(
            key=f"fact_{i}",
            value=f"value_{i}"
        ) for i in range(count)]
```

### Episode Factories

```python
# tests/utils/generators.py
class EpisodeGenerator:
    """Generate test episodes for episodic store tests."""

    @staticmethod
    def create_test_episode(
        situation: str = "Test situation",
        action: str = "Test action",
        outcome: str = "success",
        lesson: str = "Test lesson",
        confidence: float = 0.9,
        lesson_type: str = "pattern",
        quality: float = 0.9
    ) -> Episode:
        """Create a test episode with default values."""
        return Episode(
            situation=situation,
            action=action,
            outcome=outcome,
            lesson=lesson,
            confidence=confidence,
            lesson_type=lesson_type,
            quality=quality
        )

    @staticmethod
    def create_random_episodes(count: int = 10) -> List[Episode]:
        """Create multiple random test episodes."""
        return [EpisodeGenerator.create_test_episode(
            situation=f"Situation {i}",
            lesson=f"Lesson {i}"
        ) for i in range(count)]
```

### Document Chunk Factories

```python
# tests/utils/generators.py
class DocumentChunkGenerator:
    """Generate test document chunks for semantic store tests."""

    @staticmethod
    def create_test_chunk(
        text: str = "Test text content",
        metadata: Dict[str, Any] = None
    ) -> DocumentChunk:
        """Create a test document chunk with default values."""
        return DocumentChunk(
            text=text,
            metadata=metadata or {},
            embedding=[0.1] * 768  # Mock embedding
        )

    @staticmethod
    def create_random_chunks(count: int = 10) -> List[DocumentChunk]:
        """Create multiple random test chunks."""
        return [DocumentChunkGenerator.create_test_chunk(
            text=f"Chunk text {i}",
            metadata={"chunk_id": i}
        ) for i in range(count)]
```

### Query Factories

```python
# tests/utils/generators.py
class QueryGenerator:
    """Generate test queries for retrieval tests."""

    @staticmethod
    def create_test_query(
        text: str = "Test query",
        top_k: int = 3,
        min_score: float = 0.3
    ) -> Dict[str, Any]:
        """Create a test query with default values."""
        return {
            "text": text,
            "top_k": top_k,
            "min_score": min_score
        }

    @staticmethod
    def create_test_queries() -> List[str]:
        """Create standard test queries."""
        return [
            "What is the chunk size?",
            "How does authentication work?",
            "What is the memory hierarchy?",
            "How do I add a new model?"
        ]
```

---

## Fixtures Architecture

### Global Fixtures (conftest.py)

```python
# tests/conftest.py
@pytest.fixture(scope="session")
def test_environment():
    """Set up test environment variables."""
    os.environ["RAG_TEST_MODE"] = "true"
    os.environ["TEST_MODE"] = "true"
    yield
    # Cleanup

@pytest.fixture
def temp_dir(tmp_path: Path) -> Path:
    """Provide temporary directory for test data."""
    yield tmp_path

@pytest.fixture
def temp_db_path(temp_dir: Path) -> Path:
    """Provide temporary database path."""
    return temp_dir / "test.db"

@pytest.fixture
def mock_embedding_service():
    """Mock embedding service for fast tests."""
    class MockEmbeddingService:
        def embed(self, texts: List[str]) -> List[List[float]]:
            return [[0.1] * 768 for _ in texts]

    return MockEmbeddingService()

@pytest.fixture
def memory_store(temp_db_path):
    """Provide memory store instance."""
    from core.memory_store import MemoryStore
    store = MemoryStore(str(temp_db_path))
    yield store
    # Cleanup

@pytest.fixture
def episodic_store(temp_db_path):
    """Provide episodic store instance."""
    from core.episodic_store import EpisodicStore
    store = EpisodicStore(str(temp_db_path))
    yield store
    # Cleanup

@pytest.fixture
def semantic_store(temp_dir, mock_embedding_service):
    """Provide semantic store instance."""
    from core.semantic_store import SemanticStore
    store = SemanticStore(
        index_path=str(temp_dir / "semantic_index"),
        embedding_service=mock_embedding_service
    )
    yield store
    # Cleanup

@pytest.fixture
def cli_runner():
    """Provide CLI test runner."""
    from typer.testing import CliRunner
    return CliRunner()
```

### Module-Specific Fixtures

```python
# tests/unit/core/conftest.py
@pytest.fixture
def orchestrator(temp_dir, mock_embedding_service):
    """Provide RAG orchestrator instance."""
    from core.orchestrator import RAGOrchestrator
    config_path = temp_dir / "test_config.json"
    # Create test config
    yield RAGOrchestrator(config_path=str(config_path))
    # Cleanup

@pytest.fixture
def vectorstore_factory():
    """Provide vector store factory."""
    from core.vectorstore_factory import get_vector_store
    return get_vector_store
```

---

## Test Patterns

### Unit Test Pattern

```python
import pytest
from core.memory_store import MemoryStore, MemoryFact

@pytest.mark.unit
class TestMemoryStore:
    """Test MemoryStore class for symbolic memory."""

    def test_add_fact(self, memory_store):
        """Test adding a fact to memory store."""
        # Arrange
        fact = MemoryFact(
            scope="user",
            category="preference",
            key="theme",
            value="dark",
            confidence=0.9,
            source="test"
        )

        # Act
        result = memory_store.add_fact(fact)

        # Assert
        assert result is not None
        assert result.id is not None
        assert result.scope == "user"
        assert result.value == "dark"

    def test_get_fact_by_id(self, memory_store):
        """Test retrieving a fact by ID."""
        # Arrange
        fact = FactGenerator.create_test_fact()
        added = memory_store.add_fact(fact)

        # Act
        retrieved = memory_store.get_fact_by_id(added.id)

        # Assert
        assert retrieved is not None
        assert retrieved.id == added.id
        assert retrieved.key == added.key
```

### Integration Test Pattern

```python
import pytest
from core.orchestrator import RAGOrchestrator
from core.memory_store import MemoryStore

@pytest.mark.integration
class TestRAGPipeline:
    """Test RAG pipeline integration."""

    def test_ingest_retrieve_generate(self, temp_dir, mock_embedding_service):
        """Test full RAG workflow."""
        # Arrange
        orchestrator = RAGOrchestrator(config_path=str(temp_dir / "config.json"))
        test_doc = "This is a test document about authentication."

        # Act
        # Ingest
        orchestrator.ingest_text(test_doc)

        # Retrieve
        results = orchestrator.retrieve("What is authentication?")

        # Generate
        response = orchestrator.chat(
            messages=[{"role": "user", "content": "What is authentication?"}]
        )

        # Assert
        assert len(results) > 0
        assert response is not None
        assert "authentication" in response.lower()
```

### E2E Test Pattern

```python
import pytest
import subprocess
from pathlib import Path

@pytest.mark.e2e
class TestCLIWorkflows:
    """Test complete CLI workflows."""

    def test_full_workflow(self, tmp_path):
        """Test complete workflow: setup → ingest → query."""
        # Setup
        test_project = tmp_path / "test_project"
        test_project.mkdir()
        (test_project / "test.md").write_text("# Test\nContent here.")

        # Act
        # Step 1: Setup
        setup_result = subprocess.run(
            ["synapse", "setup", "--offline"],
            capture_output=True,
            timeout=30
        )

        # Step 2: Ingest
        ingest_result = subprocess.run(
            ["synapse", "ingest", str(test_project)],
            capture_output=True,
            timeout=30
        )

        # Step 3: Query
        query_result = subprocess.run(
            ["synapse", "query", "what's in the test project?"],
            capture_output=True,
            timeout=30
        )

        # Assert
        assert setup_result.returncode == 0
        assert ingest_result.returncode == 0
        assert query_result.returncode == 0
```

---

## Mocking Strategy

### External Dependencies

```python
# Mock embedding service
@pytest.fixture
def mock_embedding_service():
    """Mock embedding service for fast tests."""
    class MockEmbeddingService:
        def embed(self, texts: List[str]) -> List[List[float]]:
            return [[0.1] * 768 for _ in texts]

    return MockEmbeddingService()

# Mock LLM service
@pytest.fixture
def mock_llm_service():
    """Mock LLM service for fast tests."""
    class MockLLMService:
        def generate(self, prompt: str) -> str:
            return f"Response to: {prompt[:50]}"

    return MockLLMService()

# Mock HTTP client
@pytest.fixture
def mock_http_client():
    """Mock HTTP client for MCP server tests."""
    import httpx

    client = httpx.MockTransport(
        handler=lambda request: httpx.Response(200, json={"result": "success"})
    )
    return client
```

### Database Mocking

```python
# Use in-memory SQLite for fast tests
@pytest.fixture
def in_memory_db():
    """Provide in-memory SQLite database."""
    import sqlite3
    conn = sqlite3.connect(":memory:")
    cursor = conn.cursor()

    # Create tables
    cursor.execute("CREATE TABLE facts (id INTEGER PRIMARY KEY, ...)")

    yield conn
    conn.close()
```

---

## Implementation Phases

### Phase 1: Fix Broken Tests (Week 1)

**Tasks**:
1. Fix syntax error in `test_memory_writer.py:9`
2. Fix import error in `test_prompt_builder.py`
3. Fix module not found error in `test_rag_pipeline.py`
4. Stabilize 57 failing unit tests
5. Ensure all 149 tests pass

**Approach**:
- Run tests with `-v` flag for verbose output
- Identify root causes of failures
- Fix imports, mocks, and assertions
- Add missing fixtures

**Success Criteria**:
- All 149 tests pass without errors
- Test suite runs in under 30 seconds

### Phase 2: Complete Unit Tests (Weeks 2-4)

**Tasks**:
1. Create RAG module tests (17 test files)
2. Create CLI command tests (8 test files)
3. Create MCP server tests (6 test file)
4. Create script tests (2 test files)
5. Achieve 70%+ coverage

**Approach**:
- Follow TDD pattern: Write test → Fail → Implement → Pass
- Use pytest parametrization for similar tests
- Create reusable fixtures and utilities
- Mock external dependencies (embedding, LLM, HTTP)

**Test Count Breakdown**:
- RAG modules: 24 test files × 10 tests = 240 tests
- CLI commands: 8 test files × 8 tests = 64 tests
- MCP server: 6 test files × 10 tests = 60 tests
- Scripts: 2 test files × 6 tests = 12 tests
- **Total**: 376 tests (target: 300+)

**Success Criteria**:
- 300+ unit tests implemented
- 70%+ overall coverage
- 80%+ coverage for critical modules
- All tests pass in under 2 minutes

### Phase 3: Complete Integration Tests (Weeks 5-6)

**Tasks**:
1. Expand memory integration tests
2. Create RAG pipeline integration tests
3. Expand MCP server integration tests
4. Expand CLI integration tests
5. Create cross-module integration tests

**Approach**:
- Test interactions between modules
- Test full workflows (end-to-end of component)
- Use real dependencies (not mocked)
- Focus on integration points and data flow

**Test Count Breakdown**:
- Memory integration: 10 tests
- RAG pipeline: 8 tests
- MCP server: 8 tests
- CLI integration: 10 tests
- Cross-module: 8 tests
- **Total**: 44 tests

**Success Criteria**:
- 40+ integration tests implemented
- All cross-module interactions tested
- Integration tests pass in under 30 seconds

### Phase 4: Complete E2E Tests (Weeks 7-8)

**Tasks**:
1. Create user workflow tests
2. Create performance benchmark tests
3. Create edge case tests
4. Create error scenario tests

**Approach**:
- Test complete user workflows
- Test error recovery paths
- Establish performance baselines
- Test boundary conditions

**Test Count Breakdown**:
- User workflows: 6 tests
- Performance benchmarks: 4 tests
- Edge cases: 4 tests
- Error scenarios: 4 tests
- **Total**: 18 tests

**Success Criteria**:
- 14+ E2E tests implemented
- All critical workflows tested
- Performance baselines established
- E2E tests pass in under 60 seconds

### Phase 5: Quality Gates (Ongoing)

**Tasks**:
1. Set up CI/CD pipeline
2. Configure coverage reporting
3. Implement PR blocking rules
4. Add test documentation

**Approach**:
- Use GitHub Actions for CI/CD
- Integrate with Codecov for coverage
- Block PRs if tests fail or coverage drops
- Document test suite in README

**Success Criteria**:
- All tests run on every push
- Coverage reports uploaded to Codecov
- PRs blocked if tests fail or coverage <70%
- Test suite documented

---

## Dependencies

### Python Dependencies

```txt
# requirements.txt (additions for testing)
pytest>=7.0.0
pytest-cov>=4.0.0
pytest-asyncio>=0.21.0
pytest-xdist>=3.0.0  # Optional for parallel execution
httpx>=0.27.0
typer>=0.12.0
```

### Internal Dependencies

- All RAG modules must be functional
- All CLI commands must be implemented
- All MCP server tools must be implemented
- Test fixtures must be defined

### External Services

- None (all tests use mocking or in-memory databases)

---

## Risk Assessment

### Risk 1: Test Maintenance Overhead
**Likelihood**: High
**Impact**: Medium
**Mitigation**:
- Write maintainable, self-documenting tests
- Use reusable fixtures and utilities
- Document test patterns in test suite README
- Focus on critical paths first

### Risk 2: Slow Test Execution
**Likelihood**: High
**Impact**: Medium
**Mitigation**:
- Use mocks for external services
- Run unit tests in parallel (pytest-xdist)
- Mark slow tests with @pytest.mark.slow marker
- Optimize test data and fixtures

### Risk 3: Flaky Tests
**Likelihood**: Medium
**Impact**: High
**Mitigation**:
- Use mocking for non-deterministic code
- Fix seed values in random operations
- Test in isolation (no shared state)
- Identify and eliminate race conditions

### Risk 4: Incomplete Coverage
**Likelihood**: Medium
**Impact**: High
**Mitigation**:
- Set coverage thresholds in CI/CD
- Review coverage reports regularly
- Focus on critical modules first
- Use coverage-guided testing (pytest-cov --cov-report=html)

---

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.9, 3.10, 3.11, 3.12]

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -e ".[dev]"

    - name: Run unit tests
      run: pytest -m unit --cov=rag --cov=synapse --cov=mcp_server

    - name: Run integration tests
      run: pytest -m integration

    - name: Run E2E tests
      run: pytest -m e2e

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage.xml
        flags: unittests
        name: codecov-umbrella
        fail_ci_if_error: true
```

### Coverage Thresholds

```ini
# pytest.ini (additions)
[coverage:run]
source = rag, synapse, mcp_server

[coverage:report]
precision = 2
show_missing = True
skip_covered = False

[coverage:fail_under]
rag = 80
synapse = 70
mcp_server = 70
total = 70
```

---

## Success Metrics

### Coverage Targets
| Module Type | Target Coverage | Success |
|-------------|-----------------|----------|
| Critical RAG Modules | 80%+ | ⏳ Pending |
| Standard RAG Modules | 70%+ | ⏳ Pending |
| CLI Commands | 70%+ | ⏳ Pending |
| MCP Server | 70%+ | ⏳ Pending |
| **Overall** | **70%+** | **⏳ Pending** |

### Test Count Targets
| Phase | Target Tests | Success |
|-------|--------------|----------|
| Unit Tests | 300+ | ⏳ Pending |
| Integration Tests | 40+ | ⏳ Pending |
| E2E Tests | 14+ | ⏳ Pending |
| **Total** | **354+** | **⏳ Pending** |

### Performance Targets
| Metric | Target | Success |
|--------|---------|----------|
| Unit test execution | <5s | ⏳ Pending |
| Integration test execution | <30s | ⏳ Pending |
| E2E test execution | <60s | ⏳ Pending |
| Full test suite | <2m | ⏳ Pending |

### Quality Targets
| Metric | Target | Success |
|--------|---------|----------|
| Flaky tests | 0% | ⏳ Pending |
| Passing tests on CI/CD | 100% | ⏳ Pending |
| Code review | Required | ⏳ Pending |

---

## Implementation Priority

### Priority 1: Critical (Week 1-2)
- Fix all broken tests
- Implement tests for RAG orchestrator
- Implement tests for memory selector
- Implement tests for vectorstore factory
- **Goal**: Ensure core RAG functionality is tested

### Priority 2: High (Week 2-4)
- Implement tests for all RAG modules
- Implement tests for CLI commands
- Implement tests for MCP server
- **Goal**: Achieve 70%+ coverage

### Priority 3: Medium (Week 5-6)
- Implement integration tests
- Test cross-module interactions
- **Goal**: Ensure modules work together

### Priority 4: Low (Week 7-8)
- Implement E2E tests
- Implement performance benchmarks
- **Goal**: Complete user workflows

---

## Definition of Done

A test is **done** when:
- [ ] Test file is created and committed
- [ ] All tests in file pass
- [ ] Test follows pytest conventions
- [ ] Test is documented (docstrings)
- [ ] Test is marked with appropriate marker
- [ ] Test achieves required coverage

The feature is **complete** when:
- [ ] All broken tests are fixed
- [ ] All unit tests are implemented (300+)
- [ ] All integration tests are implemented (40+)
- [ ] All E2E tests are implemented (14+)
- [ ] Overall coverage ≥70%
- [ ] All tests pass on CI/CD
- [ ] CI/CD pipeline is set up
- [ ] Documentation is updated
- [ ] Index.md is marked as [Completed]

---

**Document Status**: Ready for User Approval
**Next Step**: Present plan to user for approval before proceeding to task breakdown

**Questions for User**:
1. Does this technical plan meet expectations?
2. Should we adjust coverage targets?
3. Should we prioritize specific modules?
4. Any additional concerns or requirements?
