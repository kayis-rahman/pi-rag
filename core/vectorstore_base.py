"""
Vector Store Abstraction Layer

Defines interfaces for vector storage implementations.
Allows swapping between different backends (ChromaDB, legacy, etc.).
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional, Tuple


class IVectorStore(ABC):
    """
    Abstract interface for vector storage implementations.

    Methods:
        add: Add documents with vectors to the store
        search: Search for similar vectors
        save: Persist the store to disk
        load: Load the store from disk
        clear: Remove all vectors from the store
        get_stats: Get statistics about the store
    """

    @abstractmethod
    def add(
        self,
        docs: List[str],
        vectors: List[List[float]],
        metadata: Optional[List[Dict[str, Any]]] = None
    ) -> None:
        """
        Add documents with their vectors to the store.

        Args:
            docs: List of document texts
            vectors: List of embedding vectors (same length as docs)
            metadata: Optional list of metadata dicts (same length as docs)
        """
        pass

    @abstractmethod
    def search(
        self,
        query_vector: List[float],
        top_k: int = 3,
        metadata_filters: Optional[Dict[str, Any]] = None
    ) -> List[Tuple[str, float, Dict[str, Any]]]:
        """
        Search for similar vectors.

        Args:
            query_vector: Query embedding vector
            top_k: Number of results to return
            metadata_filters: Optional metadata filters

        Returns:
            List of tuples: (doc_text, similarity_score, metadata)
        """
        pass

    @abstractmethod
    def save(self, path: Optional[str] = None) -> None:
        """
        Persist the store to disk.

        Args:
            path: Optional path to save to (uses default if not provided)
        """
        pass

    @abstractmethod
    def load(self, path: Optional[str] = None) -> None:
        """
        Load the store from disk.

        Args:
            path: Optional path to load from (uses default if not provided)
        """
        pass

    @abstractmethod
    def clear(self) -> None:
        """Remove all vectors from the store."""
        pass

    @abstractmethod
    def get_stats(self) -> Dict[str, int]:
        """
        Get statistics about the store.

        Returns:
            Dict with keys like 'total_docs', 'vector_dim', 'total_vectors'
        """
        pass


class ISemanticStore(ABC):
    """
    Abstract interface for semantic memory storage.

    Methods:
        add_document: Add a document with chunking
        search: Search for similar content
        get_chunk_by_id: Get a specific chunk
        delete_document: Delete a document by ID
        get_stats: Get statistics
        save: Persist to disk
        load: Load from disk
    """

    @abstractmethod
    def add_document(
        self,
        content: str,
        metadata: Dict[str, Any],
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ) -> List[str]:
        """
        Add a document with automatic chunking.

        Args:
            content: Document text content
            metadata: Document metadata (source, type, etc.)
            chunk_size: Target chunk size in characters
            chunk_overlap: Overlap between chunks

        Returns:
            List of chunk IDs created
        """
        pass

    @abstractmethod
    def search(
        self,
        query: str,
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None,
        min_score: float = 0.3,
        return_embeddings: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Search for similar content.

        Args:
            query: Search query text
            top_k: Number of results
            filters: Optional metadata filters
            min_score: Minimum similarity score
            return_embeddings: Whether to include embeddings in results

        Returns:
            List of result dicts with keys: chunk_id, content, score, metadata, etc.
        """
        pass

    @abstractmethod
    def get_chunk_by_id(self, chunk_id: str) -> Any:
        """
        Get a specific chunk by ID.

        Args:
            chunk_id: Chunk identifier

        Returns:
            Chunk object if found, None otherwise
        """
        pass

    @abstractmethod
    def delete_document(self, document_id: str) -> int:
        """
        Delete all chunks for a document.

        Args:
            document_id: Document identifier

        Returns:
            Number of chunks deleted
        """
        pass

    @abstractmethod
    def get_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the store.

        Returns:
            Dict with keys: total_chunks, total_documents, etc.
        """
        pass

    @abstractmethod
    def save(self) -> None:
        """Persist the store to disk."""
        pass

    @abstractmethod
    def load(self) -> None:
        """Load the store from disk."""
        pass
