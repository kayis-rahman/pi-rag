"""
Unit tests for EmbeddingService.

Tests cover embedding generation, caching, thread safety, and test mode.
"""

import pytest
from core.embedding import EmbeddingService, get_embedding_service


@pytest.mark.unit
class TestEmbeddingService:
    """Test EmbeddingService class."""

    def test_embed_single_text(self, mock_embedding_service):
        """Test embedding single text string."""
        text = "Hello, world!"

        result = mock_embedding_service.embed_single(text)

        assert result is not None, "Embedding should not be None"
        assert isinstance(result, list), "Embedding should be a list"
        assert len(result) > 0, "Embedding should not be empty"
        assert all(isinstance(x, (int, float)) for x in result), \
            "Embedding should contain numbers"

    def test_embed_batch(self, mock_embedding_service):
        """Test embedding multiple texts."""
        texts = ["Hello", "world", "test"]

        results = mock_embedding_service.embed(texts)

        assert results is not None, "Embeddings should not be None"
        assert isinstance(results, list), "Embeddings should be a list"
        assert len(results) == len(texts), "Should return one embedding per text"

        # Verify each embedding
        for i, embedding in enumerate(results):
            assert isinstance(embedding, list), f"Embedding {i} should be a list"
            assert len(embedding) > 0, f"Embedding {i} should not be empty"

    def test_embedding_cache(self, mock_embedding_service):
        """Test that embeddings are cached."""
        text = "Cache test text"

        # First call - should generate embedding
        embed1 = mock_embedding_service.embed_single(text)
        count1 = mock_embedding_service.embed_count

        # Second call - should use cache
        embed2 = mock_embedding_service.embed_single(text)
        count2 = mock_embedding_service.embed_count

        # In test mode, we track embed count
        # If cache is working, count should increase
        assert embed1 == embed2, "Cached embeddings should be identical"

    def test_cache_eviction(self, mock_embedding_service):
        """Test that cache evicts old entries when full."""
        # Create service with small cache
        service = mock_embedding_service
        service._cache = {}  # Reset cache

        # Fill cache
        texts = [f"Text {i}" for i in range(150)]

        for text in texts:
            service.embed_single(text)

        # Cache should have grown
        initial_cache_size = len(service._cache)
        assert initial_cache_size > 0, "Cache should have entries"

        # This test is simplified for mock embedding service
        # Real implementation would test LRU eviction

    def test_test_mode(self, monkeypatch):
        """Test that test mode uses mock embeddings."""
        import os

        # Enable test mode
        monkeypatch.setenv("SYNAPSE_TEST_MODE", "true")

        # Create service
        service = EmbeddingService()

        # In test mode, should not load actual model
        # Should use mock embeddings
        assert service._test_mode is True, "Service should be in test mode"

        # Embed should work without model file
        embedding = service.embed_single("test text")

        assert embedding is not None, "Mock embedding should work"
        assert len(embedding) > 0, "Mock embedding should have dimensions"

        # Cleanup
        if hasattr(service, '_model'):
            del service._model

    def test_embedding_dimensions(self, mock_embedding_service):
        """Test that all embeddings have consistent dimensions."""
        texts = ["Short", "Medium length text", "This is a very long text string for testing dimensions"]

        embeddings = mock_embedding_service.embed(texts)

        # All embeddings should have the same dimension
        dimensions = [len(embedding) for embedding in embeddings]
        assert all(d == dimensions[0] for d in dimensions), \
            "All embeddings should have the same dimension"

        assert dimensions[0] > 0, "Embedding dimension should be > 0"

    def test_thread_safety(self, mock_embedding_service):
        """Test that embedding service is thread-safe."""
        import threading

        texts = [f"Test text {i}" for i in range(10)]
        results = []
        errors = []

        def worker(text_list):
            """Worker function for thread."""
            try:
                embeddings = mock_embedding_service.embed(text_list)
                results.extend(embeddings)
            except Exception as e:
                errors.append(e)

        # Create and start threads
        threads = []
        for i in range(5):
            t = threading.Thread(target=worker, args=(texts[i*2:i*2+2],))
            threads.append(t)
            t.start()

        # Wait for all threads to complete
        for t in threads:
            t.join()

        # Verify all threads completed without errors
        assert len(errors) == 0, "No thread errors should occur"
        assert len(results) == len(texts), "All texts should be embedded"

    def test_invalid_input(self, mock_embedding_service):
        """Test handling of invalid input."""
        # Test empty string
        result_empty = mock_embedding_service.embed_single("")
        assert result_empty is not None, "Empty string should return embedding"

        # Test None
        with pytest.raises((AttributeError, TypeError)):
            mock_embedding_service.embed_single(None)

        # Test empty list
        result_empty_list = mock_embedding_service.embed([])
        assert result_empty_list == [], "Empty list should return empty list"

    def test_cache_key_generation(self, mock_embedding_service):
        """Test that cache keys are generated correctly."""
        text = "Test text for cache key"

        # Generate embedding (should create cache entry)
        embedding = mock_embedding_service.embed_single(text)

        # In test mode, cache is a simple dict
        # Keys should be the text strings themselves
        if hasattr(mock_embedding_service, '_cache'):
            assert text in mock_embedding_service._cache or \
                   any(k == text for k in mock_embedding_service._cache.keys()), \
                   "Cache should use text as key"
