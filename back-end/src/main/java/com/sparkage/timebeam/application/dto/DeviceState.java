package com.sparkage.timebeam.application.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.sparkage.timebeam.domain.model.TimerStateChangeEvent;
import java.util.List;

/**
 * Device state for cross-device synchronization
 */
public class DeviceState {
    public enum State {
        ACTIVE,
        CONFLICT_RESOLUTION_REQUIRED,
        INACTIVE
    }

    private State state;
    private TimerStateChangeEvent conflictEvent;
    private List<TimerStateChangeEvent> recentEvents;
    private String userId;
    
    private DeviceState() {}
    
    public static Builder builder() {
        return new Builder();
    }
    
    public static class Builder {
        private State state;
        private TimerStateChangeEvent conflictEvent;
        private List<TimerStateChangeEvent> recentEvents;
        private String userId;
        
        public Builder state(State state) {
            this.state = state;
            return this;
        }
        
        public Builder conflictEvent(TimerStateChangeEvent conflictEvent) {
            this.conflictEvent = conflictEvent;
            return this;
        }
        
        public Builder recentEvents(List<TimerStateChangeEvent> recentEvents) {
            this.recentEvents = recentEvents;
            return this;
        }
        
        public Builder userId(String userId) {
            this.userId = userId;
            return this;
        }
        
        public DeviceState build() {
            DeviceState deviceState = new DeviceState();
            deviceState.state = this.state;
            deviceState.conflictEvent = this.conflictEvent;
            deviceState.recentEvents = this.recentEvents;
            deviceState.userId = this.userId;
            return deviceState;
        }
    }
    
    // Getters and setters
    public State getState() { return state; }
    public void setState(State state) { this.state = state; }
    
    public TimerStateChangeEvent getConflictEvent() { return conflictEvent; }
    public void setConflictEvent(TimerStateChangeEvent conflictEvent) { this.conflictEvent = conflictEvent; }
    
    public List<TimerStateChangeEvent> getRecentEvents() { return recentEvents; }
    public void setRecentEvents(List<TimerStateChangeEvent> recentEvents) { this.recentEvents = recentEvents; }
    
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
}