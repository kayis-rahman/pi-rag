package com.synapse.llm.config;

import io.micrometer.core.aop.TimedAspect;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tag;
import io.micrometer.core.instrument.Tags;
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

    /**
     * TimedAspect for @Timed annotation support on methods.
     */
    @Bean
    public TimedAspect timedAspect() {
        return new TimedAspect();
    }
}
