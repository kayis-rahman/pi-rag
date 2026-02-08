# Plan: Universal Multi-Agent Hook-Based Auto-Learning System

**Feature ID**: 004-universal-hook-auto-learning
**Version**: 1.0
**Status**: In Progress
**Created**: January 4, 2026

---

## Architecture Overview

The universal hook-based auto-learning system consists of four main components:

1. **Hook Interface Layer** - Standard interface for all agent adapters
2. **Conversation Analyzer** - Extracts facts and episodes using heuristics
3. **Agent Adapters** - Agent-specific implementations (OpenCode, Claude Code, etc.)
4. **RAG MCP Server** - Provides `core.analyze_conversation` tool for storage

**Data Flow**:
```
Agent Conversation → Hook (tool.execute.before) → RAG Tool (rag.analyze_conversation)
                                                      ↓
                                            Conversation Analyzer
                                                      ↓
                                       Heuristics (Regex Patterns)
                                                      ↓
                                    Facts (Symbolic) + Episodes (Episodic)
                                                      ↓
                                        RAG Memory Storage
```

---

## Design Principles

### 1. Language-Agnostic
- Hooks defined in Python (ABC) and TypeScript (interface)
- Agents use native language (Python, TypeScript, Bash)
- No language lock-in

### 2. Graceful Degradation
- System works even if RAG server is offline
- Errors logged but never crash agents
- Fallback to heuristics if LLM unavailable

### 3. Async-Ready
- All hooks execute asynchronously (non-blocking)
- Parallel storage of facts and episodes
- No blocking operations on agent thread

### 4. Zero Agent Lock-In
- Hooks only - no agent code modification
- Plugins are optional and removable
- Agents work without plugin

### 5. Configurable
- All behavior tunable via `rag_config.json`
- Per-adapter configuration
- Extraction mode: heuristic (no LLM)

---

## Component Designs

### 1. Hook Interface Layer

#### Python Interface (`core/universal_hook.py`)

```python
from typing import Dict, Any, Optional
from abc import ABC, abstractmethod

class UniversalHookInterface(ABC):
    """Standard interface for hook-based auto-learning."""

    @abstractmethod
    def pre_tool_use(
        self,
        tool_name: str,
        arguments: Dict[str, Any],
        user_message: str,
        agent_response: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Called before tool execution."""
        pass

    @abstractmethod
    def post_tool_use(
        self,
        tool_name: str,
        result: Dict[str, Any],
        user_message: str,
        agent_response: str
    ) -> Optional[Dict[str, Any]]:
        """Called after tool execution."""
        pass

    @abstractmethod
    def session_start(self) -> Optional[Dict[str, Any]]:
        """Called when session starts."""
        pass

    @abstractmethod
    def session_end(self) -> Optional[Dict[str, Any]]:
        """Called when session ends."""
        pass

    @abstractmethod
    def user_prompt_submit(
        self,
        prompt: str
    ) -> Optional[Dict[str, Any]]:
        """Called when user submits prompt."""
        pass
```

#### TypeScript Interface (`interfaces/hook-interface.ts`)

```typescript
export interface UniversalHookInterface {
  preToolUse?(params: {
    toolName: string;
    arguments: any;
    userMessage: string;
    agentResponse?: string;
  }): Promise<{
    block?: boolean;
    message?: string;
    analyzeNow?: boolean;
  } | undefined>;

  postToolUse?(params: {
    toolName: string;
    result: any;
    userMessage: string;
    agentResponse: string;
  }): Promise<{
    analyze?: boolean;
    context?: any;
  }>;

  sessionStart?(): Promise<any>;
  sessionEnd?(): Promise<any>;
  userPromptSubmit?(prompt: string): Promise<any>;
}
```

---

### 2. Conversation Analyzer

#### Class Definition (`core/conversation_analyzer.py`)

```python
class ConversationAnalyzer:
    """Analyze conversations for automatic learning."""

    def __init__(self, model_manager, config):
        """Initialize with config (no LLM required for heuristics)."""
        self.config = config
        self.extraction_mode = config.get("extraction_mode", "heuristic")
        self.use_llm = config.get("use_llm", False)
        self.min_fact_confidence = config.get("min_fact_confidence", 0.7)
        self.min_episode_confidence = config.get("min_episode_confidence", 0.6)
        self.deduplication_mode = config.get("deduplication_mode", "per_day")
        self.window_days = config.get("deduplication_window_days", 7)
        self.recent_facts = {}
        self.recent_episodes = {}

    async def analyze_conversation_async(
        self,
        user_message: str,
        agent_response: str,
        context: Optional[Dict] = None
    ) -> List[Dict]:
        """Async analysis: heuristics only, no LLM."""
        learnings = []

        # Fast: heuristics (sync, <10ms)
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
```

#### Heuristic Patterns

**Facts** (Regex patterns):
```python
patterns = {
    "api_endpoint": r"API (?:endpoint|url|address) is (https?://[^\s]+)",
    "version": r"(?:version|ver) is ([\d.]+)",
    "preference": r"prefer (\w+) over (\w+)",
    "decision": r"(?:decided|agreed|confirmed) to use (\w+)",
    "constraint": r"(?:must|cannot|should not) (?:use|support) (\w+)"
}
```

**Episodes** (Regex patterns):
```python
patterns = {
    "workaround": r"(?:i found|there's a) workaround",
    "mistake": r"(?:this|that) (?:didn't work|was a mistake|failed)",
    "lesson": r"the (?:lesson is|i learned)",
    "recommendation": r"(?:i recommend|you should)",
    "success": r"(?:successfully|successfuly) (?:completed|finished)"
}
```

---

### 3. OpenCode Plugin

#### Plugin File (`.opencode/plugins/synapse-auto-learning.ts`)

```typescript
import type { PluginInput, Hooks } from "@opencode-ai/plugin";

interface SynapseConfig {
  enabled: boolean;
  priority: number;
  analyze_after_tools: string[];
  min_message_length: number;
  skip_patterns: string[];
  rag_project_id: string;
  async_processing: boolean;
  extraction_mode: string;
}

const SynapseAutoLearningPlugin = async (ctx: PluginInput): Promise<Hooks> => {
  const config: SynapseConfig = {
    enabled: true,
    priority: 1,
    analyze_after_tools: ["rag.add_fact", "rag.add_episode", "rag.search"],
    min_message_length: 10,
    skip_patterns: ["^test$", "^hello$"],
    rag_project_id: "synapse",
    async_processing: true,
    extraction_mode: "heuristic"
  };

  return {
    "tool.execute.before": async (input, output) => {
      if (!config.enabled) return;
      if (!config.analyze_after_tools.includes(input.tool)) return;

      try {
        const result = await ctx.client.tools.call("rag.analyze_conversation", {
          project_id: config.rag_project_id,
          user_message: input.sessionID,
          agent_response: "",
          context: { tool_name: input.tool },
          auto_store: true
        });
        console.log(`[Synapse] Analyzed: ${result.facts_stored} facts, ${result.episodes_stored} episodes`);
      } catch (error) {
        console.error(`[Synapse] Error: ${error}`);
      }
    },

    "tool.execute.after": async (input, output) => {
      // Track tool execution for logging
    }
  };
};

export default SynapseAutoLearningPlugin;
```

---

### 4. RAG MCP Server Integration

#### New Tool: `core.analyze_conversation`

```python
Tool(
    name="rag.analyze_conversation",
    description="Analyze conversation and extract facts/episodes (heuristic mode)",
    inputSchema={
        "type": "object",
        "required": ["project_id", "user_message"],
        "properties": {
            "project_id": {"type": "string"},
            "user_message": {"type": "string"},
            "agent_response": {"type": "string"},
            "context": {"type": "object"},
            "auto_store": {"type": "boolean", "default": true},
            "return_only": {"type": "boolean", "default": false},
            "extraction_mode": {"type": "string", "enum": ["heuristic", "llm", "hybrid"]}
        }
    }
)
```

#### Handler Implementation

```python
async def handle_analyze_conversation(
    project_id: str,
    user_message: str,
    agent_response: str = "",
    context: Optional[Dict] = None,
    auto_store: bool = True,
    return_only: bool = False,
    extraction_mode: str = "heuristic"
) -> Dict:
    """Analyze conversation and store facts/episodes."""

    # Load config
    config = load_universal_hooks_config()
    analyzer_config = config["conversation_analyzer"]
    analyzer_config["extraction_mode"] = extraction_mode or analyzer_config["extraction_mode"]

    # Initialize analyzer
    analyzer = ConversationAnalyzer(model_manager=None, config=analyzer_config)

    # Analyze conversation
    learnings = await analyzer.analyze_conversation_async(user_message, agent_response, context)

    # Separate facts and episodes
    facts = [l for l in learnings if l["type"] == "fact"]
    episodes = [l for l in learnings if l["type"] == "episode"]

    # Filter by confidence
    facts = [f for f in facts if f["confidence"] >= analyzer_config["min_fact_confidence"]]
    episodes = [e for e in episodes if e["confidence"] >= analyzer_config["min_episode_confidence"]]

    if return_only:
        return {"facts": facts, "episodes": episodes}

    if auto_store:
        # Parallel storage
        storage_tasks = []

        for fact in facts:
            storage_tasks.append(backend.add_fact(
                project_id=project_id,
                fact_key=fact["key"],
                fact_value=fact["value"],
                confidence=fact["confidence"],
                category="user"
            ))

        for episode in episodes:
            storage_tasks.append(backend.add_episode(
                project_id=project_id,
                title=episode["title"],
                content=episode["content"],
                lesson_type=episode["lesson_type"],
                quality=episode["confidence"]
            ))

        await asyncio.gather(*storage_tasks)

    return {
        "facts_stored": len(facts),
        "episodes_stored": len(episodes),
        "facts": facts,
        "episodes": episodes
    }
```

---

## Configuration Schema

### `rag_config.json` - universal_hooks Section

```json
{
  "universal_hooks": {
    "enabled": true,
    "default_project_id": "synapse",

    "adapters": {
      "opencode": {
        "enabled": true,
        "priority": 1,
        "analyze_after_tools": ["rag.add_fact", "rag.add_episode"],
        "min_message_length": 10,
        "skip_patterns": ["^test$", "^hello$"],
        "async_processing": true,
        "extraction_mode": "heuristic"
      }
    },

    "conversation_analyzer": {
      "extraction_mode": "heuristic",
      "use_llm": false,
      "min_fact_confidence": 0.7,
      "min_episode_confidence": 0.6,
      "deduplicate_facts": true,
      "deduplicate_episodes": true,
      "deduplication_mode": "per_day",
      "deduplication_window_days": 7
    },

    "performance": {
      "async_processing": true,
      "analyze_every_n_messages": 1,
      "timeout_ms": 5000
    }
  }
}
```

---

## Standard Hook Interface

### Method Contracts

#### `pre_tool_use(tool_name, arguments, user_message, agent_response)`
- **Purpose**: Intercept tool execution before it happens
- **Returns**: `None` (allow) or `{"block": True, "message": "reason"}` (block)
- **Use Case**: OpenCode plugin triggers analysis here

#### `post_tool_use(tool_name, result, user_message, agent_response)`
- **Purpose**: Track tool execution results
- **Returns**: `{"analyze": True/False, "context": {...}}`
- **Use Case**: Log tool execution for debugging

#### `session_start()`
- **Purpose**: Initialize session state (buffers, counters)
- **Returns**: Initialization config
- **Use Case**: Clear conversation buffer, reset token budget

#### `session_end()`
- **Purpose**: Cleanup and final actions
- **Returns**: Final actions (batch analysis, stats)
- **Use Case**: Analyze buffered conversations

#### `user_prompt_submit(prompt)`
- **Purpose**: Intercept user input before agent processing
- **Returns**: Context injection or modifications
- **Use Case**: Inject context from memory

---

## Error Handling

### Graceful Degradation Strategy

1. **RAG Server Offline**
   - Log error: `"[Synapse] RAG server unavailable, skipping analysis"`
   - Continue without learning
   - Agent works normally

2. **Invalid Configuration**
   - Use sensible defaults
   - Log warning
   - System continues

3. **Extraction Failure**
   - Return empty results
   - Log error details
   - Don't crash agent

4. **Storage Failure**
   - Log error with details
   - Return partial results
   - Continue operation

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Regex patterns miss learnings | High | Medium | Monitor precision, add patterns iteratively |
| Heuristic extraction slow | Low | Medium | Benchmark, optimize regex, add caching |
| Deduplication too aggressive | Medium | Medium | Make configurable, allow tuning |
| OpenCode SDK changes | Medium | High | Version-lock, follow examples closely |
| RAG server downtime | Low | High | Graceful degradation, cache locally |

---

## Implementation Phases

### Phase 1: Foundation (Complete)
- ✅ Hook interfaces (Python + TypeScript)
- ✅ Conversation analyzer with heuristics
- ✅ Configuration schema
- ✅ Requirements and plan documentation

### Phase 2: MCP Server Integration
- Add `core.analyze_conversation` tool
- Implement handler with ConversationAnalyzer
- Load config from rag_config.json
- Add to tool routing

### Phase 3: OpenCode Adapter
- Create TypeScript plugin file
- Implement `tool.execute.before` hook
- Implement `tool.execute.after` hook
- Add RAG tool integration
- Error handling and logging

### Phase 4: Testing
- Unit tests for ConversationAnalyzer
- Integration tests: Plugin → RAG → Storage
- Performance tests: <50ms hooks
- Acceptance tests with OpenCode

### Phase 5: Completion
- Update documentation
- Update tasks.md
- Verify OpenCode starts successfully
- Provide user testing instructions

---

**Status**: Ready for Phase 2 (MCP Server Integration)
