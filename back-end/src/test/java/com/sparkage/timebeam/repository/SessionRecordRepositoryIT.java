package com.sparkage.timebeam.repository;

import com.sparkage.timebeam.model.SessionRecord;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class SessionRecordRepositoryIT {
    @Autowired
    private SessionRecordRepository repo;

    @Test
    void saveAndFindByUser() {
        UUID userId = UUID.randomUUID();
        SessionRecord r = new SessionRecord(UUID.randomUUID(), userId, Instant.now(), 1500, SessionRecord.Kind.WORK);
        repo.save(r);

        List<SessionRecord> list = repo.findByUserIdOrderByStartedAtDesc(userId);
        assertThat(list).isNotEmpty();
        assertThat(list.get(0).getUserId()).isEqualTo(userId);
    }
}

