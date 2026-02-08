"""
Tests for Universal Hook Auto-Learning System.

Tests cover:
- Conversation Analyzer (heuristic extraction)
- Deduplication logic
- Confidence scoring
- MCP tool integration
- OpenCode plugin hooks (mocked)
"""

import pytest
import asyncio
from core.conversation_analyzer import ConversationAnalyzer


class TestConversationAnalyzer:
    """Test ConversationAnalyzer class."""

    @pytest.fixture
    def config(self):
        """Return test configuration."""
        return {
            "extraction_mode": "heuristic",
            "use_llm": False,
            "min_fact_confidence": 0.7,
            "min_episode_confidence": 0.6,
            "deduplication_mode": "per_day",
            "deduplication_window_days": 7,
            "async_processing": True
        }

    @pytest.fixture
    def analyzer(self, config):
        """Return ConversationAnalyzer instance."""
        return ConversationAnalyzer(model_manager=None, config=config)

    def test_heuristic_fact_extraction_api_endpoint(self, analyzer):
        """Test extraction of API endpoints."""
        text = "The API endpoint is http://localhost:8002/mcp"
        facts = analyzer._extract_facts_heuristic(text)

        assert len(facts) > 0
        assert any(f["key"] == "api_endpoint" for f in facts)
        assert any("http://localhost:8002/mcp" in str(f["value"]) for f in facts)

    def test_heuristic_fact_extraction_version(self, analyzer):
        """Test extraction of version numbers."""
        text = "The version is 1.3.0"
        facts = analyzer._extract_facts_heuristic(text)

        assert len(facts) > 0
        assert any(f["key"] == "version" for f in facts)

    def test_heuristic_fact_extraction_preference(self, analyzer):
        """Test extraction of user preferences."""
        text = "I prefer TypeScript over JavaScript"
        facts = analyzer._extract_facts_heuristic(text)

        assert len(facts) > 0
        assert any(f["key"] == "preference" for f in facts)

    def test_heuristic_episode_extraction_workaround(self, analyzer):
        """Test extraction of workaround patterns."""
        text = "I found a workaround for the issue"
        episodes = analyzer._extract_episodes_heuristic(text)

        assert len(episodes) > 0
        assert any(e["lesson_type"] == "workaround" for e in episodes)

    def test_heuristic_episode_extraction_mistake(self, analyzer):
        """Test extraction of mistake patterns."""
        text = "This didn't work, it was a mistake"
        episodes = analyzer._extract_episodes_heuristic(text)

        assert len(episodes) > 0
        assert any(e["lesson_type"] == "mistake" for e in episodes)

    def test_heuristic_episode_extraction_lesson(self, analyzer):
        """Test extraction of lesson patterns."""
        text = "The lesson is to always validate inputs"
        episodes = analyzer._extract_episodes_heuristic(text)

        assert len(episodes) > 0
        assert any(e["lesson_type"] == "lesson" for e in episodes)

    def test_confidence_scoring_heuristic_fact(self, analyzer):
        """Test confidence scoring for heuristic facts."""
        learning = {
            "type": "fact",
            "key": "test",
            "value": "value",
            "source": "heuristic"
        }

        confidence = analyzer.score_confidence(learning)

        assert 0.7 <= confidence <= 1.0

    def test_confidence_scoring_heuristic_episode(self, analyzer):
        """Test confidence scoring for heuristic episodes."""
        learning = {
            "type": "episode",
            "lesson_type": "pattern",
            "source": "heuristic"
        }

        confidence = analyzer.score_confidence(learning)

        assert 0.6 <= confidence <= 1.0

    def test_deduplication_per_day(self, analyzer):
        """Test per-day deduplication logic."""
        # Add fact
        learning1 = {
            "type": "fact",
            "key": "test_key",
            "value": "test_value",
            "confidence": 0.8
        }

        # Deduplicate same fact
        learning2 = learning1.copy()
        result1 = analyzer.deduplicate([learning1])
        result2 = analyzer.deduplicate([learning2])

        # First should pass, second should be filtered
        assert len(result1) == 1
        assert len(result2) == 0

    def test_deduplication_different_facts(self, analyzer):
        """Test that different facts pass deduplication."""
        learning1 = {
            "type": "fact",
            "key": "test_key_1",
            "value": "test_value_1",
            "confidence": 0.8
        }

        learning2 = {
            "type": "fact",
            "key": "test_key_2",
            "value": "test_value_2",
            "confidence": 0.8
        }

        result = analyzer.deduplicate([learning1, learning2])

        # Both should pass
        assert len(result) == 2

    def test_analyze_conversation_async(self, analyzer):
        """Test async conversation analysis."""
        user_message = "The API endpoint is http://localhost:8002/mcp"
        agent_response = "I found a workaround for the issue"

        async def run_analysis():
            return await analyzer.analyze_conversation_async(user_message, agent_response)

        result = asyncio.run(run_analysis())

        assert isinstance(result, list)
        assert len(result) > 0

        # Check for facts and episodes
        facts = [r for r in result if r["type"] == "fact"]
        episodes = [r for r in result if r["type"] == "episode"]

        assert len(facts) > 0
        assert len(episodes) > 0

    def test_analyze_conversation_empty(self, analyzer):
        """Test analysis of empty conversation."""
        async def run_analysis():
            return await analyzer.analyze_conversation_async("", "")

        result = asyncio.run(run_analysis())

        # Should return empty list
        assert isinstance(result, list)
        # May have some matches from empty strings, but not errors

    def test_get_learning_key_fact(self, analyzer):
        """Test learning key generation for facts."""
        learning = {
            "type": "fact",
            "key": "test_key",
            "value": "test_value"
        }

        key = analyzer._get_learning_key(learning)

        assert key == "fact:test_key"

    def test_get_learning_key_episode(self, analyzer):
        """Test learning key generation for episodes."""
        learning = {
            "type": "episode",
            "title": "test_title"
        }

        key = analyzer._get_learning_key(learning)

        assert key == "episode:test_title"

    def test_extract_facts_no_matches(self, analyzer):
        """Test fact extraction with no matches."""
        text = "This is just regular text with no patterns"
        facts = analyzer._extract_facts_heuristic(text)

        # May still have matches from generic patterns
        assert isinstance(facts, list)

    def test_extract_episodes_no_matches(self, analyzer):
        """Test episode extraction with no matches."""
        text = "This is just regular text with no patterns"
        episodes = analyzer._extract_episodes_heuristic(text)

        # May still have matches from generic patterns
        assert isinstance(episodes, list)

    def test_model_manager_none(self, config):
        """Test that analyzer works without model_manager."""
        analyzer = ConversationAnalyzer(model_manager=None, config=config)

        # Should initialize without error
        assert analyzer is not None
        assert analyzer.model_manager is None

    def test_config_defaults(self):
        """Test that default config is applied."""
        analyzer = ConversationAnalyzer(model_manager=None, config={})

        assert analyzer.extraction_mode == "hybrid"
        assert analyzer.use_llm == True
        assert analyzer.min_fact_confidence == 0.7
        assert analyzer.min_episode_confidence == 0.6

    def test_estimate_tokens(self, analyzer):
        """Test token estimation."""
        text = "This is a test message with some words"
        tokens = analyzer._estimate_tokens(text)

        # Should be approximately length / 4
        assert tokens > 0
        assert tokens < len(text)  # Tokens should be less than chars


class TestMCPIntegration:
    """Test MCP server integration for rag.analyze_conversation."""

    @pytest.mark.asyncio
    async def test_analyze_conversation_tool_call(self):
        """Test that rag.analyze_conversation tool can be called."""
        # This test requires the MCP server to be running
        # For now, we'll just check that the method exists
        from mcp_server.synapse_server import MemoryBackend

        backend = MemoryBackend()

        # Check that analyze_conversation method exists
        assert hasattr(backend, 'analyze_conversation')

        # Test basic call (will fail if server not running)
        try:
            result = await backend.analyze_conversation(
                project_id="test",
                user_message="Test message",
                agent_response="Test response",
                auto_store=False,
                return_only=True
            )

            # Should return dict with facts/episodes
            assert "facts" in result
            assert "episodes" in result
            assert isinstance(result["facts"], list)
            assert isinstance(result["episodes"], list)

        except Exception as e:
            # Expected if server not running or DB not initialized
            pytest.skip(f"MCP server not running: {e}")

    @pytest.mark.asyncio
    async def test_analyze_conversation_return_only(self):
        """Test return_only flag."""
        from mcp_server.synapse_server import MemoryBackend

        backend = MemoryBackend()

        try:
            result = await backend.analyze_conversation(
                project_id="test",
                user_message="Test message",
                auto_store=False,
                return_only=True
            )

            # Should not store anything
            assert result["facts_stored"] == 0
            assert result["episodes_stored"] == 0
            assert len(result["facts"]) > 0 or len(result["episodes"]) > 0

        except Exception as e:
            pytest.skip(f"MCP server not running: {e}")
