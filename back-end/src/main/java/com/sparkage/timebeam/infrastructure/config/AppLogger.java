package com.sparkage.timebeam.infrastructure.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AppLogger {

    private static final Logger logger = LoggerFactory.getLogger(AppLogger.class);

    // Prevent instantiation
    private AppLogger() {}

    /**
     * Mask email addresses for privacy
     * @param email Email to mask
     * @return Masked email (e.g., "user***@domain.com")
     */
    public static String maskEmail(String email) {
        if (email == null || email.isEmpty()) {
            return "<empty>";
        }

        int atIndex = email.indexOf('@');
        if (atIndex <= 0) {
            return "<invalid>";
        }

        String localPart = email.substring(0, atIndex);
        String domainPart = email.substring(atIndex);

        // Show first 2 characters, mask the rest
        String maskedLocal = localPart.length() > 2
            ? localPart.substring(0, 2) + "***"
            : localPart + "***";

        return maskedLocal + domainPart;
    }

    /**
     * Mask sensitive tokens/keys
     * @param token Token to mask
     * @return Masked token showing only first/last few characters
     */
    public static String maskToken(String token) {
        if (token == null || token.isEmpty()) {
            return "<empty>";
        }

        if (token.length() <= 8) {
            return "***" + token.substring(Math.max(0, token.length() - 4));
        }

        return token.substring(0, 4) + "***" + token.substring(token.length() - 4);
    }

    /**
     * Log authentication events with PII masking
     */
    public static void logAuthEvent(String event, String email) {
        logger.info("Auth event: {} | Email: {}", event, maskEmail(email));
    }

    /**
     * Log authentication events with user ID
     */
    public static void logAuthEvent(String event, String email, String userId) {
        logger.info("Auth event: {} | Email: {} | UserID: {}", event, maskEmail(email), userId);
    }

    /**
     * Log timer synchronization events
     */
    public static void logSyncEvent(String event, String details) {
        logger.info("Sync event: {} | Details: {}", event, details);
    }

    /**
     * Log API requests with PII masking
     */
    public static void logApiRequest(String method, String path, String userId) {
        logger.debug("API Request: {} {} | UserID: {}", method, path, userId);
    }

    /**
     * Log timer state changes
     */
    public static void logTimerEvent(String event, String phase, String deviceId) {
        logger.info("Timer event: {} | Phase: {} | Device: {}", event, phase, maskToken(deviceId));
    }

    /**
     * Log errors with context
     */
    public static void logError(String context, Throwable error, String userId) {
        logger.error("Error in {} | UserID: {} | Message: {}", context, userId, error.getMessage(), error);
    }

    /**
     * Log session events
     */
    public static void logSessionEvent(String event, String sessionId, String userId) {
        logger.info("Session event: {} | SessionID: {} | UserID: {}", event, sessionId, userId);
    }

    /**
     * Log analytics events
     */
    public static void logAnalyticsEvent(String event, String userId, int dataPoints) {
        logger.info("Analytics event: {} | UserID: {} | DataPoints: {}", event, userId, dataPoints);
    }

    /**
     * Log push notification events
     */
    public static void logPushEvent(String event, String deviceToken, String userId) {
        logger.info("Push event: {} | DeviceToken: {} | UserID: {}",
                   event, maskToken(deviceToken), userId);
    }

    /**
     * Log security events
     */
    public static void logSecurityEvent(String event, String ipAddress, String userAgent) {
        logger.warn("Security event: {} | IP: {} | UserAgent: {}", event, ipAddress, userAgent);
    }
}
