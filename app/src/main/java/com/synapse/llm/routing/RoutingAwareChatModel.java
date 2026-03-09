package com.synapse.llm.routing;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.synapse.llm.config.ModelConfiguration;
import com.synapse.llm.config.OpenAICompatibleChatModel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;

import java.util.Arrays;
import java.util.List;

@Component
@Slf4j
@RequiredArgsConstructor
public class RoutingAwareChatModel implements ChatModel {

    private final RequestRouter router;
    private final RoutingConfigProperties routingConfig;
    private final WebClient.Builder webClientBuilder;
    private final ObjectMapper objectMapper;

    private volatile RoutingDecision lastDecision;

    @Override
    public ChatResponse call(Prompt prompt) {
        List<Message> messages = prompt.getInstructions();
        RoutingDecision decision = router.route("default", messages, false);
        lastDecision = decision;
        return buildModel(decision).call(prompt);
    }

    @Override
    public Flux<ChatResponse> stream(Prompt prompt) {
        List<Message> messages = prompt.getInstructions();
        RoutingDecision decision = router.route("default", messages, false);
        lastDecision = decision;
        return buildModel(decision).stream(prompt);
    }

    @Override
    public String call(Message... messages) {
        List<Message> msgList = Arrays.asList(messages);
        RoutingDecision decision = router.route("default", msgList, false);
        lastDecision = decision;
        return buildModel(decision).call(messages);
    }

    @Override
    public Flux<String> stream(Message... messages) {
        List<Message> msgList = Arrays.asList(messages);
        RoutingDecision decision = router.route("default", msgList, false);
        lastDecision = decision;
        return buildModel(decision).stream(messages);
    }

    @Override
    public ChatOptions getDefaultOptions() {
        return ChatOptions.builder().build();
    }

    /**
     * Returns the last routing decision — useful for testing and debugging.
     */
    public RoutingDecision lastDecision() {
        return lastDecision;
    }

    private OpenAICompatibleChatModel buildModel(RoutingDecision decision) {
        ModelConfiguration.LiteLLMParams params = new ModelConfiguration.LiteLLMParams(
            decision.servedModelName(),
            decision.apiBase(),
            decision.apiKey()
        );
        WebClient webClient = webClientBuilder.build();
        return new OpenAICompatibleChatModel(
            decision.servedModelName(), params, webClient, objectMapper);
    }
}
