"""
Query Expansion - Improves retrieval recall by expanding queries with related terms.

Strategy: Multi-Query Expansion with Synonym Augmentation

Approach:
1. Generate 2-3 related queries from original query
2. Search with original + expanded queries
3. Merge and deduplicate results
4. Return top-K results

Expected Benefit: 15-25% better recall for complex queries
Risk: Low
Implementation Time: 2-3 hours

Example:
    Original: "How do I handle authentication errors?"
    Expanded:
      - "authentication error handling"
      - "how to handle auth errors"
      - "error handling in authentication"

    Results: Broader coverage, more relevant documents found
"""

from typing import List, Dict, Any, Optional, Callable
import re
from collections import Counter


class QueryExpander:
    """
    Expands queries to improve retrieval recall.

    Uses multi-query expansion with synonym augmentation.
    """

    # Common synonyms and related terms
    SYNONYMS = {
        "auth": ["authentication", "authorization", "login", "verify", "validate"],
        "error": ["exception", "failure", "issue", "problem", "bug"],
        "handle": ["process", "manage", "deal with", "respond to", "resolve"],
        "create": ["make", "build", "generate", "construct", "initialize"],
        "delete": ["remove", "erase", "destroy", "clear", "eliminate"],
        "update": ["modify", "change", "edit", "alter", "revise"],
        "get": ["retrieve", "fetch", "obtain", "load", "read"],
        "list": ["show", "display", "enumerate", "index", "catalog"],
        "config": ["configuration", "settings", "setup", "options", "preferences"],
        "api": ["endpoint", "interface", "service", "rest", "http"],
        "db": ["database", "storage", "data store", "repository"],
        "test": ["verify", "validate", "check", "assert", "spec"],
        "deploy": ["ship", "release", "publish", "distribute"],
        "debug": ["fix", "troubleshoot", "investigate", "diagnose"]
    }

    def __init__(self, num_expansions: int = 3):
        """
        Initialize query expander.

        Args:
            num_expansions: Number of expanded queries to generate (default: 3)
        """
        self.num_expansions = num_expansions

    def expand_query(self, query: str) -> List[str]:
        """
        Generate expanded query variations.

        Args:
            query: Original query string

        Returns:
            List of expanded queries (including original)
        """
        queries = [query]

        # Generate expansions
        expansions = []

        # Strategy 1: Synonym expansion
        synonym_query = self._expand_with_synonyms(query)
        if synonym_query and synonym_query != query:
            expansions.append(synonym_query)

        # Strategy 2: Query rewriting (remove stopwords, rephrase)
        rewritten_query = self._rewrite_query(query)
        if rewritten_query and rewritten_query != query:
            expansions.append(rewritten_query)

        # Strategy 3: Extract key terms and form variations
        key_terms_query = self._expand_with_key_terms(query)
        if key_terms_query and key_terms_query != query:
            expansions.append(key_terms_query)

        # Add unique expansions up to limit
        for exp in expansions:
            if exp not in queries and len(queries) < 1 + self.num_expansions:
                queries.append(exp)

        return queries[:1 + self.num_expansions]

    def _expand_with_synonyms(self, query: str) -> Optional[str]:
        """Expand query by replacing terms with synonyms."""
        words = query.lower().split()
        expanded_words = []

        for word in words:
            # Find matching synonym (partial match)
            matched = False
            for key, synonyms in self.SYNONYMS.items():
                if key in word or word in key:
                    # Replace with first synonym
                    expanded_words.append(synonyms[0])
                    matched = True
                    break

            if not matched:
                expanded_words.append(word)

        expanded = " ".join(expanded_words)
        return expanded if expanded != query.lower() else None

    def _rewrite_query(self, query: str) -> Optional[str]:
        """Rewrite query by changing structure."""
        # Convert "how do I" to "how to"
        if re.match(r"how\s+do\s+i\s+", query.lower()):
            rewritten = re.sub(r"how\s+do\s+i\s+", "how to ", query, flags=re.IGNORECASE)
            return rewritten

        # Convert "what is the" to "what"
        if re.match(r"what\s+is\s+the\s+", query.lower()):
            rewritten = re.sub(r"what\s+is\s+the\s+", "what ", query, flags=re.IGNORECASE)
            return rewritten

        # Remove common stopwords
        stopwords = {"the", "a", "an", "is", "are", "was", "were", "do", "does", "did"}
        words = query.split()
        filtered = [w for w in words if w.lower() not in stopwords]

        if filtered and len(filtered) < len(words):
            return " ".join(filtered)

        return None

    def _expand_with_key_terms(self, query: str) -> Optional[str]:
        """Extract key terms and create concise query."""
        # Remove question words
        question_words = {"how", "what", "where", "when", "why", "which", "who"}
        words = query.split()
        filtered = [w for w in words if w.lower() not in question_words]

        # Remove common stopwords
        stopwords = {"is", "are", "the", "a", "an", "to", "for", "in", "on", "at"}
        filtered = [w for w in filtered if w.lower() not in stopwords]

        if filtered and len(filtered) < len(words):
            return " ".join(filtered)

        return None

    def merge_results(
        self,
        all_results: List[List[Dict[str, Any]]],
        top_k: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Merge results from multiple query searches.

        Deduplicates and re-ranks by:
        1. Content similarity (dedup)
        2. Average score (across multiple queries)
        3. Frequency (how many queries found this result)

        Args:
            all_results: List of result lists from each query
            top_k: Number of top results to return

        Returns:
            Merged and re-ranked results
        """
        if not all_results:
            return []

        # Track results by content (for deduplication)
        content_map: Dict[str, Dict[str, Any]] = {}

        for query_results in all_results:
            for result in query_results:
                content = result.get("content", "")
                score = result.get("score", 0.0)
                metadata = result.get("metadata", {})

                # Normalize content for comparison
                normalized_content = self._normalize_content(content)

                if normalized_content in content_map:
                    # Merge scores (take max)
                    existing = content_map[normalized_content]
                    existing_score = existing.get("score", 0.0)
                    existing["score"] = max(existing_score, score)
                    existing["query_count"] += 1
                else:
                    content_map[normalized_content] = {
                        "content": content,
                        "score": score,
                        "metadata": metadata,
                        "query_count": 1
                    }

        # Re-rank: prioritize results found by multiple queries
        sorted_results = sorted(
            content_map.values(),
            key=lambda r: (r.get("query_count", 0), r.get("score", 0.0)),
            reverse=True
        )

        return sorted_results[:top_k]

    def _normalize_content(self, content: str) -> str:
        """Normalize content for deduplication comparison."""
        # Lowercase, remove extra whitespace
        normalized = re.sub(r"\s+", " ", content.lower().strip())
        return normalized

    def expand_and_search(
        self,
        query: str,
        search_func: Any,
        top_k: int = 3,
        **search_kwargs: Any
    ) -> List[Dict[str, Any]]:
        """
        Expand query and perform search.

        Convenience method that combines expansion and searching.

        Args:
            query: Original query
            search_func: Function to call for search (e.g., retriever.search)
            top_k: Number of results to return
            **search_kwargs: Additional arguments to pass to search_func

        Returns:
            Merged and re-ranked results
        """
        # Expand query
        expanded_queries = self.expand_query(query)

        # Search with each query
        all_results = []
        for expanded_query in expanded_queries:
            results = search_func(expanded_query, top_k=top_k, **search_kwargs)
            all_results.append(results)

        # Merge results
        merged = self.merge_results(all_results, top_k=top_k)

        return merged


# Singleton instance
_expander: Optional[QueryExpander] = None


def get_query_expander(num_expansions: int = 3) -> QueryExpander:
    """Get or create the query expander singleton."""
    global _expander
    if _expander is None:
        _expander = QueryExpander(num_expansions=num_expansions)
    return _expander
