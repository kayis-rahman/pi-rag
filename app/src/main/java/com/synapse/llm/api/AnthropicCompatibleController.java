package com.synapse.llm.api;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.synapse.llm.config.LlmConfigurationProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;

/**
 * Anthropic API compatible endpoint with true LiteLLM-style format translation.
 * Accepts full Anthropic requests, translates to OpenAI format, forwards to vLLM,
 * and translates responses back to Anthropic format.
 */
@RestController
@RequestMapping("/v1")
@Slf4j
@RequiredArgsConstructor
public class AnthropicCompatibleController {

    private final LlmConfigurationProperties config;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @PostMapping("/messages")
    public ResponseEntity<?> messages(@RequestBody String rawBody) {
        try {
            log.info("📨 /v1/messages - Received Anthropic format request");

            if (rawBody == null || rawBody.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Request body required"));
            }

            // Parse Anthropic request
            Map<String, Object> anthropicRequest = objectMapper.readValue(rawBody, Map.class);

            // Build OpenAI chat/completions request
            Map<String, Object> openaiRequest = translateAnthropicToOpenAI(anthropicRequest);

            // Forward to vLLM
            String openaiResponse = forwardToVllm(openaiRequest);

            // Parse OpenAI response
            Map<String, Object> openaiResponseMap = objectMapper.readValue(openaiResponse, Map.class);

            // Translate to Anthropic format
            Map<String, Object> anthropicResponse = translateOpenAIToAnthropic(
                openaiResponseMap,
                (String) anthropicRequest.get("model")
            );

            return ResponseEntity.ok(anthropicResponse);

        } catch (Exception e) {
            log.error("Error processing Anthropic API request", e);
            return ResponseEntity.status(400).body(Map.of(
                "error", e.getMessage(),
                "type", e.getClass().getSimpleName()
            ));
        }
    }

    /**
     * Translate Anthropic request format to OpenAI format.
     * - Prepend system prompt to messages if present
     * - Map stop_sequences → stop
     * - Use configured model name (override client model)
     * - Pass through max_tokens, temperature, top_p, stream
     */
    private Map<String, Object> translateAnthropicToOpenAI(Map<String, Object> anthropicRequest) {
        Map<String, Object> openaiRequest = new LinkedHashMap<>();

        // Get messages from Anthropic request
        @SuppressWarnings("unchecked")
        List<Object> messages = (List<Object>) anthropicRequest.get("messages");
        if (messages == null || messages.isEmpty()) {
            throw new IllegalArgumentException("No messages provided");
        }

        // Create mutable messages list
        List<Object> openaiMessages = new ArrayList<>(messages);

        // Prepend system prompt if provided
        Object systemPrompt = anthropicRequest.get("system");
        if (systemPrompt != null && !systemPrompt.toString().isEmpty()) {
            Map<String, Object> systemMessage = new LinkedHashMap<>();
            systemMessage.put("role", "system");
            systemMessage.put("content", systemPrompt.toString());
            openaiMessages.add(0, systemMessage);
        }

        openaiRequest.put("messages", openaiMessages);

        // Use configured model name (ignore client-sent model)
        openaiRequest.put("model", config.getQwen().getModelName());

        // Map Anthropic parameters to OpenAI
        if (anthropicRequest.containsKey("max_tokens")) {
            openaiRequest.put("max_tokens", anthropicRequest.get("max_tokens"));
        }

        if (anthropicRequest.containsKey("temperature")) {
            openaiRequest.put("temperature", anthropicRequest.get("temperature"));
        }

        if (anthropicRequest.containsKey("top_p")) {
            openaiRequest.put("top_p", anthropicRequest.get("top_p"));
        }

        // Map stop_sequences → stop
        if (anthropicRequest.containsKey("stop_sequences")) {
            openaiRequest.put("stop", anthropicRequest.get("stop_sequences"));
        }

        // Ensure non-streaming responses (this controller handles sync only)
        openaiRequest.put("stream", false);

        log.debug("Translated Anthropic request to OpenAI format: {} messages, model: {}",
                  openaiMessages.size(), config.getQwen().getModelName());

        return openaiRequest;
    }

    /**
     * Forward request to vLLM using HttpClient.
     */
    private String forwardToVllm(Map<String, Object> openaiRequest) throws Exception {
        String vllmUrl = config.getQwen().getBaseUrl() + "/chat/completions";
        long timeoutSeconds = config.getQwen().getTimeoutSeconds();

        String requestBody = objectMapper.writeValueAsString(openaiRequest);

        log.info("🚀 Forwarding to vLLM: {} with {} messages", vllmUrl,
                 ((List<?>) openaiRequest.get("messages")).size());

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(timeoutSeconds))
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(vllmUrl))
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        log.info("📥 vLLM response status: {}", response.statusCode());
        log.debug("📄 vLLM response body: {}", response.body().substring(0, Math.min(500, response.body().length())));

        if (response.statusCode() != 200) {
            log.error("vLLM error status {}: {}", response.statusCode(), response.body());
            throw new RuntimeException("vLLM error: " + response.statusCode() + " - " + response.body());
        }

        return response.body();
    }

    /**
     * Translate OpenAI response format to Anthropic format.
     * OpenAI: {"id": "...", "choices": [{"message": {"content": "..."}, "finish_reason": "stop"}], "usage": {...}}
     * Anthropic: {"id": "msg-...", "type": "message", "role": "assistant", "content": [{"type": "text", "text": "..."}], ...}
     */
    private Map<String, Object> translateOpenAIToAnthropic(
            Map<String, Object> openaiResponse,
            String clientModel) {

        Map<String, Object> anthropicResponse = new LinkedHashMap<>();

        // Generate Anthropic-style message ID
        String messageId = "msg-" + UUID.randomUUID().toString().substring(0, 8);
        anthropicResponse.put("id", messageId);

        anthropicResponse.put("type", "message");
        anthropicResponse.put("role", "assistant");

        // Extract content from first choice
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> choices = (List<Map<String, Object>>) openaiResponse.get("choices");
        if (choices == null || choices.isEmpty()) {
            throw new RuntimeException("No choices in OpenAI response");
        }

        Map<String, Object> firstChoice = choices.get(0);
        @SuppressWarnings("unchecked")
        Map<String, Object> message = (Map<String, Object>) firstChoice.get("message");
        String content = (String) message.get("content");

        // Wrap content in Anthropic format
        List<Map<String, Object>> contentBlocks = new ArrayList<>();
        Map<String, Object> textBlock = new LinkedHashMap<>();
        textBlock.put("type", "text");
        textBlock.put("text", content);
        contentBlocks.add(textBlock);

        anthropicResponse.put("content", contentBlocks);

        // Map finish_reason
        String finishReason = (String) firstChoice.get("finish_reason");
        anthropicResponse.put("stop_reason", mapFinishReason(finishReason));

        // Use configured model name (or client model as fallback)
        anthropicResponse.put("model", clientModel != null ? clientModel : config.getQwen().getModelName());

        // Extract and map usage
        @SuppressWarnings("unchecked")
        Map<String, Object> usage = (Map<String, Object>) openaiResponse.get("usage");
        if (usage != null) {
            Map<String, Object> anthropicUsage = new LinkedHashMap<>();
            anthropicUsage.put("input_tokens", usage.get("prompt_tokens"));
            anthropicUsage.put("output_tokens", usage.get("completion_tokens"));
            anthropicResponse.put("usage", anthropicUsage);
        }

        log.debug("Translated OpenAI response to Anthropic format: id={}, stop_reason={}",
                  messageId, anthropicResponse.get("stop_reason"));

        return anthropicResponse;
    }

    /**
     * Map OpenAI finish_reason to Anthropic stop_reason.
     */
    private String mapFinishReason(String openaiFinishReason) {
        if (openaiFinishReason == null) {
            return "end_turn";
        }
        return switch (openaiFinishReason) {
            case "stop" -> "end_turn";
            case "length" -> "max_tokens";
            default -> openaiFinishReason;
        };
    }

    // ========== Request/Response Classes for documentation ==========

    @lombok.Data
    @lombok.AllArgsConstructor
    @lombok.NoArgsConstructor
    public static class AnthropicRequest {
        public String model;
        public List<MessageBlock> messages;
        public String system;
        @JsonProperty("max_tokens")
        public int max_tokens;
        public Double temperature;
        public Double top_p;
        public List<String> stop_sequences;
        public Boolean stream;

        @lombok.Data
        @lombok.NoArgsConstructor
        public static class MessageBlock {
            public String role;
            public Object content; // Can be string or array of content blocks
        }
    }

    @lombok.Data
    @lombok.AllArgsConstructor
    @lombok.NoArgsConstructor
    public static class AnthropicResponse {
        public String id;
        public String type;
        public String role;
        public List<ContentBlock> content;
        public String model;
        @JsonProperty("stop_reason")
        public String stop_reason;
        public Usage usage;

        @lombok.Data
        @lombok.AllArgsConstructor
        @lombok.NoArgsConstructor
        public static class ContentBlock {
            public String type;
            public String text;
        }

        @lombok.Data
        @lombok.AllArgsConstructor
        @lombok.NoArgsConstructor
        public static class Usage {
            @JsonProperty("input_tokens")
            public int input_tokens;
            @JsonProperty("output_tokens")
            public int output_tokens;
        }
    }
}
