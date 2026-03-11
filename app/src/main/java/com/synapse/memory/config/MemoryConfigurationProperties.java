package com.synapse.memory.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@ConfigurationProperties(prefix = "memory")
public class MemoryConfigurationProperties {

    private Episodic episodic = new Episodic();
    private Semantic semantic = new Semantic();
    private Knowledge knowledge = new Knowledge();
    private Management management = new Management();

    // Getters and setters

    public Episodic getEpisodic() {
        return episodic;
    }

    public void setEpisodic(Episodic episodic) {
        this.episodic = episodic;
    }

    public Semantic getSemantic() {
        return semantic;
    }

    public void setSemantic(Semantic semantic) {
        this.semantic = semantic;
    }

    public Knowledge getKnowledge() {
        return knowledge;
    }

    public void setKnowledge(Knowledge knowledge) {
        this.knowledge = knowledge;
    }

    public Management getManagement() {
        return management;
    }

    public void setManagement(Management management) {
        this.management = management;
    }

    public static class Episodic {
        private String postgresqlUrl = "jdbc:postgresql://localhost:5432/synapse_memory";
        private String postgresqlUsername = "synapse_user";
        private String postgresqlPassword = "synapse_password";
        private Redis redis = new Redis();

        // Getters and setters

        public String getPgUrl() {
            return postgresqlUrl;
        }

        public void setPgUrl(String postgresqlUrl) {
            this.postgresqlUrl = postgresqlUrl;
        }

        public String getPgUsername() {
            return postgresqlUsername;
        }

        public void setPgUsername(String postgresqlUsername) {
            this.postgresqlUsername = postgresqlUsername;
        }

        public String getPgPassword() {
            return postgresqlPassword;
        }

        public void setPgPassword(String postgresqlPassword) {
            this.postgresqlPassword = postgresqlPassword;
        }

        public Redis getRedis() {
            return redis;
        }

        public void setRedis(Redis redis) {
            this.redis = redis;
        }

        public static class Redis {
            private String host = "localhost";
            private int port = 6379;
            private int ttl = 3600; // seconds
            private int maxMemory = 100000000; // 100MB

            // Getters and setters

            public String getHost() {
                return host;
            }

            public void setHost(String host) {
                this.host = host;
            }

            public int getPort() {
                return port;
            }

            public void setPort(int port) {
                this.port = port;
            }

            public int getTtl() {
                return ttl;
            }

            public void setTtl(int ttl) {
                this.ttl = ttl;
            }

            public int getMaxMemory() {
                return maxMemory;
            }

            public void setMaxMemory(int maxMemory) {
                this.maxMemory = maxMemory;
            }
        }
    }

    public static class Semantic {
        private String qdrantHost = "localhost";
        private int qdrantPort = 6334;
        private String qdrantApiKey = "";
        private String collectionName = "semantic_memory";

        // Getters and setters

        public String getQdrantHost() {
            return qdrantHost;
        }

        public void setQdrantHost(String qdrantHost) {
            this.qdrantHost = qdrantHost;
        }

        public int getQdrantPort() {
            return qdrantPort;
        }

        public void setQdrantPort(int qdrantPort) {
            this.qdrantPort = qdrantPort;
        }

        public String getQdrantApiKey() {
            return qdrantApiKey;
        }

        public void setQdrantApiKey(String qdrantApiKey) {
            this.qdrantApiKey = qdrantApiKey;
        }

        public String getCollectionName() {
            return collectionName;
        }

        public void setCollectionName(String collectionName) {
            this.collectionName = collectionName;
        }
    }

    public static class Knowledge {
        private String sqlitePath = "/var/lib/synapse/knowledge.db";
        private int maxMemory = 500000000; // 500MB

        // Getters and setters

        public String getSqlitePath() {
            return sqlitePath;
        }

        public void setSqlitePath(String sqlitePath) {
            this.sqlitePath = sqlitePath;
        }

        public int getMaxMemory() {
            return maxMemory;
        }

        public void setMaxMemory(int maxMemory) {
            this.maxMemory = maxMemory;
        }
    }

    public static class Management {
        private int maxRamPercentage = 70;
        private long cleanupInterval = 300000; // 5 minutes in milliseconds
        private boolean adaptiveMemoryManagement = true;
        private Map<String, Object> evictionPolicies = Map.of();

        // Getters and setters

        public int getMaxRamPercentage() {
            return maxRamPercentage;
        }

        public void setMaxRamPercentage(int maxRamPercentage) {
            this.maxRamPercentage = maxRamPercentage;
        }

        public long getCleanupInterval() {
            return cleanupInterval;
        }

        public void setCleanupInterval(long cleanupInterval) {
            this.cleanupInterval = cleanupInterval;
        }

        public boolean isAdaptiveMemoryManagement() {
            return adaptiveMemoryManagement;
        }

        public void setAdaptiveMemoryManagement(boolean adaptiveMemoryManagement) {
            this.adaptiveMemoryManagement = adaptiveMemoryManagement;
        }

        public Map<String, Object> getEvictionPolicies() {
            return evictionPolicies;
        }

        public void setEvictionPolicies(Map<String, Object> evictionPolicies) {
            this.evictionPolicies = evictionPolicies;
        }
    }
}