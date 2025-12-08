package com.sparkage.timebeam.presentation.dto;

public class ApnNotificationPayloadDto {
    private String type;
    private TimerSyncActionDto action;

    public ApnNotificationPayloadDto() {}

    public ApnNotificationPayloadDto(String type, TimerSyncActionDto action) {
        this.type = type;
        this.action = action;
    }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public TimerSyncActionDto getAction() { return action; }
    public void setAction(TimerSyncActionDto action) { this.action = action; }

    @Override
    public String toString() {
        return "ApnNotificationPayloadDto{" +
                "type='" + type + '\'' +
                ", action=" + action +
                '}';
    }
}