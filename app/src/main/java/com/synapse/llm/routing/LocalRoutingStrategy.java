package com.synapse.llm.routing;

import dev.langchain4j.data.message.ChatMessage;
import java.util.List;

/**
 * Local routing strategy that always sends requests to QWEN_LOCAL.
 * Use this when you want all traffic routed to the local/remote vLLM endpoint
 * without any heuristic-based switching to Claude API.
 */
public class LocalRoutingStrategy implements RoutingStrategy {

    @Override
    public RoutingDecision decide(List<ChatMessage> messages, boolean hasTools) {
        int estimatedTokens = messages.stream()
                .mapToInt(msg -> {
                    String text = msg.text();
                    if (text == null || text.isBlank()) return 0;
                    return (int) (text.trim().split("\\s+").length * 1.3);
                })
                .sum();

        return new RoutingDecision(ModelChoice.QWEN_LOCAL, "local_default", estimatedTokens);
    }
}
