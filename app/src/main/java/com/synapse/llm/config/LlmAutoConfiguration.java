package com.synapse.llm.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.ChatModel;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Map;

@Configuration
@ConditionalOnClass(ChatModel.class)
@EnableConfigurationProperties(LlmConfigurationProperties.class)
public class LlmAutoConfiguration {

    private static final Logger logger = LoggerFactory.getLogger(LlmAutoConfiguration.class);
    private final LlmConfigurationProperties properties;

    public LlmAutoConfiguration(LlmConfigurationProperties properties) {
        this.properties = properties;
    }

    @Bean
    public Map<String, ModelConfiguration> modelConfigurations() {
        return properties.getModels();
    }

    @Bean
    @ConditionalOnProperty(name = "llm.settings.default-model", havingValue = "claude-sonnet-4-6", matchIfMissing = true)
    public ChatModel claudeSonnet46ChatModel() {
        return createChatModel("claude-sonnet-4-6", properties.getModels().get("claude-sonnet-4-6"));
    }

    @Bean
    @ConditionalOnProperty(name = "llm.settings.default-model", havingValue = "claude-sonnet-4-5-20251022")
    public ChatModel claudeSonnet4520251022ChatModel() {
        return createChatModel("claude-sonnet-4-5-20251022", properties.getModels().get("claude-sonnet-4-5-20251022"));
    }

    @Bean
    @ConditionalOnProperty(name = "llm.settings.default-model", havingValue = "claude-sonnet-4-5")
    public ChatModel claudeSonnet45ChatModel() {
        return createChatModel("claude-sonnet-4-5", properties.getModels().get("claude-sonnet-4-5"));
    }

    @Bean
    @ConditionalOnProperty(name = "llm.settings.default-model", havingValue = "claude-haiku-4-5-20251001")
    public ChatModel claudeHaiku4520251001ChatModel() {
        return createChatModel("claude-haiku-4-5-20251001", properties.getModels().get("claude-haiku-4-5-20251001"));
    }

    @Bean
    @ConditionalOnProperty(name = "llm.settings.default-model", havingValue = "claude-haiku-4-5")
    public ChatModel claudeHaiku45ChatModel() {
        return createChatModel("claude-haiku-4-5", properties.getModels().get("claude-haiku-4-5"));
    }

    private ChatModel createChatModel(String modelName, ModelConfiguration config) {
        logger.info("Creating ChatModel for: {} (apiBase: {}, model: {})", modelName, config.getApiBase(), config.getModel());
        return new MockChatModel(modelName);
    }
}
