package com.sparkage.timebeam.infrastructure.persistence;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "timer_events",
       indexes = {
           @Index(name = "idx_timer_events_user_timestamp", columnList = "user_id, timestamp"),
           @Index(name = "idx_timer_events_user_device", columnList = "user_id, device_id")
       })
public class TimerEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "device_id", nullable = false)
    private String deviceId;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false)
    private EventType eventType;

    @Column(name = "timer_data", columnDefinition = "TEXT")
    private String timerData; // JSON representation of timer state

    @Column(name = "timestamp", nullable = false)
    private Instant timestamp;

    @Column(name = "processed", nullable = false)
    private boolean processed = false;

    // Constructors, getters, setters
    public TimerEvent() {}

    public TimerEvent(UUID userId, String deviceId, EventType eventType, String timerData) {
        this.userId = userId;
        this.deviceId = deviceId;
        this.eventType = eventType;
        this.timerData = timerData;
        this.timestamp = Instant.now();
    }

    // Enum for event types
    public enum EventType {
        TIMER_STARTED,
        TIMER_PAUSED,
        TIMER_RESUMED,
        TIMER_COMPLETED,
        TIMER_CANCELLED
    }

    // Getters and setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public EventType getEventType() { return eventType; }
    public void setEventType(EventType eventType) { this.eventType = eventType; }

    public String getTimerData() { return timerData; }
    public void setTimerData(String timerData) { this.timerData = timerData; }

    public Instant getTimestamp() { return timestamp; }
    public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }

    public boolean isProcessed() { return processed; }
    public void setProcessed(boolean processed) { this.processed = processed; }
}