"""
Metrics Collection Thread - Background daemon for periodic metrics collection.

Uses APScheduler to collect metrics at configurable intervals.
"""

import asyncio
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from datetime import datetime

from core.metrics_collector import get_metrics_collector

logger = logging.getLogger(__name__)


class MetricsCollectionThread:
    """
    Background thread for metrics collection.
    
    Runs periodic tasks:
    - Resource monitoring (CPU, memory, disk)
    - Data aggregation
    - Metrics cleanup
    """
    
    def __init__(self):
        """Initialize metrics collection thread."""
        self.scheduler = AsyncIOScheduler()
        self.collector = get_metrics_collector()
        self._is_running = False
        
        logger.info("Metrics collection thread initialized")
    
    async def start(self) -> None:
        """
        Start the metrics collection daemon.
        
        Will schedule periodic tasks:
        - System resource monitoring (every 1 second)
        - Metrics aggregation (every 1 minute)
        - Data cleanup (every 1 hour)
        """
        if self._is_running:
            logger.warning("Metrics collection thread already running")
            return
        
        self._is_running = True
        logger.info("Starting metrics collection daemon")
        
        # Schedule periodic tasks
        self._schedule_resource_monitoring()
        self._schedule_data_aggregation()
        self._schedule_data_cleanup()
        
        # Start scheduler
        self.scheduler.start()
        logger.info("Metrics collection daemon started successfully")
    
    async def stop(self) -> None:
        """
        Stop the metrics collection daemon gracefully.
        """
        if not self._is_running:
            logger.warning("Metrics collection thread not running")
            return
        
        logger.info("Stopping metrics collection daemon")
        
        # Shutdown scheduler
        self.scheduler.shutdown(wait=True)
        
        self._is_running = False
        logger.info("Metrics collection daemon stopped")
    
    def _schedule_resource_monitoring(self) -> None:
        """
        Schedule system resource monitoring every 1 second.
        """
        self.scheduler.add_job(
            self._collect_system_resources,
            'interval',
            seconds=1,
            id='resource_monitoring',
            max_instances=1,
            coalesce=True
        )
        logger.info("Scheduled resource monitoring: interval=1s")
    
    def _schedule_data_aggregation(self) -> None:
        """
        Schedule metrics aggregation every 1 minute.
        """
        self.scheduler.add_job(
            self._aggregate_metrics,
            'interval',
            seconds=60,
            id='data_aggregation',
            max_instances=1,
            coalesce=True
        )
        logger.info("Scheduled data aggregation: interval=60s")
    
    def _schedule_data_cleanup(self) -> None:
        """
        Schedule old data cleanup every 1 hour.
        """
        self.scheduler.add_job(
            self._cleanup_old_data,
            'interval',
            seconds=3600,
            id='data_cleanup',
            max_instances=1,
            coalesce=True
        )
        logger.info("Scheduled data cleanup: interval=3600s (1 hour)")
    
    async def _collect_system_resources(self) -> None:
        """
        Collect system resources (CPU, memory, disk, network).
        
        Will be stored to time-series database.
        """
        try:
            logger.debug("Collecting system resources")
            self.collector.record_system_resources()
            logger.debug("System resources collected successfully")
        except Exception as e:
            logger.error(f"Failed to collect system resources: {e}", exc_info=True)
    
    async def _aggregate_metrics(self) -> None:
        """
        Aggregate raw metrics for faster dashboard queries.
        
        Will create 1m, 5m, 1h aggregated metrics.
        """
        try:
            logger.debug("Aggregating metrics")
            
            # Placeholder: Aggregation logic will be implemented
            # This involves:
            # 1. Grouping raw metrics by type and time window
            # 2. Calculating avg, min, max, percentiles
            # 3. Storing to metrics_aggregated table
            # 4. Deleting raw metrics after aggregation
            
            logger.debug("Metrics aggregated successfully")
        except Exception as e:
            logger.error(f"Failed to aggregate metrics: {e}", exc_info=True)
    
    async def _cleanup_old_data(self) -> None:
        """
        Clean up old metrics data based on retention policy.
        
        Deletes metrics older than configured retention period (default: 90 days).
        """
        try:
            logger.debug("Cleaning up old metrics data")
            
            # Placeholder: Cleanup logic will be implemented
            # This involves:
            # 1. Querying for metrics older than retention period
            # 2. Deleting from metrics_raw table
            # 3. Deleting from metrics_aggregated table
            # 4. Deleting from alert_history table
            
            logger.debug("Old metrics data cleaned successfully")
        except Exception as e:
            logger.error(f"Failed to clean up old metrics data: {e}", exc_info=True)
    
    def get_scheduled_jobs(self) -> list:
        """
        Get list of all scheduled jobs.
        
        Returns:
            List of job IDs and next run times
        """
        jobs = []
        
        for job in self.scheduler.get_jobs():
            jobs.append({
                "id": job.id,
                "name": job.name,
                "next_run_time": job.next_run_time.isoformat() if job.next_run_time else None
            })
        
        return jobs
    
    def get_status(self) -> dict:
        """
        Get current status of metrics collection thread.
        
        Returns:
            Status information
        """
        return {
            "is_running": self._is_running,
            "scheduler_status": "running" if self._is_running else "stopped",
            "scheduled_jobs": len(self.scheduler.get_jobs()),
            "uptime": datetime.now().isoformat() if self._is_running else None
        }


# Singleton instance for easy access
_instance: Optional[MetricsCollectionThread] = None


def get_metrics_thread() -> MetricsCollectionThread:
    """
    Get singleton metrics collection thread instance.
    
    Returns:
        MetricsCollectionThread instance
    """
    global _instance
    
    if _instance is None:
        _instance = MetricsCollectionThread()
        logger.info("Metrics collection thread singleton created")
    
    return _instance
