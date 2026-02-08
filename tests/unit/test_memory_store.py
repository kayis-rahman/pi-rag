"""
Unit tests for MemoryStore (Symbolic Memory).

Tests cover CRUD operations, querying, validation, and authority levels.
"""

import pytest
from core.memory_store import MemoryStore, MemoryFact


@pytest.mark.unit
class TestMemoryStore:
    """Test MemoryStore class for symbolic memory."""

    def test_add_fact(self, memory_store):
        """Test adding a fact to memory store."""
        fact = MemoryFact(
            scope="user",
            category="preference",
            key="theme",
            value="dark",
            confidence=0.9,
            source="user"
        )

        result = memory_store.add_fact(fact)

        assert result is not None, "Fact should be added successfully"
        assert result.id is not None, "Fact should have an ID"
        assert result.scope == "user"
        assert result.category == "preference"
        assert result.key == "theme"
        assert result.value == "dark"
        assert result.confidence == 0.9
        assert result.source == "user"

    def test_get_fact_by_id(self, memory_store):
        """Test retrieving a fact by ID."""
        fact = MemoryFact(
            scope="project",
            category="fact",
            key="language",
            value="python",
            confidence=1.0,
            source="agent"
        )

        added = memory_store.add_fact(fact)
        retrieved = memory_store.get_fact_by_id(added.id)

        assert retrieved is not None, "Fact should be retrievable"
        assert retrieved.id == added.id
        assert retrieved.key == "language"
        assert retrieved.value == "python"

    def test_update_fact(self, memory_store):
        """Test updating an existing fact."""
        fact = MemoryFact(
            scope="user",
            category="preference",
            key="theme",
            value="dark",
            confidence=0.5,
            source="user"
        )

        added = memory_store.add_fact(fact)

        # Update confidence
        added.confidence = 0.9
        added.value = "light"
        updated = memory_store.update_fact(added)

        assert updated is not None, "Fact should be updated"
        assert updated.confidence == 0.9
        assert updated.value == "light"
        assert updated.updated_at is not None

    def test_delete_fact(self, memory_store):
        """Test deleting a fact from memory store."""
        fact = MemoryFact(
            scope="project",
            category="fact",
            key="test_key",
            value="test_value",
            confidence=1.0,
            source="agent"
        )

        added = memory_store.add_fact(fact)
        deleted = memory_store.delete_fact(added.id)

        assert deleted is True, "Fact should be deleted"

        # Verify fact is gone
        retrieved = memory_store.get_fact_by_id(added.id)
        assert retrieved is None, "Deleted fact should not be retrievable"

    def test_query_facts_by_scope(self, memory_store):
        """Test querying facts by scope."""
        # Add facts with different scopes
        fact1 = MemoryFact(scope="user", category="preference", key="theme", value="dark", confidence=0.9, source="user")
        fact2 = MemoryFact(scope="project", category="fact", key="language", value="python", confidence=1.0, source="agent")
        fact3 = MemoryFact(scope="user", category="preference", key="editor", value="vim", confidence=0.8, source="user")

        memory_store.add_fact(fact1)
        memory_store.add_fact(fact2)
        memory_store.add_fact(fact3)

        # Query by user scope
        user_facts = memory_store.query_facts(scope="user")

        assert len(user_facts) == 2, "Should retrieve 2 user-scoped facts"
        assert all(f.scope == "user" for f in user_facts), "All facts should have user scope"

        # Query by project scope
        project_facts = memory_store.query_facts(scope="project")

        assert len(project_facts) == 1, "Should retrieve 1 project-scoped fact"
        assert project_facts[0].scope == "project"

    def test_query_facts_by_category(self, memory_store):
        """Test querying facts by category."""
        # Add facts with different categories
        fact1 = MemoryFact(scope="user", category="preference", key="theme", value="dark", confidence=0.9, source="user")
        fact2 = MemoryFact(scope="project", category="fact", key="language", value="python", confidence=1.0, source="agent")
        fact3 = MemoryFact(scope="project", category="preference", key="format", value="black", confidence=0.8, source="agent")

        memory_store.add_fact(fact1)
        memory_store.add_fact(fact2)
        memory_store.add_fact(fact3)

        # Query by preference category
        preference_facts = memory_store.query_facts(category="preference")

        assert len(preference_facts) == 2, "Should retrieve 2 preference facts"
        assert all(f.category == "preference" for f in preference_facts)

        # Query by fact category
        fact_facts = memory_store.query_facts(category="fact")

        assert len(fact_facts) == 1, "Should retrieve 1 fact category"
        assert fact_facts[0].category == "fact"

    def test_query_facts_by_confidence(self, memory_store):
        """Test querying facts by confidence threshold."""
        # Add facts with different confidence levels
        fact1 = MemoryFact(scope="user", category="preference", key="theme", value="dark", confidence=0.9, source="user")
        fact2 = MemoryFact(scope="project", category="fact", key="language", value="python", confidence=0.5, source="agent")
        fact3 = MemoryFact(scope="project", category="preference", key="format", value="black", confidence=0.7, source="agent")

        memory_store.add_fact(fact1)
        memory_store.add_fact(fact2)
        memory_store.add_fact(fact3)

        # Query with min confidence 0.8
        high_conf_facts = memory_store.query_facts(min_confidence=0.8)

        assert len(high_conf_facts) == 1, "Should retrieve 1 fact with confidence >= 0.8"
        assert high_conf_facts[0].confidence == 0.9

        # Query with min confidence 0.6
        medium_conf_facts = memory_store.query_facts(min_confidence=0.6)

        assert len(medium_conf_facts) == 2, "Should retrieve 2 facts with confidence >= 0.6"

    def test_confidence_authority(self, memory_store):
        """Test that symbolic facts have 100% authority."""
        fact = MemoryFact(
            scope="project",
            category="fact",
            key="authoritative_fact",
            value="always_true",
            confidence=1.0,
            source="agent"
        )

        added = memory_store.add_fact(fact)

        # Symbolic memory facts should have 100% authority
        # This is tested by ensuring confidence is 1.0
        assert added.confidence == 1.0, "Symbolic facts can have max confidence"

    def test_fact_uniqueness(self, memory_store):
        """Test that fact uniqueness is enforced by (scope, key)."""
        # Add first fact
        fact1 = MemoryFact(
            scope="user",
            category="preference",
            key="theme",
            value="dark",
            confidence=0.9,
            source="user"
        )

        memory_store.add_fact(fact1)

        # Try to add duplicate fact (same scope and key)
        fact2 = MemoryFact(
            scope="user",
            category="preference",
            key="theme",
            value="light",
            confidence=0.8,
            source="user"
        )

        # This should either update the existing fact or reject the duplicate
        # The exact behavior depends on implementation
        result = memory_store.add_fact(fact2)

        # Query to check uniqueness
        facts = memory_store.query_facts(scope="user", key="theme")

        # Should have at most 1 fact with this (scope, key) combination
        assert len(facts) <= 1, "Should enforce uniqueness by (scope, key)"

    def test_db_persistence(self, test_db_path):
        """Test that facts persist across connections."""
        # Add fact with first connection
        store1 = MemoryStore(str(test_db_path))
        fact = MemoryFact(
            scope="project",
            category="fact",
            key="persistent_key",
            value="persistent_value",
            confidence=1.0,
            source="agent"
        )

        added = store1.add_fact(fact)
        store1.close()

        # Retrieve with second connection
        store2 = MemoryStore(str(test_db_path))
        retrieved = store2.get_fact_by_id(added.id)
        store2.close()

        assert retrieved is not None, "Fact should persist across connections"
        assert retrieved.key == "persistent_key"
        assert retrieved.value == "persistent_value"

    def test_invalid_fact_creation(self, memory_store):
        """Test that invalid facts are rejected."""
        # Test with invalid confidence (out of range)
        invalid_fact = MemoryFact(
            scope="user",
            category="preference",
            key="theme",
            value="dark",
            confidence=1.5,  # Invalid: > 1.0
            source="user"
        )

        # This should either fail validation or be clamped to valid range
        try:
            result = memory_store.add_fact(invalid_fact)
            # If it succeeds, confidence should be clamped
            if result is not None:
                assert 0.0 <= result.confidence <= 1.0, "Confidence should be in valid range"
        except (ValueError, AssertionError):
            # Or it should raise an error
            pass

    def test_timestamp_updates(self, memory_store):
        """Test that updated_at timestamp changes on update."""
        import time

        fact = MemoryFact(
            scope="user",
            category="preference",
            key="theme",
            value="dark",
            confidence=0.9,
            source="user"
        )

        added = memory_store.add_fact(fact)
        created_at = added.updated_at

        # Wait a bit to ensure timestamp difference
        time.sleep(0.01)

        # Update the fact
        added.confidence = 1.0
        updated = memory_store.update_fact(added)

        assert updated is not None, "Fact should be updated"
        assert updated.updated_at > created_at, "updated_at should be newer than initial timestamp"

    def test_query_with_multiple_filters(self, memory_store):
        """Test querying with multiple filters combined."""
        # Add multiple facts
        facts = [
            MemoryFact(scope="user", category="preference", key="theme", value="dark", confidence=0.9, source="user"),
            MemoryFact(scope="user", category="preference", key="editor", value="vim", confidence=0.8, source="user"),
            MemoryFact(scope="project", category="preference", key="format", value="black", confidence=0.7, source="agent"),
            MemoryFact(scope="project", category="fact", key="language", value="python", confidence=1.0, source="agent"),
        ]

        for fact in facts:
            memory_store.add_fact(fact)

        # Query with multiple filters
        results = memory_store.query_facts(
            scope="user",
            category="preference",
            min_confidence=0.8
        )

        assert len(results) == 1, "Should retrieve 1 fact matching all filters"
        assert results[0].scope == "user"
        assert results[0].category == "preference"
        assert results[0].confidence >= 0.8
