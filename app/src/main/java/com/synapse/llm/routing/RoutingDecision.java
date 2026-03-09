package com.synapse.llm.routing;

public record RoutingDecision(
    ModelTier tier,
    String reason,
    String servedModelName,
    String apiBase,
    String apiKey
) {}
