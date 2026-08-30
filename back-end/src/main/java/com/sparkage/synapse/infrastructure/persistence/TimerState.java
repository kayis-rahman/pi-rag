package com.sparkage.synapse.infrastructure.persistence;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "timer_states", indexes = {
    @Index(columnList = "last_updated_at")
})
public class TimerState {
    @Id
    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Column(nullable = false, length = 20)
    private String phase;

    @Column(name = "remaining_seconds", nullable = false)
    private int remainingSeconds;

    @Column(name = "is_running", nullable = false)
    private boolean running;

    @Column(name = "work_duration_minutes", nullable = false)
    private int workDurationMinutes;

    @Column(name = "break_duration_minutes", nullable = false)
    private int breakDurationMinutes;

    @Column(name = "long_break_duration_minutes", nullable = false)
    private int longBreakDurationMinutes;

    @Column(name = "auto_start_next", nullable = false)
    private boolean autoStartNext;

    @Column(name = "short_breaks_completed", nullable = false)
    private int shortBreaksCompleted;

    @Column(name = "total_duration")
    private Integer totalDuration;

    @Column(name = "start_timestamp")
    private Double startTimestamp;

    @Column(name = "pause_timestamp")
    private Double pauseTimestamp;

    @Column(name = "last_updated_at", nullable = false)
    private Instant lastUpdatedAt;

    @Column(name = "updated_by_device_id", columnDefinition = "uuid")
    private UUID updatedByDeviceId;

    @Version
    @Column(nullable = false)
    private long version;

    public TimerState() {}

    public TimerState(UUID userId, String phase, int remainingSeconds, boolean running,
                     int workDurationMinutes, int breakDurationMinutes, int longBreakDurationMinutes,
                     boolean autoStartNext, int shortBreaksCompleted, Integer totalDuration,
                     Double startTimestamp, Double pauseTimestamp, Instant lastUpdatedAt,
                     UUID updatedByDeviceId, long version) {
        this.userId = userId;
        this.phase = phase;
        this.remainingSeconds = remainingSeconds;
        this.running = running;
        this.workDurationMinutes = workDurationMinutes;
        this.breakDurationMinutes = breakDurationMinutes;
        this.longBreakDurationMinutes = longBreakDurationMinutes;
        this.autoStartNext = autoStartNext;
        this.shortBreaksCompleted = shortBreaksCompleted;
        this.totalDuration = totalDuration;
        this.startTimestamp = startTimestamp;
        this.pauseTimestamp = pauseTimestamp;
        this.lastUpdatedAt = lastUpdatedAt;
        this.updatedByDeviceId = updatedByDeviceId;
        this.version = version;
    }

    // Getters and setters
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getPhase() { return phase; }
    public void setPhase(String phase) { this.phase = phase; }

    public int getRemainingSeconds() { return remainingSeconds; }
    public void setRemainingSeconds(int remainingSeconds) { this.remainingSeconds = remainingSeconds; }

    public boolean isRunning() { return running; }
    public void setRunning(boolean running) { this.running = running; }

    public int getWorkDurationMinutes() { return workDurationMinutes; }
    public void setWorkDurationMinutes(int workDurationMinutes) { this.workDurationMinutes = workDurationMinutes; }

    public int getBreakDurationMinutes() { return breakDurationMinutes; }
    public void setBreakDurationMinutes(int breakDurationMinutes) { this.breakDurationMinutes = breakDurationMinutes; }

    public int getLongBreakDurationMinutes() { return longBreakDurationMinutes; }
    public void setLongBreakDurationMinutes(int longBreakDurationMinutes) { this.longBreakDurationMinutes = longBreakDurationMinutes; }

    public boolean isAutoStartNext() { return autoStartNext; }
    public void setAutoStartNext(boolean autoStartNext) { this.autoStartNext = autoStartNext; }

    public int getShortBreaksCompleted() { return shortBreaksCompleted; }
    public void setShortBreaksCompleted(int shortBreaksCompleted) { this.shortBreaksCompleted = shortBreaksCompleted; }

    public Integer getTotalDuration() { return totalDuration; }
    public void setTotalDuration(Integer totalDuration) { this.totalDuration = totalDuration; }

    public Double getStartTimestamp() { return startTimestamp; }
    public void setStartTimestamp(Double startTimestamp) { this.startTimestamp = startTimestamp; }

    public Double getPauseTimestamp() { return pauseTimestamp; }
    public void setPauseTimestamp(Double pauseTimestamp) { this.pauseTimestamp = pauseTimestamp; }

    public Instant getLastUpdatedAt() { return lastUpdatedAt; }
    public void setLastUpdatedAt(Instant lastUpdatedAt) { this.lastUpdatedAt = lastUpdatedAt; }

    public UUID getUpdatedByDeviceId() { return updatedByDeviceId; }
    public void setUpdatedByDeviceId(UUID updatedByDeviceId) { this.updatedByDeviceId = updatedByDeviceId; }

    public long getVersion() { return version; }
    public void setVersion(long version) { this.version = version; }

    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        if (lastUpdatedAt == null) {
            lastUpdatedAt = Instant.now();
        }
    }

    // Factory method for creating default timer state
    public static TimerState createDefault(UUID userId, UUID deviceId) {
        return new TimerState(
            userId,
            "work", // phase
            25 * 60, // remainingSeconds (25 minutes)
            false, // running
            25, // workDurationMinutes
            5, // breakDurationMinutes
            15, // longBreakDurationMinutes
            false, // autoStartNext
            0, // shortBreaksCompleted
            25 * 60, // totalDuration (25 minutes in seconds)
            null, // startTimestamp (timer not started)
            null, // pauseTimestamp (timer not paused)
            Instant.now(), // lastUpdatedAt
            deviceId, // updatedByDeviceId
            1L // version
        );
    }

    // Method to check if state is stale (for conflict resolution)
    public boolean isStale(Instant otherTimestamp) {
        return this.lastUpdatedAt.isBefore(otherTimestamp);
    }
}
