package com.synapse.llm.routing;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@ConfigurationProperties(prefix = "llm.routing")
public class RoutingConfig {
    private boolean enabled = true;
    private String smallModel;
    private String largeModel;
    private Map<String, ServerConfig> servers;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getSmallModel() {
        return smallModel;
    }

    public void setSmallModel(String smallModel) {
        this.smallModel = smallModel;
    }

    public String getLargeModel() {
        return largeModel;
    }

    public void setLargeModel(String largeModel) {
        this.largeModel = largeModel;
    }

    public Map<String, ServerConfig> getServers() {
        return servers;
    }

    public void setServers(Map<String, ServerConfig> servers) {
        this.servers = servers;
    }
}
