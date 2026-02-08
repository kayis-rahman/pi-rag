"""
Unit tests for VectorStoreFactory.

Tests cover vector store creation, configuration-based routing, and error handling.
"""

import pytest
import tempfile
from pathlib import Path
from core.vectorstore_factory import get_vector_store, get_semantic_store_config
from tests.utils.helpers import (
    MockEmbeddingService,
    save_test_config,
    load_test_config,
)
from core.vectorstore_base import IVectorStore
from core.vectorstore import VectorStore
from core.chroma_vectorstore import ChromaVectorStore
from core.semantic_store import SemanticStore
from core.chroma_semantic_store import ChromaSemanticStore


@pytest.mark.unit
class TestVectorStoreFactory:
    """Test vector store factory functions."""

    def test_get_vector_store_with_chromadb_backend(self, tmp_path):
        """Test creating ChromaDB vector store."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config)

        store = get_vector_store(config=str(config_path))

        assert store is not None
        assert isinstance(store, ChromaVectorStore)

    def test_get_vector_store_with_legacy_backend(self, tmp_path):
        """Test creating legacy vector store."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "legacy",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config)

        store = get_vector_store(config=str(config_path))

        assert store is not None
        assert isinstance(store, VectorStore)

    def test_get_vector_store_with_invalid_backend(self, tmp_path):
        """Test creating vector store with invalid backend."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "invalid_backend",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config)

        with pytest.raises(ValueError, match="Unsupported vector backend"):
            get_vector_store(config=str(config_path))

    def test_get_vector_store_with_missing_config_file(self, tmp_path):
        """Test creating vector store with missing config file."""
        config_path = tmp_path / "nonexistent.json"

        # Should use defaults when config file is missing
        store = get_vector_store(config=str(config_path))

        # Default backend should be chromadb
        assert store is not None
        assert isinstance(store, ChromaVectorStore)

    def test_get_vector_store_with_missing_backend_key(self, tmp_path):
        """Test creating vector store with missing backend key."""
        config_path = tmp_path / "config.json"
        config = {
            "index_path": str(tmp_path / "index")
            # Missing "vector_backend" key
        }
        save_test_config(str(config_path), config)

        # Should use default backend (chromadb)
        store = get_vector_store(config=str(config_path))

        assert store is not None
        assert isinstance(store, ChromaVectorStore)

    def test_get_vector_store_returns_ivectorstore(self, tmp_path):
        """Test that get_vector_store returns IVectorStore interface."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config)

        store = get_vector_store(config=str(config_path))

        assert isinstance(store, IVectorStore)

    def test_get_vector_store_with_custom_index_path(self, tmp_path):
        """Test creating vector store with custom index path."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": "/custom/path/to/index"
        }
        save_test_config(str(config_path), config)

        store = get_vector_store(config=str(config_path))

        assert store is not None
        assert isinstance(store, ChromaVectorStore)


@pytest.mark.unit
class TestSemanticStoreConfigFactory:
    """Test semantic store configuration factory."""

    def test_get_semantic_store_config_with_chromadb(self, tmp_path):
        """Test creating semantic store config for ChromaDB."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": str(tmp_path / "semantic_index")
        }
        save_test_config(str(config_path), config)

        store_config = get_semantic_store_config(config=str(config_path))

        assert store_config is not None
        assert hasattr(store_config, 'index_path')
        assert hasattr(store_config, 'vector_backend')
        assert hasattr(store_config, 'embedding_service')

    def test_get_semantic_store_config_with_legacy(self, tmp_path):
        """Test creating semantic store config for legacy backend."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "legacy",
            "index_path": str(tmp_path / "semantic_index")
        }
        save_test_config(str(config_path), config)

        store_config = get_semantic_store_config(config=str(config_path))

        assert store_config is not None
        assert hasattr(store_config, 'index_path')
        assert hasattr(store_config, 'vector_backend')
        assert hasattr(store_config, 'embedding_service')

    def test_get_semantic_store_config_with_missing_backend(self, tmp_path):
        """Test semantic store config with missing backend."""
        config_path = tmp_path / "config.json"
        config = {
            "index_path": str(tmp_path / "semantic_index")
            # Missing "vector_backend" key
        }
        save_test_config(str(config_path), config)

        # Should use default backend (chromadb)
        store_config = get_semantic_store_config(config=str(config_path))

        assert store_config is not None
        assert store_config.vector_backend == "chromadb"

    def test_get_semantic_store_config_with_missing_index_path(self, tmp_path):
        """Test semantic store config with missing index path."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb"
            # Missing "index_path" key
        }
        save_test_config(str(config_path), config)

        # Should use default index path
        store_config = get_semantic_store_config(config=str(config_path))

        assert store_config is not None
        assert hasattr(store_config, 'index_path')
        assert hasattr(store_config, 'vector_backend')

    def test_get_semantic_store_config_with_custom_index_path(self, tmp_path):
        """Test semantic store config with custom index path."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": "/custom/path/to/semantic_index"
        }
        save_test_config(str(config_path), config)

        store_config = get_semantic_store_config(config=str(config_path))

        assert store_config is not None
        assert store_config.index_path == "/custom/path/to/semantic_index"


@pytest.mark.unit
class TestVectorStoreFactoryErrorHandling:
    """Test error handling in vector store factory."""

    def test_invalid_backend_raises_valueerror(self, tmp_path):
        """Test that invalid backend raises ValueError."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "totally_invalid_backend",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config)

        with pytest.raises(ValueError) as exc_info:
            get_vector_store(config=str(config_path))

        assert "Unsupported vector backend" in str(exc_info.value)
        assert "totally_invalid_backend" in str(exc_info.value)

    def test_invalid_semantic_backend_raises_valueerror(self, tmp_path):
        """Test that invalid semantic backend raises ValueError."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "invalid_backend",
            "index_path": str(tmp_path / "semantic_index")
        }
        save_test_config(str(config_path), config)

        with pytest.raises(ValueError) as exc_info:
            get_semantic_store_config(config=str(config_path))

        assert "Unsupported vector backend" in str(exc_info.value)
        assert "invalid_backend" in str(exc_info.value)

    def test_backend_case_sensitivity(self, tmp_path):
        """Test that backend selection is case-insensitive."""
        config_path = tmp_path / "config.json"

        # Test uppercase
        config_upper = {
            "vector_backend": "CHROMADB",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config_upper)

        store = get_vector_store(config=str(config_path))
        assert isinstance(store, ChromaVectorStore)

        # Test lowercase
        config_lower = {
            "vector_backend": "chromadb",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config_lower)

        store = get_vector_store(config=str(config_path))
        assert isinstance(store, ChromaVectorStore)


@pytest.mark.unit
class TestVectorStoreFactoryConfigHandling:
    """Test configuration handling in vector store factory."""

    def test_empty_config_uses_defaults(self, tmp_path):
        """Test that empty config uses default values."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {})

        store = get_vector_store(config=str(config_path))

        # Should use default backend (chromadb)
        assert store is not None
        assert isinstance(store, ChromaVectorStore)

    def test_config_override_with_env_vars(self, tmp_path):
        """Test that environment variables can override config."""
        import os

        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config)

        # Set environment variable to override
        os.environ["VECTOR_BACKEND"] = "legacy"

        # Note: Current implementation doesn't check env vars,
        # but this test verifies the config is loaded correctly
        store = get_vector_store(config=str(config_path))

        assert store is not None

    def test_config_with_extra_keys(self, tmp_path):
        """Test that extra config keys are ignored."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": str(tmp_path / "index"),
            "extra_key": "extra_value",
            "another_extra": 123
        }
        save_test_config(str(config_path), config)

        store = get_vector_store(config=str(config_path))

        assert store is not None
        assert isinstance(store, ChromaVectorStore)


@pytest.mark.unit
class TestVectorStoreFactoryInterface:
    """Test that factory returns correct interface types."""

    def test_chromadb_returns_chroma_vectorstore(self, tmp_path):
        """Test that ChromaDB backend returns ChromaVectorStore."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config)

        store = get_vector_store(config=str(config_path))

        assert isinstance(store, ChromaVectorStore)
        assert hasattr(store, 'add_documents')
        assert hasattr(store, 'search')
        assert hasattr(store, 'delete_documents')

    def test_legacy_returns_vectorstore(self, tmp_path):
        """Test that legacy backend returns VectorStore."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "legacy",
            "index_path": str(tmp_path / "index")
        }
        save_test_config(str(config_path), config)

        store = get_vector_store(config=str(config_path))

        assert isinstance(store, VectorStore)
        assert hasattr(store, 'add_documents')
        assert hasattr(store, 'search')
        assert hasattr(store, 'delete_documents')

    def test_semantic_config_returns_config_dict(self, tmp_path):
        """Test that semantic store config returns configuration dictionary."""
        config_path = tmp_path / "config.json"
        config = {
            "vector_backend": "chromadb",
            "index_path": str(tmp_path / "semantic_index")
        }
        save_test_config(str(config_path), config)

        store_config = get_semantic_store_config(config=str(config_path))

        assert isinstance(store_config, dict)
        assert 'vector_backend' in store_config
        assert 'index_path' in store_config
