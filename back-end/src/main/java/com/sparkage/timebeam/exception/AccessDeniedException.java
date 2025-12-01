package com.sparkage.timebeam.exception;

/**
 * Exception thrown when a user attempts to access a resource they don't own or have permission for.
 * This follows clean code principles by providing specific exception types for different error conditions.
 */
public class AccessDeniedException extends RuntimeException {

    public AccessDeniedException(String message) {
        super(message);
    }

    public AccessDeniedException(String message, Throwable cause) {
        super(message, cause);
    }

    public static AccessDeniedException sessionAccessDenied(String sessionId, String userId) {
        return new AccessDeniedException("Access denied: Session " + sessionId + " does not belong to user " + userId);
    }
}
