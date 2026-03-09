package com.synapse.llm.routing;

public record RoutingDecision(
    ModelTier tier,
    String reason,
    String targetModelName,
    String targetApiBase,
    String targetApiKey
) {}
