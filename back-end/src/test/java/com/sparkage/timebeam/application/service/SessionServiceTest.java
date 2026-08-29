package com.sparkage.timebeam.application.service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.mapstruct.factory.Mappers;
import org.mockito.Mockito;

import com.sparkage.timebeam.infrastructure.persistence.SessionRecord;
import com.sparkage.timebeam.infrastructure.persistence.SessionRecordMapper;
import com.sparkage.timebeam.infrastructure.persistence.SessionRecordRepository;
import com.sparkage.timebeam.presentation.dto.SessionRecordDto;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

class SessionServiceTest {
    private final SessionRecordRepository repo = Mockito.mock(SessionRecordRepository.class);
    private final SessionRecordMapper mapper = Mappers.getMapper(SessionRecordMapper.class);
    private final SessionService svc = new SessionService(repo, mapper);

    @Test
    void create_and_list() {
        var dto = new SessionRecordDto(null, UUID.randomUUID(), Instant.now(), 1500, "WORK");
        when(repo.save(any(SessionRecord.class))).thenAnswer(i -> i.getArgument(0));
        when(repo.findByUserIdOrderByStartedAtDesc(dto.getUserId())).thenReturn(List.of(mapper.toEntity(dto)));

        var created = svc.create(dto);
        assertNotNull(created.getId());

        var list = svc.listForUser(dto.getUserId());
        assertEquals(1, list.size());
    }
}
