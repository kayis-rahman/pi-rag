"""
Query Result Cache - LRU cache with TTL for RAG search results.

Reduces latency for repeated queries by caching results.
"""
import hashlib
import time
from collections import OrderedDict
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)


class QueryCache:
    """
    LRU query result cache with TTL (Time To Live).

    Features:
    - LRU eviction (Least Recently Used)
    - TTL-based invalidation (5-minute default)
    - Hit/miss tracking
    - MD5 cache keys (deterministic)
    - Memory-efficient (ordered dict)
    - Statistics reporting
    """

    def __init__(self, max_size: int = 500, ttl_seconds: int = 300):
        """
        Initialize query cache.

        Args:
            max_size: Maximum number of entries in cache (LRU eviction)
            ttl_seconds: Time-to-live for cache entries (default: 5 minutes)

        Memory Calculation (max_size=500, dims=384):
            - Vector data: 500 entries × 384 dims × 4 bytes = 768KB
            - Metadata overhead: ~100KB
            - Total: ~868KB (fits comfortably in RAM)
        """
        self.cache: Dict[str, Dict[str, Any]] = OrderedDict()
        self.max_size = max_size
        self.ttl = ttl_seconds
        self.hits = 0
        self.misses = 0

        logger.info(f"QueryCache initialized: max_size={max_size}, ttl={ttl_seconds}s, "
                   f"estimated_memory=~{(max_size * 384 * 4 / 1024 / 1024):.1f}MB")

    def _get_key(self, query: str, top_k: int, project_id: str) -> str:
        """
        Generate deterministic cache key.

        Args:
            query: Search query text
            top_k: Number of results requested
            project_id: Project identifier (for isolation)

        Returns:
            MD5 hash of combined parameters
        """
        key_data = f"{query}:{top_k}:{project_id}"
        return hashlib.md5(key_data.encode()).hexdigest()

    def get(self, query: str, top_k: int, project_id: str) -> Optional[Dict[str, Any]]:
        """
        Get cached result if valid (not expired).

        Args:
            query: Search query
            top_k: Number of results
            project_id: Project ID

        Returns:
            Cached result dict or None if miss/expired
        """
        key = self._get_key(query, top_k, project_id)

        if key not in self.cache:
            self.misses += 1
            logger.debug(f"Cache MISS: query={query[:50]}..., key={key[:16]}...")
            return None

        entry = self.cache[key]
        age = time.time() - entry["timestamp"]

        # Check if entry expired
        if age >= self.ttl:
            self.misses += 1
            logger.debug(f"Cache EXPIRED: query={query[:50]}..., age={age:.1f}s, ttl={self.ttl}s")
            del self.cache[key]
            return None

        # Cache hit
        self.hits += 1
        logger.debug(f"Cache HIT: query={query[:50]}..., age={age:.1f}s, key={key[:16]}...")
        return entry["result"]

    def set(self, query: str, top_k: int, project_id: str, result: Dict[str, Any]) -> None:
        """
        Cache result with LRU eviction.

        Args:
            query: Search query
            top_k: Number of results
            project_id: Project ID
            result: Search results to cache
        """
        key = self._get_key(query, top_k, project_id)

        # Evict if full (remove oldest - LRU)
        if len(self.cache) >= self.max_size:
            evicted_key = next(iter(self.cache))
            del self.cache[evicted_key]
            logger.debug(f"Cache EVICTED: key={evicted_key[:16]}... (LRU)")

        self.cache[key] = {
            "result": result,
            "timestamp": time.time()
        }
        logger.debug(f"Cache SET: key={key[:16]}...")

    def invalidate(self, query: str, top_k: int, project_id: str) -> None:
        """
        Manually invalidate specific cache entry.

        Args:
            query: Query to invalidate
            top_k: Number of results
            project_id: Project ID
        """
        key = self._get_key(query, top_k, project_id)
        if key in self.cache:
            del self.cache[key]
            logger.debug(f"Cache INVALIDATED: key={key[:16]}...")

    def invalidate_all(self) -> None:
        """Clear entire cache."""
        count = len(self.cache)
        self.cache.clear()
        logger.info(f"Cache CLEARED: {count} entries removed")

    def get_stats(self) -> Dict[str, Any]:
        """
        Get cache statistics.

        Returns:
            Dict with hits, misses, hit_rate, size, max_size, ttl
        """
        total = self.hits + self.misses
        hit_rate = (self.hits / total * 100) if total > 0 else 0

        return {
            "hits": self.hits,
            "misses": self.misses,
            "total_requests": total,
            "hit_rate": hit_rate,
            "cache_size": len(self.cache),
            "max_size": self.max_size,
            "ttl_seconds": self.ttl,
            "eviction_policy": "LRU"
        }

    def __del__(self):
        """Cleanup on object destruction."""
        try:
            if hasattr(self, 'cache'):
                count = len(self.cache)
                logger.info(f"QueryCache destroyed: {count} entries were in cache")
        except Exception:
            pass
