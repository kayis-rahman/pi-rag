package com.sparkage.synapse.infrastructure.persistence;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "user_preferences")
public class UserPreferences {
    @Id
    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "work_duration_minutes", nullable = false)
    private int workDurationMinutes;

    @Column(name = "short_break_minutes", nullable = false)
    private int shortBreakMinutes;

    @Column(name = "long_break_minutes", nullable = false)
    private int longBreakMinutes;

    @Column(name = "sessions_before_long_break", nullable = false)
    private int sessionsBeforeLongBreak;

    @Column(name = "auto_start_breaks", nullable = false)
    private boolean autoStartBreaks;

    @Column(name = "auto_start_work", nullable = false)
    private boolean autoStartWork;

    @Column(name = "daily_goal_minutes", nullable = false)
    private int dailyGoalMinutes;

    @Column(nullable = false, length = 20)
    private String theme;

    @Column(name = "sound_enabled", nullable = false)
    private boolean soundEnabled;

    @Column(name = "notifications_enabled", nullable = false)
    private boolean notificationsEnabled;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public UserPreferences() {}

    public UserPreferences(UUID userId, int workDurationMinutes, int shortBreakMinutes,
                          int longBreakMinutes, int sessionsBeforeLongBreak,
                          boolean autoStartBreaks, boolean autoStartWork,
                          int dailyGoalMinutes, String theme, boolean soundEnabled,
                          boolean notificationsEnabled, Instant createdAt, Instant updatedAt) {
        this.userId = userId;
        this.workDurationMinutes = workDurationMinutes;
        this.shortBreakMinutes = shortBreakMinutes;
        this.longBreakMinutes = longBreakMinutes;
        this.sessionsBeforeLongBreak = sessionsBeforeLongBreak;
        this.autoStartBreaks = autoStartBreaks;
        this.autoStartWork = autoStartWork;
        this.dailyGoalMinutes = dailyGoalMinutes;
        this.theme = theme;
        this.soundEnabled = soundEnabled;
        this.notificationsEnabled = notificationsEnabled;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    // Getters and setters
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public int getWorkDurationMinutes() { return workDurationMinutes; }
    public void setWorkDurationMinutes(int workDurationMinutes) { this.workDurationMinutes = workDurationMinutes; }

    public int getShortBreakMinutes() { return shortBreakMinutes; }
    public void setShortBreakMinutes(int shortBreakMinutes) { this.shortBreakMinutes = shortBreakMinutes; }

    public int getLongBreakMinutes() { return longBreakMinutes; }
    public void setLongBreakMinutes(int longBreakMinutes) { this.longBreakMinutes = longBreakMinutes; }

    public int getSessionsBeforeLongBreak() { return sessionsBeforeLongBreak; }
    public void setSessionsBeforeLongBreak(int sessionsBeforeLongBreak) { this.sessionsBeforeLongBreak = sessionsBeforeLongBreak; }

    public boolean isAutoStartBreaks() { return autoStartBreaks; }
    public void setAutoStartBreaks(boolean autoStartBreaks) { this.autoStartBreaks = autoStartBreaks; }

    public boolean isAutoStartWork() { return autoStartWork; }
    public void setAutoStartWork(boolean autoStartWork) { this.autoStartWork = autoStartWork; }

    public int getDailyGoalMinutes() { return dailyGoalMinutes; }
    public void setDailyGoalMinutes(int dailyGoalMinutes) { this.dailyGoalMinutes = dailyGoalMinutes; }

    public String getTheme() { return theme; }
    public void setTheme(String theme) { this.theme = theme; }

    public boolean isSoundEnabled() { return soundEnabled; }
    public void setSoundEnabled(boolean soundEnabled) { this.soundEnabled = soundEnabled; }

    public boolean isNotificationsEnabled() { return notificationsEnabled; }
    public void setNotificationsEnabled(boolean notificationsEnabled) { this.notificationsEnabled = notificationsEnabled; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
        if (updatedAt == null) {
            updatedAt = Instant.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    // Default preferences factory method
    public static UserPreferences createDefault(UUID userId) {
        return new UserPreferences(
            userId,
            25, // workDurationMinutes
            5,  // shortBreakMinutes
            15, // longBreakMinutes
            4,  // sessionsBeforeLongBreak
            true, // autoStartBreaks
            false, // autoStartWork
            120, // dailyGoalMinutes
            "system", // theme
            true, // soundEnabled
            true, // notificationsEnabled
            Instant.now(),
            Instant.now()
        );
    }
}
