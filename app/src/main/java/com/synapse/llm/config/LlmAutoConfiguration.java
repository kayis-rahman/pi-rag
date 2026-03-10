package com.synapse.llm.config;

import com.synapse.llm.health.VllmCircuitBreaker;
import com.synapse.llm.logging.ModelUsageLogger;
import com.synapse.llm.routing.AdaptiveRoutingStrategy;
import com.synapse.llm.routing.RouterChatLanguageModel;
import com.synapse.llm.routing.RoutingStrategy;
import com.synapse.llm.routing.StrategyRegistry;
import com.synapse.llm.routing.TieredClaudeRoutingStrategy;
import java.util.Map;
import dev.langchain4j.model.anthropic.AnthropicChatModel;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.openai.OpenAiChatModel;
import java.time.Duration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * Spring Boot auto-configuration for LLM routing layer.
 *
 * Produces:
 * - OpenAiChatModel (Qwen via vLLM OpenAI-compatible API)
 * - AnthropicChatModel (Claude Sonnet)
 * - AnthropicChatModel (Claude Haiku)
 * - AdaptiveRoutingStrategy (heuristic-based routing)
 * - TieredClaudeRoutingStrategy (Sonnet/Haiku tiering)
 * - StrategyRegistry (runtime strategy switching)
 * - VllmCircuitBreaker (Resilience4j wrapper)
 * - ModelUsageLogger (MDC integration)
 * - RouterChatLanguageModel (@Primary ChatLanguageModel for injection)
 *
 * Configuration is bound from synapse.llm.* in application.yml
 */
@Configuration
@EnableConfigurationProperties(LlmConfigurationProperties.class)
public class LlmAutoConfiguration {

    /**
     * Create OpenAiChatModel for Qwen via vLLM.
     * vLLM exposes an OpenAI-compatible API, so we use OpenAiChatModel with custom baseUrl.
     */
    @Bean(name = "qwenChatModel")
    public ChatLanguageModel qwenChatModel(LlmConfigurationProperties props) {
        LlmConfigurationProperties.QwenConfig qwen = props.getQwen();
        return OpenAiChatModel.builder()
                .baseUrl(qwen.getBaseUrl())
                .modelName(qwen.getModelName())
                .apiKey(qwen.getApiKey())
                .timeout(Duration.ofSeconds(qwen.getTimeoutSeconds()))
                .build();
    }

    /**
     * Create AnthropicChatModel for Claude API (Sonnet).
     */
    @Bean(name = "claudeChatModel")
    public ChatLanguageModel claudeChatModel(LlmConfigurationProperties props) {
        LlmConfigurationProperties.ClaudeConfig claude = props.getClaude();
        return AnthropicChatModel.builder()
                .apiKey(claude.getApiKey())
                .modelName(claude.getModelName())
                .timeout(Duration.ofSeconds(claude.getTimeoutSeconds()))
                .build();
    }

    /**
     * Create AnthropicChatModel for Claude Haiku (fast, cost-effective).
     */
    @Bean(name = "claudeHaikuChatModel")
    public ChatLanguageModel claudeHaikuChatModel(LlmConfigurationProperties props) {
        LlmConfigurationProperties.ClaudeHaikuConfig claudeHaiku = props.getClaudeHaiku();
        // Use the same API key as Sonnet if not explicitly configured
        String apiKey = claudeHaiku.getApiKey() != null ? claudeHaiku.getApiKey() : props.getClaude().getApiKey();
        return AnthropicChatModel.builder()
                .apiKey(apiKey)
                .modelName(claudeHaiku.getModelName())
                .timeout(Duration.ofSeconds(claudeHaiku.getTimeoutSeconds()))
                .build();
    }

    /**
     * Create adaptive routing strategy with heuristics.
     */
    @Bean
    public AdaptiveRoutingStrategy adaptiveRoutingStrategy(LlmConfigurationProperties props) {
        return new AdaptiveRoutingStrategy(props.getRouting());
    }

    /**
     * Create tiered Claude routing strategy.
     */
    @Bean
    public TieredClaudeRoutingStrategy tieredClaudeRoutingStrategy(LlmConfigurationProperties props) {
        return new TieredClaudeRoutingStrategy(props.getRouting());
    }

    /**
     * Create strategy registry for runtime strategy switching.
     */
    @Bean
    public StrategyRegistry strategyRegistry(
            AdaptiveRoutingStrategy adaptiveRoutingStrategy,
            TieredClaudeRoutingStrategy tieredClaudeRoutingStrategy
    ) {
        return new StrategyRegistry(
                Map.of(
                        "adaptive", adaptiveRoutingStrategy,
                        "tiered-claude", tieredClaudeRoutingStrategy
                ),
                "adaptive"  // Default to adaptive strategy
        );
    }

    /**
     * Create circuit breaker for vLLM health detection.
     */
    @Bean
    public VllmCircuitBreaker vllmCircuitBreaker(LlmConfigurationProperties props) {
        return new VllmCircuitBreaker(props.getCircuitBreaker());
    }

    /**
     * Create ModelUsageLogger for MDC-based provenance tracking.
     */
    @Bean
    public ModelUsageLogger modelUsageLogger() {
        return new ModelUsageLogger();
    }

    /**
     * Create the primary ChatLanguageModel that routes requests intelligently.
     * This is marked @Primary so it will be injected when ChatLanguageModel is requested.
     */
    @Bean
    @Primary
    public ChatLanguageModel routerChatLanguageModel(
            StrategyRegistry strategyRegistry,
            LlmAutoConfiguration config,
            VllmCircuitBreaker circuitBreaker,
            ModelUsageLogger usageLogger,
            LlmConfigurationProperties props
    ) {
        ChatLanguageModel qwenModel = qwenChatModel(props);
        ChatLanguageModel claudeModel = claudeChatModel(props);

        return new RouterChatLanguageModel(
                strategyRegistry,
                qwenModel,
                claudeModel,
                circuitBreaker,
                usageLogger
        );
    }
}
