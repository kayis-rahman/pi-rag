package com.sparkage.timebeam.application.dto;

/**
 * Push notification action for interactive notifications
 */
public class PushNotificationAction {
    private String id;
    private String title;
    
    public PushNotificationAction() {}
    
    public static Builder builder() {
        return new Builder();
    }
    
    public static class Builder {
        private String id;
        private String title;
        
        public Builder id(String id) {
            this.id = id;
            return this;
        }
        
        public Builder title(String title) {
            this.title = title;
            return this;
        }
        
        public PushNotificationAction build() {
            PushNotificationAction action = new PushNotificationAction();
            action.id = this.id;
            action.title = this.title;
            return action;
        }
    }
    
    // Getters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
}