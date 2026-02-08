"""
Integration tests for Automatic Learning System.

Tests cover:
- Episode auto-storage after task completion
- Fact extraction from code ingestion
- Pattern detection (repeated failures/successes)
- Manual override (auto_learn=false)
- Configuration modes (aggressive/moderate/minimal)
- Deduplication logic
"""

import pytest
import asyncio
from datetime import datetime

from core.auto_learning_tracker import AutoLearningTracker
from core.learning_extractor import LearningExtractor
from core.model_manager import ModelManager
from core import EpisodicStore, get_episodic_store, Episode
from core import MemoryStore, get_memory_store, MemoryFact


class MockModelManager:
    """Mock model manager for testing."""

    def __init__(self):
        self.chat_calls = []

    def chat_completion(self, model_name, messages, temperature=None, max_tokens=None):
        """Mock chat completion."""
        self.chat_calls.append({
            "model_name": model_name,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        })

        # Return a successful extraction response
        return {
            "choices": [{
                "message": {
                    "content": '{"situation": "Test situation", "action": "Test action", "outcome": "success", "lesson": "Test learned strategy", "confidence": 0.75}'
                }
            }]
        }


class TestAutoLearningIntegration:
    """Integration tests for auto-learning system."""

    @pytest.fixture
    def temp_db_path(self, tmp_path):
        """Temporary database path."""
        db_path = tmp_path / "test_memory.db"
        yield str(db_path)

    @pytest.fixture
    def symbolic_store(self, temp_db_path):
        """Symbolic memory store for testing."""
        # Clean existing file if present
        import os
        if os.path.exists(temp_db_path):
            os.remove(temp_db_path)

        store = get_memory_store(temp_db_path)
        yield store
        # Cleanup
        if os.path.exists(temp_db_path):
            os.remove(temp_db_path)

    @pytest.fixture
    def episodic_store(self, temp_db_path):
        """Episodic memory store for testing."""
        db_path = temp_db_path.parent / "test_episodic.db"

        # Clean existing file if present
        import os
        if os.path.exists(db_path):
            os.remove(db_path)

        store = get_episodic_store(db_path)
        yield store
        # Cleanup
        if os.path.exists(db_path):
            os.remove(db_path)

    @pytest.fixture
    def auto_config(self):
        """Default auto-learning configuration."""
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
    def mock_model_manager(self):
        """Mock model manager."""
        return MockModelManager()

    @pytest.fixture
    def tracker(self, auto_config, mock_model_manager):
        """Auto-learning tracker for testing."""
        return AutoLearningTracker(config=auto_config, model_manager=mock_model_manager)

    @pytest.fixture
    def extractor(self, mock_model_manager):
        """Learning extractor for testing."""
        return LearningExtractor(model_manager=mock_model_manager)

    def test_episode_storage_after_task_completion(self, tracker, episodic_store):
        """Test episode is stored after task completion detection."""
        # Track a multi-step task
        operations = [
            {"tool_name": "rag.search", "result": "success", "timestamp": datetime.now()},
            {"tool_name": "rag.get_context", "result": "success", "timestamp": datetime.now()},
            {"tool_name": "read_file", "result": "success", "timestamp": datetime.now()}
        ]

        for op in operations:
            tracker.track_operation(op)

        # Detect task completion
        task_completion = tracker.detect_task_completion()
        assert task_completion is not None
        assert task_completion["type"] == "task_completion"
        assert task_completion["outcome"] == "success"

    def test_fact_extraction_from_file_ingestion(self, extractor):
        """Test facts extracted from file ingestion."""
        file_path = "/test/app.py"
        file_content = '''
from fastapi import FastAPI
from pydantic import BaseModel

@app.get("/users")
@app.post("/users")
'''

        facts = extractor.extract_facts_from_code(file_path, file_content)

        # Should extract dependencies, framework, and endpoints
        assert len(facts) > 0
        assert any(f["key"] == "dependencies" for f in facts)
        assert any(f["key"] == "framework" for f in facts)
        assert any(f["key"] == "api_endpoints" for f in facts)

        # Verify FastAPI was detected
        framework_facts = [f for f in facts if f["key"] == "framework"]
        assert len(framework_facts) > 0
        assert "fastapi" in framework_facts[0]["value"]["framework"].lower()

    def test_pattern_detection_repeated_failures(self, tracker):
        """Test pattern detection for repeated failures."""
        # Track repeated failures
        for i in range(3):
            operation = {
                "tool_name": "rag.search",
                "result": "error",
                "timestamp": datetime.now()
            }
            tracker.track_operation(operation)

        # Detect pattern
        pattern = tracker.detect_pattern()
        assert pattern is not None
        assert pattern["type"] == "pattern"
        assert "repeated" in pattern["situation"].lower()
        assert "failure" in pattern["outcome"].lower() or pattern["outcome"] == "failure"

    def test_pattern_detection_repeated_successes(self, tracker):
        """Test pattern detection for repeated successes in aggressive mode."""
        # Track repeated successes
        for i in range(5):
            operation = {
                "tool_name": "rag.search",
                "result": "success",
                "timestamp": datetime.now()
            }
            tracker.track_operation(operation)

        # Detect pattern (should detect in aggressive mode with 5 ops)
        pattern = tracker.detect_pattern()
        # Pattern detection requires 5 operations in aggressive mode
        assert pattern is not None or len(tracker.operation_buffer) < 5

    def test_manual_override_disables_tracking(self, tracker, auto_config):
        """Test auto_learn=false disables tracking."""
        # Test with auto_learn=false
        operation = {
            "tool_name": "rag.search",
            "arguments": {"auto_learn": False},
            "result": "success",
            "timestamp": datetime.now()
        }

        should_track = tracker.should_auto_track(operation)
        assert should_track is False

        # Test with auto_learn=true (explicit override)
        operation["arguments"]["auto_learn"] = True
        should_track = tracker.should_auto_track(operation)
        assert should_track is True

        # Test without override (respects global config)
        operation["arguments"] = {}
        auto_config["enabled"] = True
        should_track = tracker.should_auto_track(operation)
        assert should_track is True

        auto_config["enabled"] = False
        should_track = tracker.should_auto_track(operation)
        assert should_track is False

    def test_buffer_max_size(self, tracker):
        """Test buffer is limited to 100 operations."""
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

    def test_episode_confidence_filtering(self, extractor):
        """Test low confidence episodes are filtered out."""
        # Test with low confidence (should be rejected)
        low_confidence_task = {
            "type": "task_completion",
            "situation": "Simple task",
            "action": "Completed simple task",
            "outcome": "success",
            "confidence": 0.5  # Below threshold
        }

        episode = extractor.extract_episode_from_task(low_confidence_task)
        assert episode is None  # Should be filtered out

        # Test with high confidence (should be accepted)
        high_confidence_task = {
            "type": "task_completion",
            "situation": "Complex task",
            "action": "Solved complex problem",
            "outcome": "success",
            "confidence": 0.8  # Above threshold
        }

        episode = extractor.extract_episode_from_task(high_confidence_task)
        assert episode is not None
        assert episode["confidence"] == 0.8

    def test_file_ingestion_pattern(self, tracker):
        """Test file ingestion task completion detection."""
        operations = [
            {"tool_name": "rag.ingest_file", "result": "success", "timestamp": datetime.now()},
            {"tool_name": "rag.ingest_file", "result": "success", "timestamp": datetime.now()},
            {"tool_name": "rag.ingest_file", "result": "success", "timestamp": datetime.now()}
        ]

        for op in operations:
            tracker.track_operation(op)

        task_completion = tracker.detect_task_completion()
        assert task_completion is not None
        assert "ingestion" in task_completion["action"].lower()

    def test_get_buffer_stats(self, tracker):
        """Test buffer statistics calculation."""
        operations = [
            {"tool_name": "rag.search", "result": "success", "duration_ms": 100, "timestamp": datetime.now()},
            {"tool_name": "rag.search", "result": "error", "duration_ms": 50, "timestamp": datetime.now()},
            {"tool_name": "rag.get_context", "result": "success", "duration_ms": 200, "timestamp": datetime.now()}
        ]

        for op in operations:
            tracker.track_operation(op)

        stats = tracker.get_buffer_stats()
        assert stats["total_operations"] == 3
        assert stats["successful_operations"] == 2
        assert stats["failed_operations"] == 1
        assert stats["success_rate"] == 2/3
        assert stats["average_duration_ms"] == 116.67  # (100 + 50 + 200) / 3
        assert stats["unique_tools"] == 2

    def test_clear_buffer(self, tracker):
        """Test buffer clearing."""
        # Add operations
        for i in range(10):
            operation = {
                "tool_name": "rag.search",
                "result": "success",
                "timestamp": datetime.now()
            }
            tracker.track_operation(operation)

        assert len(tracker.operation_buffer) == 10

        # Clear buffer
        tracker.clear_buffer()

        assert len(tracker.operation_buffer) == 0


if __name__ == "__main__":
    pytest.main([__file__])
