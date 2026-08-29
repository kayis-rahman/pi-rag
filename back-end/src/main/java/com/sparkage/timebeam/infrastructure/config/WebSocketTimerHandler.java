package com.sparkage.timebeam.infrastructure.config;

import java.io.IOException;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sparkage.timebeam.application.service.TimerSyncService;
import com.sparkage.timebeam.presentation.dto.TimerStateDto;

@Component
public class WebSocketTimerHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(WebSocketTimerHandler.class);

    private final WebSocketSessionManager sessionManager;
    private final TimerSyncService timerSyncService;
    private final ObjectMapper objectMapper;

    public WebSocketTimerHandler(WebSocketSessionManager sessionManager,
                                  TimerSyncService timerSyncService,
                                  ObjectMapper objectMapper) {
        this.sessionManager = sessionManager;
        this.timerSyncService = timerSyncService;
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        UUID userId = (UUID) session.getAttributes().get("userId");
        if (userId == null) {
            log.warn("WebSocket connection without userId — closing");
            try { session.close(CloseStatus.POLICY_VIOLATION); } catch (IOException e) { /* ignore */ }
            return;
        }

        sessionManager.register(userId, session);
        log.info("WebSocket registered: user={}, total={}", userId, sessionManager.count());

        // Send current timer state so new connection gets live snapshot
        timerSyncService.pullTimerState(userId).ifPresent(state -> {
            try {
                Map<String, Object> payload = new HashMap<>();
                payload.put("type", "state");
                payload.put("phase", state.getPhase());
                payload.put("remainingSeconds", state.getRemainingSeconds());
                payload.put("isRunning", state.getIsRunning());
                payload.put("workDuration", state.getWorkDuration());
                payload.put("breakDuration", state.getBreakDuration());
                payload.put("longBreakDuration", state.getLongBreakDuration());
                payload.put("autoStartNextSession", state.getAutoStartNextSession());
                payload.put("shortBreaksCompleted", state.getShortBreaksCompleted());
                payload.put("totalDuration", state.getTotalDuration());
                payload.put("startTimestamp", state.getStartTimestamp());
                payload.put("pauseTimestamp", state.getPauseTimestamp());
                payload.put("lastModifiedTimestamp", state.getLastModifiedTimestamp() != null
                        ? state.getLastModifiedTimestamp().toEpochMilli() / 1000.0 : 0);
                payload.put("deviceId", state.getDeviceId());
                session.sendMessage(new TextMessage(objectMapper.writeValueAsString(payload)));
                log.info("Sent initial state to new WebSocket connection: user={}", userId);
            } catch (IOException e) {
                log.error("Failed to send initial state via WebSocket: user={}", userId, e);
            }
        });
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage textMessage) throws IOException {
        UUID userId = (UUID) session.getAttributes().get("userId");
        if (userId == null) return;

        String message = textMessage.getPayload();
        try {
            Map<String, Object> json = objectMapper.readValue(message, Map.class);
            @SuppressWarnings("unchecked")
            Map<String, Object> data = json;
            String type = (String) data.get("type");

            if ("action".equals(type)) {
                String action = (String) data.getOrDefault("action", "");
                String phase = (String) data.getOrDefault("phase", "work");
                boolean isRunning = objectMapper.convertValue(data.get("isRunning"), Boolean.class);
                int remainingSeconds = objectMapper.convertValue(data.getOrDefault("remainingSeconds", 0), Integer.class);
                int workDuration = objectMapper.convertValue(data.getOrDefault("workDuration", 1500), Integer.class);
                int breakDuration = objectMapper.convertValue(data.getOrDefault("breakDuration", 300), Integer.class);
                int longBreakDuration = objectMapper.convertValue(data.getOrDefault("longBreakDuration", 900), Integer.class);
                boolean autoStartNext = objectMapper.convertValue(data.getOrDefault("autoStartNextSession", false), Boolean.class);
                int shortBreaksCompleted = objectMapper.convertValue(data.getOrDefault("shortBreaksCompleted", 0), Integer.class);
                String deviceId = (String) data.getOrDefault("deviceId", "");
                double timestamp = objectMapper.convertValue(data.getOrDefault("timestamp", 0), Double.class);

                // Store deviceId in session attributes for broadcast filtering
                if (!deviceId.isEmpty()) {
                    session.getAttributes().put("deviceId", deviceId);
                }

                // Build state from action and push to backend
                TimerStateDto state = new TimerStateDto(
                    phase, remainingSeconds, isRunning,
                    workDuration, breakDuration, longBreakDuration,
                    autoStartNext, shortBreaksCompleted,
                    workDuration,
                    timestamp > 0 ? timestamp : Instant.now().toEpochMilli() / 1000.0,
                    null,
                    Instant.now(),
                    deviceId
                );

                timerSyncService.pushTimerState(userId, state, deviceId);
                log.info("WebSocket action received: user={}, action={}, phase={}", userId, action, phase);

            } else if ("ping".equals(type)) {
                session.sendMessage(new TextMessage("{\"type\":\"pong\"}"));
            }
        } catch (Exception e) {
            log.error("Error handling WebSocket message: user={}, message={}", userId, message, e);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        UUID userId = (UUID) session.getAttributes().get("userId");
        if (userId != null) {
            sessionManager.unregister(userId, session);
            log.info("WebSocket closed: user={}, status={}, total={}", userId, status, sessionManager.count());
        }
    }
}
