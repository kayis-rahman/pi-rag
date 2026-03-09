package com.synapse.llm.routing;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@ConfigurationProperties(prefix = "llm.routing")
public class RoutingConfigProperties {

    private boolean enabled = true;
    private Map<String, ServerConfig> servers = Map.of();
    private Map<String, String> modelTierMap = Map.of();
    private RulesConfig rules = new RulesConfig();

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public Map<String, ServerConfig> getServers() { return servers; }
    public void setServers(Map<String, ServerConfig> servers) { this.servers = servers; }

    public Map<String, String> getModelTierMap() { return modelTierMap; }
    public void setModelTierMap(Map<String, String> modelTierMap) { this.modelTierMap = modelTierMap; }

    public RulesConfig getRules() { return rules; }
    public void setRules(RulesConfig rules) { this.rules = rules; }

    public static class RulesConfig {
        private int maxSmallTokens = 500;
        private int maxSmallWords = 30;

        public int getMaxSmallTokens() { return maxSmallTokens; }
        public void setMaxSmallTokens(int maxSmallTokens) { this.maxSmallTokens = maxSmallTokens; }

        public int getMaxSmallWords() { return maxSmallWords; }
        public void setMaxSmallWords(int maxSmallWords) { this.maxSmallWords = maxSmallWords; }
    }
}
