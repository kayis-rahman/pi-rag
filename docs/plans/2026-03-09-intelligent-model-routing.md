# Intelligent Model Routing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement intelligent model routing system that routes requests to SMALL (G139/9B) or LARGE (G145/35B) tier based on 7 complexity rules before delegating to existing OpenAICompatibleChatModel infrastructure.

**Architecture:** RoutingAwareChatModel implements Spring AI ChatModel interface and sits as primary bean for model requests. It delegates to RequestRouter for tier selection, then routes to appropriate OpenAICompatibleChatModel instance based on routing decision.

**Tech Stack:** Java 21, Spring Boot, Spring AI, Lombok @Slf4j, WebFlux reactive programming, Records for immutable data

---

## Phase 1: Create Core Routing Classes

### Task 1: Create ModelTier Enum

**Files:**
- Create: `app/src/main/java/com/synapse/llm/routing/ModelTier.java`

**Step 1: Write ModelTier.java**

```java
package com.synapse.llm.routing;

public enum ModelTier {
    SMALL,
    LARGE
}
```

**Step 2: Verify file created**

Run: `cat app/src/main/java/com/synapse/llm/routing/ModelTier.java`
Expected: File contains enum with SMALL and LARGE values

**Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/routing/ModelTier.java
git commit -m "feat: add ModelTier enum for SMALL/LARGE tiers"
```

---

### Task 2: Create ServerConfig Record

**Files:**
- Create: `app/src/main/java/com/synapse/llm/routing/ServerConfig.java`

**Step 1: Write ServerConfig.java**

```java
package com.synapse.llm.routing;

public record ServerConfig(
    String instanceId,
    String apiBase,
    String apiKey,
    String modelName,
    ModelTier tier
) {}
```

**Step 2: Verify file created**

Run: `cat app/src/main/java/com/synapse/llm/routing/ServerConfig.java`
Expected: Record with 5 fields as specified

**Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/routing/ServerConfig.java
git commit -m "feat: add ServerConfig record for server configuration"
```

---

### Task 3: Create RoutingDecision Record

**Files:**
- Create: `app/src/main/java/com/synapse/llm/routing/RoutingDecision.java`

**Step 1: Write RoutingDecision.java**

```java
package com.synapse.llm.routing;

public record RoutingDecision(
    ModelTier tier,
    String reason,
    String targetModelName,
    String targetApiBase,
    String targetApiKey
) {}
```

**Step 2: Verify file created**

Run: `cat app/src/main/java/com/synapse/llm/routing/RoutingDecision.java`
Expected: Record with 5 fields as specified

**Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/routing/RoutingDecision.java
git commit -m "feat: add RoutingDecision record for routing results"
```

---

### Task 4: Create RoutingConfig Class

**Files:**
- Create: `app/src/main/java/com/synapse/llm/routing/RoutingConfig.java`

**Step 1: Write RoutingConfig.java**

```java
package com.synapse.llm.routing;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@ConfigurationProperties(prefix = "llm.routing")
public class RoutingConfig {
    private boolean enabled = true;
    private String smallModel;
    private String largeModel;
    private Map<String, ServerConfig> servers;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getSmallModel() {
        return smallModel;
    }

    public void setSmallModel(String smallModel) {
        this.smallModel = smallModel;
    }

    public String getLargeModel() {
        return largeModel;
    }

    public void setLargeModel(String largeModel) {
        this.largeModel = largeModel;
    }

    public Map<String, ServerConfig> getServers() {
        return servers;
    }

    public void setServers(Map<String, ServerConfig> servers) {
        this.servers = servers;
    }
}
```

**Step 2: Verify file created**

Run: `cat app/src/main/java/com/synapse/llm/routing/RoutingConfig.java`
Expected: Class with @Component, @ConfigurationProperties, and getters/setters

**Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/routing/RoutingConfig.java
git commit -m "feat: add RoutingConfig with @ConfigurationProperties"
```

---

## Phase 2: Implement RequestRouter

### Task 5: Create RequestRouter Test - Tools Detection

**Files:**
- Test: `app/src/test/java/com/synapse/llm/service/RequestRouterTest.java`
- Create new test file

**Step 1: Write failing test for tool detection**

```java
package com.synapse.llm.service;

import com.synapse.llm.api.ChatRequest;
import com.synapse.llm.routing.ModelTier;
import com.synapse.llm.routing.RequestRouter;
import com.synapse.llm.routing.RoutingDecision;
import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.UserMessage;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class RequestRouterTest {

    @Test
    void testRoutingWithTools() {
        RequestRouter router = new RequestRouter();
        List<Message> messages = List.of(new UserMessage("Help me use tools"));
        List<Tool> tools = List.of(new Tool("function1", "desc"));

        RoutingDecision decision = router.route("claude-sonnet-4-5-20251022", messages, tools);

        assertEquals(ModelTier.LARGE, decision.tier());
        assertTrue(decision.reason().contains("tool"));
    }
}
```

**Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "com.synapse.llm.service.RequestRouterTest.testRoutingWithTools" -v`
Expected: FAIL with "class RequestRouter not found"

**Step 3: Commit**

```bash
git add app/src/test/java/com/synapse/llm/service/RequestRouterTest.java
git commit -m "test: add RequestRouterTest with tool detection test"
```

---

### Task 6: Implement RequestRouter - Tool Detection

**Files:**
- Create: `app/src/main/java/com/synapse/llm/routing/RequestRouter.java`

**Step 1: Write RequestRouter.java with tool detection**

```java
package com.synapse.llm.routing;

import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.metadata.ToolExecution;
import org.springframework.ai.chat.metadata.ToolExecutionRequest;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.stereotype.Component;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.stream.Collectors;

@Component
@Slf4j
public class RequestRouter {

    public RoutingDecision route(String modelName, List<Message> messages, List<Tool> tools) {
        // Rule 1: Check for tools
        if (tools != null && !tools.isEmpty()) {
            log.info("Routing decision: tier=LARGE, reason=tools-array-detected, model={}", modelName);
            return new RoutingDecision(ModelTier.LARGE, "tools-array-detected", modelName, null, null);
        }

        return new RoutingDecision(ModelTier.LARGE, "default", modelName, null, null);
    }
}
```

**Step 2: Run test to verify it passes**

Run: `./gradlew test --tests "com.synapse.llm.service.RequestRouterTest.testRoutingWithTools" -v`
Expected: PASS

**Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/routing/RequestRouter.java
git commit -m "feat: implement RequestRouter with tool detection rule"
```

---

### Task 7: Implement RequestRouter - Remaining Rules

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/routing/RequestRouter.java`

**Step 1: Complete RequestRouter with all 7 rules**

```java
package com.synapse.llm.routing;

import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.stereotype.Component;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.regex.Pattern;

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
            .filter(java.util.Objects::nonNull)
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
```

**Step 2: Run all tests to verify they pass**

Run: `./gradlew test --tests "com.synapse.llm.service.RequestRouterTest" -v`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/routing/RequestRouter.java
git commit -m "feat: complete RequestRouter with all 7 routing rules"
```

---

## Phase 3: Create RoutingAwareChatModel

### Task 8: Create RoutingAwareChatModel

**Files:**
- Create: `app/src/main/java/com/synapse/llm/routing/RoutingAwareChatModel.java`

**Step 1: Write RoutingAwareChatModel.java**

```java
package com.synapse.llm.routing;

import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.StreamingChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.chat.messages.Message;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class RoutingAwareChatModel implements ChatModel, StreamingChatModel {

    private final RequestRouter requestRouter;
    private final Map<String, ChatModel> chatModels;

    @Override
    public ChatResponse call(Prompt prompt) {
        RoutingDecision decision = requestRouter.route(
            prompt.getMetadata() != null ? prompt.getMetadata().getModel() : "default",
            prompt.getMessages(),
            null
        );

        log.info("RoutingAwareChatModel: routing to tier={}, reason={}", decision.tier(), decision.reason());

        ChatModel targetModel = getTargetModel(decision);
        return targetModel.call(prompt);
    }

    @Override
    public ChatResponse call(Message... messages) {
        RoutingDecision decision = requestRouter.route(
            "default",
            List.of(messages),
            null
        );

        log.info("RoutingAwareChatModel: routing to tier={}, reason={}", decision.tier(), decision.reason());

        ChatModel targetModel = getTargetModel(decision);
        return targetModel.call(messages);
    }

    @Override
    public Flux<ChatResponse> stream(Prompt prompt) {
        RoutingDecision decision = requestRouter.route(
            prompt.getMetadata() != null ? prompt.getMetadata().getModel() : "default",
            prompt.getMessages(),
            null
        );

        log.info("RoutingAwareChatModel: streaming routing to tier={}, reason={}", decision.tier(), decision.reason());

        StreamingChatModel targetModel = getStreamingModel(decision);
        return targetModel.stream(prompt);
    }

    @Override
    public Flux<ChatResponse> stream(Message... messages) {
        RoutingDecision decision = requestRouter.route(
            "default",
            List.of(messages),
            null
        );

        log.info("RoutingAwareChatModel: streaming routing to tier={}, reason={}", decision.tier(), decision.reason());

        StreamingChatModel targetModel = getStreamingModel(decision);
        return targetModel.stream(messages);
    }

    private ChatModel getTargetModel(RoutingDecision decision) {
        // For now, return first available model
        // Future: select based on tier
        return chatModels.values().iterator().next();
    }

    private StreamingChatModel getStreamingModel(RoutingDecision decision) {
        // For now, return first available model
        // Future: select based on tier
        return (StreamingChatModel) chatModels.values().iterator().next();
    }
}
```

**Step 2: Verify compilation**

Run: `./gradlew compileJava`
Expected: No compilation errors

**Step 3: Commit**

```bash
git add app/src/main/java/com/synapse/llm/routing/RoutingAwareChatModel.java
git commit -m "feat: add RoutingAwareChatModel with routing delegation"
```

---

## Phase 4: Update AutoConfiguration

### Task 9: Update LlmAutoConfiguration

**Files:**
- Modify: `app/src/main/java/com/synapse/llm/config/LlmAutoConfiguration.java`

**Step 1: Read current LlmAutoConfiguration**

Read: `app/src/main/java/com/synapse/llm/config/LlmAutoConfiguration.java`

**Step 2: Add routing beans**

Add to LlmAutoConfiguration:

```java
@Bean
public RoutingConfig routingConfig() {
    return new RoutingConfig();
}

@Bean
public RequestRouter requestRouter() {
    return new RequestRouter();
}

@Bean
@Primary
public RoutingAwareChatModel routingAwareChatModel(
    RequestRouter requestRouter,
    Map<String, ChatModel> chatModels) {
    return new RoutingAwareChatModel(requestRouter, chatModels);
}
```

**Step 3: Verify compilation**

Run: `./gradlew compileJava`
Expected: No compilation errors

**Step 4: Commit**

```bash
git add app/src/main/java/com/synapse/llm/config/LlmAutoConfiguration.java
git commit -m "feat: add routing beans to LlmAutoConfiguration"
```

---

## Phase 5: Update application.yml

### Task 10: Add Routing Configuration

**Files:**
- Modify: `app/src/main/resources/application.yml`

**Step 1: Read current application.yml**

Read: `app/src/main/resources/application.yml`

**Step 2: Add routing section**

Add after existing llm configuration:

```yaml
llm:
  routing:
    enabled: true
    small-model: claude-haiku-4-5
    large-model: claude-sonnet-4-5-20251022
    servers:
      small:
        instance-id: g139-9b
        api-base: https://u425-twwp-6d5643db.singapore-b.gpuhub.com:8443/v1
        api-key: ${GPUHUB_API_KEY:"test-key"}
        model-name: Qwen3.5-9B
        tier: SMALL
      large:
        instance-id: g145-35b
        api-base: https://u425-u70w-e4420dcd.singapore-b.gpuhub.com:8443/v1
        api-key: ${GPUHUB_API_KEY:"test-key"}
        model-name: Qwen3.5-35B
        tier: LARGE
```

**Step 3: Verify YAML syntax**

Run: `cat app/src/main/resources/application.yml`
Expected: Valid YAML with routing section

**Step 4: Commit**

```bash
git add app/src/main/resources/application.yml
git commit -m "feat: add routing configuration to application.yml"
```

---

## Phase 6: Complete RequestRouter Tests

### Task 11: Complete RequestRouter Test Suite

**Files:**
- Modify: `app/src/test/java/com/synapse/llm/service/RequestRouterTest.java`

**Step 1: Read current test file**

Read: `app/src/test/java/com/synapse/llm/service/RequestRouterTest.java`

**Step 2: Add all routing rule tests**

Complete test file with tests for all 7 rules plus edge cases.

**Step 3: Run all tests**

Run: `./gradlew test --tests "com.synapse.llm.service.RequestRouterTest" -v`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add app/src/test/java/com/synapse/llm/service/RequestRouterTest.java
git commit -m "test: complete RequestRouter test suite for all routing rules"
```

---

## Verification

### Compile

```bash
./gradlew compileJava
```

### Run Tests

```bash
./gradlew test --tests "com.synapse.llm.service.RequestRouterTest"
```

### Run All Tests

```bash
./gradlew test
```

### Start Application

```bash
./gradlew bootRun
```

### Test Routing via API

Send simple query → should log routing to SMALL
Send complex query with code → should log routing to LARGE

---

## Dependencies

- Spring Boot 3.x
- Spring AI 1.x
- Lombok @Slf4j
- Reactor (WebFlux)

---

## Notes

- All classes in package `com.synapse.llm.routing`
- Use Java 21 features (records, pattern matching)
- No `.block()` calls - fully reactive
- Logging at INFO level via @Slf4j
- Keep implementation simple - follow YAGNI principle
