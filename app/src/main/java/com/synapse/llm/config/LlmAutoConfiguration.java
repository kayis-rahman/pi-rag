package com.synapse.llm.config;

import com.synapse.llm.health.VllmCircuitBreaker;
import com.synapse.llm.logging.ModelUsageLogger;
import com.synapse.llm.routing.AdaptiveRoutingStrategy;
import com.synapse.llm.routing.RouterChatLanguageModel;
import com.synapse.llm.routing.RoutingStrategy;
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
 * - AnthropicChatModel (Claude)
 * - RoutingStrategy (AdaptiveRoutingStrategy)
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
     * Create AnthropicChatModel for Claude API.
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
     * Create routing strategy with heuristics.
     */
    @Bean
    public RoutingStrategy routingStrategy(LlmConfigurationProperties props) {
        return new AdaptiveRoutingStrategy(props.getRouting());
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
            RoutingStrategy routingStrategy,
            LlmAutoConfiguration config,
            VllmCircuitBreaker circuitBreaker,
            ModelUsageLogger usageLogger,
            LlmConfigurationProperties props
    ) {
        ChatLanguageModel qwenModel = qwenChatModel(props);
        ChatLanguageModel claudeModel = claudeChatModel(props);

        return new RouterChatLanguageModel(
                routingStrategy,
                qwenModel,
                claudeModel,
                circuitBreaker,
                usageLogger
        );
    }
}
