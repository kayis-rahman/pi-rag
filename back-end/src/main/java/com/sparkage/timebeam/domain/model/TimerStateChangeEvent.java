package com.sparkage.timebeam.application.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.sparkage.timebeam.domain.model.TimerState;
import com.sparkage.timebeam.infrastructure.persistence.TimerStateRepository;
import com.sparkage.timebeam.application.dto.DeviceHeartbeatDto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Smart timer event service for event-driven multi-device synchronization
 * Sends events only when timer state changes (start/pause/reset), not every second
 */
@Service
public class SmartTimerEventService {
    private static final Logger log = LoggerFactory.getLogger(SmartTimerEventService.class);
    
    private final TimerStateRepository timerStateRepository;
    private final DeviceHeartbeatService deviceHeartbeatService;
    
    public SmartTimerEventService(TimerStateRepository timerStateRepository,
                                DeviceHeartbeatService deviceHeartbeatService) {
        this.timerStateRepository = timerStateRepository;
        this.deviceHeartbeatService = deviceHeartbeatService;
    }
    
    /**
     * Handle timer event and broadcast to all active devices
     * Only broadcasts IMPORTANT state changes, not tick-by-tick updates
     */
    @Transactional
    public void handleTimerEvent(UUID userId, String deviceId, TimerState newState, TimerState previousState) {
        log.info("Handling timer event: action={}, userId={}, sourceDevice={}", 
            newState.getPhase(), userId, deviceId);
        
        // Save the new timer state
        timerStateRepository.save(newState);
        
        // Broadcast to all active devices (excluding source)
        List<String> activeDevices = deviceHeartbeatService.getActiveDevices(userId)
            .stream()
            .filter(activeDeviceId -> !activeDeviceId.equals(deviceId))
            .toList();
        
        broadcastToActiveDevices(userId, createStateChangeEvent(userId, deviceId, newState, previousState), activeDevices);
        
        // Send APNs to inactive devices
        sendPushNotificationsToInactiveDevices(userId, createStateChangeEvent(userId, deviceId, newState, previousState));
    }
    
    /**
     * Create timer state change event
     */
    private TimerStateChangeEvent createStateChangeEvent(UUID userId, String sourceDeviceId, 
                                                         TimerState newState, TimerState previousState) {
        return TimerStateChangeEvent.builder()
            .userId(userId)
            .sourceDeviceId(sourceDeviceId)
            .previousState(mapTimerState(previousState))
            .newState(mapTimerState(newState))
            .phase(getPhaseChange(previousState, newState))
            .action(determineAction(previousState, newState))
            .timestamp(Instant.now())
            .build();
    }
    
    /**
     * Broadcast state change event to active devices
     */
    private void broadcastToActiveDevices(UUID userId, TimerStateChangeEvent event, List<String> activeDevices) {
        // Broadcast via WebSocket for macOS, SSE for iOS
        // This would be implemented in Phase 2
        log.debug("Broadcasting state change to {} active devices", activeDevices.size());
    }
    
    /**
     * Send rich push notifications to inactive devices
     */
    private void sendPushNotificationsToInactiveDevices(UUID userId, TimerStateChangeEvent event) {
        List<String> inactiveDevices = deviceHeartbeatService.getInactiveDevices(userId);
        
        for (String device : inactiveDevices) {
            sendConflictResolutionNotification(userId, device, event);
        }
    }
    
    /**
     * Send conflict resolution push notification
     */
    private void sendConflictResolutionNotification(UUID userId, String deviceId, TimerStateChangeEvent event) {
        // This would integrate with enhanced APNs service
        log.info("Sending conflict notification to inactive device: {}", deviceId);
        // TODO: Implement when APNs service is enhanced
    }
    
    /**
     * Determine what action occurred
     */
    private String determineAction(TimerState previousState, TimerState newState) {
        if (previousState == null) {
            return newState.getPhase().equals("WORK") ? "START" : "RESET";
        }
        
        if (!previousState.isRunning() && newState.isRunning()) {
            return "START";
        }
        
        if (previousState.isRunning() && !newState.isRunning()) {
            return "PAUSE";
        }
        
        if (!previousState.isRunning() && newState.isRunning()) {
            return "RESUME";
        }
        
        return newState.getPhase().equals(previousState.getPhase()) ? "UPDATE" : "PHASE_CHANGE";
    }
    
    /**
     * Get phase change if any
     */
    private String getPhaseChange(TimerState previousState, TimerState newState) {
        return previousState.getPhase().equals(newState.getPhase()) ? "NONE" : newState.getPhase();
    }
    
    /**
     * Map TimerState to DTO for events
     */
    private TimerStateDto mapTimerState(TimerState state) {
        return TimerStateDto.builder()
            .phase(state.getPhase())
            .remainingSeconds(state.getRemainingSeconds())
            .isRunning(state.isRunning())
            .workDuration(state.getWorkDuration())
            .breakDuration(state.getBreakDuration())
            .longBreakDuration(state.getLongBreakDuration())
            .autoStartNextSession(state.isAutoStartNextSession())
            .shortBreaksCompleted(state.getShortBreaksCompleted())
            .lastModifiedTimestamp(state.getLastModifiedTimestamp())
            .deviceId(state.getLastUpdatedByDevice())
            .build();
    }
}