"""
SYNAPSE Test Suite - Global Pytest Configuration

This file contains shared fixtures and configuration for all SYNAPSE tests.
Fixtures are auto-discovered by pytest and available in all test files.
"""

import os
import sys
import tempfile
import json
from pathlib import Path
from typing import Dict, List, Any, Generator, Optional
from datetime import datetime
import uuid

import pytest

# Add project root to path for imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# ============================================================================
# Environment Setup
# ============================================================================

@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """
    Global test environment setup.

    Ensures test mode is enabled for fast tests.
    """
    # Enable test mode for mock embeddings (fast tests)
    os.environ["SYNAPSE_TEST_MODE"] = "true"

    # Set test database paths
    os.environ["TEST_MODE"] = "true"

    yield

    # Cleanup after all tests
    pass


# ============================================================================
# Temporary Directory Fixtures
# ============================================================================

@pytest.fixture
def temp_dir(tmp_path: Path) -> Generator[Path, None, None]:
    """
    Provide a temporary directory that is automatically cleaned up.

    Args:
        tmp_path: Pytest's built-in temporary path fixture

    Yields:
        Path to temporary directory
    """
    yield tmp_path


@pytest.fixture
def temp_data_dir(tmp_path: Path) -> Generator[Path, None, None]:
    """
    Provide a temporary data directory with subdirectories.

    Creates:
    - data/
    - data/models/
    - data/rag_index/
    - data/docs/
    - data/logs/

    Args:
        tmp_path: Pytest's built-in temporary path fixture

    Yields:
        Path to temporary data directory
    """
    data_dir = tmp_path / "data"
    data_dir.mkdir()
    (data_dir / "models").mkdir()
    (data_dir / "rag_index").mkdir()
    (data_dir / "docs").mkdir()
    (data_dir / "logs").mkdir()

    yield data_dir


# ============================================================================
# Database Path Fixtures
# ============================================================================

@pytest.fixture
def test_db_path(temp_dir: Path) -> Path:
    """
    Provide a path to a test SQLite database.

    The database is created and cleaned up automatically.

    Args:
        temp_dir: Temporary directory fixture

    Returns:
        Path to test database file
    """
    return temp_dir / "test_memory.db"


@pytest.fixture
def test_memory_db_path(temp_dir: Path) -> Path:
    """
    Provide a path to a test memory database.

    Args:
        temp_dir: Temporary directory fixture

    Returns:
        Path to test memory database file
    """
    return temp_dir / "memory.db"


@pytest.fixture
def test_episodic_db_path(temp_dir: Path) -> Path:
    """
    Provide a path to a test episodic database.

    Args:
        temp_dir: Temporary directory fixture

    Returns:
        Path to test episodic database file
    """
    return temp_dir / "episodic.db"


# ============================================================================
# Configuration Path Fixtures
# ============================================================================

@pytest.fixture
def test_config_path(temp_dir: Path) -> Path:
    """
    Provide a path to a test configuration file.

    Creates a default test configuration.

    Args:
        temp_dir: Temporary directory fixture

    Returns:
        Path to test config file
    """
    config = {
        "rag_enabled": True,
        "chunk_size": 500,
        "chunk_overlap": 50,
        "top_k": 3,
        "min_retrieval_score": 0.3,
        "query_expansion_enabled": True,
        "num_expansions": 3,
        "index_path": str(temp_dir / "rag_index"),
        "docs_path": str(temp_dir / "docs"),
        "embedding_model_path": "test_model.gguf",
        "embedding_model_name": "test_embedding",
        "chat_model_path": "test_chat.gguf",
        "chat_model_name": "test_chat",
        "temperature": 0.7,
        "max_tokens": 2048,
        "memory_enabled": True,
        "memory_db_path": str(temp_dir / "memory.db"),
        "memory_scope": "session",
        "memory_min_confidence": 0.7,
        "memory_max_facts": 10,
    }

    config_path = temp_dir / "rag_config.json"
    config_path.write_text(json.dumps(config, indent=2))

    return config_path


# ============================================================================
# Mock Embedding Service Fixture
# ============================================================================

@pytest.fixture
def mock_embedding_service():
    """
    Mock embedding service for fast tests.

    Returns consistent mock embeddings without loading actual models.
    Mock embedding: [0.1, 0.1, 0.1, ...] (768 dimensions by default)
    """
    class MockEmbeddingService:
        """Mock embedding service."""

        def __init__(self, config_path: Optional[str] = None):
            self.embedding_dim = 768
            self.embed_count = 0

        def embed(self, texts: List[str]) -> List[List[float]]:
            """
            Generate mock embeddings.

            Args:
                texts: List of text strings

            Returns:
                List of embedding vectors
            """
            self.embed_count += len(texts)
            return [[0.1] * self.embedding_dim for _ in texts]

        def embed_single(self, text: str) -> List[float]:
            """
            Generate mock embedding for single text.

            Args:
                text: Text string

            Returns:
                Embedding vector
            """
            self.embed_count += 1
            return [0.1] * self.embedding_dim

    return MockEmbeddingService()


# ============================================================================
# Sample Documents Fixture
# ============================================================================

@pytest.fixture
def test_documents(temp_dir: Path) -> Dict[str, Path]:
    """
    Provide sample documents for testing.

    Creates:
    - README.md
    - config.json
    - example.py
    - documentation.md

    Args:
        temp_dir: Temporary directory fixture

    Returns:
        Dictionary mapping document names to paths
    """
    docs_dir = temp_dir / "docs"
    docs_dir.mkdir()

    # Create README.md
    readme_path = docs_dir / "README.md"
    readme_path.write_text("""# SYNAPSE RAG System

SYNAPSE is a local RAG system for AI agents.

## Features

- Semantic memory for document retrieval
- Episodic memory for agent learning
- Symbolic memory for facts and preferences

## Usage

Install and run:
```bash
pip install synapse
synapse start
```

## Configuration

Edit `configs/rag_config.json` to customize settings.
""")

    # Create config.json
    config_path = docs_dir / "config.json"
    config_path.write_text("""{
    "chunk_size": 500,
    "chunk_overlap": 50,
    "top_k": 3,
    "min_retrieval_score": 0.3
}""")

    # Create example.py
    example_path = docs_dir / "example.py"
    example_path.write_text("""
def authenticate(username: str, password: str) -> bool:
    \"\"\"
    Authenticate user with username and password.

    Uses OAuth2 for authentication.
    \"\"\"
    if not username or not password:
        return False

    # OAuth2 authentication
    token = get_oauth2_token(username, password)
    return verify_token(token)


def get_oauth2_token(username: str, password: str) -> str:
    \"\"\"Get OAuth2 token for user.\"\"\"
    # Implementation details...
    pass


def verify_token(token: str) -> bool:
    \"\"\"Verify OAuth2 token.\"\"\"
    # Implementation details...
    pass
""")

    # Create documentation.md
    docs_path = docs_dir / "documentation.md"
    docs_path.write_text("""
# Authentication Module

## Overview

The authentication module provides OAuth2-based user authentication.

## Functions

### authenticate(username, password)
Authenticates a user with username and password.

Returns:
- True if authentication successful
- False if authentication failed

### get_oauth2_token(username, password)
Retrieves OAuth2 token for a user.

### verify_token(token)
Verifies an OAuth2 token is valid.

## Example Usage

```python
from auth import authenticate

success = authenticate("user@example.com", "password123")
if success:
    print("Login successful!")
```
""")

    return {
        "readme": readme_path,
        "config": config_path,
        "example": example_path,
        "documentation": docs_path,
    }


# ============================================================================
# Sample Queries Fixture
# ============================================================================

@pytest.fixture
def test_queries() -> Dict[str, str]:
    """
    Provide sample queries for testing.

    Returns:
        Dictionary mapping query types to query strings
    """
    return {
        "fact_query": "What is the chunk size?",
        "code_query": "How does authentication work?",
        "concept_query": "What is the memory hierarchy?",
        "multi_hop_query": "How do I add a new model and use it for embedding?",
        "triple_hop_query": "What functions handle OAuth2 authentication and how do they work together?",
    }


# ============================================================================
# Sample Facts Fixture
# ============================================================================

@pytest.fixture
def test_facts() -> List[Dict[str, Any]]:
    """
    Provide sample memory facts for testing.

    Returns:
        List of fact dictionaries
    """
    return [
        {
            "id": str(uuid.uuid4()),
            "scope": "user",
            "category": "preference",
            "key": "theme",
            "value": "dark",
            "confidence": 0.9,
            "source": "user",
        },
        {
            "id": str(uuid.uuid4()),
            "scope": "project",
            "category": "fact",
            "key": "language",
            "value": "python",
            "confidence": 1.0,
            "source": "agent",
        },
        {
            "id": str(uuid.uuid4()),
            "scope": "project",
            "category": "constraint",
            "key": "max_chunk_size",
            "value": 1000,
            "confidence": 0.8,
            "source": "agent",
        },
    ]


# ============================================================================
# Sample Episodes Fixture
# ============================================================================

@pytest.fixture
def test_episodes() -> List[Dict[str, Any]]:
    """
    Provide sample episodes for testing.

    Returns:
        List of episode dictionaries
    """
    return [
        {
            "id": str(uuid.uuid4()),
            "situation": "User asked about authentication implementation",
            "action": "Retrieved OAuth2 documentation from semantic memory",
            "outcome": "success",
            "lesson": "OAuth2 is the preferred authentication method in this codebase",
            "confidence": 0.9,
            "lesson_type": "pattern",
            "quality": 0.9,
        },
        {
            "id": str(uuid.uuid4()),
            "situation": "Tried to use basic authentication",
            "action": "Attempted to implement basic auth",
            "outcome": "failure",
            "lesson": "Basic authentication is not supported, use OAuth2 instead",
            "confidence": 0.85,
            "lesson_type": "failure",
            "quality": 0.95,
        },
        {
            "id": str(uuid.uuid4()),
            "situation": "User requested Python code for authentication",
            "action": "Provided complete OAuth2 implementation example",
            "outcome": "success",
            "lesson": "Users appreciate complete, copy-pasteable code examples",
            "confidence": 0.8,
            "lesson_type": "success",
            "quality": 0.85,
        },
    ]


# ============================================================================
# Memory Store Fixtures
# ============================================================================

@pytest.fixture
def memory_store(test_db_path: Path):
    """
    Provide a MemoryStore instance for testing.

    The database is cleaned up automatically after the test.

    Args:
        test_db_path: Path to test database

    Returns:
        MemoryStore instance
    """
    from core.memory_store import get_memory_store

    store = get_memory_store(str(test_db_path))
    yield store

    # Cleanup
    if test_db_path.exists():
        test_db_path.unlink()


# ============================================================================
# Episodic Store Fixture
# ============================================================================

@pytest.fixture
def episodic_store(test_db_path: Path):
    """
    Provide an EpisodicStore instance for testing.

    The database is cleaned up automatically after the test.

    Args:
        test_db_path: Path to test database

    Returns:
        EpisodicStore instance
    """
    from core.episodic_store import get_episodic_store

    store = get_episodic_store(str(test_db_path))
    yield store

    # Cleanup
    if test_db_path.exists():
        test_db_path.unlink()


# ============================================================================
# Semantic Store Fixture
# ============================================================================

@pytest.fixture
def semantic_store(temp_dir: Path, mock_embedding_service):
    """
    Provide a SemanticStore instance for testing.

    Args:
        temp_dir: Temporary directory fixture
        mock_embedding_service: Mock embedding service

    Returns:
        SemanticStore instance
    """
    from core.semantic_store import get_semantic_store

    store = get_semantic_store(
        index_path=str(temp_dir / "semantic_index"),
        embedding_service=mock_embedding_service,
    )
    yield store

    # Cleanup is handled by SemanticStore's close method


# ============================================================================
# CLI Test Runner Fixture
# ============================================================================

@pytest.fixture
def cli_runner():
    """
    Provide a test runner for CLI commands.

    Returns:
        Function to run CLI commands
    """
    from click.testing import CliRunner

    runner = CliRunner(mix_stderr=False)

    def run_command(command_func, *args, **kwargs):
        """
        Run a CLI command.

        Args:
            command_func: Command function to run
            *args: Command arguments
            **kwargs: Additional arguments for invoke()

        Returns:
            Result object with exit_code, output, etc.
        """
        return runner.invoke(command_func, args, **kwargs)

    return run_command


# ============================================================================
# Assertion Helpers
# ============================================================================

@pytest.fixture
def assert_valid_uuid():
    """
    Helper to validate UUID strings.

    Returns:
        Function that raises AssertionError if invalid UUID
    """
    def _assert_valid_uuid(uuid_str: str, msg: Optional[str] = None):
        """
        Assert that a string is a valid UUID.

        Args:
            uuid_str: UUID string to validate
            msg: Optional error message

        Raises:
            AssertionError if invalid UUID
        """
        try:
            uuid.UUID(uuid_str)
        except ValueError:
            raise AssertionError(f"Invalid UUID: {uuid_str}. {msg or ''}")

    return _assert_valid_uuid


@pytest.fixture
def assert_valid_embedding():
    """
    Helper to validate embedding vectors.

    Returns:
        Function that raises AssertionError if invalid embedding
    """
    def _assert_valid_embedding(embedding: List[float], msg: Optional[str] = None):
        """
        Assert that a vector is a valid embedding.

        Args:
            embedding: Embedding vector to validate
            msg: Optional error message

        Raises:
            AssertionError if invalid embedding
        """
        assert isinstance(embedding, list), f"Embedding must be a list. {msg or ''}"
        assert len(embedding) > 0, f"Embedding must not be empty. {msg or ''}"
        assert all(isinstance(x, (int, float)) for x in embedding), \
            f"Embedding must contain numbers. {msg or ''}"
        assert all(0.0 <= x <= 1.0 for x in embedding), \
            f"Embedding values must be normalized [0, 1]. {msg or ''}"

    return _assert_valid_embedding


# ============================================================================
# Skip Conditions
# ============================================================================

def pytest_configure(config):
    """
    Configure pytest hooks.

    Skips tests marked with `requires_model` if model files are not available.
    """
    config.addinivalue_line(
        "markers", "requires_model: Tests requiring actual model files"
    )


def pytest_collection_modifyitems(config, items):
    """
    Modify test collection to skip model-dependent tests if needed.

    Tests marked with `@pytest.mark.requires_model` will be skipped
    if no model files are found.
    """
    skip_model = pytest.mark.skip(reason="Model files not available")

    # Check if we have model files
    models_dir = Path.home() / ".synapse" / "models"
    has_models = models_dir.exists() and any(models_dir.glob("*.gguf"))

    for item in items:
        if "requires_model" in item.keywords and not has_models:
            item.add_marker(skip_model)
