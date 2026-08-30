package com.sparkage.synapse.infrastructure.persistence;

import com.sparkage.synapse.application.dto.ConflictResolutionStrategy;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

/**
 * User Sync Preferences Entity
 */
@Entity
@Table(name = "user_sync_preferences")
public class UserSyncPreferences {
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", columnDefinition = "uuid", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "conflict_resolution_strategy", nullable = false)
    private ConflictResolutionStrategy conflictResolutionStrategy;

    @Column(name = "primary_device_id", length = 255)
    private String primaryDeviceId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    // Default constructor
    public UserSyncPreferences() {}

    // Builder pattern
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private UUID id;
        private UUID userId;
        private ConflictResolutionStrategy conflictResolutionStrategy;
        private String primaryDeviceId;

        public Builder id(UUID id) {
            this.id = id;
            return this;
        }

        public Builder userId(UUID userId) {
            this.userId = userId;
            return this;
        }

        public Builder conflictResolutionStrategy(ConflictResolutionStrategy strategy) {
            this.conflictResolutionStrategy = strategy;
            return this;
        }

        public Builder primaryDeviceId(String primaryDeviceId) {
            this.primaryDeviceId = primaryDeviceId;
            return this;
        }

        public UserSyncPreferences build() {
            UserSyncPreferences preferences = new UserSyncPreferences();
            preferences.id = this.id;
            preferences.userId = this.userId;
            preferences.conflictResolutionStrategy = this.conflictResolutionStrategy;
            preferences.primaryDeviceId = this.primaryDeviceId;
            preferences.createdAt = Instant.now();
            preferences.updatedAt = Instant.now();
            return preferences;
        }
    }

    // Getters and setters
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public ConflictResolutionStrategy getConflictResolutionStrategy() {
        return conflictResolutionStrategy;
    }

    public void setConflictResolutionStrategy(ConflictResolutionStrategy conflictResolutionStrategy) {
        this.conflictResolutionStrategy = conflictResolutionStrategy;
    }

    public String getPrimaryDeviceId() {
        return primaryDeviceId;
    }

    public void setPrimaryDeviceId(String primaryDeviceId) {
        this.primaryDeviceId = primaryDeviceId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = Instant.now();
    }
}
