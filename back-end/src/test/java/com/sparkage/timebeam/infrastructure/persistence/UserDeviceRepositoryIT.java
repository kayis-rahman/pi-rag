package com.sparkage.timebeam.infrastructure.persistence;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
class UserDeviceRepositoryIT {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private UserDeviceRepository userDeviceRepository;

    private UUID userId;
    private UUID deviceId;
    private UserDevice userDevice;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        deviceId = UUID.randomUUID();

        userDevice = new UserDevice();
        userDevice.setId(deviceId);
        userDevice.setUserId(userId);
        userDevice.setDeviceId("test-device-123");
        userDevice.setDeviceName("iPhone 15");
        userDevice.setDeviceType("ios");
        userDevice.setPlatformVersion("18.0");
        userDevice.setAppVersion("1.0.0");
        userDevice.setFcmToken("fcm-token-123");
        userDevice.setLastSeenAt(Instant.now());
        userDevice.setActive(true);
    }

    @Test
    void saveAndFindById_ShouldPersistAndRetrieveUserDevice() {
        // When
        UserDevice saved = userDeviceRepository.save(userDevice);
        entityManager.flush();
        entityManager.clear();

        // Then
        Optional<UserDevice> found = userDeviceRepository.findById(deviceId);
        assertThat(found).isPresent();
        assertThat(found.get().getDeviceId()).isEqualTo("test-device-123");
        assertThat(found.get().getDeviceName()).isEqualTo("iPhone 15");
        assertThat(found.get().getDeviceType()).isEqualTo("ios");
        assertThat(found.get().isActive()).isTrue();
    }

    @Test
    void findByUserIdAndActiveTrue_ShouldReturnOnlyActiveDevices() {
        // Given
        userDeviceRepository.save(userDevice);

        // Create an inactive device
        UserDevice inactiveDevice = createUserDevice(userId, "inactive-device", false);
        userDeviceRepository.save(inactiveDevice);

        entityManager.flush();

        // When
        List<UserDevice> activeDevices = userDeviceRepository.findByUserIdAndActiveTrue(userId);

        // Then
        assertThat(activeDevices).hasSize(1);
        assertThat(activeDevices.get(0).getDeviceId()).isEqualTo("test-device-123");
        assertThat(activeDevices.get(0).isActive()).isTrue();
    }

    @Test
    void findByUserIdAndDeviceId_ShouldReturnCorrectDevice() {
        // Given
        userDeviceRepository.save(userDevice);

        // Create another device for same user
        UserDevice anotherDevice = createUserDevice(userId, "another-device", true);
        userDeviceRepository.save(anotherDevice);

        entityManager.flush();

        // When
        Optional<UserDevice> found = userDeviceRepository.findByUserIdAndDeviceId(userId, "test-device-123");

        // Then
        assertThat(found).isPresent();
        assertThat(found.get().getDeviceId()).isEqualTo("test-device-123");
        assertThat(found.get().getDeviceName()).isEqualTo("iPhone 15");
    }

    @Test
    void existsByUserIdAndDeviceId_ShouldReturnTrue_WhenDeviceExists() {
        // Given
        userDeviceRepository.save(userDevice);
        entityManager.flush();

        // When
        boolean exists = userDeviceRepository.existsByUserIdAndDeviceId(userId, "test-device-123");

        // Then
        assertThat(exists).isTrue();
    }

    @Test
    void existsByUserIdAndDeviceId_ShouldReturnFalse_WhenDeviceDoesNotExist() {
        // When
        boolean exists = userDeviceRepository.existsByUserIdAndDeviceId(userId, "nonexistent-device");

        // Then
        assertThat(exists).isFalse();
    }

    @Test
    void findStaleDevices_ShouldReturnDevicesNotSeenRecently() {
        // Given
        Instant oldTimestamp = Instant.now().minusSeconds(40 * 24 * 60 * 60); // 40 days ago
        userDevice.setLastSeenAt(oldTimestamp);
        userDeviceRepository.save(userDevice);

        // Create a recently seen device
        UserDevice recentDevice = createUserDevice(userId, "recent-device", true);
        recentDevice.setLastSeenAt(Instant.now());
        userDeviceRepository.save(recentDevice);

        entityManager.flush();

        // When
        Instant cutoff = Instant.now().minusSeconds(30 * 24 * 60 * 60); // 30 days ago
        List<UserDevice> staleDevices = userDeviceRepository.findStaleDevices(cutoff);

        // Then
        assertThat(staleDevices).hasSize(1);
        assertThat(staleDevices.get(0).getDeviceId()).isEqualTo("test-device-123");
    }

    @Test
    void countByUserIdAndActiveTrue_ShouldReturnCorrectCount() {
        // Given
        userDeviceRepository.save(userDevice);

        // Create another active device
        UserDevice anotherDevice = createUserDevice(userId, "another-device", true);
        userDeviceRepository.save(anotherDevice);

        // Create an inactive device
        UserDevice inactiveDevice = createUserDevice(userId, "inactive-device", false);
        userDeviceRepository.save(inactiveDevice);

        entityManager.flush();

        // When
        long activeCount = userDeviceRepository.countByUserIdAndActiveTrue(userId);

        // Then
        assertThat(activeCount).isEqualTo(2);
    }

    @Test
    void findByUserIdAndDeviceType_ShouldReturnDevicesOfSpecificType() {
        // Given
        userDeviceRepository.save(userDevice);

        // Create a macOS device
        UserDevice macDevice = createUserDevice(userId, "mac-device", true);
        macDevice.setDeviceType("macos");
        userDeviceRepository.save(macDevice);

        // Create an iOS device for different user
        UUID differentUserId = UUID.randomUUID();
        UserDevice iosDevice = createUserDevice(differentUserId, "ios-device", true);
        iosDevice.setDeviceType("ios");
        userDeviceRepository.save(iosDevice);

        entityManager.flush();

        // When
        List<UserDevice> iosDevices = userDeviceRepository.findByUserIdAndDeviceType(userId, "ios");

        // Then
        assertThat(iosDevices).hasSize(1);
        assertThat(iosDevices.get(0).getDeviceId()).isEqualTo("test-device-123");
    }

    @Test
    void delete_ShouldRemoveDeviceFromDatabase() {
        // Given
        userDeviceRepository.save(userDevice);
        entityManager.flush();

        // Verify it exists
        assertThat(userDeviceRepository.existsById(deviceId)).isTrue();

        // When
        userDeviceRepository.delete(userDevice);
        entityManager.flush();

        // Then
        assertThat(userDeviceRepository.existsById(deviceId)).isFalse();
    }

    @Test
    void uniqueConstraint_ShouldPreventDuplicateUserDeviceId() {
        // Given
        userDeviceRepository.save(userDevice);

        // Create another device with same user_id and device_id
        UserDevice duplicateDevice = new UserDevice();
        duplicateDevice.setId(UUID.randomUUID());
        duplicateDevice.setUserId(userId);
        duplicateDevice.setDeviceId("test-device-123"); // Same device_id
        duplicateDevice.setDeviceName("Duplicate Device");
        duplicateDevice.setDeviceType("ios");
        duplicateDevice.setActive(true);

        // When & Then - This should throw an exception due to unique constraint
        org.junit.jupiter.api.Assertions.assertThrows(Exception.class, () -> {
            userDeviceRepository.save(duplicateDevice);
            entityManager.flush();
        });
    }

    @Test
    void multipleUsers_ShouldHaveIsolatedDevices() {
        // Given
        userDeviceRepository.save(userDevice);

        // Create device for different user
        UUID differentUserId = UUID.randomUUID();
        UserDevice differentUserDevice = createUserDevice(differentUserId, "different-device", true);
        userDeviceRepository.save(differentUserDevice);

        entityManager.flush();

        // When
        List<UserDevice> firstUserDevices = userDeviceRepository.findByUserIdAndActiveTrue(userId);
        List<UserDevice> secondUserDevices = userDeviceRepository.findByUserIdAndActiveTrue(differentUserId);

        // Then
        assertThat(firstUserDevices).hasSize(1);
        assertThat(secondUserDevices).hasSize(1);
        assertThat(firstUserDevices.get(0).getUserId()).isNotEqualTo(secondUserDevices.get(0).getUserId());
    }

    @Test
    void updateLastSeenAt_ShouldUpdateTimestamp() {
        // Given
        UserDevice saved = userDeviceRepository.save(userDevice);
        Instant beforeUpdate = saved.getLastSeenAt();
        entityManager.flush();

        // When - Simulate the update query
        userDeviceRepository.updateLastSeen(deviceId, Instant.now().plusSeconds(60));
        entityManager.flush();
        entityManager.clear();

        // Then
        UserDevice updated = userDeviceRepository.findById(deviceId).get();
        assertThat(updated.getLastSeenAt()).isAfter(beforeUpdate);
    }

    private UserDevice createUserDevice(UUID userId, String deviceId, boolean active) {
        UserDevice device = new UserDevice();
        device.setId(UUID.randomUUID());
        device.setUserId(userId);
        device.setDeviceId(deviceId);
        device.setDeviceName("Test Device " + deviceId);
        device.setDeviceType("ios");
        device.setPlatformVersion("18.0");
        device.setAppVersion("1.0.0");
        device.setLastSeenAt(Instant.now());
        device.setActive(active);
        return device;
    }
}
