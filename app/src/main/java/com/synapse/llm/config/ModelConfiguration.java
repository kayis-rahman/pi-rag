package com.synapse.llm.config;

import java.util.List;

public class ModelConfiguration {
    private String modelName;
    private LiteLLMParams litellmParams;
    private LiteLLMSettings litellmSettings;
    private List<ModelInstanceConfiguration> instances;

    public ModelConfiguration() {}

    public ModelConfiguration(String modelName, LiteLLMParams litellmParams) {
        this.modelName = modelName;
        this.litellmParams = litellmParams;
    }

    public ModelConfiguration(String apiBase, String apiKey, String model) {
        this.litellmParams = new LiteLLMParams(model, apiBase, apiKey);
    }

    // Getters and setters
    public String getModelName() { return modelName; }
    public void setModelName(String modelName) { this.modelName = modelName; }
    public LiteLLMParams getLitellmParams() { return litellmParams; }
    public void setLitellmParams(LiteLLMParams litellmParams) { this.litellmParams = litellmParams; }
    public LiteLLMSettings getLitellmSettings() { return litellmSettings; }
    public void setLitellmSettings(LiteLLMSettings litellmSettings) { this.litellmSettings = litellmSettings; }
    public List<ModelInstanceConfiguration> getInstances() { return instances; }
    public void setInstances(List<ModelInstanceConfiguration> instances) { this.instances = instances; }

    // Inner class for LiteLLM parameters
    public static class LiteLLMParams {
        private String model;
        private String apiBase;
        private String apiKey;
        private Boolean verify;

        public LiteLLMParams() {}

        public LiteLLMParams(String model, String apiBase, String apiKey) {
            this.model = model;
            this.apiBase = apiBase;
            this.apiKey = apiKey;
        }

        public String getModel() { return model; }
        public void setModel(String model) { this.model = model; }
        public String getApiBase() { return apiBase; }
        public void setApiBase(String apiBase) { this.apiBase = apiBase; }
        public String getApiKey() { return apiKey; }
        public void setApiKey(String apiKey) { this.apiKey = apiKey; }
        public Boolean getVerify() { return verify; }
        public void setVerify(Boolean verify) { this.verify = verify; }
    }

    // Inner class for LiteLLM settings
    public static class LiteLLMSettings {
        private Boolean dropParams;
        private Boolean setVerbose;

        public LiteLLMSettings() {}

        public Boolean getDropParams() { return dropParams; }
        public void setDropParams(Boolean dropParams) { this.dropParams = dropParams; }
        public Boolean getSetVerbose() { return setVerbose; }
        public void setSetVerbose(Boolean setVerbose) { this.setVerbose = setVerbose; }
    }
}
