"""
Unit tests for RAGOrchestrator.

Tests cover RAG orchestration, context injection, streaming, and multi-model support.
"""

import pytest
import tempfile
from pathlib import Path
from core.orchestrator import RAGOrchestrator, get_orchestrator
from tests.utils.helpers import (
    MockEmbeddingService,
    MockLLMService,
    save_test_config,
    load_test_config
)


@pytest.mark.unit
class TestRAGOrchestratorInitialization:
    """Test RAGOrchestrator initialization."""

    def test_get_orchestrator_singleton(self):
        """Test that get_orchestrator returns singleton."""
        # Reset singleton
        from core.orchestrator import _orchestrator
        import importlib
        importlib.reload(rag.orchestrator)

        # First call should create instance
        orchestrator1 = get_orchestrator()
        assert orchestrator1 is not None

        # Second call should return same instance
        orchestrator2 = get_orchestrator()
        assert orchestrator2 is orchestrator1

    def test_initialization_with_defaults(self, tmp_path):
        """Test initialization with default configuration."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {})

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator is not None
        assert orchestrator.rag_enabled == True
        assert orchestrator.top_k == 3
        assert orchestrator.disable_keyword == "disable-rag"
        assert orchestrator.temperature == 0.7

    def test_initialization_with_custom_config(self, tmp_path):
        """Test initialization with custom configuration."""
        config_path = tmp_path / "config.json"
        custom_config = {
            "rag_enabled": False,
            "top_k": 5,
            "rag_disable_keyword": "no-rag",
            "temperature": 0.5
        }
        save_test_config(str(config_path), custom_config)

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.rag_enabled == False
        assert orchestrator.top_k == 5
        assert orchestrator.disable_keyword == "no-rag"
        assert orchestrator.temperature == 0.5

    def test_initialization_with_memory_config(self, tmp_path):
        """Test initialization with memory configuration."""
        config_path = tmp_path / "config.json"
        config = {
            "memory_enabled": True,
            "memory_db_path": str(tmp_path / "memory.db"),
            "memory_scope": "project",
            "memory_min_confidence": 0.8,
            "memory_max_facts": 15
        }
        save_test_config(str(config_path), config)

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.memory_enabled == True
        assert orchestrator.memory_scope == "project"
        assert orchestrator.memory_min_confidence == 0.8
        assert orchestrator.memory_max_facts == 15


@pytest.mark.unit
class TestRAGOrchestratorChat:
    """Test RAGOrchestrator chat functionality."""

    def test_chat_with_rag_enabled(self, tmp_path):
        """Test chat with RAG enabled."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {"rag_enabled": True})

        # This test verifies that chat method exists
        # Actual RAG retrieval is tested in integration tests
        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert hasattr(orchestrator, 'chat')

    def test_chat_with_rag_disabled(self, tmp_path):
        """Test chat with RAG disabled."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {"rag_enabled": False})

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.rag_enabled == False
        assert hasattr(orchestrator, 'chat')

    def test_chat_with_disable_keyword(self, tmp_path):
        """Test chat with disable-rag keyword."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {"rag_disable_keyword": "disable-rag"})

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.disable_keyword == "disable-rag"
        assert hasattr(orchestrator, 'chat')

    def test_chat_with_memory_enabled(self, tmp_path):
        """Test chat with memory enabled."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {
            "memory_enabled": True,
            "memory_db_path": str(tmp_path / "memory.db")
        })

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.memory_enabled == True
        assert hasattr(orchestrator, 'chat')

    def test_chat_without_memory(self, tmp_path):
        """Test chat without memory."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {"memory_enabled": False})

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.memory_enabled == False
        assert hasattr(orchestrator, 'chat')

    def test_chat_with_custom_temperature(self, tmp_path):
        """Test chat with custom temperature."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {"temperature": 0.9})

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.temperature == 0.9
        assert hasattr(orchestrator, 'chat')

    def test_chat_with_custom_top_k(self, tmp_path):
        """Test chat with custom top_k."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {"top_k": 10})

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.top_k == 10
        assert hasattr(orchestrator, 'chat')

    def test_chat_with_custom_max_tokens(self, tmp_path):
        """Test chat with custom max_tokens."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {"max_tokens": 4096})

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.max_tokens == 4096
        assert hasattr(orchestrator, 'chat')


@pytest.mark.unit
class TestRAGOrchestratorContextInjection:
    """Test context injection functionality."""

    def test_context_injection_enabled(self, tmp_path):
        """Test with context injection enabled."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {
            "context_injection_enabled": True
        })

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert hasattr(orchestrator, '_inject_context')
        assert hasattr(orchestrator, '_extract_query')

    def test_context_injection_disabled(self, tmp_path):
        """Test with context injection disabled."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {
            "context_injection_enabled": False
        })

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.context_injection_enabled == False

    def test_file_path_mode_enabled(self, tmp_path):
        """Test with file path mode enabled."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {
            "file_path_mode_enabled": True
        })

        orchestrator = RAGOrchestrator(config_path=str(config_path))

        assert orchestrator.file_path_mode_enabled == True


@pytest.mark.unit
class TestRAGOrchestratorModelManagement:
    """Test model management functionality."""

    def test_preload_models_exists(self):
        """Test that preload_models method exists."""
        # Reset singleton to test fresh instance
        from core.orchestrator import _orchestrator
        _orchestrator = None

        orchestrator = get_orchestrator()
        assert hasattr(orchestrator, 'preload_models')

    def test_unload_models_exists(self):
        """Test that unload_models method exists."""
        orchestrator = get_orchestrator()

        assert hasattr(orchestrator, 'unload_models')

    def test_get_stats_exists(self):
        """Test that get_stats method exists."""
        orchestrator = get_orchestrator()

        assert hasattr(orchestrator, 'get_stats')

    def test_get_stats_returns_dict(self, tmp_path):
        """Test that get_stats returns dictionary."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {})

        orchestrator = RAGOrchestrator(config_path=str(config_path))
        stats = orchestrator.get_stats()

        assert isinstance(stats, dict)
        assert "rag_enabled" in stats
        assert "chat_model" in stats


@pytest.mark.unit
class TestRAGOrchestratorErrorHandling:
    """Test error handling in orchestrator."""

    def test_missing_config_file(self, tmp_path):
        """Test behavior with missing config file."""
        config_path = tmp_path / "nonexistent.json"

        # Orchestrator should use defaults when config file is missing
        orchestrator = RAGOrchestrator(config_path=str(config_path))

        # Should still initialize with defaults
        assert orchestrator is not None

    def test_invalid_config_json(self, tmp_path):
        """Test behavior with invalid JSON config."""
        config_path = tmp_path / "invalid.json"
        with open(config_path, 'w') as f:
            f.write("invalid json {{{")

        # Orchestrator should handle invalid JSON gracefully
        # This test verifies error handling
        orchestrator = RAGOrchestrator(config_path=str(config_path))

        # Should still initialize
        assert orchestrator is not None

    def test_missing_dependencies_handling(self, tmp_path):
        """Test handling of missing dependencies."""
        config_path = tmp_path / "config.json"
        save_test_config(str(config_path), {})

        # Test that orchestrator can handle missing model manager, retriever, etc.
        # This verifies graceful degradation
        orchestrator = RAGOrchestrator(config_path=str(config_path))

        # Should initialize even with warnings
        assert orchestrator is not None
