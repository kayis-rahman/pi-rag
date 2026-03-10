package com.synapse.llm.routing;

import dev.langchain4j.data.message.ChatMessage;
import java.util.List;

/**
 * Strategy interface for determining which LLM model should handle a given request.
 *
 * Implementations are responsible for analyzing request characteristics and producing
 * routing decisions based on configured heuristics.
 */
public interface RoutingStrategy {

    /**
     * Determine which model should handle this request.
     *
     * @param messages The conversation messages
     * @param hasTools Whether the request includes tool specifications (for function calling)
     * @return A RoutingDecision with the selected model, reason, and token estimate
     */
    RoutingDecision decide(List<ChatMessage> messages, boolean hasTools);
}
