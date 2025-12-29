package com.sparkage.timebeam.application.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;

/**
 * DTO for timer state used in events and API responses
 */
public class TimerStateDto {
    private String phase;
    private Integer remainingSeconds;
    private boolean isRunning;
    private Integer workDuration;
    private Integer breakDuration;
    private Integer longBreakDuration;
    private boolean autoStartNextSession;
    private Integer shortBreaksCompleted;
    private Instant lastModifiedTimestamp;
    private String deviceId;
    
    private TimerStateDto() {}
    
    public static Builder builder() {
        return new Builder();
    }
    
    public static class Builder {
        private String phase;
        private Integer remainingSeconds;
        private boolean isRunning;
        private Integer workDuration;
        private Integer breakDuration;
        private Integer longBreakDuration;
        private boolean autoStartNextSession;
        private Integer shortBreaksCompleted;
        private Instant lastModifiedTimestamp;
        private String deviceId;
        
        public Builder phase(String phase) {
            this.phase = phase;
            return this;
        }
        
        public Builder remainingSeconds(Integer remainingSeconds) {
            this.remainingSeconds = remainingSeconds;
            return this;
        }
        
        public Builder isRunning(boolean isRunning) {
            this.isRunning = isRunning;
            return this;
        }
        
        public Builder workDuration(Integer workDuration) {
            this.workDuration = workDuration;
            return this;
        }
        
        public Builder breakDuration(Integer breakDuration) {
            this.breakDuration = breakDuration;
            return this;
        }
        
        public Builder longBreakDuration(Integer longBreakDuration) {
            this.longBreakDuration = longBreakDuration;
            return this;
        }
        
        public Builder autoStartNextSession(boolean autoStartNextSession) {
            this.autoStartNextSession = autoStartNextSession;
            return this;
        }
        
        public Builder shortBreaksCompleted(Integer shortBreaksCompleted) {
            this.shortBreaksCompleted = shortBreaksCompleted;
            return this;
        }
        
        public Builder lastModifiedTimestamp(Instant lastModifiedTimestamp) {
            this.lastModifiedTimestamp = lastModifiedTimestamp;
            return this;
        }
        
        public Builder deviceId(String deviceId) {
            this.deviceId = deviceId;
            return this;
        }
        
        public TimerStateDto build() {
            TimerStateDto dto = new TimerStateDto();
            dto.phase = this.phase;
            dto.remainingSeconds = this.remainingSeconds;
            dto.isRunning = this.isRunning;
            dto.workDuration = this.workDuration;
            dto.breakDuration = this.breakDuration;
            dto.longBreakDuration = this.longBreakDuration;
            dto.autoStartNextSession = this.autoStartNextSession;
            dto.shortBreaksCompleted = this.shortBreaksCompleted;
            dto.lastModifiedTimestamp = this.lastModifiedTimestamp;
            dto.deviceId = this.deviceId;
            return dto;
        }
    }
    
    // Getters and setters
    public String getPhase() { return phase; }
    public void setPhase(String phase) { this.phase = phase; }
    
    public Integer getRemainingSeconds() { return remainingSeconds; }
    public void setRemainingSeconds(Integer remainingSeconds) { this.remainingSeconds = remainingSeconds; }
    
    public boolean isRunning() { return isRunning; }
    public void setRunning(boolean isRunning) { this.isRunning = isRunning; }
    
    public Integer getWorkDuration() { return workDuration; }
    public void setWorkDuration(Integer workDuration) { this.workDuration = workDuration; }
    
    public Integer getBreakDuration() { return breakDuration; }
    public void setBreakDuration(Integer breakDuration) { this.breakDuration = this.breakDuration; }
    
    public Integer getLongBreakDuration() { return longBreakDuration; }
    public void setLongBreakDuration(Integer longBreakDuration) { this.longBreakDuration = return this.longBreakDuration; }
    
    public boolean isAutoStartNextSession() { return autoStartNextSession; }
    public void setAutoStartNextSession(boolean autoStartNextSession) { this.autoStartNextSession = autoStartNextSession; }
    
    public Integer getShortBreaksCompleted() { return shortBreaksCompleted; }
    public void setShortBreaksCompleted(Integer shortBreaksCompleted) { this.shortBreaksCompleted = shortBreaksCompleted; }
    
    public Instant getLastModifiedTimestamp() { return lastModifiedTimestamp; }
    public void setLastModifiedTimestamp(Instant lastModifiedTimestamp) { this.lastModifiedTimestamp = lastModifiedTimestamp; }
    
    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }
}
    
    public static class Builder {
        private String phase;
        private Integer remainingSeconds;
        private boolean isRunning;
        private Integer workDuration;
        private Integer breakDuration;
        private Integer longBreakDuration;
        private boolean autoStartNextSession;
        private Integer shortBreaksCompleted;
        private Instant lastModifiedTimestamp;
        private String deviceId;
        
        public Builder phase(String phase) {
            this.phase = phase;
            return this;
        }
        
        public Builder remainingSeconds(Integer remainingSeconds) {
            this.remainingSeconds = remainingSeconds;
            return this;
        }
        
        public Builder isRunning(boolean isRunning) {
            this.isRunning = isRunning;
            return this;
        }
        
        public Builder workDuration(Integer workDuration) {
            this.workDuration = workDuration;
            return this;
        }
        
        public Builder breakDuration(Integer breakDuration) {
            this.breakDuration = breakDuration;
            return this;
        }
        
        public Builder longBreakDuration(Integer longBreakDuration) {
            this.longBreakDuration = longBreakDuration;
            return this;
        }
        
        public Builder autoStartNextSession(boolean autoStartNextSession) {
            this.autoStartNextSession = autoStartNextSession;
            return this;
        }
        
        public Builder shortBreaksCompleted(Integer shortBreaksCompleted) {
            this.shortBreaksCompleted = shortBreaksCompleted;
            return this;
        }
        
        public Builder lastModifiedTimestamp(Instant lastModifiedTimestamp) {
            this.lastModifiedTimestamp = lastModifiedTimestamp;
            return this;
        }
        
        public Builder deviceId(String deviceId) {
            this.deviceId = deviceId;
            return this;
        }
        
        public TimerStateDto build() {
            TimerStateDto dto = new TimerStateDto();
            dto.phase = this.phase;
            dto.remainingSeconds = this.remainingSeconds;
            dto.isRunning = this.isRunning;
            dto.workDuration = this.workDuration;
            dto.breakDuration = this.breakDuration;
            dto.longBreakDuration = this.longBreakDuration;
            dto.autoStartNextSession = this.autoStartNextSession;
            dto.shortBreaksCompleted = this.shortBreaksCompleted;
            dto.lastModifiedTimestamp = this.lastModifiedTimestamp;
            dto.deviceId = this.deviceId;
            return dto;
        }
    }
    
    // Getters and setters
    public String getPhase() { return phase; }
    public void setPhase(String phase) { this.phase = phase; }
    
    public Integer getRemainingSeconds() { return remainingSeconds; }
    public void setRemainingSeconds(Integer remainingSeconds) { this.remainingSeconds = remainingSeconds; }
    
    public boolean isRunning() { return isRunning; }
    public void setRunning(boolean isRunning) { this.isRunning = isRunning; }
    
    public Integer getWorkDuration() { return workDuration; }
    public void setWorkDuration(Integer workDuration) { this.workDuration = workDuration; }
    
    public Integer getBreakDuration() { return breakDuration; }
    public void setBreakDuration(Integer breakDuration) { this.breakDuration = breakDuration; }
    
    public Integer getLongBreakDuration() { return longBreakDuration; }
    public void setLongBreakDuration(Integer longBreakDuration) { this.longBreakDuration = longBreakDuration; }
    
    public boolean isAutoStartNextSession() { return autoStartNextSession; }
    public void setAutoStartNextSession(boolean autoStartNextSession) { this.autoStartNextSession = autoStartNextSession; }
    
    public Integer getShortBreaksCompleted() { return shortBreaksCompleted; }
    public void setShortBreaksCompleted(Integer shortBreaksCompleted) { this.shortBreaksCompleted = shortBreaksCompleted; }
    
    public Instant getLastModifiedTimestamp() { return lastModifiedTimestamp; }
    public void setLastModifiedTimestamp(Instant lastModifiedTimestamp) { this.lastModifiedTimestamp = lastModifiedTimestamp; }
    
    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }
}