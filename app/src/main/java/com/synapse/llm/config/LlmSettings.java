package com.synapse.llm.config;

public class LlmSettings {
    private String defaultModel = "claude-sonnet-4-6";
    private String selectionStrategy = "round-robin";
    private GeneralSettings generalSettings = new GeneralSettings();

    public LlmSettings() {}

    public String getDefaultModel() { return defaultModel; }
    public void setDefaultModel(String defaultModel) { this.defaultModel = defaultModel; }
    public String getSelectionStrategy() { return selectionStrategy; }
    public void setSelectionStrategy(String selectionStrategy) { this.selectionStrategy = selectionStrategy; }
    public GeneralSettings getGeneralSettings() { return generalSettings; }
    public void setGeneralSettings(GeneralSettings generalSettings) { this.generalSettings = generalSettings; }

    // Inner class for General settings
    public static class GeneralSettings {
        private Boolean disableCooldowns;

        public GeneralSettings() {}

        public Boolean getDisableCooldowns() { return disableCooldowns; }
        public void setDisableCooldowns(Boolean disableCooldowns) { this.disableCooldowns = disableCooldowns; }
    }
}
