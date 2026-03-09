package com.synapse.llm.config;

import org.springframework.ai.chat.model.ChatModel;

/**
 * Wrapper class to hold a configured ChatModel instance and track its health state.
 * Used for failover decisions in multi-instance setups.
 */
public class ModelInstance {
    private final ChatModel chatModel;
    private final String instanceId;
    private final boolean isPrimary;
    private boolean isHealthy = true;
    private String lastFailureReason = null;

    public ModelInstance(ChatModel chatModel, String instanceId, boolean isPrimary) {
        this.chatModel = chatModel;
        this.instanceId = instanceId;
        this.isPrimary = isPrimary;
    }

    public ModelInstance(ChatModel chatModel, String instanceId) {
        this(chatModel, instanceId, false);
    }

    public ChatModel getChatModel() {
        return chatModel;
    }

    public String getInstanceId() {
        return instanceId;
    }

    public boolean isPrimary() {
        return isPrimary;
    }

    public boolean isHealthy() {
        return isHealthy;
    }

    public void setHealthy(boolean healthy) {
        if (healthy) {
            this.isHealthy = true;
            this.lastFailureReason = null;
        } else {
            this.isHealthy = false;
        }
    }

    public void markUnhealthy(String failureReason) {
        this.isHealthy = false;
        this.lastFailureReason = failureReason;
    }

    public String getLastFailureReason() {
        return lastFailureReason;
    }

    @Override
    public String toString() {
        return "ModelInstance{" +
                "instanceId='" + instanceId + '\'' +
                ", isPrimary=" + isPrimary +
                ", isHealthy=" + isHealthy +
                ", lastFailureReason='" + lastFailureReason + '\'' +
                '}';
    }
}
