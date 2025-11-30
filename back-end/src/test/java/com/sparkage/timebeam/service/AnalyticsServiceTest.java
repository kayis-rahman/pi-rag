package com.sparkage.timebeam.service;

import com.sparkage.timebeam.dto.SessionRecordDto;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.ZoneId;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class AnalyticsServiceTest {
    private final AnalyticsService svc = new AnalyticsService();

    @Test
    void last7DaysTotals_returnsZeroForEmpty() {
        var res = svc.last7DaysTotals(List.of(), ZoneId.of("UTC"));
        assertEquals(7, res.size());
        res.forEach(d -> assertEquals(0, d.totalMinutes()));
    }

    @Test
    void productiveStreak_countsConsecutiveDays() {
        var now = Instant.now();
        var r1 = new SessionRecordDto(null, null, now.minusSeconds(3600*24), 1500, "WORK");
        var r2 = new SessionRecordDto(null, null, now, 1500, "WORK");
        var streak = svc.productiveStreak(List.of(r1, r2), ZoneId.of("UTC"));
        assertTrue(streak >= 1);
    }
}

