package com.synapse.llm.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.chat.messages.Message;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Multi-instance ChatModel implementation that routes requests to multiple vLLM instances.
 * Implements health-based failover: primary instance with automatic failover to backup on failure.
 *
 * Features:
 * - Routes all requests to primary instance by default
 * - Automatic failover to backup instance on HTTP errors or timeouts
 * - Manual recovery: instances can be marked healthy after recovery
 * - Thread-safe instance state management
 */
public class MultiInstanceChatModel implements ChatModel {

    private static final Logger log = LoggerFactory.getLogger(MultiInstanceChatModel.class);
    private final List<OpenAICompatibleChatModel> instances;
    private final InstanceLoadBalancer loadBalancer;
    private final String modelName;
    private final Map<String, Long> instanceFailureCache = new ConcurrentHashMap<>();
    private final long failureCacheTtl = 30000L; // 30 seconds

    public MultiInstanceChatModel(List<OpenAICompatibleChatModel> instances, InstanceLoadBalancer loadBalancer, String modelName) {
        this.instances = instances;
        this.loadBalancer = loadBalancer;
        this.modelName = modelName;
    }

    @Override
    public String call(Message... messages) {
        log.info("Calling multi-instance model: {} with {} messages", modelName, messages.length);

        ModelInstance instance = loadBalancer.selectInstance();
        if (instance == null) {
            throw new RuntimeException("No healthy instances available for model: " + modelName);
        }

        try {
            return instance.getChatModel().call(messages);
        } catch (Exception e) {
            log.error("Failed to call instance {} for model {}: {}",
                instance.getInstanceId(), modelName, e.getMessage(), e);
            handleFailure(instance, e.getMessage());
            throw e;
        }
    }

    @Override
    public ChatResponse call(Prompt prompt) {
        log.info("Calling multi-instance model: {} with prompt", modelName);

        ModelInstance instance = loadBalancer.selectInstance();
        if (instance == null) {
            throw new RuntimeException("No healthy instances available for model: " + modelName);
        }

        try {
            return instance.getChatModel().call(prompt);
        } catch (Exception e) {
            log.error("Failed to call instance {} for model {}: {}",
                instance.getInstanceId(), modelName, e.getMessage(), e);
            handleFailure(instance, e.getMessage());
            throw e;
        }
    }

    @Override
    public ChatOptions getDefaultOptions() {
        return ChatModel.super.getDefaultOptions();
    }

    @Override
    public Flux<ChatResponse> stream(Prompt prompt) {
        log.info("Streaming multi-instance model: {}", modelName);

        ModelInstance instance = loadBalancer.selectInstance();
        if (instance == null) {
            throw new RuntimeException("No healthy instances available for model: " + modelName);
        }

        try {
            return instance.getChatModel().stream(prompt);
        } catch (Exception e) {
            log.error("Failed to stream from instance {} for model {}: {}",
                instance.getInstanceId(), modelName, e.getMessage(), e);
            handleFailure(instance, e.getMessage());
            throw e;
        }
    }

    @Override
    public Flux<String> stream(Message... messages) {
        log.info("Streaming multi-instance model: {} with {} messages", modelName, messages.length);

        ModelInstance instance = loadBalancer.selectInstance();
        if (instance == null) {
            throw new RuntimeException("No healthy instances available for model: " + modelName);
        }

        try {
            return instance.getChatModel().stream(messages);
        } catch (Exception e) {
            log.error("Failed to stream from instance {} for model {}: {}",
                instance.getInstanceId(), modelName, e.getMessage(), e);
            handleFailure(instance, e.getMessage());
            throw e;
        }
    }

    /**
     * Handles failure by marking instance as unhealthy and triggering failover.
     */
    private void handleFailure(ModelInstance instance, String failureReason) {
        // Check if this failure is recent (within TTL)
        String cacheKey = instance.getInstanceId();
        Long cachedFailure = instanceFailureCache.get(cacheKey);

        if (cachedFailure != null && System.currentTimeMillis() - cachedFailure < failureCacheTtl) {
            log.warn("Instance {} already marked as failed recently ({}ms ago), skipping failover",
                cacheKey, System.currentTimeMillis() - cachedFailure);
            return;
        }

        // Mark instance as unhealthy
        loadBalancer.markInstanceUnhealthy(instance, failureReason);

        // Cache the failure
        instanceFailureCache.put(cacheKey, System.currentTimeMillis());

        log.warn("Failed over from instance {} to model {}: {}",
            instance.getInstanceId(), modelName, failureReason);
    }

    /**
     * Marks an instance as healthy (manual recovery after successful request).
     */
    public void markInstanceHealthy(String instanceId) {
        ModelInstance instance = loadBalancer.getAllInstances().stream()
            .filter(i -> i.getInstanceId().equals(instanceId))
            .findFirst()
            .orElse(null);

        if (instance != null) {
            loadBalancer.markInstanceHealthy(instance);
            // Clear failure cache for this instance
            instanceFailureCache.remove(instanceId);
            log.info("Instance {} marked as healthy for model {}", instanceId, modelName);
        }
    }

    /**
     * Resets all instance failure cache (e.g., after successful batch of requests).
     */
    public void clearFailureCache() {
        instanceFailureCache.clear();
    }

    public List<OpenAICompatibleChatModel> getInstances() {
        return instances;
    }

    public String getModelName() {
        return modelName;
    }
}
