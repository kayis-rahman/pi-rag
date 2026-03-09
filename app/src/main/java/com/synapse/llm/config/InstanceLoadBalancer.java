package com.synapse.llm.config;

import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Load balancer for managing multiple vLLM instances.
 * Implements health-based failover: primary instance with automatic failover to backup.
 */
@Component
public class InstanceLoadBalancer {
    private final List<ModelInstance> instances;
    private ModelInstance currentInstance;

    public InstanceLoadBalancer(List<ModelInstance> instances) {
        this.instances = instances;
        this.currentInstance = null;
    }

    /**
     * Returns the primary instance if healthy, otherwise returns the next available instance.
     * Implements health-based failover without automatic health checks.
     */
    public ModelInstance getHealthyInstance() {
        if (currentInstance != null && currentInstance.isHealthy()) {
            return currentInstance;
        }

        // Find the primary instance
        ModelInstance primary = instances.stream()
                .findFirst()
                .orElse(null);

        // If primary is not healthy or not found, find any healthy instance
        if (primary == null || !primary.isHealthy()) {
            primary = instances.stream()
                    .filter(ModelInstance::isHealthy)
                    .findFirst()
                    .orElse(null);
        }

        if (primary != null) {
            currentInstance = primary;
            return primary;
        }

        return null;
    }

    /**
     * Selects the next available instance based on health state.
     * Updates the current instance state.
     */
    public ModelInstance selectInstance() {
        ModelInstance instance = getHealthyInstance();
        if (instance != null) {
            currentInstance = instance;
        }
        return instance;
    }

    /**
     * Marks an instance as unhealthy (failover triggered).
     */
    public void markInstanceUnhealthy(ModelInstance instance, String failureReason) {
        if (currentInstance == instance) {
            currentInstance = null;
        }
        instance.markUnhealthy(failureReason);
    }

    /**
     * Marks an instance as healthy (failover recovered).
     */
    public void markInstanceHealthy(ModelInstance instance) {
        instance.setHealthy(true);
        // Don't automatically switch back to primary - manual recovery required
    }

    /**
     * Resets the current instance selection (e.g., after successful request).
     */
    public void resetCurrentInstance() {
        currentInstance = null;
    }

    /**
     * Manually set a specific instance as current (for recovery scenarios).
     */
    public void setCurrentInstance(ModelInstance instance) {
        if (instance != null && instance.isHealthy()) {
            currentInstance = instance;
        }
    }

    public List<ModelInstance> getAllInstances() {
        return instances;
    }
}
