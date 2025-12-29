package com.sparkage.timebeam.infrastructure.external;

import java.io.File;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Future;
import java.util.stream.Collectors;

import com.eatthepath.pushy.apns.ApnsClient;
import com.eatthepath.pushy.apns.ApnsClientBuilder;
import com.eatthepath.pushy.apns.PushNotificationResponse;
import com.eatthepath.pushy.apns.auth.ApnsSigningKey;
import com.eatthepath.pushy.apns.util.SimpleApnsPushNotification;
import com.eatthepath.pushy.apns.util.TokenUtil;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.sparkage.timebeam.infrastructure.persistence.UserDevice;
import com.sparkage.timebeam.infrastructure.persistence.UserDeviceRepository;

@Service
public class PushNotificationService {
    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);

    /**
     * Simple data class to hold device token and platform information
     */
    public static class DeviceTokenInfo {
        private final String apnsToken;
        private final String platform;

        public DeviceTokenInfo(String apnsToken, String platform) {
            this.apnsToken = apnsToken;
            this.platform = platform;
        }

        public String getApnsToken() {
            return apnsToken;
        }

        public String getPlatform() {
            return platform;
        }
    }

    @Value("${apns.key-path:#{null}}")
    private String apnsKeyPath;

    @Value("${apns.key-id:#{null}}")
    private String apnsKeyId;

    @Value("${apns.team-id:#{null}}")
    private String apnsTeamId;

    @Value("${apns.bundle-id-ios:com.sparkage.timebeam.ios}")
    private String apnsBundleIdIos;

    @Value("${apns.bundle-id-macos:com.sparkage.timebeam.macos}")
    private String apnsBundleIdMacos;

    @Value("${apns.enabled:false}")
    private boolean apnsEnabled;

    @Value("${apns.production:false}")
    private boolean apnsProduction;

    private ApnsClient apnsClient;
    private final UserDeviceRepository userDeviceRepository;

    public PushNotificationService(UserDeviceRepository userDeviceRepository) {
        this.userDeviceRepository = userDeviceRepository;
    }

    @PostConstruct
    public void init() {
        if (!apnsEnabled || apnsKeyPath == null) {
            log.info("APNs push notifications disabled or not configured");
            return;
        }
        try {
            ApnsClientBuilder builder = new ApnsClientBuilder();
            if (apnsProduction) {
                builder.setApnsServer(ApnsClientBuilder.PRODUCTION_APNS_HOST);
            } else {
                builder.setApnsServer(ApnsClientBuilder.DEVELOPMENT_APNS_HOST);
            }

            // Load APNs signing key
            File signingKeyFile = new File(apnsKeyPath);
            ApnsSigningKey signingKey = ApnsSigningKey.loadFromPkcs8File(
                signingKeyFile,
                apnsTeamId,
                apnsKeyId
            );

            builder.setSigningKey(signingKey);
            apnsClient = builder.build();

            log.info("APNs client initialized successfully for {}", apnsProduction ? "production" : "development");

        } catch (Exception e) {
            log.error("Failed to initialize APNs client", e);
        }
    }

    /**
     * Send silent APNs message to trigger timer sync on other devices
     */
    public void sendTimerSyncPush(String userId, String deviceId, String action, String timestamp) {
        if (!apnsEnabled || apnsClient == null) {
            log.debug("APNs not enabled, skipping push for user: {}", userId);
            return;
        }

        try {
            // Get APNs tokens with platform info for this user (excluding sending device)
            List<DeviceTokenInfo> deviceTokens = getApnsTokensWithPlatformForUser(userId, deviceId);
            if (deviceTokens.isEmpty()) {
                log.debug("No APNs tokens found for user: {}", userId);
                return;
            }

            // Create payload for silent notification matching iOS app expectations
            String payload = String.format(
                "{\"aps\":{\"content-available\":1,\"sound\":\"\"},\"type\":\"timer_sync\",\"action\":{\"action\":\"%s\",\"deviceId\":\"%s\",\"timestamp\":\"%s\"}}",
                action, deviceId, timestamp
            );

            // Send to all devices using platform-specific bundle IDs
            for (DeviceTokenInfo deviceToken : deviceTokens) {
                String bundleId = getBundleIdForPlatform(deviceToken.getPlatform());
                SimpleApnsPushNotification push = new SimpleApnsPushNotification(
                    TokenUtil.sanitizeTokenString(deviceToken.getApnsToken()),
                    bundleId,
                    payload
                );

                Future<PushNotificationResponse<SimpleApnsPushNotification>> response = apnsClient.sendNotification(push);
                log.debug("Timer sync push sent to token: {}, bundle: {}, user: {}",
                         deviceToken.getApnsToken(), bundleId, userId);
            }

        } catch (Exception e) {
            log.error("Failed to send timer sync push for user: {}, device: {}", userId, deviceId, e);
        }
    }

    /**
     * Send timer event push notification to other devices
     */
    public void sendTimerEventPush(String userId, String deviceId, String eventType, String timerData) {
        if (!apnsEnabled || apnsClient == null) {
            log.debug("APNs not enabled, skipping timer event push for user: {}", userId);
            return;
        }

        try {
            // Get APNs tokens with platform info for this user (excluding sending device)
            List<DeviceTokenInfo> deviceTokens = getApnsTokensWithPlatformForUser(userId, deviceId);
            if (deviceTokens.isEmpty()) {
                log.debug("No APNs tokens found for user: {}", userId);
                return;
            }

            // Create payload for timer event notification
            String payload = String.format(
                "{\"aps\":{\"content-available\":1,\"sound\":\"\"},\"type\":\"timer_event\",\"eventType\":\"%s\",\"deviceId\":\"%s\",\"timerData\":%s}",
                eventType, deviceId, timerData
            );

            // Send to all devices using platform-specific bundle IDs
            for (DeviceTokenInfo deviceToken : deviceTokens) {
                String bundleId = getBundleIdForPlatform(deviceToken.getPlatform());
                SimpleApnsPushNotification push = new SimpleApnsPushNotification(
                    TokenUtil.sanitizeTokenString(deviceToken.getApnsToken()),
                    bundleId,
                    payload
                );

                Future<PushNotificationResponse<SimpleApnsPushNotification>> response = apnsClient.sendNotification(push);
                log.debug("Timer event push sent to token: {}, bundle: {}, user: {}, eventType: {}",
                         deviceToken.getApnsToken(), bundleId, userId, eventType);
            }

        } catch (Exception e) {
            log.error("Failed to send timer event push for user: {}, device: {}, eventType: {}", userId, deviceId, eventType, e);
        }
    }

    /**
     * Get APNs tokens with platform for a user, excluding specified device
     */
    private List<DeviceTokenInfo> getApnsTokensWithPlatformForUser(String userId, String excludeDeviceId) {
        UUID userUuid = UUID.fromString(userId);
        return userDeviceRepository.findByUserId(userUuid)
                .stream()
                .filter(device -> !device.getDeviceId().equals(excludeDeviceId))
                .filter(device -> device.getActive())
                .map(device -> new DeviceTokenInfo(
                    device.getApnsToken(),
                    device.getDeviceType()
                ))
                .collect(Collectors.toList());
    }

    /**
     * Get appropriate bundle ID for platform
     */
    private String getBundleIdForPlatform(String platform) {
        if (platform == null) {
            return apnsBundleIdIos;
        }
        return switch (platform.toLowerCase()) {
            case "ios" -> apnsBundleIdIos;
            case "macos" -> apnsBundleIdMacos;
            default -> apnsBundleIdIos;
        };
    }
}
