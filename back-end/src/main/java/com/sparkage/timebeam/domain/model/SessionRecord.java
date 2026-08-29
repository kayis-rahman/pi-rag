package com.sparkage.timebeam.domain.model;

import java.time.Instant;
import java.util.UUID;

public class SessionRecord {
    private final UUID id;
    private final UUID userId;
    private final Instant startedAt;
    private final long durationSeconds;
    private final Kind kind;

    public enum Kind {
        WORK, SHORT_BREAK, LONG_BREAK;

        public boolean isProductive() {
            return this == WORK;
        }

        public static Kind fromString(String value) {
            return switch (value.toUpperCase()) {
                case "WORK" -> WORK;
                case "SHORT_BREAK" -> SHORT_BREAK;
                case "LONG_BREAK" -> LONG_BREAK;
                default -> throw new IllegalArgumentException("Unknown session kind: " + value);
            };
        }
    }

    public SessionRecord(UUID id, UUID userId, Instant startedAt, long durationSeconds, Kind kind) {
        this.id = validateId(id);
        this.userId = validateUserId(userId);
        this.startedAt = validateStartedAt(startedAt);
        this.durationSeconds = validateDuration(durationSeconds);
        this.kind = validateKind(kind);
    }

    public UUID getId() { return id; }

    public UUID getUserId() { return userId; }

    public Instant getStartedAt() { return startedAt; }

    public long getDurationSeconds() { return durationSeconds; }

    public Kind getKind() { return kind; }

    // Domain methods
    public boolean isProductive() {
        return kind.isProductive();
    }

    public Instant getEndTime() {
        return startedAt.plusSeconds(durationSeconds);
    }

    public int getDurationMinutes() {
        return (int) Math.ceil(durationSeconds / 60.0);
    }

    // Validation methods
    private UUID validateId(UUID id) {
        if (id == null) {
            throw new IllegalArgumentException("SessionRecord id cannot be null");
        }
        return id;
    }

    private UUID validateUserId(UUID userId) {
        if (userId == null) {
            throw new IllegalArgumentException("UserId cannot be null");
        }
        return userId;
    }

    private Instant validateStartedAt(Instant startedAt) {
        if (startedAt == null) {
            throw new IllegalArgumentException("StartedAt cannot be null");
        }
        if (startedAt.isAfter(Instant.now())) {
            throw new IllegalArgumentException("StartedAt cannot be in the future");
        }
        return startedAt;
    }

    private long validateDuration(long durationSeconds) {
        if (durationSeconds <= 0) {
            throw new IllegalArgumentException("Duration must be positive");
        }
        if (durationSeconds > 24 * 60 * 60) { // 24 hours max
            throw new IllegalArgumentException("Duration cannot exceed 24 hours");
        }
        return durationSeconds;
    }

    private Kind validateKind(Kind kind) {
        if (kind == null) {
            throw new IllegalArgumentException("Kind cannot be null");
        }
        return kind;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        SessionRecord that = (SessionRecord) obj;
        return id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id.hashCode();
    }

    @Override
    public String toString() {
        return "SessionRecord{id=" + id + ", userId=" + userId + ", startedAt=" + startedAt +
               ", durationSeconds=" + durationSeconds + ", kind=" + kind + '}';
    }
}
