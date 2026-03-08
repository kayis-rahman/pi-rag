package com.synapse.llm.config;

import org.springframework.ai.chat.ChatModel;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;

public class MockChatModel implements ChatModel {
    private final String modelName;

    public MockChatModel(String modelName) {
        this.modelName = modelName;
    }

    @Override
    public ChatResponse call(Prompt prompt) {
        return new ChatResponse(new org.springframework.ai.chat.model.ChatResponseMetadata(modelName));
    }

    @Override
    public ChatResponse call(UserMessage message) {
        return new ChatResponse(new org.springframework.ai.chat.model.ChatResponseMetadata(modelName));
    }

    public String getModelName() {
        return modelName;
    }
}
