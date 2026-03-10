package com.synapse.llm.routing;

import static org.junit.jupiter.api.Assertions.*;

import com.synapse.llm.config.LlmConfigurationProperties;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.data.message.AiMessage;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Comprehensive unit tests for AdaptiveRoutingStrategy.
 * Tests all routing rules, edge cases, and priority ordering.
 */
@DisplayName("AdaptiveRoutingStrategy Comprehensive Tests")
public class AdaptiveRoutingStrategyComprehensiveTest {

    private AdaptiveRoutingStrategy strategy;
    private LlmConfigurationProperties.RoutingConfig config;

    @BeforeEach
    void setUp() {
        config = createDefaultConfig();
        strategy = new AdaptiveRoutingStrategy(config);
    }

    private LlmConfigurationProperties.RoutingConfig createDefaultConfig() {
        var config = new LlmConfigurationProperties.RoutingConfig();
        config.setMaxLocalTokens(4096);
        config.setShortQueryThreshold(20);
        config.setCodeKeywords(Arrays.asList("python", "javascript", "java", "code", "function", "class"));
        config.setComplexKeywords(Arrays.asList("explain", "analyze", "philosophical", "geopolitical"));
        config.setSimpleKeywords(Arrays.asList("capital", "definition", "what", "who"));
        return config;
    }

    @Nested
    @DisplayName("Rule 1: Tool Use Detection")
    class ToolUseDetectionTests {

        @Test
        @DisplayName("Should route to Claude when hasTools=true")
        void testToolUseDetection() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Use the calculator tool")
            );

            RoutingDecision decision = strategy.decide(messages, true);

            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("tool_use", decision.reason());
        }

        @Test
        @DisplayName("Tool use should have highest priority")
        void testToolUsePriority() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("python code here ```code block``` use tool for this")
            );

            RoutingDecision decision = strategy.decide(messages, true);

            // Should route to Claude for tool use, even with code present
            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("tool_use", decision.reason());
        }
    }

    @Nested
    @DisplayName("Rule 2: Large Context Detection")
    class LargeContextDetectionTests {

        @Test
        @DisplayName("Should route to Claude when tokens exceed threshold")
        void testLargeContextDetection() {
            StringBuilder largeText = new StringBuilder();
            for (int i = 0; i < 3000; i++) {
                largeText.append("This is a long text. ");
            }

            List<ChatMessage> messages = List.of(
                    UserMessage.from(largeText.toString())
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("long_context", decision.reason());
            assertTrue(decision.estimatedTokens() > config.getMaxLocalTokens());
        }

        @Test
        @DisplayName("Should route to Qwen when tokens are within threshold")
        void testWithinTokenThreshold() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Short text")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertTrue(decision.estimatedTokens() <= config.getMaxLocalTokens());
        }

        @Test
        @DisplayName("Should route to Claude at exact token boundary")
        void testExactTokenBoundary() {
            // Create text that's approximately at the boundary
            int targetWords = (int) (config.getMaxLocalTokens() / 1.3);
            StringBuilder text = new StringBuilder();
            for (int i = 0; i < targetWords + 100; i++) {
                text.append("word ");
            }

            List<ChatMessage> messages = List.of(
                    UserMessage.from(text.toString())
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("long_context", decision.reason());
        }
    }

    @Nested
    @DisplayName("Rule 3: Code Detection")
    class CodeDetectionTests {

        @Test
        @DisplayName("Should detect code blocks with triple backticks")
        void testCodeBlockDetection() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Fix this:\n```python\ndef func():\n  pass\n```")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("code_task", decision.reason());
        }

        @ParameterizedTest
        @ValueSource(strings = {
                "python function",
                "javascript code",
                "write java class",
                "code example",
                "function implementation"
        })
        @DisplayName("Should detect code keywords")
        void testCodeKeywordDetection(String query) {
            List<ChatMessage> messages = List.of(UserMessage.from(query));

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("code_task", decision.reason());
        }

        @Test
        @DisplayName("Code detection should have priority over simple keywords")
        void testCodePriority() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("What is the definition of python code?")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            // Code keyword should take priority over "definition" simple keyword
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("code_task", decision.reason());
        }
    }

    @Nested
    @DisplayName("Rule 4: Complex Keywords Detection")
    class ComplexKeywordsDetectionTests {

        @ParameterizedTest
        @ValueSource(strings = {
                "explain quantum mechanics",
                "analyze geopolitical situation",
                "explain philosophical concepts",
                "analyze the implications"
        })
        @DisplayName("Should detect complex keywords")
        void testComplexKeywordDetection(String query) {
            List<ChatMessage> messages = List.of(UserMessage.from(query));

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("complex_task", decision.reason());
        }

        @Test
        @DisplayName("Complex keywords should have priority over simple keywords")
        void testComplexPriority() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Explain the definition of philosophy")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            // "explain" (complex) should take priority over "definition" (simple)
            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("complex_task", decision.reason());
        }
    }

    @Nested
    @DisplayName("Rule 5: Simple Keywords Detection")
    class SimpleKeywordsDetectionTests {

        @ParameterizedTest
        @ValueSource(strings = {
                "What is the capital of France?",
                "Define algorithm",
                "Who invented the telephone?",
                "What does deterministic mean?"
        })
        @DisplayName("Should detect simple keywords")
        void testSimpleKeywordDetection(String query) {
            List<ChatMessage> messages = List.of(UserMessage.from(query));

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("simple_retrieval", decision.reason());
        }
    }

    @Nested
    @DisplayName("Rule 6: Short Query Detection")
    class ShortQueryDetectionTests {

        @Test
        @DisplayName("Should detect very short queries")
        void testVeryShortQuery() {
            List<ChatMessage> messages = List.of(UserMessage.from("Hello"));

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("short_query", decision.reason());
        }

        @Test
        @DisplayName("Should detect short queries below threshold")
        void testShortQueryBelowThreshold() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Tell me a story")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            int wordCount = countWords("Tell me a story");
            assertTrue(wordCount < config.getShortQueryThreshold());
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("short_query", decision.reason());
        }

        @Test
        @DisplayName("Should not use short_query reason for longer text")
        void testLongerQueryNotShort() {
            StringBuilder longQuery = new StringBuilder();
            for (int i = 0; i < 25; i++) {
                longQuery.append("word ");
            }

            List<ChatMessage> messages = List.of(
                    UserMessage.from(longQuery.toString())
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertNotEquals("short_query", decision.reason());
        }
    }

    @Nested
    @DisplayName("Rule 7: Default Routing")
    class DefaultRoutingTests {

        @Test
        @DisplayName("Should default to Qwen for generic queries")
        void testDefaultRouting() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("Tell me an interesting historical fact")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("default", decision.reason());
        }

        @Test
        @DisplayName("Should default to Qwen when no rules match")
        void testDefaultWhenNoRulesMatch() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("This is a random query with no matching keywords or characteristics")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("default", decision.reason());
        }
    }

    @Nested
    @DisplayName("Edge Cases & Boundary Conditions")
    class EdgeCasesTests {

        @Test
        @DisplayName("Should handle null messages gracefully")
        void testNullMessages() {
            RoutingDecision decision = strategy.decide(List.of(), false);

            assertNotNull(decision);
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
        }

        @Test
        @DisplayName("Should handle empty message list")
        void testEmptyMessageList() {
            RoutingDecision decision = strategy.decide(List.of(), false);

            assertNotNull(decision);
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
        }

        @Test
        @DisplayName("Should handle messages with only whitespace")
        void testWhitespaceOnlyMessages() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("   \n\t  ")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertNotNull(decision);
            assertNotEquals("short_query", decision.reason()); // Should not match as short query
        }

        @Test
        @DisplayName("Should handle mixed case keywords")
        void testMixedCaseKeywords() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("PYTHON Code Example")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("code_task", decision.reason());
        }

        @Test
        @DisplayName("Should handle multi-message conversation")
        void testMultiMessageConversation() {
            List<ChatMessage> messages = Arrays.asList(
                    UserMessage.from("What is python?"),
                    AiMessage.from("Python is a programming language"),
                    UserMessage.from("How do I write a function?")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            // Should use the last user message
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("code_task", decision.reason());
        }

        @Test
        @DisplayName("Should use last user message in conversation")
        void testLastUserMessageExtraction() {
            List<ChatMessage> messages = Arrays.asList(
                    UserMessage.from("explain quantum mechanics"),
                    AiMessage.from("Long complex response..."),
                    UserMessage.from("hello")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            // Should use "hello" (last user message), not the complex one
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("short_query", decision.reason());
        }
    }

    @Nested
    @DisplayName("Token Estimation Tests")
    class TokenEstimationTests {

        @Test
        @DisplayName("Should estimate tokens as wordCount × 1.3")
        void testTokenEstimation() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("hello world test")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            int expectedTokens = (int) (3 * 1.3); // 3 words
            assertEquals(expectedTokens, decision.estimatedTokens());
        }

        @Test
        @DisplayName("Should accumulate tokens across multiple messages")
        void testMultiMessageTokenEstimation() {
            List<ChatMessage> messages = Arrays.asList(
                    UserMessage.from("hello world"),
                    AiMessage.from("response text"),
                    UserMessage.from("follow up")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            int expectedTokens = (int) ((2 + 2 + 2) * 1.3); // 6 words total
            assertEquals(expectedTokens, decision.estimatedTokens());
        }

        @Test
        @DisplayName("Should include token count in decision")
        void testDecisionIncludesTokenCount() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("test query")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            assertTrue(decision.estimatedTokens() > 0);
        }
    }

    @Nested
    @DisplayName("Rule Priority & Ordering Tests")
    class RulePriorityTests {

        @Test
        @DisplayName("Tool use should have highest priority (Rule 1 > others)")
        void testToolUsePriority() {
            // Tool use + code + complex keywords + large context
            List<ChatMessage> messages = List.of(
                    UserMessage.from("""
                            Use the calculator tool to analyze this complex python code:
                            ```python
                            def complex_function():
                                pass
                            ```
                            Explain the implications""")
            );

            RoutingDecision decision = strategy.decide(messages, true);

            // Should route to Claude for tool use (highest priority)
            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("tool_use", decision.reason());
        }

        @Test
        @DisplayName("Large context should have high priority (Rule 2)")
        void testLargeContextHighPriority() {
            StringBuilder text = new StringBuilder();
            for (int i = 0; i < 5000; i++) {
                text.append("word ");
            }
            // Add code keyword but make it a large context
            text.append("python example");

            List<ChatMessage> messages = List.of(
                    UserMessage.from(text.toString())
            );

            RoutingDecision decision = strategy.decide(messages, false);

            // Should route to Claude for long_context (higher than code)
            assertEquals(ModelChoice.CLAUDE_API, decision.tier());
            assertEquals("long_context", decision.reason());
        }

        @Test
        @DisplayName("Code should have priority over simple keywords (Rule 3 > Rule 5)")
        void testCodeVsSimpleKeywordsPriority() {
            List<ChatMessage> messages = List.of(
                    UserMessage.from("What is the definition of python programming?")
            );

            RoutingDecision decision = strategy.decide(messages, false);

            // "python" (code) should take priority over "definition" (simple)
            assertEquals(ModelChoice.QWEN_LOCAL, decision.tier());
            assertEquals("code_task", decision.reason());
        }
    }

    // Helper method
    private int countWords(String text) {
        if (text == null || text.isBlank()) {
            return 0;
        }
        return text.trim().split("\\s+").length;
    }
}
