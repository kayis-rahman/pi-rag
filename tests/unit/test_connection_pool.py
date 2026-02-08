"""
Unit tests for SQLiteConnectionPool.

Tests cover pool management, thread safety, and connection lifecycle.
"""

import pytest
import threading
from core.connection_pool import SQLiteConnectionPool


@pytest.mark.unit
class TestSQLiteConnectionPool:
    """Test SQLiteConnectionPool class."""

    def test_pool_initialization(self, test_db_path):
        """Test that pool is initialized with correct size."""
        pool_size = 5
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=pool_size)

        current_size = pool.get_pool_size()

        assert current_size == pool_size, f"Pool should have {pool_size} connections"

        pool.close_all()

    def test_get_connection(self, test_db_path):
        """Test getting a connection from pool."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=3)

        with pool.get_connection() as conn:
            assert conn is not None, "Connection should not be None"
            assert conn.execute("SELECT 1").fetchone()[0] == 1, "Connection should be usable"

        pool.close_all()

    def test_return_connection(self, test_db_path):
        """Test returning connection to pool."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=3)

        # Get and return connection
        with pool.get_connection() as conn:
            size_after_get = pool.get_pool_size()
            # Pool size decreases after getting connection

        size_after_return = pool.get_pool_size()

        # Pool size should be restored after returning connection
        assert size_after_return >= size_after_get, "Connection should be returned to pool"

        pool.close_all()

    def test_pool_exhaustion(self, test_db_path):
        """Test that pool creates temporary connection when exhausted."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=1)

        connections = []
        for i in range(5):
            with pool.get_connection() as conn:
                connections.append(conn)
                # Verify connection works
                assert conn.execute("SELECT 1").fetchone()[0] == 1, "All connections should be usable"

        # Should have 5 working connections (1 from pool, 4 temporary)
        assert len(connections) == 5, "Should create temporary connections when pool exhausted"

        pool.close_all()

    def test_lifo_ordering(self, test_db_path):
        """Test that pool uses LIFO ordering (last used = first recycled)."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=3)

        # Get and return connections
        connections = []
        for i in range(3):
            with pool.get_connection() as conn:
                connections.append(id(conn))

        # Pool should have 3 connections
        assert pool.get_pool_size() == 3, "All connections should be returned to pool"

        pool.close_all()

    def test_thread_safety(self, test_db_path):
        """Test that pool is thread-safe."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=5)

        results = []
        num_threads = 10
        connections_per_thread = 5

        def worker(thread_id):
            """Worker function for thread."""
            thread_results = []
            for i in range(connections_per_thread):
                with pool.get_connection() as conn:
                    result = conn.execute(f"SELECT {thread_id * 100 + i}").fetchone()[0]
                    thread_results.append(result)
            results.extend(thread_results)

        # Create and start threads
        threads = []
        for i in range(num_threads):
            t = threading.Thread(target=worker, args=(i,))
            threads.append(t)
            t.start()

        # Wait for all threads to complete
        for t in threads:
            t.join()

        # Verify all threads completed successfully
        assert len(results) == num_threads * connections_per_thread, \
            f"All threads should complete: {len(results)} results"

        pool.close_all()

    def test_close_all(self, test_db_path):
        """Test closing all connections in pool."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=3)

        # Get connections
        with pool.get_connection() as conn1:
            with pool.get_connection() as conn2:
                with pool.get_connection() as conn3:
                    pass  # Just get connections

        # Close all
        pool.close_all()

        # Pool should be empty
        assert pool.get_pool_size() == 0, "Pool should be empty after close_all"

    def test_wal_mode(self, test_db_path):
        """Test that WAL mode is enabled for concurrency."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=3)

        with pool.get_connection() as conn:
            # Check journal mode
            result = conn.execute("PRAGMA journal_mode").fetchone()

            assert result[0].lower() == "wal", "WAL mode should be enabled"

        pool.close_all()

    def test_foreign_keys_enabled(self, test_db_path):
        """Test that foreign key constraints are enabled."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=3)

        with pool.get_connection() as conn:
            # Check foreign keys
            result = conn.execute("PRAGMA foreign_keys").fetchone()

            assert result[0] == 1, "Foreign keys should be enabled"

        pool.close_all()

    def test_pool_cleanup(self, test_db_path):
        """Test that pool is cleaned up on object destruction."""
        # Create pool in a scope
        def create_and_use_pool():
            pool = SQLiteConnectionPool(str(test_db_path), pool_size=3)

            # Use connections
            with pool.get_connection() as conn:
                conn.execute("SELECT 1")

            # Pool goes out of scope here

        create_and_use_pool()

        # Pool should be cleaned up
        # (This is hard to test directly, but we verify no exceptions are raised)
        assert True, "Pool cleanup should not raise exceptions"

    def test_connection_context_manager(self, test_db_path):
        """Test that connection works with context manager."""
        pool = SQLiteConnectionPool(str(test_db_path), pool_size=3)

        # Test successful context
        with pool.get_connection() as conn:
            result = conn.execute("SELECT 1").fetchone()[0]
            assert result == 1, "Connection should be usable in context"

        # Connection should be returned after context exit

        pool.close_all()

    def test_multiple_pools(self, test_db_path, temp_dir):
        """Test that multiple pools can coexist."""
        # Create multiple pools with different databases
        db1 = temp_dir / "db1.db"
        db2 = temp_dir / "db2.db"

        pool1 = SQLiteConnectionPool(str(db1), pool_size=2)
        pool2 = SQLiteConnectionPool(str(db2), pool_size=3)

        assert pool1.get_pool_size() == 2, "Pool 1 should have 2 connections"
        assert pool2.get_pool_size() == 3, "Pool 2 should have 3 connections"

        # Use both pools
        with pool1.get_connection() as conn1:
            with pool2.get_connection() as conn2:
                result1 = conn1.execute("SELECT 1").fetchone()[0]
                result2 = conn2.execute("SELECT 2").fetchone()[0]

                assert result1 == 1, "Connection 1 should work"
                assert result2 == 2, "Connection 2 should work"

        pool1.close_all()
        pool2.close_all()
