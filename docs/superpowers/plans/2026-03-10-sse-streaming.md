# SSE Streaming for /v1/messages and /v1/chat/completions Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement proper SSE streaming support for both Anthropic-compatible `/v1/messages` endpoint and new OpenAI-compatible `/v1/chat/completions` endpoint.

**Architecture:** Replace blocking `HttpClient` with Spring's reactive `WebClient` for non-blocking SSE streaming. Create unified streaming handler to avoid code duplication between endpoints.

**Tech Stack:** Spring WebFlux, WebClient, Reactor, Jackson

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java` | Modify | Add `/v1/chat/completions` endpoint, fix streaming to use WebClient |
| `app/src/test/java/com/synapse/llm/api/AnthropicCompatibleControllerTest.java` | Create | Unit tests for both endpoints (streaming and non-streaming) |
| `app/src/test/java/com/synapse/llm/api/ApiIntegrationTest.java` | Modify | Integration tests with curl-style verification |

---

## Task 1: Add WebClient Dependency Injection

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java`

- [ ] **Step 1: Add WebClient field**

Add `WebClient` field to class:
```java
private final WebClient webClient;

public AnthropicCompatibleController(LlmConfigurationProperties config) {
    this.config = config;
    this.webClient = WebClient.builder().build();
}
```

- [ ] **Step 2: Run compilation**

```bash
./gradlew compileJava
```
Expected: PASS - No errors

- [ ] **Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java
git commit -m "feat: add WebClient for reactive HTTP calls"
```

---

## Task 2: Refactor Streaming to Use WebClient

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java:268-383`

- [ ] **Step 1: Write test for streaming behavior first**

Create temporary test to verify current behavior before refactoring.

- [ ] **Step 2: Replace HttpClient with WebClient in streamMessages**

Replace lines 281-378 with WebClient-based streaming:
```java
private ResponseEntity<?> streamMessages(Map<String, Object> anthropicRequest) throws Exception {
    Map<String, Object> openaiRequest = translateAnthropicToOpenAI(anthropicRequest);
    openaiRequest.put("stream", true);

    String vllmUrl = config.getQwen().getBaseUrl() + "/chat/completions";
    String requestBody = objectMapper.writeValueAsString(openaiRequest);
    String clientModel = (String) anthropicRequest.get("model");
    String modelName = clientModel != null ? clientModel : config.getQwen().getModelName();
    long timeoutSeconds = config.getQwen().getTimeoutSeconds();

    log.info("🌊 Streaming to vLLM: {} with {} messages", vllmUrl,
             ((List<?>) openaiRequest.get("messages")).size());

    String messageId = "msg-" + UUID.randomUUID().toString().substring(0, 8);

    Flux<ServerSentEvent<String>> sseFlux = webClient.post()
        .uri(vllmUrl)
        .contentType(MediaType.APPLICATION_JSON)
        .bodyValue(requestBody)
        .retrieve()
        .bodyToFlux(String.class)
        .doOnCancel(() -> log.info("🚫 SSE stream cancelled by client"))
        .doOnError(error -> log.error("🔴 SSE stream error", error))
        .map(sseChunk -> parseAndTransformSseChunk(sseChunk, messageId, modelName, openaiRequest))
        .onErrorResume(error -> {
            log.error("Error in streaming", error);
            return Flux.error(error);
        });

    return ResponseEntity.ok()
        .contentType(MediaType.TEXT_EVENT_STREAM)
        .body(sseFlux);
}
```

- [ ] **Step 3: Add helper method parseAndTransformSseChunk**

Add new method after `createSseEvent`:
```java
private ServerSentEvent<String> parseAndTransformSseChunk(
    String sseChunk, String messageId, String modelName, Map<String, Object> openaiRequest) throws JsonProcessingException {

    // Parse vLLM OpenAI SSE format
    Map<String, Object> chunk = objectMapper.readValue(sseChunk, Map.class);
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> choices = (List<Map<String, Object>>) chunk.get("choices");

    if (choices == null || choices.isEmpty()) {
        return null; // Skip empty chunks
    }

    Map<String, Object> choice = choices.get(0);
    @SuppressWarnings("unchecked")
    Map<String, Object> delta = (Map<String, Object>) choice.get("delta");
    String finishReason = (String) choice.get("finish_reason");

    // Track state for proper Anthropic event sequencing
    // Return appropriate Anthropic SSE event based on content and finish_reason
}
```

- [ ] **Step 4: Run compilation**

```bash
./gradlew compileJava
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java
git commit -m "refactor: replace HttpClient with WebClient for non-blocking streaming"
```

---

## Task 3: Add /v1/chat/completions Endpoint

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java`

- [ ] **Step 1: Add new endpoint method**

Add after `messages` method (around line 86):
```java
@PostMapping("/chat/completions")
public ResponseEntity<?> chatCompletions(@RequestBody String rawBody) {
    try {
        log.info("📨 /v1/chat/completions - Received OpenAI format request");

        if (rawBody == null || rawBody.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Request body required"));
        }

        Map<String, Object> openaiRequest = objectMapper.readValue(rawBody, Map.class);

        // Check if client wants streaming
        boolean wantsStream = Boolean.TRUE.equals(openaiRequest.get("stream"));
        if (wantsStream) {
            return streamChatCompletions(openaiRequest);
        }

        // Forward to vLLM (no translation needed - already OpenAI format)
        String openaiResponse = forwardToVllm(openaiRequest);

        return ResponseEntity.ok(objectMapper.readTree(openaiResponse));

    } catch (Exception e) {
        log.error("Error processing OpenAI API request", e);
        return ResponseEntity.status(400).body(Map.of(
            "error", e.getMessage(),
            "type", e.getClass().getSimpleName()
        ));
    }
}

private ResponseEntity<?> streamChatCompletions(Map<String, Object> openaiRequest) throws Exception {
    openaiRequest.put("stream", true);

    String vllmUrl = config.getQwen().getBaseUrl() + "/chat/completions";
    String requestBody = objectMapper.writeValueAsString(openaiRequest);
    long timeoutSeconds = config.getQwen().getTimeoutSeconds();

    log.info("🌊 Streaming to vLLM (OpenAI format): {} with {} messages", vllmUrl,
             ((List<?>) openaiRequest.get("messages")).size());

    Flux<ServerSentEvent<String>> sseFlux = webClient.post()
        .uri(vllmUrl)
        .contentType(MediaType.APPLICATION_JSON)
        .bodyValue(requestBody)
        .retrieve()
        .bodyToFlux(String.class)
        .doOnCancel(() -> log.info("🚫 SSE stream cancelled by client"))
        .doOnError(error -> log.error("🔴 SSE stream error", error))
        .map(chunk -> {
            try {
                if ("[DONE]".equals(chunk.trim())) {
                    return ServerSentEvent.builder("[DONE]")
                        .event("done")
                        .build();
                }
                return ServerSentEvent.builder(chunk)
                    .event("message")
                    .build();
            } catch (Exception e) {
                log.error("Error parsing SSE chunk", e);
                return null;
            }
        })
        .filter(Objects::nonNull)
        .onErrorResume(error -> {
            log.error("Error in streaming", error);
            return Flux.error(error);
        });

    return ResponseEntity.ok()
        .contentType(MediaType.TEXT_EVENT_STREAM)
        .body(sseFlux);
}
```

- [ ] **Step 2: Run compilation**

```bash
./gradlew compileJava
```
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java
git commit -m "feat: add /v1/chat/completions OpenAI-compatible endpoint"
```

---

## Task 4: Add Usage Tracking in Streaming

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java`

- [ ] **Step 1: Add usage parsing in streamMessages**

Modify `parseAndTransformSseChunk` to extract usage from final chunk:
```java
// When finish_reason is present, also extract usage
Map<String, Object> usage = (Map<String, Object>) chunk.get("usage");
if (usage != null) {
    // Include in message_delta event
    deltaMap.put("usage", Map.of(
        "input_tokens", usage.get("prompt_tokens"),
        "output_tokens", usage.get("completion_tokens")
    ));
}
```

- [ ] **Step 2: Run compilation**

```bash
./gradlew compileJava
```
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/api/AnthropicCompatibleController.java
git commit -m "fix: add usage tracking to streaming responses"
```

---

## Task 5: Create Unit Tests

**Files:**
- Create: `app/src/test/java/com/synapse/llm/api/AnthropicCompatibleControllerTest.java`

- [ ] **Step 1: Write test class structure**

```java
@SpringBootTest
@AutoConfigureWebTestClient
class AnthropicCompatibleControllerTest {

    @MockBean
    private LlmConfigurationProperties config;

    @Autowired
    private WebTestClient webTestClient;

    @Test
    void testMessagesNonStreaming() throws Exception {
        // Test /v1/messages non-streaming
    }

    @Test
    void testMessagesStreaming() throws Exception {
        // Test /v1/messages streaming with Anthropic format
    }

    @Test
    void testChatCompletionsNonStreaming() throws Exception {
        // Test /v1/chat/completions non-streaming
    }

    @Test
    void testChatCompletionsStreaming() throws Exception {
        // Test /v1/chat/completions streaming with OpenAI format
    }
}
```

- [ ] **Step 2: Run tests**

```bash
./gradlew test --tests AnthropicCompatibleControllerTest
```
Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
git add app/src/test/java/com/synapse/llm/api/AnthropicCompatibleControllerTest.java
git commit -m "feat: add unit tests for streaming endpoints"
```

---

## Task 6: Add Integration Tests

**Files:**
- Modify: `app/src/test/java/com/synapse/llm/api/ApiIntegrationTest.java`

- [ ] **Step 1: Add streaming integration tests**

```java
@Test
void testMessagesStreaming() throws Exception {
    // curl -N -X POST http://localhost:8080/v1/messages -d '{"stream":true,...}'
}

@Test
void testChatCompletionsStreaming() throws Exception {
    // curl -N -X POST http://localhost:8080/v1/chat/completions -d '{"stream":true,...}'
}
```

- [ ] **Step 2: Run integration tests**

```bash
./gradlew test --tests ApiIntegrationTest
```
Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
git add app/src/test/java/com/synapse/llm/api/ApiIntegrationTest.java
git commit -m "feat: add integration tests for streaming endpoints"
```

---

## Task 7: Manual Verification

- [ ] **Step 1: Start application**

```bash
./gradlew bootRun
```
Expected: Application starts without errors

- [ ] **Step 2: Test /v1/messages streaming**

```bash
curl -N -X POST http://localhost:8080/v1/messages \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 100,
    "stream": true
  }'
```
Expected: Anthropic SSE format with `message_start`, `content_block_delta`, `message_delta`, `message_stop`

- [ ] **Step 3: Test /v1/chat/completions streaming**

```bash
curl -N -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 100,
    "stream": true
  }'
```
Expected: OpenAI SSE format with `delta.content` chunks and `[DONE]`

- [ ] **Step 4: Verify existing endpoints unchanged**

```bash
curl -X POST http://localhost:8080/api/chat/sync \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello"}]}'
```
Expected: Existing `/api/chat/sync` still works

---

## Verification Summary

1. ✅ Build succeeds - `./gradlew build`
2. ✅ Application starts - No errors in logs
3. ✅ `/v1/messages` streaming - Anthropic SSE format
4. ✅ `/v1/chat/completions` streaming - OpenAI SSE format
5. ✅ Usage tracking - Token counts in `message_delta` event
6. ✅ Existing endpoints unchanged - `/api/chat/sync` still works
