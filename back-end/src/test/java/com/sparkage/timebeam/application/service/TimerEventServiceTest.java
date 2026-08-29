package com.sparkage.timebeam.application.service;

import com.sparkage.timebeam.infrastructure.external.PushNotificationService;
import com.sparkage.timebeam.infrastructure.persistence.TimerEvent;
import com.sparkage.timebeam.infrastructure.persistence.TimerEventRepository;
import com.sparkage.timebeam.presentation.dto.TimerEventDto;
import com.sparkage.timebeam.domain.model.TimerActionType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TimerEventServiceTest {

    @Mock
    private TimerEventRepository timerEventRepository;

    @Mock
    private PushNotificationService pushNotificationService;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    private TimerEventService timerEventService;

    private UUID userId;
    private String deviceId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        deviceId = UUID.randomUUID().toString();
        timerEventService = new TimerEventService(timerEventRepository, pushNotificationService, messagingTemplate);
    }

    @Test
    void testProcessTimerEvent_CreatesAndStoresEvent() {
        // Given
        TimerEventDto eventDto = new TimerEventDto();
        eventDto.setEventType("TIMER_STARTED");
        eventDto.setTimestamp(Instant.now());
        eventDto.setTimerData("{\"phase\":\"work\",\"remainingSeconds\":1500}");

        // When
        timerEventService.processTimerEvent(userId, deviceId, eventDto);

        // Then
        verify(timerEventRepository, times(1)).save(any(TimerEvent.class));
        verify(messagingTemplate, times(1)).convertAndSend(anyString(), any(TimerEventDto.class));
    }

    @Test
    void testGetRecentEvents_ReturnsEvents() {
        // Given
        TimerEvent event = new TimerEvent();
        event.setEventType(TimerEvent.EventType.TIMER_STARTED);
        when(timerEventRepository.findRecentEventsForUser(eq(userId), any(Instant.class)))
                .thenReturn(List.of(event));

        // When
        List<TimerEventDto> result = timerEventService.getRecentEvents(userId, Instant.now().minusSeconds(300));

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        verify(timerEventRepository, times(1)).findRecentEventsForUser(eq(userId), any(Instant.class));
    }

    @Test
    void testProcessPendingEvents_HandlesEvents() {
        // Given
        TimerEvent event = new TimerEvent();
        event.setUserId(userId);
        event.setDeviceId(deviceId);
        event.setEventType(TimerEvent.EventType.TIMER_STARTED);
        event.setTimestamp(Instant.now());
        event.setProcessed(false);

        when(timerEventRepository.findByProcessedFalseOrderByTimestampAsc())
                .thenReturn(List.of(event));

        // When
        timerEventService.processPendingEvents();

        // Then
        verify(timerEventRepository, times(1)).saveAll(any(List.class));
    }

    @Test
    void testCleanupOldEvents_DeletesOldEvents() {
        // Given
        when(timerEventRepository.deleteOldProcessedEvents(any(Instant.class)))
                .thenReturn(5);

        // When
        timerEventService.cleanupOldEvents();

        // Then
        verify(timerEventRepository, times(1)).deleteOldProcessedEvents(any(Instant.class));
    }
}