package com.sparkage.timebeam.repository;

import com.sparkage.timebeam.model.SessionRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SessionRecordRepository extends JpaRepository<SessionRecord, UUID> {
    List<SessionRecord> findByUserIdOrderByStartedAtDesc(UUID userId);
}
