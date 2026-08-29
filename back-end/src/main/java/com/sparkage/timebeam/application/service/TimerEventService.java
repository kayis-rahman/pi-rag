package com.sparkage.timebeam.application.service;

import com.sparkage.timebeam.infrastructure.external.PushNotificationService;
import com.sparkage.timebeam.infrastructure.persistence.TimerEvent;
import com.sparkage.timebeam.infrastructure.persistence.TimerEventRepository;
import com.sparkage.timebeam.presentation.dto.TimerEventDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TimerEventService {

    private static final Logger log = LoggerFactory.getLogger(TimerEventService.class);

    private final TimerEventRepository timerEventRepository;
    private final PushNotificationService pushNotificationService;
    private final SimpMessagingTemplate messagingTemplate;

    public TimerEventService(TimerEventRepository timerEventRepository,
                           PushNotificationService pushNotificationService,
                           SimpMessagingTemplate messagingTemplate) {
        this.timerEventRepository = timerEventRepository;
        this.pushNotificationService = pushNotificationService;
        this.messagingTemplate = messagingTemplate;
    }

    /**
     * Process and store a timer event from a device
     */
    @Transactional
    public void processTimerEvent(UUID userId, String deviceId, TimerEventDto eventDto) {
        log.info("Processing timer event: user={}, device={}, type={}, timestamp={}",
                userId, deviceId, eventDto.getEventType(), eventDto.getTimestamp());

        // Store the event
        TimerEvent event = new TimerEvent(userId, deviceId,
                TimerEvent.EventType.valueOf(eventDto.getEventType()),
                eventDto.getTimerData());
        timerEventRepository.save(event);

        // Broadcast to other devices immediately
        broadcastEventToOtherDevices(event);

        log.info("Timer event processed and broadcasted: eventId={}", event.getId());
    }

    /**
     * Broadcast timer event to all other active devices for the user
     */
    private void broadcastEventToOtherDevices(TimerEvent event) {
        try {
            // Send via WebSocket to connected clients
            String destination = "/topic/timer-events/" + event.getUserId();
            messagingTemplate.convertAndSend(destination, convertToDto(event));

            // Send push notifications to offline devices
            sendPushNotificationToOtherDevices(event);

        } catch (Exception e) {
            log.error("Failed to broadcast timer event: {}", e.getMessage(), e);
        }
    }

    /**
     * Send push notifications to other devices (not the sender)
     */
    private void sendPushNotificationToOtherDevices(TimerEvent event) {
        // Find other devices for this user
        List<String> otherDeviceIds = timerEventRepository
            .findByUserIdAndDeviceIdNotAndProcessedFalseOrderByTimestampAsc(
                event.getUserId(), event.getDeviceId())
            .stream()
            .map(TimerEvent::getDeviceId)
            .distinct()
            .collect(Collectors.toList());

        if (!otherDeviceIds.isEmpty()) {
            pushNotificationService.sendTimerEventPush(
                event.getUserId().toString(),
                event.getDeviceId(),
                event.getEventType().toString(),
                event.getTimerData()
            );
        }
    }

    /**
     * Get recent events for app launch sync
     */
    @Transactional(readOnly = true)
    public List<TimerEventDto> getRecentEvents(UUID userId, Instant since) {
        return timerEventRepository.findRecentEventsForUser(userId, since)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * Process pending events (for background broadcasting)
     */
    @Scheduled(fixedDelay = 30000) // Every 30 seconds
    @Transactional
    public void processPendingEvents() {
        List<TimerEvent> pendingEvents = timerEventRepository.findByProcessedFalseOrderByTimestampAsc();

        for (TimerEvent event : pendingEvents) {
            try {
                broadcastEventToOtherDevices(event);
                event.setProcessed(true);
            } catch (Exception e) {
                log.warn("Failed to process pending event {}: {}", event.getId(), e.getMessage());
            }
        }

        if (!pendingEvents.isEmpty()) {
            timerEventRepository.saveAll(pendingEvents);
        }
    }

    /**
     * Clean up old processed events
     */
    @Scheduled(fixedDelay = 3600000) // Every hour
    @Transactional
    public void cleanupOldEvents() {
        Instant cutoff = Instant.now().minusSeconds(7 * 24 * 60 * 60); // 7 days ago
        int deletedCount = timerEventRepository.deleteOldProcessedEvents(cutoff);

        if (deletedCount > 0) {
            log.info("Cleaned up {} old timer events", deletedCount);
        }
    }

    private TimerEventDto convertToDto(TimerEvent event) {
        TimerEventDto dto = new TimerEventDto();
        dto.setId(event.getId());
        dto.setUserId(event.getUserId());
        dto.setDeviceId(event.getDeviceId());
        dto.setEventType(event.getEventType().toString());
        dto.setTimerData(event.getTimerData());
        dto.setTimestamp(event.getTimestamp());
        return dto;
    }
}