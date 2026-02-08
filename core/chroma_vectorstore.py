"""
ChromaDB Vector Store Implementation

Production-ready vector storage using ChromaDB.
Implements IVectorStore interface for RAG vector search.
"""

import chromadb
import numpy as np
import os
from typing import List, Dict, Any, Optional, Tuple
import logging

try:
    from .vectorstore_base import IVectorStore
except ImportError:
    from core.vectorstore_base import IVectorStore
from .embedding import get_embedding_service


logger = logging.getLogger(__name__)


class ChromaVectorStore(IVectorStore):
    """
    ChromaDB-based vector store implementation.

    Features:
        - Automatic HNSW indexing for fast search
        - Built-in metadata filtering
        - Automatic persistence
        - Efficient for 10K-1M vectors

    Usage:
        store = ChromaVectorStore("./data/chroma_rag_index")
        store.add(docs, vectors, metadata)
        results = store.search(query_vector, top_k=10, metadata_filters={"source": "test.py"})
    """

    def __init__(
        self,
        index_path: str = "./data/chroma_rag_index",
        collection_name: str = "rag_vectors",
        embedding_dimension: int = 1024  # BGE-M3 default
    ):
        """
        Initialize ChromaDB vector store.

        Args:
            index_path: Path to store ChromaDB data
            collection_name: Name of collection
            embedding_dimension: Dimension of embedding vectors
        """
        self.index_path = index_path
        self.collection_name = collection_name
        self.embedding_dimension = embedding_dimension

        # Create directory if needed
        os.makedirs(index_path, exist_ok=True)

        # Initialize ChromaDB client (persistent mode)
        self.client = chromadb.PersistentClient(path=index_path)

        # Get or create collection with cosine similarity
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            metadata={"hnsw:space": "cosine"}
        )

        logger.info(f"ChromaVectorStore initialized at {index_path}")

    def add(
        self,
        docs: List[str],
        vectors: List[List[float]],
        metadata: Optional[List[Dict[str, Any]]] = None
    ) -> None:
        """
        Add documents with vectors to store.

        Args:
            docs: List of document texts
            vectors: List of embedding vectors (same length as docs)
            metadata: Optional list of metadata dicts (same length as docs)
        """
        if len(docs) != len(vectors):
            raise ValueError(f"docs length ({len(docs)}) != vectors length ({len(vectors)})")

        if metadata and len(metadata) != len(docs):
            raise ValueError(f"metadata length ({len(metadata)}) != docs length ({len(docs)})")

        # Generate IDs for new documents
        existing_count = self.collection.count()
        ids = [f"doc_{existing_count + i}" for i in range(len(docs))]

        # Convert metadata to ChromaDB-compatible format
        # ChromaDB Metadata type allows: str, int, float, bool, None
        chroma_metadata = []
        if metadata:
            for meta in metadata:
                # Filter to only supported types
                filtered_meta = {}
                for k, v in meta.items():
                    if isinstance(v, (str, int, float, bool)) or v is None:
                        filtered_meta[k] = v
                    else:
                        # Convert complex types to string
                        filtered_meta[k] = str(v)
                chroma_metadata.append(filtered_meta)
        else:
            chroma_metadata = [{}] * len(docs)

        # Add to collection
        self.collection.add(
            documents=docs,
            embeddings=vectors,  # ChromaDB handles List[List[float]]
            metadatas=chroma_metadata,
            ids=ids
        )

        logger.debug(f"Added {len(docs)} documents to ChromaDB")

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
        # Validate query vector dimension
        if len(query_vector) != self.embedding_dimension:
            logger.warning(
                f"Query vector dimension ({len(query_vector)}) != "
                f"expected ({self.embedding_dimension})"
            )

        # Prepare query parameters
        query_params = {
            "query_embeddings": [query_vector],
            "n_results": top_k
        }

        # Add metadata filter if provided
        if metadata_filters:
            query_params["where"] = metadata_filters

        # Execute search
        results = self.collection.query(**query_params)

        # Parse results
        results_list = []
        if results['documents'] and len(results['documents'][0]) > 0:
            for i in range(len(results['documents'][0])):
                doc_text = results['documents'][0][i]
                distance = results['distances'][0][i]  # ChromaDB returns distance
                similarity = 1.0 - distance  # Convert to similarity (cosine)

                # Convert metadata from ChromaDB Metadata type to dict
                meta_dict = {}
                if results['metadatas'] and results['metadatas'][0]:
                    meta_dict = dict(results['metadatas'][0][i]) if results['metadatas'][0][i] else {}

                results_list.append((doc_text, similarity, meta_dict))

        return results_list

    def save(self, path: Optional[str] = None) -> None:
        """
        Persist store to disk.

        ChromaDB auto-persists, so this is a no-op but kept for interface compatibility.

        Args:
            path: Optional path (ignored - ChromaDB uses persistent path from __init__)
        """
        # ChromaDB auto-persists, no action needed
        logger.debug("ChromaVectorStore: save() called (auto-persisted)")

    def load(self, path: Optional[str] = None) -> None:
        """
        Load store from disk.

        ChromaDB auto-loads on initialization, so this is a no-op but kept for compatibility.

        Args:
            path: Optional path (ignored - ChromaDB uses persistent path from __init__)
        """
        # ChromaDB auto-loads on initialization
        logger.debug("ChromaVectorStore: load() called (auto-loaded)")

    def clear(self) -> None:
        """Remove all vectors from store."""
        # Delete and recreate collection
        self.client.delete_collection(self.collection_name)

        # Recreate collection
        self.collection = self.client.get_or_create_collection(
            name=self.collection_name,
            metadata={"hnsw:space": "cosine"}
        )

        logger.info(f"Cleared all vectors from {self.collection_name}")

    def get_stats(self) -> Dict[str, int]:
        """
        Get statistics about store.

        Returns:
            Dict with keys: total_docs, vector_dim
        """
        total_docs = self.collection.count()

        return {
            "total_docs": total_docs,
            "vector_dim": self.embedding_dimension
        }

    def delete_by_ids(self, ids: List[str]) -> None:
        """
        Delete specific documents by IDs.

        Args:
            ids: List of document IDs to delete
        """
        self.collection.delete(ids=ids)
        logger.debug(f"Deleted {len(ids)} documents")

    def get_by_ids(self, ids: List[str]) -> List[Dict[str, Any]]:
        """
        Get documents by IDs.

        Args:
            ids: List of document IDs

        Returns:
            List of dicts with keys: id, document, metadata, embedding (if requested)
        """
        results = self.collection.get(ids=ids, include=["documents", "metadatas"])

        documents = []
        for i, doc_id in enumerate(results['ids']):
            meta_dict = {}
            if results['metadatas']:
                meta_dict = dict(results['metadatas'][i]) if results['metadatas'][i] else {}

            documents.append({
                "id": doc_id,
                "document": results['documents'][i],
                "metadata": meta_dict
            })

        return documents
