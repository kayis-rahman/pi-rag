"""
Unit tests for AutoLearningTracker module.

Tests cover operation tracking, task completion detection,
pattern detection, and manual override functionality.
"""

import pytest
from core.auto_learning_tracker import AutoLearningTracker
from datetime import datetime


class TestAutoLearningTracker:
    """Test AutoLearningTracker class."""
    
    @pytest.fixture
    def config(self):
        """Default test configuration."""
        return {
            "enabled": True,
            "mode": "aggressive",
            "track_tasks": True,
            "track_code_changes": True,
            "track_operations": True,
            "min_episode_confidence": 0.6,
            "episode_deduplication": True
        }
    
    @pytest.fixture
    def tracker(self, config):
        """Create AutoLearningTracker instance for testing."""
        return AutoLearningTracker(config=config)
    
    def test_track_operation_appends_to_buffer(self, tracker):
        """Test that operations are added to buffer."""
        initial_count = len(tracker.operation_buffer)
        
        operation = {
            "tool_name": "rag.search",
            "project_id": "synapse",
            "arguments": {"query": "test"},
            "result": "success",
            "timestamp": datetime.now(),
            "duration_ms": 123
        }
        
        tracker.track_operation(operation)
        
        assert len(tracker.operation_buffer) == initial_count + 1
        assert tracker.operation_buffer[-1] == operation
    
    def test_buffer_max_size_enforced(self, tracker):
        """Test that buffer is limited to 100 operations."""
        # Add 101 operations
        for i in range(101):
            operation = {
                "tool_name": "rag.search",
                "result": "success",
                "timestamp": datetime.now()
            }
            tracker.track_operation(operation)
        
        # Buffer should only have last 100 operations
        assert len(tracker.operation_buffer) == 100
        # First operation should be removed
        assert tracker.operation_buffer[0]["tool_name"] == "rag.search"
    
    def test_detect_task_completion_multi_step(self, tracker):
        """Test detection of multi-step operations."""
        operations = [
            {"tool_name": "rag.search", "result": "success"},
            {"tool_name": "rag.get_context", "result": "success"},
            {"tool_name": "read_file", "result": "success"}
        ]
        
        task_completion = tracker.detect_task_completion(operations)
        
        assert task_completion is not None
        assert task_completion["type"] == "task_completion"
        assert "Multi-step" in task_completion["situation"]
    
    def test_detect_task_completion_file_ingestion(self, tracker):
        """Test detection of successful file ingestion."""
        operations = [
            {"tool_name": "rag.ingest_file", "result": "success"},
            {"tool_name": "rag.ingest_file", "result": "success"},
            {"tool_name": "rag.ingest_file", "result": "success"}
        ]
        
        task_completion = tracker.detect_task_completion(operations)
        
        assert task_completion is not None
        assert "ingestion" in task_completion["action"].lower()
        assert task_completion["outcome"] == "success"
    
    def test_detect_task_completion_search_context_code(self, tracker):
        """Test detection of search + context + code modification."""
        operations = [
            {"tool_name": "rag.search", "result": "success"},
            {"tool_name": "rag.get_context", "result": "success"},
            {"tool_name": "read_file", "result": "success"}
        ]
        
        task_completion = tracker.detect_task_completion(operations)
        
        assert task_completion is not None
        assert task_completion["type"] == "task_completion"
        assert "search" in task_completion["situation"].lower()
        assert "code" in task_completion["situation"].lower()
    
    def test_detect_task_completion_insufficient_ops(self, tracker):
        """Test that less than 3 operations doesn't trigger detection."""
        operations = [
            {"tool_name": "rag.search", "result": "success"},
            {"tool_name": "rag.get_context", "result": "success"}
        ]
        
        task_completion = tracker.detect_task_completion(operations)
        
        # Should return None for less than 3 operations
        assert task_completion is None
    
    def test_detect_pattern_repeated_failures(self, tracker):
        """Test detection of repeated failures."""
        operations = [
            {"tool_name": "rag.search", "result": "error", "timestamp": datetime.now()},
            {"tool_name": "rag.search", "result": "error", "timestamp": datetime.now()}
        ]
        
        pattern = tracker.detect_pattern(operations)
        
        assert pattern is not None
        assert pattern["type"] == "pattern"
        assert "repeated" in pattern["situation"].lower()
        assert "failure" in pattern["outcome"].lower()
    
    def test_detect_pattern_repeated_successes(self, tracker):
        """Test detection of repeated successes (aggressive mode)."""
        # Enable aggressive mode
        tracker.mode = "aggressive"
        
        operations = [
            {"tool_name": "rag.search", "result": "success", "timestamp": datetime.now()},
            {"tool_name": "rag.search", "result": "success", "timestamp": datetime.now()},
            {"tool_name": "rag.search", "result": "success", "timestamp": datetime.now()}
        ]
        
        pattern = tracker.detect_pattern(operations)
        
        assert pattern is not None
        assert pattern["type"] == "pattern"
        assert "repeated" in pattern["situation"].lower()
        assert "success" in pattern["outcome"].lower()
    
    def test_detect_pattern_not_enough_ops(self, tracker):
        """Test that less than 5 operations doesn't trigger pattern detection."""
        operations = [
            {"tool_name": "rag.search", "result": "success"},
            {"tool_name": "rag.search", "result": "success"},
            {"tool_name": "rag.search", "result": "success"}
        ]
        
        pattern = tracker.detect_pattern(operations)
        
        # Should return None for less than 5 operations
        assert pattern is None
    
    def test_should_auto_track_respects_override_false(self, tracker):
        """Test that auto_learn=false disables tracking."""
        operation = {
            "tool_name": "rag.search",
            "arguments": {"auto_learn": False}
        }
        
        should_track = tracker.should_auto_track(operation)
        
        assert should_track is False
    
    def test_should_auto_track_respects_override_true(self, tracker):
        """Test that auto_learn=true enables tracking."""
        operation = {
            "tool_name": "rag.search",
            "arguments": {"auto_learn": True}
        }
        
        should_track = tracker.should_auto_track(operation)
        
        assert should_track is True
    
    def test_should_auto_track_default_to_global(self, tracker):
        """Test that default (no override) respects global config."""
        operation = {
            "tool_name": "rag.search",
            "arguments": {}
        }
        
        # Enable global config
        tracker.enabled = True
        
        should_track = tracker.should_auto_track(operation)
        
        assert should_track is True
    
    def test_should_auto_track_global_disabled(self, tracker):
        """Test that global disabled disables all tracking."""
        operation = {
            "tool_name": "rag.search",
            "arguments": {}
        }
        
        # Disable global config
        tracker.enabled = False
        
        should_track = tracker.should_auto_track(operation)
        
        assert should_track is False
    
    def test_get_buffer_stats(self, tracker):
        """Test buffer statistics calculation."""
        operations = [
            {"tool_name": "rag.search", "result": "success", "duration_ms": 100},
            {"tool_name": "rag.search", "result": "error", "duration_ms": 50},
            {"tool_name": "rag.get_context", "result": "success", "duration_ms": 200},
            {"tool_name": "rag.ingest_file", "result": "success", "duration_ms": 150}
        ]
        
        for op in operations:
            tracker.track_operation(op)
        
        stats = tracker.get_buffer_stats()
        
        assert stats["total_operations"] == 4
        assert stats["successful_operations"] == 3
        assert stats["failed_operations"] == 1
        assert stats["success_rate"] == 0.75
        assert stats["average_duration_ms"] == 125
        assert stats["unique_tools"] == 3
        assert "rag.search" in stats["top_tools"][0]
    
    def test_clear_buffer(self, tracker):
        """Test buffer clearing."""
        operations = [
            {"tool_name": "rag.search", "result": "success"} for _ in range(10)
        ]
        
        for op in operations:
            tracker.track_operation(op)
        
        assert len(tracker.operation_buffer) == 10
        tracker.clear_buffer()
        
        assert len(tracker.operation_buffer) == 0


if __name__ == "__main__":
    pytest.main([__file__])
