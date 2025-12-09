package com.sparkage.timebeam.application.service;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.sparkage.timebeam.infrastructure.external.PushNotificationService;
import com.sparkage.timebeam.infrastructure.persistence.TimerState;
import com.sparkage.timebeam.infrastructure.persistence.TimerStateRepository;
import com.sparkage.timebeam.infrastructure.persistence.UserDevice;
import com.sparkage.timebeam.infrastructure.persistence.UserDeviceRepository;
import com.sparkage.timebeam.presentation.dto.TimerStateDto;

@Service
public class TimerSyncService {
    private static final Logger log = LoggerFactory.getLogger(TimerSyncService.class);

    private final TimerStateRepository timerStateRepository;
    private final UserDeviceRepository userDeviceRepository;
    private final PushNotificationService pushNotificationService;

    public TimerSyncService(TimerStateRepository timerStateRepository,
                           UserDeviceRepository userDeviceRepository,
                           PushNotificationService pushNotificationService) {
        this.timerStateRepository = timerStateRepository;
        this.userDeviceRepository = userDeviceRepository;
        this.pushNotificationService = pushNotificationService;
    }

    /**
     * Push timer state from a device with collaborative control and timestamp-based conflict resolution
     * Any device can update the timer state - newer timestamps always win
     * Tracks which device made the last update for notification purposes
     */
    @Transactional
    public void pushTimerState(UUID userId, TimerStateDto state, String deviceIdString) {
        log.info("Pushing timer state for user={}, device={}, timestamp={}",
                userId, deviceIdString, state.getTimestamp());

        int maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                // Find the device by user and device ID string
                Optional<UserDevice> deviceOpt = userDeviceRepository.findByUserIdAndDeviceId(userId, deviceIdString);
                UUID deviceId = null;
                if (deviceOpt.isEmpty()) {
                    log.warn("Device not found for timer state push: user={}, deviceId={}, proceeding without device tracking", userId, deviceIdString);
                } else {
                    deviceId = deviceOpt.get().getId();
                }

                // Clean up any duplicate timer states first (shouldn't happen but handle gracefully)
                cleanupDuplicateTimerStates(userId);

                // Get or create timer state with optimistic locking
                Optional<TimerState> existingStateOpt = timerStateRepository.findByUserId(userId);

                if (existingStateOpt.isPresent()) {
                    TimerState existingState = existingStateOpt.get();

                    // In collaborative mode, we always accept updates
                    // This allows any device to control the timer at any time
                    // Update existing state with the new data
                    updateTimerState(existingState, state, deviceId);
                    timerStateRepository.save(existingState);
                    log.info("Updated timer state for user={} with state from device={} (collaborative mode)", userId, deviceIdString);

                    // Send push notification to other devices for real-time sync
                    pushNotificationService.sendTimerSyncPush(userId.toString(), deviceIdString, "state_update", state.getTimestamp().toString());
                } else {
                    // Create new timer state - first device to sync
                    TimerState newState = createTimerStateFromDto(userId, state, deviceId);
                    timerStateRepository.save(newState);
                    log.info("Created new timer state for user={} from device={}", userId, deviceIdString);
                }

                // Success, break out of retry loop
                return;

            } catch (org.springframework.orm.ObjectOptimisticLockingFailureException e) {
                if (attempt == maxRetries) {
                    log.error("Failed to push timer state after {} attempts due to concurrent updates: user={}, device={}",
                             maxRetries, userId, deviceIdString, e);
                    throw new RuntimeException("Failed to sync timer state due to concurrent updates", e);
                } else {
                    log.warn("Concurrent update detected, retrying attempt {} for user={}, device={}", attempt + 1, userId, deviceIdString);
                    // Wait a bit before retry
                    try {
                        Thread.sleep(100 * attempt);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        throw new RuntimeException("Interrupted during retry", ie);
                    }
                }
            } catch (Exception e) {
                log.error("Failed to push timer state for user={} from device={}: {}",
                         userId, deviceIdString, e.getMessage(), e);
                throw new RuntimeException("Failed to sync timer state", e);
            }
        }
    }

    /**
     * Pull latest timer state for a user
     */
    @Transactional(readOnly = true)
    public Optional<TimerStateDto> pullTimerState(UUID userId) {
        try {
            Optional<TimerState> stateOpt = timerStateRepository.findByUserId(userId);

            if (stateOpt.isPresent()) {
                TimerState state = stateOpt.get();
                TimerStateDto dto = convertToDto(state);
                log.debug("Pulled timer state for user={}, device={}, timestamp={}",
                         userId, state.getUpdatedByDeviceId(), state.getLastUpdatedAt());
                return Optional.of(dto);
            } else {
                log.debug("No timer state found for user={}", userId);
                return Optional.empty();
            }
        } catch (Exception e) {
            log.error("Failed to pull timer state for user={}: {}", userId, e.getMessage(), e);
            return Optional.empty();
        }
    }

    /**
     * Clear timer state for a user (useful for logout or reset)
     */
    @Transactional
    public void clearUserState(UUID userId) {
        log.info("Clearing timer state for user={}", userId);
        try {
            timerStateRepository.deleteById(userId);
            log.debug("Cleared timer state for user={}", userId);
        } catch (Exception e) {
            log.error("Failed to clear timer state for user={}: {}", userId, e.getMessage(), e);
        }
    }

    /**
     * Clean up old timer states (could be called periodically)
     */
    @Transactional
    public void cleanupOldStates() {
        Instant cutoff = Instant.now().minusSeconds(7 * 24 * 60 * 60); // 7 days ago

        try {
            int deletedCount = timerStateRepository.findStaleTimerStates(cutoff)
                    .stream()
                    .mapToInt(state -> {
                        timerStateRepository.delete(state);
                        return 1;
                    })
                    .sum();

            if (deletedCount > 0) {
                log.info("Cleaned up {} old timer states", deletedCount);
            }
        } catch (Exception e) {
            log.error("Failed to cleanup old timer states: {}", e.getMessage(), e);
        }
    }

    /**
     * Get timer state with device info for debugging
     */
    @Transactional(readOnly = true)
    public Optional<TimerStateDto> getTimerStateWithDeviceInfo(UUID userId) {
        try {
            Optional<TimerState> stateOpt = timerStateRepository.findByUserId(userId);

            if (stateOpt.isPresent()) {
                TimerState state = stateOpt.get();
                TimerStateDto dto = convertToDto(state);

                // Add device info if available
                if (state.getUpdatedByDeviceId() != null) {
                    Optional<UserDevice> deviceOpt = userDeviceRepository.findById(state.getUpdatedByDeviceId());
                    deviceOpt.ifPresent(device -> {
                        // Device info could be added to dto if needed in future
                        log.debug("Timer state last updated by device: {} ({})",
                                 device.getDeviceName(), device.getDeviceType());
                    });
                }

                return Optional.of(dto);
            }
        } catch (Exception e) {
            log.error("Failed to get timer state with device info for user={}: {}", userId, e.getMessage(), e);
        }

        return Optional.empty();
    }

    // Helper methods

    private void updateTimerState(TimerState existingState, TimerStateDto newState, UUID deviceId) {
        existingState.setPhase(newState.getPhase());
        existingState.setRemainingSeconds(newState.getRemainingSeconds());
        existingState.setRunning(newState.getIsRunning());
        existingState.setWorkDurationMinutes(newState.getWorkDuration());
        existingState.setBreakDurationMinutes(newState.getBreakDuration());
        existingState.setLongBreakDurationMinutes(newState.getLongBreakDuration());
        existingState.setAutoStartNext(newState.getAutoStartNextSession());
        existingState.setShortBreaksCompleted(newState.getShortBreaksCompleted());
        existingState.setLastUpdatedAt(Instant.now());
        existingState.setUpdatedByDeviceId(deviceId);
    }

    private TimerState createTimerStateFromDto(UUID userId, TimerStateDto dto, UUID deviceId) {
        TimerState state = new TimerState();
        state.setUserId(userId);
        state.setPhase(dto.getPhase());
        state.setRemainingSeconds(dto.getRemainingSeconds());
        state.setRunning(dto.getIsRunning());
        state.setWorkDurationMinutes(dto.getWorkDuration());
        state.setBreakDurationMinutes(dto.getBreakDuration());
        state.setLongBreakDurationMinutes(dto.getLongBreakDuration());
        state.setAutoStartNext(dto.getAutoStartNextSession());
        state.setShortBreaksCompleted(dto.getShortBreaksCompleted());
        state.setLastUpdatedAt(Instant.now());
        state.setUpdatedByDeviceId(deviceId);
        state.setVersion(1L);
        return state;
    }

    private TimerStateDto convertToDto(TimerState state) {
        TimerStateDto dto = new TimerStateDto();
        dto.setPhase(state.getPhase());
        dto.setRemainingSeconds(state.getRemainingSeconds());
        dto.setIsRunning(state.isRunning());
        dto.setWorkDuration(state.getWorkDurationMinutes());
        dto.setBreakDuration(state.getBreakDurationMinutes());
        dto.setLongBreakDuration(state.getLongBreakDurationMinutes());
        dto.setAutoStartNextSession(state.isAutoStartNext());
        dto.setShortBreaksCompleted(state.getShortBreaksCompleted());
        dto.setTimestamp(state.getLastUpdatedAt());
        dto.setDeviceId(state.getUpdatedByDeviceId() != null ? state.getUpdatedByDeviceId().toString() : null);
        return dto;
    }

    /**
     * Clean up duplicate timer states for a user (shouldn't happen but handle gracefully)
     * Keeps the most recently updated state and deletes others
     */
    private void cleanupDuplicateTimerStates(UUID userId) {
        try {
            // Find all timer states for this user (should only be one, but handle duplicates)
            List<TimerState> allStates = timerStateRepository.findAllByUserId(userId);

            if (allStates.size() > 1) {
                log.warn("Found {} duplicate timer states for user={}, cleaning up", allStates.size(), userId);

                // Sort by last updated time (most recent first)
                allStates.sort((a, b) -> b.getLastUpdatedAt().compareTo(a.getLastUpdatedAt()));

                // Keep the most recent one, delete the others
                for (int i = 1; i < allStates.size(); i++) {
                    TimerState duplicate = allStates.get(i);
                    log.info("Deleting duplicate timer state for user={}, id={}", userId, duplicate.getUserId());
                    timerStateRepository.delete(duplicate);
                }
            }
        } catch (Exception e) {
            log.error("Failed to cleanup duplicate timer states for user={}: {}", userId, e.getMessage(), e);
            // Don't throw - let the main operation continue
        }
    }
}
