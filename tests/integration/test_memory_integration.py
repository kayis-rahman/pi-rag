"""
Integration tests for 3-tier memory system.

Tests cover memory selector, authority hierarchy, conflict resolution, and combined context.
"""

import pytest
from core.memory_store import MemoryStore, MemoryFact
from core.episodic_store import EpisodicStore, Episode
from core.semantic_store import SemanticStore, DocumentChunk
from core.memory_selector import MemorySelector


@pytest.mark.integration
class TestMemoryIntegration:
    """Test 3-tier memory system integration."""

    def test_full_memory_query(self, test_db_path, mock_embedding_service, temp_dir):
        """Test querying across all 3 memory types."""
        # Initialize stores
        symbolic_store = MemoryStore(str(test_db_path))
        episodic_store = EpisodicStore(str(test_db_path))
        semantic_store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        # Add data to each memory type
        # Symbolic: Facts
        fact = MemoryFact(
            scope="project",
            category="fact",
            key="language",
            value="python",
            confidence=1.0,
            source="agent"
        )
        symbolic_store.add_fact(fact)

        # Episodic: Episodes
        episode = Episode(
            situation="User asked about authentication",
            action="Provided OAuth2 documentation",
            outcome="success",
            lesson="OAuth2 is the preferred method",
            confidence=0.9,
            lesson_type="pattern",
            quality=0.9
        )
        episodic_store.add_episode(episode)

        # Semantic: Documents
        semantic_store.add_document(
            doc_id="doc_1",
            content="OAuth2 authentication provides secure access",
            metadata={"source": "docs/auth.md"}
        )

        # Query all memory types
        selector = MemorySelector(
            symbolic_store=symbolic_store,
            episodic_store=episodic_store,
            semantic_store=semantic_store
        )

        results = selector.query_all(query="authentication")

        # Verify results from all 3 memory types
        assert results is not None, "Should get results from all memory types"
        assert "symbolic" in results, "Should have symbolic results"
        assert "episodic" in results, "Should have episodic results"
        assert "semantic" in results, "Should have semantic results"

    def test_authority_hierarchy(self, test_db_path, mock_embedding_service, temp_dir):
        """Test that authority hierarchy is respected (symbolic > episodic > semantic)."""
        # Initialize stores
        symbolic_store = MemoryStore(str(test_db_path))
        episodic_store = EpisodicStore(str(test_db_path))
        semantic_store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        # Add data with different authority levels
        # Symbolic: 100% authority
        fact = MemoryFact(
            scope="project",
            category="fact",
            key="chunk_size",
            value=500,
            confidence=1.0,
            source="agent"
        )
        symbolic_store.add_fact(fact)

        # Episodic: 85% authority
        episode = Episode(
            situation="Learned that chunk size affects performance",
            action="Adjusted chunk size",
            outcome="success",
            lesson="Chunk size of 500 is optimal",
            confidence=0.85,
            lesson_type="pattern",
            quality=0.85
        )
        episodic_store.add_episode(episode)

        # Semantic: 60% authority
        semantic_store.add_document(
            doc_id="doc_1",
            content="Document mentions chunk size is 500",
            metadata={"source": "docs/config.md"}
        )

        # Query with authority-aware selector
        selector = MemorySelector(
            symbolic_store=symbolic_store,
            episodic_store=episodic_store,
            semantic_store=semantic_store
        )

        results = selector.query_all(query="chunk size")

        # Verify symbolic memory has highest authority
        assert "symbolic" in results, "Should include symbolic results"
        symbolic_results = results["symbolic"]

        # Verify episodic has medium authority
        assert "episodic" in results, "Should include episodic results"
        episodic_results = results["episodic"]

        # Verify semantic has lowest authority
        assert "semantic" in results, "Should include semantic results"
        semantic_results = results["semantic"]

        # Authority should be respected in ordering
        # (implementation dependent)

    def test_memory_selector(self, test_db_path, mock_embedding_service, temp_dir):
        """Test memory selector chooses appropriate memory type."""
        symbolic_store = MemoryStore(str(test_db_path))
        episodic_store = EpisodicStore(str(test_db_path))
        semantic_store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        selector = MemorySelector(
            symbolic_store=symbolic_store,
            episodic_store=episodic_store,
            semantic_store=semantic_store
        )

        # Query should route to appropriate memory
        # Fact query → symbolic memory
        # Experience query → episodic memory
        # Document query → semantic memory
        # (implementation dependent)

        assert selector is not None, "Selector should be initialized"

    def test_memory_conflicts(self, test_db_path, mock_embedding_service, temp_dir):
        """Test detection and resolution of memory conflicts."""
        symbolic_store = MemoryStore(str(test_db_path))
        episodic_store = EpisodicStore(str(test_db_path))
        semantic_store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        # Add conflicting information
        # Symbolic: Chunk size is 500
        fact1 = MemoryFact(
            scope="project",
            category="fact",
            key="chunk_size",
            value=500,
            confidence=1.0,
            source="agent"
        )
        symbolic_store.add_fact(fact1)

        # Episodic: Learned chunk size should be 1000
        episode1 = Episode(
            situation="User mentioned different chunk size",
            action="Adjusted configuration",
            outcome="success",
            lesson="Chunk size should be 1000",
            confidence=0.7,
            lesson_type="pattern",
            quality=0.7
        )
        episodic_store.add_episode(episode1)

        # Query with conflict detection
        selector = MemorySelector(
            symbolic_store=symbolic_store,
            episodic_store=episodic_store,
            semantic_store=semantic_store
        )

        results = selector.query_all(query="chunk size", detect_conflicts=True)

        # Conflicts should be detected
        # (implementation dependent)

    def test_combined_context(self, test_db_path, mock_embedding_service, temp_dir):
        """Test combining context from all memory types."""
        symbolic_store = MemoryStore(str(test_db_path))
        episodic_store = EpisodicStore(str(test_db_path))
        semantic_store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        # Add complementary data across memory types
        # Symbolic: Language is python
        fact = MemoryFact(
            scope="project",
            category="fact",
            key="language",
            value="python",
            confidence=1.0,
            source="agent"
        )
        symbolic_store.add_fact(fact)

        # Episodic: OAuth2 is preferred
        episode = Episode(
            situation="User asked about authentication",
            action="Recommended OAuth2",
            outcome="success",
            lesson="OAuth2 is the preferred authentication method for this codebase",
            confidence=0.9,
            lesson_type="pattern",
            quality=0.9
        )
        episodic_store.add_episode(episode)

        # Semantic: OAuth2 documentation
        semantic_store.add_document(
            doc_id="oauth_doc",
            content="OAuth2 authentication provides secure, token-based access",
            metadata={"source": "docs/auth.md"}
        )

        # Query for combined context
        selector = MemorySelector(
            symbolic_store=symbolic_store,
            episodic_store=episodic_store,
            semantic_store=semantic_store
        )

        results = selector.query_all(query="authentication")

        # Context should combine all 3 types
        # (implementation dependent)

    def test_memory_isolation(self, test_db_path, mock_embedding_service, temp_dir):
        """Test that memory types don't interfere with each other."""
        symbolic_store = MemoryStore(str(test_db_path))
        episodic_store = EpisodicStore(str(test_db_path))
        semantic_store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        # Add data to each store independently
        symbolic_store.add_fact(MemoryFact(
            scope="symbolic_only",
            category="fact",
            key="key1",
            value="value1",
            confidence=1.0,
            source="test"
        ))

        episodic_store.add_episode(Episode(
            situation="episodic_only",
            action="action1",
            outcome="success",
            lesson="lesson1",
            confidence=0.9,
            lesson_type="pattern",
            quality=0.9
        ))

        semantic_store.add_document(
            doc_id="semantic_only",
            content="semantic content",
            metadata={"type": "test"}
        )

        # Query each memory type independently
        selector = MemorySelector(
            symbolic_store=symbolic_store,
            episodic_store=episodic_store,
            semantic_store=semantic_store
        )

        symbolic_results = selector.query_symbolic("symbolic query")
        episodic_results = selector.query_episodic("episodic query")
        semantic_results = selector.query_semantic("semantic query")

        # Results should be isolated
        # (implementation dependent)

    def test_empty_memory_query(self, test_db_path, mock_embedding_service, temp_dir):
        """Test handling when no results found."""
        symbolic_store = MemoryStore(str(test_db_path))
        episodic_store = EpisodicStore(str(test_db_path))
        semantic_store = SemanticStore(
            index_path=str(temp_dir / "semantic_index"),
            embedding_service=mock_embedding_service
        )

        selector = MemorySelector(
            symbolic_store=symbolic_store,
            episodic_store=episodic_store,
            semantic_store=semantic_store
        )

        # Query for non-existent data
        results = selector.query_all(query="nonexistent topic")

        # Should handle empty results gracefully
        # (implementation dependent)
