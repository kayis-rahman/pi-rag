package com.sparkage.timebeam.presentation.dto;

import java.time.Instant;

public class TimerActionDto {
    private String action;
    private Instant timestamp;
    private String deviceId;

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

    @Override
    public String toString() {
        return "TimerActionDto{" +
                "action='" + action + '\'' +
                ", timestamp=" + timestamp +
                ", deviceId='" + deviceId + '\'' +
                '}';
    }
}
