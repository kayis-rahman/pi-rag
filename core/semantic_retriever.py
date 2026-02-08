"""
Semantic Retriever - Enhanced retrieval for semantic memory.

Design Principles (NON-NEGOTIABLE):
- Retrieval is QUERY-DRIVEN (not always-on)
- Never overrides symbolic or episodic memory
- Supports citations and traceability
- Ranks by similarity, metadata relevance, and recency
- Filters by metadata (type, source, etc.)

Retrieval Triggers (CRITICAL):
✅ Retrieve ONLY when:
• Planner explicitly states: "I need external information"
• Symbolic memory cannot answer
• Episodic memory suggests retrieval

❌ Do NOT retrieve:
• By default on every request
• For user preferences or decisions (→ Symbolic Memory)
• For agent lessons (→ Episodic Memory)

Memory Type Separation:
- Symbolic Memory: Facts, preferences (authoritative)
- Episodic Memory: Agent lessons (advisory)
- Semantic Memory: Documents, code (non-authoritative)

Semantic memory answers:
"What information might be relevant?"

It does NOT answer:
"What is true?"
"""

import json
import os
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta

from .semantic_store import SemanticStore, get_semantic_store
from .embedding import EmbeddingService, get_embedding_service
from .query_expander import get_query_expander


class SemanticRetriever:
    """
    Enhanced semantic retrieval with ranking, filtering, and citations.

    Features:
    - Query-driven (never auto-retrieves)
    - Ranks by similarity + metadata relevance + recency
    - Supports citations with source tracking
    - Never overrides symbolic or episodic memory

    Example:
        >>> retriever = SemanticRetriever()
        >>> results = retriever.retrieve(
        ...     query="How does authentication work?",
        ...     trigger="external_info_needed",
        ...     top_k=3
        ... )
    """

    # Valid retrieval triggers
    VALID_TRIGGERS = {
        "external_info_needed",
        "symbolic_memory_insufficient",
        "episodic_suggests_retrieval",
        "explicit_retrieval_request"
    }

    # Recency weights
    RECENCY_DECAY_DAYS = 30  # Full recency weight for recent documents

    def __init__(
        self,
        semantic_store: Optional[SemanticStore] = None,
        embedding_service: Optional[EmbeddingService] = None,
        query_expansion_enabled: bool = True,
        num_expansions: int = 3
    ):
        """
        Initialize semantic retriever.

        Args:
            semantic_store: Semantic store instance
            embedding_service: Embedding service instance
            query_expansion_enabled: Enable query expansion (default: True)
            num_expansions: Number of query expansions (default: 3)
        """
        self.semantic_store = semantic_store or get_semantic_store()
        self.embedding_service = embedding_service or get_embedding_service()
        self.query_expansion_enabled = query_expansion_enabled
        self.num_expansions = num_expansions

    def retrieve(
        self,
        query: str,
        trigger: str = "external_info_needed",
        top_k: int = 3,
        metadata_filters: Optional[Dict[str, Any]] = None,
        min_score: float = 0.0,
        include_recency: bool = True,
        max_results: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Retrieve relevant documents based on query (query-driven).

        Args:
            query: Search query text
            trigger: Retrieval trigger (must be valid)
            top_k: Number of top results to return
            metadata_filters: Optional metadata filters
            min_score: Minimum similarity score
            include_recency: Whether to boost recent documents
            max_results: Maximum number of results to return

        Returns:
            List of retrieved documents with scores, metadata, and citations

        Raises:
            ValueError: If trigger is invalid
        """
        # Validate trigger (prevent auto-retrieval)
        if trigger not in self.VALID_TRIGGERS:
            raise ValueError(
                f"Invalid retrieval trigger: {trigger}. "
                f"Valid triggers are: {', '.join(self.VALID_TRIGGERS)}. "
                "Retrieval must be explicitly triggered, not automatic."
            )

        # Generate query embedding
        query_embedding = self.embedding_service.embed_single(query)

        if not query_embedding:
            return []

        # Search semantic store
        raw_results = self.semantic_store.search(
            query_embedding=query_embedding,
            top_k=max_results,
            metadata_filters=metadata_filters,
            min_score=min_score
        )

        # Rank results (similarity + metadata relevance + recency)
        ranked_results = self._rank_results(raw_results, query, include_recency)

        # Return top-k results
        return ranked_results[:top_k]

    def retrieve_with_expansion(
        self,
        query: str,
        trigger: str = "external_info_needed",
        top_k: int = 3,
        metadata_filters: Optional[Dict[str, Any]] = None,
        min_score: float = 0.0,
        include_recency: bool = True,
        num_expansions: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Retrieve with query expansion for better recall.

        Uses multi-query expansion to improve retrieval quality.

        Args:
            query: Search query text
            trigger: Retrieval trigger (must be valid)
            top_k: Number of top results to return
            metadata_filters: Optional metadata filters
            min_score: Minimum similarity score
            include_recency: Whether to boost recent documents
            num_expansions: Number of expansions (default: from config)

        Returns:
            List of retrieved documents with scores, metadata, and citations

        Raises:
            ValueError: If trigger is invalid
        """
        if not self.query_expansion_enabled:
            # Fall back to normal retrieval
            return self.retrieve(query, trigger, top_k, metadata_filters, min_score, include_recency)

        expansions = num_expansions or self.num_expansions
        expander = get_query_expander(num_expansions=expansions)

        # Expand query
        expanded_queries = expander.expand_query(query)

        # Search with each query
        all_results = []
        for expanded_query in expanded_queries:
            results = self._search_without_trigger(
                expanded_query,
                top_k=top_k * 2,  # Get more results per query
                metadata_filters=metadata_filters,
                min_score=min_score
            )
            all_results.append(results)

        # Merge and deduplicate results
        merged_results = self._merge_retrieval_results(all_results)

        # Rank merged results
        ranked_results = self._rank_results(merged_results, query, include_recency)

        # Return top-k results
        return ranked_results[:top_k]

    def _search_without_trigger(
        self,
        query: str,
        top_k: int = 3,
        metadata_filters: Optional[Dict[str, Any]] = None,
        min_score: float = 0.0
    ) -> List[Dict[str, Any]]:
        """
        Search without trigger validation (internal use).

        Used by retrieve_with_expansion to avoid trigger validation on expanded queries.

        Args:
            query: Search query text
            top_k: Number of top results to return
            metadata_filters: Optional metadata filters
            min_score: Minimum similarity score

        Returns:
            List of retrieved documents with scores, metadata, and citations
        """
        # Generate query embedding
        query_embedding = self.embedding_service.embed_single(query)

        if not query_embedding:
            return []

        # Search semantic store
        raw_results = self.semantic_store.search(
            query_embedding=query_embedding,
            top_k=top_k,
            metadata_filters=metadata_filters,
            min_score=min_score
        )

        return raw_results

    def _merge_retrieval_results(
        self,
        all_results: List[List[Dict[str, Any]]]
    ) -> List[Dict[str, Any]]:
        """
        Merge results from multiple query searches.

        Deduplicates and keeps best score.

        Args:
            all_results: List of result lists from each query

        Returns:
            Merged and deduplicated results
        """
        if not all_results:
            return []

        # Track results by content for deduplication
        content_map: Dict[str, Dict[str, Any]] = {}

        for query_results in all_results:
            for result in query_results:
                content = result.get("content", "")
                score = result.get("score", 0.0)
                metadata = result.get("metadata", {})
                created_at = result.get("created_at", "")

                if content in content_map:
                    # Keep the highest score
                    existing = content_map[content]
                    if score > existing.get("score", 0.0):
                        content_map[content] = result
                else:
                    content_map[content] = result

        return list(content_map.values())

    def _rank_results(
        self,
        results: List[Dict[str, Any]],
        query: str,
        include_recency: bool
    ) -> List[Dict[str, Any]]:
        """
        Rank results by combined score (similarity + metadata + recency).

        Args:
            results: Raw search results
            query: Original query string
            include_recency: Whether to include recency in ranking

        Returns:
            Ranked list of results
        """
        ranked = []

        for result in results:
            base_score = result["score"]
            metadata = result["metadata"]

            # Calculate metadata relevance boost
            metadata_boost = self._calculate_metadata_boost(query, metadata)

            # Calculate recency boost
            recency_boost = 0.0
            if include_recency:
                recency_boost = self._calculate_recency_boost(result.get("created_at", ""))

            # Combined score (base + boosts)
            # Weighting: 70% similarity, 20% metadata, 10% recency
            combined_score = (
                base_score * 0.7 +
                metadata_boost * 0.2 +
                recency_boost * 0.1
            )

            result["combined_score"] = combined_score
            result["metadata_boost"] = metadata_boost
            result["recency_boost"] = recency_boost
            result["ranking_factors"] = {
                "similarity": base_score,
                "metadata": metadata_boost,
                "recency": recency_boost
            }

            ranked.append(result)

        # Sort by combined score
        ranked.sort(key=lambda x: x["combined_score"], reverse=True)

        return ranked

    def _calculate_metadata_boost(
        self,
        query: str,
        metadata: Dict[str, Any]
    ) -> float:
        """
        Calculate metadata relevance boost based on query and document metadata.

        Args:
            query: Query string
            metadata: Document metadata

        Returns:
            Metadata boost score (0.0-1.0)
        """
        boost = 0.0

        # Type relevance (boost code for code queries, etc.)
        doc_type = metadata.get("type", "doc")

        # Keywords suggesting code search
        code_keywords = ["function", "class", "api", "method", "implement", "code"]
        query_lower = query.lower()
        filename_lower = metadata.get("filename", "").lower()

        if any(kw in query_lower for kw in code_keywords):
            if doc_type == "code":
                boost += 0.3
            elif "code" in filename_lower:
                boost += 0.2

        # Source path relevance (prefer sources in query)
        source = metadata.get("source", "")
        if source and source.lower() in query.lower():
            boost += 0.2

        # Clamp boost to 0.0-1.0
        return min(boost, 1.0)

    def _calculate_recency_boost(self, created_at: str) -> float:
        """
        Calculate recency boost for recent documents.

        Args:
            created_at: Creation timestamp

        Returns:
            Recency boost score (0.0-1.0)
        """
        if not created_at:
            return 0.0

        try:
            # Parse timestamp
            created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            now = datetime.now()

            # Calculate days difference
            delta = now - created
            days_ago = delta.total_seconds() / 86400  # Convert to days

            # Decay factor: 1.0 for recent, 0.0 for old
            if days_ago >= self.RECENCY_DECAY_DAYS:
                return 0.0

            # Linear decay
            decay = 1.0 - (days_ago / self.RECENCY_DECAY_DAYS)

            return max(decay, 0.0)

        except (ValueError, AttributeError):
            return 0.0

    def search_by_type(
        self,
        query: str,
        doc_type: str,
        top_k: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Search documents of specific type.

        Args:
            query: Search query
            doc_type: Document type (doc, code, note, article, reference)
            top_k: Number of results

        Returns:
            List of retrieved documents
        """
        return self.retrieve(
            query=query,
            trigger="external_info_needed",
            top_k=top_k,
            metadata_filters={"type": doc_type}
        )

    def search_by_source(
        self,
        query: str,
        source_pattern: str,
        top_k: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Search documents from specific source.

        Args:
            query: Search query
            source_pattern: Source path pattern
            top_k: Number of results

        Returns:
            List of retrieved documents
        """
        return self.retrieve(
            query=query,
            trigger="external_info_needed",
            top_k=top_k,
            metadata_filters={"source": source_pattern}
        )

    def get_retrieval_stats(self) -> Dict[str, Any]:
        """
        Get retrieval statistics.

        Returns:
            Dictionary with statistics
        """
        store_stats = self.semantic_store.get_stats()

        return {
            "semantic_store": store_stats,
            "valid_triggers": list(self.VALID_TRIGGERS),
            "recency_decay_days": self.RECENCY_DECAY_DAYS
        }

    def explain_ranking(
        self,
        results: List[Dict[str, Any]]
    ) -> List[str]:
        """
        Explain ranking factors for retrieved results.

        Args:
            results: Ranked results

        Returns:
            List of explanation strings
        """
        explanations = []

        for i, result in enumerate(results):
            ranking = result.get("ranking_factors", {})
            sim_score = ranking.get("similarity", 0.0)
            meta_boost = ranking.get("metadata", 0.0)
            rec_boost = ranking.get("recency", 0.0)

            parts = []
            parts.append(f"Similarity: {sim_score:.3f}")

            if meta_boost > 0:
                parts.append(f"Metadata: +{meta_boost:.3f}")

            if rec_boost > 0:
                parts.append(f"Recency: +{rec_boost:.3f}")

            explanation = f"{i+1}. {result.get('content', '')[:50]}... [{', '.join(parts)}]"
            explanations.append(explanation)

        return explanations


# Singleton instance
_semantic_retriever: Optional[SemanticRetriever] = None


def get_semantic_retriever(
    semantic_store: Optional[SemanticStore] = None,
    embedding_service: Optional[EmbeddingService] = None
) -> SemanticRetriever:
    """
    Get or create the semantic retriever singleton.

    Args:
        semantic_store: Semantic store instance
        embedding_service: Embedding service instance

    Returns:
        SemanticRetriever instance
    """
    global _semantic_retriever
    if _semantic_retriever is None:
        _semantic_retriever = SemanticRetriever(semantic_store, embedding_service)
    return _semantic_retriever
