package com.synapse.workflow;

import java.util.Map;

public class TaskState {
    private String taskId;
    private String status;
    private Map<String, Object> data;

    // Constructors
    public TaskState() {}

    public TaskState(String taskId, String status, Map<String, Object> data) {
        this.taskId = taskId;
        this.status = status;
        this.data = data;
    }

    // Getters and setters
    public String getTaskId() {
        return taskId;
    }

    public void setTaskId(String taskId) {
        this.taskId = taskId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Map<String, Object> getData() {
        return data;
    }

    public void setData(Map<String, Object> data) {
        this.data = data;
    }
}