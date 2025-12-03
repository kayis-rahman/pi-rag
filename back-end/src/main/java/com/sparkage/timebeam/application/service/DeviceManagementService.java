package com.sparkage.timebeam.application.service;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.sparkage.timebeam.infrastructure.persistence.UserDevice;
import com.sparkage.timebeam.infrastructure.persistence.UserDeviceRepository;
import com.sparkage.timebeam.presentation.dto.DeviceRegistrationDto;

@Service
public class DeviceManagementService {
    private static final Logger log = LoggerFactory.getLogger(DeviceManagementService.class);

    private final UserDeviceRepository deviceRepository;

    public DeviceManagementService(UserDeviceRepository deviceRepository) {
        this.deviceRepository = deviceRepository;
    }

    /**
     * Register or update a device for a user
     */
    @Transactional
    public UserDevice registerOrUpdateDevice(UUID userId, DeviceRegistrationDto registration) {
        log.info("Registering/updating device for user={}, deviceId={}", userId, registration.getDeviceId());

        // Check if device already exists
        Optional<UserDevice> existingDeviceOpt = deviceRepository.findByUserIdAndDeviceId(userId, registration.getDeviceId());

        if (existingDeviceOpt.isPresent()) {
            // Update existing device
            UserDevice existingDevice = existingDeviceOpt.get();
            updateDeviceInfo(existingDevice, registration);
            deviceRepository.save(existingDevice);
            log.info("Updated existing device: {}", existingDevice.getId());
            return existingDevice;
        } else {
            // Create new device
            UserDevice newDevice = createDeviceFromRegistration(userId, registration);
            deviceRepository.save(newDevice);
            log.info("Created new device: {}", newDevice.getId());
            return newDevice;
        }
    }

    /**
     * Get all active devices for a user
     */
    @Transactional(readOnly = true)
    public List<UserDevice> getActiveDevices(UUID userId) {
        List<UserDevice> devices = deviceRepository.findByUserIdAndActiveTrue(userId);
        log.debug("Found {} active devices for user={}", devices.size(), userId);
        return devices;
    }

    /**
     * Update device last seen time
     */
    @Transactional
    public void updateDeviceLastSeen(UUID deviceId) {
        Optional<UserDevice> deviceOpt = deviceRepository.findById(deviceId);
        if (deviceOpt.isPresent()) {
            UserDevice device = deviceOpt.get();
            device.setLastSeenAt(Instant.now());
            deviceRepository.save(device);
            log.debug("Updated last seen time for device={}", deviceId);
        }
    }

    /**
     * Deactivate a device
     */
    @Transactional
    public void deactivateDevice(UUID deviceId) {
        Optional<UserDevice> deviceOpt = deviceRepository.findById(deviceId);
        if (deviceOpt.isPresent()) {
            UserDevice device = deviceOpt.get();
            device.setActive(false);
            deviceRepository.save(device);
            log.info("Deactivated device={}", deviceId);
        }
    }

    /**
     * Clean up stale devices (not seen for more than specified days)
     */
    @Transactional
    public int cleanupStaleDevices(int maxDaysInactive) {
        Instant cutoff = Instant.now().minusSeconds(maxDaysInactive * 24L * 60L * 60L);

        List<UserDevice> staleDevices = deviceRepository.findStaleDevices(cutoff);

        for (UserDevice device : staleDevices) {
            device.setActive(false);
            deviceRepository.save(device);
        }

        if (!staleDevices.isEmpty()) {
            log.info("Deactivated {} stale devices (inactive since {})", staleDevices.size(), cutoff);
        }

        return staleDevices.size();
    }

    /**
     * Get device by ID with user validation
     */
    @Transactional(readOnly = true)
    public Optional<UserDevice> getDeviceByIdAndUser(UUID deviceId, UUID userId) {
        Optional<UserDevice> deviceOpt = deviceRepository.findById(deviceId);

        if (deviceOpt.isPresent()) {
            UserDevice device = deviceOpt.get();
            if (device.getUserId().equals(userId)) {
                return Optional.of(device);
            }
        }

        return Optional.empty();
    }

    /**
     * Get device statistics for a user
     */
    @Transactional(readOnly = true)
    public DeviceStats getDeviceStats(UUID userId) {
        List<UserDevice> allDevices = deviceRepository.findByUserId(userId);
        List<UserDevice> activeDevices = deviceRepository.findByUserIdAndActiveTrue(userId);

        long iosDevices = activeDevices.stream()
                .filter(d -> "ios".equals(d.getDeviceType()))
                .count();
        long macosDevices = activeDevices.stream()
                .filter(d -> "macos".equals(d.getDeviceType()))
                .count();
        long watchosDevices = activeDevices.stream()
                .filter(d -> "watchos".equals(d.getDeviceType()))
                .count();

        return new DeviceStats(
                allDevices.size(),
                activeDevices.size(),
                iosDevices,
                macosDevices,
                watchosDevices
        );
    }

    // Helper methods

    private void updateDeviceInfo(UserDevice device, DeviceRegistrationDto registration) {
        device.setDeviceName(registration.getDeviceName());
        device.setDeviceType(registration.getDeviceType());
        device.setPlatformVersion(registration.getPlatformVersion());
        device.setAppVersion(registration.getAppVersion());
        device.setFcmToken(registration.getFcmToken());
        device.setLastSeenAt(Instant.now());
        device.setActive(true);
    }

    private UserDevice createDeviceFromRegistration(UUID userId, DeviceRegistrationDto registration) {
        UserDevice device = new UserDevice();
        device.setId(UUID.randomUUID());
        device.setUserId(userId);
        device.setDeviceId(registration.getDeviceId());
        device.setDeviceName(registration.getDeviceName());
        device.setDeviceType(registration.getDeviceType());
        device.setPlatformVersion(registration.getPlatformVersion());
        device.setAppVersion(registration.getAppVersion());
        device.setFcmToken(registration.getFcmToken());
        device.setLastSeenAt(Instant.now());
        device.setActive(true);
        return device;
    }

    // Inner class for device statistics
    public static class DeviceStats {
        private final int totalDevices;
        private final int activeDevices;
        private final long iosDevices;
        private final long macosDevices;
        private final long watchosDevices;

        public DeviceStats(int totalDevices, int activeDevices, long iosDevices, long macosDevices, long watchosDevices) {
            this.totalDevices = totalDevices;
            this.activeDevices = activeDevices;
            this.iosDevices = iosDevices;
            this.macosDevices = macosDevices;
            this.watchosDevices = watchosDevices;
        }

        public int getTotalDevices() { return totalDevices; }
        public int getActiveDevices() { return activeDevices; }
        public long getIosDevices() { return iosDevices; }
        public long getMacosDevices() { return macosDevices; }
        public long getWatchosDevices() { return watchosDevices; }
    }
}
