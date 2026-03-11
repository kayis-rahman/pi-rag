package com.synapse.llm.routing;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.synapse.llm.health.VllmCircuitBreaker;
import com.synapse.llm.logging.ModelUsageLogger;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.data.message.AiMessage;
import dev.langchain4j.model.output.Response;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Integration tests for RouterChatLanguageModel.
 * Tests routing logic, delegation, MDC logging, and fallback behavior.
 */
@ExtendWith(MockitoExtension.class)
public class RouterChatLanguageModelIntegrationTest {

    @Mock
    private RoutingStrategy routingStrategy;

    @Mock
    private ChatLanguageModel qwenModel;

    @Mock
    private ChatLanguageModel claudeModel;

    @Mock
    private VllmCircuitBreaker circuitBreaker;

    @Mock
    private ModelUsageLogger usageLogger;

    private RouterChatLanguageModel router;

    @BeforeEach
    public void setUp() {
        router = new RouterChatLanguageModel(
                routingStrategy,
                qwenModel,
                claudeModel,
                circuitBreaker,
                usageLogger
        );
    }

    @Test
    public void testGenerateWithQwenDecision() {
        // Setup
        List<ChatMessage> messages = List.of(createUserMessage("Simple code question"));
        RoutingDecision decision = new RoutingDecision(ModelChoice.QWEN_LOCAL, "code_task", 50);

        Response<AiMessage> mockResponse = Response.from(AiMessage.from("Here's the code..."));
        when(routingStrategy.decide(messages, false)).thenReturn(decision);
        when(circuitBreaker.executeWithFallback(any(), any())).thenReturn(mockResponse);

        // Execute
        Response<AiMessage> result = router.generate(messages);

        // Verify
        assertEquals("Here's the code...", result.content().text());
        verify(routingStrategy).decide(messages, false);
        verify(circuitBreaker).executeWithFallback(any(), any());
        verify(usageLogger).startRequest(decision);
        verify(usageLogger).endRequest(anyLong());
    }

    @Test
    public void testGenerateWithClaudeDecision() {
        // Setup
        List<ChatMessage> messages = List.of(createUserMessage("Complex architectural question"));
        RoutingDecision decision = new RoutingDecision(ModelChoice.CLAUDE_API, "complex_task", 200);

        when(routingStrategy.decide(messages, false)).thenReturn(decision);
        when(claudeModel.generate(messages)).thenReturn(
                Response.from(AiMessage.from("Here's the architecture..."))
        );

        // Execute
        String result = router.generate(messages);

        // Verify
        assertEquals("Here's the architecture...", result);
        verify(routingStrategy).decide(messages, false);
        verify(claudeModel).generate(messages);
        verify(circuitBreaker, never()).executeWithFallback(any(), any());
        verify(usageLogger).startRequest(decision);
        verify(usageLogger).endRequest(anyLong());
    }

    @Test
    public void testMdcIsPopulatedWithDecision() {
        // Setup
        List<ChatMessage> messages = List.of(createUserMessage("Test"));
        RoutingDecision decision = new RoutingDecision(ModelChoice.QWEN_LOCAL, "simple_retrieval", 75);

        when(routingStrategy.decide(messages, false)).thenReturn(decision);
        when(circuitBreaker.executeWithFallback(any(), any())).thenReturn("Response");

        // Execute
        router.generate(messages);

        // Verify MDC logging
        verify(usageLogger).startRequest(decision);
        verify(usageLogger).endRequest(anyLong());
    }

    @Test
    public void testMdcIsCleanedUpEvenOnException() {
        // Setup
        List<ChatMessage> messages = List.of(createUserMessage("Test"));
        RoutingDecision decision = new RoutingDecision(ModelChoice.QWEN_LOCAL, "code_task", 50);

        when(routingStrategy.decide(messages, false)).thenReturn(decision);
        when(circuitBreaker.executeWithFallback(any(), any()))
                .thenThrow(new RuntimeException("Unexpected error"));

        // Execute and expect exception
        assertThrows(RuntimeException.class, () -> router.generate(messages));

        // Verify MDC is still cleaned up
        verify(usageLogger).startRequest(decision);
        verify(usageLogger).endRequest(anyLong());
    }

    @Test
    public void testCircuitBreakerIsCalledForQwenDecisions() {
        // Setup
        List<ChatMessage> messages = List.of(createUserMessage("Code"));
        RoutingDecision decision = new RoutingDecision(ModelChoice.QWEN_LOCAL, "code_task", 50);

        when(routingStrategy.decide(messages, false)).thenReturn(decision);
        when(circuitBreaker.executeWithFallback(any(), any())).thenReturn("Response");

        // Execute
        router.generate(messages);

        // Verify circuit breaker is used
        verify(circuitBreaker).executeWithFallback(any(), any());
    }

    @Test
    public void testCircuitBreakerIsNotCalledForClaudeDecisions() {
        // Setup
        List<ChatMessage> messages = List.of(createUserMessage("Complex"));
        RoutingDecision decision = new RoutingDecision(ModelChoice.CLAUDE_API, "complex_task", 200);

        when(routingStrategy.decide(messages, false)).thenReturn(decision);
        when(claudeModel.generate(messages)).thenReturn(
                Response.from(AiMessage.from("Response"))
        );

        // Execute
        router.generate(messages);

        // Verify circuit breaker is NOT used
        verify(circuitBreaker, never()).executeWithFallback(any(), any());
    }

    // Helper methods
    private ChatMessage createUserMessage(String text) {
        return UserMessage.from(text);
    }
}
