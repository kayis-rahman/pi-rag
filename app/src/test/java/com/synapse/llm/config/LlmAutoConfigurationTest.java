package com.synapse.llm.config;

import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;

import java.util.Arrays;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class LlmAutoConfigurationTest {

    @Autowired
    private ApplicationContext applicationContext;

    @Test
    void testChatModelsBeanReturnsMap() {
        Map<String, ChatModel> chatModels =
            applicationContext.getBeansOfType(ChatModel.class);

        // 5 individual model beans + RoutingAwareChatModel (@Component) + routingAwareChatModel (@Bean @Primary)
        assertEquals(7, chatModels.size());
        assertTrue(chatModels.containsKey("claude-sonnet-4-6"));
        assertTrue(chatModels.containsKey("claude-sonnet-4-5-20251022"));
        assertTrue(chatModels.containsKey("claude-sonnet-4-5"));
        assertTrue(chatModels.containsKey("claude-haiku-4-5-20251001"));
        assertTrue(chatModels.containsKey("claude-haiku-4-5"));
    }

    @Test
    void testIndividualModelBeansCreated() {
        String[] beanNames = applicationContext.getBeanNamesForType(ChatModel.class);

        // 5 individual model beans + RoutingAwareChatModel (@Component) + routingAwareChatModel (@Bean @Primary)
        assertEquals(7, beanNames.length);
        assertTrue(Arrays.asList(beanNames).contains("claudeSonnet46ChatModel"));
        assertTrue(Arrays.asList(beanNames).contains("claudeSonnet4520251022ChatModel"));
        assertTrue(Arrays.asList(beanNames).contains("claudeSonnet45ChatModel"));
        assertTrue(Arrays.asList(beanNames).contains("claudeHaiku4520251001ChatModel"));
        assertTrue(Arrays.asList(beanNames).contains("claudeHaiku45ChatModel"));
        assertTrue(Arrays.asList(beanNames).contains("routingAwareChatModel"));
    }

    @Test
    void testChatModelsBeanKeysMatchModelNames() {
        Map<String, ChatModel> chatModels =
            applicationContext.getBeansOfType(ChatModel.class);

        // Verify keys are model names without suffix
        assertTrue(chatModels.containsKey("claude-sonnet-4-6"));
        assertTrue(chatModels.containsKey("claude-haiku-4-5"));
    }

    @Test
    void testModelConfigurationsBeanExists() {
        Map<String, ModelConfiguration> configs =
            applicationContext.getBeansOfType(ModelConfiguration.class);

        assertNotNull(configs);
    }
}
