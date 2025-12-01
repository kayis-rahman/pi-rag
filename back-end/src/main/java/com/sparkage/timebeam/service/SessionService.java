package com.sparkage.timebeam.service;

import com.sparkage.timebeam.dto.SessionRecordDto;
import com.sparkage.timebeam.exception.AccessDeniedException;
import com.sparkage.timebeam.exception.ResourceNotFoundException;
import com.sparkage.timebeam.mapper.SessionRecordMapper;
import com.sparkage.timebeam.model.SessionRecord;
import com.sparkage.timebeam.repository.SessionRecordRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.Optional;
import java.time.Instant;
import java.time.Duration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class SessionService {
    private static final Logger log = LoggerFactory.getLogger(SessionService.class);

    private final SessionRecordRepository repository;
    private final SessionRecordMapper mapper;

    public SessionService(SessionRecordRepository repository, SessionRecordMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    public SessionRecordDto create(SessionRecordDto dto) {
        log.debug("SessionService.create called dto.id={}, kind={}", dto.getId(), dto.getKind());
        if (dto.getId() == null) dto.setId(UUID.randomUUID());
        SessionRecord entity = mapper.toEntity(dto);
        repository.save(entity);
        log.info("SessionRecord saved id={}, userId={}", entity.getId(), entity.getUserId());
        return mapper.toDto(entity);
    }

    public List<SessionRecordDto> listForUser(UUID userId) {
        log.debug("listForUser called userId={}", userId);
        return repository.findByUserIdOrderByStartedAtDesc(userId).stream().map(mapper::toDto).collect(Collectors.toList());
    }

    public void delete(UUID id) {
        log.debug("delete session called id={}", id);
        repository.deleteById(id);
    }

    // Start a new session for the given user and kind. Uses current time as startedAt.
    public SessionRecordDto start(String kind, UUID userId) {
        log.debug("SessionService.start called userId={}, kind={}", userId, kind);
        var dto = new SessionRecordDto(null, userId, Instant.now(), 0L, kind);
        return create(dto);
    }

    // Stop an existing session by id. Verifies ownership by userId, computes duration and saves.
    public SessionRecordDto stop(UUID id, UUID userId) {
        log.debug("SessionService.stop called id={}, userId={}", id, userId);

        SessionRecord entity = repository.findById(id)
            .orElseThrow(() -> ResourceNotFoundException.sessionNotFound(id.toString()));

        if (!entity.getUserId().equals(userId)) {
            log.warn("Session access denied: session {} belongs to user {}, requested by user {}",
                id, entity.getUserId(), userId);
            throw AccessDeniedException.sessionAccessDenied(id.toString(), userId.toString());
        }

        long duration = Duration.between(entity.getStartedAt(), Instant.now()).getSeconds();
        entity.setDurationSeconds(duration);
        repository.save(entity);
        log.info("SessionRecord stopped id={}, durationSeconds={}", entity.getId(), duration);
        return mapper.toDto(entity);
    }
}
