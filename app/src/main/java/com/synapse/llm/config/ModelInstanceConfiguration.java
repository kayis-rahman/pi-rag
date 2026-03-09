package com.synapse.llm.config;

/**
 * Configuration for a single vLLM instance within a model configuration.
 * Supports multi-instance setup with primary/backup failover.
 */
public class ModelInstanceConfiguration {
    private String instanceId;
    private String apiBase;
    private String apiKey;
    private Boolean enabled = true;
    private Boolean isPrimary = false;

    public ModelInstanceConfiguration() {}

    public ModelInstanceConfiguration(String instanceId, String apiBase, String apiKey) {
        this.instanceId = instanceId;
        this.apiBase = apiBase;
        this.apiKey = apiKey;
    }

    // Getters and setters
    public String getInstanceId() { return instanceId; }
    public void setInstanceId(String instanceId) { this.instanceId = instanceId; }

    public String getApiBase() { return apiBase; }
    public void setApiBase(String apiBase) { this.apiBase = apiBase; }

    public String getApiKey() { return apiKey; }
    public void setApiKey(String apiKey) { this.apiKey = apiKey; }

    public Boolean getEnabled() { return enabled; }
    public void setEnabled(Boolean enabled) { this.enabled = enabled; }

    public Boolean getIsPrimary() { return isPrimary; }
    public void setIsPrimary(Boolean isPrimary) { this.isPrimary = isPrimary; }

    @Override
    public String toString() {
        return "ModelInstanceConfiguration{" +
                "instanceId='" + instanceId + '\'' +
                ", apiBase='" + apiBase + '\'' +
                ", apiKey='" + apiKey + '\'' +
                ", enabled=" + enabled +
                ", isPrimary=" + isPrimary +
                '}';
    }
}
