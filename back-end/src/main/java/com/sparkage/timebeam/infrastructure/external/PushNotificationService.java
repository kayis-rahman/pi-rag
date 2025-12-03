package com.sparkage.timebeam.infrastructure.external;

import java.io.FileInputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;

import jakarta.annotation.PostConstruct;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class PushNotificationService {
    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);

    @Value("${firebase.service-account-path:#{null}}")
    private String firebaseServiceAccountPath;

    @Value("${firebase.enabled:false}")
    private boolean firebaseEnabled;

    @PostConstruct
    public void init() {
        if (!firebaseEnabled || firebaseServiceAccountPath == null) {
            log.info("Firebase push notifications disabled or not configured");
            return;
        }

        try {
            FileInputStream serviceAccount = new FileInputStream(firebaseServiceAccountPath);

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(com.google.auth.oauth2.GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
            }

            log.info("Firebase initialized successfully");
        } catch (Exception e) {
            log.error("Failed to initialize Firebase", e);
        }
    }

    /**
     * Send silent FCM message to trigger timer sync on other devices
     */
    public void sendTimerSyncPush(String userId, String deviceId, String action) {
        if (!firebaseEnabled) {
            log.debug("Firebase not enabled, skipping push for user: {}", userId);
            return;
        }

        try {
            // Get FCM tokens for this user (excluding the sending device)
            List<String> fcmTokens = getFcmTokensForUser(userId, deviceId);
            if (fcmTokens.isEmpty()) {
                log.debug("No FCM tokens found for user: {}", userId);
                return;
            }

            // Create data-only message (silent)
            Map<String, String> data = new HashMap<>();
            data.put("type", "timer_sync");
            data.put("action", action);
            data.put("fromDevice", deviceId);

            // Send to all devices
            for (String fcmToken : fcmTokens) {
                Message message = Message.builder()
                        .setToken(fcmToken)
                        .putAllData(data)
                        .build();

                try {
                    String response = FirebaseMessaging.getInstance().send(message);
                    log.debug("FCM message sent successfully: {}", response);
                } catch (FirebaseMessagingException e) {
                    log.error("Failed to send FCM message to token: {}", fcmToken, e);
                }
            }

            log.info("Sent timer sync FCM messages to {} devices for user: {}", fcmTokens.size(), userId);

        } catch (Exception e) {
            log.error("Failed to send timer sync FCM messages for user: {}", userId, e);
        }
    }

    /**
     * Get FCM tokens for a user (placeholder - implement based on your token storage)
     */
    private List<String> getFcmTokensForUser(String userId, String excludeDeviceId) {
        // TODO: Implement FCM token storage and retrieval
        // This should return FCM tokens for all devices belonging to the user
        // except the device that sent the action (excludeDeviceId)
        log.warn("getFcmTokensForUser not implemented - returning empty list");
        return List.of();
    }

    /**
     * Store FCM token when app registers for push notifications
     */
    public void storeFcmToken(String userId, String deviceId, String fcmToken) {
        // TODO: Implement FCM token storage
        log.info("FCM token stored for user: {}, device: {}", userId, deviceId);
    }
}
