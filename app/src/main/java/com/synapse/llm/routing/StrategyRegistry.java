package com.synapse.llm.routing;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Thread-safe registry for managing routing strategies at runtime.
 * Allows hot-swapping between different routing strategies without restarting the application.
 *
 * Example usage:
 * <pre>
 *   strategyRegistry.switchTo("tiered-claude");
 *   RoutingStrategy active = strategyRegistry.getActive();
 * </pre>
 */
public class StrategyRegistry {
    private static final Logger logger = LoggerFactory.getLogger(StrategyRegistry.class);

    private final Map<String, RoutingStrategy> strategies;
    private final AtomicReference<String> activeName;

    /**
     * Create a new strategy registry with available strategies.
     *
     * @param strategies Map of strategy name to implementation (e.g., "adaptive" -> AdaptiveRoutingStrategy)
     * @param defaultName Initial active strategy name
     * @throws IllegalArgumentException if defaultName is not found in strategies
     */
    public StrategyRegistry(Map<String, RoutingStrategy> strategies, String defaultName) {
        if (!strategies.containsKey(defaultName)) {
            throw new IllegalArgumentException(
                    "Default strategy '" + defaultName + "' not found in available strategies"
            );
        }
        this.strategies = strategies;
        this.activeName = new AtomicReference<>(defaultName);
        logger.info("StrategyRegistry initialized with default strategy: {}", defaultName);
        logger.info("Available strategies: {}", strategies.keySet());
    }

    /**
     * Get the currently active routing strategy.
     *
     * @return the active RoutingStrategy instance
     */
    public RoutingStrategy getActive() {
        String name = activeName.get();
        return strategies.get(name);
    }

    /**
     * Get the name of the currently active strategy.
     *
     * @return active strategy name
     */
    public String getActiveName() {
        return activeName.get();
    }

    /**
     * Get all available strategy names.
     *
     * @return set of strategy names
     */
    public Set<String> getAvailableNames() {
        return strategies.keySet();
    }

    /**
     * Switch to a different routing strategy at runtime.
     *
     * @param name the name of the strategy to switch to
     * @throws IllegalArgumentException if the strategy name is not found
     */
    public void switchTo(String name) {
        if (!strategies.containsKey(name)) {
            throw new IllegalArgumentException(
                    "Strategy '" + name + "' not found. Available: " + strategies.keySet()
            );
        }
        String previous = activeName.getAndSet(name);
        logger.info("Routing strategy switched from '{}' to '{}'", previous, name);
    }
}
