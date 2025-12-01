package com.sparkage.timebeam.exception;

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
}
