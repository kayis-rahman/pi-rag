package com.synapse.llm.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.synapse.llm.routing.RequestRouter;
import com.synapse.llm.routing.RoutingAwareChatModel;
import com.synapse.llm.routing.RoutingConfigProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Configuration
@EnableConfigurationProperties(LlmConfigurationProperties.class)
public class LlmAutoConfiguration {

    private static final Logger logger = LoggerFactory.getLogger(LlmAutoConfiguration.class);
    private final LlmConfigurationProperties properties;
    private final WebClient webClient;
    private final ObjectMapper objectMapper;
    private Map<String, ChatModel> models;

    public LlmAutoConfiguration(LlmConfigurationProperties properties, WebClient.Builder webClientBuilder, ObjectMapper objectMapper) {
        this.properties = properties;
        this.webClient = webClientBuilder.build();
        this.objectMapper = objectMapper;
        this.models = new HashMap<>();
    }

    @Bean
    public Map<String, ModelConfiguration> modelConfigurations() {
        return properties.toModelMap();
    }

    @Bean
    public InstanceLoadBalancer instanceLoadBalancer() {
        // Create ModelInstance wrappers for each configured instance
        List<ModelInstance> instances = new java.util.ArrayList<>();

        properties.getModelList().forEach(model -> {
            if (model.getInstances() == null || model.getInstances().isEmpty()) {
                // Single instance mode: create one instance from litellmParams
                ModelConfiguration.LiteLLMParams params = model.getLitellmParams();
                if (params != null) {
                    instances.add(new ModelInstance(
                        new OpenAICompatibleChatModel(model.getModelName(), params, webClient, objectMapper),
                        model.getModelName(),
                        true
                    ));
                }
            } else {
                // Multi-instance mode: create instances from configured instances
                model.getInstances().stream()
                    .filter(i -> i.getEnabled() != null && i.getEnabled())
                    .forEach(i -> {
                        ModelConfiguration.LiteLLMParams params = new ModelConfiguration.LiteLLMParams(
                            model.getModelName(),
                            i.getApiBase(),
                            i.getApiKey()
                        );
                        instances.add(new ModelInstance(
                            new OpenAICompatibleChatModel(model.getModelName(), params, webClient, objectMapper),
                            i.getInstanceId(),
                            i.getIsPrimary() != null && i.getIsPrimary()
                        ));
                    });
            }
        });

        return new InstanceLoadBalancer(instances);
    }

    @Bean
    public Map<String, ChatModel> chatModels() {
        Map<String, ChatModel> modelMap = new HashMap<>();

        properties.getModelList().forEach(modelConfig -> {
            String modelName = modelConfig.getModelName();
            List<ModelInstanceConfiguration> instances = modelConfig.getInstances();

            if (instances != null && !instances.isEmpty()) {
                // Multi-instance mode: create MultiInstanceChatModel
                List<OpenAICompatibleChatModel> chatModels = instances.stream()
                    .filter(i -> i.getEnabled() != null && i.getEnabled())
                    .map(i -> {
                        ModelConfiguration.LiteLLMParams params = new ModelConfiguration.LiteLLMParams(
                            modelName,
                            i.getApiBase(),
                            i.getApiKey()
                        );
                        return new OpenAICompatibleChatModel(modelName, params, webClient, objectMapper);
                    })
                    .collect(Collectors.toList());

                models.put(modelName, new MultiInstanceChatModel(chatModels, instanceLoadBalancer(), modelName));
                modelMap.put(modelName, new MultiInstanceChatModel(chatModels, instanceLoadBalancer(), modelName));
                logger.info("Created MultiInstanceChatModel for model: {} with {} instances", modelName, chatModels.size());
            } else {
                // Single instance mode (backward compatibility): create regular OpenAICompatibleChatModel
                ModelConfiguration.LiteLLMParams params = modelConfig.getLitellmParams();
                if (params != null) {
                    models.put(modelName, new OpenAICompatibleChatModel(modelName, params, webClient, objectMapper));
                    modelMap.put(modelName, new OpenAICompatibleChatModel(modelName, params, webClient, objectMapper));
                    logger.info("Created single-instance ChatModel for: {} (model: {}, apiBase: {})",
                        modelName, params.getModel(), params.getApiBase());
                }
            }
        });

        return modelMap;
    }

    @Bean
    public ChatModel claudeSonnet46ChatModel() {
        return models.get("claude-sonnet-4-6");
    }

    @Bean
    public ChatModel claudeSonnet4520251022ChatModel() {
        return models.get("claude-sonnet-4-5-20251022");
    }

    @Bean
    public ChatModel claudeSonnet45ChatModel() {
        return models.get("claude-sonnet-4-5");
    }

    @Bean
    public ChatModel claudeHaiku4520251001ChatModel() {
        return models.get("claude-haiku-4-5-20251001");
    }

    @Bean
    public ChatModel claudeHaiku45ChatModel() {
        return models.get("claude-haiku-4-5");
    }

    @Bean
    @Primary
    public RoutingAwareChatModel routingAwareChatModel(
            RequestRouter router,
            RoutingConfigProperties routingConfig,
            WebClient.Builder webClientBuilder,
            ObjectMapper objectMapper) {
        return new RoutingAwareChatModel(router, routingConfig, webClientBuilder, objectMapper);
    }
}
