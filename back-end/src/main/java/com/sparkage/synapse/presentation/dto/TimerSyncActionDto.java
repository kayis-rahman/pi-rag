package com.sparkage.synapse.presentation.dto;

public class TimerSyncActionDto {
    private String action;
    private String deviceId;
    private String timestamp;

    public TimerSyncActionDto() {}

    public TimerSyncActionDto(String action, String deviceId, String timestamp) {
        this.action = action;
        this.deviceId = deviceId;
        this.timestamp = timestamp;
    }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }

    @Override
    public String toString() {
        return "TimerSyncActionDto{" +
                "action='" + action + '\'' +
                ", deviceId='" + deviceId + '\'' +
                ", timestamp='" + timestamp + '\'' +
                '}';
    }
}