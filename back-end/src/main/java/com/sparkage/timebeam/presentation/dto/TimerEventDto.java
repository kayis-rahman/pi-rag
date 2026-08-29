package com.sparkage.timebeam.presentation.dto;

import java.time.Instant;
import java.util.UUID;

public class TimerEventDto {

    private UUID id;
    private UUID userId;
    private String deviceId;
    private String eventType;
    private String timerData;
    private Instant timestamp;

    // Constructors, getters, setters
    public TimerEventDto() {}

    public TimerEventDto(UUID id, UUID userId, String deviceId, String eventType, String timerData, Instant timestamp) {
        this.id = id;
        this.userId = userId;
        this.deviceId = deviceId;
        this.eventType = eventType;
        this.timerData = timerData;
        this.timestamp = timestamp;
    }

    // Getters and setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }

    public String getTimerData() { return timerData; }
    public void setTimerData(String timerData) { this.timerData = timerData; }

    public Instant getTimestamp() { return timestamp; }
    public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }
}