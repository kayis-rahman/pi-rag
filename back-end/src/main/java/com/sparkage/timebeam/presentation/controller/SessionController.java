package com.sparkage.timebeam.presentation.controller;

import com.sparkage.timebeam.presentation.dto.SessionRecordDto;
import com.sparkage.timebeam.infrastructure.external.UserNotAuthenticatedException;
import com.sparkage.timebeam.application.service.SessionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.UUID;
import java.security.Principal;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api/sessions")
@PreAuthorize("isAuthenticated()")
public class SessionController {
    private static final Logger log = LoggerFactory.getLogger(SessionController.class);

    private final SessionService sessionService;

    public SessionController(SessionService sessionService) {
        this.sessionService = sessionService;
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
