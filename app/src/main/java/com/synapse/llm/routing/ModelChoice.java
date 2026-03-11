package com.synapse.llm.routing;

/**
 * Enum representing the available model choices for routing decisions.
 */
public enum ModelChoice {
    QWEN_LOCAL("Qwen3.5 35B Local"),
    CLAUDE_API("Claude 3.5 Sonnet API"),
    CLAUDE_HAIKU("Claude 3.5 Haiku API");

    private final String displayName;

    ModelChoice(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
