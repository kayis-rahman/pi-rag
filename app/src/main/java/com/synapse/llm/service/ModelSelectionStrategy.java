package com.synapse.llm.service;

import java.util.List;

public interface ModelSelectionStrategy {
    String selectModel(List<String> modelNames);
}
