"""
Retriever - Combines vector store and embedding service for document retrieval.
"""

import json
import os
from typing import List, Dict, Any, Optional, Tuple, Callable

from .vectorstore import VectorStore
from .embedding import EmbeddingService, get_embedding_service
from .query_expander import get_query_expander
from .logger import get_logger
logger = get_logger(__name__)


class Retriever:
    """
    Retrieves relevant documents based on semantic similarity.
    
    Usage:
        retriever = Retriever()
        results = retriever.search("How does authentication work?", top_k=3)
    """
    
    def __init__(
        self,
        config_path: str = "./configs/rag_config.json",
        embedding_service: Optional[EmbeddingService] = None,
        vector_store: Optional[VectorStore] = None
    ):
        self.config_path = config_path
        self._load_config()
        
        # Use provided services or create defaults
        self.embedding_service = embedding_service or get_embedding_service(config_path)
        self.vector_store = vector_store or VectorStore(self.index_path)
    
    def _load_config(self) -> None:
        """Load configuration from JSON file."""
        self.top_k = 3
        self.index_path = "./data/rag_index"
        self.min_score = 0.0
        self.query_expansion_enabled = False
        self.num_expansions = 3

        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                self.top_k = config.get("top_k", 3)
                self.index_path = config.get("index_path", "./data/rag_index")
                self.min_score = config.get("min_retrieval_score", 0.0)
                self.query_expansion_enabled = config.get("query_expansion_enabled", False)
                self.num_expansions = config.get("num_expansions", 3)
        except Exception as e:
            logger.warning(f"Failed to load retriever config: {e}")
    
    def search(
        self,
        query: str,
        top_k: Optional[int] = None,
        metadata_filters: Optional[Dict[str, Any]] = None,
        min_score: Optional[float] = None
    ) -> List[Dict[str, Any]]:
        """
        Search for relevant documents.
        
        Args:
            query: Search query text
            top_k: Number of results to return (default: from config)
            metadata_filters: Optional filters to apply
            min_score: Minimum similarity score (0-1)
            
        Returns:
            List of dicts with 'content', 'score', and 'metadata'
        """
        k = top_k or self.top_k
        score_threshold = min_score if min_score is not None else self.min_score

        # Generate query embedding
        query_embedding = self.embedding_service.embed_single(query)

        if not query_embedding:
            return []
        
        # Search vector store
        results = self.vector_store.search(
            query_vector=query_embedding,
            top_k=k,
            metadata_filters=metadata_filters
        )
        
        # Format results
        formatted = []
        for content, score, metadata in results:
            if score >= score_threshold:
                formatted.append({
                    "content": content,
                    "score": score,
                    "metadata": metadata
                })
        
        return formatted
    
    def search_with_context(
        self,
        query: str,
        top_k: Optional[int] = None,
        metadata_filters: Optional[Dict[str, Any]] = None,
        use_expansion: Optional[bool] = None
    ) -> Tuple[str, List[Dict[str, Any]]]:
        """
        Search and return formatted context string.

        Args:
            query: Search query text
            top_k: Number of results
            metadata_filters: Optional filters
            use_expansion: Use query expansion (default: from config)

        Returns:
            Tuple of (context_string, raw_results)
        """
        # Determine if expansion should be used
        should_expand = use_expansion if use_expansion is not None else self.query_expansion_enabled

        # Search with or without expansion
        if should_expand:
            results = self.search_with_expansion(query, top_k, metadata_filters)
        else:
            results = self.search(query, top_k, metadata_filters)

        logger.debug(f"Retrieval results: {results}")
        if not results:
            return "", []
        
        # Build context string
        context_parts = []
        for i, result in enumerate(results, 1):
            source = result["metadata"].get("source", "unknown")
            content = result["content"]
            score = result["score"]
            context_parts.append(
                f"[Source {i}: {source} (relevance: {score:.2f})]\n{content}"
            )
        
        context = "\n\n---\n\n".join(context_parts)
        return context, results

    def search_with_expansion(
        self,
        query: str,
        top_k: Optional[int] = None,
        metadata_filters: Optional[Dict[str, Any]] = None,
        min_score: Optional[float] = None,
        num_expansions: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Search with query expansion for better recall.

        Expands query using multi-query strategy and merges results.

        Args:
            query: Search query text
            top_k: Number of results to return (default: from config)
            metadata_filters: Optional filters to apply
            min_score: Minimum similarity score (0-1)
            num_expansions: Number of expansions (default: from config)

        Returns:
            List of dicts with 'content', 'score', and 'metadata'
        """
        k = top_k or self.top_k
        score_threshold = min_score if min_score is not None else self.min_score
        expansions = num_expansions or self.num_expansions

        # Get query expander
        expander = get_query_expander(num_expansions=expansions)

        # Define search function for expander
        def _search_func(q: str, top_k: int, metadata_filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
            """Internal search function."""
            query_embedding = self.embedding_service.embed_single(q)
            if not query_embedding:
                return []

            results = self.vector_store.search(
                query_vector=query_embedding,
                top_k=top_k,
                metadata_filters=metadata_filters
            )

            formatted = []
            for content, score, metadata in results:
                if score >= score_threshold:
                    formatted.append({
                        "content": content,
                        "score": score,
                        "metadata": metadata
                    })

            return formatted

        # Use expander's expand_and_search
        return expander.expand_and_search(
            query=query,
            search_func=lambda q, **kw: _search_func(q, kw.get('top_k', k), kw.get('metadata_filters')),
            top_k=k,
            metadata_filters=metadata_filters
        )

    def add_documents(
        self,
        documents: List[str],
        metadata: Optional[List[Dict[str, Any]]] = None
    ) -> int:
        """
        Add documents to the index.
        
        Args:
            documents: List of document texts
            metadata: Optional metadata for each document
            
        Returns:
            Number of documents added
        """
        if not documents:
            return 0
        
        # Generate embeddings
        embeddings = self.embedding_service.embed(documents)
        
        if not embeddings:
            return 0
        
        # Add to vector store
        self.vector_store.add(documents, embeddings, metadata)
        
        # Save to disk
        self.vector_store.save()
        
        return len(documents)
    
    def clear_index(self) -> None:
        """Clear all documents from the index."""
        self.vector_store.clear()
        self.vector_store.save()
    
    def get_stats(self) -> Dict[str, Any]:
        """Get retriever statistics."""
        return {
            "vector_store": self.vector_store.get_stats(),
            "embedding_service": self.embedding_service.get_stats(),
            "config": {
                "top_k": self.top_k,
                "index_path": self.index_path,
                "min_score": self.min_score
            }
        }


# Singleton instance
_retriever: Optional[Retriever] = None


def get_retriever(config_path: str = "./configs/rag_config.json") -> Retriever:
    """Get or create the retriever singleton."""
    global _retriever
    if _retriever is None:
        _retriever = Retriever(config_path)
    return _retriever
