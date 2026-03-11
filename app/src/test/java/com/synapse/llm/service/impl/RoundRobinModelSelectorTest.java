package com.synapse.llm.service.impl;

import com.synapse.llm.service.ModelSelectionStrategy;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class RoundRobinModelSelectorTest {

    @Test
    void testRoundRobinSelection() {
        List<String> models = Arrays.asList("model1", "model2", "model3");
        ModelSelectionStrategy strategy = new RoundRobinModelSelector(models);

        String first = strategy.selectModel(models);
        String second = strategy.selectModel(models);
        String third = strategy.selectModel(models);
        String fourth = strategy.selectModel(models);

        assertEquals("model1", first);
        assertEquals("model2", second);
        assertEquals("model3", third);
        assertEquals("model1", fourth);
    }

    @Test
    void testEmptyModels() {
        List<String> emptyModels = Arrays.asList();
        ModelSelectionStrategy strategy = new RoundRobinModelSelector(emptyModels);

        assertThrows(IllegalStateException.class, () -> {
            strategy.selectModel(emptyModels);
        });
    }
}
