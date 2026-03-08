package com.synapse.llm.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@ConfigurationProperties(prefix = "llm")
public class LlmConfigurationProperties {
    private Map<String, ModelConfiguration> models = Map.of();
    private LlmSettings settings = new LlmSettings();

    public Map<String, ModelConfiguration> getModels() { return models; }
    public void setModels(Map<String, ModelConfiguration> models) { this.models = models; }
    public LlmSettings getSettings() { return settings; }
    public void setSettings(LlmSettings settings) { this.settings = settings; }
}
