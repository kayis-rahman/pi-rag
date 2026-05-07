package com.sparkage.timebeam.presentation.controller;

import java.security.Principal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import jakarta.validation.Valid;

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
import com.sparkage.timebeam.presentation.dto.ApnsTokenUpdateRequestDto;
import com.sparkage.timebeam.presentation.dto.SessionRecordDto;
import com.sparkage.timebeam.domain.model.TimerActionType;
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
    public ResponseEntity<?> start(@RequestParam(name = "kind", defaultValue = "WORK") String kind,
                                  @RequestParam(name = "taskId", required = false) UUID taskId,
                                  Principal principal) {
        log.debug("start session requested kind={}, taskId={}", kind, taskId);
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        SessionRecordDto created = sessionService.start(kind, uid, taskId);
        log.info("session started: id={}, userId={}, kind={}, taskId={}", created.getId(), created.getUserId(), created.getKind(), taskId);
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

        timerSyncService.pushTimerState(uid, timerState, timerState.getDeviceId());
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
        log.debug("push timer action called: action={}, device={}, phase={}, remainingSeconds={}, isRunning={}, workDuration={}, breakDuration={}, longBreakDuration={}, autoStartNextSession={}, shortBreaksCompleted={}",
                actionDto.getAction(), actionDto.getDeviceId(), actionDto.getPhase(), actionDto.getRemainingSeconds(),
                actionDto.getIsRunning(), actionDto.getWorkDuration(), actionDto.getBreakDuration(),
                actionDto.getLongBreakDuration(), actionDto.getAutoStartNextSession(), actionDto.getShortBreaksCompleted());
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        // Store the action as state - now using the complete timer state provided by the client
        // Retry on optimistic locking failures
        TimerStateDto stateFromAction = null;
        int maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                stateFromAction = convertActionToState(actionDto);
                log.debug("Converted action to state: phase={}, remainingSeconds={}, isRunning={}, workDuration={}, breakDuration={}, longBreakDuration={}, autoStartNextSession={}, shortBreaksCompleted={}",
                        stateFromAction.getPhase(), stateFromAction.getRemainingSeconds(), stateFromAction.getIsRunning(),
                        stateFromAction.getWorkDuration(), stateFromAction.getBreakDuration(), stateFromAction.getLongBreakDuration(),
                        stateFromAction.getAutoStartNextSession(), stateFromAction.getShortBreaksCompleted());
                timerSyncService.pushTimerState(uid, stateFromAction, actionDto.getDeviceId());
                log.info("timer action pushed for user={}, device={}, action={}, phase={}, remaining={}",
                        uid, actionDto.getDeviceId(), actionDto.getAction(),
                        actionDto.getPhase(), actionDto.getRemainingSeconds());
                // Success, break out of retry loop
                break;
            } catch (org.springframework.orm.ObjectOptimisticLockingFailureException e) {
                if (attempt == maxRetries) {
                    log.error("Failed to push timer action after {} attempts due to concurrent updates: user={}, device={}",
                             maxRetries, uid, actionDto.getDeviceId(), e);
                    return ResponseEntity.status(409).build(); // Conflict
                } else {
                    log.warn("Concurrent update detected during commit, retrying attempt {} for user={}, device={}", attempt + 1, uid, actionDto.getDeviceId());
                    // Wait a bit before retry
                    try {
                        Thread.sleep(100 * attempt);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        log.error("Interrupted during retry", ie);
                        return ResponseEntity.status(500).build();
                    }
                }
            } catch (Exception e) {
                log.error("Failed to process timer action", e);
                return ResponseEntity.status(400).build();
            }
        }

        // Send silent push notification with full timer state to other devices
        if (stateFromAction != null) {
            try {
                pushService.sendTimerSyncPush(uid.toString(), actionDto.getDeviceId(), stateFromAction);
            } catch (Exception e) {
                log.warn("Failed to send push notification for timer sync, but action was stored successfully", e);
                // Don't fail the request if push fails - the action is still stored
            }
        }

        return ResponseEntity.ok().build();
    }

    @PostMapping("/devices/apns-token")
    public ResponseEntity<Void> updateApnsToken(@Valid @RequestBody ApnsTokenUpdateRequestDto request, Principal principal) {
        log.debug("update APNs token called: device={}", request.getDeviceId());
        UUID uid = resolveUserId(principal);
        if (uid == null) return ResponseEntity.status(401).build();

        try {
            pushService.storeApnsToken(uid.toString(), request.getDeviceId(), request.getApnsToken());
            log.info("APNs token updated for user={}, device={}", uid, request.getDeviceId());
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Failed to update APNs token for user={}, device={}", uid, request.getDeviceId(), e);
            return ResponseEntity.status(500).build();
        }
    }

    // Helper to convert action to state - now uses complete timer state provided by client
    private TimerStateDto convertActionToState(TimerActionDto actionDto) {
        // Calculate total duration based on phase
        // Durations from iOS arrive in seconds (e.g., workDuration=1500 for 25 minutes)
        // Defaults are: 1500s (25min), 300s (5min), 900s (15min)
        int workDuration = actionDto.getWorkDuration() > 0 ? actionDto.getWorkDuration() : 1500;
        int breakDuration = actionDto.getBreakDuration() > 0 ? actionDto.getBreakDuration() : 300;
        int longBreakDuration = actionDto.getLongBreakDuration() > 0 ? actionDto.getLongBreakDuration() : 900;
        int totalDuration;

        String phase = actionDto.getPhase() != null ? actionDto.getPhase() : "work";
        switch (phase) {
            case "work":
                totalDuration = workDuration;
                break;
            case "break":
            case "short_break":
                totalDuration = breakDuration;
                break;
            case "longBreak":
            case "long_break":
                totalDuration = longBreakDuration;
                break;
            default:
                totalDuration = workDuration;
        }

        // For START/ADVANCE, calculate remainingSeconds from phase duration
        // (client doesn't send it in the action DTO, so it defaults to 0)
        // For PAUSE/RESET/STOP, use the value from the client
        int remainingSeconds;
        TimerActionType action = actionDto.getActionType();
        if (action == TimerActionType.START || action == TimerActionType.ADVANCE) {
            remainingSeconds = totalDuration;
        } else {
            remainingSeconds = actionDto.getRemainingSeconds();
        }

        // Use action's client timestamp as snapshot time (when this action was created)
        // Other devices compute: elapsed = now - startTs, remaining = remainingSeconds - elapsed
        Instant startTs;
        Long actionTimestamp = actionDto.getTimestamp();
        if (actionTimestamp != null && actionTimestamp > 0) {
            startTs = Instant.ofEpochSecond(actionTimestamp);
        } else {
            startTs = Instant.now();
        }

        return new TimerStateDto(
            phase,
            remainingSeconds,
            actionDto.isRunning(),
            workDuration,
            breakDuration,
            longBreakDuration,
            actionDto.isAutoStartNextSession(),
            actionDto.getShortBreaksCompleted(),
            totalDuration,
            startTs.toEpochMilli() / 1000.0,
            null,
            Instant.now(),
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
