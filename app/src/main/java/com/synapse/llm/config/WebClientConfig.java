package com.synapse.llm.config;

import io.netty.channel.ChannelOption;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;
import java.time.Duration;

@Configuration
@RequiredArgsConstructor
public class WebClientConfig {
    private final LlmConfigurationProperties llmProps;

    @Bean(name = "vllmWebClient")
    public WebClient vllmWebClient() {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS,
                        (int) Duration.ofSeconds(llmProps.getQwen().getTimeoutSeconds()).toMillis())
                .responseTimeout(Duration.ofSeconds(llmProps.getQwen().getTimeoutSeconds()));

        ExchangeStrategies strategies = ExchangeStrategies.builder()
                .codecs(config -> config.defaultCodecs().maxInMemorySize(-1))
                .build();

        return WebClient.builder()
                .baseUrl(llmProps.getQwen().getServerUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .exchangeStrategies(strategies)
                .build();
    }
}
