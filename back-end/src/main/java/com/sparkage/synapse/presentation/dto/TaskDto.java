package com.sparkage.synapse.presentation.dto;

import java.time.Instant;
import java.util.UUID;

public class TaskDto {
    private UUID id;
    private UUID userId;
    private String title;
    private String description;
    private String status;
    private Instant createdAt;
    private Instant updatedAt;
    private Instant deletedAt;

    public TaskDto() {}

    public TaskDto(UUID id, UUID userId, String title, String description, String status, Instant createdAt, Instant updatedAt) {
        this(id, userId, title, description, status, createdAt, updatedAt, null);
    }

    public TaskDto(UUID id, UUID userId, String title, String description, String status, Instant createdAt, Instant updatedAt, Instant deletedAt) {
        this.id = id;
        this.userId = userId;
        this.title = title;
        this.description = description;
        this.status = status;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.deletedAt = deletedAt;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public Instant getDeletedAt() { return deletedAt; }
    public void setDeletedAt(Instant deletedAt) { this.deletedAt = deletedAt; }
}