package com.synapse.llm.service;

import com.synapse.llm.config.LlmConfigurationProperties;
import com.synapse.llm.config.ModelConfiguration;
import com.synapse.llm.service.impl.RoundRobinModelSelector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.ChatModel;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class LlmModelRouter {

    private static final Logger logger = LoggerFactory.getLogger(LlmModelRouter.class);
    private final LlmConfigurationProperties properties;
    private final Map<String, ChatModel> chatModels;
    private final ModelSelectionStrategy modelSelector;

    public LlmModelRouter(LlmConfigurationProperties properties, Map<String, ChatModel> chatModels) {
        this.properties = properties;
        this.chatModels = chatModels;

        String strategy = properties.getSettings().getSelectionStrategy();
        logger.info("Initializing LlmModelRouter with strategy: {}", strategy);

        List<String> modelNames = new ArrayList<>(properties.getModels().keySet());
        this.modelSelector = createModelSelector(strategy, modelNames);
    }

    private ModelSelectionStrategy createModelSelector(String strategy, List<String> modelNames) {
        return switch (strategy.toLowerCase()) {
            case "round-robin" -> new RoundRobinModelSelector(modelNames);
            default -> {
                logger.warn("Unknown strategy: {}, defaulting to round-robin", strategy);
                yield new RoundRobinModelSelector(modelNames);
            }
        };
    }

    public String getSelectedModel() {
        return modelSelector.selectModel(new ArrayList<>(properties.getModels().keySet()));
    }

    public ChatModel getSelectedChatModel() {
        String modelName = getSelectedModel();
        ChatModel chatModel = chatModels.get(modelName + "ChatModel");
        if (chatModel == null) {
            throw new IllegalStateException("ChatModel not found for: " + modelName);
        }
        return chatModel;
    }

    public ChatModel getChatModelByModelName(String modelName) {
        ChatModel chatModel = chatModels.get(modelName + "ChatModel");
        if (chatModel == null) {
            throw new IllegalStateException("ChatModel not found for: " + modelName);
        }
        return chatModel;
    }

    public ModelConfiguration getModelConfiguration(String modelName) {
        return properties.getModels().get(modelName);
    }

    public List<String> getAvailableModels() {
        return new ArrayList<>(properties.getModels().keySet());
    }
}
