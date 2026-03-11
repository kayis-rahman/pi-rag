package com.synapse.llm.health;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import java.time.Duration;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.synapse.llm.config.LlmConfigurationProperties;

/**
 * Wraps Resilience4j CircuitBreaker to detect vLLM downtime and manage failover.
 *
 * Detects:
 * - Failure rate threshold exceeded (e.g., 50% of calls failing)
 * - Slow calls exceeding timeout (e.g., >5 seconds)
 *
 * States:
 * - CLOSED: Normal operation, requests proceed to Qwen
 * - OPEN: Circuit breaker tripped, requests immediately fail and fallback to Claude
 * - HALF_OPEN: Testing state, permitted number of calls allowed to probe if service recovered
 */
public class VllmCircuitBreaker {

    private static final Logger logger = LoggerFactory.getLogger(VllmCircuitBreaker.class);

    private final CircuitBreaker circuitBreaker;

    public VllmCircuitBreaker(LlmConfigurationProperties.CircuitBreakerConfig config) {
        CircuitBreakerConfig cbConfig = CircuitBreakerConfig.custom()
                .failureRateThreshold(config.getFailureRateThreshold())
                .slowCallRateThreshold(config.getFailureRateThreshold())
                .slowCallDurationThreshold(Duration.ofMillis(config.getSlowCallDurationThresholdMs()))
                .waitDurationInOpenState(Duration.ofMillis(config.getWaitDurationInOpenStateMs()))
                .permittedNumberOfCallsInHalfOpenState(config.getPermittedCallsInHalfOpen())
                .minimumNumberOfCalls(config.getMinCallsBeforeEvaluation())
                .recordExceptions(Exception.class)
                .build();

        CircuitBreakerRegistry registry = CircuitBreakerRegistry.of(cbConfig);
        this.circuitBreaker = registry.circuitBreaker("vllm-circuit-breaker", cbConfig);
    }

    /**
     * Execute primary supplier with fallback (generic version).
     * If primary fails, circuit breaker records the failure.
     * If circuit opens, subsequent calls immediately execute fallback.
     *
     * @param primary The primary callable (e.g., Qwen)
     * @param fallback The fallback callable (e.g., Claude)
     * @param <T> The return type
     * @return Result from either primary (if successful) or fallback
     */
    public <T> T executeWithFallback(
            Supplier<T> primary,
            Supplier<T> fallback
    ) {
        try {
            return circuitBreaker.executeSupplier(primary);
        } catch (Exception e) {
            logger.warn("Circuit breaker executed fallback due to: {}", e.getMessage());
            return fallback.get();
        }
    }


    /**
     * Get current circuit breaker state (CLOSED, OPEN, HALF_OPEN).
     */
    public CircuitBreaker.State getState() {
        return circuitBreaker.getState();
    }

    /**
     * Get the underlying Resilience4j CircuitBreaker for direct access.
     */
    public CircuitBreaker getUnderlyingCircuitBreaker() {
        return circuitBreaker;
    }
}
