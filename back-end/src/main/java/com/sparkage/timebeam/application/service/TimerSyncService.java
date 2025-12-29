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
import com.sparkage.timebeam.presentation.dto.TimerStateDto;
import com.sparkage.timebeam.presentation.dto.TimerActionDto;
import com.sparkage.timebeam.domain.model.TimerActionType;

import static com.sparkage.timebeam.presentation.dto.TimerStateDto.convertToDto;

@Service
public class TimerSyncService {
    private static final Logger log = LoggerFactory.getLogger(TimerSyncService.class);

    private final TimerStateRepository timerStateRepository;
    private final PushNotificationService pushNotificationService;

    public TimerSyncService(TimerStateRepository timerStateRepository,
                            PushNotificationService pushNotificationService) {
        this.timerStateRepository = timerStateRepository;
        this.pushNotificationService = pushNotificationService;
    }

    /**
     * Push timer state from a device with collaborative control
     * Any device can update timer state - newer timestamps always win
     * Tracks which device made the last update for notification purposes
     */
    @Transactional
    public void pushTimerState(UUID userId, TimerStateDto stateDto, String deviceIdString) {
        log.info("Pushing timer state for user={}, device={}, phase={}, running={}, remaining={}",
                userId, deviceIdString, stateDto.getPhase(), stateDto.getIsRunning(), stateDto.getRemainingSeconds());

        int maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                // Clean up any duplicate timer states first
                cleanupDuplicateTimerStates(userId);

                // Get or create timer state with optimistic locking
                Optional<TimerState> existingStateOpt = timerStateRepository.findByUserId(userId);

                if (existingStateOpt.isPresent()) {
                    TimerState existingState = existingStateOpt.get();

                    // Update existing state with new state data
                    updateTimerState(existingState, stateDto);
                    existingState.setUpdatedByDeviceId(UUID.fromString(deviceIdString));
                    timerStateRepository.save(existingState);
                    log.info("Updated timer state for user={} from device={} (collaborative mode)", userId, deviceIdString);

                    // Send push notification to other devices for real-time sync
                    pushNotificationService.sendTimerSyncPush(
                        userId.toString(),
                        deviceIdString,
                        "state_update",
                        stateDto.getLastModifiedTimestamp() != null ? stateDto.getLastModifiedTimestamp().toString() : Instant.now().toString()
                    );
                } else {
                    // Create new timer state - first device to sync
                    TimerState newState = new TimerState();
                    newState.setUserId(userId);
                    newState.setPhase(stateDto.getPhase());
                    newState.setRemainingSeconds(stateDto.getRemainingSeconds());
                    newState.setRunning(stateDto.getIsRunning());
                    newState.setWorkDurationMinutes(stateDto.getWorkDuration());
                    newState.setBreakDurationMinutes(stateDto.getBreakDuration());
                    newState.setLongBreakDurationMinutes(stateDto.getLongBreakDuration());
                    newState.setAutoStartNext(stateDto.getAutoStartNextSession());
                    newState.setShortBreaksCompleted(stateDto.getShortBreaksCompleted());
                    newState.setTotalDuration(stateDto.getTotalDuration());
                    newState.setStartTimestamp(stateDto.getStartTimestamp());
                    newState.setPauseTimestamp(stateDto.getPauseTimestamp());
                    newState.setLastUpdatedAt(Instant.now());
                    newState.setUpdatedByDeviceId(UUID.fromString(deviceIdString));
                    newState.setVersion(1L);
                    timerStateRepository.save(newState);
                    log.info("Created new timer state for user={} from device={}", userId, deviceIdString);
                }
                return;
            } catch (org.springframework.orm.ObjectOptimisticLockingFailureException e) {
                if (attempt == maxRetries) {
                    log.error("Failed to push timer state after {} attempts due to concurrent updates: user={}, device={}",
                            maxRetries, userId, deviceIdString, e);
                    throw new RuntimeException("Failed to sync timer state due to concurrent updates", e);
                }
                log.warn("Concurrent update detected, retrying attempt {} for user={}, device={}", attempt + 1, userId, deviceIdString);
                try {
                    Thread.sleep(100 * attempt);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw new RuntimeException("Interrupted during retry", ie);
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
     * Returns Optional empty if no state exists
     */
    @Transactional(readOnly = true)
    public Optional<TimerStateDto> pullTimerState(UUID userId) {
        try {
            Optional<TimerState> stateOpt = timerStateRepository.findByUserId(userId);
            if (stateOpt.isPresent()) {
                TimerState state = stateOpt.get();
                TimerStateDto dto = convertToDto(state);
                double unixTimestamp = Math.round(((double) state.getLastUpdatedAt().toEpochMilli() / 1000.0) * 100.0) / 100.0;
                log.info("TIMER_SYNC_DEBUG: Pulling timer state - Unix timestamp: {} (as string: {})", unixTimestamp, String.format("%.2f", unixTimestamp));
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
        Instant cutoff = Instant.now().minusSeconds(7 * 24 * 60); // 7 days ago
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
                return Optional.of(dto);
            }
        } catch (Exception e) {
            log.error("Failed to get timer state with device info for user={}: {}", userId, e.getMessage(), e);
        }
        return Optional.empty();
    }

    /**
     * Helper method to update timer state from full state DTO
     */
    private void updateTimerState(TimerState existingState, TimerStateDto newState) {
        existingState.setPhase(newState.getPhase());
        existingState.setRemainingSeconds(newState.getRemainingSeconds());
        existingState.setRunning(newState.getIsRunning());
        existingState.setWorkDurationMinutes(newState.getWorkDuration());
        existingState.setBreakDurationMinutes(newState.getBreakDuration());
        existingState.setLongBreakDurationMinutes(newState.getLongBreakDuration());
        existingState.setAutoStartNext(newState.getAutoStartNextSession());
        existingState.setShortBreaksCompleted(newState.getShortBreaksCompleted());
        existingState.setTotalDuration(newState.getTotalDuration());
        existingState.setStartTimestamp(newState.getStartTimestamp());
        existingState.setPauseTimestamp(newState.getPauseTimestamp());
        existingState.setLastUpdatedAt(Instant.now());
    }

    /**
     * Apply timer action to state for event-based synchronization
     * Handles different action types (START, PAUSE, RESET, STOP, ADVANCE)
     */
    private void applyActionToTimerState(TimerState existingState, TimerActionDto actionDto) {
        TimerActionType actionType = actionDto.getActionType();

        switch (actionType) {
            case START:
                existingState.setPhase(actionDto.getPhase());
                existingState.setRunning(true);
                if (actionDto.getWorkDuration() > 0) {
                    existingState.setWorkDurationMinutes(actionDto.getWorkDuration());
                    existingState.setBreakDurationMinutes(actionDto.getBreakDuration());
                    existingState.setLongBreakDurationMinutes(actionDto.getLongBreakDuration());
                }
                break;

            case PAUSE:
                existingState.setRunning(false);
                if (actionDto.getRemainingSeconds() >= 0) {
                    existingState.setRemainingSeconds(actionDto.getRemainingSeconds());
                }
                break;

            case RESET:
                existingState.setPhase("work");
                existingState.setRunning(false);
                existingState.setRemainingSeconds(0);
                existingState.setShortBreaksCompleted(0);
                break;

            case STOP:
                existingState.setRunning(false);
                break;

            case ADVANCE:
                if (actionDto.getPhase() != null) {
                    existingState.setPhase(actionDto.getPhase());
                }
                if (actionDto.getShortBreaksCompleted() >= 0) {
                    existingState.setShortBreaksCompleted(actionDto.getShortBreaksCompleted());
                }
                break;
        }

        existingState.setLastUpdatedAt(Instant.now());
    }

    /**
     * Create new timer state from action DTO
     */
    private TimerState createTimerStateFromActionDto(UUID userId, TimerActionDto actionDto) {
        TimerState state = new TimerState();
        state.setUserId(userId);

        // Set timer state fields from action dto if available
        if (actionDto.getPhase() != null) {
            state.setPhase(actionDto.getPhase());
        }
        state.setRemainingSeconds(actionDto.getRemainingSeconds());
        state.setRunning(actionDto.isRunning());
        if (actionDto.getWorkDuration() > 0) {
            state.setWorkDurationMinutes(actionDto.getWorkDuration());
            state.setBreakDurationMinutes(actionDto.getBreakDuration());
            state.setLongBreakDurationMinutes(actionDto.getLongBreakDuration());
            state.setAutoStartNext(actionDto.isAutoStartNextSession());
            state.setShortBreaksCompleted(actionDto.getShortBreaksCompleted());
            // Set total duration based on phase
            int totalDuration = switch (state.getPhase()) {
                case "work" -> actionDto.getWorkDuration() * 60;
                case "break" -> actionDto.getBreakDuration() * 60;
                case "longBreak" -> actionDto.getLongBreakDuration() * 60;
                default -> actionDto.getWorkDuration() * 60;
            };
            state.setTotalDuration(totalDuration);
        } else {
            // Default values if actionDto is not provided
            state.setPhase("work");
            state.setRemainingSeconds(0);
            state.setRunning(false);
            state.setWorkDurationMinutes(25);
            state.setBreakDurationMinutes(5);
            state.setLongBreakDurationMinutes(15);
            state.setAutoStartNext(false);
            state.setShortBreaksCompleted(0);
            state.setTotalDuration(25 * 60); // 25 minutes in seconds
        }

        // Initialize timestamps to null (not set until started)
        state.setStartTimestamp(null);
        state.setPauseTimestamp(null);
        state.setLastUpdatedAt(Instant.now());
        state.setVersion(1L);
        return state;
    }

    /**
     * Push timer action from a device with collaborative control and timestamp-based conflict resolution
     * Any device can trigger timer actions - newer timestamps always win
     * Tracks which device made the last action for notification purposes
     */
    @Transactional
    public void pushTimerAction(UUID userId, TimerActionDto actionDto, String deviceIdString) {
        log.info("Pushing timer action for user={}, device={}, action={}, timestamp={}",
                userId, deviceIdString, actionDto.getActionType(), actionDto.getTimestamp());

        int maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                // Clean up any duplicate timer states first (shouldn't happen but handle gracefully)
                cleanupDuplicateTimerStates(userId);

                // Get or create timer state with optimistic locking
                Optional<TimerState> existingStateOpt = timerStateRepository.findByUserId(userId);

                if (existingStateOpt.isPresent()) {
                    TimerState existingState = existingStateOpt.get();

                    // In collaborative mode, we always accept updates
                    // This allows any device to control the timer at any time
                    // Update existing state with action data
                    applyActionToTimerState(existingState, actionDto);
                    timerStateRepository.save(existingState);
                    log.info("Updated timer state for user={} with action from device={} (collaborative mode)", userId, deviceIdString);

                    // Send push notification to other devices for real-time sync
                    pushNotificationService.sendTimerSyncPush(userId.toString(), deviceIdString, "action_" + actionDto.getActionType().toString().toLowerCase(), actionDto.getTimestamp().toString());
                } else {
                    // Create new timer state - first device to sync
                    TimerState newState = createTimerStateFromActionDto(userId, actionDto);
                    timerStateRepository.save(newState);
                    log.info("Created new timer state for user={} from device={}", userId, deviceIdString);
                }
                return;
            } catch (org.springframework.orm.ObjectOptimisticLockingFailureException e) {
                if (attempt == maxRetries) {
                    log.error("Failed to push timer action after {} attempts due to concurrent updates: user={}, device={}",
                            maxRetries, userId, deviceIdString, e);
                    throw new RuntimeException("Failed to sync timer action due to concurrent updates", e);
                }
                log.warn("Concurrent update detected, retrying attempt {} for user={}, device={}", attempt + 1, userId, deviceIdString);
                try {
                    Thread.sleep(100 * attempt);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw new RuntimeException("Interrupted during retry", ie);
                }
            } catch (Exception e) {
                log.error("Failed to push timer action for user={} from device={}: {}",
                        userId, deviceIdString, e.getMessage(), e);
                throw new RuntimeException("Failed to sync timer action", e);
            }
        }
    }

    /**
     * Clean up duplicate timer states for a user
     * Keeps most recently updated state and deletes others
     */
    private void cleanupDuplicateTimerStates(UUID userId) {
        try {
            // Find all timer states for this user (should only be one, but handle duplicates)
            List<TimerState> allStates = timerStateRepository.findAllByUserId(userId);

            if (allStates.size() > 1) {
                log.warn("Found {} duplicate timer states for user={}, cleaning up", allStates.size(), userId);

                // Sort by last updated time (most recent first)
                allStates.sort((a, b) -> b.getLastUpdatedAt().compareTo(a.getLastUpdatedAt()));

                // Keep the most recent one, delete the rest
                TimerState mostRecentState = allStates.get(0);

                for (int i = 1; i < allStates.size(); i++) {
                    TimerState duplicate = allStates.get(i);
                    log.info("Deleting duplicate timer state for user={}, id={}", userId, duplicate.getUserId());
                    timerStateRepository.delete(duplicate);
                }
            }

            log.info("Cleaned up {} duplicate timer states for user={}", allStates.size() - 1, userId);
        } catch (
                Exception e) {
            log.error("Failed to cleanup duplicate timer states for user={}: {}", userId, e.getMessage(), e);
        }
    }
}

