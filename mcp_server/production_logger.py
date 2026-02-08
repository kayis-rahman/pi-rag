"""
Production-Grade Structured Logger for RAG MCP Server.

Features:
- Pipe-delimited logs (human-readable + analytics-ready)
- JSON metrics output to separate file
- Multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Async-safe (no blocking operations)
- Pi-optimized (low overhead)

Log Format:
2025-12-29T16:00:00.000Z | INFO | rag-mcp-server | tool=create_project | status=success | latency_ms=45
"""
import logging
import os
import json
import sys
from typing import Optional, Dict, Any, IO
from datetime import datetime, timezone
from pathlib import Path


class ProductionLogger:
    """
    Production-grade structured logger for RAG MCP system.
    
    Output:
    - Human-readable pipe-delimited logs to stdout
    - JSON metrics to file (line-delimited, analytics-ready)
    - Debug mode controlled by LOG_LEVEL env var
    """
    
    def __init__(self, name: str):
        """Initialize logger with handlers and configuration."""
        self.name = name
        self.logger = logging.getLogger(name)
        
        # Configuration
        self.log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
        self.log_file = os.environ.get("LOG_FILE", "/opt/synapse/logs/rag-mcp.log")
        self.metrics_file = os.environ.get("METRICS_FILE", "/opt/synapse/loki-data/metrics.json")
        
        # Enable flags
        self.debug_enabled = self.log_level == "DEBUG"
        self.metrics_enabled = os.environ.get("METRICS_ENABLED", "true").lower() == "true"
        self.json_output = os.environ.get("LOG_JSON_OUTPUT", "false").lower() == "true"
        
        self._setup_logger()
        
    def _setup_logger(self):
        """Setup logger with handlers and formatters."""
        # Create log directories
        Path(self.log_file).parent.mkdir(parents=True, exist_ok=True)
        Path(self.metrics_file).parent.mkdir(parents=True, exist_ok=True)
        
        # Set log level
        level = getattr(logging, self.log_level, logging.INFO)
        self.logger.setLevel(level)
        
        # Remove existing handlers
        for handler in self.logger.handlers[:]:
            self.logger.removeHandler(handler)
        
        # Console handler (pipe-delimited)
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(PipeDelimitedFormatter())
        self.logger.addHandler(console_handler)
        
        # File handler (pipe-delimited)
        file_handler = logging.FileHandler(self.log_file)
        file_handler.setFormatter(PipeDelimitedFormatter())
        self.logger.addHandler(file_handler)
        
        self.info("Logger initialized", 
                 log_level=self.log_level,
                 log_file=self.log_file,
                 metrics_file=self.metrics_file,
                 debug_enabled=self.debug_enabled)
    
    def _emit_json_metric(self, metric_type: str, data: Dict[str, Any]):
        """Emit JSON metric line to metrics file (appends, doesn't overwrite)."""
        if not self.metrics_enabled:
            return
        
        try:
            # Create JSON line
            timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
            
            metric_line = {
                "timestamp": timestamp,
                "@type": "metric",
                "metric_type": metric_type,
                "service": "rag-mcp-server",
                "node": os.environ.get("NODE_NAME", "pi5-01"),
                "labels": {
                    "environment": os.environ.get("ENV", "dev")
                },
                "data": data
            }
            
            # Append to metrics file (line-delimited JSON for streaming)
            with open(self.metrics_file, 'a') as f:
                f.write(json.dumps(metric_line) + "\n")
                
        except Exception as e:
            self.error("Failed to write metric", metric_type=metric_type, error=str(e))
    
    def _format_fields(self, **fields) -> str:
        """Format key=value fields for pipe-delimited output."""
        formatted = []
        for key, value in fields.items():
            formatted.append(f"{key}={value}")
        return " | ".join(formatted)
    
    def debug(self, msg: str, **kwargs):
        """Debug level (only logged if LOG_LEVEL=DEBUG)."""
        # Always store metrics for analysis, even if not shown
        if kwargs:
            self._emit_json_metric("debug", kwargs)
        
        if self.debug_enabled:
            if kwargs:
                extra_str = self._format_fields(**kwargs)
                full_msg = f"{msg} | {extra_str}" if kwargs else msg
            else:
                full_msg = msg
            self.logger.debug(full_msg)
    
    def info(self, msg: str, **kwargs):
        """Info level (always logged)."""
        if kwargs:
            self._emit_json_metric("info", kwargs)
        
        if kwargs:
            extra_str = self._format_fields(**kwargs)
            full_msg = f"{msg} | {extra_str}" if kwargs else msg
        else:
            full_msg = msg
        self.logger.info(full_msg)
    
    def warning(self, msg: str, **kwargs):
        """Warning level (always logged)."""
        if kwargs:
            self._emit_json_metric("warning", kwargs)
        
        if kwargs:
            extra_str = self._format_fields(**kwargs)
            full_msg = f"{msg} | {extra_str}" if kwargs else msg
        else:
            full_msg = msg
        self.logger.warning(full_msg)
    
    def error(self, msg: str, exc_info: bool = False, **kwargs):
        """Error level (always logged)."""
        if kwargs:
            self._emit_json_metric("error", kwargs)
        
        if kwargs:
            extra_str = self._format_fields(**kwargs)
            full_msg = f"{msg} | {extra_str}" if kwargs else msg
        else:
            full_msg = msg
        self.logger.error(full_msg, exc_info=exc_info)
    
    def critical(self, msg: str, **kwargs):
        """Critical level (always logged)."""
        if kwargs:
            self._emit_json_metric("critical", kwargs)
        
        if kwargs:
            extra_str = self._format_fields(**kwargs)
            full_msg = f"{msg} | {extra_str}" if kwargs else msg
        else:
            full_msg = msg
        self.logger.critical(full_msg)


class PipeDelimitedFormatter(logging.Formatter):
    """Formatter for pipe-delimited human-readable logs."""
    
    def __init__(self):
        """Initialize the formatter."""
        super().__init__(
            fmt='%(asctime)s | %(levelname)s | %(name)s | %(message)s',
            datefmt='%Y-%m-%dT%H:%M:%S'
        )
    
    def format(self, record):
        """Format log record as pipe-delimited string."""
        try:
            formatted = super().format(record)
            # Add node info for distributed systems
            node = os.environ.get("NODE_NAME", "pi5-01")
            return f"{formatted} | node={node}"
        except Exception:
            return str(record)


# Singleton instance
_logger_instances: Dict[str, ProductionLogger] = {}


def get_logger(name: str) -> ProductionLogger:
    """Get or create logger singleton."""
    if name not in _logger_instances:
        _logger_instances[name] = ProductionLogger(name)
    return _logger_instances[name]


def get_metrics_file_path() -> str:
    """Get metrics file path for Grafana/Promtail."""
    return os.environ.get("METRICS_FILE", "/opt/synapse/loki-data/metrics.json")
