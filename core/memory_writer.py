"""
Memory Writer - LLM-assisted memory extraction from interactions.

Design Principles (STRICT):
- Memory writes are explicit, not automatic
- No guesses, single mentions, or agent assumptions
- Output must be valid JSON
- Confidence and source must be included
- Returns empty list if nothing qualifies

Memory Write Rules (NON-NEGOTIABLE):
Memory CAN be written only if at least ONE is true:
1. User explicitly says "remember", "use this going forward"
2. A hard technical decision is made
3. A structural fact is confirmed (language, framework, architecture)
4. A preference is explicitly stated

Memory MUST NOT be written for:
- Guesses
- Single mentions
- Agent assumptions
- Generated content
"""

import json
import logging
import re
from typing import List, Dict, Any, Optional, TYPE_CHECKING

# Import at runtime to avoid circular imports
from .memory_store import MemoryFact, get_memory_store
from .logger import get_logger

logger = get_logger(__name__)

if TYPE_CHECKING:
    from .memory_store import MemoryStore


class MemoryWriter:
    """
    Extracts candidate memory facts from interactions using LLM.

    Features:
    - Safe JSON parsing with validation
    - Confidence scoring
    - Fact validation against write rules
    - Deterministic extraction (no hallucinations)
    - Explicit extraction (not automatic)

    Example:
        >>> writer = MemoryWriter()
        >>> interaction = {
        ...     "role": "user",
        ...     "content": "I prefer JSON output for all responses"
        ... }
        >>> facts = writer.extract_memory(interaction, scope="user")
        >>> if facts:
        ...     store = get_memory_store()
        ...     for fact in facts:
        ...         store.store_memory(fact)
    """

    # System prompt for memory extraction
    SYSTEM_PROMPT = """You are a Memory Extraction System. Your task is to identify explicit, durable facts from user interactions that should be stored for future reference.

STRICT RULES:
- Only extract facts that are EXPLICITLY stated by the user
- DO NOT extract guesses, assumptions, or single casual mentions
- DO NOT extract generated content or agent responses
- Only extract when user says phrases like "remember", "use this going forward", "always"
- Only extract confirmed technical decisions (language, framework, architecture)
- Only extract explicitly stated preferences

VALID FACT CATEGORIES:
- preference: User preferences (e.g., "I prefer JSON output")
- constraint: Requirements/limitations (e.g., "Cannot use external APIs")
- decision: Technical decisions (e.g., "We'll use Python for this project")
- fact: Confirmed structural facts (e.g., "This is a FastAPI project")

OUTPUT FORMAT:
Return ONLY valid JSON with this structure:
{
  "facts": [
    {
      "scope": "user|project|org|session",
      "category": "preference|constraint|decision|fact",
      "key": "unique_key_name",
      "value": "fact_value",
      "confidence": 0.0-1.0,
      "source": "user"
    }
  ]
}

CONFIDENCE GUIDELINES:
- 1.0: Explicit user statement with "remember" or "always"
- 0.9: Clear preference with direct confirmation
- 0.8: Strong inference from context (use sparingly)
- 0.7 or lower: DO NOT include

If NO facts qualify, return:
{"facts": []}

CRITICAL:
- Output MUST be valid JSON only
- No explanations, no markdown, no additional text
- If unsure, do not include the fact
- Return empty array if nothing qualifies"""

    def __init__(self, default_scope: str = "session", default_source: str = "user"):
        """
        Initialize MemoryWriter.

        Args:
            default_scope: Default scope for extracted facts
            default_source: Default source for extracted facts
        """
        self.default_scope = default_scope
        self.default_source = default_source

    def extract_memory(
        self,
        interaction: Dict[str, Any],
        scope: Optional[str] = None,
        model_name: str = "chat",
        temperature: float = 0.3
    ) -> List[MemoryFact]:
        """
        Extract memory facts from an interaction using LLM.

        Args:
            interaction: Interaction dict with 'role' and 'content'
            scope: Scope for extracted facts (defaults to instance default)
            model_name: Model to use for extraction
            temperature: Temperature for generation (low = deterministic)

        Returns:
            List of MemoryFact objects (empty if nothing qualifies)

        Note:
            This is a placeholder implementation. To use with actual LLM,
            you need to integrate with your ModelManager or external API.
            See extract_memory_with_model() for a working example.
        """
        # This is a rule-based fallback implementation
        # In production, integrate with ModelManager for LLM extraction

        role = interaction.get("role", "")
        content = interaction.get("content", "")

        # Only extract from user messages
        if role != "user":
            return []

        # Rule-based extraction as fallback
        facts = []

        # Check for explicit "remember" or "always" phrases
        if self._contains_explicit_memory_keyword(content):
            extracted = self._extract_facts_from_text(content, scope or self.default_scope)
            facts.extend(extracted)

        return facts

    def extract_memory_with_model(
        self,
        interaction: Dict[str, Any],
        model_manager,
        scope: Optional[str] = None,
        model_name: str = "chat",
        temperature: float = 0.3
    ) -> List[MemoryFact]:
        """
        Extract memory facts using actual LLM model.

        Args:
            interaction: Interaction dict with 'role' and 'content'
            model_manager: ModelManager instance for LLM access
            scope: Scope for extracted facts
            model_name: Model to use for extraction
            temperature: Temperature for generation

        Returns:
            List of MemoryFact objects (empty if nothing qualifies)
        """
        role = interaction.get("role", "")
        content = interaction.get("content", "")

        # Only extract from user messages
        if role != "user":
            return []

        # Build prompt
        user_prompt = f"""Analyze this user interaction and extract any facts that should be remembered:

User Message:
{content}

Extract facts that meet these criteria:
- User explicitly says "remember", "always", "use this going forward"
- Hard technical decisions are confirmed
- Structural facts about language/framework/architecture
- Explicit preferences are stated

Return ONLY valid JSON."""

        try:
            # Call the model
            response = model_manager.chat_completion(
                model_name,
                [
                    {"role": "system", "content": self.SYSTEM_PROMPT},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=temperature,
                max_tokens=1000
            )

            # Extract content from response
            llm_content = ""
            if response and isinstance(response, dict):
                choices = response.get("choices", [])
                if choices:
                    choice = choices[0]
                    if "message" in choice:
                        llm_content = choice["message"].get("content", "")
                    elif "text" in choice:
                        llm_content = choice.get("text", "")

            # Parse JSON response
            facts = self._parse_and_validate_response(llm_content, scope or self.default_scope)
            return facts

        except Exception as e:
            logger.error(f"Error in memory extraction: {e}")
            return []

    def _contains_explicit_memory_keyword(self, text: str) -> bool:
        """
        Check if text contains explicit memory keywords.

        Args:
            text: Text to check

        Returns:
            True if explicit memory keyword is found
        """
        memory_keywords = [
            r'\bremember\b',
            r'\balways\b',
            r'\buse this going forward\b',
            r'\bfrom now on\b',
            r'\bprefer\b',
            r'\bwant\b.*\bto\b',
            r'\brequire\b',
            r'\bmust\b',
            r'\bdecision\b',
            r'\busing\b.*\bfor\b',
            r'\bbuilt with\b'
        ]

        text_lower = text.lower()

        for pattern in memory_keywords:
            if re.search(pattern, text_lower):
                return True

        return False

    def _extract_facts_from_text(self, text: str, scope: str) -> List[MemoryFact]:
        """
        Extract facts from text using rule-based patterns.

        Args:
            text: Text to analyze
            scope: Scope for facts

        Returns:
            List of MemoryFact objects
        """
        facts = []
        text_lower = text.lower()

        # Pattern: "I prefer X"
        prefer_match = re.search(r'i prefer (.+)', text_lower)
        if prefer_match:
            preference = prefer_match.group(1).strip()
            facts.append(MemoryFact(
                scope=scope,
                category="preference",
                key="user_preference",
                value={"preference": preference},
                confidence=0.9,
                source="user"
            ))

        # Pattern: "Always use X"
        always_match = re.search(r'always use (.+)', text_lower)
        if always_match:
            value = always_match.group(1).strip()
            facts.append(MemoryFact(
                scope=scope,
                category="preference",
                key="always_use",
                value={"value": value},
                confidence=0.95,
                source="user"
            ))

        # Pattern: "We're using X" (language/framework)
        using_match = re.search(r'we\'?re using (.+)', text_lower)
        if using_match:
            tech = using_match.group(1).strip()
            # Determine if it's a language, framework, or tool
            if any(lang in tech for lang in ['python', 'javascript', 'java', 'go', 'rust']):
                category = "decision"
                key = "programming_language"
            elif any(fw in tech for fw in ['fastapi', 'flask', 'django', 'react', 'vue']):
                category = "decision"
                key = "framework"
            else:
                category = "fact"
                key = "technology_stack"

            facts.append(MemoryFact(
                scope=scope,
                category=category,
                key=key,
                value={"value": tech},
                confidence=0.85,
                source="user"
            ))

        return facts

    def _parse_and_validate_response(
        self,
        response_text: str,
        scope: str
    ) -> List[MemoryFact]:
        """
        Parse and validate LLM JSON response.

        Args:
            response_text: JSON response from LLM
            scope: Scope for facts

        Returns:
            List of validated MemoryFact objects
        """
        facts = []

        try:
            # Extract JSON from response (handle potential markdown code blocks)
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if not json_match:
                logger.warning("No valid JSON found in response")
                return []

            json_str = json_match.group(0)
            data = json.loads(json_str)

            # Validate structure
            if not isinstance(data, dict) or "facts" not in data:
                logger.warning("Invalid response structure: missing 'facts' key")
                return []

            facts_array = data["facts"]
            if not isinstance(facts_array, list):
                logger.warning("Invalid 'facts' type: expected list")
                return []

            # Convert to MemoryFact objects
            for fact_data in facts_array:
                try:
                    fact = self._dict_to_memory_fact(fact_data, scope)
                    facts.append(fact)
                except (ValueError, KeyError) as e:
                    logger.warning(f"Invalid fact data: {e}")
                    continue

        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
        except Exception as e:
            logger.error(f"Error parsing response: {e}")

        return facts

    def _dict_to_memory_fact(
        self,
        data: Dict[str, Any],
        scope: str
    ) -> 'MemoryFact':
        """
        Convert dict to MemoryFact with validation.

        Args:
            data: Fact data dict
            scope: Scope for the fact

        Returns:
            MemoryFact object

        Raises:
            ValueError: If validation fails
        """
        from .memory_store import MemoryFact, MemoryStore

        # Validate required fields
        required_fields = ["category", "key", "value", "confidence", "source"]
        for field in required_fields:
            if field not in data:
                raise ValueError(f"Missing required field: {field}")

        # Use provided scope or data's scope
        fact_scope = data.get("scope", scope)

        # Validate values
        if data["category"] not in MemoryStore.VALID_CATEGORIES:
            raise ValueError(f"Invalid category: {data['category']}")

        if data["source"] not in MemoryStore.VALID_SOURCES:
            raise ValueError(f"Invalid source: {data['source']}")

        confidence = float(data["confidence"])
        if not (0.0 <= confidence <= 1.0):
            raise ValueError(f"Confidence must be between 0.0 and 1.0, got {confidence}")

        return MemoryFact(
            scope=fact_scope,
            category=data["category"],
            key=data["key"],
            value=data["value"],
            confidence=confidence,
            source=data["source"]
        )


def extract_and_store(
    interaction: Dict[str, Any],
    scope: Optional[str] = None,
    model_manager=None,
    db_path: str = "./data/memory.db"
) -> List[MemoryFact]:
    """
    Convenience function: Extract memory and store it.

    Args:
        interaction: Interaction dict with 'role' and 'content'
        scope: Scope for facts
        model_manager: Optional ModelManager for LLM extraction
        db_path: Path to memory database

    Returns:
        List of stored MemoryFact objects
    """
    writer = MemoryWriter()
    store = get_memory_store(db_path)

    if model_manager:
        facts = writer.extract_memory_with_model(interaction, model_manager, scope)
    else:
        facts = writer.extract_memory(interaction, scope)

    # Store facts
    stored = []
    for fact in facts:
        try:
            stored_fact = store.store_memory(fact)
            if stored_fact:
                stored.append(stored_fact)
        except Exception as e:
            logger.error(f"Error storing memory fact: {e}")

    return stored
