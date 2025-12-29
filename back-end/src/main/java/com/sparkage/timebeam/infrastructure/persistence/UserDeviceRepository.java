package com.sparkage.timebeam.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Repository for UserDevice entities with enhanced queries for multi-device sync
 */
@Repository
public interface UserDeviceRepository extends JpaRepository<UserDevice, UUID> {

    // Find all active devices for a user
    @Query("SELECT d FROM UserDevice d WHERE d.userId = :userId AND d.active = true")
    List<UserDevice> findActiveDevices(@Param("userId") UUID userId);

    // Find all devices for a user (active and inactive)
    List<UserDevice> findByUserId(@Param("userId") UUID userId);

    // Find device by user and device ID
    Optional<UserDevice> findByUserIdAndDeviceId(@Param("userId") UUID userId, @Param("deviceId") String deviceId);

    // Check if device exists for user
    boolean existsByUserIdAndDeviceId(@Param("userId") UUID userId, @Param("deviceId") String deviceId);

    // Find devices that haven't been seen recently (for cleanup)
    @Query("SELECT d FROM UserDevice d WHERE d.lastSeenAt < :cutoffTime AND d.active = true")
    List<UserDevice> findStaleDevices(@Param("cutoffTime") Instant cutoffTime);

    // Count active devices for a user
    @Query("SELECT COUNT(d) FROM UserDevice d WHERE d.userId = :userId AND d.active = true")
    long countByUserIdAndActiveTrue(@Param("userId") UUID userId);

    // Find devices by type
    List<UserDevice> findByUserIdAndDeviceType(@Param("userId") UUID userId, @Param("deviceType") String deviceType);

    // Update last seen time for a device (using @Modifying for better performance)
    @Modifying
    @Query("UPDATE UserDevice d SET d.lastSeenAt = :now WHERE d.id = :deviceId")
    void updateLastSeen(@Param("deviceId") UUID deviceId, @Param("now") Instant now);

    // Update last seen time for a device with timer state update
    @Modifying
    @Query("UPDATE UserDevice d SET d.lastSeenAt = :now, d.timerStateId = :timerStateId WHERE d.id = :deviceId")
    void updateLastSeenWithTimerState(@Param("deviceId") UUID deviceId,
                                       @Param("now") Instant now,
                                       @Param("timerStateId") UUID timerStateId);
}
