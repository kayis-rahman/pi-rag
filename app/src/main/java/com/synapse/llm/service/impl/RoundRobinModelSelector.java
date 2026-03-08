package com.synapse.llm.service.impl;

import com.synapse.llm.service.ModelSelectionStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

public class RoundRobinModelSelector implements ModelSelectionStrategy {

    private static final Logger logger = LoggerFactory.getLogger(RoundRobinModelSelector.class);
    private final AtomicInteger counter = new AtomicInteger(0);
    private final List<String> modelNames;

    public RoundRobinModelSelector(List<String> modelNames) {
        this.modelNames = modelNames;
        logger.info("RoundRobinModelSelector initialized with {} models", modelNames.size());
    }

    @Override
    public String selectModel(List<String> modelNames) {
        if (modelNames.isEmpty()) {
            throw new IllegalStateException("No models available for selection");
        }

        int index = counter.getAndIncrement() % modelNames.size();
        String selectedModel = modelNames.get(index);
        logger.debug("Round-robin selected model: {} (index: {})", selectedModel, index);
        return selectedModel;
    }
}
