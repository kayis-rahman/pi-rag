"""
Memory Formatter - Format memory facts as read-only context for safe injection.

Design Principles (READ-ONLY):
- Memory injection is deterministic
- LLM cannot mutate memory during injection
- Clear separation between memory and chat history
- Safe to inject into prompts
"""

from typing import List, Dict, Any, Optional
from .memory_store import MemoryFact


class MemoryFormatter:
    """
    Formats memory facts for prompt injection.

    Features:
    - Read-only context formatting
    - Conflict annotation
    - Confidence-based ordering
    - Human-readable formatting
    - Context size estimation

    Example:
        >>> formatter = MemoryFormatter()
        >>> prompt = formatter.format_as_read_only_context(facts, "Help me")
        >>> # In production, use: logger.info(prompt)
        >>> # Here we show raw output for clarity
        >>> print(prompt)
    """

    # Maximum context characters to prevent prompt bloat
    MAX_CONTEXT_CHARS = 5000

    # Read-only header
    READ_ONLY_HEADER = "PERSISTENT MEMORY (READ-ONLY)\n" + "=" * 60 + "\n"

    def format_as_read_only_context(
        self,
        facts: List[MemoryFact],
        instruction: Optional[str] = None,
        user_query: Optional[str] = None,
        include_conflicts: Optional[bool] = None
    ) -> str:
        """
        Format memory facts as read-only context section.

        Args:
            facts: Memory facts to format
            instruction: Custom instruction (optional)
            user_query: User query (optional)
            include_conflicts: Whether to include conflict markers

        Returns:
            Formatted string ready for prompt injection
        """
        if not facts:
            return ""

        # Start with read-only header
        context_parts = [self.READ_ONLY_HEADER]

        # Add custom instruction if provided
        if instruction:
            context_parts.append(f"{instruction}\n")

        # Group facts by category for better readability
        facts_by_category = self._group_by_category(facts)

        # Format each category
        for category, category_facts in facts_by_category.items():
            if not category_facts:
                continue

            context_parts.append(f"\n{category.capitalize()}s:\n")
            for fact in category_facts:
                context_parts.append(self._format_fact(fact))

        # Add usage rules
        context_parts.append("\n" + "-" * 60)
        context_parts.append(
            "Rules for using this memory:\n"
            "1. These are explicit facts stored by the user or system.\n"
            "2. Do not contradict these facts unless user explicitly says so.\n"
            "3. These are read-only and cannot be modified.\n"
            "4. Use these to provide context, not to override.\n"
        )

        # Add conflict warnings if enabled
        if include_conflicts:
            conflicts = self._detect_conflicts(facts)
            if conflicts:
                context_parts.append("\n" + "!" * 60)
                context_parts.append(
                    "NOTICE: Some facts have conflicts:\n"
                )
                for conflict in conflicts:
                    context_parts.append(f"  - {conflict}\n")

        # Combine context
        context = "\n".join(context_parts)

        # Estimate size
        size_estimate = len(context)
        if size_estimate > self.MAX_CONTEXT_CHARS:
            context_parts.append(
                "\n" + "!" * 60 + "\n"
                f"WARNING: Context size ({size_estimate} chars) exceeds limit ({self.MAX_CONTEXT_CHARS}). "
                "This may degrade performance."
            )

        # Add user query if provided
        if user_query:
            context += f"\n\n---\nUSER REQUEST:\n{user_query}\n---\n"

        return context

    def _group_by_category(self, facts: List[MemoryFact]) -> Dict[str, List[MemoryFact]]:
        """Group facts by category."""
        categories = {}
        for fact in facts:
            if fact.category not in categories:
                categories[fact.category] = []
            categories[fact.category].append(fact)
        return categories

    def _format_fact(self, fact: MemoryFact, show_conflicts: bool = False) -> str:
        """Format a single fact."""
        fact_dict = fact.to_dict()

        # Format based on value type
        if isinstance(fact_dict["value"], dict):
            # Format dict as key-value pairs
            items = [f"{k}: {v}" for k, v in fact_dict["value"].items()]
            value_str = ", ".join(items)
        else:
            value_str = str(fact_dict["value"])

        # Build line
        line = f"  - {fact.key}: {value_str}"

        # Add confidence
        if show_conflicts:
            line += f" (confidence: {fact.confidence:.2f})"

        return line

    def _detect_conflicts(self, facts: List[MemoryFact]) -> List[str]:
        """Detect conflicting facts."""
        # Group by (scope, key)
        by_key = {}
        for fact in facts:
            key = (fact.scope, fact.key)
            if key not in by_key:
                by_key[key] = []
            by_key[key].append(fact)

        # Find conflicts
        conflicts = []
        for key, fact_list in by_key.items():
            if len(fact_list) > 1:
                # Check for value differences
                values = [f.to_dict()["value"] for f in fact_list]

                # Normalize values for comparison
                normalized = []
                for v in values:
                    if isinstance(v, str):
                        normalized.append(v.lower())
                    elif isinstance(v, dict):
                        normalized.append(str(sorted(v.items())))
                    else:
                        normalized.append(str(v))

                # Check for differences
                unique_values = set(normalized)
                if len(unique_values) > 1:
                    values_str = " vs ".join(unique_values)
                    conflicts.append(f"{fact.scope}/{fact.key}: {values_str}")

        return conflicts

    def estimate_size(
        self,
        facts: List[MemoryFact],
        max_chars: int = MAX_CONTEXT_CHARS
    ) -> Dict[str, Any]:
        """
        Estimate context size with breakdown.

        Args:
            facts: Facts to include
            max_chars: Maximum allowed characters

        Returns:
            Dictionary with size breakdown
        """
        total_size = 0
        breakdown = {}

        # Header size
        total_size += len(self.READ_ONLY_HEADER)

        # Facts size
        for fact in facts:
            line_size = len(self._format_fact(fact)) + 1  # +1 for newline
            category = fact.category
            if category not in breakdown:
                breakdown[category] = 0
            breakdown[category] += line_size
            total_size += line_size

        # Separator size
        total_size += 1  # newline

        # Rules section size (approximate)
        rules_size = 200
        total_size += rules_size

        # Size metadata
        metadata = {
            "header_size": len(self.READ_ONLY_HEADER),
            "total_facts": len(facts),
            "fact_categories": breakdown,
            "rules_section_estimated": rules_size,
            "estimated_total": total_size
        }

        if total_size > max_chars:
            metadata["exceeds_limit"] = True
            metadata["excess_chars"] = total_size - max_chars
        else:
            metadata["exceeds_limit"] = False

        return metadata
