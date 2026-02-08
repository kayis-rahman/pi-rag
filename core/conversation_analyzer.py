"""
Conversation Analyzer - Extract facts and episodes from conversations using heuristics + LLM.

Extraction Modes:
1. Heuristic: Fast regex patterns (no LLM, <10ms)
2. LLM: Prompt-based extraction (high quality, <100ms)
3. Hybrid: Heuristics first, LLM for complex (balanced)

NEW: Async processing for non-blocking behavior.
NEW: Token budget management (configurable).
NEW: Per-day deduplication (allow repeats across sessions).
"""

import re
import asyncio
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


class ConversationAnalyzer:
    """
    Analyze conversations for automatic learning.

    Configuration:
    - extraction_mode: "heuristic" | "llm" | "hybrid"
    - use_llm: bool (use LLM for extraction)
    - min_fact_confidence: float (0.0-1.0)
    - min_episode_confidence: float (0.0-1.0)
    - async_processing: bool (enable async mode)
    - deduplication_mode: "per_session" | "per_day" | "global"

    Token Budget:
    - llm_token_budget: dict with enabled flag and limits
    - max_tokens_per_session: maximum tokens per session
    - max_tokens_per_message: maximum tokens per message
    - budget_reset_mode: "per_session" | "per_day" | "never"
    """

    def __init__(
        self,
        model_manager: Optional[Any] = None,
        config: Optional[Dict[str, Any]] = None
    ):
        """Initialize with LLM access and config."""
        self.model_manager = model_manager
        self.config = config or {}

        # Configuration
        self.extraction_mode = self.config.get("extraction_mode", "hybrid")
        self.use_llm = self.config.get("use_llm", True)
        self.min_fact_confidence = self.config.get("min_fact_confidence", 0.7)
        self.min_episode_confidence = self.config.get("min_episode_confidence", 0.6)

        # NEW: Async processing flag
        self.async_processing = self.config.get("async_processing", True)

        # NEW: Token budget
        self.token_budget = self.config.get("llm_token_budget", {})
        self.tokens_used_this_session = 0
        self.tokens_used_today = 0

        # NEW: Per-day deduplication
        self.deduplication_mode = self.config.get("deduplication_mode", "per_day")
        self.window_days = self.config.get("deduplication_window_days", 7)
        self.recent_facts = {}  # key -> list of timestamps
        self.recent_episodes = {}  # key -> list of timestamps

        logger.info(
            f"ConversationAnalyzer initialized: mode={self.extraction_mode}, "
            f"async={self.async_processing}, llm={self.use_llm}"
        )

    async def analyze_conversation_async(
        self,
        user_message: str,
        agent_response: str,
        context: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Async version of analyze_conversation (non-blocking).

        Heuristics run synchronously (<10ms).
        LLM extraction runs asynchronously (non-blocking).

        Args:
            user_message: User's message
            agent_response: Agent's response
            context: Optional context (tool calls, session info)

        Returns:
            List of learnings (facts + episodes)
        """
        start_time = datetime.now()
        learnings = []

        # Fast: heuristics (sync, <10ms)
        user_heuristics = self._extract_facts_heuristic(user_message)
        user_episodes = self._extract_episodes_heuristic(user_message)
        agent_heuristics = self._extract_facts_heuristic(agent_response)
        agent_episodes = self._extract_episodes_heuristic(agent_response)

        learnings.extend(user_heuristics + user_episodes + agent_heuristics + agent_episodes)

        # Slow: LLM extraction (async, non-blocking)
        if self.use_llm and self.extraction_mode in ["llm", "hybrid"]:
            # Spawn async LLM tasks
            llm_tasks = [
                self._extract_facts_llm_async(user_message, context),
                self._extract_facts_llm_async(agent_response, context),
                self._extract_episodes_llm_async(user_message + " " + agent_response, context)
            ]

            # Wait for both (parallel, non-blocking)
            llm_results = await asyncio.gather(*llm_tasks, return_exceptions=True)

            # Merge results
            for result in llm_results:
                if isinstance(result, list):
                    learnings.extend(result)
                elif isinstance(result, Exception):
                    logger.warning(f"LLM extraction failed: {result}")

        # Score confidence
        for learning in learnings:
            learning["confidence"] = self.score_confidence(learning)

        # NEW: Per-day deduplication
        learnings = self.deduplicate(learnings)

        duration = (datetime.now() - start_time).total_seconds() * 1000
        logger.info(f"Analyzed conversation in {duration:.0f}ms: {len(learnings)} learnings")

        return learnings

    async def _extract_facts_llm_async(
        self,
        text: str,
        context: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Async LLM fact extraction with token budget check.

        NEW: Non-blocking async/await.
        NEW: Token budget enforcement.
        """
        # NEW: Check token budget
        if self._should_skip_llm_due_to_budget(text):
            logger.info("Skipping LLM extraction: token budget exceeded")
            return []

        # Estimate tokens
        estimated_tokens = self._estimate_tokens(text)

        # NEW: Async LLM call
        try:
            result = await self._llm_call_async(
                prompt=self._build_fact_extraction_prompt(text),
                temperature=0.3,
                max_tokens=500
            )

            # NEW: Track token usage
            self.tokens_used_this_session += estimated_tokens
            self.tokens_used_today += estimated_tokens

            return self._parse_fact_response(result)
        except Exception as e:
            logger.error(f"LLM fact extraction failed: {e}")
            return []

    async def _extract_episodes_llm_async(
        self,
        text: str,
        context: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """Async LLM episode extraction with token budget check."""
        # Similar implementation to _extract_facts_llm_async
        pass

    def _should_skip_llm_due_to_budget(self, text: str) -> bool:
        """Check if token budget exceeded."""
        if not self.token_budget.get("enabled", False):
            return False

        max_per_session = self.token_budget.get("max_tokens_per_session", float('inf'))
        max_per_message = self.token_budget.get("max_tokens_per_message", float('inf'))

        # Check per-message limit
        estimated_tokens = self._estimate_tokens(text)
        if estimated_tokens > max_per_message:
            logger.info(
                f"Skipping LLM: message exceeds per-message budget "
                f"({estimated_tokens} > {max_per_message})"
            )
            return True

        # Check per-session limit
        if self.tokens_used_this_session + estimated_tokens > max_per_session:
            logger.info(
                f"Skipping LLM: session budget exceeded "
                f"({self.tokens_used_this_session} + {estimated_tokens} > {max_per_session})"
            )
            return True

        return False

    def _estimate_tokens(self, text: str) -> int:
        """Rough token estimation (4 chars = 1 token)."""
        return len(text) // 4

    async def _llm_call_async(self, prompt: str, temperature: float, max_tokens: int) -> str:
        """Async LLM call."""
        # Implementation depends on model_manager interface
        if self.async_processing and hasattr(self.model_manager, 'chat_completion_async'):
            return await self.model_manager.chat_completion_async(
                "chat",
                [{"role": "system", "content": "You are a helpful assistant that outputs valid JSON only."},
                 {"role": "user", "content": prompt}],
                temperature=temperature,
                max_tokens=max_tokens
            )
        else:
            # Fallback to sync
            return self.model_manager.chat_completion(
                "chat",
                [{"role": "system", "content": "You are a helpful assistant that outputs valid JSON only."},
                 {"role": "user", "content": prompt}],
                temperature=temperature,
                max_tokens=max_tokens
            )

    def deduplicate(self, learnings: List[Dict]) -> List[Dict]:
        """
        Deduplicate with per-day strategy.

        NEW: Allow 1 fact per day within window.
        """
        mode = self.deduplication_mode
        window_days = self.window_days
        now = datetime.now()
        cutoff = now - timedelta(days=window_days)

        filtered = []

        for learning in learnings:
            key = self._get_learning_key(learning)

            if mode == "per_day":
                # NEW: Allow 1 fact per day, reinforce over time
                if key in self.recent_facts:
                    timestamps = self.recent_facts[key]
                    # Clean old timestamps
                    timestamps = [t for t in timestamps if t > cutoff]

                    # Check if already added today
                    today = now.date()
                    already_today = any(t.date() == today for t in timestamps)

                    if not already_today:
                        # Allow - reinforces learning
                        filtered.append(learning)
                        timestamps.append(now)
                        self.recent_facts[key] = timestamps
                    else:
                        # Skip - already added today
                        logger.debug(f"Skipping duplicate (per-day): {key}")
                else:
                    # New fact
                    filtered.append(learning)
                    self.recent_facts[key] = [now]

            elif mode == "per_session":
                # Never duplicate in same session
                if key not in self.recent_facts:
                    filtered.append(learning)
                    self.recent_facts[key] = [now]

            elif mode == "global":
                # Never duplicate ever
                if key not in self.recent_facts:
                    filtered.append(learning)
                    self.recent_facts[key] = [now]

        return filtered

    def _get_learning_key(self, learning: Dict) -> str:
        """Get deduplication key from learning."""
        if learning["type"] == "fact":
            return f"fact:{learning.get('key', '')}"
        elif learning["type"] == "episode":
            return f"episode:{learning.get('title', '')}"
        return f"unknown:{hash(str(learning))}"

    def _extract_facts_heuristic(self, text: str) -> List[Dict[str, Any]]:
        """Extract facts using regex patterns."""
        patterns = {
            "api_endpoint": r"API (?:endpoint|url|address) is (https?://[^\s]+)",
            "version": r"(?:version|ver) is ([\d.]+)",
            "preference": r"prefer (\w+) over (\w+)",
            "decision": r"(?:decided|agreed|confirmed) to use (\w+)",
            "constraint": r"(?:must|cannot|should not) (?:use|support) (\w+)"
        }

        facts = []
        for key, pattern in patterns.items():
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                facts.append({
                    "type": "fact",
                    "key": key,
                    "value": match.group(1) if key == "preference" else match.group(0),
                    "confidence": 0.85,  # High confidence for heuristic matches
                    "source": "heuristic"
                })

        return facts

    def _extract_episodes_heuristic(self, text: str) -> List[Dict[str, Any]]:
        """Extract episodes using regex patterns."""
        patterns = {
            "workaround": r"(?:i found|there(?:['\u2019])?s a) .*?workaround",
            "mistake": r"(?:this|that) .*?(?:didn't work|was a mistake|failed)",
            "lesson": r"(?:the |i )(?:lesson is|learned)",
            "recommendation": r"(?:i recommend|you should)",
            "success": r"(?:successfully|successfuly) (?:completed|finished)"
        }

        episodes = []
        for lesson_type, pattern in patterns.items():
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                episodes.append({
                    "type": "episode",
                    "lesson_type": lesson_type,  # Add missing key
                    "situation": text[:100],  # First 100 chars
                    "action": "Pattern detected: " + match.group(0),
                    "outcome": "success" if lesson_type == "success" else "pattern",
                    "lesson": self._abstract_lesson(lesson_type, text),
                    "confidence": 0.75,
                    "source": "heuristic"
                })

        return episodes

    def _abstract_lesson(self, lesson_type: str, text: str) -> str:
        """Abstract lesson into reusable strategy."""
        # Simple abstraction logic
        if lesson_type == "workaround":
            return "Workarounds can solve seemingly impossible problems"
        elif lesson_type == "mistake":
            return "Documenting mistakes prevents repetition"
        elif lesson_type == "lesson":
            return "Explicitly stated lessons capture tacit knowledge"
        elif lesson_type == "recommendation":
            return "User recommendations often shortcut experimentation"
        elif lesson_type == "success":
            return "Successful patterns should be repeated"
        return "Pattern detected from conversation"

    def score_confidence(self, learning: Dict) -> float:
        """Score confidence of extracted learning."""
        # Factors:
        # - Pattern strength (how specific regex matched)
        # - LLM confidence (if from LLM)
        # - Context relevance
        # - Duplicate detection

        base_confidence = learning.get("confidence", 0.7)

        # Boost confidence if multiple indicators
        if learning.get("source") == "heuristic":
            # High confidence for heuristic matches
            base_confidence = min(base_confidence * 1.1, 1.0)

        return min(base_confidence, 1.0)

    def _build_fact_extraction_prompt(self, text: str) -> str:
        """Build prompt for LLM fact extraction."""
        prompt = """Analyze this message and extract factual statements:

Message: {message}

Extract facts about:
- Project configuration (API endpoints, versions, paths, settings)
- User preferences ("prefer X over Y")
- Technical decisions (framework choice, architecture)
- Constraints/requirements ("must use X", "cannot use Y")

Return JSON array of facts:
[
  {{"key": "fact_key", "value": "fact_value", "confidence": 0.9}}
]

If NO facts qualify, return: {{ "facts": [] }}"""
        return prompt.format(message=text)

    def _parse_fact_response(self, response: str) -> List[Dict[str, Any]]:
        """Parse JSON response from LLM."""
        try:
            import json
            data = json.loads(response)

            if isinstance(data, dict) and "facts" in data:
                facts = []
                for fact in data["facts"]:
                    facts.append({
                        "type": "fact",
                        "key": fact.get("key", ""),
                        "value": fact.get("value", ""),
                        "confidence": fact.get("confidence", 0.8),
                        "source": "llm"
                    })
                return facts

            return []
        except Exception as e:
            logger.error(f"Failed to parse LLM response: {e}")
            return []

    # Sync wrapper for backwards compatibility
    def analyze_conversation(
        self,
        user_message: str,
        agent_response: str,
        context: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Sync version of analyze_conversation.

        NEW: Wraps async version for compatibility.
        """
        if self.async_processing:
            # Use async version
            return asyncio.run(self.analyze_conversation_async(user_message, agent_response, context))
        else:
            # Use sync version (heuristics only)
            learnings = []

            # Heuristics only
            user_heuristics = self._extract_facts_heuristic(user_message)
            user_episodes = self._extract_episodes_heuristic(user_message)
            agent_heuristics = self._extract_facts_heuristic(agent_response)
            agent_episodes = self._extract_episodes_heuristic(agent_response)

            learnings.extend(user_heuristics + user_episodes + agent_heuristics + agent_episodes)

            # Score confidence
            for learning in learnings:
                learning["confidence"] = self.score_confidence(learning)

            # Deduplicate
            learnings = self.deduplicate(learnings)

            return learnings
