package com.synapse.llm.api;

import com.synapse.llm.routing.RoutingAwareChatModel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@Slf4j
@RequiredArgsConstructor
public class ChatController {

    private final RoutingAwareChatModel routingAwareChatModel;

    @PostMapping("/sync")
    public Map<String, Object> chat(@RequestBody ChatRequest request) {
        log.info("📨 Chat request: model={}, content={}", request.model(), request.content());

        try {
            ChatResponse response = routingAwareChatModel.call(
                new Prompt(List.of(new UserMessage(request.content())))
            );

            return Map.of(
                "response", response.getResult().getOutput().getText(),
                "routing_decision", Map.of(
                    "tier", routingAwareChatModel.lastDecision().tier(),
                    "reason", routingAwareChatModel.lastDecision().reason(),
                    "server", routingAwareChatModel.lastDecision().servedModelName(),
                    "api_base", routingAwareChatModel.lastDecision().apiBase()
                )
            );
        } catch (Exception e) {
            log.error("Error: {}", e.getMessage());
            return Map.of(
                "error", e.getMessage(),
                "routing_decision", Map.of(
                    "tier", routingAwareChatModel.lastDecision().tier(),
                    "reason", routingAwareChatModel.lastDecision().reason(),
                    "server", routingAwareChatModel.lastDecision().servedModelName(),
                    "api_base", routingAwareChatModel.lastDecision().apiBase()
                )
            );
        }
    }

    public record ChatRequest(String model, String content) {}
}
