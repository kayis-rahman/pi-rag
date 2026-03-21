package com.synapse.llm.api;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.synapse.llm.config.LlmConfigurationProperties;
import com.synapse.llm.metrics.MetricsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;
import java.util.stream.Collectors;

/**
 * Anthropic API compatible endpoint with true LiteLLM-style format translation.
 * Accepts full Anthropic requests, translates to OpenAI format, forwards to vLLM,
 * and translates responses back to Anthropic format.
 */
@RestController
@RequestMapping("/v1")
@Slf4j
public class AnthropicCompatibleController {

    private final LlmConfigurationProperties config;
    private final WebClient vllmWebClientA;
    private final WebClient vllmWebClientB;
    private final MetricsService metricsService;
    private final ObjectMapper objectMapper;

    public AnthropicCompatibleController(
            LlmConfigurationProperties config,
            @Qualifier("vllmWebClientA") WebClient vllmWebClientA,
            @Qualifier("vllmWebClientB") WebClient vllmWebClientB,
            MetricsService metricsService) {
        this.config = config;
        this.vllmWebClientA = vllmWebClientA;
        this.vllmWebClientB = vllmWebClientB;
        this.metricsService = metricsService;
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Select WebClient based on model name.
     * Routes "haiku" models to Server A, all others to Server B.
     */
    private WebClient selectClient(String model) {
        if (model != null && model.toLowerCase().contains("haiku")) {
            log.info("🔀 Routing model [{}] → Server A (haiku)", model);
            return vllmWebClientA;
        }
        log.debug("🔀 Routing model [{}] → Server B (sonnet)", model);
        return vllmWebClientB;
    }

    /**
     * Resolve the correct vLLM model name based on client-requested model.
     * Haiku requests → Server A (claude-haiku-4-5-20251001)
     * Non-haiku requests → Server B (claude-sonnet-4-6)
     */
    private String resolveVllmModelName(String clientModel) {
        if (clientModel != null && clientModel.toLowerCase().contains("haiku")) {
            return config.getQwen().getModelName();           // claude-haiku-4-5-20251001
        }
        return config.getQwen().getSecondaryModelName();      // claude-sonnet-4-6
    }

    @PostMapping("/messages")
    public Mono<ResponseEntity<?>> messages(@RequestBody String rawBody) {
        long startTime = System.currentTimeMillis();

        try {
            log.info("📨 /v1/messages - Received Anthropic format request");

            if (rawBody == null || rawBody.isEmpty()) {
                return Mono.just(ResponseEntity.badRequest().body(
                    anthropicError("invalid_request_error", "Request body required")
                ));
            }

            // Parse Anthropic request
            Map<String, Object> anthropicRequest = objectMapper.readValue(rawBody, Map.class);
            String model = (String) anthropicRequest.get("model");
            @SuppressWarnings("unchecked")
            List<Object> messages = (List<Object>) anthropicRequest.get("messages");
            int messageCount = messages != null ? messages.size() : 0;

            // Check if client wants streaming
            boolean wantsStream = Boolean.TRUE.equals(anthropicRequest.get("stream"));

            // Record metrics for request
            metricsService.recordLlmRequest(model, messageCount, wantsStream);

            if (wantsStream) {
                return Mono.just(streamMessages(anthropicRequest));
            }

            // Build OpenAI chat/completions request
            Map<String, Object> openaiRequest = translateAnthropicToOpenAI(anthropicRequest);

            // Forward to vLLM asynchronously
            return forwardToVllm(openaiRequest, model, messageCount, startTime)
                    .map(openaiResponse -> {
                        try {
                            // Parse OpenAI response
                            Map<String, Object> openaiResponseMap = objectMapper.readValue(openaiResponse, Map.class);

                            // Translate to Anthropic format
                            Map<String, Object> anthropicResponse = translateOpenAIToAnthropic(
                                openaiResponseMap,
                                model
                            );

                            long latencyMs = System.currentTimeMillis() - startTime;
                            metricsService.recordLlmResponse(model, latencyMs, 200, false);
                            return (ResponseEntity<?>) ResponseEntity.ok(anthropicResponse);
                        } catch (Exception e) {
                            log.error("Error parsing/translating vLLM response", e);
                            long latencyMs = System.currentTimeMillis() - startTime;
                            metricsService.recordLlmResponse(model, latencyMs, 400, false);
                            return (ResponseEntity<?>) ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
                                anthropicError("api_error", "Response translation failed: " + e.getMessage())
                            );
                        }
                    })
                    .onErrorResume(e -> {
                        log.error("Error forwarding to vLLM", e);
                        long latencyMs = System.currentTimeMillis() - startTime;
                        // Use original HTTP status code if available, otherwise 502
                        int statusCode = (e instanceof VllmHttpException ve) ? ve.getStatus() : 502;
                        String errType = statusCode >= 500 ? "api_error" : "invalid_request_error";
                        metricsService.recordLlmResponse(model, latencyMs, statusCode, false);
                        return Mono.just((ResponseEntity<?>) ResponseEntity.status(statusCode).body(
                            anthropicError(errType, e.getMessage())
                        ));
                    });

        } catch (Exception e) {
            log.error("Error processing Anthropic API request", e);
            return Mono.just(ResponseEntity.status(400).body(
                anthropicError("invalid_request_error", "Invalid request body: " + e.getMessage())
            ));
        }
    }

    /**
     * Translate Anthropic request format to OpenAI format.
     * - Prepend system prompt to messages if present
     * - Map stop_sequences → stop
     * - Route model name based on client request (haiku vs. sonnet)
     * - Cap max_tokens to avoid context overflow
     * - Pass through temperature, top_p, stream
     */
    private Map<String, Object> translateAnthropicToOpenAI(Map<String, Object> anthropicRequest) {
        Map<String, Object> openaiRequest = new LinkedHashMap<>();

        // Get messages from Anthropic request
        @SuppressWarnings("unchecked")
        List<Object> messages = (List<Object>) anthropicRequest.get("messages");
        if (messages == null || messages.isEmpty()) {
            throw new IllegalArgumentException("No messages provided");
        }

        // Convert messages with tool_use/tool_result blocks
        List<Object> openaiMessages = new ArrayList<>();
        for (Object rawMsg : messages) {
            @SuppressWarnings("unchecked")
            Map<String, Object> msg = (Map<String, Object>) rawMsg;
            String role = (String) msg.get("role");
            Object content = msg.get("content");

            if (!(content instanceof List)) {
                // Simple string content — pass through unchanged
                openaiMessages.add(msg);
                continue;
            }

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> blocks = (List<Map<String, Object>>) content;
            boolean hasToolUse    = blocks.stream().anyMatch(b -> "tool_use".equals(b.get("type")));
            boolean hasToolResult = blocks.stream().anyMatch(b -> "tool_result".equals(b.get("type")));

            if ("assistant".equals(role) && hasToolUse) {
                // Build OpenAI assistant message: {role, content (text|null), tool_calls}
                String textContent = blocks.stream()
                    .filter(b -> "text".equals(b.get("type")))
                    .map(b -> (String) b.getOrDefault("text", ""))
                    .collect(Collectors.joining(""));

                List<Map<String, Object>> toolCalls = blocks.stream()
                    .filter(b -> "tool_use".equals(b.get("type")))
                    .map(b -> {
                        Map<String, Object> fn = new LinkedHashMap<>();
                        fn.put("name", b.get("name"));
                        try { fn.put("arguments", objectMapper.writeValueAsString(b.get("input"))); }
                        catch (Exception e) { fn.put("arguments", "{}"); }
                        Map<String, Object> tc2 = new LinkedHashMap<>();
                        tc2.put("id", b.get("id"));
                        tc2.put("type", "function");
                        tc2.put("function", fn);
                        return tc2;
                    }).collect(Collectors.toList());

                Map<String, Object> openaiMsg = new LinkedHashMap<>();
                openaiMsg.put("role", "assistant");
                openaiMsg.put("content", textContent.isEmpty() ? null : textContent);
                openaiMsg.put("tool_calls", toolCalls);
                openaiMessages.add(openaiMsg);

            } else if ("user".equals(role) && hasToolResult) {
                // Each tool_result block → separate {"role":"tool"} message
                for (Map<String, Object> block : blocks) {
                    if (!"tool_result".equals(block.get("type"))) continue;
                    Object toolContent = block.get("content");
                    String resultText;
                    if (toolContent instanceof String) {
                        resultText = (String) toolContent;
                    } else if (toolContent instanceof List) {
                        @SuppressWarnings("unchecked")
                        List<Map<String, Object>> cbs = (List<Map<String, Object>>) toolContent;
                        resultText = cbs.stream()
                            .filter(b -> "text".equals(b.get("type")))
                            .map(b -> (String) b.getOrDefault("text", ""))
                            .collect(Collectors.joining(""));
                    } else {
                        resultText = "";
                    }
                    Map<String, Object> toolMsg = new LinkedHashMap<>();
                    toolMsg.put("role", "tool");
                    toolMsg.put("tool_call_id", block.get("tool_use_id"));
                    toolMsg.put("content", resultText);
                    openaiMessages.add(toolMsg);
                }

            } else {
                // Regular content array (text only) — extract text and pass as string
                String textContent = blocks.stream()
                    .filter(b -> "text".equals(b.get("type")))
                    .map(b -> (String) b.getOrDefault("text", ""))
                    .collect(Collectors.joining(""));
                Map<String, Object> openaiMsg = new LinkedHashMap<>();
                openaiMsg.put("role", role);
                openaiMsg.put("content", textContent);
                openaiMessages.add(openaiMsg);
            }
        }

        // Prepend system prompt if provided
        Object systemPrompt = anthropicRequest.get("system");
        if (systemPrompt != null) {
            String systemText = extractSystemText(systemPrompt);
            if (!systemText.isEmpty()) {
                Map<String, Object> systemMessage = new LinkedHashMap<>();
                systemMessage.put("role", "system");
                systemMessage.put("content", systemText);
                openaiMessages.add(0, systemMessage);
            }
        }

        openaiRequest.put("messages", openaiMessages);

        // Resolve model name based on client request (haiku → Server A, sonnet → Server B)
        String clientModel = (String) anthropicRequest.get("model");
        String vllmModelName = resolveVllmModelName(clientModel);
        openaiRequest.put("model", vllmModelName);
        log.debug("🔀 Resolved model [{}] → [{}]", clientModel, vllmModelName);

        // Map Anthropic parameters to OpenAI, forwarding max_tokens directly
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

        // Translate tools: Anthropic {name, description, input_schema} → OpenAI {type, function:{name, description, parameters}}
        if (anthropicRequest.containsKey("tools")) {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> anthropicTools = (List<Map<String, Object>>) anthropicRequest.get("tools");
            List<Map<String, Object>> openaiTools = anthropicTools.stream().map(t -> {
                Map<String, Object> fn = new LinkedHashMap<>();
                fn.put("name", t.get("name"));
                if (t.containsKey("description")) fn.put("description", t.get("description"));
                fn.put("parameters", t.getOrDefault("input_schema", new LinkedHashMap<>()));
                Map<String, Object> tool = new LinkedHashMap<>();
                tool.put("type", "function");
                tool.put("function", fn);
                return tool;
            }).collect(Collectors.toList());
            openaiRequest.put("tools", openaiTools);
        }

        // Translate tool_choice
        if (anthropicRequest.containsKey("tool_choice")) {
            @SuppressWarnings("unchecked")
            Map<String, Object> tc = (Map<String, Object>) anthropicRequest.get("tool_choice");
            String tcType = (String) tc.get("type");
            if (tcType != null) {
                switch (tcType) {
                    case "auto" -> openaiRequest.put("tool_choice", "auto");
                    case "any"  -> openaiRequest.put("tool_choice", "required");
                    case "tool" -> {
                        Map<String, Object> specific = new LinkedHashMap<>();
                        specific.put("type", "function");
                        specific.put("function", Map.of("name", tc.get("name")));
                        openaiRequest.put("tool_choice", specific);
                    }
                }
            }
        }

        // For sync path, ensure non-streaming (streaming is handled separately)
        // Default to false unless caller explicitly sets stream=true
        if (!anthropicRequest.containsKey("stream")) {
            openaiRequest.put("stream", false);
        }

        log.debug("Translated Anthropic request to OpenAI format: {} messages, model: {}",
                  openaiMessages.size(), config.getQwen().getModelName());

        return openaiRequest;
    }

    /**
     * Forward request to vLLM using reactive WebClient with model-based routing.
     */
    private Mono<String> forwardToVllm(Map<String, Object> openaiRequest, String model, int messageCount, long startTime) {
        String requestBody;
        try {
            requestBody = objectMapper.writeValueAsString(openaiRequest);
        } catch (Exception e) {
            return Mono.error(e);
        }

        log.info("🚀 Forwarding to vLLM with {} messages",
                 ((List<?>) openaiRequest.get("messages")).size());

        WebClient client = selectClient(model);
        return client
                .post()
                .uri("/v1/chat/completions")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(requestBody)
                .retrieve()
                .onStatus(status -> !status.is2xxSuccessful(), resp ->
                    resp.bodyToMono(String.class)
                        .flatMap(body -> {
                            int statusCode = resp.statusCode().value();
                            log.error("vLLM error ({}): {}", statusCode, body);
                            return Mono.error(new VllmHttpException(statusCode, body));
                        }))
                .bodyToMono(String.class)
                .doOnNext(response -> {
                    log.info("📥 vLLM response received");
                    log.debug("📄 vLLM response body: {}", response.substring(0, Math.min(500, response.length())));
                });
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

        // Build content blocks — handle both text and tool_calls
        List<Map<String, Object>> contentBlocks = new ArrayList<>();

        // Text content (may be null when tool calls are present)
        String content = message.get("content") != null ? (String) message.get("content") : "";
        if (!content.isEmpty()) {
            Map<String, Object> textBlock = new LinkedHashMap<>();
            textBlock.put("type", "text");
            textBlock.put("text", content);
            contentBlocks.add(textBlock);
        }

        // Tool calls
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> toolCalls = (List<Map<String, Object>>) message.get("tool_calls");
        if (toolCalls != null) {
            for (Map<String, Object> tc : toolCalls) {
                @SuppressWarnings("unchecked")
                Map<String, Object> fn = (Map<String, Object>) tc.get("function");
                Map<String, Object> toolUseBlock = new LinkedHashMap<>();
                toolUseBlock.put("type", "tool_use");
                toolUseBlock.put("id", tc.get("id"));
                toolUseBlock.put("name", fn.get("name"));
                try {
                    String argsJson = (String) fn.get("arguments");
                    Object input = objectMapper.readValue(argsJson, Object.class);
                    toolUseBlock.put("input", input);
                } catch (Exception e) {
                    toolUseBlock.put("input", new LinkedHashMap<>());
                }
                contentBlocks.add(toolUseBlock);
            }
        }

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
            case "tool_calls" -> "tool_use";
            default -> openaiFinishReason;
        };
    }

    /**
     * Extract text from system prompt, handling both String and Array formats.
     * Anthropic allows: "system": "string" OR "system": [{"type": "text", "text": "..."}]
     */
    @SuppressWarnings("unchecked")
    private String extractSystemText(Object system) {
        if (system instanceof String s) {
            return s;
        }
        if (system instanceof List<?> blocks) {
            List<Map<String, Object>> typedBlocks = (List<Map<String, Object>>) (List<?>) blocks;
            return typedBlocks.stream()
                .filter(b -> "text".equals(b.get("type")))
                .map(b -> String.valueOf(b.getOrDefault("text", "")))
                .collect(Collectors.joining(""));
        }
        return "";
    }

    /**
     * Handle streaming requests by forwarding to vLLM and converting to Anthropic SSE format.
     * Uses reactive WebClient with ServerSentEvent deserialization to avoid blocking I/O.
     */
    private ResponseEntity<?> streamMessages(Map<String, Object> anthropicRequest) {
        long startTime = System.currentTimeMillis();
        String modelNameParam = (String) anthropicRequest.get("model");

        Map<String, Object> openaiRequest = translateAnthropicToOpenAI(anthropicRequest);
        openaiRequest.put("stream", true);
        openaiRequest.put("stream_options", Map.of("include_usage", true));

        // Model name is already resolved in translateAnthropicToOpenAI
        final String modelName = (String) openaiRequest.get("model");

        String requestBody;
        try {
            requestBody = objectMapper.writeValueAsString(openaiRequest);
        } catch (Exception e) {
            log.error("Error serializing OpenAI request", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Request serialization failed"));
        }

        String messageId = "msg-" + UUID.randomUUID().toString().substring(0, 8);

        log.info("🌊 Streaming to vLLM with {} messages",
                 ((List<?>) openaiRequest.get("messages")).size());

        // upstream SSE from vLLM
        WebClient client = selectClient(modelName);
        Flux<ServerSentEvent<String>> upstream = client
                .post()
                .uri("/v1/chat/completions")
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.TEXT_EVENT_STREAM)
                .bodyValue(requestBody)
                .retrieve()
                .onStatus(status -> !status.is2xxSuccessful(), resp ->
                    resp.bodyToMono(String.class)
                        .flatMap(b -> {
                            int statusCode = resp.statusCode().value();
                            log.error("vLLM streaming error ({}): {}", statusCode, b);
                            return Mono.error(new VllmHttpException(statusCode, b));
                        }))
                .bodyToFlux(new ParameterizedTypeReference<ServerSentEvent<String>>() {});

        // translate vLLM delta events → Anthropic content_block_delta events
        // State for tracking content blocks
        AtomicReference<String> finalFinishReason = new AtomicReference<>("end_turn");
        AtomicInteger nextBlockIndex = new AtomicInteger(0);
        AtomicInteger textBlockIndex = new AtomicInteger(-1);       // -1 = not started
        AtomicReference<Map<Integer, Integer>> toolBlockIndexMap = new AtomicReference<>(new LinkedHashMap<>());
        AtomicReference<Integer> inputTokensRef = new AtomicReference<>(0);
        AtomicReference<Integer> outputTokensRef = new AtomicReference<>(0);

        Flux<String> deltaFlux = upstream
                .takeWhile(event -> event.data() == null || !"[DONE]".equals(event.data()))
                .filter(event -> event.data() != null)
                .concatMap(event -> {
                    try {
                        Map<String, Object> chunk = objectMapper.readValue(event.data(), Map.class);
                        List<Map<String, Object>> choices = (List<Map<String, Object>>) chunk.get("choices");
                        if (choices == null || choices.isEmpty()) {
                            return Flux.empty();
                        }
                        Map<String, Object> choice = choices.get(0);

                        // Capture finish_reason if present
                        if (choice.get("finish_reason") != null) {
                            finalFinishReason.set(mapFinishReason((String) choice.get("finish_reason")));
                        }

                        Map<String, Object> delta = (Map<String, Object>) choice.get("delta");
                        if (delta == null) {
                            // This is the final usage-only chunk from vLLM (choices is empty)
                            Map<String, Object> usageChunk = (Map<String, Object>) chunk.get("usage");
                            if (usageChunk != null) {
                                inputTokensRef.set(((Number) usageChunk.getOrDefault("prompt_tokens", 0)).intValue());
                                outputTokensRef.set(((Number) usageChunk.getOrDefault("completion_tokens", 0)).intValue());
                            }
                            return Flux.empty();
                        }

                        List<String> outEvents = new ArrayList<>();

                        // Text delta
                        if (delta.get("content") instanceof String text && !text.isEmpty()) {
                            if (textBlockIndex.get() == -1) {
                                int idx = nextBlockIndex.getAndIncrement();
                                textBlockIndex.set(idx);
                                outEvents.add(buildTextBlockStartEvent(idx));
                            }
                            outEvents.add(buildTextDeltaEvent(textBlockIndex.get(), text));
                        }

                        // Tool call deltas
                        @SuppressWarnings("unchecked")
                        List<Map<String, Object>> toolCalls = (List<Map<String, Object>>) delta.get("tool_calls");
                        if (toolCalls != null) {
                            for (Map<String, Object> tc : toolCalls) {
                                int toolCallIdx = ((Number) tc.get("index")).intValue();
                                Map<Integer, Integer> indexMap = toolBlockIndexMap.get();

                                if (!indexMap.containsKey(toolCallIdx)) {
                                    // First chunk for this tool call — emit content_block_start
                                    int blockIdx = nextBlockIndex.getAndIncrement();
                                    indexMap.put(toolCallIdx, blockIdx);
                                    toolBlockIndexMap.set(indexMap);
                                    @SuppressWarnings("unchecked")
                                    Map<String, Object> fn = (Map<String, Object>) tc.get("function");
                                    String toolId = (String) tc.get("id");
                                    String toolName = fn != null ? (String) fn.get("name") : "";
                                    outEvents.add(buildToolUseBlockStartEvent(blockIdx, toolId, toolName));
                                    // Also emit initial arguments if present
                                    if (fn != null && fn.get("arguments") instanceof String args && !args.isEmpty()) {
                                        outEvents.add(buildInputJsonDeltaEvent(blockIdx, args));
                                    }
                                } else {
                                    // Subsequent chunk — emit input_json_delta
                                    int blockIdx = indexMap.get(toolCallIdx);
                                    @SuppressWarnings("unchecked")
                                    Map<String, Object> fn = (Map<String, Object>) tc.get("function");
                                    if (fn != null && fn.get("arguments") instanceof String args && !args.isEmpty()) {
                                        outEvents.add(buildInputJsonDeltaEvent(blockIdx, args));
                                    }
                                }
                            }
                        }

                        return Flux.fromIterable(outEvents);
                    } catch (Exception e) {
                        log.error("Error parsing SSE event", e);
                        return Flux.error(e);
                    }
                });

        // Trailing events — close all open blocks, then message_delta/stop
        Flux<String> trailingFlux = Flux.defer(() -> {
            List<String> trailingEvents = new ArrayList<>();
            if (textBlockIndex.get() != -1) trailingEvents.add(buildContentBlockStopEvent(textBlockIndex.get()));
            toolBlockIndexMap.get().values().forEach(idx -> trailingEvents.add(buildContentBlockStopEvent(idx)));
            trailingEvents.add(buildMessageDeltaEvent(finalFinishReason.get(), inputTokensRef.get(), outputTokensRef.get()));
            trailingEvents.add(buildMessageStopEvent());
            return Flux.fromIterable(trailingEvents);
        });

        // assemble the complete Anthropic SSE sequence
        final long startTimeRef = startTime;
        Flux<String> sseFlux = Flux.concat(
            Flux.just(buildMessageStartEvent(messageId, modelName)),
            deltaFlux,
            trailingFlux
        )
        .onErrorResume(e -> {
            long latencyMs = System.currentTimeMillis() - startTimeRef;
            int statusCode = (e instanceof VllmHttpException ve) ? ve.getStatus() : 500;
            metricsService.recordLlmResponse(modelName, latencyMs, statusCode, true);
            log.error("❌ Stream error for model [{}]: {}", modelName, e.getMessage());
            return Flux.just(buildSseErrorEvent(e.getMessage(), statusCode));  // emit Anthropic error event, then stream closes cleanly
        })
        .doOnComplete(() -> {
            long latencyMs = System.currentTimeMillis() - startTimeRef;
            metricsService.recordLlmResponse(modelName, latencyMs, 200, true);
            log.info("✅ Stream completed for model [{}] in {}ms", modelName, latencyMs);
        });

        return ResponseEntity.ok()
                .contentType(MediaType.TEXT_EVENT_STREAM)
                .body(sseFlux);
    }

    /**
     * Build Anthropic message_start SSE event.
     */
    private String buildMessageStartEvent(String messageId, String modelName) {
        try {
            Map<String, Object> messageStartEvent = new LinkedHashMap<>();
            messageStartEvent.put("type", "message_start");
            Map<String, Object> msgMeta = new LinkedHashMap<>();
            msgMeta.put("id", messageId);
            msgMeta.put("type", "message");
            msgMeta.put("role", "assistant");
            msgMeta.put("content", List.of());
            msgMeta.put("model", modelName);
            msgMeta.put("stop_reason", null);
            msgMeta.put("usage", Map.of("input_tokens", 0, "output_tokens", 0));
            messageStartEvent.put("message", msgMeta);
            return "event: message_start\ndata: " + objectMapper.writeValueAsString(messageStartEvent) + "\n\n";
        } catch (Exception e) {
            log.error("Error building message_start event", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Build Anthropic content_block_start SSE event for text block.
     */
    private String buildTextBlockStartEvent(int index) {
        try {
            Map<String, Object> blockStart = new LinkedHashMap<>();
            blockStart.put("type", "content_block_start");
            blockStart.put("index", index);
            blockStart.put("content_block", Map.of("type", "text", "text", ""));
            return "event: content_block_start\ndata: " + objectMapper.writeValueAsString(blockStart) + "\n\n";
        } catch (Exception e) {
            log.error("Error building text_block_start event", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Build Anthropic content_block_start SSE event for tool_use block.
     */
    private String buildToolUseBlockStartEvent(int index, String id, String name) {
        try {
            Map<String, Object> blockStart = new LinkedHashMap<>();
            blockStart.put("type", "content_block_start");
            blockStart.put("index", index);
            blockStart.put("content_block", Map.of("type", "tool_use", "id", id, "name", name, "input", new LinkedHashMap<>()));
            return "event: content_block_start\ndata: " + objectMapper.writeValueAsString(blockStart) + "\n\n";
        } catch (Exception e) {
            log.error("Error building tool_use_block_start event", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Build Anthropic content_block_delta SSE event for text delta.
     */
    private String buildTextDeltaEvent(int index, String text) {
        try {
            Map<String, Object> blockDelta = new LinkedHashMap<>();
            blockDelta.put("type", "content_block_delta");
            blockDelta.put("index", index);
            blockDelta.put("delta", Map.of("type", "text_delta", "text", text));
            return "event: content_block_delta\ndata: " + objectMapper.writeValueAsString(blockDelta) + "\n\n";
        } catch (Exception e) {
            log.error("Error building text_delta event", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Build Anthropic content_block_delta SSE event for input_json_delta (tool arguments).
     */
    private String buildInputJsonDeltaEvent(int index, String partialJson) {
        try {
            Map<String, Object> blockDelta = new LinkedHashMap<>();
            blockDelta.put("type", "content_block_delta");
            blockDelta.put("index", index);
            blockDelta.put("delta", Map.of("type", "input_json_delta", "partial_json", partialJson));
            return "event: content_block_delta\ndata: " + objectMapper.writeValueAsString(blockDelta) + "\n\n";
        } catch (Exception e) {
            log.error("Error building input_json_delta event", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Build Anthropic content_block_stop SSE event.
     */
    private String buildContentBlockStopEvent(int index) {
        try {
            Map<String, Object> blockStop = new LinkedHashMap<>();
            blockStop.put("type", "content_block_stop");
            blockStop.put("index", index);
            return "event: content_block_stop\ndata: " + objectMapper.writeValueAsString(blockStop) + "\n\n";
        } catch (Exception e) {
            log.error("Error building content_block_stop event", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Build Anthropic message_delta SSE event.
     */
    private String buildMessageDeltaEvent(String finishReason, int inputTokens, int outputTokens) {
        try {
            Map<String, Object> msgDelta = new LinkedHashMap<>();
            msgDelta.put("type", "message_delta");
            Map<String, Object> delta = new LinkedHashMap<>();
            delta.put("stop_reason", finishReason);
            delta.put("stop_sequence", null);
            msgDelta.put("delta", delta);
            msgDelta.put("usage", Map.of("input_tokens", inputTokens, "output_tokens", outputTokens));
            return "event: message_delta\ndata: " + objectMapper.writeValueAsString(msgDelta) + "\n\n";
        } catch (Exception e) {
            log.error("Error building message_delta event", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Build Anthropic message_stop SSE event.
     */
    private String buildMessageStopEvent() {
        try {
            Map<String, Object> msgStop = new LinkedHashMap<>();
            msgStop.put("type", "message_stop");
            return "event: message_stop\ndata: " + objectMapper.writeValueAsString(msgStop) + "\n\n";
        } catch (Exception e) {
            log.error("Error building message_stop event", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Build Anthropic error SSE event (graceful error handling in streams).
     * Emitted when an error occurs mid-stream instead of crashing the connection.
     */
    private String buildSseErrorEvent(String message, int statusCode) {
        try {
            Map<String, Object> errorEvent = new LinkedHashMap<>();
            errorEvent.put("type", "error");
            Map<String, Object> error = new LinkedHashMap<>();
            String errType = statusCode >= 500 ? "api_error" : "invalid_request_error";
            error.put("type", errType);
            error.put("message", message != null ? message : "Unknown error");
            errorEvent.put("error", error);
            return "event: error\ndata: " + objectMapper.writeValueAsString(errorEvent) + "\n\n";
        } catch (Exception e) {
            // Fallback to hardcoded JSON if serialization fails
            return "event: error\ndata: {\"type\":\"error\",\"error\":{\"type\":\"api_error\",\"message\":\"Internal error\"}}\n\n";
        }
    }

    /**
     * Build Anthropic-conforming error response body.
     * Schema: {"type": "error", "error": {"type": "...", "message": "..."}}
     */
    private Map<String, Object> anthropicError(String type, String message) {
        Map<String, Object> error = new LinkedHashMap<>();
        error.put("type", type);
        error.put("message", message);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("type", "error");
        body.put("error", error);
        return body;
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
