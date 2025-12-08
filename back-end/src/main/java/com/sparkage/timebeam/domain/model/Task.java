package com.sparkage.timebeam.domain.model;

import java.time.Instant;
import java.util.UUID;

public class Task {
    private final UUID id;
    private final UUID userId;
    private final String title;
    private final String description;
    private final Status status;
    private final Instant createdAt;
    private final Instant updatedAt;

    public enum Status {
        TODO, IN_PROGRESS, COMPLETED;

        public boolean isActive() {
            return this == TODO || this == IN_PROGRESS;
        }

        public boolean isCompleted() {
            return this == COMPLETED;
        }

        public static Status fromString(String value) {
            return switch (value.toUpperCase()) {
                case "TODO" -> TODO;
                case "IN_PROGRESS" -> IN_PROGRESS;
                case "COMPLETED" -> COMPLETED;
                default -> throw new IllegalArgumentException("Unknown task status: " + value);
            };
        }
    }

    public Task(UUID id, UUID userId, String title, String description, Status status, Instant createdAt, Instant updatedAt) {
        this.id = validateId(id);
        this.userId = validateUserId(userId);
        this.title = validateTitle(title);
        this.description = description; // optional
        this.status = validateStatus(status);
        this.createdAt = validateCreatedAt(createdAt);
        this.updatedAt = validateUpdatedAt(updatedAt, createdAt);
    }

    public UUID getId() { return id; }

    public UUID getUserId() { return userId; }

    public String getTitle() { return title; }

    public String getDescription() { return description; }

    public Status getStatus() { return status; }

    public Instant getCreatedAt() { return createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }

    // Domain methods
    public boolean isActive() {
        return status.isActive();
    }

    public boolean isCompleted() {
        return status.isCompleted();
    }

    public Task withStatus(Status newStatus) {
        return new Task(id, userId, title, description, newStatus, createdAt, Instant.now());
    }

    public Task withTitle(String newTitle) {
        return new Task(id, userId, newTitle, description, status, createdAt, Instant.now());
    }

    public Task withDescription(String newDescription) {
        return new Task(id, userId, title, newDescription, status, createdAt, Instant.now());
    }

    // Validation methods
    private UUID validateId(UUID id) {
        if (id == null) {
            throw new IllegalArgumentException("Task id cannot be null");
        }
        return id;
    }

    private UUID validateUserId(UUID userId) {
        if (userId == null) {
            throw new IllegalArgumentException("UserId cannot be null");
        }
        return userId;
    }

    private String validateTitle(String title) {
        if (title == null || title.trim().isEmpty()) {
            throw new IllegalArgumentException("Task title cannot be null or empty");
        }
        if (title.length() > 255) {
            throw new IllegalArgumentException("Task title cannot exceed 255 characters");
        }
        return title.trim();
    }

    private Status validateStatus(Status status) {
        if (status == null) {
            throw new IllegalArgumentException("Task status cannot be null");
        }
        return status;
    }

    private Instant validateCreatedAt(Instant createdAt) {
        if (createdAt == null) {
            throw new IllegalArgumentException("CreatedAt cannot be null");
        }
        if (createdAt.isAfter(Instant.now())) {
            throw new IllegalArgumentException("CreatedAt cannot be in the future");
        }
        return createdAt;
    }

    private Instant validateUpdatedAt(Instant updatedAt, Instant createdAt) {
        if (updatedAt == null) {
            throw new IllegalArgumentException("UpdatedAt cannot be null");
        }
        if (updatedAt.isBefore(createdAt)) {
            throw new IllegalArgumentException("UpdatedAt cannot be before CreatedAt");
        }
        if (updatedAt.isAfter(Instant.now())) {
            throw new IllegalArgumentException("UpdatedAt cannot be in the future");
        }
        return updatedAt;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        Task that = (Task) obj;
        return id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id.hashCode();
    }

    @Override
    public String toString() {
        return "Task{id=" + id + ", userId=" + userId + ", title='" + title + "', status=" + status +
               ", createdAt=" + createdAt + ", updatedAt=" + updatedAt + '}';
    }
}