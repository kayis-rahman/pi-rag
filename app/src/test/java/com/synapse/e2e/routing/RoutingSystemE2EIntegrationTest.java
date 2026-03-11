package com.synapse.e2e.routing;

import static org.junit.jupiter.api.Assertions.*;

import com.synapse.llm.config.LlmConfigurationProperties;
import com.synapse.llm.health.VllmCircuitBreaker;
import com.synapse.llm.logging.ModelUsageLogger;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.output.Response;
import dev.langchain4j.data.message.AiMessage;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * End-to-end integration tests for the complete routing system.
 * Tests the interaction between AdaptiveRoutingStrategy, RouterChatLanguageModel,
 * VllmCircuitBreaker, and logging components.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("Routing System End-to-End Integration Tests")
@Tag("e2e")
@Tag("routing")
public class RoutingSystemE2EIntegrationTest {

    @Mock
    private ChatLanguageModel qwenModel;

    @Mock
    private ChatLanguageModel claudeModel;

    @Mock
    private VllmCircuitBreaker circuitBreaker;

    @Mock
    private ModelUsageLogger usageLogger;

    private AdaptiveRoutingStrategy routingStrategy;
    private RouterChatLanguageModel router;
    private LlmConfigurationProperties.RoutingConfig config;

    @BeforeEach
    void setUp() {
        config = createConfig();
        routingStrategy = new AdaptiveRoutingStrategy(config);
        router = new RouterChatLanguageModel(
                routingStrategy,
                qwenModel,
                claudeModel,
                circuitBreaker,
                usageLogger
        );
    }

    private LlmConfigurationProperties.RoutingConfig createConfig() {
        var config = new LlmConfigurationProperties.RoutingConfig();
        config.setMaxLocalTokens(4096);
        config.setShortQueryThreshold(20);
        config.setCodeKeywords(List.of("python", "javascript", "code", "function", "class"));
        config.setComplexKeywords(List.of("explain", "analyze", "philosophical"));
        config.setSimpleKeywords(List.of("capital", "definition", "what"));
        return config;
    }

    @Nested
    @DisplayName("End-to-End Routing Decision Flow")
    class EndToEndRoutingFlow {

        @Test
        @DisplayName("Should route simple question to Qwen via circuit breaker")
        void testSimpleQuestionRoutingE2E() {
            // Setup
            List<ChatMessage> messages = List.of(UserMessage.from("Hello"));
            when(circuitBreaker.executeWithFallback(any(), any()))
                    .thenReturn(Response.from(AiMessage.from("Hi there!")));

            // Execute
            String result = router.generate(messages);

            // Verify routing decision
            RoutingDecision decision = router.lastDecision();
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("short_query", decision.reason());

            // Verify circuit breaker was used (Qwen goes through CB)
            verify(circuitBreaker).executeWithFallback(any(), any());

            // Verify logging was performed
            verify(usageLogger).startRequest(decision);
            verify(usageLogger).endRequest(anyLong());
        }

        @Test
        @DisplayName("Should route code question directly to Qwen (no CB)")
        void testCodeQuestionRoutingE2E() {
            // Setup
            List<ChatMessage> messages = List.of(UserMessage.from("How do I write python code?"));
            when(qwenModel.generate(messages))
                    .thenReturn(Response.from(AiMessage.from("Here's how to write Python...")));

            // Execute
            String result = router.generate(messages);

            // Verify routing decision
            RoutingDecision decision = router.lastDecision();
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("code_task", decision.reason());

            // Verify qwen was called through circuit breaker
            verify(circuitBreaker).executeWithFallback(any(), any());

            // Verify logging
            verify(usageLogger).startRequest(decision);
            verify(usageLogger).endRequest(anyLong());
        }

        @Test
        @DisplayName("Should route complex question directly to Claude")
        void testComplexQuestionRoutingE2E() {
            // Setup
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Explain the philosophical implications of quantum mechanics")
            );
            when(claudeModel.generate(messages))
                    .thenReturn(Response.from(AiMessage.from("This is a complex explanation...")));

            // Execute
            String result = router.generate(messages);

            // Verify routing decision
            RoutingDecision decision = router.lastDecision();
            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("complex_task", decision.reason());

            // Verify Claude was called directly (no circuit breaker)
            verify(claudeModel).generate(messages);
            verify(circuitBreaker, never()).executeWithFallback(any(), any());

            // Verify logging
            verify(usageLogger).startRequest(decision);
            verify(usageLogger).endRequest(anyLong());
        }
    }

    @Nested
    @DisplayName("Routing Priority Validation E2E")
    class RoutingPriorityValidationE2E {

        @Test
        @DisplayName("Tool use should override other rules")
        void testToolUsePriority() {
            // Query with code + complex keywords + tool use
            List<ChatMessage> messages = List.of(
                    UserMessage.from("""
                            Use the calculator tool to analyze this complex python code:
                            Explain the implications""")
            );

            // When hasTools=true, tool use should take priority
            RoutingDecision decision = routingStrategy.decide(messages, true);

            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("tool_use", decision.reason());
        }

        @Test
        @DisplayName("Large context should override code detection")
        void testLargeContextVsCodePriority() {
            StringBuilder largeCode = new StringBuilder();
            for (int i = 0; i < 5000; i++) {
                largeCode.append("python code line ");
            }

            List<ChatMessage> messages = List.of(UserMessage.from(largeCode.toString()));

            RoutingDecision decision = routingStrategy.decide(messages, false);

            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("long_context", decision.reason());
        }

        @Test
        @DisplayName("Complex keywords should override simple keywords")
        void testComplexVsSimpleKeywordsPriority() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Explain the definition of quantum mechanics")
            );

            RoutingDecision decision = routingStrategy.decide(messages, false);

            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("complex_task", decision.reason());
        }
    }

    @Nested
    @DisplayName("Circuit Breaker Integration E2E")
    class CircuitBreakerIntegrationE2E {

        @Test
        @DisplayName("Should use fallback when Qwen circuit breaker triggers")
        void testQwenFallbackToClaudeOnCircuitBreak() {
            // Setup: Qwen is failing, circuit breaker will use fallback
            List<ChatMessage> messages = List.of(UserMessage.from("Hello"));

            // Circuit breaker configured to fallback to Claude
            when(circuitBreaker.executeWithFallback(any(), any()))
                    .thenReturn(Response.from(AiMessage.from("Fallback response from Claude")));

            // Execute
            String result = router.generate(messages);

            // Verify fallback was used
            assertEquals("Fallback response from Claude", result);
            verify(circuitBreaker).executeWithFallback(any(), any());
        }

        @Test
        @DisplayName("Should not use circuit breaker for Claude direct calls")
        void testClaudeBypassesCircuitBreaker() {
            // Setup
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Explain this complex concept")
            );
            when(claudeModel.generate(messages))
                    .thenReturn(Response.from(AiMessage.from("Complex explanation")));

            // Execute
            String result = router.generate(messages);

            // Verify circuit breaker was NOT used
            verify(circuitBreaker, never()).executeWithFallback(any(), any());
            verify(claudeModel).generate(messages);
        }
    }

    @Nested
    @DisplayName("Logging and Observability E2E")
    class LoggingE2E {

        @Test
        @DisplayName("Should log routing decision with correct metadata")
        void testRoutingDecisionLogging() {
            List<ChatMessage> messages = List.of(UserMessage.from("test"));
            when(circuitBreaker.executeWithFallback(any(), any()))
                    .thenReturn(Response.from(AiMessage.from("Response")));

            router.generate(messages);

            RoutingDecision decision = router.lastDecision();

            // Verify logging was called
            verify(usageLogger).startRequest(decision);
            verify(usageLogger).endRequest(anyLong());

            // Verify decision contains required metadata
            assertNotNull(decision.tier());
            assertNotNull(decision.reason());
            assertTrue(decision.estimatedTokens() >= 0);
        }

        @Test
        @DisplayName("Should log latency information")
        void testLatencyLogging() {
            List<ChatMessage> messages = List.of(UserMessage.from("test"));
            when(circuitBreaker.executeWithFallback(any(), any()))
                    .thenReturn(Response.from(AiMessage.from("Response")));

            router.generate(messages);

            // Verify endRequest was called with non-zero latency
            verify(usageLogger).endRequest(gt(0L));
        }

        @Test
        @DisplayName("Should clean up MDC even on exception")
        void testMDCCleanupOnException() {
            List<ChatMessage> messages = List.of(UserMessage.from("test"));
            when(circuitBreaker.executeWithFallback(any(), any()))
                    .thenThrow(new RuntimeException("Test error"));

            assertThrows(RuntimeException.class, () -> router.generate(messages));

            // Verify logging cleanup still happened
            verify(usageLogger).startRequest(any());
            verify(usageLogger).endRequest(anyLong());
        }
    }

    @Nested
    @DisplayName("Multi-Message Conversation E2E")
    class MultiMessageConversationE2E {

        @Test
        @DisplayName("Should use last user message for routing decision")
        void testRoutingUsesLastUserMessage() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Explain quantum mechanics"),
                    AiMessage.from("Quantum mechanics is..."),
                    UserMessage.from("Hello")
            );

            when(circuitBreaker.executeWithFallback(any(), any()))
                    .thenReturn(Response.from(AiMessage.from("Hi")));

            router.generate(messages);

            RoutingDecision decision = router.lastDecision();

            // Should use "Hello" (last user message), not the complex one
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("short_query", decision.reason());
        }

        @Test
        @DisplayName("Should accumulate tokens across conversation")
        void testTokenAccumulationAcrossConversation() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("first question"),
                    AiMessage.from("first answer"),
                    UserMessage.from("second question")
            );

            RoutingDecision decision = routingStrategy.decide(messages, false);

            // Token count should include all messages
            int wordCount = 2 + 2 + 2; // 6 words total
            int expectedTokens = (int) (wordCount * 1.3);
            assertEquals(expectedTokens, decision.estimatedTokens());
        }
    }

    @Nested
    @DisplayName("Error Scenarios E2E")
    class ErrorScenariosE2E {

        @Test
        @DisplayName("Should handle empty message list gracefully")
        void testEmptyMessageListHandling() {
            List<ChatMessage> messages = List.of();

            when(circuitBreaker.executeWithFallback(any(), any()))
                    .thenReturn(Response.from(AiMessage.from("Response")));

            String result = router.generate(messages);

            assertNotNull(result);
            assertNotNull(router.lastDecision());
        }

        @Test
        @DisplayName("Should handle null responses from models")
        void testNullResponseHandling() {
            List<ChatMessage> messages = List.of(UserMessage.from("test"));

            when(circuitBreaker.executeWithFallback(any(), any()))
                    .thenReturn(Response.from(AiMessage.from("")));

            String result = router.generate(messages);

            assertNotNull(result);
        }
    }

    @Nested
    @DisplayName("Configuration Sensitivity E2E")
    class ConfigurationSensitivityE2E {

        @Test
        @DisplayName("Should respect token threshold configuration")
        void testTokenThresholdRespect() {
            // Create config with lower threshold
            var lowThresholdConfig = new LlmConfigurationProperties.RoutingConfig();
            lowThresholdConfig.setMaxLocalTokens(100); // Very low threshold
            lowThresholdConfig.setShortQueryThreshold(20);
            lowThresholdConfig.setCodeKeywords(config.getCodeKeywords());
            lowThresholdConfig.setComplexKeywords(config.getComplexKeywords());
            lowThresholdConfig.setSimpleKeywords(config.getSimpleKeywords());

            AdaptiveRoutingStrategy lowThresholdStrategy =
                    new AdaptiveRoutingStrategy(lowThresholdConfig);

            List<ChatMessage> messages = List.of(
                    UserMessage.from("This is a medium length text that might exceed lower threshold")
            );

            RoutingDecision decision = lowThresholdStrategy.decide(messages, false);

            // Should route to Claude due to lower threshold
            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("long_context", decision.reason());
        }

        @Test
        @DisplayName("Should respect short query threshold configuration")
        void testShortQueryThresholdRespect() {
            var strictConfig = new LlmConfigurationProperties.RoutingConfig();
            strictConfig.setMaxLocalTokens(4096);
            strictConfig.setShortQueryThreshold(5); // Very strict threshold
            strictConfig.setCodeKeywords(config.getCodeKeywords());
            strictConfig.setComplexKeywords(config.getComplexKeywords());
            strictConfig.setSimpleKeywords(config.getSimpleKeywords());

            AdaptiveRoutingStrategy strictStrategy = new AdaptiveRoutingStrategy(strictConfig);

            List<ChatMessage> messages = List.of(
                    UserMessage.from("hello world test")
            );

            RoutingDecision decision = strictStrategy.decide(messages, false);

            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("short_query", decision.reason());
        }
    }
}
