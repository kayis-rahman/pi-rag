"""
Unit tests for PromptBuilder.

Tests cover prompt building with context, memory injection, system messages, and chat history.
"""

import pytest
from core.prompt_builder import PromptBuilder, build_prompt_from_components


@pytest.mark.unit
class TestPromptBuilder:
    """Test PromptBuilder class for prompt construction."""

    def test_initialization(self):
        """Test PromptBuilder initialization."""
        builder = PromptBuilder()

        assert builder is not None
        assert hasattr(builder, "build_prompt")
        assert hasattr(builder, "build_prompt_with_selector")

    def test_build_prompt_with_user_query_only(self):
        """Test building prompt with just user query."""
        builder = PromptBuilder()

        prompt = builder.build_prompt(user_query="Help me build a REST API")

        assert prompt is not None
        assert "USER REQUEST" in prompt
        assert "REST API" in prompt

    def test_build_prompt_with_memory_facts(self):
        """Test building prompt with memory facts."""
        builder = PromptBuilder()

        memory_facts = [
            {
                "scope": "user",
                "category": "preference",
                "key": "theme",
                "value": "dark"
            },
            {
                "scope": "project",
                "category": "fact",
                "key": "language",
                "value": "Python"
            }
        ]

        prompt = builder.build_prompt(
            user_query="What are my preferences?",
            memory_facts=memory_facts
        )

        assert prompt is not None
        assert "PERSISTENT MEMORY" in prompt
        assert "dark" in prompt
        assert "Python" in prompt

    def test_build_prompt_with_rag_context(self):
        """Test building prompt with RAG context."""
        builder = PromptBuilder()

        rag_context = "[Retrieved document about API setup...]"

        prompt = builder.build_prompt(
            user_query="How do I set up the API?",
            rag_context=rag_context
        )

        assert prompt is not None
        assert "RELEVANT CONTEXT" in prompt
        assert "API setup" in prompt

    def test_build_prompt_with_system_instruction(self):
        """Test building prompt with system instruction."""
        builder = PromptBuilder()

        system_instruction = "You are a helpful coding assistant."

        prompt = builder.build_prompt(
            user_query="Help me write code",
            system_instruction=system_instruction
        )

        assert prompt is not None
        assert "SYSTEM" in prompt
        assert "coding assistant" in prompt

    def test_build_prompt_with_all_components(self):
        """Test building prompt with all components."""
        builder = PromptBuilder()

        memory_facts = [
            {"scope": "user", "category": "preference", "key": "theme", "value": "dark"}
        ]
        rag_context = "[Retrieved document about Go setup...]"
        system_instruction = "You are a Go expert."

        prompt = builder.build_prompt(
            user_query="Help me set up a Go project",
            memory_facts=memory_facts,
            rag_context=rag_context,
            system_instruction=system_instruction
        )

        assert prompt is not None
        assert "SYSTEM" in prompt
        assert "PERSISTENT MEMORY" in prompt
        assert "RELEVANT CONTEXT" in prompt
        assert "USER REQUEST" in prompt
        assert "dark" in prompt
        assert "Go" in prompt

    def test_build_prompt_with_empty_components(self):
        """Test building prompt with empty components."""
        builder = PromptBuilder()

        prompt = builder.build_prompt(
            user_query="Hello",
            memory_facts=None,
            rag_context=None
        )

        assert prompt is not None
        assert "USER REQUEST" in prompt

    def test_build_prompt_from_components_function(self):
        """Test module-level build_prompt_from_components function."""
        user_query = "Help me write code"
        memory_facts = [
            {"scope": "user", "category": "preference", "key": "language", "value": "Python"}
        ]

        prompt = build_prompt_from_components(
            user_query=user_query,
            memory_facts=memory_facts
        )

        assert prompt is not None
        assert isinstance(prompt, str)
        assert "Python" in prompt

    def test_build_prompt_with_selector(self):
        """Test building prompt with MemorySelector."""
        from core.memory_selector import MemorySelector

        builder = PromptBuilder()
        selector = MemorySelector()

        prompt = builder.build_prompt_with_selector(
            user_query="What is the project language?",
            selector=selector
        )

        # This test verifies the method exists and can be called
        # Actual selector behavior is tested in integration tests
        assert prompt is not None
        assert isinstance(prompt, str)

    def test_prompt_structure_separation(self):
        """Test that prompt has clear section separation."""
        builder = PromptBuilder()

        prompt = builder.build_prompt(
            user_query="Help me",
            memory_facts=[{"scope": "user", "key": "test", "value": "data"}],
            rag_context="[Context]"
        )

        # Check for section headers
        assert "PERSISTENT MEMORY" in prompt
        assert "RELEVANT CONTEXT" in prompt
        assert "USER REQUEST" in prompt

        # Check for separation
        sections = prompt.split("---\n")
        assert len(sections) >= 2  # At least MEMORY, RAG, REQUEST
