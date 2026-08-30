package com.sparkage.synapse.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface TimerEventRepository extends JpaRepository<TimerEvent, UUID> {

    // Find recent events for a user (for sync on app launch)
    @Query("SELECT e FROM TimerEvent e WHERE e.userId = :userId AND e.timestamp > :since ORDER BY e.timestamp DESC")
    List<TimerEvent> findRecentEventsForUser(@Param("userId") UUID userId, @Param("since") Instant since);

    // Find unprocessed events for broadcasting
    List<TimerEvent> findByProcessedFalseOrderByTimestampAsc();

    // Find events for a specific device (to avoid echoing back to sender)
    List<TimerEvent> findByUserIdAndDeviceIdNotAndProcessedFalseOrderByTimestampAsc(UUID userId, String deviceId);

    // Mark events as processed
    @Query("UPDATE TimerEvent e SET e.processed = true WHERE e.id IN :eventIds")
    void markEventsAsProcessed(@Param("eventIds") List<UUID> eventIds);

    // Clean up old processed events (for maintenance)
    @Query("DELETE FROM TimerEvent e WHERE e.processed = true AND e.timestamp < :cutoffDate")
    int deleteOldProcessedEvents(@Param("cutoffDate") Instant cutoffDate);
}