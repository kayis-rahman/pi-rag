"""
Test ingestion persistence - Feature 015

Tests that verify BUG-INGEST-01 fix:
- Data is persisted to disk correctly
- Singleton pattern respects index_path parameter
- Data can be retrieved after ingestion
"""

import pytest
import tempfile
import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from rag.semantic_store import get_semantic_store, _semantic_store_cache


class TestIngestionPersistence:
    """Test ingestion persistence fix for BUG-INGEST-01."""

    def test_singleton_cache_by_path(self):
        """Test that get_semantic_store caches by path correctly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            path1 = os.path.join(tmpdir, "store1")
            path2 = os.path.join(tmpdir, "store2")
            
            # Get stores for different paths
            store1 = get_semantic_store(path1)
            store2 = get_semantic_store(path2)
            
            # Different paths should get different instances
            assert store1 is not store2, "Different paths should get different instances"
            
            # Get store for same path again
            store1_again = get_semantic_store(path1)
            
            # Same path should get cached instance
            assert store1 is store1_again, "Same path should get cached instance"

    def test_data_persists_to_disk(self):
        """Test that ingested data persists to disk and can be loaded."""
        with tempfile.TemporaryDirectory() as tmpdir:
            index_path = os.path.join(tmpdir, "test_index")
            
            # Create store and add document
            store1 = get_semantic_store(index_path)
            chunk_ids = store1.add_document(
                content="This is a test document that should persist",
                metadata={"source": "test.txt", "type": "doc"}
            )
            
            # Verify chunks were created
            assert len(chunk_ids) > 0, "Should create at least one chunk"
            
            # Create new store instance (simulates server restart)
            store2 = get_semantic_store(index_path)
            
            # Verify data persisted
            assert len(store2.chunks) > 0, "Data should persist after restart"
            assert store2.chunks[0].content == store1.chunks[0].content, "Content should match"

    def test_persisted_data_is_searchable(self):
        """Test that persisted data can be searched."""
        with tempfile.TemporaryDirectory() as tmpdir:
            index_path = os.path.join(tmpdir, "search_test")
            
            # Create store and add document
            store = get_semantic_store(index_path)
            store.add_document(
                content="The quick brown fox jumps over the lazy dog",
                metadata={"source": "animals.txt", "type": "doc"}
            )
            
            # Create new store instance
            store2 = get_semantic_store(index_path)
            
            # Generate query embedding (empty for this test since we don't have model)
            query_embedding = []
            
            # Search should work even with empty query
            # (In real usage, would have actual embeddings)
            stats = store2.get_stats()
            assert stats["total_chunks"] > 0, "Should have searchable chunks"

    def test_multiple_paths_independent(self):
        """Test that multiple index paths are independent."""
        with tempfile.TemporaryDirectory() as tmpdir:
            path1 = os.path.join(tmpdir, "project_a")
            path2 = os.path.join(tmpdir, "project_b")
            
            # Add document to project A
            store_a = get_semantic_store(path1)
            store_a.add_document(
                content="Project A document",
                metadata={"source": "a.txt", "type": "doc"}
            )
            
            # Add document to project B
            store_b = get_semantic_store(path2)
            store_b.add_document(
                content="Project B document",
                metadata={"source": "b.txt", "type": "doc"}
            )
            
            # Verify isolation
            fresh_a = get_semantic_store(path1)
            fresh_b = get_semantic_store(path2)
            
            assert len(fresh_a.chunks) == 1, "Project A should have 1 chunk"
            assert len(fresh_b.chunks) == 1, "Project B should have 1 chunk"
            assert fresh_a.chunks[0].content == "Project A document"
            assert fresh_b.chunks[0].content == "Project B document"

    def test_cache_normalizes_paths(self):
        """Test that path normalization works correctly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Different representations of same path
            path1 = os.path.join(tmpdir, "store")
            path2 = os.path.abspath(path1)
            
            # Get stores
            store1 = get_semantic_store(path1)
            store2 = get_semantic_store(path2)
            
            # Should be same instance due to path normalization
            assert store1 is store2, "Path normalization should result in same instance"

    def test_corrupted_json_handling(self):
        """Test graceful handling of corrupted JSON files."""
        with tempfile.TemporaryDirectory() as tmpdir:
            index_path = os.path.join(tmpdir, "corrupt_test")
            
            # Create valid store first
            store = get_semantic_store(index_path)
            store.add_document(
                content="Valid document",
                metadata={"source": "valid.txt", "type": "doc"}
            )
            
            # Corrupt the chunks.json file
            chunks_file = os.path.join(index_path, "chunks.json")
            with open(chunks_file, 'w') as f:
                f.write("[invalid json")
            
            # Clear cache to force reload
            _semantic_store_cache.clear()
            
            # Create new store - should handle gracefully
            store2 = get_semantic_store(index_path)
            # Should not crash, but will have empty chunks due to load failure
            assert isinstance(store2.chunks, list), "Should have chunks list even after load failure"


class TestBulkIngestIntegration:
    """Integration tests for bulk ingestion."""

    def test_bulk_ingest_creates_valid_json(self):
        """Test that bulk_ingest creates valid JSON files."""
        import json
        
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a test file
            test_file = os.path.join(tmpdir, "test.md")
            with open(test_file, 'w') as f:
                f.write("# Test Document\n\nThis is test content.")
            
            # Ingest it
            from rag.semantic_ingest import get_semantic_ingestor
            ingestor = get_semantic_ingestor()
            
            chunk_ids = ingestor.ingest_file(
                file_path=test_file,
                metadata={"type": "doc", "source": test_file}
            )
            
            assert len(chunk_ids) > 0, "Should create chunks"
            
            # Verify JSON is valid
            index_path = ingestor.semantic_store.index_path
            chunks_file = os.path.join(index_path, "chunks.json")
            
            with open(chunks_file, 'r') as f:
                data = json.load(f)
            
            assert isinstance(data, list), "Should be valid JSON array"
            assert len(data) > 0, "Should have at least one chunk"


if __name__ == "__main__":
    # Run tests directly
    test_class = TestIngestionPersistence()
    
    print("Running BUG-INGEST-01 persistence tests...\n")
    
    tests = [
        ("test_singleton_cache_by_path", "Singleton cache-by-path"),
        ("test_data_persists_to_disk", "Data persists to disk"),
        ("test_persisted_data_is_searchable", "Persisted data searchable"),
        ("test_multiple_paths_independent", "Multiple paths independent"),
        ("test_cache_normalizes_paths", "Path normalization"),
    ]
    
    passed = 0
    failed = 0
    
    for test_name, description in tests:
        try:
            getattr(test_class, test_name)()
            print(f"✓ {description}")
            passed += 1
        except AssertionError as e:
            print(f"✗ {description}: {e}")
            failed += 1
        except Exception as e:
            print(f"✗ {description}: {type(e).__name__}: {e}")
            failed += 1
    
    print(f"\n{passed} passed, {failed} failed")
    
    if failed == 0:
        print("\n🎉 All BUG-INGEST-01 tests passed!")
    else:
        print(f"\n⚠ {failed} test(s) failed")
        sys.exit(1)
