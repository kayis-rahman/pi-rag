package com.synapse.llm.config;

import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.boot.actuate.autoconfigure.metrics.MeterRegistryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for Micrometer metrics in Synapse routing system.
 * Provides custom meters for LLM routing, model usage, and API performance.
 */
@Configuration
public class MetricsConfig {

    /**
     * Custom tags for all metrics (e.g., environment, service name).
     */
    @Bean
    public MeterRegistryCustomizer<MeterRegistry> metricsCustomizer() {
        return registry -> registry.config()
            .commonTags("service", "synapse")
            .commonTags("environment", "development");
    }
}
