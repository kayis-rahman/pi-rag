"""
Metrics Collector - Background daemon for collecting RAG quality metrics.

Collects metrics from:
- RAG operations (retrieval quality, tool performance)
- Memory usage (symbolic, episodic, semantic)
- Auto-learning effectiveness (episodes, facts)
- System resources (CPU, memory, disk, network)

Stores to time-series database with 1-second intervals.
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
import psutil

logger = logging.getLogger(__name__)


@dataclass
class RetrievalQualityMetric:
    """Retrieval quality metrics."""
    timestamp: datetime
    memory_type: str  # "symbolic" | "episodic" | "semantic"
    score: float
    query_count: int
    avg_latency_ms: float


@dataclass
class ToolPerformanceMetric:
    """Tool performance metrics."""
    timestamp: datetime
    tool_name: str
    operation_count: int
    error_count: int
    avg_latency_ms: float
    p50_latency_ms: float
    p95_latency_ms: float
    p99_latency_ms: float


@dataclass
class MemoryUsageMetric:
    """Memory usage metrics."""
    timestamp: datetime
    memory_type: str
    storage_mb: float
    document_count: int
    chunk_count: int


@dataclass
class AutoLearningMetric:
    """Auto-learning effectiveness metrics."""
    timestamp: datetime
    episodes_created: int
    facts_extracted: int
    avg_confidence: float
    deduplication_rate: float


@dataclass
class SystemResourceMetric:
    """System resource metrics."""
    timestamp: datetime
    cpu_percent: float
    memory_percent: float
    disk_usage_mb: float
    network_bytes_sent: int
    network_bytes_recv: int


class MetricsCollector:
    """
    Main metrics collector daemon.
    
    Collects metrics from all RAG components and stores to time-series database.
    Runs in background thread with configurable intervals.
    """
    
    def __init__(
        self,
        config_path: str = "./configs/rag_config.json",
        metrics_config_path: str = "./configs/metrics_config.json"
    ):
        """
        Initialize metrics collector.
        
        Args:
            config_path: Path to main RAG configuration
            metrics_config_path: Path to metrics-specific configuration
        """
        self.config_path = Path(config_path)
        self.metrics_config_path = Path(metrics_config_path)
        
        # Load configurations
        self.rag_config = self._load_rag_config()
        self.metrics_config = self._load_metrics_config()
        
        # Initialize metrics storage (in-memory for now, will be database later)
        self.metrics_buffer: List[Dict[str, Any]] = []
        self.max_buffer_size = self.metrics_config.get("buffer_size", 100)
        
        # Background task reference
        self._collection_task: Optional[asyncio.Task] = None
        self._is_running = False
        
        logger.info(
            f"MetricsCollector initialized: "
            f"enabled={self.metrics_config.get('collection', {}).get('enabled', False)}, "
            f"interval={self.metrics_config.get('collection', {}).get('interval_seconds', 1)}s, "
            f"buffer_size={self.max_buffer_size}"
        )
    
    def _load_rag_config(self) -> Dict[str, Any]:
        """Load RAG system configuration."""
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load RAG config from {self.config_path}: {e}")
            return {}
    
    def _load_metrics_config(self) -> Dict[str, Any]:
        """Load metrics-specific configuration."""
        try:
            if self.metrics_config_path.exists():
                with open(self.metrics_config_path, 'r') as f:
                    return json.load(f)
            
            # Return defaults if config doesn't exist
            return {
                "collection": {
                    "enabled": False,
                    "interval_seconds": 1,
                    "buffer_size": 100
                },
                "database": {
                    "type": "sqlite",
                    "path": "/opt/synapse/data/metrics.db"
                },
                "alerts": {
                    "enabled": False,
                    "debounce_seconds": 300
                }
            }
        except Exception as e:
            logger.error(f"Failed to load metrics config from {self.metrics_config_path}: {e}")
            return {}
    
    def _flush_metrics_to_storage(self):
        """
        Flush metrics buffer to time-series database.
        
        This is a placeholder that will be implemented in Phase 1.4.
        """
        if not self.metrics_buffer:
            return
        
        logger.info(f"Flushing {len(self.metrics_buffer)} metrics to database")
        
        # Placeholder: Log metrics (will be stored to database later)
        for metric in self.metrics_buffer:
            metric_type = metric.get("type", "unknown")
            timestamp = metric.get("timestamp", datetime.now())
            value = metric.get("value", 0)
            tags = json.dumps(metric.get("tags", {}))
            
            logger.debug(
                f"Metric: type={metric_type}, timestamp={timestamp}, "
                f"value={value}, tags={tags}"
            )
        
        # Clear buffer
        self.metrics_buffer.clear()
    
    # ===== PUBLIC API =====
    
    def record_retrieval_quality(
        self,
        memory_type: str,
        score: float,
        query_count: int,
        avg_latency_ms: float
    ) -> None:
        """
        Record retrieval quality metric.
        
        Args:
            memory_type: Type of memory (symbolic/episodic/semantic)
            score: Retrieval quality score (0.0-1.0)
            query_count: Number of queries
            avg_latency_ms: Average query latency
        """
        if not self.metrics_config.get("collection", {}).get("enabled", False):
            logger.debug("Metrics collection disabled, skipping retrieval quality")
            return
        
        metric = {
            "type": "retrieval_quality",
            "timestamp": datetime.now(),
            "value": score,
            "tags": {
                "memory_type": memory_type,
                "query_count": query_count,
                "avg_latency_ms": avg_latency_ms
            }
        }
        
        self.metrics_buffer.append(metric)
        
        # Flush if buffer is full
        if len(self.metrics_buffer) >= self.max_buffer_size:
            self._flush_metrics_to_storage()
    
    def record_tool_performance(
        self,
        tool_name: str,
        operation_count: int = 1,
        error_count: int = 0,
        avg_latency_ms: float = 0,
        p50_latency_ms: Optional[float] = None,
        p95_latency_ms: Optional[float] = None,
        p99_latency_ms: Optional[float] = None
    ) -> None:
        """
        Record tool performance metric.
        
        Args:
            tool_name: Name of the tool (e.g., "sy.mem.search")
            operation_count: Number of operations
            error_count: Number of errors
            avg_latency_ms: Average latency in milliseconds
            p50_latency_ms: 50th percentile latency
            p95_latency_ms: 95th percentile latency
            p99_latency_ms: 99th percentile latency
        """
        if not self.metrics_config.get("collection", {}).get("enabled", False):
            logger.debug("Metrics collection disabled, skipping tool performance")
            return
        
        metric = {
            "type": "tool_performance",
            "timestamp": datetime.now(),
            "value": avg_latency_ms,
            "tags": {
                "tool_name": tool_name,
                "operation_count": operation_count,
                "error_count": error_count,
                "p50_latency_ms": p50_latency_ms,
                "p95_latency_ms": p95_latency_ms,
                "p99_latency_ms": p99_latency_ms
            }
        }
        
        self.metrics_buffer.append(metric)
        
        # Flush if buffer is full
        if len(self.metrics_buffer) >= self.max_buffer_size:
            self._flush_metrics_to_storage()
    
    def record_memory_usage(
        self,
        memory_type: str,
        storage_mb: float,
        document_count: int,
        chunk_count: int
    ) -> None:
        """
        Record memory usage metric.
        
        Args:
            memory_type: Type of memory (symbolic/episodic/semantic)
            storage_mb: Storage used in MB
            document_count: Number of documents
            chunk_count: Number of chunks
        """
        if not self.metrics_config.get("collection", {}).get("enabled", False):
            logger.debug("Metrics collection disabled, skipping memory usage")
            return
        
        metric = {
            "type": "memory_usage",
            "timestamp": datetime.now(),
            "value": storage_mb,
            "tags": {
                "memory_type": memory_type,
                "document_count": document_count,
                "chunk_count": chunk_count
            }
        }
        
        self.metrics_buffer.append(metric)
        
        # Flush if buffer is full
        if len(self.metrics_buffer) >= self.max_buffer_size:
            self._flush_metrics_to_storage()
    
    def record_auto_learning(
        self,
        episodes_created: int,
        facts_extracted: int,
        avg_confidence: float,
        deduplication_rate: float = 0.0
    ) -> None:
        """
        Record auto-learning effectiveness metric.
        
        Args:
            episodes_created: Number of episodes created
            facts_extracted: Number of facts extracted
            avg_confidence: Average episode confidence
            deduplication_rate: Rate of deduplication (0.0-1.0)
        """
        if not self.metrics_config.get("collection", {}).get("enabled", False):
            logger.debug("Metrics collection disabled, skipping auto-learning")
            return
        
        metric = {
            "type": "auto_learning",
            "timestamp": datetime.now(),
            "value": episodes_created,  # Primary metric
            "tags": {
                "facts_extracted": facts_extracted,
                "avg_confidence": avg_confidence,
                "deduplication_rate": deduplication_rate
            }
        }
        
        self.metrics_buffer.append(metric)
        
        # Flush if buffer is full
        if len(self.metrics_buffer) >= self.max_buffer_size:
            self._flush_metrics_to_storage()
    
    def record_system_resources(self) -> SystemResourceMetric:
        """
        Collect and record system resource metrics.
        
        Returns:
            System resource metric with current values
        """
        if not self.metrics_config.get("collection", {}).get("enabled", False):
            logger.debug("Metrics collection disabled, skipping system resources")
            return SystemResourceMetric(
                timestamp=datetime.now(),
                cpu_percent=0,
                memory_percent=0,
                disk_usage_mb=0,
                network_bytes_sent=0,
                network_bytes_recv=0
            )
        
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # Memory usage
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            
            # Disk usage
            disk = psutil.disk_usage('/opt/synapse/data')
            disk_usage_mb = disk.used / (1024 * 1024)
            
            # Network usage
            net_io = psutil.net_io_counters()
            network_bytes_sent = net_io.bytes_sent
            network_bytes_recv = net_io.bytes_recv
            
            metric = SystemResourceMetric(
                timestamp=datetime.now(),
                cpu_percent=cpu_percent,
                memory_percent=memory_percent,
                disk_usage_mb=disk_usage_mb,
                network_bytes_sent=network_bytes_sent,
                network_bytes_recv=network_bytes_recv
            )
            
            # Convert to dict for buffer
            metric_dict = {
                "type": "system_resources",
                "timestamp": metric.timestamp,
                "value": cpu_percent,  # Primary metric
                "tags": {
                    "memory_percent": metric.memory_percent,
                    "disk_usage_mb": metric.disk_usage_mb,
                    "network_bytes_sent": metric.network_bytes_sent,
                    "network_bytes_recv": metric.network_bytes_recv
                }
            }
            
            self.metrics_buffer.append(metric_dict)
            
            # Flush if buffer is full
            if len(self.metrics_buffer) >= self.max_buffer_size:
                self._flush_metrics_to_storage()
            
            return metric
            
        except Exception as e:
            logger.error(f"Failed to collect system resources: {e}")
            return SystemResourceMetric(
                timestamp=datetime.now(),
                cpu_percent=0,
                memory_percent=0,
                disk_usage_mb=0,
                network_bytes_sent=0,
                network_bytes_recv=0
            )
    
    def get_buffer_stats(self) -> Dict[str, Any]:
        """
        Get statistics about metrics buffer.
        
        Returns:
            Dict with buffer statistics
        """
        total_metrics = len(self.metrics_buffer)
        metric_types = {}
        
        for metric in self.metrics_buffer:
            metric_type = metric.get("type", "unknown")
            metric_types[metric_type] = metric_types.get(metric_type, 0) + 1
        
        return {
            "total_metrics": total_metrics,
            "metric_types": metric_types,
            "buffer_size": len(self.metrics_buffer),
            "max_buffer_size": self.max_buffer_size,
            "buffer_utilization": f"{(total_metrics / self.max_buffer_size) * 100:.1f}%"
        }
    
    def start(self) -> None:
        """
        Start metrics collection daemon.
        
        Will start background collection thread when implemented.
        """
        if self._is_running:
            logger.warning("Metrics collector is already running")
            return
        
        self._is_running = True
        logger.info("Starting metrics collection daemon")
        
        # Placeholder: Start background thread for periodic collection
        # This will be implemented in Task 1.4
        logger.info("Background collection thread not yet implemented (placeholder)")
    
    def stop(self) -> None:
        """
        Stop metrics collection daemon.
        """
        logger.info("Stopping metrics collection daemon")
        self._is_running = False
        
        # Placeholder: Stop background thread
        # This will be implemented in Task 1.4
        
        # Flush any remaining metrics
        if self.metrics_buffer:
            self._flush_metrics_to_storage()
        
        logger.info(f"Metrics collector stopped. Buffer flushed.")


# Singleton instance for easy access
_collector_instance: Optional[MetricsCollector] = None


def get_metrics_collector() -> MetricsCollector:
    """
    Get singleton metrics collector instance.
    
    Returns:
        MetricsCollector instance
    """
    global _collector_instance
    
    if _collector_instance is None:
        _collector_instance = MetricsCollector()
        logger.info("Metrics collector singleton created")
    
    return _collector_instance
