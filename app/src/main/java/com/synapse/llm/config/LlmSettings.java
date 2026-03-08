package com.synapse.llm.config;

public class LlmSettings {
    private String defaultModel = "claude-sonnet-4-6";
    private String selectionStrategy = "round-robin";

    public LlmSettings() {}

    public String getDefaultModel() { return defaultModel; }
    public void setDefaultModel(String defaultModel) { this.defaultModel = defaultModel; }
    public String getSelectionStrategy() { return selectionStrategy; }
    public void setSelectionStrategy(String selectionStrategy) { this.selectionStrategy = selectionStrategy; }
}
