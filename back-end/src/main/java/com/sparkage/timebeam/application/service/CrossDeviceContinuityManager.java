package com.sparkage.timebeam.application.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sparkage.timebeam.domain.model.TimerState;
import com.sparkage.timebeam.domain.model.TimerStateChangeEvent;
import com.sparkage.timebeam.application.dto.TimerStateDto;
import com.sparkage.timebeam.application.dto.VectorClock;
import com.sparkage.timebeam.infrastructure.persistence.UserDeviceRepository;
import com.sparkage.timebeam.infrastructure.persistence.UserSyncPreferences;
import com.sparkage.timebeam.infrastructure.persistence.UserSyncPreferencesRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

/**
 * Cross-Device Continuity Manager
 * Handles smart conflict resolution and device priority for seamless multi-device experience
 */
@Service
public class CrossDeviceContinuityManager {
    private static final Logger log = LoggerFactory.getLogger(CrossDeviceContinuityManager.class);
    
    private final UserDeviceRepository deviceRepository;
    private final UserSyncPreferencesRepository preferencesRepository;
    private final ObjectMapper objectMapper;
    
    // In-memory cache for device states
    private final Map<UUID, DeviceState> deviceStates = new ConcurrentHashMap<>();
    
    public CrossDeviceContinuityManager(UserDeviceRepository deviceRepository,
                                     UserSyncPreferencesRepository preferencesRepository,
                                     ObjectMapper objectMapper) {
        this.deviceRepository = deviceRepository;
        this.preferencesRepository = preferencesRepository;
        this.objectMapper = objectMapper;
    }
    
    /**
     * Handle concurrent timer event from multiple devices
     * Implements smart conflict resolution based on user preferences
     */
    @Transactional
    public TimerStateChangeEvent resolveConflict(UUID userId, List<TimerStateChangeEvent> concurrentEvents) {
        log.info("Resolving conflict for user={}, concurrentEvents={}", userId, concurrentEvents.size());
        
        // Get user's conflict resolution preference
        ConflictResolutionStrategy strategy = getConflictResolutionStrategy(userId);
        TimerStateChangeEvent resolvedEvent = null;
        
        switch (strategy) {
            case LATEST_EVENT_WINS:
                resolvedEvent = resolveLatestEvent(concurrentEvents);
                break;
                
            case DEVICE_PRIORITY:
                resolvedEvent = resolveDevicePriority(concurrentEvents);
                break;
                
            case USER_CHOICE:
                resolvedEvent = resolveUserChoice(userId, concurrentEvents);
                break;
                
            case TIME_BASED:
                resolvedEvent = resolveTimeBased(concurrentEvents);
                break;
        }
        
        // Record conflict resolution in database
        if (resolvedEvent != null) {
            recordConflictResolution(userId, concurrentEvents, resolvedEvent);
        }
        
        return resolvedEvent;
    }
    
    /**
     * Get user's conflict resolution preference
     */
    private ConflictResolutionStrategy getConflictResolutionStrategy(UUID userId) {
        Optional<UserSyncPreferences> prefs = preferencesRepository.findByUserId(userId);
        return prefs.map(UserSyncPreferences::getConflictResolutionStrategy)
                  .orElse(ConflictResolutionStrategy.LATEST_EVENT_WINS);
    }
    
    /**
     * Resolve conflict using latest event (chronological)
     */
    private TimerStateChangeEvent resolveLatestEvent(List<TimerStateChangeEvent> events) {
        return events.stream()
                .max(Comparator.comparing(TimerStateChangeEvent::getTimestamp))
                .orElse(null);
    }
    
    /**
     * Resolve conflict using device priority
     */
    private TimerStateChangeEvent resolveDevicePriority(List<TimerStateChangeEvent> events) {
        Map<String, Integer> devicePriority = Map.of(
            "macos", 1,    // Highest priority for work
            "ios", 2,        // Medium priority
            "watchos", 3    // Lowest priority for notifications
        ));
        
        return events.stream()
                .max(Comparator.comparingInt(
                    (e1, e2) -> {
                        Integer priority1 = devicePriority.getOrDefault(e1.getSourceDeviceId(), 4);
                        Integer priority2 = devicePriority.getOrDefault(e2.getSourceDeviceId(), 4);
                        return priority1.compareTo(priority2);
                    })
                .orElse(null);
    }
    
    /**
     * Generate user choice for conflict resolution
     */
    private TimerStateChangeEvent resolveUserChoice(UUID userId, List<TimerStateChangeEvent> events) {
        // Find the two most recent conflicting events
        List<TimerStateChangeEvent> recentEvents = events.stream()
                .sorted(Comparator.comparing(TimerStateChangeEvent::getTimestamp))
                .limit(2)
                .toList();
        
        if (recentEvents.size() < 2) {
            return resolveLatestEvent(events);
        }
        
        // Create user choice event with preference data
        TimerStateChangeEvent conflictEvent = TimerStateChangeEvent.builder()
                .userId(userId)
                .sourceDeviceId("user-choice")
                .phase("CONFLICT_RESOLUTION")
                .action("USER_CHOICE")
                .timestamp(Instant.now())
                .build();
        
        // Store in device cache for UI presentation
        deviceStates.put(userId, DeviceState.builder()
                .conflictEvent(conflictEvent)
                .recentEvents(recentEvents)
                .state(DeviceState.State.CONFLICT_RESOLUTION_REQUIRED)
                .build());
        
        return conflictEvent;
    }
    
    /**
     * Resolve conflict based on time remaining calculations
     */
    private TimerStateChangeEvent resolveTimeBased(List<TimerStateChangeEvent> events) {
        return events.stream()
                .max(Comparator.comparingInt((e1, e2) -> {
                    Integer time1 = e1.getNewState().getRemainingSeconds();
                    Integer time2 = e2.getNewState().getRemainingSeconds();
                    return Integer.compare(time1, time2);
                }))
                .orElse(null);
    }
    
    /**
     * Record conflict resolution for analytics and debugging
     */
    private void recordConflictResolution(UUID userId, List<TimerStateChangeEvent> originalEvents, 
                                           TimerStateChangeEvent resolvedEvent) {
        try {
            JsonNode resolution = objectMapper.createObjectNode();
            resolution.put("userId", userId.toString());
            resolution.put("originalEventCount", originalEvents.size());
            resolution.put("resolvedAction", resolvedEvent.getAction());
            resolution.put("resolvedBy", resolvedEvent.getSourceDeviceId());
            resolution.put("resolvedAt", resolvedEvent.getTimestamp().toString());
            
            // Store resolution in a separate table or log for analytics
            log.info("Conflict resolution recorded: {}", resolution.toString());
            
        } catch (Exception e) {
            log.error("Failed to record conflict resolution", e);
        }
    }
    
    /**
     * Get current device state for user
     */
    public DeviceState getCurrentDeviceState(UUID userId) {
        return deviceStates.get(userId, DeviceState.builder()
                .state(DeviceState.State.ACTIVE)
                .build());
    }
    
    /**
     * Update device state after conflict resolution
     */
    public void updateDeviceState(UUID userId, DeviceState.State state, TimerStateChangeEvent resolvedEvent) {
        deviceStates.put(userId, DeviceState.builder()
                .state(state)
                .conflictEvent(resolvedEvent)
                .build());
    }
    
    /**
     * Clear device state when user makes choice
     */
    public void clearConflictState(UUID userId) {
        deviceStates.computeIfPresent(userId, (deviceState) -> {
            deviceState.toBuilder()
                    .state(DeviceState.State.ACTIVE)
                    .conflictEvent(null)
                    .build();
        });
    }
    
    /**
     * Generate rich push notification for conflict resolution
     */
    public RichPushNotification generateConflictNotification(UUID userId, DeviceState deviceState) {
        if (deviceState.getState() != DeviceState.State.CONFLICT_RESOLUTION_REQUIRED || 
            deviceState.getConflictEvent() == null) {
            return null;
        }
        
        TimerStateChangeEvent conflictEvent = deviceState.getConflictEvent();
        RichPushNotification notification = RichPushNotification.builder()
                .userId(userId)
                .title("Timer Conflict Detected")
                .subtitle("Multiple devices have timer conflicts")
                .body(buildConflictMessage(conflictEvent))
                .actions(List.of(
                    PushNotificationAction.builder()
                            .id("keep_current")
                            .title("Keep Current Timer")
                            .build(),
                    PushNotificationAction.builder()
                            .id("use_remote")
                            .title("Use Remote Timer")
                            .build()
                ))
                .priority(.HIGH)
                .build();
        
        return notification;
    }
    
    /**
     * Build conflict message for notification
     */
    private String buildConflictMessage(TimerStateChangeEvent conflictEvent) {
        if (conflictEvent.getPreviousState() == null || conflictEvent.getNewState() == null) {
            return "Timer state changed";
        }
        
        Integer currentRemaining = conflictEvent.getPreviousState().getRemainingSeconds();
        Integer remoteRemaining = conflictEvent.getNewState().getRemainingSeconds();
        
        return String.format("Your timer: %d:%02d\nRemote timer: %d:%02d\nWhich would you like to keep?",
                        currentRemaining / 60, currentRemaining % 60,
                        remoteRemaining / 60, remoteRemaining % 60);
    }
}