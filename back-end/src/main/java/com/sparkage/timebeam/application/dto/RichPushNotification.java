package com.sparkage.timebeam.application.dto;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Vector clock for causal ordering of concurrent events
 * Prevents race conditions in distributed timer synchronization
 */
public class VectorClock {
    private String deviceId;
    private Map<String, Long> counters;
    
    private VectorClock() {
        this.counters = new java.util.HashMap<>();
    }
    
    @JsonCreator
    public static VectorClock create(String deviceId) {
        VectorClock clock = new VectorClock();
        clock.deviceId = deviceId;
        return clock;
    }
    
    /**
     * Increment counter for current device
     */
    public void increment(String key) {
        counters.merge(key, 1L, Long::sum);
    }
    
    /**
     * Increment counter for local device
     */
    public void incrementLocal() {
        counters.merge(deviceId, 1L, Long::sum);
    }
    
    /**
     * Update counters from another vector clock
     */
    public void update(VectorClock other) {
        for (Map.Entry<String, Long> entry : other.counters.entrySet()) {
            counters.merge(entry.getKey(), entry.getValue(), Math::max);
        }
    }
    
    /**
     * Check if this clock happened before another
     */
    public boolean happenedBefore(VectorClock other) {
        for (Map.Entry<String, Long> entry : counters.entrySet()) {
            Long otherCount = other.counters.getOrDefault(entry.getKey(), 0L);
            if (entry.getValue() < otherCount) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Check if clocks are concurrent (no ordering)
     */
    public boolean isConcurrentWith(VectorClock other) {
        boolean thisBeforeOther = this.happenedBefore(other);
        boolean otherBeforeThis = other.happenedBefore(this);
        return !thisBeforeOther && !otherBeforeThis;
    }
    
    /**
     * Merge two vector clocks
     */
    public VectorClock merge(VectorClock other) {
        VectorClock merged = new VectorClock();
        merged.deviceId = deviceId;
        
        for (String key : counters.keySet()) {
            Long thisCount = counters.getOrDefault(key, 0L);
            Long otherCount = other.counters.getOrDefault(key, 0L);
            merged.counters.put(key, Math.max(thisCount, otherCount));
        }
        
        return merged;
    }
    
    /**
     * Get all counters as unmodifiable map
     */
    public java.util.Map<String, Long> getCounters() {
        return java.util.Collections.unmodifiableMap(counters);
    }
    
    /**
     * Get device ID
     */
    public String getDeviceId() {
        return deviceId;
    }
}