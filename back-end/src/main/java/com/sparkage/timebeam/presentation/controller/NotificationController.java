package com.sparkage.timebeam.presentation.controller;

import java.security.Principal;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sparkage.timebeam.application.service.DeviceManagementService;
import com.sparkage.timebeam.infrastructure.external.PushNotificationService;
import com.sparkage.timebeam.infrastructure.external.UserNotAuthenticatedException;
import com.sparkage.timebeam.presentation.dto.ApnNotificationPayloadDto;

@RestController
@RequestMapping("/api/notifications")
@PreAuthorize("isAuthenticated()")
public class NotificationController {
    private static final Logger log = LoggerFactory.getLogger(NotificationController.class);

    private final PushNotificationService pushNotificationService;
    private final DeviceManagementService deviceService;

    public NotificationController(PushNotificationService pushNotificationService,
                                DeviceManagementService deviceService) {
        this.pushNotificationService = pushNotificationService;
        this.deviceService = deviceService;
    }

    @PostMapping("/send")
    public ResponseEntity<Void> sendApnNotification(@RequestBody ApnNotificationPayloadDto payload,
                                                  Principal principal) {
        log.debug("APN notification request received: type={}", payload.getType());

        UUID userId = resolveUserId(principal);
        if (userId == null) {
            throw new UserNotAuthenticatedException("Authentication required to send notifications");
        }

        // Validate that the notification is for timer sync
        if (!"timer_sync".equals(payload.getType())) {
            log.warn("Unsupported notification type: {}", payload.getType());
            return ResponseEntity.badRequest().build();
        }

        // Send the notification to other devices
        pushNotificationService.sendTimerSyncPush(
            userId.toString(),
            payload.getAction().getDeviceId(),
            payload.getAction().getAction(),
            payload.getAction().getTimestamp()
        );

        log.info("APN notification sent successfully for user: {}, device: {}",
                userId, payload.getAction().getDeviceId());

        return ResponseEntity.ok().build();
    }

    private UUID resolveUserId(Principal principal) {
        if (principal == null || principal.getName() == null) {
            log.info("Principal missing or has null name");
            return null;
        }
        try {
            return UUID.fromString(principal.getName());
        } catch (Exception ex) {
            log.info("Invalid principal name for UUID conversion: {}", principal.getName());
            return null;
        }
    }
}