package com.sparkage.timebeam.exception;

/**
 * Exception thrown when a user is not authenticated or their authentication is invalid.
 * This follows clean code principles by providing specific exception types for different error conditions.
 */
public class UserNotAuthenticatedException extends RuntimeException {

    public UserNotAuthenticatedException(String message) {
        super(message);
    }

    public UserNotAuthenticatedException(String message, Throwable cause) {
        super(message, cause);
    }
}
