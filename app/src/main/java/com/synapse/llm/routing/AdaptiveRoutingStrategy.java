package com.synapse.llm.routing;

import dev.langchain4j.data.message.ChatMessage;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.synapse.llm.config.LlmConfigurationProperties;

/**
 * Adaptive routing strategy that classifies requests based on heuristics.
 *
 * Rules evaluated in priority order:
 * 1. Tool use (function calling) → CLAUDE_API
 * 2. Token budget exceeded → CLAUDE_API
 * 3. Code detection → QWEN_LOCAL
 * 4. Complex reasoning keywords → CLAUDE_API
 * 5. Simple retrieval keywords → QWEN_LOCAL
 * 6. Short query (< 20 words) → QWEN_LOCAL
 * 7. Default → QWEN_LOCAL
 */
public class AdaptiveRoutingStrategy implements RoutingStrategy {

    private static final Logger logger = LoggerFactory.getLogger(AdaptiveRoutingStrategy.class);

    private final LlmConfigurationProperties.RoutingConfig config;

    public AdaptiveRoutingStrategy(LlmConfigurationProperties.RoutingConfig config) {
        this.config = config;
    }

    @Override
    public RoutingDecision decide(
            List<ChatMessage> messages,
            boolean hasTools
    ) {
        // Rule 1: Tool use (function calling) → CLAUDE_API
        if (hasTools) {
            int estimatedTokens = estimateTokens(messages);
            return new RoutingDecision(ModelChoice.CLAUDE_API, "tool_use", estimatedTokens);
        }

        // Extract the last user message as the primary query
        String query = extractLastUserMessage(messages);
        if (query == null || query.isBlank()) {
            query = "";
        }

        int estimatedTokens = estimateTokens(messages);
        int wordCount = countWords(query);
        String lowerQuery = query.toLowerCase();

        // Rule 2: Token budget exceeded → CLAUDE_API
        if (estimatedTokens > config.getMaxLocalTokens()) {
            return new RoutingDecision(ModelChoice.CLAUDE_API, "long_context", estimatedTokens);
        }

        // Rule 3: Code detection → QWEN_LOCAL
        if (hasCodeBlock(query) || hasCodeKeywords(lowerQuery)) {
            return new RoutingDecision(ModelChoice.QWEN_LOCAL, "code_task", estimatedTokens);
        }

        // Rule 4: Complex reasoning keywords → CLAUDE_API
        if (hasComplexKeywords(lowerQuery)) {
            return new RoutingDecision(ModelChoice.CLAUDE_API, "complex_task", estimatedTokens);
        }

        // Rule 5: Simple retrieval keywords → QWEN_LOCAL
        if (hasSimpleKeywords(lowerQuery)) {
            return new RoutingDecision(ModelChoice.QWEN_LOCAL, "simple_retrieval", estimatedTokens);
        }

        // Rule 6: Short query → QWEN_LOCAL
        if (wordCount < config.getShortQueryThreshold()) {
            return new RoutingDecision(ModelChoice.QWEN_LOCAL, "short_query", estimatedTokens);
        }

        // Rule 7: Default → QWEN_LOCAL
        return new RoutingDecision(ModelChoice.QWEN_LOCAL, "default", estimatedTokens);
    }

    /**
     * Estimate token count as wordCount × 1.3.
     */
    private int estimateTokens(List<ChatMessage> messages) {
        int totalWords = messages.stream()
                .mapToInt(msg -> countWords(msg.text()))
                .sum();
        return (int) (totalWords * 1.3);
    }

    /**
     * Count words in a string (split by whitespace).
     */
    private int countWords(String text) {
        if (text == null || text.isBlank()) {
            return 0;
        }
        return text.trim().split("\\s+").length;
    }

    /**
     * Extract the last user message from the conversation.
     */
    private String extractLastUserMessage(List<ChatMessage> messages) {
        if (messages == null || messages.isEmpty()) {
            return null;
        }
        // Iterate in reverse to find the last user message
        for (int i = messages.size() - 1; i >= 0; i--) {
            ChatMessage msg = messages.get(i);
            if (msg.type() != null && msg.type().toString().equalsIgnoreCase("user")) {
                return msg.text();
            }
        }
        return null;
    }

    /**
     * Detect code blocks (triple backticks).
     */
    private boolean hasCodeBlock(String text) {
        return text.contains("```");
    }

    /**
     * Check if query contains code keywords.
     */
    private boolean hasCodeKeywords(String lowerQuery) {
        Set<String> keywords = config.getCodeKeywords().stream()
                .map(String::toLowerCase)
                .collect(Collectors.toSet());
        return keywords.stream().anyMatch(lowerQuery::contains);
    }

    /**
     * Check if query contains complex reasoning keywords.
     */
    private boolean hasComplexKeywords(String lowerQuery) {
        Set<String> keywords = config.getComplexKeywords().stream()
                .map(String::toLowerCase)
                .collect(Collectors.toSet());
        return keywords.stream().anyMatch(lowerQuery::contains);
    }

    /**
     * Check if query contains simple retrieval keywords.
     */
    private boolean hasSimpleKeywords(String lowerQuery) {
        Set<String> keywords = config.getSimpleKeywords().stream()
                .map(String::toLowerCase)
                .collect(Collectors.toSet());
        return keywords.stream().anyMatch(lowerQuery::contains);
    }
}
