package com.synapse.llm.config;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.NestedConfigurationProperty;

/**
 * Spring Boot configuration properties for LLM routing, model configuration, and circuit breaker.
 * Binds to {@code synapse.llm.*} prefix in application.yml.
 */
@ConfigurationProperties(prefix = "synapse.llm")
public class LlmConfigurationProperties {

    @NestedConfigurationProperty
    private QwenConfig qwen = new QwenConfig();

    @NestedConfigurationProperty
    private ClaudeConfig claude = new ClaudeConfig();

    @NestedConfigurationProperty
    private RoutingConfig routing = new RoutingConfig();

    @NestedConfigurationProperty
    private CircuitBreakerConfig circuitBreaker = new CircuitBreakerConfig();

    // Getters
    public QwenConfig getQwen() {
        return qwen;
    }

    public void setQwen(QwenConfig qwen) {
        this.qwen = qwen;
    }

    public ClaudeConfig getClaude() {
        return claude;
    }

    public void setClaude(ClaudeConfig claude) {
        this.claude = claude;
    }

    public RoutingConfig getRouting() {
        return routing;
    }

    public void setRouting(RoutingConfig routing) {
        this.routing = routing;
    }

    public CircuitBreakerConfig getCircuitBreaker() {
        return circuitBreaker;
    }

    public void setCircuitBreaker(CircuitBreakerConfig circuitBreaker) {
        this.circuitBreaker = circuitBreaker;
    }

    /**
     * Qwen model configuration for local vLLM instance.
     */
    public static class QwenConfig {
        private String baseUrl = "http://localhost:8000/v1";
        private String modelName = "Qwen/Qwen3.5-35B-Instruct";
        private String apiKey = "not-needed";
        private long timeoutSeconds = 60;

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }

        public String getModelName() {
            return modelName;
        }

        public void setModelName(String modelName) {
            this.modelName = modelName;
        }

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public long getTimeoutSeconds() {
            return timeoutSeconds;
        }

        public void setTimeoutSeconds(long timeoutSeconds) {
            this.timeoutSeconds = timeoutSeconds;
        }
    }

    /**
     * Claude model configuration for Anthropic API.
     */
    public static class ClaudeConfig {
        private String apiKey;
        private String modelName = "claude-3-5-sonnet-20241022";
        private long timeoutSeconds = 120;

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public String getModelName() {
            return modelName;
        }

        public void setModelName(String modelName) {
            this.modelName = modelName;
        }

        public long getTimeoutSeconds() {
            return timeoutSeconds;
        }

        public void setTimeoutSeconds(long timeoutSeconds) {
            this.timeoutSeconds = timeoutSeconds;
        }
    }

    /**
     * Routing strategy configuration with heuristic thresholds and keyword lists.
     */
    public static class RoutingConfig {
        private int maxLocalTokens = 4096;
        private int shortQueryThreshold = 20;
        private List<String> codeKeywords = List.of(
                "class", "def", "public", "function", "interface", "return", "import", "async", "await"
        );
        private List<String> complexKeywords = List.of(
                "implement", "refactor", "debug", "architect", "design", "analyze", "migrate", "optimize", "review", "build"
        );
        private List<String> simpleKeywords = List.of(
                "what is", "define", "list the", "explain", "summarize", "how many", "is this", "yes or no"
        );

        public int getMaxLocalTokens() {
            return maxLocalTokens;
        }

        public void setMaxLocalTokens(int maxLocalTokens) {
            this.maxLocalTokens = maxLocalTokens;
        }

        public int getShortQueryThreshold() {
            return shortQueryThreshold;
        }

        public void setShortQueryThreshold(int shortQueryThreshold) {
            this.shortQueryThreshold = shortQueryThreshold;
        }

        public List<String> getCodeKeywords() {
            return codeKeywords;
        }

        public void setCodeKeywords(List<String> codeKeywords) {
            this.codeKeywords = codeKeywords;
        }

        public List<String> getComplexKeywords() {
            return complexKeywords;
        }

        public void setComplexKeywords(List<String> complexKeywords) {
            this.complexKeywords = complexKeywords;
        }

        public List<String> getSimpleKeywords() {
            return simpleKeywords;
        }

        public void setSimpleKeywords(List<String> simpleKeywords) {
            this.simpleKeywords = simpleKeywords;
        }
    }

    /**
     * Resilience4j circuit breaker configuration for vLLM health detection.
     */
    public static class CircuitBreakerConfig {
        private boolean enabled = true;
        private int failureRateThreshold = 50;
        private int slowCallDurationThresholdMs = 5000;
        private int waitDurationInOpenStateMs = 30000;
        private int permittedCallsInHalfOpen = 3;
        private int minCallsBeforeEvaluation = 5;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public int getFailureRateThreshold() {
            return failureRateThreshold;
        }

        public void setFailureRateThreshold(int failureRateThreshold) {
            this.failureRateThreshold = failureRateThreshold;
        }

        public int getSlowCallDurationThresholdMs() {
            return slowCallDurationThresholdMs;
        }

        public void setSlowCallDurationThresholdMs(int slowCallDurationThresholdMs) {
            this.slowCallDurationThresholdMs = slowCallDurationThresholdMs;
        }

        public int getWaitDurationInOpenStateMs() {
            return waitDurationInOpenStateMs;
        }

        public void setWaitDurationInOpenStateMs(int waitDurationInOpenStateMs) {
            this.waitDurationInOpenStateMs = waitDurationInOpenStateMs;
        }

        public int getPermittedCallsInHalfOpen() {
            return permittedCallsInHalfOpen;
        }

        public void setPermittedCallsInHalfOpen(int permittedCallsInHalfOpen) {
            this.permittedCallsInHalfOpen = permittedCallsInHalfOpen;
        }

        public int getMinCallsBeforeEvaluation() {
            return minCallsBeforeEvaluation;
        }

        public void setMinCallsBeforeEvaluation(int minCallsBeforeEvaluation) {
            this.minCallsBeforeEvaluation = minCallsBeforeEvaluation;
        }
    }
}
