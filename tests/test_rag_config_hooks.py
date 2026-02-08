#!/usr/bin/env python3
"""Test RAG config universal_hooks section."""
import pytest
import json
from pathlib import Path


class TestRagConfigUniversalHooks:
    """Test universal_hooks configuration."""

    def test_universal_hooks_section_exists(self):
        """Verify universal_hooks section exists in config."""
        config_path = Path("configs/synapse_config.json")
        config = json.loads(config_path.read_text())

        assert "universal_hooks" in config

    def test_opencode_adapter_exists(self):
        """Verify opencode adapter configuration."""
        config_path = Path("configs/synapse_config.json")
        config = json.loads(config_path.read_text())

        assert "adapters" in config["universal_hooks"]
        assert "opencode" in config["universal_hooks"]["adapters"]

    def test_opencode_config_complete(self):
        """Verify opencode adapter has all required config."""
        config_path = Path("configs/synapse_config.json")
        config = json.loads(config_path.read_text())

        opencode_config = config["universal_hooks"]["adapters"]["opencode"]

        required_keys = [
            "enabled",
            "priority",
            "analyze_after_tools",
            "min_message_length",
            "skip_patterns",
            "async_processing",
            "extraction_mode"
        ]

        for key in required_keys:
            assert key in opencode_config, f"Missing required config key: {key}"

    def test_conversation_analyzer_config_exists(self):
        """Verify conversation_analyzer configuration."""
        config_path = Path("configs/synapse_config.json")
        config = json.loads(config_path.read_text())

        assert "conversation_analyzer" in config["universal_hooks"]

    def test_config_sensible_defaults(self):
        """Verify configuration has sensible defaults."""
        config_path = Path("configs/synapse_config.json")
        config = json.loads(config_path.read_text())

        analyzer_config = config["universal_hooks"]["conversation_analyzer"]

        # Check confidence thresholds are in valid range
        assert analyzer_config["min_fact_confidence"] >= 0.5
        assert analyzer_config["min_fact_confidence"] <= 1.0
        assert analyzer_config["min_episode_confidence"] >= 0.5
        assert analyzer_config["min_episode_confidence"] <= 1.0

        # Check deduplication settings
        assert analyzer_config["deduplication_mode"] in ["per_day", "per_session", "global"]
        assert analyzer_config["deduplication_window_days"] >= 1

    def test_opencode_enabled(self):
        """Verify opencode adapter is enabled by default."""
        config_path = Path("configs/synapse_config.json")
        config = json.loads(config_path.read_text())

        opencode_config = config["universal_hooks"]["adapters"]["opencode"]
        assert opencode_config["enabled"] is True

    def test_opencode_priority(self):
        """Verify opencode adapter has priority set."""
        config_path = Path("configs/synapse_config.json")
        config = json.loads(config_path.read_text())

        opencode_config = config["universal_hooks"]["adapters"]["opencode"]
        assert opencode_config["priority"] == 1
