package com.sparkage.synapse.application.dto;

/**
 * Conflict resolution strategy for multi-device synchronization
 */
public enum ConflictResolutionStrategy {
    LATEST_EVENT_WINS,    // Use most recent event (chronological)
    DEVICE_PRIORITY,        // Use device hierarchy (Mac > iOS > Watch)
    USER_CHOICE,           // Prompt user to choose
    TIME_BASED            // Keep device with more remaining time
}