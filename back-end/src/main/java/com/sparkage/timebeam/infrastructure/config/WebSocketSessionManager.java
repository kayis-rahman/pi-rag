package com.sparkage.timebeam.infrastructure.config;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketSession;

@Component
public class WebSocketSessionManager {

    private final Map<UUID, List<WebSocketSession>> userSessions = new ConcurrentHashMap<>();

    public void register(UUID userId, WebSocketSession session) {
        userSessions.computeIfAbsent(userId, k -> new ArrayList<>()).add(session);
    }

    public void unregister(UUID userId, WebSocketSession session) {
        List<WebSocketSession> sessions = userSessions.get(userId);
        if (sessions != null) {
            sessions.remove(session);
            if (sessions.isEmpty()) {
                userSessions.remove(userId);
            }
        }
    }

    public List<WebSocketSession> getSessions(UUID userId) {
        List<WebSocketSession> sessions = userSessions.get(userId);
        return sessions != null ? Collections.unmodifiableList(sessions) : List.of();
    }

    public int count() {
        return userSessions.values().stream().mapToInt(List::size).sum();
    }
}
