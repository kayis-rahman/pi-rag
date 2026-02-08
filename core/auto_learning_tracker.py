"""
Auto Learning Tracker - Automatically tracks operations and extracts learnings.

This module tracks all MCP tool calls, detects patterns, and triggers
automatic episode/fact extraction based on task completion and patterns.

Design Principles:
- Operations are tracked in in-memory buffer (no disk I/O)
- Task completion detection from operation sequences
- Pattern detection (repeated failures/successes)
- Confidence scoring to filter low-quality learnings
- Immediate storage (no batching - per user requirement)
"""

import logging
from typing import Dict, List, Any, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class AutoLearningTracker:
    """
    Automatically tracks operations and extracts learnings.
    
    Responsibilities:
    - Track all MCP tool calls in buffer
    - Detect task completion from operation sequences
    - Detect patterns (repeated failures/successes)
    - Provide data for learning extraction
    - Support manual override (auto_learn=false)
    """
    
    def __init__(
        self,
        config: Dict[str, Any],
        model_manager: Optional[Any] = None
    ):
        """
        Initialize auto-learning tracker.
        
        Args:
            config: Automatic learning configuration
            model_manager: Optional ModelManager for LLM access
        """
        self.config = config
        self.model_manager = model_manager
        
        # Configuration settings
        self.enabled = config.get("enabled", False)
        self.mode = config.get("mode", "moderate")
        self.track_tasks = config.get("track_tasks", True)
        self.track_code_changes = config.get("track_code_changes", True)
        self.track_operations = config.get("track_operations", True)
        self.min_episode_confidence = config.get("min_episode_confidence", 0.6)
        self.episode_deduplication = config.get("episode_deduplication", True)
        
        # Operation buffer (rolling window of last 100 operations)
        self.operation_buffer: List[Dict[str, Any]] = []
        self.max_buffer_size = 100
        
        logger.info(f"AutoLearningTracker initialized: enabled={self.enabled}, mode={self.mode}")
    
    def track_operation(self, operation: Dict[str, Any]) -> None:
        """
        Track an MCP tool operation.
        
        Args:
            operation: Dict with keys:
                - tool_name: str
                - project_id: str
                - arguments: dict
                - result: "success" | "error"
                - timestamp: datetime
                - duration_ms: int
        """
        if not self.enabled:
            return
        
        # Add timestamp if not provided
        if "timestamp" not in operation:
            operation["timestamp"] = datetime.now()
        
        # Add to buffer (maintain max size)
        self.operation_buffer.append(operation)
        if len(self.operation_buffer) > self.max_buffer_size:
            self.operation_buffer = self.operation_buffer[-self.max_buffer_size:]
        
        # Check for immediate patterns after each addition
        if self.track_operations:
            self._check_immediate_patterns(operation)
    
    def _check_immediate_patterns(self, operation: Dict[str, Any]) -> None:
        """
        Check for immediate patterns (repeated failures, specific issues).
        
        This is called after each operation to detect urgent patterns.
        """
        if len(self.operation_buffer) < 3:
            return
        
        # Check for repeated failures (same tool, 3 consecutive errors)
        last_3 = self.operation_buffer[-3:]
        errors = [op for op in last_3 if op.get("result") == "error"]
        
        if len(errors) == 3:
            tool_name = operation.get("tool_name", "unknown")
            logger.warning(f"Pattern detected: {tool_name} failed 3 times consecutively")
    
    def detect_task_completion(self, operations: Optional[List[Dict[str, Any]]] = None) -> Optional[Dict[str, Any]]:
        """
        Detect completed task from operation sequence.

        Patterns:
        1. Multi-step operations (3+ tools used)
        2. Successful file ingestion (rag.ingest_file success)
        3. Bug fix sequence (search → read → edit)
        4. Deployment sequence (build → test → deploy)

        Args:
            operations: Optional list of operations (uses internal buffer if None)

        Returns:
            Task completion dict with:
                - type: "task_completion"
                - situation: What task was started
                - action: What was done
                - outcome: success/failure
                - confidence: float (0.6-0.9)
        """
        ops = operations if operations is not None else self.operation_buffer

        if len(ops) < 3:
            return None

        last_3 = ops[-3:]

        # Generic multi-step pattern (any 3+ successful operations)
        if self.track_tasks:
            if all(op.get("result") == "success" for op in last_3):
                # Check for specific patterns first
                # Pattern 1: File ingestion success
                if all(op.get("tool_name") == "rag.ingest_file" for op in last_3):
                    return {
                        "type": "task_completion",
                        "situation": "Multiple files needed to be ingested",
                        "action": "File ingestion completed successfully for multiple files",
                        "outcome": "success",
                        "confidence": 0.8
                    }

                # Pattern 2: Search → Get Context → Code modification
                tools_used = [op.get("tool_name") for op in last_3]

                # Check for search + context retrieval
                has_search = "rag.search" in tools_used
                has_get_context = "rag.get_context" in tools_used

                # Check for file WRITE operations (excludes read)
                has_write_ops = any(t in tools_used for t in ["edit_file", "write_file", "edit", "write"])

                if has_search and has_get_context and has_write_ops:
                    return {
                        "type": "task_completion",
                        "situation": "Search and code modification",
                        "action": "Searched semantic memory, retrieved context, and modified code",
                        "outcome": "success",
                        "confidence": 0.75
                    }

                # Generic multi-step pattern (any 3 successful operations, excluding file ingestion)
                tool_names = [op.get("tool_name") for op in last_3]
                unique_tools = len(set(tool_names))
                is_file_ingestion = all(op.get("tool_name") == "rag.ingest_file" for op in last_3)

                if not is_file_ingestion and not has_search and not has_get_context:
                    return {
                        "type": "task_completion",
                        "situation": f"Multi-step operation using {unique_tools} different tools",
                        "action": "Executed multiple operations successfully",
                        "outcome": "success",
                        "confidence": 0.7
                    }

        return None
    
    def detect_pattern(self, operations: Optional[List[Dict[str, Any]]] = None) -> Optional[Dict[str, Any]]:
        """
        Detect repeated patterns across operations.

        Patterns:
        1. Same tool fails 2+ times consecutively
        2. Same operation succeeds 3+ times
        3. Specific query pattern repeats

        Args:
            operations: Optional list of operations (uses internal buffer if None)

        Returns:
            Pattern dict with:
                - type: "pattern"
                - situation: What pattern was detected
                - action: What happened
                - outcome: pattern description
                - confidence: float (0.7-0.9)
        """
        ops = operations if operations is not None else self.operation_buffer

        if len(ops) < 2:
            return None

        # Use all available operations (not just last 5)
        recent_ops = ops[-5:] if len(ops) >= 5 else ops

        # Check for repeated failures (need at least 2)
        failures = [op for op in recent_ops if op.get("result") == "error"]

        if len(failures) >= 2:
            # Check if same tool failed
            failed_tools = [op.get("tool_name") for op in failures]
            if len(set(failed_tools)) == 1:  # All same tool
                tool_name = failed_tools[0]
                return {
                    "type": "pattern",
                    "situation": f"Repeated failures in {tool_name}",
                    "action": f"Attempted {tool_name} {len(failures)} times consecutively without success",
                    "outcome": "failure",
                    "confidence": 0.85
                }

        # Check for repeated successes (need at least 3 consecutive in aggressive mode, AND 5+ total ops)
        if self.mode == "aggressive" and len(ops) >= 5:
            successes = [op for op in recent_ops if op.get("result") == "success"]

            if len(successes) >= 3:
                success_tools = [op.get("tool_name") for op in successes]
                if len(set(success_tools)) == 1:
                    tool_name = success_tools[0]
                    return {
                        "type": "pattern",
                        "situation": f"Repeated success with {tool_name}",
                        "action": f"Successfully used {tool_name} {len(successes)} times",
                        "outcome": "success",
                        "confidence": 0.8
                    }

        return None
    
    def should_auto_track(self, operation: Dict[str, Any]) -> bool:
        """
        Check if operation should be auto-tracked.
        
        Checks:
        1. Global auto-learning enabled
        2. Manual override not set (auto_learn=false)
        
        Args:
            operation: Operation dict with arguments
            
        Returns:
            True if should track, False otherwise
        """
        # Check global enable/disable
        if not self.enabled:
            return False
        
        # Check for manual override
        auto_learn = operation.get("arguments", {}).get("auto_learn", None)
        
        if auto_learn is not None:
            # Explicit override - use it
            return auto_learn
        
        # Default: respect global setting
        return True
    
    def get_buffer_stats(self) -> Dict[str, Any]:
        """
        Get statistics about operation buffer.

        Returns:
            Dict with counts of various metrics
        """
        total = len(self.operation_buffer)
        successes = len([op for op in self.operation_buffer if op.get("result") == "success"])
        errors = len([op for op in self.operation_buffer if op.get("result") == "error"])

        # Count by tool
        tool_counts = {}
        for op in self.operation_buffer:
            tool = op.get("tool_name", "unknown")
            tool_counts[tool] = tool_counts.get(tool, 0) + 1

        # Calculate average duration
        durations = [op.get("duration_ms", 0) for op in self.operation_buffer if "duration_ms" in op]
        avg_duration = sum(durations) / len(durations) if durations else 0

        return {
            "total_operations": total,
            "successful_operations": successes,
            "failed_operations": errors,
            "success_rate": successes / total if total > 0 else 0,
            "average_duration_ms": round(avg_duration),
            "unique_tools": len(tool_counts),
            "top_tools": sorted(tool_counts.items(), key=lambda x: x[1], reverse=True)[:5]
        }
    
    def clear_buffer(self) -> None:
        """Clear the operation buffer."""
        self.operation_buffer = []
        logger.info("Operation buffer cleared")
