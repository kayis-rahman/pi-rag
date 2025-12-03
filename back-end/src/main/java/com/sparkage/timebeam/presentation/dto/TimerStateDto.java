package com.sparkage.timebeam.presentation.dto;

import java.time.Instant;

public class TimerStateDto {
    private String phase;
    private Integer remainingSeconds;
    private Boolean isRunning;
    private Integer workDuration;
    private Integer breakDuration;
    private Integer longBreakDuration;
    private Boolean autoStartNextSession;
    private Integer shortBreaksCompleted;
    private Instant timestamp;
    private String deviceId;

    // Default constructor
    public TimerStateDto() {}

    // Constructor with all fields (no primary device concept)
    public TimerStateDto(String phase, Integer remainingSeconds, Boolean isRunning,
                        Integer workDuration, Integer breakDuration, Integer longBreakDuration,
                        Boolean autoStartNextSession, Integer shortBreaksCompleted,
                        Instant timestamp, String deviceId) {
        this.phase = phase;
        this.remainingSeconds = remainingSeconds;
        this.isRunning = isRunning;
        this.workDuration = workDuration;
        this.breakDuration = breakDuration;
        this.longBreakDuration = longBreakDuration;
        this.autoStartNextSession = autoStartNextSession;
        this.shortBreaksCompleted = shortBreaksCompleted;
        this.timestamp = timestamp;
        this.deviceId = deviceId;
    }

    // Getters and Setters
    public String getPhase() { return phase; }
    public void setPhase(String phase) { this.phase = phase; }

    public Integer getRemainingSeconds() { return remainingSeconds; }
    public void setRemainingSeconds(Integer remainingSeconds) { this.remainingSeconds = remainingSeconds; }

    public Boolean getIsRunning() { return isRunning; }
    public void setIsRunning(Boolean isRunning) { this.isRunning = isRunning; }

    public Integer getWorkDuration() { return workDuration; }
    public void setWorkDuration(Integer workDuration) { this.workDuration = workDuration; }

    public Integer getBreakDuration() { return breakDuration; }
    public void setBreakDuration(Integer breakDuration) { this.breakDuration = breakDuration; }

    public Integer getLongBreakDuration() { return longBreakDuration; }
    public void setLongBreakDuration(Integer longBreakDuration) { this.longBreakDuration = longBreakDuration; }

    public Boolean getAutoStartNextSession() { return autoStartNextSession; }
    public void setAutoStartNextSession(Boolean autoStartNextSession) { this.autoStartNextSession = autoStartNextSession; }

    public Integer getShortBreaksCompleted() { return shortBreaksCompleted; }
    public void setShortBreaksCompleted(Integer shortBreaksCompleted) { this.shortBreaksCompleted = shortBreaksCompleted; }

    public Instant getTimestamp() { return timestamp; }
    public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    @Override
    public String toString() {
        return "TimerStateDto{" +
                "phase='" + phase + '\'' +
                ", remainingSeconds=" + remainingSeconds +
                ", isRunning=" + isRunning +
                ", timestamp=" + timestamp +
                ", deviceId='" + deviceId + '\'' +
                '}';
    }
}
