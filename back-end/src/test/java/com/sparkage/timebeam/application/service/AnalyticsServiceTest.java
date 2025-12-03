package com.sparkage.timebeam.application.service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

class AnalyticsServiceTest {
    private final JdbcTemplate jdbcTemplate = Mockito.mock(JdbcTemplate.class);
    private final AnalyticsService svc = new AnalyticsService(jdbcTemplate);

    @Test
    void getDailyTotals_returnsZeroForEmpty() {
        UUID userId = UUID.randomUUID();

        // Mock empty result
        when(jdbcTemplate.queryForList(anyString(), any(), any(), any(), any()))
            .thenReturn(List.of());

        var result = svc.getDailyTotals(userId, 7, "UTC");

        assertEquals(7, result.get("period"));
        assertEquals("UTC", result.get("timezone"));
        assertEquals("minutes", result.get("unit"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> data = (List<Map<String, Object>>) result.get("data");
        assertTrue(data.isEmpty());
    }

    @Test
    void getProductiveStreak_returnsZeroForNoSessions() {
        UUID userId = UUID.randomUUID();

        // Mock query returning null (no streak)
        when(jdbcTemplate.queryForObject(anyString(), eq(Integer.class), any(), any(), any()))
            .thenReturn(null);

        int streak = svc.getProductiveStreak(userId, "UTC");
        assertEquals(0, streak);
    }

    @Test
    void getProductiveStreak_returnsStreakValue() {
        UUID userId = UUID.randomUUID();

        // Mock query returning streak of 3
        when(jdbcTemplate.queryForObject(anyString(), eq(Integer.class), any(), any(), any()))
            .thenReturn(3);

        int streak = svc.getProductiveStreak(userId, "UTC");
        assertEquals(3, streak);
    }
}
