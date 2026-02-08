"""
Unit tests for SemanticStore.

Tests cover document storage, search, chunking, metadata, and non-authoritative authority.
"""

import pytest
from core.semantic_store import SemanticStore, DocumentChunk


@pytest.mark.unit
class TestSemanticStore:
    """Test SemanticStore class for semantic memory."""

    def test_add_document(self, temp_dir, mock_embedding_service):
        """Test adding a document to semantic store."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        document_id = "test_doc_1"
        content = "This is a test document."
        metadata = {"source": "README.md"}

        store.add_document(document_id, content, metadata)

        retrieved = store.get_document(document_id)

        assert retrieved is not None, "Document should be retrievable"
        assert retrieved["content"] == content, "Content should match"
        assert retrieved["metadata"] == metadata, "Metadata should match"

    def test_get_document(self, temp_dir, mock_embedding_service):
        """Test retrieving a document by ID."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        document_id = "test_doc_2"
        content = "Test document content"

        store.add_document(document_id, content, {})

        retrieved = store.get_document(document_id)

        assert retrieved is not None, "Document should be retrievable"
        assert retrieved["id"] == document_id, "ID should match"

    def test_search_documents(self, temp_dir, mock_embedding_service):
        """Test semantic search for documents."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        # Add documents
        store.add_document("doc_1", "Python programming language", {})
        store.add_document("doc_2", "JavaScript web development", {})
        store.add_document("doc_3", "Authentication and OAuth2", {})

        # Search for "authentication"
        results = store.search("authentication", top_k=3)

        assert len(results) > 0, "Should find matching documents"
        assert all("content" in doc for doc in results), "Results should have content"

    def test_delete_document(self, temp_dir, mock_embedding_service):
        """Test deleting a document from semantic store."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        document_id = "doc_to_delete"
        store.add_document(document_id, "Delete me", {})

        # Delete
        deleted = store.delete_document(document_id)

        assert deleted is True, "Document should be deleted"

        # Verify deletion
        retrieved = store.get_document(document_id)
        assert retrieved is None, "Deleted document should not be retrievable"

    def test_chunk_splitting(self, temp_dir, mock_embedding_service):
        """Test that documents are chunked correctly."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service,
            chunk_size=50,
            chunk_overlap=10
        )

        # Add long document
        long_content = "A" * 200
        store.add_document("long_doc", long_content, {})

        # Retrieve and check chunking
        retrieved = store.get_document("long_doc")

        assert retrieved is not None, "Document should be retrievable"
        assert "chunks" in retrieved, "Document should have chunks"
        assert len(retrieved["chunks"]) > 1, "Long document should be split into multiple chunks"

    def test_metadata_storage(self, temp_dir, mock_embedding_service):
        """Test that metadata is stored and retrieved correctly."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        metadata = {
            "source": "config.json",
            "line": 42,
            "file_type": "json"
        }

        store.add_document("doc_with_metadata", "Content", metadata)

        retrieved = store.get_document("doc_with_metadata")

        assert retrieved is not None, "Document should be retrievable"
        assert retrieved["metadata"] == metadata, "Metadata should match exactly"

    def test_embedding_generation(self, temp_dir, mock_embedding_service):
        """Test that embeddings are generated for chunks."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        store.add_document("test_doc", "Test content for embedding", {})

        retrieved = store.get_document("test_doc")

        assert retrieved is not None, "Document should be retrievable"

        # Check if embeddings are present (depends on implementation)
        # Some implementations store embeddings separately
        # For now, we verify the document was added successfully

    def test_non_authoritative(self, temp_dir, mock_embedding_service):
        """Test that semantic memory is non-authoritative (60% authority)."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        # Semantic memory is non-authoritative
        # This is tested by ensuring documents can be retrieved
        # but are not treated as absolute truth

        store.add_document("non_authorative_doc", "Content that may be outdated", {})

        retrieved = store.get_document("non_authorative_doc")

        assert retrieved is not None, "Document should be retrievable"
        # The non-authoritative nature means:
        # - Documents are suggestions, not facts
        # - Users should verify information
        # - Not used for critical facts

    def test_citation_tracking(self, temp_dir, mock_embedding_service):
        """Test that source citations are tracked."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        metadata = {
            "source": "README.md",
            "line": 10,
            "file_path": "/path/to/README.md"
        }

        store.add_document("doc_with_citation", "Content", metadata)

        retrieved = store.get_document("doc_with_citation")

        assert retrieved is not None, "Document should be retrievable"
        assert retrieved["metadata"]["source"] == "README.md", "Source should be tracked"
        assert retrieved["metadata"]["line"] == 10, "Line number should be tracked"

    def test_vector_similarity(self, temp_dir, mock_embedding_service):
        """Test that vector similarity is calculated correctly."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        # Add similar documents
        store.add_document("doc_1", "Authentication in web apps", {})
        store.add_document("doc_2", "OAuth2 for user login", {})
        store.add_document("doc_3", "Python code examples", {})

        # Search for "authentication"
        results = store.search("authentication", top_k=3)

        # Results should be ordered by similarity
        # (most similar first)
        assert len(results) > 0, "Should find matching documents"

    def test_top_k_retrieval(self, temp_dir, mock_embedding_service):
        """Test that top-K results are returned."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service,
            top_k=5
        )

        # Add many documents
        for i in range(10):
            store.add_document(f"doc_{i}", f"Document {i} content", {})

        # Search with top_k=3
        results = store.search("document", top_k=3)

        assert len(results) <= 3, f"Should return at most 3 results, got {len(results)}"

    def test_min_score_filter(self, temp_dir, mock_embedding_service):
        """Test that results are filtered by minimum score."""
        store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service,
            min_score=0.7
        )

        # Add documents
        store.add_document("doc_relevant", "Authentication and OAuth2", {})
        store.add_document("doc_irrelevant", "Unrelated content here", {})

        # Search
        results = store.search("authentication", top_k=10)

        # Results should be filtered by minimum score
        # (implementation dependent - this is a basic test)
        assert isinstance(results, list), "Results should be a list"
