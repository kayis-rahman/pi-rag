package com.sparkage.timebeam.presentation.controller;

import java.security.Principal;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sparkage.timebeam.application.service.DeviceManagementService;
import com.sparkage.timebeam.infrastructure.external.UserNotAuthenticatedException;
import com.sparkage.timebeam.presentation.dto.DeviceRegistrationDto;

@RestController
@RequestMapping("/api/devices")
@PreAuthorize("isAuthenticated()")
public class DeviceController {
    private static final Logger log = LoggerFactory.getLogger(DeviceController.class);

    private final DeviceManagementService deviceService;

    public DeviceController(DeviceManagementService deviceService) {
        this.deviceService = deviceService;
    }

    @PostMapping("/register")
    public ResponseEntity<Void> registerDevice(@RequestBody DeviceRegistrationDto registration,
                                             Principal principal) {
        log.debug("Device registration requested: deviceId={}, deviceType={}",
                 registration.getDeviceId(), registration.getDeviceType());

        UUID userId = resolveUserId(principal);
        if (userId == null) {
            throw new UserNotAuthenticatedException("Authentication required to register device");
        }

        deviceService.registerOrUpdateDevice(userId, registration);
        log.info("Device registered successfully: userId={}, deviceId={}",
                userId, registration.getDeviceId());

        return ResponseEntity.ok().build();
    }

    @GetMapping("/stats")
    public ResponseEntity<DeviceManagementService.DeviceStats> getDeviceStats(Principal principal) {
        log.debug("Device stats requested");

        UUID userId = resolveUserId(principal);
        if (userId == null) {
            throw new UserNotAuthenticatedException("Authentication required to get device stats");
        }

        DeviceManagementService.DeviceStats stats = deviceService.getDeviceStats(userId);
        log.debug("Device stats retrieved for userId={}: total={}, active={}",
                 userId, stats.getTotalDevices(), stats.getActiveDevices());

        return ResponseEntity.ok(stats);
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
