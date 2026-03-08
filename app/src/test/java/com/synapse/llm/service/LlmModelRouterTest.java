package com.synapse.llm.service;

import com.synapse.llm.config.LlmConfigurationProperties;
import com.synapse.llm.config.ModelConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class LlmModelRouterTest {

    @Autowired(required = false)
    private LlmModelRouter router;

    @Test
    void testRouterInitialization() {
        assertNotNull(router);
    }

    @Test
    void testGetAvailableModels() {
        assertNotNull(router.getAvailableModels());
        assertTrue(router.getAvailableModels().size() > 0);
    }

    @Test
    void testGetSelectedModel() {
        String model = router.getSelectedModel();
        assertNotNull(model);
        assertTrue(router.getAvailableModels().contains(model));
    }
}
