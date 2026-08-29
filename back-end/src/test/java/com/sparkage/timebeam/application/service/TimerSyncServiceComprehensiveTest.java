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

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class TimerSyncServiceComprehensiveTest {

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
    void testPushTimerState_ComprehensiveScenarios() {
        // Test 1: New user creates state
        TimerStateDto stateDto = new TimerStateDto();
        stateDto.setPhase("work");
        stateDto.setRemainingSeconds(1500); // 25 minutes
        stateDto.setIsRunning(false);
        stateDto.setWorkDuration(25);
        stateDto.setBreakDuration(5);
        stateDto.setLongBreakDuration(15);
        stateDto.setAutoStartNextSession(false);
        stateDto.setShortBreaksCompleted(0);
        stateDto.setTotalDuration(1500);
        stateDto.setLastModifiedTimestamp(Instant.now());

        assertDoesNotThrow(() -> timerSyncService.pushTimerState(userId, stateDto, deviceIdString));
        verify(timerStateRepository, times(1)).save(any(TimerState.class));

        // Test 2: Existing user updates state
        TimerState existingState = new TimerState();
        existingState.setUserId(userId);
        existingState.setPhase("work");
        existingState.setRemainingSeconds(1500);
        existingState.setRunning(false);
        existingState.setLastUpdatedAt(Instant.now().minusSeconds(10));

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));

        TimerStateDto updatedStateDto = new TimerStateDto();
        updatedStateDto.setPhase("break");
        updatedStateDto.setRemainingSeconds(300); // 5 minutes
        updatedStateDto.setIsRunning(true);
        updatedStateDto.setWorkDuration(25);
        updatedStateDto.setBreakDuration(5);
        updatedStateDto.setLongBreakDuration(15);
        updatedStateDto.setAutoStartNextSession(false);
        updatedStateDto.setShortBreaksCompleted(1);
        updatedStateDto.setTotalDuration(300);
        updatedStateDto.setLastModifiedTimestamp(Instant.now());

        assertDoesNotThrow(() -> timerSyncService.pushTimerState(userId, updatedStateDto, deviceIdString));
        verify(timerStateRepository, times(2)).save(any(TimerState.class));
    }

    @Test
    void testPushTimerState_ExistingStateUpdated() {
        // Test updating existing state
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

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));
        when(timerStateRepository.save(any(TimerState.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertDoesNotThrow(() -> timerSyncService.pushTimerState(userId, stateDto, deviceIdString));
        verify(timerStateRepository, times(1)).save(any(TimerState.class));
    }

    @Test
    void testPullTimerState_WithVariousStates() {
        // Test 1: State exists
        TimerState existingState = new TimerState();
        existingState.setUserId(userId);
        existingState.setPhase("work");
        existingState.setRemainingSeconds(1500);
        existingState.setRunning(false);
        existingState.setLastUpdatedAt(Instant.now());

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));

        Optional<TimerStateDto> result = timerSyncService.pullTimerState(userId);
        assertTrue(result.isPresent());
        assertEquals("work", result.get().getPhase());
        assertEquals(1500, result.get().getRemainingSeconds());

        // Test 2: No state exists
        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.empty());
        Optional<TimerStateDto> result2 = timerSyncService.pullTimerState(userId);
        assertFalse(result2.isPresent());
    }

    @Test
    void testClearUserState_Functionality() {
        assertDoesNotThrow(() -> timerSyncService.clearUserState(userId));
        verify(timerStateRepository, times(1)).deleteById(userId);
    }

    @Test
    void testPushTimerAction_ComprehensiveActionTypes() {
        // Test 1: START action
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

        assertDoesNotThrow(() -> timerSyncService.pushTimerAction(userId, startActionDto, deviceIdString));
        verify(timerStateRepository, times(1)).save(any(TimerState.class));

        // Test 2: PAUSE action
        TimerActionDto pauseActionDto = new TimerActionDto();
        pauseActionDto.setActionType(TimerActionType.PAUSE);
        pauseActionDto.setPhase("work");
        pauseActionDto.setRunning(false);
        pauseActionDto.setRemainingSeconds(600); // 10 minutes left
        pauseActionDto.setTimestamp(Instant.now().toEpochMilli());

        assertDoesNotThrow(() -> timerSyncService.pushTimerAction(userId, pauseActionDto, deviceIdString));
        verify(timerStateRepository, times(2)).save(any(TimerState.class));

        // Test 3: RESET action
        TimerActionDto resetActionDto = new TimerActionDto();
        resetActionDto.setActionType(TimerActionType.RESET);
        resetActionDto.setPhase("work");
        resetActionDto.setRunning(false);
        resetActionDto.setRemainingSeconds(0);
        resetActionDto.setShortBreaksCompleted(0);
        resetActionDto.setTimestamp(Instant.now().toEpochMilli());

        assertDoesNotThrow(() -> timerSyncService.pushTimerAction(userId, resetActionDto, deviceIdString));
        verify(timerStateRepository, times(3)).save(any(TimerState.class));

        // Test 4: STOP action
        TimerActionDto stopActionDto = new TimerActionDto();
        stopActionDto.setActionType(TimerActionType.STOP);
        stopActionDto.setPhase("work");
        stopActionDto.setRunning(false);
        stopActionDto.setTimestamp(Instant.now().toEpochMilli());

        assertDoesNotThrow(() -> timerSyncService.pushTimerAction(userId, stopActionDto, deviceIdString));
        verify(timerStateRepository, times(4)).save(any(TimerState.class));

        // Test 5: ADVANCE action
        TimerActionDto advanceActionDto = new TimerActionDto();
        advanceActionDto.setActionType(TimerActionType.ADVANCE);
        advanceActionDto.setPhase("break");
        advanceActionDto.setShortBreaksCompleted(1);
        advanceActionDto.setTimestamp(Instant.now().toEpochMilli());

        assertDoesNotThrow(() -> timerSyncService.pushTimerAction(userId, advanceActionDto, deviceIdString));
        verify(timerStateRepository, times(5)).save(any(TimerState.class));
    }

    @Test
    void testPushTimerAction_ActionAppliedToExistingState() {
        // Test applying action to existing state
        TimerState existingState = new TimerState();
        existingState.setUserId(userId);
        existingState.setPhase("work");
        existingState.setRemainingSeconds(1500);
        existingState.setRunning(false);
        existingState.setLastUpdatedAt(Instant.now().minusSeconds(10));

        TimerActionDto actionDto = new TimerActionDto();
        actionDto.setActionType(TimerActionType.START);
        actionDto.setPhase("work");
        actionDto.setRunning(true);
        actionDto.setTimestamp(Instant.now().toEpochMilli());

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));
        when(timerStateRepository.save(any(TimerState.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertDoesNotThrow(() -> timerSyncService.pushTimerAction(userId, actionDto, deviceIdString));
        verify(timerStateRepository, times(1)).save(any(TimerState.class));
    }

    @Test
    void testCleanupDuplicateTimerStates() {
        // Test duplicate cleanup functionality
        TimerState state1 = new TimerState();
        state1.setUserId(userId);
        state1.setLastUpdatedAt(Instant.now().minusSeconds(10));

        TimerState state2 = new TimerState();
        state2.setUserId(userId);
        state2.setLastUpdatedAt(Instant.now().minusSeconds(5)); // Most recent

        when(timerStateRepository.findAllByUserId(userId)).thenReturn(java.util.Arrays.asList(state1, state2));

        timerSyncService.cleanupDuplicateTimerStates(userId);

        verify(timerStateRepository, times(1)).delete(state1);
    }

    @Test
    void testTimerStateUpdateWithTimestamps() {
        // Test state timestamp handling
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
        stateDto.setLastModifiedTimestamp(Instant.now()); // New timestamp

        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(existingState));

        assertDoesNotThrow(() -> timerSyncService.pushTimerState(userId, stateDto, deviceIdString));

        verify(timerStateRepository, times(1)).save(any(TimerState.class));
    }
}