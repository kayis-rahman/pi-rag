package com.synapse.memory.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class MemoryConfigurationService {

    @Autowired
    private MemoryConfigurationProperties memoryConfig;

    public MemoryConfigurationProperties getConfiguration() {
        return memoryConfig;
    }

    public void updateConfiguration(MemoryConfigurationProperties newConfig) {
        // In a real implementation, this would update the configuration
        // and notify listeners of the change
        this.memoryConfig = newConfig;
    }

    public String getEpisodicPostgresqlUrl() {
        return memoryConfig.getEpisodic().getPgUrl();
    }

    public String getEpisodicPostgresqlUsername() {
        return memoryConfig.getEpisodic().getPgUsername();
    }

    public String getEpisodicPostgresqlPassword() {
        return memoryConfig.getEpisodic().getPgPassword();
    }

    public String getEpisodicRedisHost() {
        return memoryConfig.getEpisodic().getRedis().getHost();
    }

    public int getEpisodicRedisPort() {
        return memoryConfig.getEpisodic().getRedis().getPort();
    }

    public int getEpisodicRedisTtl() {
        return memoryConfig.getEpisodic().getRedis().getTtl();
    }

    public String getSemanticQdrantHost() {
        return memoryConfig.getSemantic().getQdrantHost();
    }

    public int getSemanticQdrantPort() {
        return memoryConfig.getSemantic().getQdrantPort();
    }

    public String getSemanticQdrantApiKey() {
        return memoryConfig.getSemantic().getQdrantApiKey();
    }

    public String getSemanticCollectionName() {
        return memoryConfig.getSemantic().getCollectionName();
    }

    public String getKnowledgeSqlitePath() {
        return memoryConfig.getKnowledge().getSqlitePath();
    }

    public int getManagementMaxRamPercentage() {
        return memoryConfig.getManagement().getMaxRamPercentage();
    }

    public long getManagementCleanupInterval() {
        return memoryConfig.getManagement().getCleanupInterval();
    }

    public boolean isAdaptiveMemoryManagementEnabled() {
        return memoryConfig.getManagement().isAdaptiveMemoryManagement();
    }

    public Map<String, Object> getEvictionPolicies() {
        return memoryConfig.getManagement().getEvictionPolicies();
    }
}