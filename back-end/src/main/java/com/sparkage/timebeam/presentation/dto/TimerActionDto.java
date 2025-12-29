package com.sparkage.timebeam.presentation.dto;

import com.sparkage.timebeam.domain.model.TimerActionType;
import com.sparkage.timebeam.domain.model.TimerState;

public class TimerActionDto {
    private TimerActionType actionType;
    private TimerState timerState;
    private String deviceId;
    private Long timestamp;
    
    // Default constructor
    public TimerActionDto() {}
    
    // Constructor with all fields
    public TimerActionDto(TimerActionType actionType, TimerState timerState, String deviceId, Long timestamp) {
        this.actionType = actionType;
        this.timerState = timerState;
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
    
    public TimerState getTimerState() {
        return timerState;
    }
    
    public void setTimerState(TimerState timerState) {
        this.timerState = timerState;
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
}