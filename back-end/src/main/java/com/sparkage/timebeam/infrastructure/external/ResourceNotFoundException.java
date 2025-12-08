package com.sparkage.timebeam.infrastructure.external;

/**
 * Exception thrown when a requested resource is not found.
 * This follows clean code principles by providing specific exception types for different error conditions.
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public ResourceNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }

    public static ResourceNotFoundException sessionNotFound(String sessionId) {
        return new ResourceNotFoundException("Session not found: " + sessionId);
    }

    public static ResourceNotFoundException userNotFound(String userId) {
        return new ResourceNotFoundException("User not found: " + userId);
    }

    public static ResourceNotFoundException taskNotFound(String taskId) {
        return new ResourceNotFoundException("Task not found: " + taskId);
    }
}
