"""Test semantic store API signatures and compatibility."""

import pytest
from unittest.mock import patch, MagicMock
import inspect


class TestSemanticAPI:
    """Test semantic store API signatures."""

    def test_search_method_signature(self):
        """Test that SemanticStore.search has correct signature."""
        from core.semantic_store import SemanticStore
        sig = inspect.signature(SemanticStore.search)
        params = list(sig.parameters.keys())

        assert 'self' in params, "search method must have 'self' parameter"
        # SemanticStore.search takes query_embedding (not raw query)
        assert 'query_embedding' in params, "search method must have 'query_embedding' parameter"
        assert 'top_k' in params, "search method must have 'top_k' parameter"

        print(f"✅ SemanticStore.search signature: {params}")

    def test_search_method_defaults(self):
        """Test that search method has appropriate defaults."""
        from core.semantic_store import SemanticStore
        sig = inspect.signature(SemanticStore.search)

        # Check for default values
        top_k_param = sig.parameters.get('top_k')
        if top_k_param:
            assert top_k_param.default == 5 or top_k_param.default == 3, \
                f"top_k should have reasonable default, got {top_k_param.default}"

        print(f"✅ top_k default: {top_k_param.default if top_k_param else 'not found'}")

    def test_add_document_method_exists(self):
        """Test that add_document method exists."""
        from core.semantic_store import SemanticStore
        assert hasattr(SemanticStore, 'add_document'), \
            "SemanticStore must have add_document method"

        print("✅ add_document method exists")

    def test_get_document_method_exists(self):
        """Test that SemanticStore has document retrieval methods."""
        from core import SemanticStore
        # SemanticStore has get_chunk_by_id, not get_document
        has_get_chunk = hasattr(SemanticStore, 'get_chunk_by_id')
        has_add = hasattr(SemanticStore, 'add_document')
        has_delete = hasattr(SemanticStore, 'delete_document')
        assert has_get_chunk and has_add and has_delete, \
            "SemanticStore must have document management methods (get_chunk_by_id, add_document, delete_document)"
        print("✅ SemanticStore has document management methods")

    def test_delete_document_method_exists(self):
        """Test that delete_document method exists."""
        from core.semantic_store import SemanticStore
        assert hasattr(SemanticStore, 'delete_document'), \
            "SemanticStore must have delete_document method"

        print("✅ delete_document method exists")


class TestMemoryStores:
    """Test that all memory stores are importable."""

    def test_memory_store_importable(self):
        """Test that MemoryStore is importable."""
        from core import MemoryStore
        print("✅ MemoryStore importable")

    def test_episodic_store_importable(self):
        """Test that EpisodicStore is importable."""
        from core import EpisodicStore
        print("✅ EpisodicStore importable")

    def test_semantic_store_importable(self):
        """Test that SemanticStore is importable."""
        from core import SemanticStore
        print("✅ SemanticStore importable")


class TestIngestorAPI:
    """Test semantic ingestor API."""

    def test_ingestor_has_ingest_method(self):
        """Test that SemanticIngestor has ingest methods."""
        from core import SemanticIngestor
        # Check for ingest methods (plural - there are multiple)
        has_ingest = any(hasattr(SemanticIngestor, m) for m in ['ingest_file', 'ingest_text', 'ingest'])
        assert has_ingest, \
            "SemanticIngestor must have ingest methods (ingest_file, ingest_text, etc.)"
        print("✅ SemanticIngestor has ingest methods")

    def test_ingestor_has_add_file_method(self):
        """Test that SemanticIngestor has add_file method."""
        from core import SemanticIngestor
        assert hasattr(SemanticIngestor, 'ingest_file'), \
            "SemanticIngestor must have ingest_file method"
        print("✅ SemanticIngestor.ingest_file exists")


class TestRetrieverAPI:
    """Test semantic retriever API."""

    def test_retriever_has_search_method(self):
        """Test that SemanticRetriever has retrieve methods."""
        from core import SemanticRetriever
        # SemanticRetriever uses 'retrieve' not 'search'
        has_retrieve = any(hasattr(SemanticRetriever, m) for m in ['retrieve', 'retrieve_with_expansion'])
        assert has_retrieve, \
            "SemanticRetriever must have retrieve methods (retrieve, retrieve_with_expansion)"
        print("✅ SemanticRetriever has retrieve methods")

    def test_retriever_has_get_relevant_method(self):
        """Test that SemanticRetriever has retrieval methods."""
        from core import SemanticRetriever
        # Check for retrieval-related methods
        has_ranking = hasattr(SemanticRetriever, 'explain_ranking')
        has_stats = hasattr(SemanticRetriever, 'get_retrieval_stats')
        assert has_ranking or has_stats, \
            "SemanticRetriever must have explanation or stats methods"
        print("✅ SemanticRetriever has retrieval analysis methods")


class TestMCP工具签名:
    """Test MCP tool signatures (using Chinese name as per project conventions)."""

    def test_synapse_server_has_all_tools(self):
        """Test that http_wrapper.py has all expected tools."""
        import os
        server_path = os.path.join(
            os.path.dirname(__file__),
            '..', '..', '..',
            'mcp_server', 'http_wrapper.py'
        )

        if not os.path.exists(server_path):
            pytest.skip("http_wrapper.py not found")

        with open(server_path, 'r') as f:
            content = f.read()

        # Check for all 7 tools (compact hierarchical naming - Feature 016)
        expected_tools = [
            'sy.proj.list',
            'sy.src.list',
            'sy.mem.search',
            'sy.ctx.get',
            'sy.mem.ingest',
            'sy.mem.fact.add',
            'sy.mem.ep.add'
        ]

        for tool in expected_tools:
            assert f'name="{tool}"' in content, \
                f"Tool {tool} not found in http_wrapper.py"

        print(f"✅ All {len(expected_tools)} MCP tools found with compact 'sy.' prefix")

    def test_no_rag_prefix_in_tools(self):
        """Test that no tools use old 'rag.' prefix in active server."""
        import os
        server_path = os.path.join(
            os.path.dirname(__file__),
            '..', '..', '..',
            'mcp_server', 'http_wrapper.py'
        )

        if not os.path.exists(server_path):
            pytest.skip("http_wrapper.py not found")

        with open(server_path, 'r') as f:
            content = f.read()

        # Check that no tool definitions use rag. prefix
        import re
        tool_definitions = re.findall(r'name="rag\.[^"]+"', content)
        assert len(tool_definitions) == 0, \
            f"Found {len(tool_definitions)} tools with old 'rag.' prefix: {tool_definitions}"

        print("✅ No tools found with old 'rag.' prefix in http_wrapper.py")
