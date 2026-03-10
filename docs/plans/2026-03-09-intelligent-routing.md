# Intelligent LLM Routing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Route LLM requests to the 9B model (G139, fast) or 35B model (G145, complex) based on 10 priority-ordered rules derived from request complexity.

**Architecture:** A new `RoutingAwareChatModel` wraps `RequestRouter` and becomes the `@Primary` `ChatModel` bean. On every call, it routes to the correct GPU server by building a fresh `OpenAICompatibleChatModel` with the selected server's params. The `RequestRouter` applies 10 rules in strict priority order: tools → routing-disabled → model-tier-map → token count → code detection → complex keywords → simple keywords → word count → fallback.

**Tech Stack:** Spring AI 1.0.0, Spring Boot 3.3.5, WebFlux/Reactor, Lombok, JUnit 5, Gradle (run from `app/` directory)

---

## Pre-flight: Current State

The following already exist and are **correct** — do NOT modify:
- `ModelTier.java` — enum SMALL/LARGE ✅
- `OpenAICompatibleChatModel.java` — HTTP client ✅
- `LlmConfigurationProperties.java` — YAML properties ✅
- `ModelConfiguration.java` + `ModelConfiguration.LiteLLMParams` ✅

The following exist but need to be **replaced/modified**:
- `ServerConfig.java` — wrong fields (has `modelName` + `tier`, needs `servedModelName`)
- `RoutingDecision.java` — wrong field names (`targetModelName/targetApiBase/targetApiKey`)
- `RoutingConfig.java` — missing `modelTierMap` and `rules`; will be replaced by `RoutingConfigProperties.java`
- `RequestRouter.java` — wrong signature (`List<Tool>` not `boolean hasTools`), no server config awareness, wrong token estimation
- `LlmModelRouterTest.java` — fully commented out, replace with new tests

The following do **not exist yet**:
- `RoutingConfigProperties.java` — new config properties class
- `RoutingAwareChatModel.java` — new primary ChatModel bean

---

## Task 1: Add routing config to application.yml

**Files:**
- Modify: `app/src/main/resources/application.yml`

**Step 1: Add routing block under `llm:` section**

In `application.yml`, after the `settings:` block (line ~81) and before `litellm_settings:`, add:

```yaml
  routing:
    enabled: true
    servers:
      small:
        instance-id: g139-9b
        api-base: https://u425-twwp-6d5643db.singapore-b.gpuhub.com:8443/v1
        api-key: ${GPUHUB_API_KEY:"test-key"}
        served-model-name: Qwen3.5-9B
      large:
        instance-id: g145-35b
        api-base: https://u425-u70w-e4420dcd.singapore-b.gpuhub.com:8443/v1
        api-key: ${GPUHUB_API_KEY:"test-key"}
        served-model-name: Qwen3.5-35B
    model-tier-map:
      claude-sonnet-4-6: LARGE
      claude-sonnet-4-5-20251022: LARGE
      claude-sonnet-4-5: LARGE
      claude-haiku-4-5-20251001: SMALL
      claude-haiku-4-5: SMALL
    rules:
      max-small-tokens: 500
      max-small-words: 30
```

**Step 2: Verify YAML is valid**

```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/app && ./gradlew compileJava --quiet 2>&1 | tail -5
```
Expected: No output (clean compile) or only warnings.

**Step 3: Commit**

```bash
git add app/src/main/resources/application.yml
git commit -m "feat: add llm.routing config block for G139/G145 server routing"
```

---

## Task 2: Replace ServerConfig.java

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/routing/ServerConfig.java`

Current file has fields `modelName` and `tier` which are wrong. Replace entirely.

**Step 1: Overwrite ServerConfig.java**

```java
package com.synapse.llm.routing;

public record ServerConfig(
    String instanceId,
    String apiBase,
    String apiKey,
    String servedModelName
) {}
```

Note: `ServerConfig` is a record so Spring Boot uses setter-style binding via constructor. For `@ConfigurationProperties` to bind record fields from kebab-case YAML, Spring Boot 3.x supports records natively.

**Step 2: Compile check**

```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/app && ./gradlew compileJava --quiet 2>&1 | tail -10
```
Expected: May fail on `RequestRouter` and `RoutingConfig` — that's expected, they'll be fixed in subsequent tasks.

---

## Task 3: Replace RoutingDecision.java

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/routing/RoutingDecision.java`

Current fields `targetModelName/targetApiBase/targetApiKey` don't match the spec. Replace:

**Step 1: Overwrite RoutingDecision.java**

```java
package com.synapse.llm.routing;

public record RoutingDecision(
    ModelTier tier,
    String reason,
    String servedModelName,
    String apiBase,
    String apiKey
) {}
```

---

## Task 4: Create RoutingConfigProperties.java (replaces RoutingConfig.java)

**Files:**
- Create: `app/src/main/java/com/synapse/llm/routing/RoutingConfigProperties.java`
- Delete: `app/src/main/java/com/synapse/llm/routing/RoutingConfig.java`

**Step 1: Create RoutingConfigProperties.java**

```java
package com.synapse.llm.routing;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@ConfigurationProperties(prefix = "llm.routing")
public class RoutingConfigProperties {

    private boolean enabled = true;
    private Map<String, ServerConfig> servers = Map.of();
    private Map<String, String> modelTierMap = Map.of();
    private RulesConfig rules = new RulesConfig();

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public Map<String, ServerConfig> getServers() { return servers; }
    public void setServers(Map<String, ServerConfig> servers) { this.servers = servers; }

    public Map<String, String> getModelTierMap() { return modelTierMap; }
    public void setModelTierMap(Map<String, String> modelTierMap) { this.modelTierMap = modelTierMap; }

    public RulesConfig getRules() { return rules; }
    public void setRules(RulesConfig rules) { this.rules = rules; }

    public static class RulesConfig {
        private int maxSmallTokens = 500;
        private int maxSmallWords = 30;

        public int getMaxSmallTokens() { return maxSmallTokens; }
        public void setMaxSmallTokens(int maxSmallTokens) { this.maxSmallTokens = maxSmallTokens; }

        public int getMaxSmallWords() { return maxSmallWords; }
        public void setMaxSmallWords(int maxSmallWords) { this.maxSmallWords = maxSmallWords; }
    }
}
```

**Step 2: Delete RoutingConfig.java**

```bash
rm /Users/kayisrahman/Documents/workspace/ideas/synapse/app/src/main/java/com/synapse/llm/routing/RoutingConfig.java
```

---

## Task 5: Rewrite RequestRouter.java

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/routing/RequestRouter.java`

**Key changes from current version:**
- Inject `RoutingConfigProperties` instead of nothing
- Change signature: `List<Tool>` → `boolean hasTools`
- Add rules 2-4: routing-disabled, modelTierMap (replaces old "Tool" rule is now rule 1)
- Fix token estimation: `words * 1.3` (not `chars / 4`)
- Fill `servedModelName`, `apiBase`, `apiKey` from server config in decisions
- Log format: `→ Routing [model] to TIER (reason) — server: instanceId`

**Step 1: Write the failing test first** (see Task 8 — write all tests in Task 8, then come back to verify)

**Step 2: Overwrite RequestRouter.java**

```java
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
        int rules = routingConfig.getRules().getMaxSmallTokens();

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
        // Fallback if no server config (e.g. in unit tests)
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
```

**Step 3: Compile check**

```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/app && ./gradlew compileJava --quiet 2>&1 | tail -10
```

Note: Will fail until `RoutingAwareChatModel` is created and `LlmAutoConfiguration` is updated. That's OK at this stage. Fix any import or API errors that show up.

---

## Task 6: Create RoutingAwareChatModel.java

**Files:**
- Create: `app/src/main/java/com/synapse/llm/routing/RoutingAwareChatModel.java`

**Step 1: Create the file**

```java
package com.synapse.llm.routing;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.synapse.llm.config.ModelConfiguration;
import com.synapse.llm.config.OpenAICompatibleChatModel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.UserMessage;
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
```

**Step 2: Compile check**

```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/app && ./gradlew compileJava --quiet 2>&1 | tail -10
```

Expected: Should compile cleanly or fail only in `LlmAutoConfiguration` (next task).

---

## Task 7: Update LlmAutoConfiguration.java

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/config/LlmAutoConfiguration.java`

**Step 1: Add imports and new bean**

Add these imports at the top of `LlmAutoConfiguration.java`:

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import com.synapse.llm.routing.RequestRouter;
import com.synapse.llm.routing.RoutingAwareChatModel;
import com.synapse.llm.routing.RoutingConfigProperties;
import org.springframework.context.annotation.Primary;
```

Add this bean at the end of the class (before closing `}`):

```java
@Bean
@Primary
public RoutingAwareChatModel routingAwareChatModel(
        RequestRouter router,
        RoutingConfigProperties routingConfig,
        WebClient.Builder webClientBuilder,
        ObjectMapper objectMapper) {
    return new RoutingAwareChatModel(router, routingConfig, webClientBuilder, objectMapper);
}
```

Also add `@EnableConfigurationProperties(RoutingConfigProperties.class)` to the class annotation, OR ensure `RoutingConfigProperties` has `@Component` (it does — already annotated in Task 4).

**Step 2: Full compile + test compile check**

```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/app && ./gradlew compileJava compileTestJava --quiet 2>&1 | tail -15
```

Expected: Clean compile.

**Step 3: Commit all routing infrastructure**

```bash
git add app/src/main/java/com/synapse/llm/routing/ app/src/main/java/com/synapse/llm/config/LlmAutoConfiguration.java
git commit -m "feat: add routing infrastructure — RoutingConfigProperties, RequestRouter, RoutingAwareChatModel"
```

---

## Task 8: Write Tests in LlmModelRouterTest.java

**Files:**
- Modify: `app/src/test/java/com/synapse/llm/service/LlmModelRouterTest.java`

**Step 1: Replace the file with new tests**

```java
package com.synapse.llm.service;

import com.synapse.llm.routing.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.messages.Message;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class LlmModelRouterTest {

    private RoutingConfigProperties config;
    private RequestRouter router;

    @BeforeEach
    void setUp() {
        config = new RoutingConfigProperties();
        config.setEnabled(true);

        ServerConfig small = new ServerConfig("g139-9b",
            "https://small.gpuhub.com/v1", "test-key", "Qwen3.5-9B");
        ServerConfig large = new ServerConfig("g145-35b",
            "https://large.gpuhub.com/v1", "test-key", "Qwen3.5-35B");
        config.setServers(Map.of("small", small, "large", large));

        config.setModelTierMap(Map.of(
            "claude-sonnet-4-6", "LARGE",
            "claude-haiku-4-5", "SMALL"
        ));

        RoutingConfigProperties.RulesConfig rules = new RoutingConfigProperties.RulesConfig();
        rules.setMaxSmallTokens(500);
        rules.setMaxSmallWords(30);
        config.setRules(rules);

        router = new RequestRouter(config);
    }

    // Rule 1: hasTools → LARGE
    @Test
    void rule1_hasTools_routesToLarge() {
        List<Message> msgs = List.of(new UserMessage("What is 2+2?"));
        RoutingDecision decision = router.route("claude-haiku-4-5", msgs, true);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("tool_use", decision.reason());
    }

    // Rule 2: routing disabled → LARGE
    @Test
    void rule2_routingDisabled_routesToLarge() {
        config.setEnabled(false);
        List<Message> msgs = List.of(new UserMessage("What is 2+2?"));
        RoutingDecision decision = router.route("claude-haiku-4-5", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("routing_disabled", decision.reason());
    }

    // Rule 3: modelTierMap SMALL
    @Test
    void rule3_modelTierMapSmall_routesToSmall() {
        List<Message> msgs = List.of(new UserMessage("What is 2+2?"));
        RoutingDecision decision = router.route("claude-haiku-4-5", msgs, false);
        assertEquals(ModelTier.SMALL, decision.tier());
        assertEquals("model_tier_map", decision.reason());
        assertEquals("Qwen3.5-9B", decision.servedModelName());
        assertEquals("https://small.gpuhub.com/v1", decision.apiBase());
    }

    // Rule 4: modelTierMap LARGE
    @Test
    void rule4_modelTierMapLarge_routesToLarge() {
        List<Message> msgs = List.of(new UserMessage("What is 2+2?"));
        RoutingDecision decision = router.route("claude-sonnet-4-6", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("model_tier_map", decision.reason());
        assertEquals("Qwen3.5-35B", decision.servedModelName());
    }

    // Rule 5: long context (>500 estimated tokens ≈ >385 words) → LARGE
    @Test
    void rule5_longContext_routesToLarge() {
        // Need >500 tokens: ~385 words × 1.3 > 500
        // Use an unknown model to skip modelTierMap
        String longText = "word ".repeat(400).trim();
        List<Message> msgs = List.of(new UserMessage(longText));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("long_context", decision.reason());
    }

    // Rule 6: contains code block → LARGE
    @Test
    void rule6_codeBlock_routesToLarge() {
        List<Message> msgs = List.of(new UserMessage("Check this ```java\nint x = 1;\n```"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("contains_code", decision.reason());
    }

    // Rule 6: contains code keyword → LARGE
    @Test
    void rule6_codeKeyword_routesToLarge() {
        List<Message> msgs = List.of(new UserMessage("public class Foo { }"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("contains_code", decision.reason());
    }

    // Rule 7: complex keywords → LARGE
    @Test
    void rule7_complexKeyword_implement_routesToLarge() {
        List<Message> msgs = List.of(new UserMessage("implement a sort algorithm"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("complex_keywords", decision.reason());
    }

    @Test
    void rule7_complexKeyword_refactor_routesToLarge() {
        List<Message> msgs = List.of(new UserMessage("refactor this code"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("complex_keywords", decision.reason());
    }

    // Rule 8: simple phrase → SMALL
    @Test
    void rule8_simplePhrase_whatIs_routesToSmall() {
        List<Message> msgs = List.of(new UserMessage("what is the capital of France and what is its population history"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.SMALL, decision.tier());
        assertEquals("simple_keywords", decision.reason());
    }

    @Test
    void rule8_simplePhrase_explain_routesToSmall() {
        List<Message> msgs = List.of(new UserMessage("explain quantum computing in simple terms please now"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.SMALL, decision.tier());
        assertEquals("simple_keywords", decision.reason());
    }

    // Rule 9: short query < 30 words → SMALL
    @Test
    void rule9_shortQuery_routesToSmall() {
        List<Message> msgs = List.of(new UserMessage("hello"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.SMALL, decision.tier());
        assertEquals("short_query", decision.reason());
    }

    // Rule 10: default fallback → LARGE
    @Test
    void rule10_defaultFallback_routesToLarge() {
        // 30+ words, no code, no keywords
        String text = "The quick brown fox jumps over the lazy dog repeatedly. " +
            "This sentence has enough words to exceed the threshold without triggering " +
            "any specific routing rule based on keywords or code detection in the text.";
        List<Message> msgs = List.of(new UserMessage(text));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("default_fallback", decision.reason());
    }

    // Priority: Rule 1 beats everything
    @Test
    void priority_rule1_beatsModelTierMap() {
        // haiku maps to SMALL (rule 3), but hasTools should win (rule 1)
        List<Message> msgs = List.of(new UserMessage("What is 2+2?"));
        RoutingDecision decision = router.route("claude-haiku-4-5", msgs, true);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("tool_use", decision.reason());
    }

    // Server config is resolved correctly
    @Test
    void serverConfig_smallTier_hasCorrectEndpoint() {
        List<Message> msgs = List.of(new UserMessage("hi"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.SMALL, decision.tier());
        assertNotNull(decision.apiBase());
        assertNotNull(decision.servedModelName());
    }

    @Test
    void serverConfig_largeTier_hasCorrectEndpoint() {
        // Force LARGE via complex keyword
        List<Message> msgs = List.of(new UserMessage("implement a binary search tree"));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertNotNull(decision.apiBase());
        assertEquals("Qwen3.5-35B", decision.servedModelName());
    }
}
```

**Step 2: Run tests**

```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/app && ./gradlew test --tests "com.synapse.llm.service.LlmModelRouterTest" 2>&1 | tail -30
```

Expected: All tests pass. If any fail, read the failure message carefully:
- `model_tier_map` not firing: check `modelTierMap` key lookup
- `long_context` not firing: check token estimation math (`words * 1.3 > 500` means need ~385+ words)
- `short_query` not firing: verify it's an unknown model with no keywords

**Step 3: Commit**

```bash
git add app/src/test/java/com/synapse/llm/service/LlmModelRouterTest.java
git commit -m "test: add comprehensive routing rule tests covering all 10 priority rules"
```

---

## Task 9: Run full test suite

**Step 1: Run all tests**

```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/app && ./gradlew test 2>&1 | tail -30
```

Expected: Previously passing tests still pass. If any existing tests break:
- Tests referencing `RoutingConfig` (deleted): update import to `RoutingConfigProperties`
- Tests referencing old `RoutingDecision` field names: update to `servedModelName/apiBase/apiKey`
- Tests referencing `Tool` class in router: update to `boolean hasTools` signature

**Step 2: Fix any regressions, then final commit**

```bash
git add -A
git commit -m "feat: complete intelligent routing with RoutingAwareChatModel as primary ChatModel"
```

---

## Gotchas & Notes

**Spring Boot record binding:** `ServerConfig` is a record. Spring Boot 3.3.5 supports `@ConfigurationProperties` on records using the canonical constructor. The YAML key `served-model-name` maps to `servedModelName` parameter. This works out of the box — no special annotations needed.

**@Primary conflict:** If the old individual ChatModel beans (`claudeSonnet46ChatModel` etc.) are still `@Primary`, there will be a conflict. The task above adds `@Primary` only to `routingAwareChatModel`. Check that no other bean in `LlmAutoConfiguration` has `@Primary`.

**`RoutingConfigProperties` + `LlmConfigurationProperties` dual binding:** Both bind under `llm.*`. Spring Boot handles this fine — each class binds its own prefix (`llm.routing` vs `llm.model_list`).

**Token estimation math:** The spec says `estimateTokens = sum_of_words * 1.3`. With `maxSmallTokens=500`, the threshold triggers at `500 / 1.3 ≈ 385` words. The test for Rule 5 uses 400 words to reliably trigger it.

**`Tool.java`:** The `Tool` class is now unused (it was only referenced by the old `RequestRouter` signature). It can be left in place or deleted — leaving it causes no harm.
