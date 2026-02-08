"""
Universal Hook Interface

Standard interface for hook-based auto-learning that all agent adapters must implement.
"""

from typing import Dict, Any, Optional
from abc import ABC, abstractmethod


class UniversalHookInterface(ABC):
    """
    Standard interface for hook-based auto-learning.

    All agent adapters must implement these methods.

    Design Principles:
    - Language-agnostic (Python, TypeScript, Bash, REST)
    - Graceful degradation (never crash agents)
    - Async-ready (supports both sync and async)
    - Zero agent lock-in (hooks only, no agent code modification)
    """

    @abstractmethod
    def pre_tool_use(
        self,
        tool_name: str,
        arguments: Dict[str, Any],
        user_message: str,
        agent_response: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Called before tool execution.

        Args:
            tool_name: Name of tool being executed
            arguments: Tool arguments (dict)
            user_message: User's original message
            agent_response: Agent's previous response (optional)

        Returns:
            None (allow execution) or dict with:
                - "block": bool (if True, block tool execution)
                - "message": str (reason for blocking)
                - "analyze_now": bool (trigger immediate analysis)
        """
        pass

    @abstractmethod
    def post_tool_use(
        self,
        tool_name: str,
        result: Dict[str, Any],
        user_message: str,
        agent_response: str
    ) -> Optional[Dict[str, Any]]:
        """
        Called after tool execution.

        Args:
            tool_name: Name of tool that was executed
            result: Tool execution result (dict)
            user_message: User's original message
            agent_response: Agent's response

        Returns:
            Dict with:
                - "analyze": bool (should analyze conversation)
                - "context": Dict (additional context for analysis)
        """
        pass

    @abstractmethod
    def session_start(self) -> Optional[Dict[str, Any]]:
        """
        Called when session starts.

        Returns:
            Dict with initialization config
        """
        pass

    @abstractmethod
    def session_end(self) -> Optional[Dict[str, Any]]:
        """
        Called when session ends.

        Returns:
            Dict with final actions (batch analysis, cleanup, etc.)
        """
        pass

    @abstractmethod
    def user_prompt_submit(
        self,
        prompt: str
    ) -> Optional[Dict[str, Any]]:
        """
        Called when user submits prompt.

        Args:
            prompt: User's submitted prompt

        Returns:
            Dict with context injection or modifications
        """
        pass
