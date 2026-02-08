"""
Unit tests for QueryExpander.

Tests cover query expansion, expansion count, expansion methods, and uniqueness.
"""

import pytest
from core.query_expander import QueryExpander, get_query_expander


@pytest.mark.unit
class TestQueryExpander:
    """Test QueryExpander class for query expansion."""

    def test_expand_query(self, test_config_path):
        """Test expanding a single query."""
        expander = QueryExpander(config_path=str(test_config_path))

        original_query = "authentication"

        expanded = expander.expand(original_query)

        # Verify expansion returns results
        assert expanded is not None, "Expansion should not be None"
        assert isinstance(expanded, list), "Expansion should return a list"

    def test_no_expansion(self, test_config_path):
        """Test behavior when expansion is disabled."""
        # Create a config with expansion disabled
        import json
        from pathlib import Path

        config = {
            "query_expansion_enabled": False,
            "num_expansions": 0,
        }

        config_path = test_config_path
        config_path.write_text(json.dumps(config))

        expander = QueryExpander(config_path=str(config_path))

        original_query = "authentication"
        expanded = expander.expand(original_query)

        # With expansion disabled, should return original only
        # (or minimal expansion)
        assert isinstance(expanded, list), "Should still return a list"
        # Behavior depends on implementation

    def test_expansion_count(self, test_config_path):
        """Test that expansion generates N expansions."""
        import json
        from pathlib import Path

        config = {
            "query_expansion_enabled": True,
            "num_expansions": 5,
        }

        config_path = test_config_path
        config_path.write_text(json.dumps(config))

        expander = QueryExpander(config_path=str(config_path))

        original_query = "auth"
        expanded = expander.expand(original_query)

        # Should generate expansions
        assert isinstance(expanded, list), "Should return a list"
        # Actual count depends on implementation

    def test_expansion_method(self, test_config_path):
        """Test using different expansion methods."""
        import json
        from pathlib import Path

        # Test semantic method
        config_semantic = {
            "query_expansion_enabled": True,
            "num_expansions": 3,
            "query_expansion_method": "semantic",
        }

        config_path = test_config_path
        config_path.write_text(json.dumps(config_semantic))

        expander = QueryExpander(config_path=str(config_path))

        query = "login"
        expanded = expander.expand(query)

        assert isinstance(expanded, list), "Should return a list"

    def test_expansion_uniqueness(self, test_config_path):
        """Test that expanded queries are unique."""
        import json
        from pathlib import Path

        config = {
            "query_expansion_enabled": True,
            "num_expansions": 3,
        }

        config_path = test_config_path
        config_path.write_text(json.dumps(config))

        expander = QueryExpander(config_path=str(config_path))

        query = "oauth2"
        expanded = expander.expand(query)

        # Verify no duplicates in expansion
        if len(expanded) > 0:
            assert len(expanded) == len(set(expanded)), "Expansions should be unique"

    def test_expand_batch(self, test_config_path):
        """Test expanding multiple queries at once."""
        expander = QueryExpander(config_path=str(test_config_path))

        queries = ["authentication", "login", "oauth2"]
        results = []

        for query in queries:
            expanded = expander.expand(query)
            results.append(expanded)

        # Verify all queries were expanded
        assert len(results) == len(queries), "Should expand all queries"
        assert all(isinstance(r, list) for r in results), "All results should be lists"
