package com.sparkage.timebeam.domain.model;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.UUID;

/**
 * Event representing a timer state change for multi-device synchronization
 */
public class TimerStateChangeEvent {
    private UUID userId;
    private String sourceDeviceId;
    private TimerStateDto previousState;
    private TimerStateDto newState;
    private String phase;
    private String action;
    private Instant timestamp;
    
    private TimerStateChangeEvent() {}
    
    public static Builder builder() {
        return new Builder();
    }
    
    public static class Builder {
        private UUID userId;
        private String sourceDeviceId;
        private TimerStateDto previousState;
        private TimerStateDto newState;
        private String phase;
        private String action;
        private Instant timestamp;
        
        public Builder userId(UUID userId) {
            this.userId = userId;
            return this;
        }
        
        public Builder sourceDeviceId(String sourceDeviceId) {
            this.sourceDeviceId = sourceDeviceId;
            return this;
        }
        
        public Builder previousState(TimerStateDto previousState) {
            this.previousState = previousState;
            return this;
        }
        
        public Builder newState(TimerStateDto newState) {
            this.newState = newState;
            return this;
        }
        
        public Builder phase(String phase) {
            this.phase = phase;
            return this;
        }
        
        public Builder action(String action) {
            this.action = action;
            return this;
        }
        
        public Builder timestamp(Instant timestamp) {
            this.timestamp = timestamp;
            return this;
        }
        
        public TimerStateChangeEvent build() {
            TimerStateChangeEvent event = new TimerStateChangeEvent();
            event.userId = this.userId;
            event.sourceDeviceId = this.sourceDeviceId;
            event.previousState = this.previousState;
            event.newState = this.newState;
            event.phase = this.phase;
            event.action = this.action;
            event.timestamp = this.timestamp;
            return event;
        }
    }
    
    // Getters
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    
    public String getSourceDeviceId() { return sourceDeviceId; }
    public void setSourceDeviceId(String sourceDeviceId) { this.sourceDeviceId = sourceDeviceId; }
    
    public TimerStateDto getPreviousState() { return previousState; }
    public void setPreviousState(TimerStateDto previousState) { this.previousState = previousState; }
    
    public TimerStateDto getNewState() { return newState; }
    public void setNewState(TimerStateDto newState) { this.newState = newState; }
    
    public String getPhase() { return phase; }
    public void setPhase(String phase) { this.phase = phase; }
    
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
    
    public Instant getTimestamp() { return timestamp; }
    public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }
}