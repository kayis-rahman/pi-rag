package com.synapse.llm.routing;

import com.synapse.llm.config.LlmConfigurationProperties.RoutingConfig;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.UserMessage;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Routing strategy that tiers Claude models (Sonnet for planning, Haiku for editing, Qwen for simple tasks).
 *
 * Rules (first match wins):
 * 1. Planning keywords (design, architect, plan, analyze, strategy) → CLAUDE_API (Sonnet)
 * 2. Edit keywords (fix, edit, update, patch, rewrite, rename, change) → CLAUDE_HAIKU
 * 3. Default → CLAUDE_HAIKU
 *
 * Rate limit fallback: If a Claude call fails with HTTP 429, the request is rerouted to Qwen.
 */
public class TieredClaudeRoutingStrategy implements RoutingStrategy {
    private static final Logger logger = LoggerFactory.getLogger(TieredClaudeRoutingStrategy.class);

    // Planning task keywords that require advanced reasoning
    private static final List<String> PLANNING_KEYWORDS = List.of(
            "design", "architect", "plan", "analyze", "strategy", "architect", "think through",
            "conceptual", "architectural", "reasoning", "implement"
    );

    // Edit task keywords that are quick fixes and simple updates
    private static final List<String> EDIT_KEYWORDS = List.of(
            "fix", "edit", "update", "patch", "rewrite", "rename", "change", "simplify",
            "format", "correct", "revise", "adjust"
    );

    private final RoutingConfig config;

    public TieredClaudeRoutingStrategy(RoutingConfig config) {
        this.config = config;
    }

    @Override
    public RoutingDecision decide(List<ChatMessage> messages, boolean hasTools) {
        String contentLower = extractContent(messages).toLowerCase();
        int estimatedTokens = estimateTokens(contentLower);

        // Rule 1: Planning keywords → Claude Sonnet (advanced reasoning)
        if (containsKeyword(contentLower, PLANNING_KEYWORDS)) {
            return new RoutingDecision(
                    ModelChoice.CLAUDE_API,
                    "planning_task",
                    estimatedTokens
            );
        }

        // Rule 2: Edit keywords → Claude Haiku (quick, focused edits)
        if (containsKeyword(contentLower, EDIT_KEYWORDS)) {
            return new RoutingDecision(
                    ModelChoice.CLAUDE_HAIKU,
                    "edit_task",
                    estimatedTokens
            );
        }

        // Rule 3: Default → Claude Haiku (efficient for most tasks)
        return new RoutingDecision(
                ModelChoice.CLAUDE_HAIKU,
                "default_haiku",
                estimatedTokens
        );
    }

    /**
     * Extract text content from chat messages.
     * Uses the last user message as the primary content source.
     */
    private String extractContent(List<ChatMessage> messages) {
        if (messages == null || messages.isEmpty()) {
            return "";
        }

        // Find the last user message
        for (int i = messages.size() - 1; i >= 0; i--) {
            ChatMessage msg = messages.get(i);
            if (msg instanceof UserMessage userMsg) {
                return userMsg.singleText();
            }
        }

        return "";
    }

    /**
     * Check if content contains any keyword from the keyword list.
     */
    private boolean containsKeyword(String contentLower, List<String> keywords) {
        return keywords.stream()
                .anyMatch(keyword -> contentLower.contains(keyword.toLowerCase()));
    }

    /**
     * Estimate token count using simple heuristic: word count × 1.3
     */
    private int estimateTokens(String content) {
        int wordCount = content.split("\\s+").length;
        return Math.max(1, (int) (wordCount * 1.3));
    }
}
