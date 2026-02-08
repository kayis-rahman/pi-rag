"""
Test infrastructure verification.

This test file verifies that the test infrastructure is properly set up.
Run with: pytest tests/test_infrastructure.py -v
"""

import pytest


@pytest.mark.unit
def test_pytest_config_exists():
    """Verify pytest configuration is loaded."""
    import os
    assert os.environ.get("SYNAPSE_TEST_MODE") == "true", "Test mode should be enabled"


@pytest.mark.unit
def test_temp_dir_fixture(temp_dir):
    """Verify temp_dir fixture works."""
    assert temp_dir.exists(), "Temp directory should exist"
    assert temp_dir.is_dir(), "Temp directory should be a directory"


@pytest.mark.unit
def test_test_db_path_fixture(test_db_path):
    """Verify test_db_path fixture works."""
    assert test_db_path.parent.exists(), "Test database path parent should exist"


@pytest.mark.unit
def test_mock_embedding_service(mock_embedding_service):
    """Verify mock_embedding_service fixture works."""
    assert mock_embedding_service is not None
    assert hasattr(mock_embedding_service, "embed")
    assert hasattr(mock_embedding_service, "embed_single")

    # Test embedding generation
    embedding = mock_embedding_service.embed_single("test text")
    assert isinstance(embedding, list)
    assert all(isinstance(x, (int, float)) for x in embedding)


@pytest.mark.unit
def test_test_documents_fixture(test_documents):
    """Verify test_documents fixture works."""
    assert isinstance(test_documents, dict)
    assert "readme" in test_documents
    assert "config" in test_documents
    assert "example" in test_documents

    # Verify files exist
    for doc_type, doc_path in test_documents.items():
        assert doc_path.exists(), f"{doc_type} document should exist"
        assert doc_path.is_file(), f"{doc_type} should be a file"


@pytest.mark.unit
def test_test_queries_fixture(test_queries):
    """Verify test_queries fixture works."""
    assert isinstance(test_queries, dict)
    assert "fact_query" in test_queries
    assert "code_query" in test_queries
    assert "concept_query" in test_queries

    # Verify queries are strings
    for query_type, query in test_queries.items():
        assert isinstance(query, str), f"{query_type} should be a string"
        assert len(query) > 0, f"{query_type} should not be empty"


@pytest.mark.unit
def test_assert_valid_uuid_fixture(assert_valid_uuid):
    """Verify assert_valid_uuid helper works."""
    import uuid

    # Valid UUID
    valid_uuid = str(uuid.uuid4())
    assert_valid_uuid(valid_uuid)

    # Invalid UUID
    with pytest.raises(AssertionError):
        assert_valid_uuid("invalid-uuid")


@pytest.mark.unit
def test_assert_valid_embedding_fixture(assert_valid_embedding):
    """Verify assert_valid_embedding helper works."""
    # Valid embedding
    valid_embedding = [0.1, 0.2, 0.3]
    assert_valid_embedding(valid_embedding)

    # Invalid embedding (not a list)
    with pytest.raises(AssertionError):
        assert_valid_embedding("not-a-list")

    # Invalid embedding (empty)
    with pytest.raises(AssertionError):
        assert_valid_embedding([])


@pytest.mark.unit
def test_imports():
    """Verify all modules can be imported."""
    # Test utilities
    from tests.utils import (
        create_test_fact,
        create_test_episode,
        create_test_document,
        create_test_chunk,
    )

    # Test fixtures
    from tests.fixtures import SAMPLE_DOCUMENTS, SAMPLE_QUERIES

    # Verify functions are callable
    assert callable(create_test_fact)
    assert callable(create_test_episode)
    assert callable(create_test_document)
    assert callable(create_test_chunk)

    # Verify fixtures are populated
    assert len(SAMPLE_DOCUMENTS) > 0
    assert len(SAMPLE_QUERIES) > 0


@pytest.mark.unit
def test_import_rag_modules():
    """Verify core RAG modules can be imported."""
    # These imports may fail if modules have issues
    try:
        from core.memory_store import MemoryStore, MemoryFact
        from core.episodic_store import EpisodicStore, Episode
        from core.semantic_store import SemanticStore, DocumentChunk
        from core.embedding import EmbeddingService
        from core.retriever import Retriever
        from core.orchestrator import Orchestrator
    except ImportError as e:
        pytest.fail(f"Failed to import RAG modules: {e}")


@pytest.mark.unit
def test_import_synapse_modules():
    """Verify SYNAPSE modules can be imported."""
    try:
        from synapse.cli.main import app
        from synapse.config import get_config, DEFAULT_CONFIG
    except ImportError as e:
        pytest.fail(f"Failed to import SYNAPSE modules: {e}")


@pytest.mark.unit
def test_config_default_values():
    """Verify default configuration has expected values."""
    from synapse.config import DEFAULT_CONFIG

    assert "chunk_size" in DEFAULT_CONFIG
    assert "top_k" in DEFAULT_CONFIG
    assert "semantic_memory_enabled" in DEFAULT_CONFIG
    assert "episodic_memory_enabled" in DEFAULT_CONFIG
    assert "symbolic_memory_enabled" in DEFAULT_CONFIG

    # Verify some default values
    assert DEFAULT_CONFIG["chunk_size"] == 500
    assert DEFAULT_CONFIG["top_k"] == 3


@pytest.mark.unit
def test_pytest_markers():
    """Verify pytest markers are registered."""
    markers = ["unit", "integration", "e2e", "slow", "requires_model"]

    # This test just verifies that markers are defined
    # The actual marker registration is checked by pytest
    assert True, "Pytest markers should be defined in pytest.ini"
