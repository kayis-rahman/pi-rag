package com.synapse.llm.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.MediaType;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.reactive.function.client.ClientRequest;
import org.springframework.web.reactive.function.client.ClientResponse;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * E2E test for SSE multi-turn conversation with Anthropic-compatible /v1/messages endpoint.
 * Tests 5 turns of back-and-forth conversation to verify streaming works correctly.
 *
 * Run with: ./gradlew :app:e2eSseConversation
 */
public class E2eSseConversationTest {

    private static final String API_BASE_URL = System.getenv("API_BASE_URL") != null
            ? System.getenv("API_BASE_URL")
            : "http://localhost:8080";

    private static final String MODEL_NAME = "claude-haiku-4-5-20251001";

    private static final ObjectMapper objectMapper = new ObjectMapper();

    public static void main(String[] args) throws Exception {
        System.out.println("╔════════════════════════════════════════════════════════════════╗");
        System.out.println("║     E2E SSE Multi-Turn Conversation Test                      ║");
        System.out.println("╚════════════════════════════════════════════════════════════════╝");
        System.out.println();
        System.out.println("API Base URL: " + API_BASE_URL);
        System.out.println("Model: " + MODEL_NAME);
        System.out.println();

        WebClient webClient = createWebClient();

        // Conversation turns - 5 back and forth
        List<Map<String, Object>> conversationHistory = new ArrayList<>();

        String[] turns = {
                "Hello, can you help me write code?",
                "I need a Python function to sort a list.",
                "Can you add error handling for invalid inputs?",
                "What if the list is empty or contains None values?",
                "Thanks, that's very helpful!"
        };

        int passed = 0;
        int failed = 0;

        for (int i = 0; i < turns.length; i++) {
            String userMessage = turns[i];

            // Add user message to history
            conversationHistory.add(Map.of(
                    "role", "user",
                    "content", userMessage
            ));

            System.out.println("Turn " + (i + 1) + ": " + userMessage);

            try {
                ConversationResult result = runSseConversation(
                        webClient,
                        conversationHistory,
                        MODEL_NAME
                );

                if (result.isValid) {
                    System.out.println("  ✓ SSE stream received (" + result.eventCount + " events)");
                    System.out.println("  ✓ message_start event present");
                    System.out.println("  ✓ content_block_delta events received (" + result.deltaCount + " chunks)");
                    System.out.println("  ✓ message_stop event present");
                    System.out.println("  ✓ Total tokens: " + result.inputTokens + " input, " + result.outputTokens + " output");
                    System.out.println("  ✓ Response preview: " + truncate(result.fullContent, 80));
                    System.out.println();
                    passed++;
                } else {
                    System.out.println("  ❌ Invalid SSE stream format");
                    System.out.println();
                    failed++;
                }

                // Add assistant response to history
                conversationHistory.add(Map.of(
                        "role", "assistant",
                        "content", result.fullContent
                ));

            } catch (Exception e) {
                System.out.println("  ❌ ERROR: " + e.getMessage());
                System.out.println();
                failed++;
            }

            // Small delay between turns
            Thread.sleep(500);
        }

        // Summary
        System.out.println("╔════════════════════════════════════════════════════════════════╗");
        System.out.println("║                     Test Summary                               ║");
        System.out.println("╚════════════════════════════════════════════════════════════════╝");
        System.out.println();
        System.out.println("Total turns: " + turns.length);
        System.out.println("Passed: " + passed);
        System.out.println("Failed: " + failed);
        System.out.println();

        if (failed == 0) {
            System.out.println("✅ All " + turns.length + " turns passed!");
            System.exit(0);
        } else {
            System.out.println("❌ " + failed + " turn(s) failed!");
            System.exit(1);
        }
    }

    private static WebClient createWebClient() {
        HttpClient httpClient = HttpClient.create()
                .responseTimeout(Duration.ofSeconds(120))
                .compress(true);

        return WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .build();
    }

    private static ConversationResult runSseConversation(
            WebClient webClient,
            List<Map<String, Object>> messages,
            String model
    ) throws Exception {

        Map<String, Object> request = Map.of(
                "model", model,
                "messages", messages,
                "max_tokens", 512,
                "temperature", 0.7,
                "stream", true
        );

        String requestBody = objectMapper.writeValueAsString(request);

        final boolean[] isValid = {false};
        final int[] eventCount = {0};
        final int[] deltaCount = {0};
        final int[] inputTokens = {0};
        final int[] outputTokens = {0};
        final StringBuilder fullContent = new StringBuilder();

        final boolean[] hasMessageStart = {false};
        final boolean[] hasContentBlockStart = {false};
        final boolean[] hasMessageStop = {false};
        final boolean[] hasContentBlockStop = {false};

        webClient.post()
                .uri(API_BASE_URL + "/v1/messages")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(requestBody)
                .retrieve()
                .bodyToFlux(ServerSentEvent.class)
                .doOnNext(event -> {
                    eventCount[0]++;
                    Object dataObj = event.data();
                    String data = dataObj != null ? dataObj.toString() : "";

                    try {
                        JsonNode json = objectMapper.readTree(data);

                        String type = json.has("type") ? json.get("type").asText() : "";

                        switch (type) {
                            case "message_start":
                                hasMessageStart[0] = true;
                                break;
                            case "content_block_start":
                                hasContentBlockStart[0] = true;
                                break;
                            case "content_block_delta":
                                deltaCount[0]++;
                                if (json.has("delta") && json.get("delta").has("text")) {
                                    fullContent.append(json.get("delta").get("text").asText());
                                }
                                break;
                            case "content_block_stop":
                                hasContentBlockStop[0] = true;
                                break;
                            case "message_delta":
                                if (json.has("usage")) {
                                    JsonNode usage = json.get("usage");
                                    if (usage.has("output_tokens")) {
                                        outputTokens[0] = usage.get("output_tokens").asInt();
                                    }
                                }
                                break;
                            case "message_stop":
                                hasMessageStop[0] = true;
                                if (json.has("message") && json.get("message").has("usage")) {
                                    JsonNode usage = json.get("message").get("usage");
                                    if (usage.has("input_tokens")) {
                                        inputTokens[0] = usage.get("input_tokens").asInt();
                                    }
                                    if (usage.has("output_tokens")) {
                                        outputTokens[0] = usage.get("output_tokens").asInt();
                                    }
                                }
                                break;
                        }
                    } catch (Exception e) {
                        // Ignore parsing errors for non-JSON events
                    }
                })
                .doOnError(error -> System.err.println("SSE Stream error: " + error.getMessage()))
                .blockLast();

        isValid[0] = hasMessageStart[0] && hasContentBlockStart[0] &&
                hasContentBlockStop[0] && hasMessageStop[0] &&
                deltaCount[0] > 0;

        return new ConversationResult(
                isValid[0],
                eventCount[0],
                deltaCount[0],
                inputTokens[0],
                outputTokens[0],
                fullContent.toString()
        );
    }

    private static String truncate(String s, int maxLength) {
        if (s == null || s.length() <= maxLength) {
            return s;
        }
        return s.substring(0, maxLength) + "...";
    }

    private record ConversationResult(
            boolean isValid,
            int eventCount,
            int deltaCount,
            int inputTokens,
            int outputTokens,
            String fullContent
    ) {
    }
}
