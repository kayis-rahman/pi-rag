"""
MCP Server Package

This package provides a production-grade MCP server for RAG memory system.
"""

# Import the main module (this is the standard way to import submodules)
from .synapse_server import server, RAGMemoryBackend

__all__ = ['server', 'RAGMemoryBackend']
