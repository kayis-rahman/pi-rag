package com.synapse.llm.api;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.reactive.server.WebTestClient.*;

import com.synapse.llm.routing.ModelChoice;
import com.synapse.llm.routing.RoutingAwareChatModel;
import com.synapse.llm.routing.RoutingDecision;
import lombok.RequiredArgsConstructor;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.AutoConfigureWebTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.reactive.server.WebTestClient;

/**
 * Integration tests for ChatController and intelligent model routing system.
 * Tests all routing rules, fallback behavior, and API contract.
 */
@SpringBootTest
@AutoConfigureWebTestClient
@DisplayName("ChatController Integration Tests")
public class ChatControllerIntegrationTest {

    @Autowired
    private WebTestClient webTestClient;

    @Autowired
    private RoutingAwareChatModel routingAwareChatModel;

    private static final String ENDPOINT = "/api/chat/sync";

    @Nested
    @DisplayName("Basic Connectivity Tests")
    class BasicConnectivityTests {

        @Test
        @DisplayName("Should accept valid chat request")
        void testValidChatRequest() {
            var request = new ChatController.ChatRequest("auto", "Hello");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectHeader().contentType(MediaType.APPLICATION_JSON);
        }

        @Test
        @DisplayName("Response should contain required fields")
        void testResponseStructure() {
            var request = new ChatController.ChatRequest("auto", "test");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.response").exists()
                    .jsonPath("$.routing_decision").exists()
                    .jsonPath("$.routing_decision.tier").exists()
                    .jsonPath("$.routing_decision.reason").exists()
                    .jsonPath("$.routing_decision.server").exists()
                    .jsonPath("$.routing_decision.api_base").exists();
        }

        @Test
        @DisplayName("Should handle empty content")
        void testEmptyContent() {
            var request = new ChatController.ChatRequest("auto", "");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision").exists();
        }
    }

    @Nested
    @DisplayName("Routing Rule 1: Tool Use → Claude")
    class ToolUseRoutingTests {

        @Test
        @DisplayName("Should route to Claude for tool use mention")
        void testToolUseMention() {
            var request = new ChatController.ChatRequest("auto",
                    "Use the weather tool to check the forecast");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("CLAUDE_API")
                    .jsonPath("$.routing_decision.reason").isEqualTo("tool_use");
        }

        @Test
        @DisplayName("Should route to Claude for function calling mention")
        void testFunctionCallingMention() {
            var request = new ChatController.ChatRequest("auto",
                    "Call the calculator function for this equation");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("CLAUDE_API");
        }
    }

    @Nested
    @DisplayName("Routing Rule 2: Large Context → Claude")
    class LargeContextRoutingTests {

        @Test
        @DisplayName("Should route to Claude for large context")
        void testLargeContextDetection() {
            // Create a large text (>4096 tokens estimated)
            StringBuilder largeText = new StringBuilder();
            for (int i = 0; i < 500; i++) {
                largeText.append("This is a long document with lots of content. ");
            }
            largeText.append("Summarize this.");

            var request = new ChatController.ChatRequest("auto", largeText.toString());

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("CLAUDE_API")
                    .jsonPath("$.routing_decision.reason").isEqualTo("long_context");
        }
    }

    @Nested
    @DisplayName("Routing Rule 3: Code Detection → Qwen")
    class CodeDetectionRoutingTests {

        @Test
        @DisplayName("Should route to Qwen for code block detection")
        void testCodeBlockDetection() {
            var request = new ChatController.ChatRequest("auto",
                    "Fix this bug:\n```python\ndef add(a, b)\n  return a + b\n```");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("QWEN_LOCAL")
                    .jsonPath("$.routing_decision.reason").isEqualTo("code_task");
        }

        @Test
        @DisplayName("Should route to Qwen for code keywords")
        void testCodeKeywordDetection() {
            var request = new ChatController.ChatRequest("auto",
                    "How do I write a python function?");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("QWEN_LOCAL");
        }

        @Test
        @DisplayName("Should route to Qwen for javascript questions")
        void testJavascriptKeywordDetection() {
            var request = new ChatController.ChatRequest("auto",
                    "Debug this javascript error in my code");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("QWEN_LOCAL");
        }
    }

    @Nested
    @DisplayName("Routing Rule 4: Complex Keywords → Claude")
    class ComplexKeywordsRoutingTests {

        @Test
        @DisplayName("Should route to Claude for 'explain' keyword")
        void testExplainKeyword() {
            var request = new ChatController.ChatRequest("auto",
                    "Explain the philosophical implications of quantum mechanics");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("CLAUDE_API")
                    .jsonPath("$.routing_decision.reason").isEqualTo("complex_task");
        }

        @Test
        @DisplayName("Should route to Claude for 'analyze' keyword")
        void testAnalyzeKeyword() {
            var request = new ChatController.ChatRequest("auto",
                    "Analyze the geopolitical implications of recent events");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("CLAUDE_API");
        }
    }

    @Nested
    @DisplayName("Routing Rule 5: Simple Keywords → Qwen")
    class SimpleKeywordsRoutingTests {

        @Test
        @DisplayName("Should route to Qwen for 'capital' keyword")
        void testCapitalKeyword() {
            var request = new ChatController.ChatRequest("auto",
                    "What is the capital of France?");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("QWEN_LOCAL")
                    .jsonPath("$.routing_decision.reason").isEqualTo("simple_retrieval");
        }

        @Test
        @DisplayName("Should route to Qwen for 'definition' keyword")
        void testDefinitionKeyword() {
            var request = new ChatController.ChatRequest("auto",
                    "What is the definition of algorithm?");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("QWEN_LOCAL");
        }
    }

    @Nested
    @DisplayName("Routing Rule 6: Short Query → Qwen")
    class ShortQueryRoutingTests {

        @Test
        @DisplayName("Should route very short query to Qwen")
        void testVeryShortQuery() {
            var request = new ChatController.ChatRequest("auto", "Hello");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("QWEN_LOCAL")
                    .jsonPath("$.routing_decision.reason").isEqualTo("short_query");
        }

        @Test
        @DisplayName("Should route short query (<20 words) to Qwen")
        void testShortQuery() {
            var request = new ChatController.ChatRequest("auto",
                    "Tell me a fact");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("QWEN_LOCAL");
        }
    }

    @Nested
    @DisplayName("Routing Rule 7: Default → Qwen")
    class DefaultRoutingTests {

        @Test
        @DisplayName("Should default to Qwen for generic queries")
        void testDefaultRouting() {
            var request = new ChatController.ChatRequest("auto",
                    "Tell me an interesting fact about history");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision.tier").isEqualTo("QWEN_LOCAL")
                    .jsonPath("$.routing_decision.reason").isEqualTo("default");
        }
    }

    @Nested
    @DisplayName("Error Handling Tests")
    class ErrorHandlingTests {

        @Test
        @DisplayName("Should include routing decision in error responses")
        void testErrorResponseIncludesRoutingContext() {
            var request = new ChatController.ChatRequest("auto", "");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision").exists();
        }

        @Test
        @DisplayName("Should handle missing content field")
        void testMissingContentField() {
            String jsonPayload = "{\"model\":\"auto\"}";

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(jsonPayload)
                    .exchange()
                    .expectStatus().is4xxClientError();
        }

        @Test
        @DisplayName("Should handle invalid JSON")
        void testInvalidJson() {
            String invalidJson = "{\"invalid json}";

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(invalidJson)
                    .exchange()
                    .expectStatus().is4xxClientError();
        }
    }

    @Nested
    @DisplayName("Routing Decision State Tests")
    class RoutingDecisionStateTests {

        @Test
        @DisplayName("lastDecision() should return current decision")
        void testLastDecisionReturnsCurrentRouting() {
            var request = new ChatController.ChatRequest("auto", "code example");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk();

            // Verify lastDecision is accessible and matches response
            RoutingDecision decision = routingAwareChatModel.lastDecision();
            assertNotNull(decision, "Last decision should be available");
            assertNotNull(decision.tier(), "Decision tier should not be null");
            assertNotNull(decision.reason(), "Decision reason should not be null");
        }

        @Test
        @DisplayName("lastDecision() should update after each request")
        void testLastDecisionUpdatesPerRequest() {
            // First request
            var request1 = new ChatController.ChatRequest("auto", "code");
            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request1)
                    .exchange()
                    .expectStatus().isOk();

            RoutingDecision decision1 = routingAwareChatModel.lastDecision();
            ModelChoice choice1 = decision1.tier();

            // Second request (different routing)
            var request2 = new ChatController.ChatRequest("auto",
                    "Explain this complex concept");
            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request2)
                    .exchange()
                    .expectStatus().isOk();

            RoutingDecision decision2 = routingAwareChatModel.lastDecision();
            ModelChoice choice2 = decision2.tier();

            // Decisions should be different
            assertNotEquals(choice1, choice2, "Different queries should produce different routing decisions");
        }
    }

    @Nested
    @DisplayName("Performance & Concurrency Tests")
    class PerformanceTests {

        @Test
        @DisplayName("Should handle rapid sequential requests")
        void testSequentialRequests() {
            for (int i = 0; i < 10; i++) {
                var request = new ChatController.ChatRequest("auto",
                        "Test query " + i);

                webTestClient.post()
                        .uri(ENDPOINT)
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(request)
                        .exchange()
                        .expectStatus().isOk();
            }
        }

        @Test
        @DisplayName("Should maintain response structure under load")
        void testResponseStructureUnderLoad() {
            for (int i = 0; i < 5; i++) {
                var request = new ChatController.ChatRequest("auto",
                        "Load test query " + i);

                webTestClient.post()
                        .uri(ENDPOINT)
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(request)
                        .exchange()
                        .expectStatus().isOk()
                        .expectBody()
                        .jsonPath("$.response").exists()
                        .jsonPath("$.routing_decision.tier").exists()
                        .jsonPath("$.routing_decision.reason").exists();
            }
        }
    }

    @Nested
    @DisplayName("Token Estimation Tests")
    class TokenEstimationTests {

        @Test
        @DisplayName("Should include token count in routing decision")
        void testTokenCountIncluded() {
            var request = new ChatController.ChatRequest("auto",
                    "This is a test query with multiple words");

            webTestClient.post()
                    .uri(ENDPOINT)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(request)
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.routing_decision").exists();

            RoutingDecision decision = routingAwareChatModel.lastDecision();
            assertTrue(decision.estimatedTokens() > 0,
                    "Token count should be greater than 0");
        }
    }
}
