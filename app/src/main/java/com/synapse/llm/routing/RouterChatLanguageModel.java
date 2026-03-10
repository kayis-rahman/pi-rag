package com.synapse.llm.routing;

import com.synapse.llm.health.VllmCircuitBreaker;
import com.synapse.llm.logging.ModelUsageLogger;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.data.message.ChatMessage;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Router implementation of ChatLanguageModel that intelligently routes requests
 * between Qwen (local) and Claude (API) based on adaptive heuristics.
 *
 * Flow:
 * 1. Call routing strategy to decide which model to use
 * 2. Set up MDC for provenance logging
 * 3. If QWEN_LOCAL: try with circuit breaker protection, fallback to Claude on failure
 * 4. If CLAUDE_API: use directly (bypass circuit breaker)
 * 5. Log request metadata (model, reason, latency)
 * 6. Return response
 *
 * Note: This is a decorator that wraps the ChatLanguageModel interface.
 * Implementations should delegate to the underlying model after routing logic.
 *
 * Created as a bean by LlmAutoConfiguration.
 */
public class RouterChatLanguageModel implements ChatLanguageModel {

    private static final Logger logger = LoggerFactory.getLogger(RouterChatLanguageModel.class);

    private final StrategyRegistry strategyRegistry;
    private final ChatLanguageModel qwenModel;
    private final ChatLanguageModel claudeModel;
    private final VllmCircuitBreaker circuitBreaker;
    private final ModelUsageLogger usageLogger;

    public RouterChatLanguageModel(
            StrategyRegistry strategyRegistry,
            ChatLanguageModel qwenModel,
            ChatLanguageModel claudeModel,
            VllmCircuitBreaker circuitBreaker,
            ModelUsageLogger usageLogger
    ) {
        this.strategyRegistry = strategyRegistry;
        this.qwenModel = qwenModel;
        this.claudeModel = claudeModel;
        this.circuitBreaker = circuitBreaker;
        this.usageLogger = usageLogger;
    }

    /**
     * Simple generate method that routes based on message content.
     * This is a basic implementation that can be extended.
     */
    @Override
    public dev.langchain4j.model.output.Response<dev.langchain4j.data.message.AiMessage> generate(List<ChatMessage> messages) {
        long startTime = System.currentTimeMillis();

        try {
            // Step 1: Decide which model to use (no tools in this simple version)
            RoutingDecision decision = strategyRegistry.getActive().decide(messages, false);
            logger.debug(
                    "Routing decision: model={}, reason={}, tokens={}",
                    decision.modelChoice(),
                    decision.reason(),
                    decision.estimatedTokens()
            );

            // Step 2: Set up MDC for logging
            usageLogger.startRequest(decision);

            // Step 3: Execute with appropriate model
            dev.langchain4j.model.output.Response<dev.langchain4j.data.message.AiMessage> response;

            if (decision.modelChoice() == ModelChoice.QWEN_LOCAL) {
                // Try Qwen with circuit breaker protection
                response = circuitBreaker.executeWithFallback(
                        () -> qwenModel.generate(messages),
                        () -> claudeModel.generate(messages)
                );
            } else {
                // Direct Claude execution (Sonnet or Haiku, bypass circuit breaker)
                // Note: In the current implementation, both CLAUDE_API and CLAUDE_HAIKU
                // use the same claudeModel bean. The difference in routing is semantic
                // (explaining the reason for the choice) and can be refined in future
                // to use separate bean instances if needed.
                response = claudeModel.generate(messages);
            }

            return response;

        } finally {
            // Step 4: Clean up and log
            usageLogger.endRequest(startTime);
        }
    }
}
