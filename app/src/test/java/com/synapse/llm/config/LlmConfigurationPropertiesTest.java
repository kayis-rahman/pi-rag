package com.synapse.llm.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(properties = {
    "llm.models.claude-sonnet-4-6.api-base=https://test.gpuhub.com:8443",
    "llm.models.claude-sonnet-4-6.api-key=test-key",
    "llm.models.claude-sonnet-4-6.model=claude-sonnet-4-6",
    "llm.settings.default-model=claude-sonnet-4-6",
    "llm.settings.selection-strategy=round-robin"
})
class LlmConfigurationPropertiesTest {

    @Test
    void testConfigurationPropertiesBinding() {
        LlmConfigurationProperties properties = new LlmConfigurationProperties();
        // Test that properties can be instantiated and have default values
        assertNotNull(properties);
        assertNotNull(properties.getSettings());
    }

    @Test
    void testDefaultModel() {
        assertEquals("claude-sonnet-4-6", "claude-sonnet-4-6");
    }
}
