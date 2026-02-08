"""
Prompt Builder - Assemble final prompt with memory, RAG context, and user query.

Design Principles:
- Clear separation of sections
- Memory is read-only and authoritative
- RAG is advisory (retrieved documents)
- User query is primary
- No mixing of authoritative and advisory content

Section Structure:
1. System Instructions (if present)
2. PERSISTENT MEMORY (READ-ONLY) - from Phase 2
3. RELEVANT CONTEXT (RAG) - if enabled
4. USER REQUEST

Memory Injection Contract:
"Known persistent facts (read-only):
- [formatted facts]
- [formatted facts]
...
Use these unless explicitly contradicted."

This is immutable context - LLM must not modify, forget, or override.

Example:
```
SYSTEM:
You are a helpful coding assistant.

PERSISTENT MEMORY (READ-ONLY):
- Project language: Go (confidence 0.92)
- User prefers JSON output (confidence 0.85)

RELEVANT CONTEXT:
[Retrieved document about Go setup...]
---

USER REQUEST:
Help me set up a Go project structure.
```
"""

from typing import List, Dict, Any, Optional
import json

from .memory_selector import MemorySelector, RequestType


class PromptBuilder:
    """
    Assemble final prompt from components.

    Responsibilities:
    - Combine system instructions
    - Inject read-only symbolic memory
    - Add RAG context if enabled
    - Append user request
    - Ensure clear section separation
    - Maintain safe, deterministic assembly

    Example:
        >>> builder = PromptBuilder()
        >>> prompt = builder.build_prompt(
        ...     user_query="Help me build a REST API",
        ...     memory_context=get_memory_context("user")
        ... )
        >>> # In production, use: logger.info(prompt)
        >>> # Here we show raw output for clarity
        >>> print(prompt)
    """

    # Section headers
    SYSTEM_HEADER = "SYSTEM:"
    MEMORY_HEADER = "PERSISTENT MEMORY (READ-ONLY):"
    RAG_HEADER = "RELEVANT CONTEXT (RAG):"
    REQUEST_HEADER = "---\nUSER REQUEST:\n"

    # Memory read-only warning
    MEMORY_READ_ONLY = "(read-only, authoritative)"

    def __init__(self):
        """Initialize PromptBuilder."""
        pass

    def build_prompt(
        self,
        user_query: str,
        memory_facts: Optional[List[Dict[str, Any]]] = None,
        rag_context: Optional[str] = None,
        system_instruction: Optional[str] = None,
        scope: Optional[str] = None,
        min_confidence: float = 0.7,
        max_facts: int = 20,
        include_conflict_flags: bool = False,
        include_size_warning: bool = False
    ) -> str:
        """
        Assemble final prompt from components.

        Args:
            user_query: The user's actual query
            memory_facts: Pre-formatted memory facts list
            rag_context: Pre-formatted RAG context
            system_instruction: System instructions to prepend
            scope: Scope to filter memory (optional)
            min_confidence: Minimum confidence threshold
            max_facts: Maximum facts to include
            include_conflict_flags: Show conflict markers
            include_size_warning: Show size warnings

        Returns:
            Assembled prompt string ready for LLM
        """
        sections = []

        # 1. System instruction (if provided)
        if system_instruction:
            sections.append(system_instruction)

        # 2. Memory facts (if provided)
        if memory_facts:
            formatted_memory = self._format_memory_section(
                memory_facts,
                include_conflict_flags=include_conflict_flags,
                include_size_warning=include_size_warning
            )
            sections.append(formatted_memory)

        # 3. RAG context (if provided)
        if rag_context:
            sections.append(rag_context)

        # 4. User request (always provided)
        sections.append(f"{self.REQUEST_HEADER}{user_query}")

        # Combine sections
        return "\n\n".join(sections)

    def build_prompt_with_selector(
        self,
        user_query: str,
        selector: Optional[MemorySelector] = None,
        rag_context: Optional[str] = None,
        system_instruction: Optional[str] = None,
        scope: Optional[str] = None,
        min_confidence: float = 0.7,
        max_facts: int = 20
    ) -> str:
        """
        Build prompt using MemorySelector to select relevant memory.

        Args:
            user_query: User's query
            selector: MemorySelector instance
            rag_context: Optional RAG context
            system_instruction: Optional system instruction
            scope: Scope to filter memory
            min_confidence: Minimum confidence threshold
            max_facts: Maximum facts to include

        Returns:
            Final prompt with selected memory
        """
        if selector is None:
            # Fall back to basic build
            return self.build_prompt(
                user_query=user_query,
                rag_context=rag_context,
                system_instruction=system_instruction,
                scope=scope,
                min_confidence=min_confidence,
                max_facts=max_facts
            )

        # Select relevant memory
        request_type = self._infer_request_type(user_query)
        facts, metadata = selector.select_relevant_facts(
            user_query=user_query,
            request_type=request_type,
            min_confidence=min_confidence,
            max_facts=max_facts,
            scopes=[scope] if scope else None
        )

        # Convert MemoryFact objects to dicts for formatting
        facts_as_dicts = [
            {
                "key": fact.key,
                "value": json.loads(fact.value) if fact._is_json(fact.value) else fact.value,
                "confidence": fact.confidence,
                "category": fact.category,
                "scope": fact.scope
            }
            for fact in facts
        ]

        # Build memory section
        memory_section = self._format_memory_section(
            facts_as_dicts,  # type: ignore[arg-type]
            include_conflict_flags=True,
            include_size_warning=True
        )

        sections = []

        if system_instruction:
            sections.append(system_instruction)

        sections.append(memory_section)

        if rag_context:
            sections.append(rag_context)

        sections.append(f"{self.REQUEST_HEADER}{user_query}")

        return "\n\n".join(sections)

    def _infer_request_type(self, user_query: str) -> RequestType:
        """
        Infer type of user request based on content.

        Args:
            user_query: User's query

        Returns:
            RequestType enum value
        """
        # Simple keyword-based classification
        query_lower = user_query.lower()

        coding_keywords = [
            "code", "function", "api", "endpoint", "class", "method", "algorithm",
            "test", "build", "deploy", "bugfix", "feature", "refactor"
        ]
        output_keywords = [
            "format", "output", "response", "json", "xml", "yaml", "markdown",
            "structure", "design", "data", "file", "config"
        ]
        arch_keywords = [
            "architecture", "design", "pattern", "structure", "microservice",
            "service", "api", "endpoint", "component", "module"
        ]
        framework_keywords = [
            "framework", "spring", "django", "flask", "fastapi", "react",
            "angular", "vue", "express"
        ]

        if any(kw in query_lower for kw in coding_keywords):
            return RequestType.CODING
        if any(kw in query_lower for kw in output_keywords):
            return RequestType.OUTPUT_FORMAT
        if any(kw in query_lower for kw in arch_keywords):
            return RequestType.ARCHITECTURE
        if any(kw in query_lower for kw in framework_keywords):
            return RequestType.FRAMEWORK

        return RequestType.GENERAL

    def _format_memory_section(
        self,
        facts: List[Dict[str, Any]],
        include_conflict_flags: bool = False,
        include_size_warning: bool = False
    ) -> str:
        """
        Format memory facts as read-only context section.

        Args:
            facts: Memory facts to format
            include_conflict_flags: Whether to show conflict markers
            include_size_warning: Whether to show size warnings

        Returns:
            Formatted memory section string
        """
        if not facts:
            return ""

        # Header
        section = self.MEMORY_HEADER + "\n" + "No relevant memory facts found.\n"

        # Group by scope priority
        from .memory_store import MemoryStore
        scope_order = ["session", "project", "user", "org"]

        # Organize facts by scope
        by_scope = {"session": [], "project": [], "user": [], "org": []}
        for fact in facts:
            scope = fact.get("scope", "session")
            if scope in by_scope:
                by_scope[scope].append(fact)

        # Format facts by scope (in priority order)
        for scope in scope_order:
            if scope in by_scope and by_scope[scope]:
                scope_facts = by_scope[scope]

                # Sort by confidence within each scope
                scope_facts.sort(
                    key=lambda f: f.get("confidence", 0.9),
                    reverse=True
                )

                if scope_facts:
                    section += f"{scope.capitalize()} Scope:\n"
                    for fact in scope_facts:
                        fact_str = self._format_fact_line(fact)
                        section += fact_str

                    section += "\n"

        # Add read-only notice and size warning if requested
        if include_conflict_flags or include_size_warning:
            section += f"\n{self.MEMORY_READ_ONLY} These facts are {self.MEMORY_READ_ONLY} and authoritative.\n"

            if include_size_warning:
                total_chars = sum(
                    len(self._format_fact_line(fact))
                    for fact in facts
                )
                if total_chars > 2000:
                    section += f"! Context size: {total_chars} chars. May degrade performance.\n"

        return section

    def _format_fact_line(self, fact: Dict[str, Any]) -> str:
        """Format a single fact as a readable line."""
        confidence = fact.get("confidence", 0.0)
        value = fact.get("value", "")
        key = fact.get("key", "")

        # Format based on value type
        if isinstance(value, dict):
            # Format as key: value pairs
            items_str = ", ".join([f"{k}: {v}" for k, v in value.items()])
            value_display = f"{{{items_str}}}"
        else:
            value_display = value

        return f"  - {key}: {value_display} (confidence: {confidence:.2f})"


def build_prompt_from_components(
    user_query: str,
    memory_facts: Optional[List[Dict[str, Any]]] = None,
    rag_context: Optional[str] = None,
    system_instruction: Optional[str] = None
) -> str:
    """
    Convenience function to build prompt from components.

    Args:
        user_query: The user's query
        memory_facts: Pre-formatted memory facts (from selector)
        rag_context: Pre-formatted RAG context
        system_instruction: Optional system instruction

    Returns:
        Assembled prompt string
    """
    builder = PromptBuilder()
    return builder.build_prompt(
        user_query=user_query,
        memory_facts=memory_facts,
        rag_context=rag_context,
        system_instruction=system_instruction
    )
