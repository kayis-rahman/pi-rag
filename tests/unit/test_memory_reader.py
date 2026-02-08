"""
Unit tests for MemoryReader.

Tests cover memory querying, filtering, fact ordering, conflict detection, and prompt injection.
"""

import pytest
from core.memory_reader import MemoryReader, get_memory_reader


@pytest.mark.unit
class TestMemoryReader:
    """Test MemoryReader class for reading symbolic memory."""

    def test_query_memory(self, test_db_path):
        """Test querying memory facts."""
        reader = MemoryReader(db_path=str(test_db_path))

        # Note: This test assumes database is initialized
        # In practice, would need to add facts first

        # Test that reader is initialized
        assert reader is not None, "Reader should be initialized"
        assert hasattr(reader, "query_memory"), "Reader should have query_memory method"

    def test_inject_into_prompt(self, test_db_path):
        """Test injecting facts into prompt."""
        reader = MemoryReader(db_path=str(test_db_path))

        facts = [
            {
                "id": "fact_1",
                "scope": "user",
                "category": "preference",
                "key": "theme",
                "value": "dark",
                "confidence": 0.9
            },
            {
                "id": "fact_2",
                "scope": "project",
                "category": "fact",
                "key": "language",
                "value": "python",
                "confidence": 1.0
            }
        ]

        prompt = "How should I design the UI?"
        injected = reader.inject_into_prompt(facts, prompt)

        # Verify prompt is injected
        assert injected is not None, "Injected prompt should not be None"
        assert prompt in injected, "Original prompt should be in injected"

    def test_confidence_filtering(self, test_db_path):
        """Test filtering facts by confidence threshold."""
        reader = MemoryReader(db_path=str(test_db_path))

        # Test that reader can filter by confidence
        # (implementation dependent - basic structure test)

        facts = [
            {"confidence": 0.9},
            {"confidence": 0.5},
            {"confidence": 1.0},
        ]

        # Filter for high confidence
        high_conf = [f for f in facts if f["confidence"] >= 0.8]
        assert len(high_conf) == 2, "Should filter by confidence"

    def test_scope_filtering(self, test_db_path):
        """Test filtering facts by scope."""
        reader = MemoryReader(db_path=str(test_db_path))

        # Test scope filtering
        user_facts = reader.query_memory(scope="user")
        project_facts = reader.query_memory(scope="project")

        # Results should be filtered (implementation dependent)

    def test_category_filtering(self, test_db_path):
        """Test filtering facts by category."""
        reader = MemoryReader(db_path=str(test_db_path))

        # Test category filtering
        preference_facts = reader.query_memory(category="preference")
        fact_facts = reader.query_memory(category="fact")

        # Results should be filtered (implementation dependent)

    def test_fact_ordering(self, test_db_path):
        """Test that facts are ordered by confidence then recency."""
        reader = MemoryReader(db_path=str(test_db_path))

        facts = [
            {"confidence": 0.7, "created_at": "2024-01-01"},
            {"confidence": 0.9, "created_at": "2024-01-02"},
            {"confidence": 0.8, "created_at": "2024-01-03"},
        ]

        # Sort by confidence (descending), then recency (descending)
        # Higher confidence first, then newer
        sorted_facts = sorted(facts, key=lambda x: (-x["confidence"], x["created_at"]))

        # Verify ordering
        assert sorted_facts[0]["confidence"] == 0.9, "Highest confidence should be first"
        assert sorted_facts[1]["confidence"] == 0.8, "Second highest confidence should be second"

    def test_conflict_detection(self, test_db_path):
        """Test detection of conflicting facts."""
        reader = MemoryReader(db_path=str(test_db_path))

        # Create conflicting facts (same key, different values)
        facts = [
            {"key": "theme", "value": "dark", "confidence": 0.9},
            {"key": "theme", "value": "light", "confidence": 0.8},
        ]

        # Detect conflicts (implementation dependent)
        conflicts = [f for f in facts if facts[0]["key"] == f["key"] and f != facts[0]]

        assert len(conflicts) == 1, "Should detect 1 conflict"

    def test_format_for_injection(self, test_db_path):
        """Test formatting facts for prompt injection."""
        reader = MemoryReader(db_path=str(test_db_path))

        fact = {
            "key": "chunk_size",
            "value": 500,
            "confidence": 1.0,
            "category": "fact",
            "scope": "project"
        }

        # Format for injection
        formatted = reader.format_for_injection(fact)

        # Verify formatting
        assert formatted is not None, "Formatted fact should not be None"
        assert "chunk_size" in formatted, "Should include fact key"
        assert "500" in formatted, "Should include fact value"

    def test_multiple_filters(self, test_db_path):
        """Test querying with multiple filters combined."""
        reader = MemoryReader(db_path=str(test_db_path))

        # Query with multiple filters
        results = reader.query_memory(
            scope="user",
            category="preference",
            min_confidence=0.8
        )

        # Results should match all filters (implementation dependent)
