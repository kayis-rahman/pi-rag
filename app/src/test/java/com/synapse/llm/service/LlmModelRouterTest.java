package com.synapse.llm.service;

import com.synapse.llm.config.LlmConfigurationProperties;
import com.synapse.llm.config.ModelConfiguration;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class LlmModelRouterTest {

    @Test
    void testRouterInitialization() {
        LlmConfigurationProperties properties = new LlmConfigurationProperties();
        properties.setModels(Map.of(
            "claude-sonnet-4-6", new ModelConfiguration("https://test.gpuhub.com:8443", "key", "claude-sonnet-4-6")
        ));

        LlmModelRouter router = new LlmModelRouter(properties, Map.of());
        assertNotNull(router);
    }

    @Test
    void testGetAvailableModels() {
        LlmConfigurationProperties properties = new LlmConfigurationProperties();
        properties.setModels(Map.of(
            "model1", new ModelConfiguration("https://test1.com", "key", "model1"),
            "model2", new ModelConfiguration("https://test2.com", "key", "model2"),
            "model3", new ModelConfiguration("https://test3.com", "key", "model3")
        ));

        LlmModelRouter router = new LlmModelRouter(properties, Map.of());
        assertNotNull(router.getAvailableModels());
        assertEquals(3, router.getAvailableModels().size());
    }

    @Test
    void testGetSelectedModel() {
        LlmConfigurationProperties properties = new LlmConfigurationProperties();
        properties.setModels(Map.of(
            "model1", new ModelConfiguration("https://test1.com", "key", "model1"),
            "model2", new ModelConfiguration("https://test2.com", "key", "model2")
        ));

        LlmModelRouter router = new LlmModelRouter(properties, Map.of());
        String model = router.getSelectedModel();
        assertNotNull(model);
        assertTrue(router.getAvailableModels().contains(model));
    }

    @Test
    void testRoundRobinSelection() {
        LlmConfigurationProperties properties = new LlmConfigurationProperties();
        properties.setModels(Map.of(
            "model1", new ModelConfiguration("https://test1.com", "key", "model1"),
            "model2", new ModelConfiguration("https://test2.com", "key", "model2"),
            "model3", new ModelConfiguration("https://test3.com", "key", "model3")
        ));

        LlmModelRouter router = new LlmModelRouter(properties, Map.of());

        String first = router.getSelectedModel();
        String second = router.getSelectedModel();
        String third = router.getSelectedModel();
        String fourth = router.getSelectedModel();

        // Verify round-robin cycling - all selections should be valid models
        assertTrue(router.getAvailableModels().contains(first));
        assertTrue(router.getAvailableModels().contains(second));
        assertTrue(router.getAvailableModels().contains(third));
        assertTrue(router.getAvailableModels().contains(fourth));

        // Verify cycling - fourth should equal first (cycle complete)
        assertEquals(first, fourth);

        // Verify not all same (round-robin is working)
        assertNotEquals(first, second);
    }

    @Test
    void testGetModelConfiguration() {
        LlmConfigurationProperties properties = new LlmConfigurationProperties();
        ModelConfiguration config = new ModelConfiguration("https://test.gpuhub.com:8443", "local-key", "claude-sonnet-4-6");
        properties.setModels(Map.of("claude-sonnet-4-6", config));

        LlmModelRouter router = new LlmModelRouter(properties, Map.of());
        ModelConfiguration retrieved = router.getModelConfiguration("claude-sonnet-4-6");

        assertNotNull(retrieved);
        assertEquals("https://test.gpuhub.com:8443", retrieved.getApiBase());
        assertEquals("local-key", retrieved.getApiKey());
        assertEquals("claude-sonnet-4-6", retrieved.getModel());
    }
}
