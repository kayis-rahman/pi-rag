package com.sparkage.timebeam.infrastructure.persistence;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "session_records", indexes = {
    @Index(columnList = "user_id, started_at DESC"),
    @Index(columnList = "user_id, kind, started_at DESC"),
    @Index(columnList = "started_at"),
    @Index(columnList = "task_id")
})
public class SessionRecord {
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", columnDefinition = "uuid", nullable = false)
    private UUID userId;

    @Column(name = "device_id", columnDefinition = "uuid")
    private UUID deviceId;

    @Column(name = "task_id", columnDefinition = "uuid")
    private UUID taskId;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "duration_seconds", nullable = false)
    private long durationSeconds;

    @Column(name = "kind", nullable = false)
    @Enumerated(EnumType.STRING)
    private Kind kind;

    @Column(name = "was_completed", nullable = false)
    private boolean completed;

    @Column(name = "was_interrupted", nullable = false)
    private boolean interrupted;

    @Column(name = "interruption_reason")
    private String interruptionReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public enum Kind { WORK, SHORT_BREAK, LONG_BREAK }

    public SessionRecord() {}

    public SessionRecord(UUID id, UUID userId, UUID deviceId, UUID taskId, Instant startedAt,
                         long durationSeconds, Kind kind, boolean completed,
                         boolean interrupted, String interruptionReason, Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.deviceId = deviceId;
        this.taskId = taskId;
        this.startedAt = startedAt;
        this.durationSeconds = durationSeconds;
        this.kind = kind;
        this.completed = completed;
        this.interrupted = interrupted;
        this.interruptionReason = interruptionReason;
        this.createdAt = createdAt;
    }

    // Legacy constructor for backward compatibility
    public SessionRecord(UUID id, UUID userId, Instant startedAt, long durationSeconds, Kind kind) {
        this(id, userId, null, null, startedAt, durationSeconds, kind, true, false, null, Instant.now());
    }

    // Getters and setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public UUID getDeviceId() { return deviceId; }
    public void setDeviceId(UUID deviceId) { this.deviceId = deviceId; }

    public UUID getTaskId() { return taskId; }
    public void setTaskId(UUID taskId) { this.taskId = taskId; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public long getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(long durationSeconds) { this.durationSeconds = durationSeconds; }

    public Kind getKind() { return kind; }
    public void setKind(Kind kind) { this.kind = kind; }

    public boolean isCompleted() { return completed; }
    public void setCompleted(boolean completed) { this.completed = completed; }

    public boolean isInterrupted() { return interrupted; }
    public void setInterrupted(boolean interrupted) { this.interrupted = interrupted; }

    public String getInterruptionReason() { return interruptionReason; }
    public void setInterruptionReason(String interruptionReason) { this.interruptionReason = interruptionReason; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
        if (completed == false && interrupted == false) {
            completed = true; // Default assumption
        }
    }

    // Domain methods
    public boolean isProductive() {
        return kind == Kind.WORK;
    }

    public Instant getEndTime() {
        return startedAt.plusSeconds(durationSeconds);
    }

    public int getDurationMinutes() {
        return (int) Math.ceil(durationSeconds / 60.0);
    }

    public void markInterrupted(String reason) {
        this.interrupted = true;
        this.completed = false;
        this.interruptionReason = reason;
    }
}
