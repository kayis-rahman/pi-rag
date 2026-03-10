package com.synapse.llm.api;

import com.synapse.llm.routing.ModelChoice;
import com.synapse.llm.routing.RoutingAwareChatModel;
import com.synapse.llm.routing.RoutingDecision;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@Slf4j
@RequiredArgsConstructor
public class ChatController {

    private final RoutingAwareChatModel routingAwareChatModel;

    @PostMapping("/sync")
    public Mono<Map<String, Object>> chat(@RequestBody ChatRequest request) {
        log.info("📨 Chat request: model={}, content={}", request.model(), request.content());

        Prompt prompt = new Prompt(List.of(new UserMessage(request.content())));

        return routingAwareChatModel.stream(prompt)
            .doOnNext(chatResponse -> log.debug("📤 Received ChatResponse: {}", chatResponse.getResult().getOutput().getText()))
            .map(chatResponse -> chatResponse.getResult().getOutput().getText())
            .collectList()
            .doOnNext(tokens -> log.debug("📦 Collected {} tokens", tokens.size()))
            .map(tokens -> {
                String fullResponse = String.join("", tokens);
                log.info("✅ Full response length: {}", fullResponse.length());
                RoutingDecision decision = routingAwareChatModel.lastDecision();
                return Map.<String, Object>of(
                    "response", fullResponse,
                    "routing_decision", Map.of(
                        "tier", decision.modelChoice().toString(),
                        "reason", decision.reason(),
                        "server", getServerName(decision.modelChoice()),
                        "api_base", getApiBase(decision.modelChoice())
                    )
                );
            })
            .onErrorResume(e -> {
                log.error("Error: {}", e.getMessage(), e);
                RoutingDecision decision = routingAwareChatModel.lastDecision();
                Map<String, Object> routingInfo = decision != null ? Map.of(
                    "tier", decision.modelChoice().toString(),
                    "reason", decision.reason(),
                    "server", getServerName(decision.modelChoice()),
                    "api_base", getApiBase(decision.modelChoice())
                ) : Map.of();
                return Mono.just(Map.of(
                    "error", e.getMessage(),
                    "routing_decision", routingInfo
                ));
            });
    }

    private String getServerName(ModelChoice choice) {
        return choice == ModelChoice.QWEN_LOCAL ? "qwen" : "claude";
    }

    private String getApiBase(ModelChoice choice) {
        return choice == ModelChoice.QWEN_LOCAL ? "http://localhost:8000/v1" : "https://api.anthropic.com";
    }

    public record ChatRequest(String model, String content) {}
}
