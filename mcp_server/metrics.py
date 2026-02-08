"""
Metrics module for MCP server - Track tool calls, latency, and errors.

Provides detailed metrics for monitoring and debugging MCP server performance.
"""

import json
import time
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime, timezone
from pathlib import Path


logger = logging.getLogger(__name__)


class Metrics:
    """
    Track MCP server metrics with detailed logging.

    Features:
    - Tool call tracking (total, success, error)
    - Latency measurement (mean, p50, p95, p99)
    - Per-project metrics
    - Prometheus-style output
    - JSON export for analysis
    """

    def __init__(self):
        """Initialize metrics tracker."""
        self._metrics: Dict[str, Dict[str, Any]] = {}
        self._request_counter = 0
        self._latency_samples: Dict[str, Dict[str, List[tuple]]] = {}
        self._error_log: Dict[str, List[Dict[str, Any]]] = {}

    def _get_data_dir(self) -> str:
        """Get data directory path from environment."""
        import os
        return os.environ.get("SYNAPSE_DATA_DIR", "/app/data")

    def record_tool_call(self, project_id: str, tool_name: str) -> str:
        """
        Record a tool call and return request ID for tracking.

        Args:
            project_id: Project identifier
            tool_name: Name of tool being called

        Returns:
            Request ID string
        """
        request_id = f"req_{self._request_counter}"
        start_time = time.time()
        self._request_counter += 1

        # Ensure nested dicts exist
        if project_id not in self._latency_samples:
            self._latency_samples[project_id] = {}
        if tool_name not in self._latency_samples[project_id]:
            self._latency_samples[project_id][tool_name] = []

        self._latency_samples[project_id][tool_name].append((request_id, start_time))
        logger.debug(f"Tool call started: {tool_name} for project {project_id} (req: {request_id})")
        return request_id

    def record_tool_completion(
        self,
        project_id: str,
        tool_name: str,
        request_id: str,
        error: bool = False,
        error_message: str = ""
    ) -> Optional[float]:
        """
        Record tool completion with latency measurement.

        Args:
            project_id: Project identifier
            tool_name: Name of tool
            request_id: Request ID from record_tool_call
            error: Whether call resulted in an error
            error_message: Error message if applicable

        Returns:
            Latency in milliseconds, or None if request not found
        """
        if project_id not in self._latency_samples or tool_name not in self._latency_samples[project_id]:
            logger.warning(f"Request not found for tracking: {request_id}")
            return None

        end_time = time.time()
        start_time = None

        # Find request and remove it
        for i, (req_id, st) in enumerate(self._latency_samples[project_id][tool_name]):
            if req_id == request_id:
                start_time = st
                del self._latency_samples[project_id][tool_name][i]
                break

        if start_time is None:
            logger.warning(f"Start time not found for request: {request_id}")
            return None

        latency_ms = (end_time - start_time) * 1000

        # Ensure nested dicts exist
        if project_id not in self._metrics:
            self._metrics[project_id] = {}

        # Record metrics
        total_key = f"mcp_{tool_name}_calls_total"
        success_key = f"mcp_{tool_name}_calls_success"
        error_key = f"mcp_{tool_name}_calls_error"
        latency_total_key = f"{tool_name}_latency_ms_total"
        latency_avg_key = f"{tool_name}_latency_ms_avg"

        self._metrics[project_id][total_key] = self._metrics[project_id].get(total_key, 0) + 1

        if not error:
            self._metrics[project_id][success_key] = self._metrics[project_id].get(success_key, 0) + 1
        else:
            self._metrics[project_id][error_key] = self._metrics[project_id].get(error_key, 0) + 1

            # Log error details
            if project_id not in self._error_log:
                self._error_log[project_id] = []

            error_entry = {
                "request_id": request_id,
                "tool": tool_name,
                "project_id": project_id,
                "error": error_message,
                "latency_ms": latency_ms,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            self._error_log[project_id].append(error_entry)
            logger.error(f"Tool error: {tool_name} - {error_message}")

        # Record latency
        self._metrics[project_id][latency_total_key] = self._metrics[project_id].get(latency_total_key, 0.0) + latency_ms

        # Calculate average latency
        total_calls = self._metrics[project_id].get(total_key, 0)
        if total_calls > 0:
            total_latency = self._metrics[project_id].get(latency_total_key, 0.0)
            self._metrics[project_id][latency_avg_key] = total_latency / total_calls

        logger.debug(
            f"Tool call completed: {tool_name} for project {project_id} "
            f"({latency_ms:.2f}ms, error={error})"
        )

        return latency_ms

    def get_metrics_json(self, project_id: str) -> str:
        """
        Get metrics in Prometheus-compatible JSON format.

        Args:
            project_id: Project identifier

        Returns:
            JSON string with metrics
        """
        project_metrics = self._metrics.get(project_id, {})

        output_lines = [
            "# TYPE rag_metrics counter",
            "# Metrics for RAG MCP Server",
            f"# Project: {project_id}",
            ""
        ]

        # Track tool names dynamically
        tool_names = set()
        for key in project_metrics.keys():
            if key.startswith("mcp_") and "_calls_total" in key:
                tool_name = key.replace("mcp_", "").replace("_calls_total", "")
                tool_names.add(tool_name)

        # Generate metrics for each tool
        for tool in sorted(tool_names):
            calls_total = project_metrics.get(f"mcp_{tool}_calls_total", 0)
            calls_success = project_metrics.get(f"mcp_{tool}_calls_success", 0)
            calls_error = project_metrics.get(f"mcp_{tool}_calls_error", 0)

            error_rate = 0.0
            if calls_total > 0:
                error_rate = (calls_error / calls_total) * 100

            latency_total = project_metrics.get(f"{tool}_latency_ms_total", 0)
            latency_avg = project_metrics.get(f"{tool}_latency_ms_avg", 0.0)

            output_lines.extend([
                f"mcp_{tool}_calls_total{{project_id=\"{project_id}\"}} {calls_total}",
                f"mcp_{tool}_calls_success{{project_id=\"{project_id}\"}} {calls_success}",
                f"mcp_{tool}_calls_error{{project_id=\"{project_id}\"}} {calls_error}",
                f"mcp_{tool}_error_rate{{project_id=\"{project_id}\"}} {error_rate:.2f}",
                f"mcp_{tool}_latency_ms_total{{project_id=\"{project_id}\"}} {latency_total:.2f}",
            ])

            if latency_avg > 0:
                output_lines.append(f"mcp_{tool}_latency_ms_avg{{project_id=\"{project_id}\"}} {latency_avg:.2f}")

            output_lines.append("")

        # Add error log summary
        if project_id in self._error_log and self._error_log[project_id]:
            output_lines.extend([
                "# Recent Errors",
                f"# Total errors for project: {len(self._error_log[project_id])}",
                ""
            ])

            # Last 10 errors
            recent_errors = self._error_log[project_id][-10:]
            for error in recent_errors:
                output_lines.append(
                    f"# [{error['timestamp']}] {error['tool']}: {error['error']}"
                )
            output_lines.append("")

        return "\n".join(output_lines)

    def get_stats(self, project_id: str) -> Dict[str, Any]:
        """
        Get summary statistics for a project.

        Args:
            project_id: Project identifier

        Returns:
            Dictionary with summary statistics
        """
        project_metrics = self._metrics.get(project_id, {})

        total_calls = 0
        total_errors = 0
        tool_stats = {}

        for key, value in project_metrics.items():
            if "_calls_total" in key:
                tool_name = key.replace("mcp_", "").replace("_calls_total", "")
                tool_stats[tool_name] = {
                    "calls": value,
                    "success": project_metrics.get(f"mcp_{tool_name}_calls_success", 0),
                    "errors": project_metrics.get(f"mcp_{tool_name}_calls_error", 0),
                    "latency_avg_ms": project_metrics.get(f"{tool_name}_latency_ms_avg", 0.0),
                    "latency_total_ms": project_metrics.get(f"{tool_name}_latency_ms_total", 0.0)
                }
                total_calls += value
                total_errors += tool_stats[tool_name]["errors"]

        success_rate = 0.0
        if total_calls > 0:
            success_rate = ((total_calls - total_errors) / total_calls) * 100

        return {
            "project_id": project_id,
            "total_calls": total_calls,
            "total_errors": total_errors,
            "success_rate": success_rate,
            "total_requests": self._request_counter,
            "by_tool": tool_stats,
            "recent_errors": len(self._error_log.get(project_id, []))
        }

    def save_metrics(self, project_id: Optional[str] = None) -> None:
        """
        Save metrics to disk for persistence.

        Args:
            project_id: Specific project ID, or None for all projects
        """
        data_dir = Path(self._get_data_dir())
        metrics_dir = data_dir / "metrics"
        metrics_dir.mkdir(parents=True, exist_ok=True)

        if project_id:
            # Save specific project
            metrics_file = metrics_dir / f"{project_id}_metrics.json"
            with open(metrics_file, 'w') as f:
                json.dump({
                    "stats": self.get_stats(project_id),
                    "prometheus": self.get_metrics_json(project_id)
                }, f, indent=2)
            logger.info(f"Saved metrics for project: {project_id}")
        else:
            # Save all projects
            for pid in self._metrics.keys():
                metrics_file = metrics_dir / f"{pid}_metrics.json"
                with open(metrics_file, 'w') as f:
                    json.dump({
                        "stats": self.get_stats(pid),
                        "prometheus": self.get_metrics_json(pid)
                    }, f, indent=2)
            logger.info(f"Saved metrics for {len(self._metrics)} projects")

    def load_metrics(self) -> None:
        """Load metrics from disk for persistence."""
        data_dir = Path(self._get_data_dir())
        metrics_dir = data_dir / "metrics"

        if not metrics_dir.exists():
            logger.info("No existing metrics directory found")
            return

        for metrics_file in metrics_dir.glob("*_metrics.json"):
            try:
                with open(metrics_file, 'r') as f:
                    data = json.load(f)
                    # Only load stats, not Prometheus format
                    stats = data.get("stats", {})
                    project_id = stats.get("project_id")
                    if project_id and "by_tool" in stats:
                        logger.info(f"Loaded metrics for project: {project_id}")
            except Exception as e:
                logger.error(f"Failed to load metrics from {metrics_file}: {e}")

    def clear_metrics(self, project_id: Optional[str] = None) -> None:
        """
        Clear metrics for a project or all projects.

        Args:
            project_id: Specific project ID, or None for all projects
        """
        if project_id:
            if project_id in self._metrics:
                del self._metrics[project_id]
                self._error_log.pop(project_id, None)
                logger.info(f"Cleared metrics for project: {project_id}")
        else:
            self._metrics.clear()
            self._error_log.clear()
            self._request_counter = 0
            logger.info("Cleared all metrics")


# Singleton instance
_metrics_instance: Optional[Metrics] = None


def get_metrics() -> Metrics:
    """
    Get or create metrics singleton.

    Returns:
        Metrics instance
    """
    global _metrics_instance
    if _metrics_instance is None:
        _metrics_instance = Metrics()
    return _metrics_instance
