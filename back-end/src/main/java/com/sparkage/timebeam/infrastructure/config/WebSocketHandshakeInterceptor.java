package com.sparkage.timebeam.infrastructure.config;

import java.util.Map;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import com.sparkage.timebeam.infrastructure.external.JwtUtils;

@Component
public class WebSocketHandshakeInterceptor implements HandshakeInterceptor {

    private static final Logger log = LoggerFactory.getLogger(WebSocketHandshakeInterceptor.class);

    private final JwtUtils jwtUtils;

    public WebSocketHandshakeInterceptor(JwtUtils jwtUtils) {
        this.jwtUtils = jwtUtils;
    }

    private String extractToken(String query) {
        if (query == null) return null;
        String[] params = query.split("&");
        for (String param : params) {
            String[] parts = param.split("=", 2);
            if (parts.length == 2 && "token".equals(parts[0])) {
                try {
                    return java.net.URLDecoder.decode(parts[1], "UTF-8");
                } catch (Exception e) {
                    return parts[1];
                }
            }
        }
        return null;
    }

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                    WebSocketHandler handler, Map<String, Object> attributes) {
        String token = extractToken(request.getURI().getQuery());
        if (token == null || token.isBlank()) {
            log.warn("WebSocket handshake rejected: no token");
            return false;
        }

        try {
            if (!jwtUtils.validateToken(token)) {
                log.warn("WebSocket handshake rejected: invalid token");
                return false;
            }

            UUID userId = jwtUtils.parseUserId(token);
            attributes.put("userId", userId);
            log.info("WebSocket handshake authenticated: user={}", userId);
            return true;
        } catch (Exception e) {
            log.error("WebSocket handshake error: {}", e.getMessage());
            return false;
        }
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                WebSocketHandler handler, Exception exception) {
        // userId already in attributes from beforeHandshake
    }
}
