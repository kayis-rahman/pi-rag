package com.synapse.llm.routing;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.Message;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Component
@Slf4j
@RequiredArgsConstructor
public class RequestRouter {

    private final RoutingConfigProperties routingConfig;

    private static final Pattern CODE_BLOCK_PATTERN = Pattern.compile("```");
    private static final Pattern CODE_KEYWORD_PATTERN = Pattern.compile(
        "(public |private |def |function |import |class )"
    );
    private static final List<String> COMPLEX_KEYWORDS = List.of(
        "implement", "refactor", "debug", "architect", "design", "optimize",
        "review", "analyze", "migrate", "build"
    );
    private static final List<String> SIMPLE_PHRASES = List.of(
        "what is", "define", "summarize", "list the", "explain", "is this",
        "how many", "yes or no"
    );

    public RoutingDecision route(String requestedModelName,
                                  List<Message> messages,
                                  boolean hasTools) {
        RoutingDecision decision = computeDecision(requestedModelName, messages, hasTools);
        log.info("→ Routing [{}] to {} ({}) — server: {}",
            requestedModelName, decision.tier(), decision.reason(),
            decision.servedModelName());
        return decision;
    }

    private RoutingDecision computeDecision(String requestedModelName,
                                             List<Message> messages,
                                             boolean hasTools) {
        // Rule 1: hasTools → LARGE
        if (hasTools) {
            return decide(ModelTier.LARGE, "tool_use");
        }

        // Rule 2: routing disabled → LARGE
        if (!routingConfig.isEnabled()) {
            return decide(ModelTier.LARGE, "routing_disabled");
        }

        // Rule 3 & 4: modelTierMap contains model
        String mappedTier = routingConfig.getModelTierMap().get(requestedModelName);
        if (mappedTier != null) {
            ModelTier tier = ModelTier.valueOf(mappedTier.toUpperCase());
            return decide(tier, "model_tier_map");
        }

        String combinedText = extractAllText(messages);

        // Rule 5: token count > maxSmallTokens
        int estimatedTokens = estimateTokens(messages);
        if (estimatedTokens > routingConfig.getRules().getMaxSmallTokens()) {
            return decide(ModelTier.LARGE, "long_context");
        }

        // Rule 6: code detected
        if (CODE_BLOCK_PATTERN.matcher(combinedText).find() ||
            CODE_KEYWORD_PATTERN.matcher(combinedText).find()) {
            return decide(ModelTier.LARGE, "contains_code");
        }

        // Rule 7: complex keywords
        String lower = combinedText.toLowerCase();
        boolean hasComplexKeyword = COMPLEX_KEYWORDS.stream().anyMatch(lower::contains);
        if (hasComplexKeyword) {
            return decide(ModelTier.LARGE, "complex_keywords");
        }

        // Rule 8: simple phrases
        boolean hasSimplePhrase = SIMPLE_PHRASES.stream().anyMatch(lower::contains);
        if (hasSimplePhrase) {
            return decide(ModelTier.SMALL, "simple_keywords");
        }

        // Rule 9: short query
        int wordCount = countWords(messages);
        if (wordCount < routingConfig.getRules().getMaxSmallWords()) {
            return decide(ModelTier.SMALL, "short_query");
        }

        // Rule 10: default fallback
        return decide(ModelTier.LARGE, "default_fallback");
    }

    private RoutingDecision decide(ModelTier tier, String reason) {
        String serverKey = tier == ModelTier.SMALL ? "small" : "large";
        ServerConfig server = routingConfig.getServers() != null
            ? routingConfig.getServers().get(serverKey)
            : null;

        if (server != null) {
            return new RoutingDecision(tier, reason, server.servedModelName(),
                server.apiBase(), server.apiKey());
        }
        // Fallback if no server config (e.g. in unit tests with no servers configured)
        return new RoutingDecision(tier, reason, null, null, null);
    }

    private int estimateTokens(List<Message> messages) {
        int words = countWords(messages);
        return (int) (words * 1.3);
    }

    private int countWords(List<Message> messages) {
        String text = extractAllText(messages);
        if (text.isBlank()) return 0;
        return text.trim().split("\\s+").length;
    }

    private String extractAllText(List<Message> messages) {
        return messages.stream()
            .map(this::extractText)
            .filter(Objects::nonNull)
            .collect(Collectors.joining(" "));
    }

    private String extractText(Message m) {
        try {
            return m.getText();
        } catch (Exception e) {
            return "";
        }
    }
}
