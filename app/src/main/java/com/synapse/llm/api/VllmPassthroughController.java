package com.synapse.llm.api;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import java.util.Set;

@RestController
@RequestMapping("/**")
@Slf4j
public class VllmPassthroughController {

    private static final Set<String> HOP_BY_HOP = Set.of(
        "host", "connection", "keep-alive", "transfer-encoding",
        "upgrade", "proxy-authenticate", "proxy-authorization", "te", "trailer"
    );

    private final WebClient vllmWebClient;

    public VllmPassthroughController(@Qualifier("vllmWebClient") WebClient vllmWebClient) {
        this.vllmWebClient = vllmWebClient;
    }

    @GetMapping
    public Mono<ResponseEntity<Flux<DataBuffer>>> proxyGet(ServerWebExchange exchange) {
        return proxy(exchange, HttpMethod.GET, Flux.empty());
    }

    @PostMapping
    public Mono<ResponseEntity<Flux<DataBuffer>>> proxyPost(
            ServerWebExchange exchange,
            @RequestBody(required = false) Flux<DataBuffer> body) {
        return proxy(exchange, HttpMethod.POST, body != null ? body : Flux.empty());
    }

    private Mono<ResponseEntity<Flux<DataBuffer>>> proxy(
            ServerWebExchange exchange, HttpMethod method, Flux<DataBuffer> body) {

        String path = exchange.getRequest().getPath().value();
        String query = exchange.getRequest().getURI().getRawQuery();
        String fullPath = query != null ? path + "?" + query : path;

        log.info("Passthrough {} {}", method, fullPath);

        HttpHeaders upstreamHeaders = new HttpHeaders();
        exchange.getRequest().getHeaders().forEach((name, values) -> {
            if (!HOP_BY_HOP.contains(name.toLowerCase())) {
                upstreamHeaders.addAll(name, values);
            }
        });

        return vllmWebClient
                .method(method)
                .uri(fullPath)
                .headers(h -> h.addAll(upstreamHeaders))
                .body(body, DataBuffer.class)
                .exchangeToMono(clientResponse -> {
                    HttpStatus status = (HttpStatus) clientResponse.statusCode();
                    HttpHeaders responseHeaders = new HttpHeaders();
                    clientResponse.headers().asHttpHeaders().forEach((name, values) -> {
                        if (!HOP_BY_HOP.contains(name.toLowerCase()) &&
                            !name.equalsIgnoreCase("content-length")) {
                            responseHeaders.addAll(name, values);
                        }
                    });
                    Flux<DataBuffer> responseBody = clientResponse.bodyToFlux(DataBuffer.class);
                    return Mono.just(ResponseEntity.status(status)
                            .headers(responseHeaders)
                            .body(responseBody));
                })
                .onErrorResume(e -> {
                    log.error("vLLM upstream error {} {}: {}", method, fullPath, e.getMessage());
                    return Mono.just(ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                            .body(Flux.empty()));
                });
    }
}
