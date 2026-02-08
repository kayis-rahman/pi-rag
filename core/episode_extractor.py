"""
Episode Extractor - LLM-assisted extraction of agent lessons from experience.

Design Principles (NON-NEGOTIABLE):
- Extracts lessons, NOT facts
- Abstracts experience, NOT logs
- Validates JSON output strictly
- Returns empty if no episode qualifies
- No automatic persistence (explicit write only)

Episode Write Rules (CRITICAL):
An episode may be written only if at least one is true:
- A task completes successfully in a non-obvious way
- A mistake is detected and corrected
- A strategy repeats across sessions
- User feedback alters agent behavior

DO NOT write episodes for:
- Normal success
- Single attempts
- Raw failures without insight

Output Format:
{
  "situation": "What the agent faced",
  "action": "What it did",
  "outcome": "success/failure",
  "lesson": "Abstracted strategy",
  "confidence": 0.85
}
"""

import json
import re
from typing import Dict, Any, Optional, List
from .logger import get_logger

logger = get_logger(__name__)


class EpisodeExtractor:
    """
    LLM-assisted episode extraction from agent interactions.

    Responsibilities:
    - Receive situation, action, outcome
    - Use LLM to extract abstract lesson
    - Validate output strictly
    - Return empty if no episode qualifies

    Example:
        >>> extractor = EpisodeExtractor(llm_completion_func)
        >>> episode = extractor.extract_episode(
        ...     situation="Large repository with unclear entry point",
        ...     action="Searched filenames before reading files",
        ...     outcome="Found relevant code quickly"
        ... )
        >>> if episode:
        ...     store.store_episode(episode)
    """

    # Episode write rules
    VALID_SCENARIOS = [
        "non_obvious_success",  # Task completed in non-obvious way
        "mistake_corrected",    # Mistake detected and corrected
        "strategy_repeat",      # Strategy repeats across sessions
        "feedback_behavior",    # User feedback altered behavior
    ]

    def __init__(self, llm_completion_func, min_confidence: float = 0.6):
        """
        Initialize episode extractor.

        Args:
            llm_completion_func: Function that takes prompt and returns LLM response
            min_confidence: Minimum confidence threshold for valid episodes
        """
        self.llm_completion_func = llm_completion_func
        self.min_confidence = min_confidence

    def _build_extraction_prompt(
        self,
        situation: str,
        action: str,
        outcome: str,
        scenario_type: Optional[str] = None
    ) -> str:
        """
        Build the extraction prompt for the LLM.

        Args:
            situation: What the agent faced
            action: What the agent did
            outcome: Result of the action
            scenario_type: Type of scenario (optional)

        Returns:
            Formatted prompt string
        """
        scenario_hint = ""
        if scenario_type in self.VALID_SCENARIOS:
            scenario_hint = f"Scenario Type: {scenario_type}\n"

        prompt = f"""You are an episode extractor for an AI agent. Your task is to analyze agent behavior and extract learned lessons.

{scenario_hint}Input:
- Situation: {situation}
- Action: {action}
- Outcome: {outcome}

Instructions:
1. Determine if this represents a LEARNABLE LESSON (not just a fact, not a log)
2. If NO lesson is learned, return empty JSON: {{}}
3. If a lesson exists, extract the ABSTRACTED STRATEGY
4. The lesson should be generalizable, not specific to this exact situation
5. Output MUST be valid JSON only (no extra text)

Output format:
{{
  "situation": "Brief description of the situation",
  "action": "Brief description of the action taken",
  "outcome": "Brief description of the outcome",
  "lesson": "Abstracted strategy (generalizable)",
  "confidence": 0.85
}}

VALID EXAMPLES:
- "For large repos, perform keyword search before file traversal"
- "User prefers concise output over verbose explanations"
- "Running retrieval before planning caused confusion"

INVALID EXAMPLES:
- "Project uses Go" (this is a fact, not a lesson)
- "User likes JSON" (this is a preference, not a lesson)
- Raw conversation logs (lessons must be abstracted)

Output JSON only:"""

        return prompt

    def extract_episode(
        self,
        situation: str,
        action: str,
        outcome: str,
        scenario_type: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Extract an episode from the given situation, action, outcome.

        Args:
            situation: What the agent faced
            action: What the agent did
            outcome: Result of the action
            scenario_type: Type of scenario (optional)

        Returns:
            Episode dict with keys: situation, action, outcome, lesson, confidence
            Returns None if no lesson qualifies or validation fails
        """
        # Build prompt
        prompt = self._build_extraction_prompt(
            situation, action, outcome, scenario_type
        )

        try:
            # Call LLM
            response = self.llm_completion_func(prompt)

            # Parse JSON
            episode_data = self._parse_json_response(response)

            if not episode_data:
                return None

            # Validate episode structure
            if not self._validate_episode_data(episode_data):
                return None

            # Ensure lesson is abstract, not factual
            if self._is_fact_not_lesson(episode_data):
                return None

            # Check confidence threshold
            if episode_data.get("confidence", 0.0) < self.min_confidence:
                return None

            return episode_data

        except Exception as e:
            # Log error but don't crash - episodes are optional
            logger.error(f"Episode extraction failed: {e}")
            return None

    def _parse_json_response(self, response: str) -> Optional[Dict[str, Any]]:
        """
        Parse JSON from LLM response with error handling.

        Args:
            response: Raw LLM response string

        Returns:
            Parsed dict or None if invalid
        """
        if not response:
            return None

        # Try to extract JSON from response
        try:
            # Remove markdown code blocks if present
            cleaned = response.strip()

            # Remove ```json and ``` markers
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            if cleaned.startswith("```"):
                cleaned = cleaned[3:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]

            cleaned = cleaned.strip()

            # Parse JSON
            data = json.loads(cleaned)

            # Check for empty dict (no lesson)
            if not data:
                return None

            return data

        except (json.JSONDecodeError, AttributeError) as e:
            logger.error(f"Failed to parse JSON response: {e}")
            return None

    def _validate_episode_data(self, data: Dict[str, Any]) -> bool:
        """
        Validate episode data structure and content.

        Args:
            data: Episode dict to validate

        Returns:
            True if valid, False otherwise
        """
        # Check required fields
        required_fields = ["situation", "action", "outcome", "lesson", "confidence"]
        if not all(field in data for field in required_fields):
            return False

        # Check field types
        if not isinstance(data["situation"], str) or not data["situation"]:
            return False

        if not isinstance(data["action"], str) or not data["action"]:
            return False

        if not isinstance(data["outcome"], str) or not data["outcome"]:
            return False

        if not isinstance(data["lesson"], str) or not data["lesson"]:
            return False

        if not isinstance(data["confidence"], (int, float)):
            return False

        # Check confidence range
        confidence = float(data["confidence"])
        if confidence < 0.0 or confidence > 1.0:
            return False

        # Check lesson length (should be concise)
        if len(data["lesson"]) > 500:
            return False

        return True

    def _is_fact_not_lesson(self, data: Dict[str, Any]) -> bool:
        """
        Check if episode is a fact (should be in symbolic memory) not a lesson.

        Args:
            data: Episode dict to check

        Returns:
            True if it's a fact (invalid for episodic), False if it's a lesson
        """
        lesson = data["lesson"].lower()
        situation = data["situation"].lower()

        # Patterns that indicate facts (not lessons)
        fact_patterns = [
            "project uses",
            "user likes",
            "user prefers",
            "code is written in",
            "file contains",
            "function does",
            "api endpoint is",
        ]

        for pattern in fact_patterns:
            if pattern in lesson:
                return True

        # Lesson should not just repeat situation
        if lesson == situation:
            return True

        # Lesson should contain abstract concepts
        abstract_keywords = [
            "should", "prefer", "avoid", "before", "after",
            "helps", "causes", "leads to", "results in",
            "better", "worse", "faster", "slower"
        ]

        has_abstract = any(keyword in lesson for keyword in abstract_keywords)

        if not has_abstract:
            return True

        return False

    def batch_extract_episodes(
        self,
        interactions: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Extract episodes from a list of interactions.

        Args:
            interactions: List of dicts with 'situation', 'action', 'outcome', 'scenario_type'

        Returns:
            List of valid episode dicts
        """
        episodes = []

        for interaction in interactions:
            situation = interaction.get("situation", "")
            action = interaction.get("action", "")
            outcome = interaction.get("outcome", "")
            scenario_type = interaction.get("scenario_type")

            episode = self.extract_episode(
                situation, action, outcome, scenario_type
            )

            if episode:
                episodes.append(episode)

        return episodes


def create_simple_llm_func(model_manager, model_name: str = "chat"):
    """
    Create a simple LLM completion function for episode extraction.

    Args:
        model_manager: ModelManager instance
        model_name: Name of model to use

    Returns:
        Function that takes prompt and returns LLM response
    """
    def llm_completion_func(prompt: str) -> str:
        """Simple LLM completion function."""
        try:
            messages = [
                {"role": "system", "content": "You are a helpful assistant that outputs valid JSON only."},
                {"role": "user", "content": prompt}
            ]

            response = model_manager.chat_completion(
                model_name,
                messages,
                temperature=0.3,  # Lower temperature for more consistent extraction
                max_tokens=500
            )

            # Extract content
            if response and isinstance(response, dict):
                choices = response.get("choices", [])
                if choices:
                    choice = choices[0]
                    if "message" in choice:
                        return choice["message"].get("content", "")
                    elif "text" in choice:
                        return choice["text"]

            return ""

        except Exception as e:
            logger.error(f"LLM completion error: {e}")
            return ""

    return llm_completion_func
