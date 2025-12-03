package com.sparkage.timebeam.application.service;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    public TimerSyncService(TimerStateRepository timerStateRepository,
                           UserDeviceRepository userDeviceRepository) {
        this.timerStateRepository = timerStateRepository;
        this.userDeviceRepository = userDeviceRepository;
    }

    /**
     * Push timer state from a device with conflict resolution
     * Uses optimistic locking for concurrent updates
     */
    @Transactional
    public void pushTimerState(UUID userId, TimerStateDto state, UUID deviceId) {
        log.info("Pushing timer state for user={}, device={}, timestamp={}",
                userId, deviceId, state.getTimestamp());

        try {
            // Get or create timer state with pessimistic locking for safety
            Optional<TimerState> existingStateOpt = timerStateRepository.findByUserIdWithLock(userId);

            if (existingStateOpt.isPresent()) {
                TimerState existingState = existingStateOpt.get();

                // Check if the new state is actually newer
                if (state.getTimestamp().isAfter(existingState.getLastUpdatedAt())) {
                    // Update existing state
                    updateTimerState(existingState, state, deviceId);
                    timerStateRepository.save(existingState);
                    log.info("Updated timer state for user={} with newer state from device={}", userId, deviceId);
                } else {
                    log.debug("Ignoring older timer state for user={} from device={}", userId, deviceId);
                }
            } else {
                // Create new timer state
                TimerState newState = createTimerStateFromDto(userId, state, deviceId);
                timerStateRepository.save(newState);
                log.info("Created new timer state for user={} from device={}", userId, deviceId);
            }

        } catch (Exception e) {
            log.error("Failed to push timer state for user={} from device={}: {}",
                     userId, deviceId, e.getMessage(), e);
            throw new RuntimeException("Failed to sync timer state", e);
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
}
