package com.sparkage.timebeam.presentation.controller;

import java.security.Principal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.sparkage.timebeam.application.service.SessionService;
import com.sparkage.timebeam.application.service.TimerSyncService;
import com.sparkage.timebeam.infrastructure.external.PushNotificationService;
import com.sparkage.timebeam.infrastructure.external.UserNotAuthenticatedException;
import com.sparkage.timebeam.presentation.dto.SessionRecordDto;
import com.sparkage.timebeam.presentation.dto.TimerActionDto;
import com.sparkage.timebeam.presentation.dto.TimerStateDto;

@RestController
@RequestMapping("/api/sessions")
@PreAuthorize("isAuthenticated()")
public class SessionController {
    private static final Logger log = LoggerFactory.getLogger(SessionController.class);

    private final SessionService sessionService;
    private final TimerSyncService timerSyncService;
    private final PushNotificationService pushService;

    public SessionController(SessionService sessionService, TimerSyncService timerSyncService, PushNotificationService pushService) {
        this.sessionService = sessionService;
        this.timerSyncService = timerSyncService;
        this.pushService = pushService;
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody SessionRecordDto dto, Principal principal) {
        log.debug("create session request received: id={}, kind={}, startedAt={}", dto.getId(), dto.getKind(), dto.getStartedAt());
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        dto.setUserId(uid);
        log.debug("attached userId={} to session dto", uid);
        // If client did not provide startedAt, treat this as a request to start the session now
        if (dto.getStartedAt() == null) {
            SessionRecordDto started = sessionService.start(dto.getKind(), uid);
            log.info("session started via create: id={}, userId={}, kind={}", started.getId(), started.getUserId(), started.getKind());
            return ResponseEntity.status(201).body(started);
        }

        // Otherwise, persist whatever DTO was provided
        SessionRecordDto created = sessionService.create(dto);
        log.info("session created: id={}, userId={}", created.getId(), created.getUserId());
        return ResponseEntity.ok(created);
    }

    @PostMapping("/start")
    public ResponseEntity<?> start(@RequestParam(name = "kind", defaultValue = "WORK") String kind, Principal principal) {
        log.debug("start session requested kind={}", kind);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        SessionRecordDto created = sessionService.start(kind, uid);
        log.info("session started: id={}, userId={}, kind={}", created.getId(), created.getUserId(), created.getKind());
        return ResponseEntity.status(201).body(created);
    }

    @GetMapping
    public ResponseEntity<List<SessionRecordDto>> listForCurrentUser(Principal principal) {
        log.debug("listForCurrentUser called");
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        log.debug("listing sessions for userId={}", uid);
        return ResponseEntity.ok(sessionService.listForUser(uid));
    }

    @PostMapping("/{id}/stop")
    public ResponseEntity<SessionRecordDto> stop(@PathVariable("id") UUID id, Principal principal) {
        log.debug("stop session requested id={}", id);
        UUID uid = resolveUserId(principal);
        if (uid == null) {
            throw new UserNotAuthenticatedException("Authentication required to stop session");
        }

        SessionRecordDto stopped = sessionService.stop(id, uid);
        log.info("session stopped: id={}, userId={}, durationSeconds={}", stopped.getId(), stopped.getUserId(), stopped.getDurationSeconds());
        return ResponseEntity.ok(stopped);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable("id") UUID id, Principal principal) {
        log.debug("delete session called for id={}", id);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        // Optional: could check ownership before deleting, but current service deletes by id only
        sessionService.delete(id);
        log.info("session deleted: id={}", id);
        return ResponseEntity.noContent().build();
    }

    // Timer Sync Endpoints

    @PostMapping("/timer/state")
    public ResponseEntity<Void> pushTimerState(@RequestBody TimerStateDto timerState, Principal principal) {
        log.debug("push timer state called: device={}", timerState.getDeviceId());
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        UUID deviceId = UUID.fromString(timerState.getDeviceId());
        timerSyncService.pushTimerState(uid, timerState, deviceId);
        log.info("timer state pushed for user={}, device={}", uid, timerState.getDeviceId());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/timer/state")
    public ResponseEntity<TimerStateDto> pullTimerState(Principal principal) {
        log.debug("pull timer state called");
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        return timerSyncService.pullTimerState(uid)
                .map(state -> {
                    log.info("timer state pulled for user={}, device={}", uid, state.getDeviceId());
                    return ResponseEntity.ok(state);
                })
                .orElse(ResponseEntity.noContent().build());
    }

    @PostMapping("/timer/action")
    public ResponseEntity<Void> pushTimerAction(@RequestBody TimerActionDto actionDto, Principal principal) {
        log.debug("push timer action called: action={}, device={}", actionDto.getAction(), actionDto.getDeviceId());
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        // Store the action as state
        try {
            TimerStateDto stateFromAction = convertActionToState(actionDto);
            UUID deviceId = UUID.fromString(actionDto.getDeviceId());
            timerSyncService.pushTimerState(uid, stateFromAction, deviceId);
            log.info("timer action pushed for user={}, device={}, action={}", uid, actionDto.getDeviceId(), actionDto.getAction());
        } catch (Exception e) {
            log.error("Failed to process timer action", e);
            return ResponseEntity.status(400).build();
        }

        // Send silent push notification to other devices
        try {
            pushService.sendTimerSyncPush(uid.toString(), actionDto.getDeviceId(), actionDto.getAction());
        } catch (Exception e) {
            log.warn("Failed to send push notification for timer sync, but action was stored successfully", e);
            // Don't fail the request if push fails - the action is still stored
        }

        return ResponseEntity.ok().build();
    }

    // Helper to convert action to state (simplified - in practice you'd need more logic)
    private TimerStateDto convertActionToState(TimerActionDto actionDto) {
        // This is a simplified conversion - real implementation would need to track timer state properly
        // For now, we'll create a minimal state that indicates the action was performed
        // ALWAYS use current timestamp for sync actions to avoid old timestamp issues
        Instant timestamp = Instant.now();

        // Determine if timer should be running based on action
        boolean isRunning = "start".equals(actionDto.getAction());

        return new TimerStateDto(
            "WORK", // phase - simplified
            1500,   // remainingSeconds - simplified
            isRunning, // isRunning based on action (only "start" = true)
            1500,   // workDuration
            300,    // breakDuration
            900,    // longBreakDuration
            true,   // autoStartNextSession
            0,      // shortBreaksCompleted
            timestamp,
            actionDto.getDeviceId()
        );
    }



    // Helper to resolve UUID user id from Principal. Returns null on missing/invalid principal.
    private UUID resolveUserId(Principal principal) {
        if (principal == null || principal.getName() == null) {
            log.info("principal missing or has null name");
            return null;
        }
        try {
            return UUID.fromString(principal.getName());
        } catch (Exception ex) {
            log.info("invalid principal name for UUID conversion: {}", principal.getName());
            return null;
        }
    }
}
