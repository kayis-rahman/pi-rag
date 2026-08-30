package com.sparkage.synapse.application.dto;

import java.util.List;
import java.util.UUID;

/**
 * Rich push notification with interactive actions
 */
public class RichPushNotification {
    private UUID userId;
    private String title;
    private String subtitle;
    private String body;
    private Priority priority;
    private List<PushNotificationAction> actions;

    private RichPushNotification() {}

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private UUID userId;
        private String title;
        private String subtitle;
        private String body;
        private Priority priority;
        private List<PushNotificationAction> actions;

        public Builder userId(UUID userId) {
            this.userId = userId;
            return this;
        }

        public Builder userId(String userId) {
            this.userId = userId != null ? UUID.fromString(userId) : null;
            return this;
        }

        public Builder title(String title) {
            this.title = title;
            return this;
        }

        public Builder subtitle(String subtitle) {
            this.subtitle = subtitle;
            return this;
        }

        public Builder body(String body) {
            this.body = body;
            return this;
        }

        public Builder priority(Priority priority) {
            this.priority = priority;
            return this;
        }

        public Builder actions(List<PushNotificationAction> actions) {
            this.actions = actions;
            return this;
        }

        public RichPushNotification build() {
            RichPushNotification notification = new RichPushNotification();
            notification.userId = this.userId;
            notification.title = this.title;
            notification.subtitle = this.subtitle;
            notification.body = this.body;
            notification.priority = this.priority;
            notification.actions = this.actions;
            return notification;
        }
    }

    // Getters and setters
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getSubtitle() { return subtitle; }
    public void setSubtitle(String subtitle) { this.subtitle = subtitle; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public Priority getPriority() { return priority; }
    public void setPriority(Priority priority) { this.priority = priority; }

    public List<PushNotificationAction> getActions() { return actions; }
    public void setActions(List<PushNotificationAction> actions) { this.actions = actions; }

    public enum Priority {
        LOW, MEDIUM, HIGH
    }
}
