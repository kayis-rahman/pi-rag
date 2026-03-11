package com.synapse.llm.config;

import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class LlmConfigurationPropertiesTest {

    @Test
    void testConfigurationPropertiesBinding() {
        LlmConfigurationProperties properties = new LlmConfigurationProperties();
        assertNotNull(properties);
        assertNotNull(properties.getSettings());
    }

    @Test
    void testDefaultSettingsAreInitialized() {
        LlmConfigurationProperties props = new LlmConfigurationProperties();

        assertNotNull(props.getSettings());
        assertEquals("claude-sonnet-4-6", props.getSettings().getDefaultModel());
        assertEquals("round-robin", props.getSettings().getSelectionStrategy());
    }

    @Test
    void testToModelMapConvertsListToMap() {
        ModelConfiguration mc1 = new ModelConfiguration();
        mc1.setModelName("model1");
        ModelConfiguration.LiteLLMParams params1 = new ModelConfiguration.LiteLLMParams();
        params1.setModel("m1");
        params1.setApiBase("https://a.com");
        params1.setApiKey("k1");
        mc1.setLitellmParams(params1);

        ModelConfiguration mc2 = new ModelConfiguration();
        mc2.setModelName("model2");
        ModelConfiguration.LiteLLMParams params2 = new ModelConfiguration.LiteLLMParams();
        params2.setModel("m2");
        params2.setApiBase("https://b.com");
        params2.setApiKey("k2");
        mc2.setLitellmParams(params2);

        List<ModelConfiguration> models = Arrays.asList(mc1, mc2);

        LlmConfigurationProperties props = new LlmConfigurationProperties();
        props.setModelList(models);

        Map<String, ModelConfiguration> result = props.toModelMap();

        assertEquals(2, result.size());
        assertTrue(result.containsKey("model1"));
        assertTrue(result.containsKey("model2"));
        assertEquals("https://a.com", result.get("model1").getLitellmParams().getApiBase());
    }

    @Test
    void testModelListSetter() {
        ModelConfiguration mc = new ModelConfiguration();
        mc.setModelName("test-model");
        ModelConfiguration.LiteLLMParams params = new ModelConfiguration.LiteLLMParams();
        params.setModel("tm");
        params.setApiBase("https://test.com");
        params.setApiKey("key");
        mc.setLitellmParams(params);

        List<ModelConfiguration> models = Arrays.asList(mc);

        LlmConfigurationProperties props = new LlmConfigurationProperties();
        props.setModelList(models);

        assertEquals(1, props.getModelList().size());
        assertEquals("test-model", props.getModelList().get(0).getModelName());
    }

    @Test
    void testLiteLLMSettingsGetterSetter() {
        ModelConfiguration.LiteLLMSettings settings = new ModelConfiguration.LiteLLMSettings();
        settings.setDropParams(true);
        settings.setSetVerbose(false);

        LlmConfigurationProperties props = new LlmConfigurationProperties();
        props.setLitellmSettings(settings);

        assertEquals(Boolean.TRUE, props.getLitellmSettings().getDropParams());
        assertEquals(Boolean.FALSE, props.getLitellmSettings().getSetVerbose());
    }
}
