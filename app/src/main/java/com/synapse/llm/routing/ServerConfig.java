package com.synapse.llm.routing;

public record ServerConfig(
    String instanceId,
    String apiBase,
    String apiKey,
    String servedModelName
) {}
