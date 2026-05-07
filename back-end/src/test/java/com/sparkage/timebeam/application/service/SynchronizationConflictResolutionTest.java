package com.sparkage.timebeam.application.service;

import com.sparkage.timebeam.infrastructure.external.PushNotificationService;
import com.sparkage.timebeam.infrastructure.persistence.TimerState;
import com.sparkage.timebeam.infrastructure.persistence.TimerStateRepository;
import com.sparkage.timebeam.presentation.dto.TimerStateDto;
import com.sparkage.timebeam.presentation.dto.TimerActionDto;
import com.sparkage.timebeam.domain.model.TimerActionType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.orm.ObjectOptimisticLockingFailureException;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SynchronizationConflictResolutionTest {

    @Mock
    private TimerStateRepository timerStateRepository;

    @Mock
    private PushNotificationService pushNotificationService;

    private TimerSyncService timerSyncService;

    private UUID userId;
    private String deviceIdString;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        deviceIdString = UUID.randomUUID().toString();
        timerSyncService = new TimerSyncService(timerStateRepository, pushNotificationService);
    }

    @Test
    void testTimestampBasedConflictResolution_StateUpdates() {
        // Test that newer timestamps win in conflict resolution
        TimerState existingState = new TimerState();
        existingState.setUserId(userId);
        existingState.setPhase("work");
        existingState.setRemainingSeconds(1500);
        existingState.setRunning(false);
        existingState.setLastUpdatedAt(Instant.now().minusSeconds(60)); // Older timestamp

        TimerStateDto newerStateDto = new TimerStateDto();
        newerStateDto.setPhase("break");
        newerStateDto.setRemainingSeconds(300);
        newerStateDto.setIsRunning(true);
        newerStateDto.setWorkDuration(25);
        newerStateDto.setBreakDuration(5);
        newerStateDto.setLongBreakDuration(15);
        newerStateDto.setAutoStartNextSession(false);
        newerStateDto.setShortBreaksCompleted(1);
        newerStateDto.setTotalDuration(300);
        newerStateDto.setLastModifiedTimestamp(Instant.now()); // Newer timestamp

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));

        // When
        timerSyncService.pushTimerState(userId, newerStateDto, deviceIdString);

        // Then - Should update the state with newer data
        verify(timerStateRepository, times(1)).save(any(TimerState.class));
    }

    @Test
    void testCollaborativeControl_AllowsAnyDeviceToUpdate() {
        // Test collaborative control - any device can update timer state
        TimerState existingState = new TimerState();
        existingState.setUserId(userId);
        existingState.setPhase("work");
        existingState.setRemainingSeconds(1500);
        existingState.setRunning(false);
        existingState.setLastUpdatedAt(Instant.now().minusSeconds(10));

        TimerStateDto stateDto = new TimerStateDto();
        stateDto.setPhase("break");
        stateDto.setRemainingSeconds(300);
        stateDto.setIsRunning(true);
        stateDto.setWorkDuration(25);
        stateDto.setBreakDuration(5);
        stateDto.setLongBreakDuration(15);
        stateDto.setAutoStartNextSession(false);
        stateDto.setShortBreaksCompleted(1);
        stateDto.setTotalDuration(300);
        stateDto.setLastModifiedTimestamp(Instant.now());

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));

        // When - Any device can update the timer state (collaborative mode)
        timerSyncService.pushTimerState(userId, stateDto, deviceIdString);

        // Then - Should allow update regardless of device (collaborative mode)
        verify(timerStateRepository, times(1)).save(any(TimerState.class));
    }

    @Test
    void testActionBasedSynchronization_UpdatesWithDifferentActions() {
        // Test that different actions update the state appropriately
        TimerState existingState = new TimerState();
        existingState.setUserId(userId);
        existingState.setPhase("work");
        existingState.setRemainingSeconds(1500);
        existingState.setRunning(false);
        existingState.setLastUpdatedAt(Instant.now().minusSeconds(10));

        // Test START action
        TimerActionDto startActionDto = new TimerActionDto();
        startActionDto.setActionType(TimerActionType.START);
        startActionDto.setPhase("work");
        startActionDto.setRunning(true);
        startActionDto.setWorkDuration(25);
        startActionDto.setBreakDuration(5);
        startActionDto.setLongBreakDuration(15);
        startActionDto.setAutoStartNextSession(false);
        startActionDto.setShortBreaksCompleted(0);
        startActionDto.setTimestamp(Instant.now().toEpochMilli());

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));

        // When
        timerSyncService.pushTimerAction(userId, startActionDto, deviceIdString);

        // Then
        verify(timerStateRepository, times(1)).save(any(TimerState.class));
        // Verify that state was updated properly for START action
        verify(timerStateRepository).save(argThat(state -> state.isRunning() == true));
    }

    @Test
    void testTimestampBasedConflictResolution_ExistingStateUpdated() {
        // Test that state updates work when existing state exists
        TimerState existingState = new TimerState();
        existingState.setUserId(userId);
        existingState.setPhase("work");
        existingState.setRemainingSeconds(1500);
        existingState.setRunning(false);
        existingState.setLastUpdatedAt(Instant.now().minusSeconds(60)); // Older timestamp

        TimerStateDto newerStateDto = new TimerStateDto();
        newerStateDto.setPhase("break");
        newerStateDto.setRemainingSeconds(300);
        newerStateDto.setIsRunning(true);
        newerStateDto.setWorkDuration(25);
        newerStateDto.setBreakDuration(5);
        newerStateDto.setLongBreakDuration(15);
        newerStateDto.setAutoStartNextSession(false);
        newerStateDto.setShortBreaksCompleted(1);
        newerStateDto.setTotalDuration(300);
        newerStateDto.setLastModifiedTimestamp(Instant.now()); // Newer timestamp

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));
        when(timerStateRepository.save(any(TimerState.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // When
        timerSyncService.pushTimerState(userId, newerStateDto, deviceIdString);

        // Then - Should update the state with newer data
        verify(timerStateRepository, times(1)).save(any(TimerState.class));
    }
}