package com.sparkage.timebeam.model;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "session_records", indexes = {@Index(columnList = "user_id")})
public class SessionRecord {
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", columnDefinition = "uuid", nullable = false)
    private UUID userId;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "duration_seconds", nullable = false)
    private long durationSeconds;

    @Column(name = "kind", nullable = false)
    @Enumerated(EnumType.STRING)
    private Kind kind;

    public enum Kind { WORK, SHORT_BREAK, LONG_BREAK }

    public SessionRecord() {}

    public SessionRecord(UUID id, UUID userId, Instant startedAt, long durationSeconds, Kind kind) {
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

    public Kind getKind() { return kind; }
    public void setKind(Kind kind) { this.kind = kind; }
}
