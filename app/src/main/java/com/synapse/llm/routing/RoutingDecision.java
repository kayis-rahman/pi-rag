package com.synapse.llm.routing;

/**
 * Immutable record representing the result of a routing decision.
 *
 * @param modelChoice The selected model (QWEN_LOCAL or CLAUDE_API)
 * @param reason The heuristic reason for this decision (e.g., "tool_use", "long_context", "default")
 * @param estimatedTokens Estimated token count of the request
 */
public record RoutingDecision(
        ModelChoice modelChoice,
        String reason,
        int estimatedTokens
) {}
