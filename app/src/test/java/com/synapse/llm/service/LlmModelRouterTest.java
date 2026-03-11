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
        String text = "The quick brown fox jumps over the lazy dog repeatedly. " +
            "This sentence has enough words to exceed the threshold without triggering " +
            "any specific routing rule based on keywords or code detection in the text.";
        List<Message> msgs = List.of(new UserMessage(text));
        RoutingDecision decision = router.route("unknown-model", msgs, false);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("default_fallback", decision.reason());
    }

    // Priority: Rule 1 beats modelTierMap (Rule 3)
    @Test
    void priority_rule1_beatsModelTierMap() {
        List<Message> msgs = List.of(new UserMessage("What is 2+2?"));
        RoutingDecision decision = router.route("claude-haiku-4-5", msgs, true);
        assertEquals(ModelTier.LARGE, decision.tier());
        assertEquals("tool_use", decision.reason());
    }
}
