package com.synapse.llm.logging;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

/**
 * Inspect all incoming requests to see what Claude Code (or any client) is sending.
 * Logs headers, method, path, content-type, etc.
 * Uses WebFilter for WebFlux compatibility.
 */
@Component
@Slf4j
public class RequestInspectorFilter implements WebFilter {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();

        // Skip logging for actuator endpoints (health, prometheus, etc.)
        if (path.startsWith("/actuator")) {
            return chain.filter(exchange);
        }

        String method = exchange.getRequest().getMethod().toString();
        String contentType = exchange.getRequest().getHeaders().getContentType() != null ?
                exchange.getRequest().getHeaders().getContentType().toString() : "none";

        // Log request metadata
        log.info("🔍 INCOMING REQUEST: {} {} | Content-Type: {}", method, path, contentType);

        // Log all headers
        exchange.getRequest().getHeaders().forEach((headerName, headerValues) -> {
            if (isSafeToLog(headerName)) {
                log.info("  📌 {} = {}", headerName, String.join(", ", headerValues));
            } else {
                log.info("  📌 {} = [REDACTED]", headerName);
            }
        });

        // Log remote info
        var remoteAddr = exchange.getRequest().getRemoteAddress();
        log.info("  🌐 Remote: {}", remoteAddr != null ? remoteAddr.getHostName() : "unknown");
        log.info("  👤 User-Agent: {}", exchange.getRequest().getHeaders().getFirst("user-agent"));

        // Check for session identifier
        String sessionId = exchange.getRequest().getHeaders().getFirst("X-Session-ID");
        if (sessionId != null) {
            log.info("  🎫 X-Session-ID: {}", sessionId);
        }

        return chain.filter(exchange);
    }

    private boolean isSafeToLog(String headerName) {
        String lower = headerName.toLowerCase();
        return !lower.contains("authorization") &&
               !lower.contains("cookie") &&
               !lower.contains("token") &&
               !lower.contains("api-key") &&
               !lower.contains("secret");
    }
}
