"""
Memory Selector - Intelligent memory fact selection for contextual memory injection.

Design Principles:
- Apply scope priority hierarchy (session → project → user → org)
- Filter by confidence threshold (default ≥ 0.7)
- Select only memory relevant to user request
- Detect and handle conflicting facts
- Deterministic and explainable selection logic

Memory is authoritative, LLM is advisory.
"""

from typing import List, Dict, Any, Optional, Tuple, Set
from enum import Enum
from datetime import datetime

from .memory_store import MemoryFact, get_memory_store


class RequestType(Enum):
    """Types of user requests for relevance mapping."""
    CODING = "coding"
    OUTPUT_FORMAT = "output_format"
    ARCHITECTURE = "architecture"
    FRAMEWORK = "framework"
    GENERAL = "general"
    DEBUGGING = "debugging"


class ConflictResolution(Enum):
    """Strategies for resolving conflicting memory facts."""
    HIGHER_CONFIDENCE = "higher_confidence"
    NEWER_TIMESTAMP = "newer_timestamp"
    BOTH_WITH_FLAG = "both_with_flag"
    ASK_USER = "ask_user"


class MemorySelector:
    """
    Intelligently selects relevant memory facts for prompt injection.

    Features:
    - Scope priority hierarchy (session → project → user → org)
    - Confidence threshold filtering
    - Category relevance mapping to request types
    - Conflict detection and resolution
    - Deterministic and explainable selection logic

    Example:
        >>> selector = MemorySelector()
        >>> request_type = RequestType.CODING
        >>> user_query = "Help me build a web app"
        >>> facts = selector.select_relevant_facts(
        ...     user_query,
        ...     request_type=request_type,
        ...     min_confidence=0.8
        ... )
        >>> # In production, use: logger.info(f"Selected {len(facts)} facts for injection")
        >>> print(f"Selected {len(facts)} facts for injection")
    """

    # Scope priority: lower index = higher priority
    SCOPE_PRIORITY = {
        "session": 0,
        "project": 1,
        "user": 2,
        "org": 3,
    }

    # Category relevance mapping: which memory categories are relevant to which request types
    CATEGORY_RELEVANCE: Dict[RequestType, Set[str]] = {
        RequestType.CODING: {"preference", "decision", "constraint"},
        RequestType.OUTPUT_FORMAT: {"preference"},
        RequestType.ARCHITECTURE: {"decision", "fact", "constraint"},
        RequestType.FRAMEWORK: {"decision", "fact", "constraint"},
        RequestType.GENERAL: {"preference", "decision", "constraint", "fact"},
        RequestType.DEBUGGING: {"preference", "constraint", "fact"},
    }

    def __init__(self, db_path: str = "./data/memory.db"):
        """
        Initialize MemorySelector.

        Args:
            db_path: Path to memory database
        """
        self.db_path = db_path
        self.store = get_memory_store(db_path)

    def select_relevant_facts(
        self,
        user_query: str,
        request_type: RequestType = RequestType.GENERAL,
        min_confidence: float = 0.7,
        max_facts: int = 20,
        scopes: Optional[List[str]] = None,
        categories: Optional[List[str]] = None,
        allow_conflicts: bool = False,
        sort_by_relevance: bool = True
    ) -> Tuple[List[MemoryFact], Dict[str, Any]]:
        """
        Select relevant memory facts based on user query and context.

        Args:
            user_query: The user's query or request
            request_type: Type of request (for category relevance)
            min_confidence: Minimum confidence threshold
            max_facts: Maximum number of facts to select
            scopes: Specific scopes to search (None = all scopes)
            categories: Specific categories to search (None = all categories)
            allow_conflicts: Whether to include conflicting facts
            sort_by_relevance: Whether to sort by relevance (vs confidence only)

        Returns:
            Tuple of (selected_facts, metadata) where metadata includes:
            - selection_reason: Explanation of why facts were selected
            - conflicts_detected: List of conflicts found
            - confidence_stats: Statistics about confidence distribution
        """
        # Query all candidate facts
        # Handle multiple scopes and categories
        all_facts = []

        # Determine which scopes to query
        if scopes:
            scope_list = scopes
        else:
            scope_list = None

        # Determine which categories to query
        if categories:
            category_list = categories
        else:
            category_list = None

        # Query for each scope if multiple specified
        if scope_list:
            for scope in scope_list:
                facts_for_scope = self.store.query_memory(
                    scope=scope,
                    category=None, min_confidence=min_confidence
                )
                all_facts.extend(facts_for_scope)
        else:
            # Query all scopes
            all_facts = self.store.query_memory(
                scope=scope_list,
                category=None, min_confidence=min_confidence
            )

        # Step 1: Sort by scope priority (session → project → user → org)
        facts_by_priority = sorted(
            all_facts,
            key=lambda f: self.SCOPE_PRIORITY.get(f.scope, 99)
        )

        # Step 2: Filter by category relevance
        if request_type != RequestType.GENERAL:
            relevant_categories = self.CATEGORY_RELEVANCE.get(request_type, set())
            facts_by_priority = [
                f for f in facts_by_priority
                if f.category in relevant_categories
            ]

        # Step 3: Remove low-confidence facts
        facts_by_priority = [
            f for f in facts_by_priority
            if f.confidence >= min_confidence
        ]

        # Step 4: Detect and handle conflicts
        conflicts = self._detect_conflicts(facts_by_priority)

        # Step 5: Resolve conflicts
        filtered_facts, conflict_reasons = self._resolve_conflicts(
            facts_by_priority,
            conflicts,
            allow_conflicts
        )

        # Step 6: Sort by relevance (scope priority first, then confidence)
        if sort_by_relevance:
            # Sort by scope priority first, then confidence
            # Note: updated_at is ISO string, can't easily sort by recency
            sorted_facts = sorted(
                filtered_facts,
                key=lambda f: (
                    self.SCOPE_PRIORITY.get(f.scope, 99),  # Scope priority (lower = higher priority)
                    -f.confidence,  # Higher confidence first within same scope
                )
            )
        else:
            sorted_facts = filtered_facts

        # Step 7: Limit to max_facts
        sorted_facts = sorted_facts[:max_facts]

        # Collect metadata
        # Build partial metadata
        partial_metadata = {
            "total_candidates": len(all_facts),
            "confidence_filtered": len(all_facts) - len(facts_by_priority),
            "category_filtered": 0,  # Simplified for now
            "conflicts_detected": len(conflicts),
            "selected_count": len(sorted_facts),
            "min_confidence": min_confidence,
            "request_type": request_type.value,
        }
        
        # Get selection reason
        selection_reason = self._explain_selection(
            sorted_facts,
            request_type,
            partial_metadata
        )
        
        # Complete metadata
        metadata = {
            **partial_metadata,
            "selection_reason": selection_reason
        }

        return sorted_facts, metadata

    def _detect_conflicts(self, facts: List[MemoryFact]) -> List[Dict[str, Any]]:
        """
        Detect conflicting memory facts.

        A conflict exists when multiple facts have the same key
        within the same scope but different values.

        Args:
            facts: List of facts to check

        Returns:
            List of conflict objects with details
        """
        conflicts = []

        # Group facts by (scope, key)
        by_key: Dict[Tuple[str, str], List[MemoryFact]] = {}
        for fact in facts:
            key = (fact.scope, fact.key)
            if key not in by_key:
                by_key[key] = []
            by_key[key].append(fact)

        # Find conflicts (multiple facts with same key)
        for key, fact_list in by_key.items():
            if len(fact_list) > 1:
                # Conflict detected - multiple facts with same key
                # Check if values differ
                values = [fact.to_dict()["value"] for fact in fact_list]

                # Normalize values for comparison
                normalized_values = []
                for v in values:
                    if isinstance(v, str):
                        normalized_values.append(v.lower())
                    elif isinstance(v, dict):
                        normalized_values.append(str(sorted(v.items())))
                    else:
                        normalized_values.append(str(v))

                unique_values = set(normalized_values)

                if len(unique_values) > 1:
                    # True conflict - different values
                    conflicts.append({
                        "scope": key[0],
                        "key": key[1],
                        "fact_ids": [f.id for f in fact_list],
                        "values": values,
                        "conflict_type": "different_values",
                        "resolution_needed": True
                    })
                else:
                    # No conflict - same value (duplicate, not conflicting)
                    conflicts.append({
                        "scope": key[0],
                        "key": key[1],
                        "fact_ids": [f.id for f in fact_list],
                        "values": values,
                        "conflict_type": "duplicate",
                        "resolution_needed": False
                    })

        return conflicts

    def _resolve_conflicts(
        self,
        facts: List[MemoryFact],
        conflicts: List[Dict[str, Any]],
        allow_conflicts: bool
    ) -> Tuple[List[MemoryFact], List[Dict[str, str]]]:
        """
        Resolve conflicts using deterministic strategy.

        Resolution Strategy:
        1. If allow_conflicts: Keep all facts
        2. If conflicts exist and not allow_conflicts:
           a. For each conflicting key group:
              - Keep fact with highest confidence
              - Or keep fact with newest timestamp if confidence tie
              - Mark others as suppressed

        Args:
            facts: List of facts to filter
            conflicts: List of conflict objects
            allow_conflicts: Whether to include conflicting facts

        Returns:
            Tuple of (filtered_facts, conflict_reasons)
        """
        if not allow_conflicts and conflicts:
            # Get keys with true conflicts (different values)
            true_conflict_keys = {
                c["key"]
                for c in conflicts
                if c["conflict_type"] == "different_values"
            }

            # Filter out facts with true conflicts
            conflict_fact_ids = set()
            for key in true_conflict_keys:
                conflict_fact_ids.update(c["fact_ids"])

            # Get all fact IDs involved in conflicts
            all_conflict_fact_ids = set()
            for c in conflicts:
                all_conflict_fact_ids.update(c["fact_ids"])

            # Keep only the best fact per conflicting key group
            # For each conflicting key group:
            # - Sort by confidence DESC, then by updated_at DESC
            # - Keep highest confidence, or newest if tie

            kept_facts = []
            conflict_reasons = []

            by_key: Dict[Tuple[str, str], List[MemoryFact]] = {}
            for fact in facts:
                key = (fact.scope, fact.key)
                if key not in by_key:
                    by_key[key] = []
                by_key[key].append(fact)

            for key, fact_list in by_key.items():
                if key in true_conflict_keys and len(fact_list) > 1:
                    # Conflict group - keep only best fact
                    # Sort by confidence DESC, then by updated_at DESC
                    sorted_facts = sorted(
                        fact_list,
                        key=lambda f: (f.confidence, f.updated_at),
                        reverse=True
                    )
                    # Keep the first (best) fact
                    kept_fact = sorted_facts[0]
                    kept_facts.append(kept_fact)

                    # Mark others as suppressed
                    suppressed_ids = [f.id for f in sorted_facts[1:]]

                    # Add conflict reason
                    kept_value = kept_fact.to_dict()["value"]
                    suppressed_values = [
                        f.to_dict()["value"]
                        for f in sorted_facts[1:]
                    ]

                    conflict_reasons.append({
                        "fact_id": kept_fact.id,
                        "key": key[1],
                        "scope": key[0],
                        "resolution": f"Kept {kept_value} (highest confidence), suppressed {len(suppressed_ids)} duplicates",
                        "conflict_ids": suppressed_ids
                    })

            # Add back non-conflicted facts and kept facts
            kept_ids = set(kept_fact.id for kept_fact in kept_facts)
            for fact in facts:
                if fact.id not in all_conflict_fact_ids or fact.id in kept_ids:
                    kept_facts.append(fact)

            conflict_reasons = [
                {
                    "fact_id": reason["fact_id"],
                    "key": reason["key"],
                    "scope": reason["scope"],
                    "resolution": reason["resolution"]
                }
                for reason in conflict_reasons
            ]

            return kept_facts, conflict_reasons

        else:
            # allow_conflicts: Return all facts, no resolution needed
            return facts, []

    def _explain_selection(
        self,
        facts: List[MemoryFact],
        request_type: RequestType,
        metadata: Dict[str, Any]
    ) -> str:
        """
        Generate human-readable explanation of selection.

        Args:
            facts: Selected facts
            request_type: Type of user request
            metadata: Selection metadata

        Returns:
            Explanation string
        """
        reasons = []

        # Scope priority
        scope_counts = {}
        for f in facts:
            scope_counts[f.scope] = scope_counts.get(f.scope, 0) + 1

        for scope, count in scope_counts.items():
            if count > 0:
                reasons.append(f"Facts from {scope} scope included (priority level {self.SCOPE_PRIORITY.get(scope, 'unknown')})")

        # Confidence distribution
        if facts:
            avg_confidence = sum(f.confidence for f in facts) / len(facts)
            min_confidence = min(f.confidence for f in facts)
            max_confidence = max(f.confidence for f in facts)
            reasons.append(f"Confidence range: {min_confidence:.2f}-{max_confidence:.2f} (avg: {avg_confidence:.2f})")

        # Category breakdown
        category_counts = {}
        for f in facts:
            category_counts[f.category] = category_counts.get(f.category, 0) + 1

        if category_counts:
            categories = ", ".join([f"{cat} ({count})" for cat, count in category_counts.items()])
            reasons.append(f"Categories included: {categories}")

        # Request type relevance
        if request_type != RequestType.GENERAL:
            request_name = request_type.value.replace("_", " ").title()
            reasons.append(f"Selected for {request_name} request type")

        # Total selected
        reasons.append(f"Total candidates: {metadata['total_candidates']}, selected: {metadata['selected_count']}")

        # Conflicts
        if metadata.get("conflicts_detected", 0) > 0:
            reasons.append(f"Conflicts detected: {metadata['conflicts_detected']}")

        return "; ".join(reasons)

    def get_scope_stats(self) -> Dict[str, Any]:
        """
        Get statistics about memory facts by scope.

        Returns:
            Dictionary with count per scope
        """
        stats = self.store.get_stats()
        return {
            "by_scope": stats.get("by_scope", {}),
            "total_facts": stats.get("total_facts", 0)
        }
