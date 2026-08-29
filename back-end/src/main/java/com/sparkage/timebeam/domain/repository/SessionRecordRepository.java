package com.sparkage.timebeam.domain.repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.sparkage.timebeam.domain.model.SessionRecord;

public interface SessionRecordRepository {
    Optional<SessionRecord> findById(UUID id);
    List<SessionRecord> findByUserId(UUID userId);
    List<SessionRecord> findByUserIdAndDateRange(UUID userId, Instant startDate, Instant endDate);
    SessionRecord save(SessionRecord sessionRecord);
    void deleteById(UUID id);
    void deleteByUserId(UUID userId);

    // Analytics queries
    long countByUserId(UUID userId);
    long sumDurationSecondsByUserIdAndDateRange(UUID userId, Instant startDate, Instant endDate);
    List<SessionRecord> findProductiveSessionsByUserIdAndDateRange(UUID userId, Instant startDate, Instant endDate);
}
