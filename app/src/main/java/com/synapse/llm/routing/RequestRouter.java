package com.synapse.llm.routing;

import org.springframework.ai.chat.messages.Message;
import org.springframework.stereotype.Component;
import lombok.extern.slf4j.Slf4j;
import com.synapse.llm.routing.Tool;
import com.synapse.llm.routing.RoutingDecision;
import com.synapse.llm.routing.ModelTier;

import java.util.List;
import java.util.stream.Collectors;
import java.util.regex.Pattern;
import java.util.Objects;

@Component
@Slf4j
public class RequestRouter {

    private static final Pattern CODE_BLOCK_PATTERN = Pattern.compile("```");
    private static final Pattern CODE_KEYWORD_PATTERN = Pattern.compile(
        "\\b(def |func |class |import |from |const |let |var |public |private |protected )",
        Pattern.CASE_INSENSITIVE
    );
    private static final Pattern COMPLEX_KEYWORDS = Pattern.compile(
        "\\b(implement|refactor|debug|architect|design|optimize|review|analyze|migrate|build|fix)\\b",
        Pattern.CASE_INSENSITIVE
    );
    private static final Pattern SIMPLE_KEYWORDS = Pattern.compile(
        "\\b(what is|define|summarize|list|explain|is this|how many|yes or no)\\b",
        Pattern.CASE_INSENSITIVE
    );

    public RoutingDecision route(String modelName, List<Message> messages, List<Tool> tools) {
        String combinedText = messages.stream()
            .map(Message::getContent)
            .filter(Objects::nonNull)
            .collect(Collectors.joining(" "));

        // Rule 1: Tools array
        if (tools != null && !tools.isEmpty()) {
            log.info("Routing decision: tier=LARGE, reason=tools-array-detected, model={}", modelName);
            return createLargeDecision("tools-array-detected", modelName);
        }

        // Rule 2: Token count > 500
        int estimatedTokens = countTokens(combinedText);
        if (estimatedTokens > 500) {
            log.info("Routing decision: tier=LARGE, reason=high-token-count={}, model={}", estimatedTokens, modelName);
            return createLargeDecision("high-token-count-" + estimatedTokens, modelName);
        }

        // Rule 3: Code blocks
        if (CODE_BLOCK_PATTERN.matcher(combinedText).find()) {
            log.info("Routing decision: tier=LARGE, reason=code-block-detected, model={}", modelName);
            return createLargeDecision("code-block-detected", modelName);
        }

        // Rule 4: Complex keywords
        if (COMPLEX_KEYWORDS.matcher(combinedText).find()) {
            log.info("Routing decision: tier=LARGE, reason=complex-keyword-detected, model={}", modelName);
            return createLargeDecision("complex-keyword-detected", modelName);
        }

        // Rule 5: Simple keywords
        if (SIMPLE_KEYWORDS.matcher(combinedText).find()) {
            log.info("Routing decision: tier=SMALL, reason=simple-keyword-detected, model={}", modelName);
            return createSmallDecision("simple-keyword-detected", modelName);
        }

        // Rule 6: Short message < 30 words, no code
        int wordCount = countWords(combinedText);
        if (wordCount < 30 && !CODE_BLOCK_PATTERN.matcher(combinedText).find() &&
            !CODE_KEYWORD_PATTERN.matcher(combinedText).find()) {
            log.info("Routing decision: tier=SMALL, reason=short-message-no-code={}, model={}", wordCount, modelName);
            return createSmallDecision("short-message-no-code-" + wordCount, modelName);
        }

        // Rule 7: Default to LARGE
        log.info("Routing decision: tier=LARGE, reason=default, model={}", modelName);
        return createLargeDecision("default", modelName);
    }

    private int countTokens(String text) {
        // Rough estimation: 1 token ≈ 4 characters
        return text.length() / 4;
    }

    private int countWords(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }
        return text.trim().split("\\s+").length;
    }

    private RoutingDecision createLargeDecision(String reason, String modelName) {
        return new RoutingDecision(ModelTier.LARGE, reason, modelName, null, null);
    }

    private RoutingDecision createSmallDecision(String reason, String modelName) {
        return new RoutingDecision(ModelTier.SMALL, reason, modelName, null, null);
    }
}
