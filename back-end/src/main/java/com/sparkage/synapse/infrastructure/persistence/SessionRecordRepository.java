package com.sparkage.synapse.infrastructure.persistence;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.sparkage.synapse.infrastructure.persistence.SessionRecord;

public interface SessionRecordRepository extends JpaRepository<SessionRecord, UUID> {
    List<SessionRecord> findByUserIdOrderByStartedAtDesc(UUID userId);
    List<SessionRecord> findByTaskIdAndKindAndCompletedTrue(UUID taskId, SessionRecord.Kind kind);
}
