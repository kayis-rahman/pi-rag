package com.sparkage.timebeam.presentation.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonAlias;
import com.sparkage.timebeam.domain.model.TimerActionType;

/**
 * Timer Action DTO - Event-based synchronization
 * Contains only action type and static metadata (no continuously changing fields like remainingSeconds)
 */
public class TimerActionDto {
    @JsonAlias({"action", "actionType"})
    private TimerActionType actionType;
    private String phase;
    private boolean isRunning;
    private int remainingSeconds;
    private int workDuration;
    private int breakDuration;
    private int longBreakDuration;
    private boolean autoStartNextSession;
    private int shortBreaksCompleted;
    private String deviceId;
    private Long timestamp;

    // Default constructor
    public TimerActionDto() {}

    // Constructor with all fields
    public TimerActionDto(TimerActionType actionType, String phase, boolean isRunning,
                         int workDuration, int breakDuration, int longBreakDuration,
                         boolean autoStartNextSession, int shortBreaksCompleted,
                         String deviceId, Long timestamp) {
        this.actionType = actionType;
        this.phase = phase;
        this.isRunning = isRunning;
        this.remainingSeconds = remainingSeconds;
        this.workDuration = workDuration;
        this.breakDuration = breakDuration;
        this.longBreakDuration = longBreakDuration;
        this.autoStartNextSession = autoStartNextSession;
        this.shortBreaksCompleted = shortBreaksCompleted;
        this.deviceId = deviceId;
        this.timestamp = timestamp;
    }

    // Getters and setters
    public TimerActionType getActionType() {
        return actionType;
    }

    public void setActionType(TimerActionType actionType) {
        this.actionType = actionType;
    }

    // Alias for getActionType() - used by SessionController
    public TimerActionType getAction() {
        return actionType;
    }

    public void setAction(TimerActionType actionType) {
        this.actionType = actionType;
    }

    public String getPhase() {
        return phase;
    }

    public void setPhase(String phase) {
        this.phase = phase;
    }

    public boolean isRunning() {
        return isRunning;
    }

    public void setRunning(boolean running) {
        this.isRunning = running;
    }

    // Alias for isRunning() - used by SessionController
    public Boolean getIsRunning() {
        return isRunning;
    }

    public void setIsRunning(Boolean running) {
        this.isRunning = running != null ? running : false;
    }

    public int getWorkDuration() {
        return workDuration;
    }

    public void setWorkDuration(int workDuration) {
        this.workDuration = workDuration;
    }

    public int getBreakDuration() {
        return breakDuration;
    }

    public void setBreakDuration(int breakDuration) {
        this.breakDuration = breakDuration;
    }

    public int getLongBreakDuration() {
        return longBreakDuration;
    }

    public void setLongBreakDuration(int longBreakDuration) {
        this.longBreakDuration = longBreakDuration;
    }

    public boolean isAutoStartNextSession() {
        return autoStartNextSession;
    }

    public void setAutoStartNextSession(boolean autoStartNextSession) {
        this.autoStartNextSession = autoStartNextSession;
    }

    // Alias for isAutoStartNextSession() - used by SessionController
    public Boolean getAutoStartNextSession() {
        return autoStartNextSession;
    }

    public void setAutoStartNextSession(Boolean autoStartNextSession) {
        this.autoStartNextSession = autoStartNextSession != null ? autoStartNextSession : false;
    }

    public int getShortBreaksCompleted() {
        return shortBreaksCompleted;
    }

    public void setShortBreaksCompleted(int shortBreaksCompleted) {
        this.shortBreaksCompleted = shortBreaksCompleted;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public Long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Long timestamp) {
        this.timestamp = timestamp;
    }

    public int getRemainingSeconds() {
        return remainingSeconds;
    }

    public void setRemainingSeconds(int remainingSeconds) {
        this.remainingSeconds = remainingSeconds;
    }
}
