package com.sparkage.timebeam.application.service;

import com.sparkage.timebeam.presentation.dto.AnalyticsDashboardResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AnalyticsServiceTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private AnalyticsService analyticsService;

    private UUID testUserId;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();
    }

    @Test
    void getDailyTotals_shouldReturnDailyData() {
        // Arrange
        String expectedSql = "SELECT work_date as date, SUM(duration_seconds / 60) as total_minutes, COUNT(*) as session_count FROM (SELECT DATE(sr.started_at AT TIME ZONE ?) as work_date, sr.duration_seconds FROM session_records sr WHERE sr.user_id = ?::uuid AND sr.kind = 'WORK' AND sr.started_at >= ?::timestamptz AND sr.started_at < ?::timestamptz) daily_work GROUP BY work_date ORDER BY work_date ASC";

        List<Map<String, Object>> mockResults = List.of(
            Map.of("date", "2025-04-12", "total_minutes", 120, "session_count", 3),
            Map.of("date", "2025-04-11", "total_minutes", 90, "session_count", 2)
        );

        when(jdbcTemplate.queryForList(anyString(), any(Object[].class)))
            .thenReturn(mockResults);

        // Act
        Map<String, Object> result = analyticsService.getDailyTotals(testUserId, 7, "UTC");

        // Assert
        assertNotNull(result);
        assertEquals(7, result.get("period"));
        assertEquals("UTC", result.get("timezone"));
        assertEquals("minutes", result.get("unit"));

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> data = (List<Map<String, Object>>) result.get("data");
        assertNotNull(data);
        assertEquals(2, data.size());

        verify(jdbcTemplate, times(1)).queryForList(anyString(), any(Object[].class));
    }

    @Test
    void getProductiveStreak_shouldReturnStreakValue() {
        // Arrange
        when(jdbcTemplate.queryForObject(anyString(), eq(Integer.class), any(Object[].class)))
            .thenReturn(5);

        // Act
        int result = analyticsService.getProductiveStreak(testUserId, "UTC");

        // Assert
        assertEquals(5, result);

        verify(jdbcTemplate, times(1)).queryForObject(anyString(), eq(Integer.class), any(Object[].class));
    }

    @Test
    void getProductiveStreak_shouldReturnZeroWhenNull() {
        // Arrange
        when(jdbcTemplate.queryForObject(anyString(), eq(Integer.class), any(Object[].class)))
            .thenReturn(null);

        // Act
        int result = analyticsService.getProductiveStreak(testUserId, "UTC");

        // Assert
        assertEquals(0, result);

        verify(jdbcTemplate, times(1)).queryForObject(anyString(), eq(Integer.class), any(Object[].class));
    }

    @Test
    void getTopProductiveWindow_shouldReturnWindowData() {
        // Arrange
        List<Map<String, Object>> mockResults = List.of(
            Map.of("start_hour", 9, "end_hour", 11, "total_sessions", 15)
        );

        when(jdbcTemplate.queryForList(anyString(), any(Object[].class)))
            .thenReturn(mockResults);

        // Act
        Map<String, Object> result = analyticsService.getTopProductiveWindow(testUserId, "week", 2, "UTC");

        // Assert
        assertNotNull(result);
        assertEquals(9, result.get("start_hour"));
        assertEquals(11, result.get("end_hour"));
        assertEquals(15, result.get("total_sessions"));
        assertEquals("UTC", result.get("timezone"));
        assertEquals("week", result.get("time_range"));
        assertEquals(2, result.get("window_hours"));

        verify(jdbcTemplate, times(1)).queryForList(anyString(), any(Object[].class));
    }

    @Test
    void getTopProductiveWindow_shouldReturnDefaultWhenEmpty() {
        // Arrange
        when(jdbcTemplate.queryForList(anyString(), any(Object[].class)))
            .thenReturn(List.of());

        // Act
        Map<String, Object> result = analyticsService.getTopProductiveWindow(testUserId, "week", 2, "UTC");

        // Assert
        assertNotNull(result);
        assertEquals(9, result.get("start_hour"));
        assertEquals(11, result.get("end_hour"));
        assertEquals(0, result.get("total_sessions"));
        assertEquals("UTC", result.get("timezone"));
        assertEquals("week", result.get("time_range"));
        assertEquals(2, result.get("window_hours"));

        verify(jdbcTemplate, times(1)).queryForList(anyString(), any(Object[].class));
    }

    @Test
    void getBreakdown_shouldReturnBreakdownData() {
        // Arrange
        List<Map<String, Object>> mockResults = List.of(
            Map.of("breakdown_label", "Mon", "work_session_count", 5, "day_count", 1, "total_minutes", 300, "average_minutes_per_day", 300.0),
            Map.of("breakdown_label", "Tue", "work_session_count", 3, "day_count", 1, "total_minutes", 180, "average_minutes_per_day", 180.0)
        );

        when(jdbcTemplate.queryForList(anyString(), any(Object[].class)))
            .thenReturn(mockResults);

        // Act
        Map<String, Object> result = analyticsService.getBreakdown(testUserId, "week", "weekday", "UTC");

        // Assert
        assertNotNull(result);
        assertEquals("weekday", result.get("breakdown_type"));
        assertEquals("week", result.get("time_range"));
        assertEquals("UTC", result.get("timezone"));

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> data = (List<Map<String, Object>>) result.get("data");
        assertNotNull(data);
        assertEquals(2, data.size());

        verify(jdbcTemplate, times(1)).queryForList(anyString(), any(Object[].class));
    }

    @Test
    void getBreakdown_shouldThrowExceptionForInvalidType() {
        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> {
            analyticsService.getBreakdown(testUserId, "week", "invalid", "UTC");
        });

        verifyNoInteractions(jdbcTemplate);
    }

    @Test
    void getSessions_shouldReturnSessionData() {
        // Arrange
        List<Map<String, Object>> mockSessions = List.of(
            Map.of("id", UUID.randomUUID().toString(), "user_id", testUserId.toString(), "started_at", Instant.now().toString(), "duration_seconds", 1500, "kind", "WORK"),
            Map.of("id", UUID.randomUUID().toString(), "user_id", testUserId.toString(), "started_at", Instant.now().minus(1, ChronoUnit.HOURS).toString(), "duration_seconds", 1200, "kind", "BREAK")
        );

        when(jdbcTemplate.queryForList(anyString(), any(Object[].class)))
            .thenReturn(mockSessions);
        when(jdbcTemplate.queryForObject(anyString(), eq(Integer.class), any(Object[].class)))
            .thenReturn(2);

        // Act
        Map<String, Object> result = analyticsService.getSessions(testUserId, "week", Optional.empty(), 0, 10);

        // Assert
        assertNotNull(result);
        assertEquals(2, ((Map<?, ?>) result.get("pagination")).get("total"));
        assertEquals(1, ((Map<?, ?>) result.get("pagination")).get("totalPages"));
        assertEquals("week", result.get("time_range"));
        assertEquals("all", result.get("kind_filter"));

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> data = (List<Map<String, Object>>) result.get("data");
        assertNotNull(data);
        assertEquals(2, data.size());

        verify(jdbcTemplate, times(1)).queryForList(anyString(), any(Object[].class));
        verify(jdbcTemplate, times(1)).queryForObject(anyString(), eq(Integer.class), any(Object[].class));
    }

    @Test
    void getDashboardMetrics_shouldReturnCompleteDashboard() {
        // Arrange
        // Mock daily totals
        List<Map<String, Object>> dailyTotalsData = List.of(
            Map.of("date", "2025-04-12", "total_minutes", 120, "session_count", 3),
            Map.of("date", "2025-04-11", "total_minutes", 90, "session_count", 2)
        );

        // Mock streak
        when(jdbcTemplate.queryForObject(anyString(), eq(Integer.class), any(Object[].class)))
            .thenReturn(3);

        // Mock productive window
        List<Map<String, Object>> productiveWindowData = List.of(
            Map.of("start_hour", 10, "end_hour", 12, "total_sessions", 8)
        );

        // Mock breakdown
        List<Map<String, Object>> breakdownData = List.of(
            Map.of("breakdown_label", "Mon", "work_session_count", 5, "day_count", 1, "total_minutes", 300, "average_minutes_per_day", 300.0),
            Map.of("breakdown_label", "Tue", "work_session_count", 3, "day_count", 1, "total_minutes", 180, "average_minutes_per_day", 180.0)
        );

        // Setup mocks for different SQL queries
        when(jdbcTemplate.queryForList(anyString(), any(Object[].class)))
            .thenReturn(dailyTotalsData) // First call - daily totals
            .thenReturn(productiveWindowData) // Second call - productive window
            .thenReturn(breakdownData); // Third call - breakdown

        // Act
        AnalyticsDashboardResponse result = analyticsService.getDashboardMetrics(testUserId, "week", "weekday");

        // Assert
        assertNotNull(result);
        assertNotNull(result.getDailyTotals());
        assertNotNull(result.getStreak());
        assertNotNull(result.getProductiveWindow());
        assertNotNull(result.getBreakdown());
        assertNotNull(result.getMetadata());

        // Verify daily totals
        assertEquals(2, result.getDailyTotals().getData().size());
        assertEquals(7, result.getDailyTotals().getPeriod());
        assertEquals("UTC", result.getDailyTotals().getTimezone());
        assertEquals("minutes", result.getDailyTotals().getUnit());

        // Verify streak
        assertEquals(3, result.getStreak().getCurrent());
        assertEquals("days", result.getStreak().getUnit());

        // Verify productive window
        assertEquals(10, result.getProductiveWindow().getStartHour());
        assertEquals(12, result.getProductiveWindow().getEndHour());
        assertEquals(8, result.getProductiveWindow().getTotalSessions());
        assertEquals("UTC", result.getProductiveWindow().getTimezone());
        assertEquals("week", result.getProductiveWindow().getTimeRange());
        assertEquals(2, result.getProductiveWindow().getWindowHours());

        // Verify breakdown
        assertEquals(2, result.getBreakdown().getData().size());
        assertEquals("weekday", result.getBreakdown().getBreakdownType());
        assertEquals("week", result.getBreakdown().getTimeRange());
        assertEquals("UTC", result.getBreakdown().getTimezone());

        // Verify metadata
        assertNotNull(result.getMetadata().getRequestedAt());
        assertEquals("week", result.getMetadata().getTimeRange());
        assertEquals("weekday", result.getMetadata().getBreakdownType());
        assertEquals("UTC", result.getMetadata().getTimezone());

        // Verify all JDBC calls were made
        verify(jdbcTemplate, times(3)).queryForList(anyString(), any(Object[].class));
        verify(jdbcTemplate, times(1)).queryForObject(anyString(), eq(Integer.class), any(Object[].class));
    }
}
