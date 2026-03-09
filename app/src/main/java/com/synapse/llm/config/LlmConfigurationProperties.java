package com.synapse.llm.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
@Primary
@ConfigurationProperties(prefix = "llm")
public class LlmConfigurationProperties {
    private List<ModelConfiguration> modelList = List.of();
    private ModelConfiguration.LiteLLMSettings litellmSettings;
    private LlmSettings settings = new LlmSettings();
    private Map<String, ModelConfiguration> models = Map.of();

    public List<ModelConfiguration> getModelList() { return modelList; }
    public void setModelList(List<ModelConfiguration> modelList) { this.modelList = modelList; }
    public ModelConfiguration.LiteLLMSettings getLitellmSettings() { return litellmSettings; }
    public void setLitellmSettings(ModelConfiguration.LiteLLMSettings litellmSettings) { this.litellmSettings = litellmSettings; }
    public LlmSettings getSettings() { return settings; }
    public void setSettings(LlmSettings settings) { this.settings = settings; }
    public Map<String, ModelConfiguration> getModels() { return models; }
    public void setModels(Map<String, ModelConfiguration> models) { this.models = models; }

    /**
     * Convert model list to a map keyed by modelName for compatibility with existing code.
     */
    public java.util.Map<String, ModelConfiguration> toModelMap() {
        return modelList.stream()
            .collect(java.util.stream.Collectors.toMap(
                ModelConfiguration::getModelName,
                mc -> mc
            ));
    }
}
