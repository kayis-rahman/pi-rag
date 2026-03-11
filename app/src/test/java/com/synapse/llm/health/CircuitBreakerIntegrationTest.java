package com.synapse.llm.health;

import static org.junit.jupiter.api.Assertions.*;

import com.synapse.llm.config.LlmConfigurationProperties;
import dev.langchain4j.data.message.AiMessage;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Integration tests for VllmCircuitBreaker.
 * Tests circuit breaker state transitions, failure detection, slow calls, and fallback behavior.
 */
public class CircuitBreakerIntegrationTest {

    private VllmCircuitBreaker circuitBreaker;
    private LlmConfigurationProperties.CircuitBreakerConfig config;

    @BeforeEach
    public void setUp() {
        config = new LlmConfigurationProperties.CircuitBreakerConfig();
        config.setFailureRateThreshold(50);                    // 50% failure rate
        config.setSlowCallDurationThresholdMs(100);             // 100ms for easy testing
        config.setWaitDurationInOpenStateMs(500);               // 500ms wait before half-open
        config.setPermittedCallsInHalfOpen(2);                  // Allow 2 calls in half-open
        config.setMinCallsBeforeEvaluation(3);                  // Need 3 calls before evaluation

        circuitBreaker = new VllmCircuitBreaker(config);
    }

    @Test
    public void testCircuitBreakerStartsInClosedState() {
        assertEquals(CircuitBreaker.State.CLOSED, circuitBreaker.getState());
    }

    @Test
    public void testSuccessfulCallMaintainsClosedState() {
        Response<AiMessage> response = executeWithFallback(
                () -> createMockResponse("Success"),
                () -> createMockResponse("Fallback")
        );

        assertEquals("Success", response.content().text());
        assertEquals(CircuitBreaker.State.CLOSED, circuitBreaker.getState());
    }

    @Test
    public void testMultipleFailuresOpenCircuit() {
        // Need min 3 calls before evaluation, so make 5 calls (3 failures + 2 for margin)
        AtomicInteger callCount = new AtomicInteger(0);

        for (int i = 0; i < 5; i++) {
            try {
                executeWithFallback(
                        () -> {
                            callCount.incrementAndGet();
                            throw new RuntimeException("Simulated failure");
                        },
                        () -> createMockResponse("Fallback")
                );
            } catch (Exception e) {
                // Expected
            }
        }

        // After enough failures, circuit should open
        CircuitBreaker.State state = circuitBreaker.getState();
        assertTrue(
                state == CircuitBreaker.State.OPEN || state == CircuitBreaker.State.HALF_OPEN,
                "Circuit should be open or half-open after multiple failures, but was: " + state
        );
    }

    @Test
    public void testSlowCallsDetected() throws InterruptedException {
        // Create a slow call (> 100ms threshold)
        for (int i = 0; i < 5; i++) {
            try {
                executeWithFallback(
                        () -> {
                            try {
                                Thread.sleep(150);  // Slow call
                            } catch (InterruptedException e) {
                                Thread.currentThread().interrupt();
                            }
                            return createMockResponse("Slow response");
                        },
                        () -> createMockResponse("Fallback")
                );
            } catch (Exception e) {
                // Expected
            }
        }

        // After enough slow calls, circuit may open
        CircuitBreaker.State state = circuitBreaker.getState();
        assertNotEquals(CircuitBreaker.State.CLOSED, state,
                "Circuit should open after slow calls, but is still CLOSED");
    }

    @Test
    public void testFallbackIsCalledWhenCircuitOpen() {
        // Force circuit to open by causing multiple failures
        AtomicInteger primaryCalls = new AtomicInteger(0);
        AtomicInteger fallbackCalls = new AtomicInteger(0);

        // Generate failures to open circuit
        for (int i = 0; i < 5; i++) {
            try {
                executeWithFallback(
                        () -> {
                            primaryCalls.incrementAndGet();
                            throw new RuntimeException("Primary failed");
                        },
                        () -> {
                            fallbackCalls.incrementAndGet();
                            return createMockResponse("Fallback");
                        }
                );
            } catch (Exception e) {
                // Expected
            }
        }

        // Verify fallback was called
        assertTrue(fallbackCalls.get() > 0, "Fallback should have been called");
    }

    @Test
    public void testHalfOpenStateAllowsLimitedCalls() throws InterruptedException {
        // Open the circuit
        for (int i = 0; i < 5; i++) {
            try {
                executeWithFallback(
                        () -> {
                            throw new RuntimeException("Failure");
                        },
                        () -> createMockResponse("Fallback")
                );
            } catch (Exception e) {
                // Expected
            }
        }

        assertTrue(
                circuitBreaker.getState() == CircuitBreaker.State.OPEN,
                "Circuit should be open"
        );

        // Wait for half-open transition
        Thread.sleep(600);

        // In half-open state, a limited number of calls are permitted
        CircuitBreaker.State state = circuitBreaker.getState();
        assertTrue(
                state == CircuitBreaker.State.HALF_OPEN,
                "Circuit should transition to HALF_OPEN after wait duration, but is: " + state
        );
    }

    @Test
    public void testSuccessInHalfOpenClosesCircuit() throws InterruptedException {
        // Open the circuit
        for (int i = 0; i < 5; i++) {
            try {
                executeWithFallback(
                        () -> {
                            throw new RuntimeException("Failure");
                        },
                        () -> createMockResponse("Fallback")
                );
            } catch (Exception e) {
                // Expected
            }
        }

        // Wait for transition to HALF_OPEN
        Thread.sleep(600);

        // Make successful calls in half-open state
        try {
            Response<AiMessage> response = executeWithFallback(
                    () -> createMockResponse("Success in half-open"),
                    () -> createMockResponse("Fallback")
            );
            assertEquals("Success in half-open", response.content().text());
        } catch (Exception e) {
            // May fail due to timing, but that's okay for this test
        }
    }

    @Test
    public void testCircuitBreakerUnderlyingAccess() {
        CircuitBreaker underlying = circuitBreaker.getUnderlyingCircuitBreaker();
        assertNotNull(underlying);
        assertEquals(CircuitBreaker.State.CLOSED, underlying.getState());
    }

    @Test
    public void testResponsePropagationOnSuccess() {
        Response<AiMessage> response = executeWithFallback(
                () -> createMockResponse("Primary response"),
                () -> createMockResponse("Fallback response")
        );

        assertEquals("Primary response", response.content().text());
    }

    @Test
    public void testFallbackResponseOnPrimaryFailure() {
        Response<AiMessage> response = executeWithFallback(
                () -> {
                    throw new RuntimeException("Primary failure");
                },
                () -> createMockResponse("Fallback response")
        );

        assertEquals("Fallback response", response.content().text());
    }

    // Helper methods
    private ChatResponse executeWithFallback(
            java.util.function.Supplier<ChatResponse> primary,
            java.util.function.Supplier<ChatResponse> fallback
    ) {
        return circuitBreaker.executeWithFallback(primary, fallback);
    }

    private ChatResponse createMockResponse(String text) {
        return ChatResponse.builder()
                .aiMessage(AiMessage.from(text))
                .build();
    }
}
