"""
Vector Store Factory

Factory pattern for creating vector store implementations.
Supports switching between ChromaDB and legacy implementations.
"""

import os
from typing import Dict, Any, Optional

from .vectorstore_base import IVectorStore, ISemanticStore
from .vectorstore import VectorStore
from .semantic_store import SemanticStore, get_semantic_store
from .chroma_vectorstore import ChromaVectorStore
from .chroma_semantic_store import ChromaSemanticStore
from .embedding import get_embedding_service


def get_vector_store(config: Dict[str, Any]) -> IVectorStore:
    """
    Create vector store based on configuration.

    Args:
        config: Configuration dict with keys:
            - vector_backend: "chromadb" or "legacy"
            - index_path: Path to store vectors

    Returns:
        IVectorStore implementation

    Raises:
        ValueError: If backend is not supported
    """
    backend = config.get("vector_backend", "chromadb")
    index_path = config.get("index_path", "./data/rag_index")

    if backend == "chromadb":
        return ChromaVectorStore(index_path=index_path)
    elif backend == "legacy":
        return VectorStore(index_path=index_path)
    else:
        raise ValueError(f"Unsupported vector backend: {backend}. Use 'chromadb' or 'legacy'.")


def get_semantic_store_config(
    config: Dict[str, Any]
) -> ISemanticStore:
    """
    Create semantic store based on configuration.

    Args:
        config: Configuration dict with keys:
            - vector_backend: "chromadb" or "legacy"
            - index_path: Path to store semantic index

    Returns:
        ISemanticStore implementation

    Raises:
        ValueError: If backend is not supported
    """
    backend = config.get("vector_backend", "chromadb")
    index_path = config.get("index_path", "./data/semantic_index")
    embedding_service = get_embedding_service()

    if backend == "chromadb":
        return ChromaSemanticStore(
            index_path=index_path,
            embedding_service=embedding_service
        )
    elif backend == "legacy":
        return SemanticStore(
            index_path=index_path,
            embedding_service=embedding_service
        )
    else:
        raise ValueError(f"Unsupported vector backend: {backend}. Use 'chromadb' or 'legacy'.")
