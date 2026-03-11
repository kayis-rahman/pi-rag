package com.synapse.llm.routing;

import static org.junit.jupiter.api.Assertions.*;

import com.synapse.llm.config.LlmConfigurationProperties;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.data.message.AiMessage;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Unit tests for AdaptiveRoutingStrategy.
 * Tests all 7 heuristic rules and edge cases.
 */
public class AdaptiveRoutingStrategyTest {

    private AdaptiveRoutingStrategy strategy;
    private LlmConfigurationProperties.RoutingConfig config;

    @BeforeEach
    public void setUp() {
        config = new LlmConfigurationProperties.RoutingConfig();
        strategy = new AdaptiveRoutingStrategy(config);
    }

    // Rule 1: Tool use (function calling) → CLAUDE_API
    @Test
    public void testToolPresenceRoutesToClaudeApi() {
        List<ChatMessage> messages = List.of(createUserMessage("What time is it?"));

        RoutingDecision decision = strategy.decide(messages, true);

        assertEquals(ModelChoice.CLAUDE_API, decision.modelChoice());
        assertEquals("tool_use", decision.reason());
    }

    @Test
    public void testEmptyToolsRoutesNormally() {
        List<ChatMessage> messages = List.of(createUserMessage("What time is it?"));

        RoutingDecision decision = strategy.decide(messages, false);

        // Should route based on other heuristics, not tools
        assertNotNull(decision);
        assertNotEquals("tool_use", decision.reason());
    }

    // Rule 2: Token budget exceeded → CLAUDE_API
    @Test
    public void testLongContextRoutesToClaudeApi() {
        // Create a message with many words to exceed token budget (4096 * 1.3 = ~3100 words)
        StringBuilder longText = new StringBuilder();
        for (int i = 0; i < 3500; i++) {
            longText.append("word ");
        }
        List<ChatMessage> messages = List.of(createUserMessage(longText.toString()));

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.CLAUDE_API, decision.modelChoice());
        assertEquals("long_context", decision.reason());
    }

    @Test
    public void testTokenEstimation() {
        // 100 words * 1.3 ≈ 130 tokens
        List<ChatMessage> messages = List.of(
                createUserMessage("word ".repeat(100))
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertTrue(decision.estimatedTokens() >= 120 && decision.estimatedTokens() <= 140);
    }

    // Rule 3: Code detection → QWEN_LOCAL
    @Test
    public void testCodeBlockDetectionRoutesToQwen() {
        String queryWithCode = "Can you refactor this code?\n```java\npublic class Test {}\n```";
        List<ChatMessage> messages = List.of(createUserMessage(queryWithCode));

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("code_task", decision.reason());
    }

    @Test
    public void testCodeKeywordDetectionRoutesToQwen() {
        List<ChatMessage> messages = List.of(
                createUserMessage("How do I define a public method in Java?")
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("code_task", decision.reason());
    }

    @Test
    public void testMultipleCodeKeywordsRoutesToQwen() {
        List<ChatMessage> messages = List.of(
                createUserMessage("Write a class with import statements and async functions")
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("code_task", decision.reason());
    }

    // Rule 4: Complex reasoning keywords → CLAUDE_API
    @Test
    public void testComplexKeywordRoutesToClaudeApi() {
        List<ChatMessage> messages = List.of(
                createUserMessage("Can you architect a system to handle distributed transactions?")
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.CLAUDE_API, decision.modelChoice());
        assertEquals("complex_task", decision.reason());
    }

    @Test
    public void testMultipleComplexKeywordsRoutesToClaudeApi() {
        List<ChatMessage> messages = List.of(
                createUserMessage("Help me refactor and optimize this design for better performance")
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.CLAUDE_API, decision.modelChoice());
        assertEquals("complex_task", decision.reason());
    }

    // Rule 5: Simple retrieval keywords → QWEN_LOCAL
    @Test
    public void testSimpleKeywordRoutesToQwen() {
        List<ChatMessage> messages = List.of(
                createUserMessage("What is the capital of France?")
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("simple_retrieval", decision.reason());
    }

    @Test
    public void testListTheKeywordRoutesToQwen() {
        List<ChatMessage> messages = List.of(
                createUserMessage("List the planets in our solar system")
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("simple_retrieval", decision.reason());
    }

    // Rule 6: Short query → QWEN_LOCAL
    @Test
    public void testShortQueryRoutesToQwen() {
        List<ChatMessage> messages = List.of(
                createUserMessage("Hello how are you?")  // 4 words < 20
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("short_query", decision.reason());
    }

    @Test
    public void testBoundaryQueryAtThresholdRoutesToComplex() {
        // Create a query with exactly 20 words (at threshold, should not trigger short_query)
        String query = "word ".repeat(20).trim();
        List<ChatMessage> messages = List.of(createUserMessage(query));

        RoutingDecision decision = strategy.decide(messages, null);

        assertNotEquals("short_query", decision.reason());
    }

    @Test
    public void testBoundaryQueryBeforeThresholdRoutesToQwen() {
        // Create a query with 19 words (below threshold)
        String query = "word ".repeat(19).trim();
        List<ChatMessage> messages = List.of(createUserMessage(query));

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("short_query", decision.reason());
    }

    // Rule 7: Default → QWEN_LOCAL
    @Test
    public void testDefaultRoutesToQwen() {
        List<ChatMessage> messages = List.of(
                createUserMessage("Tell me about the history of Europe between 1500 and 1700")
        );

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("default", decision.reason());
    }

    // Edge cases
    @Test
    public void testEmptyMessagesDefaultsToQwen() {
        List<ChatMessage> messages = new ArrayList<>();

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
    }

    @Test
    public void testNullToolsDefaultsToQwen() {
        List<ChatMessage> messages = List.of(createUserMessage("Simple query"));

        RoutingDecision decision = strategy.decide(messages, null);

        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
    }

    @Test
    public void testMultipleMessagesUsesLastUserMessage() {
        List<ChatMessage> messages = List.of(
                createUserMessage("First message"),
                createAssistantMessage("Response"),
                createUserMessage("What is the capital of France?")  // Last user message should be used
        );

        RoutingDecision decision = strategy.decide(messages, null);

        // Should route based on last message (simple keyword)
        assertEquals(ModelChoice.QWEN_LOCAL, decision.modelChoice());
        assertEquals("simple_retrieval", decision.reason());
    }

    @Test
    public void testPriorityOrderToolUseOverComplex() {
        List<ChatMessage> messages = List.of(
                createUserMessage("Can you architect a system?")  // Complex keyword
        );

        RoutingDecision decision = strategy.decide(messages, true);  // Has tools

        // Tool use has priority over complex reasoning
        assertEquals(ModelChoice.CLAUDE_API, decision.modelChoice());
        assertEquals("tool_use", decision.reason());
    }

    @Test
    public void testPriorityOrderLongContextOverCode() {
        // Very long message with code
        StringBuilder longText = new StringBuilder();
        for (int i = 0; i < 3500; i++) {
            longText.append("word ");
        }
        longText.append("```java\npublic class Test {}\n```");

        List<ChatMessage> messages = List.of(createUserMessage(longText.toString()));

        RoutingDecision decision = strategy.decide(messages, null);

        // Long context has priority over code detection
        assertEquals(ModelChoice.CLAUDE_API, decision.modelChoice());
        assertEquals("long_context", decision.reason());
    }

    // Helper methods
    private ChatMessage createUserMessage(String text) {
        return UserMessage.from(text);
    }

    private ChatMessage createAssistantMessage(String text) {
        return AiMessage.from(text);
    }

}
