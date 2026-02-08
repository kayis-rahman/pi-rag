"""
Memory Reader - Query and inject memory into prompts.

Design Principles (READ-ONLY):
- Memory injection is deterministic
- LLM cannot mutate memory during injection
- Clear separation between memory and chat history
- Safe to inject into prompts

Memory Injection Contract:
Known persistent facts (read-only):
- Project language: Go (confidence 0.9)
- User prefers structured JSON output (confidence 0.8)

Use these unless explicitly contradicted.
"""

from typing import List, Dict, Any, Optional
from .memory_store import MemoryFact, get_memory_store


class MemoryReader:
    """
    Reads memory facts and formats them for prompt injection.

    Features:
    - Flexible querying with filters
    - Deterministic fact ordering (by confidence, then recency)
    - Safe prompt injection (no mutation)
    - Conflict detection
    - Human-readable formatting

    Example:
        >>> reader = MemoryReader()
        >>> facts = reader.query_memory(scope="user", category="preference")
        >>> prompt = reader.inject_into_prompt(facts, "Help me build a web app")
        >>> # In production, use: logger.info(prompt)
        >>> # Here we show raw output for clarity
        >>> print(prompt)
    """

    def __init__(self, db_path: str = "./data/memory.db"):
        """
        Initialize MemoryReader.

        Args:
            db_path: Path to memory database
        """
        self.store = get_memory_store(db_path)

    def query_memory(
        self,
        scope: Optional[str] = None,
        category: Optional[str] = None,
        key: Optional[str] = None,
        min_confidence: float = 0.7,
        limit: Optional[int] = None
    ) -> List[MemoryFact]:
        """
        Query memory facts with filters.

        Args:
            scope: Filter by scope (user | project | org | session)
            category: Filter by category (preference | constraint | decision | fact)
            key: Filter by key (supports LIKE patterns)
            min_confidence: Minimum confidence threshold (default: 0.7)
            limit: Maximum number of facts to return

        Returns:
            List of matching MemoryFact objects, ordered by confidence DESC
        """
        facts = self.store.query_memory(
            scope=scope,
            category=category,
            key=key,
            min_confidence=min_confidence
        )

        # Apply limit
        if limit:
            facts = facts[:limit]

        return facts

    def get_all_for_scope(self, scope: str) -> List[MemoryFact]:
        """
        Get all memory facts for a scope.

        Args:
            scope: Scope to retrieve (user | project | org | session)

        Returns:
            All facts in the scope
        """
        return self.store.list_memory(scope)

    def get_preferences(self, scope: Optional[str] = None) -> List[MemoryFact]:
        """
        Get all preferences.

        Args:
            scope: Optional scope filter

        Returns:
            List of preference facts
        """
        return self.query_memory(scope=scope, category="preference")

    def get_constraints(self, scope: Optional[str] = None) -> List[MemoryFact]:
        """
        Get all constraints.

        Args:
            scope: Optional scope filter

        Returns:
            List of constraint facts
        """
        return self.query_memory(scope=scope, category="constraint")

    def get_decisions(self, scope: Optional[str] = None) -> List[MemoryFact]:
        """
        Get all decisions.

        Args:
            scope: Optional scope filter

        Returns:
            List of decision facts
        """
        return self.query_memory(scope=scope, category="decision")

    def format_facts_for_prompt(
        self,
        facts: List[MemoryFact],
        include_confidence: bool = True,
        group_by_category: bool = True
    ) -> str:
        """
        Format memory facts for prompt injection.

        Args:
            facts: List of facts to format
            include_confidence: Whether to include confidence scores
            group_by_category: Whether to group facts by category

        Returns:
            Formatted string ready for prompt injection
        """
        if not facts:
            return ""

        lines = []

        if group_by_category:
            # Group by category
            categories = {}
            for fact in facts:
                if fact.category not in categories:
                    categories[fact.category] = []
                categories[fact.category].append(fact)

            for category in ["preference", "constraint", "decision", "fact"]:
                if category in categories:
                    lines.append(f"\n{category.capitalize()}s:")
                    for fact in categories[category]:
                        line = self._format_single_fact(fact, include_confidence)
                        lines.append(f"  - {line}")
        else:
            # Simple list
            lines.append("\nKnown facts:")
            for fact in facts:
                line = self._format_single_fact(fact, include_confidence)
                lines.append(f"  - {line}")

        return "\n".join(lines)

    def _format_single_fact(
        self,
        fact: MemoryFact,
        include_confidence: bool
    ) -> str:
        """Format a single fact."""
        value = fact.to_dict()["value"]

        # Handle different value types
        if isinstance(value, dict):
            value_str = ", ".join(f"{k}: {v}" for k, v in value.items())
        else:
            value_str = str(value)

        base = f"{fact.key}: {value_str}"

        if include_confidence:
            base += f" (confidence: {fact.confidence:.2f})"

        return base

    def inject_into_prompt(
        self,
        facts: List[MemoryFact],
        user_query: str,
        instruction: Optional[str] = None
    ) -> str:
        """
        Inject memory facts into a prompt.

        Args:
            facts: List of facts to inject
            user_query: Original user query
            instruction: Optional custom instruction (uses default if None)

        Returns:
            Augmented prompt with memory facts

        Example:
            >>> prompt = reader.inject_into_prompt(facts, "Help me build an API")
            >>> # In production, use: logger.info(prompt)
            >>> # Here we show raw output for clarity
            >>> print(prompt)
        """
        if not facts:
            return user_query

        default_instruction = "Use the following persistent facts when responding. These are explicit preferences and decisions that should be respected unless the user explicitly contradicts them."

        facts_section = self.format_facts_for_prompt(facts)

        prompt = f"""{instruction or default_instruction}{facts_section}

User query:
{user_query}"""

        return prompt

    def build_memory_context(
        self,
        scopes: Optional[List[str]] = None,
        categories: Optional[List[str]] = None,
        min_confidence: float = 0.7,
        max_facts: int = 20
    ) -> str:
        """
        Build a comprehensive memory context string.

        Args:
            scopes: List of scopes to include (default: all)
            categories: List of categories to include (default: all)
            min_confidence: Minimum confidence threshold
            max_facts: Maximum facts to include

        Returns:
            Formatted memory context string
        """
        facts = []

        # Query facts with filters
        for scope in scopes or [None]:
            for category in categories or [None]:
                filtered = self.query_memory(
                    scope=scope,
                    category=category,
                    min_confidence=min_confidence
                )
                facts.extend(filtered)

        # Deduplicate and limit
        seen_keys = set()
        unique_facts = []
        for fact in facts:
            if fact.key not in seen_keys:
                seen_keys.add(fact.key)
                unique_facts.append(fact)
            if len(unique_facts) >= max_facts:
                break

        # Format facts
        facts_section = self.format_facts_for_prompt(unique_facts)

        if not facts_section:
            return ""

        return f"""Known persistent facts (read-only):
{facts_section}

Use these unless explicitly contradicted."""

    def detect_conflicts(self, facts: List[MemoryFact]) -> Dict[str, List[MemoryFact]]:
        """
        Detect conflicting facts (same key, different values).

        Args:
            facts: List of facts to check

        Returns:
            Dict mapping conflicting keys to list of conflicting facts
        """
        conflicts = {}

        # Group by key
        by_key = {}
        for fact in facts:
            if fact.key not in by_key:
                by_key[fact.key] = []
            by_key[fact.key].append(fact)

        # Find conflicts (same key, different values)
        for key, key_facts in by_key.items():
            if len(key_facts) > 1:
                # Check if values differ
                values = set()
                for fact in key_facts:
                    value_dict = fact.to_dict()["value"]
                    if isinstance(value_dict, dict):
                        # Convert dict to tuple for comparison
                        values.add(tuple(sorted(value_dict.items())))
                    else:
                        values.add(str(value_dict))

                if len(values) > 1:
                    conflicts[key] = key_facts

        return conflicts

    def resolve_conflicts(
        self,
        facts: List[MemoryFact],
        strategy: str = "highest_confidence"
    ) -> List[MemoryFact]:
        """
        Resolve conflicts among facts.

        Args:
            facts: List of facts with potential conflicts
            strategy: Resolution strategy (highest_confidence | most_recent)

        Returns:
            List of facts with conflicts resolved
        """
        conflicts = self.detect_conflicts(facts)

        if not conflicts:
            return facts

        # Create resolved list
        resolved = []
        resolved_keys = set()

        # First, add non-conflicting facts
        for fact in facts:
            if fact.key not in conflicts:
                resolved.append(fact)
                resolved_keys.add(fact.key)

        # Then, resolve conflicting keys
        for key, conflicting_facts in conflicts.items():
            if strategy == "highest_confidence":
                # Pick fact with highest confidence
                resolved_fact = max(conflicting_facts, key=lambda f: f.confidence)
            elif strategy == "most_recent":
                # Pick most recently updated fact
                resolved_fact = max(conflicting_facts, key=lambda f: f.updated_at)
            else:
                raise ValueError(f"Unknown conflict resolution strategy: {strategy}")

            resolved.append(resolved_fact)
            resolved_keys.add(key)

        return resolved

    def get_summary(self, scope: Optional[str] = None) -> Dict[str, Any]:
        """
        Get a summary of memory facts.

        Args:
            scope: Optional scope filter

        Returns:
            Dictionary with summary statistics
        """
        stats = self.store.get_stats()

        if scope:
            facts = self.query_memory(scope=scope)
            summary = {
                "scope": scope,
                "total_facts": len(facts),
                "by_category": {}
            }

            for fact in facts:
                cat = fact.category
                if cat not in summary["by_category"]:
                    summary["by_category"][cat] = 0
                summary["by_category"][cat] += 1

            return summary
        else:
            return stats


def get_memory_reader(db_path: str = "./data/memory.db") -> MemoryReader:
    """
    Get a MemoryReader instance.

    Args:
        db_path: Path to memory database

    Returns:
        MemoryReader instance
    """
    return MemoryReader(db_path)


def inject_memory_context(
    user_query: str,
    scope: Optional[str] = "session",
    min_confidence: float = 0.7,
    max_facts: int = 10
) -> str:
    """
    Convenience function: Inject memory context into query.

    Args:
        user_query: Original user query
        scope: Scope to retrieve memory from
        min_confidence: Minimum confidence threshold
        max_facts: Maximum facts to include

    Returns:
        Query augmented with memory context
    """
    reader = get_memory_reader()
    facts = reader.query_memory(scope=scope, min_confidence=min_confidence, limit=max_facts)

    if not facts:
        return user_query

    return reader.inject_into_prompt(facts, user_query)
