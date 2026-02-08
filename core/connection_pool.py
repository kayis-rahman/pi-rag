"""
SQLite Connection Pool - Thread-safe pool for SQLite connections.

Improves performance by reusing connections instead of creating new ones per query.
"""
import sqlite3
import threading
from typing import List
from contextlib import contextmanager
import logging

logger = logging.getLogger(__name__)


class SQLiteConnectionPool:
    """
    Thread-safe SQLite connection pool with automatic overflow handling.

    Features:
    - LIFO pool (last used = first recycled)
    - WAL mode for better concurrency
    - Automatic overflow handling
    - Graceful shutdown
    - Thread-safe operations
    """

    def __init__(self, db_path: str, pool_size: int = 5):
        """
        Initialize connection pool.

        Args:
            db_path: Path to SQLite database file
            pool_size: Number of connections to maintain in pool
        """
        self.db_path = db_path
        self.pool_size = pool_size
        self._pool: List[sqlite3.Connection] = []
        self._lock = threading.Lock()

        # Initialize pool with WAL mode for better concurrency
        logger.info(f"Initializing SQLiteConnectionPool for {db_path}, pool_size={pool_size}")

        for _ in range(pool_size):
            conn = sqlite3.connect(db_path, check_same_thread=False)
            conn.execute("PRAGMA journal_mode=WAL")  # Better concurrency
            conn.execute("PRAGMA synchronous=NORMAL")   # Balanced safety/speed
            conn.execute("PRAGMA foreign_keys=ON")      # Enable foreign key constraints
            self._pool.append(conn)

        logger.info(f"SQLiteConnectionPool initialized with {len(self._pool)} connections")

    @contextmanager
    def get_connection(self):
        """
        Get connection from pool (context manager).

        Yields:
            sqlite3.Connection: Active connection from pool

        Behavior:
            - LIFO: Last used connection first
            - Overflow: Creates temporary connection if pool exhausted
            - Return: Connection goes back to pool if not full
        """
        conn = None
        try:
            # Get connection from pool (LIFO)
            with self._lock:
                if self._pool:
                    conn = self._pool.pop()
                    logger.debug(f"Got connection from pool, pool size: {len(self._pool)}")
                else:
                    # Pool exhausted, create temporary connection
                    conn = sqlite3.connect(self.db_path, check_same_thread=False)
                    conn.execute("PRAGMA journal_mode=WAL")
                    conn.execute("PRAGMA synchronous=NORMAL")
                    logger.warning("Connection pool exhausted, created temporary connection")

            yield conn

        except Exception as e:
            # Connection failed, try to return to pool
            logger.error(f"Connection error: {e}")
            if conn is not None:
                with self._lock:
                    if len(self._pool) < self.pool_size:
                        self._pool.append(conn)
            raise

        finally:
            # Return connection to pool if it's a pooled connection
            if conn is not None:
                # Check if this is a pooled connection (not temporary)
                with self._lock:
                    # Simple heuristic: if we're at pool capacity, return it
                    if len(self._pool) < self.pool_size:
                        # Check if connection is not already in pool
                        in_pool = any(c is conn for c in self._pool)
                        if not in_pool:
                            self._pool.append(conn)
                            logger.debug(f"Returned connection to pool, pool size: {len(self._pool)}")

    def close_all(self):
        """Close all connections in pool."""
        with self._lock:
            logger.info(f"Closing {len(self._pool)} connections in pool")
            for conn in self._pool:
                try:
                    conn.close()
                except Exception as e:
                    logger.warning(f"Error closing connection: {e}")
            self._pool.clear()

    def get_pool_size(self) -> int:
        """Get current number of connections in pool."""
        with self._lock:
            return len(self._pool)

    def __del__(self):
        """Cleanup on object destruction."""
        try:
            self.close_all()
        except Exception:
            pass
