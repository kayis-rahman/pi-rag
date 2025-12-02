package com.sparkage.timebeam.presentation.dto;

import java.time.Instant;
import java.util.UUID;

public class SessionRecordDto {
    private UUID id;
    private UUID userId;
    private Instant startedAt;
    private long durationSeconds;
    private String kind;

    public SessionRecordDto() {}

    public SessionRecordDto(UUID id, UUID userId, Instant startedAt, long durationSeconds, String kind) {
        this.id = id;
        this.userId = userId;
        this.startedAt = startedAt;
        this.durationSeconds = durationSeconds;
        this.kind = kind;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public long getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(long durationSeconds) { this.durationSeconds = durationSeconds; }

    public String getKind() { return kind; }
    public void setKind(String kind) { this.kind = kind; }
}
