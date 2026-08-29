package com.sparkage.timebeam.presentation.controller;

import com.sparkage.timebeam.application.service.TimerEventService;
import com.sparkage.timebeam.presentation.dto.TimerEventDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/timer-events")
public class TimerEventController {

    private static final Logger log = LoggerFactory.getLogger(TimerEventController.class);

    private final TimerEventService timerEventService;

    public TimerEventController(TimerEventService timerEventService) {
        this.timerEventService = timerEventService;
    }

    /**
     * Send a timer event from a device
     */
    @PostMapping
    public ResponseEntity<Void> sendTimerEvent(
            @RequestBody TimerEventDto eventDto,
            @RequestHeader(value = "X-Device-ID", required = true) String deviceId,
            Principal principal) {

        UUID userId = resolveUserId(principal);
        if (userId == null) {
            return ResponseEntity.badRequest().build();
        }

        log.info("Received timer event from user={}, device={}, type={}",
                userId, deviceId, eventDto.getEventType());

        // Set the user ID and device ID from authenticated context
        eventDto.setUserId(userId);
        eventDto.setDeviceId(deviceId);

        // Process and broadcast the event
        timerEventService.processTimerEvent(userId, deviceId, eventDto);

        return ResponseEntity.ok().build();
    }

    /**
     * Get recent timer events for app launch sync
     */
    @GetMapping("/recent")
    public ResponseEntity<List<TimerEventDto>> getRecentEvents(
            @RequestParam(value = "since", required = false) Long sinceTimestamp,
            Principal principal) {

        UUID userId = resolveUserId(principal);
        if (userId == null) {
            return ResponseEntity.badRequest().build();
        }

        Instant since = (sinceTimestamp != null) ?
            Instant.ofEpochSecond(sinceTimestamp) :
            Instant.now().minusSeconds(24 * 60 * 60); // Last 24 hours by default

        List<TimerEventDto> events = timerEventService.getRecentEvents(userId, since);

        log.debug("Returning {} recent timer events for user={}", events.size(), userId);
        return ResponseEntity.ok(events);
    }

    /**
     * Helper to resolve UUID user id from Principal. Returns null on missing/invalid principal.
     */
    private UUID resolveUserId(Principal principal) {
        if (principal == null || principal.getName() == null) {
            log.warn("Principal missing or has null name");
            return null;
        }

        try {
            return UUID.fromString(principal.getName());
        } catch (IllegalArgumentException e) {
            log.warn("Invalid UUID format in principal name: {}", principal.getName());
            return null;
        }
    }
}