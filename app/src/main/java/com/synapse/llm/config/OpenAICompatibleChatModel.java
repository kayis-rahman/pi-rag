package com.synapse.llm.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.Generation;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * ChatModel implementation that calls GPUHub API via OpenAI-compatible format.
 */
@Slf4j
public class OpenAICompatibleChatModel implements ChatModel {

    private final String modelName;
    private final ModelConfiguration.LiteLLMParams params;
    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    public OpenAICompatibleChatModel(String modelName, ModelConfiguration.LiteLLMParams params, WebClient webClient, ObjectMapper objectMapper) {
        this.modelName = modelName;
        this.params = params;
        this.webClient = webClient;
        this.objectMapper = objectMapper;
    }


    @Override
    public ChatResponse call(Prompt prompt) {
        log.info("Calling GPUHub API for model: {}", modelName);

        // Get the instructions (List<Message>) from prompt
        List<Message> instructions = prompt.getInstructions();

        // Extract content from first message
        String content = "";
        if (!instructions.isEmpty()) {
            content = instructions.get(0).getText();
        }

        // Stream the content and collect all chunks
        Flux<String> resultStream = stream(content);
        List<String> results = resultStream.collectList().block();

        if (results != null && !results.isEmpty()) {
            // Aggregate chunks into complete response
            String fullResponse = String.join("", results);
            // Build ChatResponse using constructor
            AssistantMessage message = new AssistantMessage(fullResponse);
            return new ChatResponse(List.of(new Generation(message)));
        }

        throw new RuntimeException("No streaming response from GPUHub");
    }

    @Override
    public String call(Message... messages) {
        log.info("Calling GPUHub API for model: {} with {} messages", modelName, messages.length);

        // Convert Message[] to a single prompt string
        String prompt = messages.length > 0 ? messages[0].getText() : "";

        // Stream the content and collect all chunks
        Flux<String> stream = stream(prompt);
        List<String> results = stream.collectList().block();

        if (results != null && !results.isEmpty()) {
            // Aggregate chunks into complete response
            return String.join("", results);
        }

        throw new RuntimeException("No streaming response from GPUHub");
    }

    @Override
    public ChatOptions getDefaultOptions() {
        return ChatOptions.builder().build();
    }

    public Flux<String> stream(String userMessage) {
        log.info("Streaming GPUHub API for model: {} with message", modelName);

        // Build OpenAI-compatible request with streaming enabled
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", params.getModel());
        requestBody.put("messages", new Object[]{
            Map.of("role", "user", "content", userMessage)
        });
        requestBody.put("stream", true);

        String jsonBody;
        try {
            jsonBody = objectMapper.writeValueAsString(requestBody);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize request body", e);
        }
        log.debug("Request body: {}", jsonBody);

        return webClient.post()
            .uri(params.getApiBase() + "/chat/completions")
            .header(HttpHeaders.AUTHORIZATION, "Bearer " + params.getApiKey())
            .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .header(HttpHeaders.ACCEPT, MediaType.TEXT_EVENT_STREAM_VALUE)
            .bodyValue(jsonBody)
            .retrieve()
            .bodyToFlux(String.class)
            .map(this::parseSseChunk)
            .filter(token -> !token.isEmpty())
            .doOnError(error -> log.error("Error parsing SSE chunk: {}", error));
    }

    /**
     * Streams a list of messages to the GPUHub API.
     */
    private Flux<String> streamMessages(List<Map<String, Object>> messages) {
        log.info("Streaming GPUHub API for model: {} with {} messages", modelName, messages.size());

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", params.getModel());
        requestBody.put("messages", messages);
        requestBody.put("stream", true);

        String jsonBody;
        try {
            jsonBody = objectMapper.writeValueAsString(requestBody);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize request body", e);
        }
        log.debug("Request body: {}", jsonBody);

        return webClient.post()
            .uri(params.getApiBase() + "/chat/completions")
            .header(HttpHeaders.AUTHORIZATION, "Bearer " + params.getApiKey())
            .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .header(HttpHeaders.ACCEPT, MediaType.TEXT_EVENT_STREAM_VALUE)
            .bodyValue(jsonBody)
            .retrieve()
            .bodyToFlux(String.class)
            .map(this::parseSseChunk)
            .filter(token -> !token.isEmpty())
            .doOnError(error -> log.error("Error parsing SSE chunk: {}", error));
    }

    @Override
    public Flux<ChatResponse> stream(Prompt prompt) {
        log.info("Streaming GPUHub API for model: {}", modelName);

        // Get the instructions (List<Message>) from prompt
        List<Message> instructions = prompt.getInstructions();

        // Extract content from first message
        String content = "";
        if (!instructions.isEmpty()) {
            content = instructions.get(0).getText();
        }

        return streamFlux(content);
    }

    private Flux<ChatResponse> streamFlux(String userMessage) {
        // Build request for streaming
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", params.getModel());
        requestBody.put("messages", new Object[]{
            Map.of("role", "user", "content", userMessage)
        });
        requestBody.put("stream", true);

        String jsonBody;
        try {
            jsonBody = objectMapper.writeValueAsString(requestBody);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize request body", e);
        }

        return webClient.post()
            .uri(params.getApiBase() + "/chat/completions")
            .header(HttpHeaders.AUTHORIZATION, "Bearer " + params.getApiKey())
            .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .header(HttpHeaders.ACCEPT, MediaType.TEXT_EVENT_STREAM_VALUE)
            .bodyValue(jsonBody)
            .retrieve()
            .bodyToFlux(String.class)
            .map(this::parseSseChunk)
            .filter(token -> !token.isEmpty())
            .doOnError(error -> log.error("Error parsing SSE chunk: {}", error))
            .map(token -> new ChatResponse(List.of(new Generation(new AssistantMessage(token)))));
    }

    @Override
    public Flux<String> stream(Message... messages) {
        log.info("Streaming GPUHub API for model: {} with {} messages", modelName, messages.length);

        // Convert Message[] to JSON array for API
        List<Map<String, Object>> messageList = Stream.of(messages)
            .map(m -> {
                Map<String, Object> message = new HashMap<>();
                String role = determineRole(m);
                message.put("role", role);
                message.put("content", m.getText());
                return message;
            })
            .collect(Collectors.toList());

        return streamMessages(messageList);
    }

    private String determineRole(Message message) {
        String role = message.getClass().getSimpleName().toLowerCase();
        if (role.contains("user")) return "user";
        if (role.contains("assistant")) return "assistant";
        if (role.contains("system")) return "system";
        return "user";
    }

    private String parseSseChunk(String sseLine) {
        // SSE format: "data: {json}\n\n"
        if (sseLine.contains("data: ")) {
            String json = sseLine.substring(sseLine.indexOf("data: ") + 6);
            return extractContent(json);
        }
        return "";
    }

    private String extractContent(String json) {
        try {
            JsonNode jsonNode = objectMapper.readTree(json);
            JsonNode choices = jsonNode.get("choices");
            if (choices != null && !choices.isEmpty()) {
                JsonNode delta = choices.get(0).get("delta");
                if (delta != null) {
                    JsonNode content = delta.get("content");
                    if (content != null) {
                        return content.asText();
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to parse SSE chunk: {}", json, e);
        }
        return "";
    }

    private void logError(Throwable error) {
        log.error("Error parsing SSE chunk: {}", error.getMessage(), error);
    }

    public String getModelName() {
        return modelName;
    }
}
