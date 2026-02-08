"""
RAG Adapters Package

Contains agent-specific hook adapters that implement UniversalHookInterface.

Adapters:
- claude_code_hook: Claude Code adapter (Python + bash hooks)
- bash_hook: Generic bash adapter (works with Aider, Goose, etc.)
- rest_hook: REST API adapter (for remote agents)
"""

from core.universal_hook import UniversalHookInterface

__all__ = ["UniversalHookInterface"]
