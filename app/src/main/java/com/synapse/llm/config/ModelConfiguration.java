package com.synapse.llm.config;

public class ModelConfiguration {
    private String apiBase;
    private String apiKey;
    private String model;

    public ModelConfiguration() {}

    public ModelConfiguration(String apiBase, String apiKey, String model) {
        this.apiBase = apiBase;
        this.apiKey = apiKey;
        this.model = model;
    }

    // Getters and setters
    public String getApiBase() { return apiBase; }
    public void setApiBase(String apiBase) { this.apiBase = apiBase; }
    public String getApiKey() { return apiKey; }
    public void setApiKey(String apiKey) { this.apiKey = apiKey; }
    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }
}
