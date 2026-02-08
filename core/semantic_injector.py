"""
Semantic Injector - Non-authoritative prompt injection for semantic memory.

Design Principles (NON-NEGOTIABLE):
- Retrieved content is injected as CONTEXT, not FACT
- Clearly labeled as non-authoritative
- Includes citations and source tracking
- Neutralized within retrieved content (no system instruction injection)
- Never overrides symbolic or episodic memory

Memory Type Separation:
- Symbolic Memory: Facts, preferences (authoritative)
- Episodic Memory: Agent lessons (advisory)
- Semantic Memory: Documents, code (non-authoritative)

Semantic memory answers:
"What information might be relevant?"

It does NOT answer:
"What is true?"
"""

from typing import List, Dict, Any, Optional


class SemanticInjector:
    """
    Non-authoritative prompt injector for retrieved semantic content.

    Features:
    - Clearly marks retrieved content as ADVISORY
    - Includes citations with source tracking
    - Neutralizes retrieved content (prevents instruction injection)
    - Separates semantic from other memory types

    Example:
        >>> injector = SemanticInjector()
        >>> results = [
        ...     {"content": "API endpoints are defined in...", "citation": "docs/api.md:0"}
        ... ]
        >>> injected = injector.inject_context(
        ...     query="How are API endpoints defined?",
        ...     results=results
        ... )
        >>> print(injected)
        "RETRIEVED CONTEXT (NON-AUTHORITATIVE):\nSource: docs/api.md:0\nExcerpt: API endpoints are defined in...\n\nNote: This is retrieved information for context, not verified facts."
    """

    # Section header for non-authoritative marking
    NON_AUTHITATIVE_HEADER = "RETRIEVED CONTEXT (NON-AUTHORITATIVE)"

    # Citation format
    CITATION_FORMAT = "[{source}:{chunk_id}]"

    # Disclaimer (always included)
    NON_AUTHITATIVE_DISCLAIMER = "Note: This is retrieved information for context, not verified facts."

    def __init__(self):
        """Initialize semantic injector."""
        pass

    def inject_context(
        self,
        query: str,
        results: List[Dict[str, Any]],
        include_citations: bool = True,
        include_scores: bool = False
    ) -> str:
        """
        Inject retrieved semantic content into prompt as non-authoritative context.

        Args:
            query: Original query string
            results: Retrieved semantic results
            include_citations: Whether to include citation markers
            include_scores: Whether to include similarity scores

        Returns:
            Formatted context string for prompt injection
        """
        if not results:
            return ""

        # Build context sections
        sections = []

        # 1. Header (non-authoritative marker)
        sections.append(self.NON_AUTHITATIVE_HEADER)

        # 2. Include query (for context)
        sections.append(f"Query: {query}")

        # 3. Build retrieved content with citations
        content_sections = []
        for i, result in enumerate(results, 1):
            content_section = self._format_result(result, i, include_citations, include_scores)
            content_sections.append(content_section)

        sections.extend(content_sections)

        # 4. Add disclaimer
        sections.append("")
        sections.append(self.NON_AUTHITATIVE_DISCLAIMER)

        return "\n".join(sections)

    def _format_result(
        self,
        result: Dict[str, Any],
        index: int,
        include_citations: bool,
        include_scores: bool
    ) -> str:
        """
        Format a single retrieval result.

        Args:
            result: Result dictionary from semantic retrieval
            index: Result index (for display)
            include_citations: Whether to include citation markers
            include_scores: Whether to include similarity scores

        Returns:
            Formatted result string
        """
        parts = [f"{index}. "]

        # Content
        content = result.get("content", "")
        parts.append(content[:200])  # Limit excerpt for brevity
        if len(content) > 200:
            parts.append("...")

        # Citations
        if include_citations:
            citation = result.get("citation", "")
            parts.append(f" {citation}")

        # Scores
        if include_scores:
            score = result.get("score", 0.0)
            combined_score = result.get("combined_score", 0.0)
            parts.append(f" (relevance: {combined_score:.3f})")

        return " ".join(parts)

    def inject_with_memory_context(
        self,
        query: str,
        semantic_results: List[Dict[str, Any]],
        symbolic_context: str,
        episodic_context: str
    ) -> str:
        """
        Inject semantic context alongside symbolic and episodic memory.

        Args:
            query: Original query string
            semantic_results: Retrieved semantic results
            symbolic_context: Formatted symbolic memory context
            episodic_context: Formatted episodic memory context

        Returns:
            Combined context string for prompt injection

        Example:
            The sections are ordered:
            1. PERSISTENT MEMORY (READ-ONLY) - from Phase 1
            2. PAST AGENT LESSONS (ADVISORY, NON-AUTHORITATIVE) - from Phase 3
            3. RETRIEVED CONTEXT (NON-AUTHORITATIVE) - from Phase 4
        """
        sections = []

        # 1. Symbolic memory (authoritative, first)
        if symbolic_context:
            sections.append(symbolic_context)

        # 2. Episodic memory (advisory, second)
        if episodic_context:
            sections.append(episodic_context)

        # 3. Semantic memory (non-authoritative, last)
        if semantic_results:
            semantic_context = self.inject_context(
                query=query,
                results=semantic_results
            )
            sections.append(semantic_context)

        return "\n\n".join(sections)

    def explain_retrieval(
        self,
        query: str,
        results: List[Dict[str, Any]]
    ) -> List[str]:
        """
        Explain retrieval ranking for transparency.

        Args:
            query: Query string
            results: Retrieved and ranked results

        Returns:
            List of explanation strings
        """
        explanations = []

        for i, result in enumerate(results, 1):
            explanation = f"{i}. {result.get('content', '')[:50]}..."

            # Add ranking factors
            factors = result.get("ranking_factors", {})
            if factors:
                parts = []
                sim = factors.get("similarity", 0.0)
                meta = factors.get("metadata", 0.0)
                rec = factors.get("recency", 0.0)

                parts.append(f"similarity: {sim:.3f}")

                if meta > 0:
                    parts.append(f"metadata: +{meta:.3f}")

                if rec > 0:
                    parts.append(f"recency: +{rec:.3f}")

                explanation += f" [{', '.join(parts)}]"

            # Add citation
            citation = result.get("citation", "")
            if citation:
                explanation += f" [{citation}]"

            explanations.append(explanation)

        return explanations

    def build_prompt(
        self,
        user_query: str,
        semantic_results: Optional[List[Dict[str, Any]]] = None,
        symbolic_context: Optional[str] = None,
        episodic_context: Optional[str] = None,
        system_instruction: Optional[str] = None
    ) -> str:
        """
        Build complete prompt with all memory types.

        Args:
            user_query: The user's query
            semantic_results: Optional retrieved semantic results
            symbolic_context: Optional symbolic memory context
            episodic_context: Optional episodic memory context
            system_instruction: Optional system instruction

        Returns:
            Complete prompt for LLM

        Example Structure:
            SYSTEM: You are a helpful assistant.

            PERSISTENT MEMORY (READ-ONLY):
            • Project language: Go (confidence 0.92)
            • User prefers JSON output (confidence 0.85)

            PAST AGENT LESSONS (ADVISORY, NON-AUTHORITATIVE):
            • For large repos, search filenames first (confidence 0.85)

            RETRIEVED CONTEXT (NON-AUTHORITATIVE):
            Source: docs/api.md
            Excerpt: API endpoints are defined in...

            USER REQUEST:
            How are API endpoints defined?
        """
        sections = []

        # 1. System instruction
        if system_instruction:
            sections.append(system_instruction)

        # 2. Symbolic memory (authoritative)
        if symbolic_context:
            sections.append(symbolic_context)

        # 3. Episodic memory (advisory)
        if episodic_context:
            sections.append(episodic_context)

        # 4. Semantic memory (non-authoritative)
        if semantic_results:
            semantic_section = self.inject_context(
                query=user_query,
                results=semantic_results
            )
            sections.append(semantic_section)

        # 5. User request (always last)
        sections.append(f"USER REQUEST:\n{user_query}")

        return "\n\n".join(sections)

    def safety_check(
        self,
        content: str,
        max_length: int = 10000
    ) -> Dict[str, Any]:
        """
        Safety check for injected content.

        Args:
            content: Content to check
            max_length: Maximum allowed length

        Returns:
            Dictionary with safety check results
        """
        checks = {
            "length_ok": len(content) <= max_length,
            "has_system_override": self._check_system_override(content),
            "has_disallowed_instructions": self._check_disallowed_instructions(content),
            "is_safe": True
        }

        # Mark as unsafe if any check fails
        if not checks["length_ok"]:
            checks["is_safe"] = False

        if checks["has_system_override"]:
            checks["is_safe"] = False

        if checks["has_disallowed_instructions"]:
            checks["is_safe"] = False

        return checks

    def _check_system_override(self, content: str) -> bool:
        """
        Check if content attempts to override system instructions.

        Args:
            content: Content to check

        Returns:
            True if system override detected
        """
        content_lower = content.lower()

        # Override patterns
        override_patterns = [
            "ignore previous instructions",
            "disregard system messages",
            "override system settings",
            "you are now a different system",
            "forget all previous context"
        ]

        for pattern in override_patterns:
            if pattern in content_lower:
                return True

        return False

    def _check_disallowed_instructions(self, content: str) -> bool:
        """
        Check if content contains disallowed instruction patterns.

        Args:
            content: Content to check

        Returns:
            True if disallowed instructions detected
        """
        content_lower = content.lower()

        # Disallowed patterns (commands within retrieved content)
        disallowed_patterns = [
            "you must",
            "you have to",
            "always do",
            "never do",
            "required to",
            "you are required"
        ]

        for pattern in disallowed_patterns:
            if f" {pattern} " in content_lower:
                return True

        return False


# Singleton instance
_semantic_injector: Optional[SemanticInjector] = None


def get_semantic_injector() -> SemanticInjector:
    """
    Get or create the semantic injector singleton.

    Returns:
        SemanticInjector instance
    """
    global _semantic_injector
    if _semantic_injector is None:
        _semantic_injector = SemanticInjector()
    return _semantic_injector
