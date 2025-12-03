package com.sparkage.timebeam.infrastructure.persistence;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface TimerStateRepository extends JpaRepository<TimerState, UUID> {

    // Find timer state by user ID (primary key query)
    Optional<TimerState> findByUserId(UUID userId);

    // Check if timer state exists for user
    boolean existsByUserId(UUID userId);

    // Find timer states updated after a certain time (for cleanup)
    @Query("SELECT t FROM TimerState t WHERE t.lastUpdatedAt < :cutoffTime")
    List<TimerState> findStaleTimerStates(@Param("cutoffTime") Instant cutoffTime);

    // Find timer states by device
    List<TimerState> findByUpdatedByDeviceId(UUID deviceId);

    // Pessimistic locking for conflict resolution
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT t FROM TimerState t WHERE t.userId = :userId")
    Optional<TimerState> findByUserIdWithLock(@Param("userId") UUID userId);

    // Update last updated time for a user (optimistic locking)
    @Query("UPDATE TimerState t SET t.lastUpdatedAt = :now, t.version = t.version + 1 WHERE t.userId = :userId AND t.version = :expectedVersion")
    int updateLastUpdated(@Param("userId") UUID userId, @Param("now") Instant now, @Param("expectedVersion") long expectedVersion);
}
