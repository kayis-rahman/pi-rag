package com.sparkage.timebeam.presentation.dto;

import java.time.Instant;

public class TimerActionDto {
    private String action;
    private Instant timestamp;
    private String deviceId;

    // Include the complete timer state with the action
    private String phase;
    private Integer remainingSeconds;
    private Boolean isRunning;
    private Integer workDuration;
    private Integer breakDuration;
    private Integer longBreakDuration;
    private Boolean autoStartNextSession;
    private Integer shortBreaksCompleted;

    // Default constructor
    public TimerActionDto() {}

    // Constructor with all fields
    public TimerActionDto(String action, Instant timestamp, String deviceId) {
        this.action = action;
        this.timestamp = timestamp;
        this.deviceId = deviceId;
    }

    // Getters and Setters
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public Instant getTimestamp() { return timestamp; }
    public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

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

    @Override
    public String toString() {
        return "TimerActionDto{" +
                "action='" + action + '\'' +
                ", timestamp=" + timestamp +
                ", deviceId='" + deviceId + '\'' +
                ", phase='" + phase + '\'' +
                ", remainingSeconds=" + remainingSeconds +
                ", isRunning=" + isRunning +
                '}';
    }
}
