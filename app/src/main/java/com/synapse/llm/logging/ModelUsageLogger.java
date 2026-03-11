package com.synapse.llm.logging;

import com.synapse.llm.routing.RoutingDecision;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;

/**
 * Manages SLF4J MDC (Mapped Diagnostic Context) for request-scoped provenance tracking.
 *
 * Sets MDC keys at request start:
 * - synapse.model: Selected model (QWEN_LOCAL or CLAUDE_API)
 * - synapse.routing.reason: Heuristic reason (e.g., "tool_use", "long_context")
 * - synapse.tokens.estimated: Estimated token count
 * - synapse.latency.ms: Request latency in milliseconds
 *
 * MDC values are included in logs and can be exported for observability.
 */
@Component
public class ModelUsageLogger {

    private static final Logger logger = LoggerFactory.getLogger(ModelUsageLogger.class);

    private static final String MDC_MODEL = "synapse.model";
    private static final String MDC_ROUTING_REASON = "synapse.routing.reason";
    private static final String MDC_TOKENS_ESTIMATED = "synapse.tokens.estimated";
    private static final String MDC_LATENCY_MS = "synapse.latency.ms";

    /**
     * Initialize MDC keys at the start of a request.
     *
     * @param decision The routing decision for this request
     */
    public void startRequest(RoutingDecision decision) {
        MDC.put(MDC_MODEL, decision.modelChoice().name());
        MDC.put(MDC_ROUTING_REASON, decision.reason());
        MDC.put(MDC_TOKENS_ESTIMATED, String.valueOf(decision.estimatedTokens()));
    }

    /**
     * Finalize request, record latency, and log the complete request metadata.
     *
     * @param startTimeMs Request start time in milliseconds (System.currentTimeMillis())
     */
    public void endRequest(long startTimeMs) {
        long latencyMs = System.currentTimeMillis() - startTimeMs;
        MDC.put(MDC_LATENCY_MS, String.valueOf(latencyMs));

        // Log the complete request with all MDC context
        String model = MDC.get(MDC_MODEL);
        String reason = MDC.get(MDC_ROUTING_REASON);
        String tokens = MDC.get(MDC_TOKENS_ESTIMATED);

        logger.info(
                "LLM request completed [model={}] [reason={}] [tokens={}] [latency={}ms]",
                model,
                reason,
                tokens,
                latencyMs
        );

        // Clear all MDC keys after request completion
        clearMdc();
    }

    /**
     * Clear all MDC keys. Should be called in a finally block to ensure cleanup.
     */
    public void clearMdc() {
        MDC.remove(MDC_MODEL);
        MDC.remove(MDC_ROUTING_REASON);
        MDC.remove(MDC_TOKENS_ESTIMATED);
        MDC.remove(MDC_LATENCY_MS);
    }
}
