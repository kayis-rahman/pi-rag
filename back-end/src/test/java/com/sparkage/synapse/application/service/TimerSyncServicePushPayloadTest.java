package com.sparkage.synapse.application.service;

import com.sparkage.synapse.infrastructure.external.PushNotificationService;
import com.sparkage.synapse.infrastructure.persistence.TimerState;
import com.sparkage.synapse.presentation.dto.TimerStateDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for TimerSyncService push payload completeness (SYNC-05).
 *
 * These stubs verify that the APNs push payload includes all required fields
 * for cross-device sync: autoStartNextSession, shortBreaksCompleted, lastModifiedTimestamp.
 */
@ExtendWith(MockitoExtension.class)
class TimerSyncServicePushPayloadTest {

    @Mock
    private PushNotificationService pushNotificationService;

    @Mock
    private TimerState timerState;

    private TimerSyncService timerSyncService;

    private UUID userId;
    private String deviceIdString;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        deviceIdString = UUID.randomUUID().toString();
        timerSyncService = new TimerSyncService(null, pushNotificationService);
    }

    // MARK: - Push Payload Field Tests

    @Test
    @Disabled("not implemented — will be satisfied by Plan 01")
    void test_sendTimerSyncPush_includesAutoStartNextSession() {
        fail("not implemented");
    }

    @Test
    @Disabled("not implemented — will be satisfied by Plan 01")
    void test_sendTimerSyncPush_includesShortBreaksCompleted() {
        fail("not implemented");
    }

    @Test
    @Disabled("not implemented — will be satisfied by Plan 01")
    void test_sendTimerSyncPush_includesLastModifiedTimestamp() {
        fail("not implemented");
    }

    // MARK: - Action to State Conversion Tests

    @Test
    @Disabled("not implemented — will be satisfied by Plan 01")
    void test_convertActionToStateDto_readsAutoStartNextFromEntity() {
        fail("not implemented");
    }

    @Test
    @Disabled("not implemented — will be satisfied by Plan 01")
    void test_convertActionToStateDto_readsShortBreaksCompletedFromEntity() {
        fail("not implemented");
    }
}
