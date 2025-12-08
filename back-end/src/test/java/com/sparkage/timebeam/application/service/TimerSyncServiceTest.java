package com.sparkage.timebeam.application.service;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.sparkage.timebeam.infrastructure.persistence.TimerState;
import com.sparkage.timebeam.infrastructure.persistence.TimerStateRepository;
import com.sparkage.timebeam.infrastructure.persistence.UserDevice;
import com.sparkage.timebeam.infrastructure.persistence.UserDeviceRepository;
import com.sparkage.timebeam.presentation.dto.TimerStateDto;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TimerSyncServiceTest {

    @Mock
    private TimerStateRepository timerStateRepository;

    @Mock
    private UserDeviceRepository userDeviceRepository;

    @InjectMocks
    private TimerSyncService timerSyncService;

    private UUID userId;
    private UUID deviceId;
    private TimerStateDto timerStateDto;
    private TimerState timerState;
    private UserDevice userDevice;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        deviceId = UUID.randomUUID();

        // Setup TimerStateDto
        timerStateDto = new TimerStateDto();
        timerStateDto.setPhase("work");
        timerStateDto.setRemainingSeconds(1500);
        timerStateDto.setIsRunning(true);
        timerStateDto.setWorkDuration(25);
        timerStateDto.setBreakDuration(5);
        timerStateDto.setLongBreakDuration(15);
        timerStateDto.setAutoStartNextSession(false);
        timerStateDto.setShortBreaksCompleted(0);
        timerStateDto.setTimestamp(Instant.now());
        timerStateDto.setDeviceId(deviceId.toString());

        // Setup TimerState entity
        timerState = new TimerState();
        timerState.setUserId(userId);
        timerState.setPhase("work");
        timerState.setRemainingSeconds(1500);
        timerState.setRunning(true);
        timerState.setWorkDurationMinutes(25);
        timerState.setBreakDurationMinutes(5);
        timerState.setLongBreakDurationMinutes(15);
        timerState.setAutoStartNext(false);
        timerState.setShortBreaksCompleted(0);
        timerState.setLastUpdatedAt(Instant.now());
        timerState.setUpdatedByDeviceId(deviceId);
        timerState.setVersion(1L);

        // Setup UserDevice
        userDevice = new UserDevice();
        userDevice.setId(deviceId);
        userDevice.setUserId(userId);
        userDevice.setDeviceId("test-device");
        userDevice.setDeviceName("Test Device");
        userDevice.setDeviceType("ios");
    }

    @Test
    void pushTimerState_ShouldCreateNewTimerState_WhenNoneExists() {
        // Given
        when(timerStateRepository.findByUserIdWithLock(userId)).thenReturn(Optional.empty());
        when(timerStateRepository.save(any(TimerState.class))).thenReturn(timerState);

        // When
        timerSyncService.pushTimerState(userId, timerStateDto, deviceId.toString());

        // Then
        verify(timerStateRepository).findByUserIdWithLock(userId);
        verify(timerStateRepository).save(any(TimerState.class));
    }

    @Test
    void pushTimerState_ShouldUpdateExistingTimerState_WhenNewerTimestamp() {
        // Given
        TimerState existingState = createTimerStateWithTimestamp(Instant.now().minusSeconds(60));
        when(timerStateRepository.findByUserIdWithLock(userId)).thenReturn(Optional.of(existingState));
        when(timerStateRepository.save(existingState)).thenReturn(existingState);

        // When
        timerSyncService.pushTimerState(userId, timerStateDto, deviceId.toString());

        // Then
        verify(timerStateRepository).findByUserIdWithLock(userId);
        verify(timerStateRepository).save(existingState);
        assertThat(existingState.getPhase()).isEqualTo("work");
        assertThat(existingState.getRemainingSeconds()).isEqualTo(1500);
    }

    @Test
    void pushTimerState_ShouldIgnoreOlderState() {
        // Given
        TimerState existingState = createTimerStateWithTimestamp(Instant.now().plusSeconds(60));
        when(timerStateRepository.findByUserIdWithLock(userId)).thenReturn(Optional.of(existingState));

        // When
        timerSyncService.pushTimerState(userId, timerStateDto, deviceId.toString());

        // Then
        verify(timerStateRepository).findByUserIdWithLock(userId);
        verify(timerStateRepository, never()).save(any(TimerState.class));
    }

    @Test
    void pullTimerState_ShouldReturnTimerStateDto_WhenExists() {
        // Given
        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(timerState));

        // When
        Optional<TimerStateDto> result = timerSyncService.pullTimerState(userId);

        // Then
        assertThat(result).isPresent();
        TimerStateDto dto = result.get();
        assertThat(dto.getPhase()).isEqualTo("work");
        assertThat(dto.getRemainingSeconds()).isEqualTo(1500);
        assertThat(dto.getIsRunning()).isTrue();
    }

    @Test
    void pullTimerState_ShouldReturnEmpty_WhenNoneExists() {
        // Given
        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.empty());

        // When
        Optional<TimerStateDto> result = timerSyncService.pullTimerState(userId);

        // Then
        assertThat(result).isEmpty();
    }

    @Test
    void clearUserState_ShouldDeleteTimerState() {
        // Given
        doNothing().when(timerStateRepository).deleteById(userId);

        // When
        timerSyncService.clearUserState(userId);

        // Then
        verify(timerStateRepository).deleteById(userId);
    }

    @Test
    void cleanupOldStates_ShouldDeleteOldStates() {
        // Given
        Instant cutoff = Instant.now().minusSeconds(7 * 24 * 60 * 60); // 7 days ago
        when(timerStateRepository.findStaleTimerStates(cutoff)).thenReturn(java.util.List.of(timerState));
        doNothing().when(timerStateRepository).delete(timerState);

        // When
        timerSyncService.cleanupOldStates();

        // Then
        verify(timerStateRepository).findStaleTimerStates(cutoff);
        verify(timerStateRepository).delete(timerState);
    }

    @Test
    void pushTimerState_ShouldThrowException_OnDatabaseError() {
        // Given
        when(timerStateRepository.findByUserIdWithLock(userId))
            .thenThrow(new RuntimeException("Database error"));

        // When & Then
        assertThatThrownBy(() -> timerSyncService.pushTimerState(userId, timerStateDto, deviceId.toString()))
            .isInstanceOf(RuntimeException.class)
            .hasMessage("Failed to sync timer state");
    }

    @Test
    void getTimerStateWithDeviceInfo_ShouldIncludeDeviceInfo() {
        // Given
        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.of(timerState));
        when(userDeviceRepository.findById(deviceId)).thenReturn(Optional.of(userDevice));

        // When
        Optional<TimerStateDto> result = timerSyncService.getTimerStateWithDeviceInfo(userId);

        // Then
        assertThat(result).isPresent();
        verify(userDeviceRepository).findById(deviceId);
    }

    private TimerState createTimerStateWithTimestamp(Instant timestamp) {
        TimerState state = new TimerState();
        state.setUserId(userId);
        state.setPhase("break");
        state.setRemainingSeconds(300);
        state.setRunning(false);
        state.setWorkDurationMinutes(25);
        state.setBreakDurationMinutes(5);
        state.setLongBreakDurationMinutes(15);
        state.setAutoStartNext(false);
        state.setShortBreaksCompleted(1);
        state.setLastUpdatedAt(timestamp);
        state.setUpdatedByDeviceId(deviceId);
        state.setVersion(1L);
        return state;
    }
}
