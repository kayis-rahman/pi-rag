package com.sparkage.synapse.presentation.dto;

import jakarta.validation.constraints.Size;

public class TaskUpdateRequest {
    @Size(max = 255, message = "Title cannot exceed 255 characters")
    private String title;

    @Size(max = 1000, message = "Description cannot exceed 1000 characters")
    private String description;

    private String status;

    public TaskUpdateRequest() {}

    public TaskUpdateRequest(String title, String description, String status) {
        this.title = title;
        this.description = description;
        this.status = status;
    }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}