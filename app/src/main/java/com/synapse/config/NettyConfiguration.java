package com.synapse.config;

import reactor.netty.resources.ConnectionProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class NettyConfiguration {

    @Bean
    public ConnectionProvider connectionProvider() {
        return ConnectionProvider.builder("synapse-connection-pool")
                .maxConnections(10000)
                .maxIdleTime(java.time.Duration.ofSeconds(30))
                .maxLifeTime(java.time.Duration.ofMinutes(1))
                .pendingAcquireMaxCount(10000)
                .pendingAcquireTimeout(java.time.Duration.ofSeconds(45))
                .build();
    }
}
