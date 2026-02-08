#!/usr/bin/env python3
"""Test OpenCode plugin configuration."""
import pytest
import json
from pathlib import Path


class TestOpenCodePluginConfig:
    """Test plugin configuration values."""

    def test_plugin_file_exists(self):
        """Verify plugin file exists."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        assert plugin_path.exists(), "Plugin file should exist"

    def test_default_config_values(self):
        """Verify default configuration in plugin."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Check for expected default values
        assert 'enabled: true' in content
        assert 'priority: 1' in content
        assert 'extraction_mode: "heuristic"' in content
        assert 'async_processing: true' in content
        assert 'min_message_length: 10' in content

    def test_skip_patterns_defined(self):
        """Verify skip patterns are defined."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Check for skip patterns array
        assert 'skip_patterns:' in content
        assert '^test$' in content
        assert '^hello$' in content
        assert '^help$' in content

    def test_analyze_after_tools_list(self):
        """Verify default tools to analyze after."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Check for expected tools
        expected_tools = [
            "sy.mem.fact.add",
            "sy.mem.ep.add",
            "sy.mem.search",
            "sy.ctx.get",
            "sy.mem.ingest"
        ]

        for tool in expected_tools:
            assert f'"{tool}"' in content or f"'{tool}'" in content


class TestOpenCodePluginHooks:
    """Test plugin hook definitions."""

    def test_tool_execute_before_defined(self):
        """Verify tool.execute.before hook is defined."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        assert '"tool.execute.before"' in content
        assert 'async (input, output)' in content
        assert 'ctx.tools.call' in content or 'tools.call' in content

    def test_tool_execute_after_defined(self):
        """Verify tool.execute.after hook is defined."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        assert '"tool.execute.after"' in content
        assert 'async (input, output)' in content


class TestOpenCodePluginErrorHandling:
    """Test error handling in plugin."""

    def test_try_catch_blocks_present(self):
        """Verify error handling with try-catch."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Should have try-catch in hooks
        try_count = content.count('try {')
        catch_count = content.count('catch (error')
        assert try_count >= 1, f"Should have try blocks, found {try_count}"
        assert catch_count >= 1, f"Should have catch blocks, found {catch_count}"

    def test_graceful_logging_present(self):
        """Verify errors are logged, not thrown."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Should log errors
        assert 'console.error' in content
        # Should have comments about graceful degradation
        assert 'graceful' in content.lower() or 'never throw' in content.lower()

    def test_performance_timing_present(self):
        """Verify performance timing is implemented."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Should track start time
        assert 'const startTime = Date.now()' in content
        # Should calculate duration
        assert 'Date.now() - startTime' in content
        # Should log duration
        assert 'execution time' in content.lower() or 'execution:' in content.lower()

    def test_min_message_length_filter_present(self):
        """Verify min_message_length filter is implemented."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Should have min_message_length check
        assert 'config.min_message_length' in content
        # Should filter short messages
        assert 'userMessage.length < config.min_message_length' in content

    def test_skip_patterns_filter_present(self):
        """Verify skip_patterns filter is implemented."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Should loop through skip_patterns
        assert 'for (const pattern of config.skip_patterns)' in content
        # Should create regex
        assert 'new RegExp(pattern' in content
        # Should skip matching messages
        assert 'return;' in content

    def test_rag_tool_call_present(self):
        """Verify RAG tool call is implemented."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Should call rag.analyze_conversation
        assert 'ctx.tools.call("rag.analyze_conversation"' in content
        # Should pass required parameters
        assert 'project_id:' in content
        assert 'user_message:' in content
        assert 'auto_store:' in content

    def test_offline_handling_present(self):
        """Verify offline scenario handling is implemented."""
        plugin_path = Path(".opencode/plugins/synapse-auto-learning.ts")
        content = plugin_path.read_text()

        # Should wrap RAG tool call in try-catch
        assert 'try {' in content
        assert 'catch (ragError' in content or 'catch (error' in content
        # Should log error without throwing
        assert 'console.error' in content
        assert 'Continuing without analysis' in content or 'graceful' in content.lower()
