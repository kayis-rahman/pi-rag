package com.sparkage.timebeam.infrastructure.persistence;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface UserDeviceRepository extends JpaRepository<UserDevice, UUID> {

    // Find all active devices for a user
    List<UserDevice> findByUserIdAndActiveTrue(UUID userId);

    // Find all devices for a user (active and inactive)
    List<UserDevice> findByUserId(UUID userId);

    // Find device by user and device ID
    Optional<UserDevice> findByUserIdAndDeviceId(UUID userId, String deviceId);

    // Check if device exists for user
    boolean existsByUserIdAndDeviceId(UUID userId, String deviceId);

    // Find devices that haven't been seen recently (for cleanup)
    @Query("SELECT d FROM UserDevice d WHERE d.lastSeenAt < :cutoffTime AND d.active = true")
    List<UserDevice> findStaleDevices(@Param("cutoffTime") Instant cutoffTime);

    // Count active devices for a user
    long countByUserIdAndActiveTrue(UUID userId);

    // Find devices by type
    List<UserDevice> findByUserIdAndDeviceType(UUID userId, String deviceType);

    // Update last seen time for a device
    @Query("UPDATE UserDevice d SET d.lastSeenAt = :now WHERE d.id = :deviceId")
    void updateLastSeen(@Param("deviceId") UUID deviceId, @Param("now") Instant now);
}
