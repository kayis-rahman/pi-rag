package com.synapse.llm.metrics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.DistributionSummary;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Service;

import java.util.concurrent.ConcurrentHashMap;

/**
 * Service for recording custom metrics in the Synapse routing system.
 * Provides methods for tracking API calls, routing decisions, model usage, and response times.
 */
@Service
public class MetricsService {

    private final MeterRegistry meterRegistry;

    // Counters for different models
    private final ConcurrentHashMap<String, Counter> modelCallCounters = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Timer> modelResponseTimers = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, DistributionSummary> modelTokenSummaries = new ConcurrentHashMap<>();

    // Counters for routing decisions
    private final ConcurrentHashMap<String, Counter> routingDecisionCounters = new ConcurrentHashMap<>();

    // Counters for API endpoints
    private final ConcurrentHashMap<String, Counter> endpointCounters = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Timer> endpointTimers = new ConcurrentHashMap<>();

    // Circuit breaker metrics
    private final Counter circuitBreakerSuccessCounter;
    private final Counter circuitBreakerFailureCounter;
    private final Counter circuitBreakerOpenCounter;

    public MetricsService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;

        // Initialize circuit breaker counters
        this.circuitBreakerSuccessCounter = Counter.builder("synapse.circuit_breaker.calls")
            .description("Circuit breaker call results")
            .tag("result", "success")
            .register(meterRegistry);

        this.circuitBreakerFailureCounter = Counter.builder("synapse.circuit_breaker.calls")
            .description("Circuit breaker call results")
            .tag("result", "failure")
            .register(meterRegistry);

        this.circuitBreakerOpenCounter = Counter.builder("synapse.circuit_breaker.state")
            .description("Circuit breaker state changes")
            .tag("state", "open")
            .register(meterRegistry);
    }

    // ============================================================================
    // Model Usage Metrics
    // ============================================================================

    /**
     * Record a call to a specific LLM model.
     */
    public void recordModelCall(String model) {
        Counter counter = modelCallCounters.computeIfAbsent(model, m ->
            Counter.builder("synapse.model.calls")
                .description("Total calls to a specific LLM model")
                .tag("model", m)
                .register(meterRegistry)
        );
        counter.increment();
    }

    /**
     * Record response time for a model call.
     */
    public void recordModelResponseTime(String model, long durationMs) {
        Timer timer = modelResponseTimers.computeIfAbsent(model, m ->
            Timer.builder("synapse.model.response_time")
                .description("Response time for LLM model calls")
                .tag("model", m)
                .register(meterRegistry)
        );
        timer.record(durationMs, java.util.concurrent.TimeUnit.MILLISECONDS);
    }

    /**
     * Record token usage for a model call.
     */
    public void recordTokenUsage(String model, int inputTokens, int outputTokens) {
        DistributionSummary inputSummary = modelTokenSummaries.computeIfAbsent(model + "_input", m ->
            DistributionSummary.builder("synapse.model.tokens")
                .description("Input token usage for LLM model")
                .tag("model", model)
                .tag("type", "input")
                .register(meterRegistry)
        );
        inputSummary.record(inputTokens);

        DistributionSummary outputSummary = modelTokenSummaries.computeIfAbsent(model + "_output", m ->
            DistributionSummary.builder("synapse.model.tokens")
                .description("Output token usage for LLM model")
                .tag("model", model)
                .tag("type", "output")
                .register(meterRegistry)
        );
        outputSummary.record(outputTokens);
    }

    // ============================================================================
    // Routing Decision Metrics
    // ============================================================================

    /**
     * Record a routing decision.
     */
    public void recordRoutingDecision(String reason, String targetModel) {
        Counter counter = routingDecisionCounters.computeIfAbsent(reason, r ->
            Counter.builder("synapse.routing.decisions")
                .description("Routing decisions by reason")
                .tag("reason", r)
                .tag("target_model", targetModel)
                .register(meterRegistry)
        );
        counter.increment();
    }

    // ============================================================================
    // API Endpoint Metrics
    // ============================================================================

    /**
     * Record an API call to an endpoint.
     */
    public void recordApiCall(String endpoint, String method) {
        Counter counter = endpointCounters.computeIfAbsent(endpoint + "_" + method, e ->
            Counter.builder("synapse.api.calls")
                .description("API calls by endpoint")
                .tag("endpoint", e.substring(0, e.lastIndexOf('_')))
                .tag("method", e.substring(e.lastIndexOf('_') + 1))
                .register(meterRegistry)
        );
        counter.increment();
    }

    /**
     * Record API response time.
     */
    public void recordApiResponseTime(String endpoint, String method, long durationMs) {
        Timer timer = endpointTimers.computeIfAbsent(endpoint + "_" + method, e ->
            Timer.builder("synapse.api.response_time")
                .description("API response times by endpoint")
                .tag("endpoint", e.substring(0, e.lastIndexOf('_')))
                .tag("method", e.substring(e.lastIndexOf('_') + 1))
                .register(meterRegistry)
        );
        timer.record(durationMs, java.util.concurrent.TimeUnit.MILLISECONDS);
    }

    // ============================================================================
    // Circuit Breaker Metrics
    // ============================================================================

    /**
     * Record circuit breaker success.
     */
    public void recordCircuitBreakerSuccess() {
        circuitBreakerSuccessCounter.increment();
    }

    /**
     * Record circuit breaker failure.
     */
    public void recordCircuitBreakerFailure() {
        circuitBreakerFailureCounter.increment();
    }

    /**
     * Record circuit breaker state change to open.
     */
    public void recordCircuitBreakerOpen() {
        circuitBreakerOpenCounter.increment();
    }

    // ============================================================================
    // Helper Methods
    // ============================================================================

    /**
     * Get all registered meters for debugging/inspection.
     */
    public Iterable<io.micrometer.core.instrument.Meter> getAllMeters() {
        return meterRegistry.getMeters();
    }
}
