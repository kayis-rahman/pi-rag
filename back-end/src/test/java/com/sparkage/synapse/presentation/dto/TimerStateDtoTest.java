package com.sparkage.synapse.presentation.dto;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.time.Instant;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.sparkage.synapse.infrastructure.persistence.TimerState;

/**
 * Unit tests for TimerStateDto conversion
 */
@DisplayName("TimerStateDto Tests")
class TimerStateDtoTest {

    private TimerState entity;
    private UUID userId;
    private UUID deviceId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        deviceId = UUID.randomUUID();
    }

    @Test
    @DisplayName("Should convert TimerState entity to DTO with all fields populated")
    void shouldConvertEntityToDto_WhenAllFieldsPopulated() {
        // Arrange
        Instant now = Instant.now();
        entity = new TimerState(
            userId,
            "work",
            1500, // remainingSeconds
            true, // running
            25, // workDurationMinutes
            5, // breakDurationMinutes
            15, // longBreakDurationMinutes
            true, // autoStartNext
            3, // shortBreaksCompleted
            1500, // totalDuration
            1735489200.123, // startTimestamp
            1735489300.456, // pauseTimestamp
            now, // lastUpdatedAt
            deviceId, // updatedByDeviceId
            5L // version
        );

        // Act
        TimerStateDto dto = TimerStateDto.convertToDto(entity);

        // Assert
        assertNotNull(dto);
        assertEquals("work", dto.getPhase());
        assertEquals(1500, dto.getRemainingSeconds());
        assertEquals(true, dto.getIsRunning());
        assertEquals(25, dto.getWorkDuration());
        assertEquals(5, dto.getBreakDuration());
        assertEquals(15, dto.getLongBreakDuration());
        assertEquals(true, dto.getAutoStartNextSession());
        assertEquals(3, dto.getShortBreaksCompleted());
        assertEquals(1500, dto.getTotalDuration());
        assertEquals(1735489200.123, dto.getStartTimestamp());
        assertEquals(1735489300.456, dto.getPauseTimestamp());
        assertEquals(now, dto.getLastModifiedTimestamp());
        assertEquals(deviceId.toString(), dto.getDeviceId());
    }

    @Test
    @DisplayName("Should convert TimerState entity to DTO with null timestamps")
    void shouldConvertEntityToDto_WhenTimestampsAreNull() {
        // Arrange
        Instant now = Instant.now();
        entity = new TimerState(
            userId,
            "break",
            300, // remainingSeconds
            false, // running
            25, // workDurationMinutes
            5, // breakDurationMinutes
            15, // longBreakDurationMinutes
            false, // autoStartNext
            2, // shortBreaksCompleted
            300, // totalDuration
            null, // startTimestamp (timer not started)
            null, // pauseTimestamp (timer not paused)
            now, // lastUpdatedAt
            deviceId, // updatedByDeviceId
            2L // version
        );

        // Act
        TimerStateDto dto = TimerStateDto.convertToDto(entity);

        // Assert
        assertNotNull(dto);
        assertEquals("break", dto.getPhase());
        assertEquals(300, dto.getRemainingSeconds());
        assertEquals(false, dto.getIsRunning());
        assertEquals(300, dto.getTotalDuration());
        assertNull(dto.getStartTimestamp());
        assertNull(dto.getPauseTimestamp());
        assertEquals(now, dto.getLastModifiedTimestamp());
        assertEquals(deviceId.toString(), dto.getDeviceId());
    }

    @Test
    @DisplayName("Should convert TimerState entity to DTO with null device ID")
    void shouldConvertEntityToDto_WhenDeviceIdIsNull() {
        // Arrange
        Instant now = Instant.now();
        entity = new TimerState(
            userId,
            "work",
            900, // remainingSeconds
            false, // running
            25, // workDurationMinutes
            5, // breakDurationMinutes
            15, // longBreakDurationMinutes
            false, // autoStartNext
            1, // shortBreaksCompleted
            1500, // totalDuration
            1735489200.0, // startTimestamp
            null, // pauseTimestamp
            now, // lastUpdatedAt
            null, // updatedByDeviceId (no device)
            1L // version
        );

        // Act
        TimerStateDto dto = TimerStateDto.convertToDto(entity);

        // Assert
        assertNotNull(dto);
        assertEquals("work", dto.getPhase());
        assertEquals(900, dto.getRemainingSeconds());
        assertEquals(1735489200.0, dto.getStartTimestamp());
        assertNull(dto.getPauseTimestamp());
        assertNull(dto.getDeviceId()); // Device ID should be null
    }

    @Test
    @DisplayName("Should convert TimerState entity to DTO from createDefault factory method")
    void shouldConvertEntityToDto_FromCreateDefaultFactory() {
        // Arrange
        TimerState defaultState = TimerState.createDefault(userId, deviceId);

        // Act
        TimerStateDto dto = TimerStateDto.convertToDto(defaultState);

        // Assert
        assertNotNull(dto);
        assertEquals("work", dto.getPhase());
        assertEquals(1500, dto.getRemainingSeconds());
        assertEquals(false, dto.getIsRunning());
        assertEquals(25, dto.getWorkDuration());
        assertEquals(5, dto.getBreakDuration());
        assertEquals(15, dto.getLongBreakDuration());
        assertEquals(false, dto.getAutoStartNextSession());
        assertEquals(0, dto.getShortBreaksCompleted());
        assertEquals(1500, dto.getTotalDuration());
        assertNull(dto.getStartTimestamp());
        assertNull(dto.getPauseTimestamp());
        assertNotNull(dto.getLastModifiedTimestamp());
        assertEquals(deviceId.toString(), dto.getDeviceId());
    }

    @Test
    @DisplayName("Should convert TimerState entity to DTO with long break phase")
    void shouldConvertEntityToDto_WithLongBreakPhase() {
        // Arrange
        Instant now = Instant.now();
        entity = new TimerState(
            userId,
            "longBreak",
            600, // remainingSeconds (10 minutes)
            false, // running
            25, // workDurationMinutes
            5, // breakDurationMinutes
            15, // longBreakDurationMinutes
            false, // autoStartNext
            4, // shortBreaksCompleted (4th pomodoro completed)
            900, // totalDuration (15 minutes)
            1735489200.0, // startTimestamp
            1735489300.0, // pauseTimestamp
            now, // lastUpdatedAt
            deviceId, // updatedByDeviceId
            4L // version
        );

        // Act
        TimerStateDto dto = TimerStateDto.convertToDto(entity);

        // Assert
        assertNotNull(dto);
        assertEquals("longBreak", dto.getPhase());
        assertEquals(600, dto.getRemainingSeconds());
        assertEquals(900, dto.getTotalDuration());
        assertEquals(4, dto.getShortBreaksCompleted());
        assertEquals(1735489200.0, dto.getStartTimestamp());
        assertEquals(1735489300.0, dto.getPauseTimestamp());
    }
}
