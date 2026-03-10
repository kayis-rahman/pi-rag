package com.synapse.llm.routing;

import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.UserMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Adapter that wraps RouterChatLanguageModel to provide Spring AI ChatModel interface.
 * Converts between Spring AI Prompt API and LangChain4j ChatMessage API.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RoutingAwareChatModel implements ChatModel {

    private final RouterChatLanguageModel routerModel;

    @Override
    public String call(String message) {
        Prompt prompt = new Prompt(new org.springframework.ai.chat.messages.UserMessage(message));
        ChatResponse response = call(prompt);
        return response.getResult().getOutput().getText();
    }

    @Override
    public ChatResponse call(Prompt prompt) {
        // Convert Spring AI Prompt to LangChain4j messages
        List<ChatMessage> messages = convertPromptToMessages(prompt);

        // Use the router model (handles routing, circuit breaker, logging)
        dev.langchain4j.model.output.Response<dev.langchain4j.data.message.AiMessage> response =
                routerModel.generate(messages);

        // Convert LangChain4j response back to Spring AI ChatResponse
        return convertToSpringAIChatResponse(response);
    }

    /**
     * Stream version of chat - returns a Flux of ChatResponse tokens.
     */
    public Flux<ChatResponse> stream(Prompt prompt) {
        // For now, use the blocking call and wrap in Flux
        // TODO: Implement true streaming support
        return Flux.just(call(prompt));
    }

    /**
     * Get the last routing decision made.
     */
    public RoutingDecision lastDecision() {
        return routerModel.getLastDecision();
    }

    /**
     * Convert Spring AI Prompt to LangChain4j ChatMessage list.
     */
    private List<ChatMessage> convertPromptToMessages(Prompt prompt) {
        // Extract content from Spring AI Prompt
        String content = "";

        try {
            // Try to get instructions (the main text content)
            Object instructions = prompt.getInstructions();

            if (instructions != null) {
                if (instructions instanceof String) {
                    content = (String) instructions;
                } else if (instructions instanceof java.util.List) {
                    java.util.List<?> msgList = (java.util.List<?>) instructions;
                    StringBuilder sb = new StringBuilder();
                    for (Object msg : msgList) {
                        if (msg instanceof org.springframework.ai.chat.messages.Message) {
                            org.springframework.ai.chat.messages.Message m =
                                (org.springframework.ai.chat.messages.Message) msg;
                            String text = extractMessageText(m);
                            if (text != null && !text.isEmpty()) {
                                sb.append(text).append(" ");
                            }
                        }
                    }
                    content = sb.toString().trim();
                } else {
                    content = instructions.toString();
                }
            }
        } catch (Exception e) {
            log.warn("Error extracting instructions from Prompt", e);
            content = "";
        }

        if (content == null || content.isEmpty()) {
            content = "";
        }
        return List.of(UserMessage.from(content));
    }

    private String extractMessageText(org.springframework.ai.chat.messages.Message msg) {
        // Try to get the message content - fallback to toString
        if (msg != null) {
            try {
                // Use reflection or just toString as fallback
                String str = msg.toString();
                // Remove class name prefix if present
                if (str.contains("[") && str.contains("]")) {
                    return str.substring(str.indexOf("]") + 1).trim();
                }
                return str;
            } catch (Exception e) {
                log.debug("Could not extract message text", e);
            }
        }
        return "";
    }

    /**
     * Convert LangChain4j Response to Spring AI ChatResponse.
     */
    private ChatResponse convertToSpringAIChatResponse(
            dev.langchain4j.model.output.Response<dev.langchain4j.data.message.AiMessage> response) {

        String text = response.content().text();

        // Create Spring AI AssistantMessage
        org.springframework.ai.chat.messages.AssistantMessage assistantMessage =
                new org.springframework.ai.chat.messages.AssistantMessage(text);

        // Create Spring AI Generation
        var generation = new org.springframework.ai.chat.model.Generation(assistantMessage);

        // Create Spring AI ChatResponse
        return new ChatResponse(List.of(generation));
    }
}
