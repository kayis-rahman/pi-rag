//
//  BackendConflictResolutionTests.java
//  TimeBeam Testing Framework
//
//  Backend conflict resolution testing for PostgreSQL and vector clocks
//

package com.sparkage.timebeam.testing;

import com.sparkage.timebeam.application.service.CrossDeviceContinuityManager;
import com.sparkage.timebeam.application.service.TimerSyncService;
import com.sparkage.timebeam.application.dto.ConflictResolutionStrategy;
import com.sparkage.timebeam.application.dto.TimerStateDto;
import com.sparkage.timebeam.application.dto.VectorClock;
import com.sparkage.timebeam.domain.model.TimerStateChangeEvent;
import com.sparkage.timebeam.infrastructure.persistence.UserDeviceRepository;
import com.sparkage.timebeam.infrastructure.persistence.UserSyncPreferencesRepository;
import com.sparkage.timebeam.infrastructure.persistence.TimerStateRepository;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Backend conflict resolution tests for multi-device synchronization
 * Tests PostgreSQL MVCC consistency and vector clock ordering
 */
@SpringBootTest
@ActiveProfiles("test")
public class BackendConflictResolutionTests {

    @Autowired
    private CrossDeviceContinuityManager continuityManager;

    @Autowired
    private TimerSyncService timerSyncService;

    @Autowired
    private UserDeviceRepository deviceRepository;

    @Autowired
    private UserSyncPreferencesRepository preferencesRepository;

    @Autowired
    private TimerStateRepository timerStateRepository;

    private ExecutorService executorService;
    private UUID testUserId;

    @BeforeEach
    void setUp() {
        executorService = Executors.newFixedThreadPool(10);
        testUserId = UUID.randomUUID();
    }

    @AfterEach
    void tearDown() throws {
        executorService.shutdown();
        executorService.awaitTermination(5, TimeUnit.SECONDS);
        
        // Clean up test data
        timerStateRepository.deleteByUserId(testUserId);
        deviceRepository.deleteByUserId(testUserId);
        preferencesRepository.deleteByUserId(testUserId);
    }

    // MARK: - Latest Event Wins Tests

    @Test
    @DisplayName("Should resolve conflict using latest event strategy")
    @Transactional
    void testLatestEventWinsStrategy() {
        // Given
        Instant now = Instant.now();
        TimerStateChangeEvent olderEvent = createTimerStateEvent(
            "device1", "start", now.minusSeconds(10));
        TimerStateChangeEvent newerEvent = createTimerStateEvent(
            "device2", "pause", now);

        List<TimerStateChangeEvent> events = Arrays.asList(olderEvent, newerEvent);

        // When
        TimerStateChangeEvent resolved = continuityManager.resolveConflict(
            testUserId, events);

        // Then
        assertNotNull(resolved);
        assertEquals("device2", resolved.getSourceDeviceId());
        assertEquals("pause", resolved.getAction());
        assertTrue(resolved.getTimestamp().isAfter(olderEvent.getTimestamp()));
    }

    @Test
    @DisplayName("Should handle concurrent latest events with same timestamp")
    @Transactional
    void testSameTimestampConflict() {
        // Given
        Instant sameTime = Instant.now();
        TimerStateChangeEvent event1 = createTimerStateEvent(
            "device1", "start", sameTime);
        TimerStateChangeEvent event2 = createTimerStateEvent(
            "device2", "pause", sameTime);

        List<TimerStateChangeEvent> events = Arrays.asList(event1, event2);

        // When
        TimerStateChangeEvent resolved = continuityManager.resolveConflict(
            testUserId, events);

        // Then
        assertNotNull(resolved);
        assertTrue(event1.getSourceDeviceId().equals(resolved.getSourceDeviceId()) ||
                   event2.getSourceDeviceId().equals(resolved.getSourceDeviceId()));
    }

    // MARK: - Device Priority Tests

    @Test
    @DisplayName("Should resolve conflict using device priority strategy")
    @Transactional
    void testDevicePriorityStrategy() {
        // Given - Set device priority preference
        setConflictResolutionStrategy(testUserId, ConflictResolutionStrategy.DEVICE_PRIORITY);

        Instant now = Instant.now();
        TimerStateChangeEvent watchEvent = createTimerStateEvent(
            "watch-device", "start", now);
        TimerStateChangeEvent iOSEvent = createTimerStateEvent(
            "ios-device", "pause", now);
        TimerStateChangeEvent macEvent = createTimerStateEvent(
            "macos-device", "reset", now);

        List<TimerStateChangeEvent> events = Arrays.asList(watchEvent, iOSEvent, macEvent);

        // When
        TimerStateChangeEvent resolved = continuityManager.resolveConflict(
            testUserId, events);

        // Then - macOS should win (highest priority)
        assertNotNull(resolved);
        assertEquals("macos-device", resolved.getSourceDeviceId());
        assertEquals("reset", resolved.getAction());
    }

    // MARK: - Vector Clock Tests

    @Test
    @DisplayName("Should resolve conflict using vector clock ordering")
    @Transactional
    void testVectorClockOrdering() {
        // Given
        VectorClock clock1 = new VectorClock();
        clock1.increment("device1");
        
        VectorClock clock2 = new VectorClock();
        clock2.increment("device1");
        clock2.increment("device2"); // clock2 should be greater

        Instant now = Instant.now();
        TimerStateChangeEvent event1 = createTimerStateEventWithVectorClock(
            "device1", "start", now, clock1);
        TimerStateChangeEvent event2 = createTimerStateEventWithVectorClock(
            "device2", "pause", now, clock2);

        List<TimerStateChangeEvent> events = Arrays.asList(event1, event2);

        // When
        TimerStateChangeEvent resolved = continuityManager.resolveConflict(
            testUserId, events);

        // Then - Event with higher vector clock should win
        assertNotNull(resolved);
        assertEquals("device2", resolved.getSourceDeviceId());
    }

    // MARK: - Helper Methods

    private TimerStateChangeEvent createTimerStateEvent(String deviceId, 
            String action, Instant timestamp) {
        return TimerStateChangeEvent.builder()
                .userId(testUserId)
                .sourceDeviceId(deviceId)
                .phase("work")
                .action(action)
                .timestamp(timestamp)
                .previousState(createMockTimerState(1500, false))
                .newState(createMockTimerState(1200, action.equals("start")))
                .build();
    }

    private TimerStateChangeEvent createTimerStateEventWithVectorClock(
            String deviceId, String action, Instant timestamp, VectorClock vectorClock) {
        return TimerStateChangeEvent.builder()
                .userId(testUserId)
                .sourceDeviceId(deviceId)
                .phase("work")
                .action(action)
                .timestamp(timestamp)
                .previousState(createMockTimerState(1500, false))
                .newState(createMockTimerState(1200, action.equals("start")))
                .vectorClock(vectorClock)
                .build();
    }

    private com.sparkage.timebeam.domain.model.TimerState createMockTimerState(
            int remainingSeconds, boolean isRunning) {
        return com.sparkage.timebeam.domain.model.TimerState.builder()
                .phase("work")
                .remainingSeconds(remainingSeconds)
                .isRunning(isRunning)
                .workDuration(1500)
                .breakDuration(300)
                .longBreakDuration(900)
                .autoStartNext(true)
                .shortBreaksCompleted(0)
                .build();
    }

    private void setConflictResolutionStrategy(UUID userId, 
            ConflictResolutionStrategy strategy) {
        // This would typically be handled by a preferences service
        // For testing, we'll set the preference directly
        var preferences = new UserSyncPreferences();
        preferences.setUserId(userId);
        preferences.setConflictResolutionStrategy(strategy);
        preferencesRepository.save(preferences);
    }
}