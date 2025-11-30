package com.sparkage.timebeam.service;

import com.sparkage.timebeam.dto.AnalyticsDashboardResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.*;

/**
 * High-performance Analytics Service using direct SQL queries.
 * All operations are database-optimized with minimal in-memory processing.
 */
@Service
public class AnalyticsService {

    private static final Logger log = LoggerFactory.getLogger(AnalyticsService.class);
    private final JdbcTemplate jdbcTemplate;

    public AnalyticsService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // ============ Daily Totals ============

    /**
     * Get daily focus totals for the last N days.
     * SQL-optimized query that groups by date and sums WORK sessions only.
     */
    public Map<String, Object> getDailyTotals(UUID userId, int days, String timezone) {
        log.debug("getDailyTotals userId={}, days={}, timezone={}", userId, days, timezone);

        String sql = """
            SELECT 
                DATE(sr.started_at AT TIME ZONE %s) as date,
                COALESCE(SUM(CASE WHEN sr.kind = 'WORK' THEN sr.duration_seconds / 60 ELSE 0 END), 0) as total_minutes,
                COUNT(CASE WHEN sr.kind = 'WORK' THEN 1 END) as session_count
            FROM session_records sr
            WHERE sr.user_id = ?::uuid
              AND sr.started_at >= (NOW() - INTERVAL '%d days')
            GROUP BY DATE(sr.started_at AT TIME ZONE %s)
            ORDER BY date ASC
            """.formatted("'" + timezone + "'", days, "'" + timezone + "'");

        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, userId.toString());

        log.info("getDailyTotals returned {} days of data", results.size());
        return Map.of(
            "data", results,
            "period", days,
            "timezone", timezone,
            "unit", "minutes"
        );
    }

    // ============ Productive Streak ============

    /**
     * Get the current productive streak (consecutive days with at least one WORK session).
     * Uses a window function to identify gaps in productivity.
     */
    public int getProductiveStreak(UUID userId, String timezone) {
        log.debug("getProductiveStreak userId={}, timezone={}", userId, timezone);

        String sql = """
            WITH productive_days AS (
                SELECT DISTINCT DATE(sr.started_at AT TIME ZONE %s) as work_date
                FROM session_records sr
                WHERE sr.user_id = ?::uuid
                  AND sr.kind = 'WORK'
                ORDER BY work_date DESC
            ),
            streaks AS (
                SELECT 
                    work_date,
                    ROW_NUMBER() OVER (ORDER BY work_date DESC) as rn
                FROM productive_days
            )
            SELECT COUNT(*) as streak
            FROM streaks
            WHERE work_date >= CURRENT_DATE AT TIME ZONE %s - (rn - 1) * INTERVAL '1 day'
            """.formatted("'" + timezone + "'", "'" + timezone + "'");

        Integer streak = jdbcTemplate.queryForObject(sql, Integer.class, userId.toString());

        log.info("getProductiveStreak userId={} streak={} days", userId, streak);
        return streak != null ? streak : 0;
    }

    // ============ Top Productive Window ============

    /**
     * Find the N-hour window with the most WORK sessions.
     * Uses sliding window aggregation optimized in SQL.
     */
    public Map<String, Object> getTopProductiveWindow(UUID userId, String timeRange,
                                                       int windowHours, String timezone) {
        log.debug("getTopProductiveWindow userId={}, timeRange={}, windowHours={}",
                  userId, timeRange, windowHours);

        String dateFilter = getDateFilter("sr.started_at", timeRange, timezone);

        String sql = """
            WITH hourly_counts AS (
                SELECT 
                    EXTRACT(HOUR FROM sr.started_at AT TIME ZONE %s)::INT as hour,
                    COUNT(*) as session_count
                FROM session_records sr
                WHERE sr.user_id = ?::uuid
                  AND sr.kind = 'WORK'
                  AND %s
                GROUP BY EXTRACT(HOUR FROM sr.started_at AT TIME ZONE %s)::INT
            ),
            windows AS (
                SELECT 
                    h1.hour as start_hour,
                    LEAST(23, h1.hour + %d) as end_hour,
                    COALESCE(SUM(h2.session_count), 0) as total_sessions
                FROM hourly_counts h1
                LEFT JOIN hourly_counts h2 
                    ON h2.hour >= h1.hour AND h2.hour < h1.hour + %d
                GROUP BY h1.hour
            )
            SELECT start_hour, end_hour, total_sessions
            FROM windows
            ORDER BY total_sessions DESC
            LIMIT 1
            """.formatted("'" + timezone + "'", dateFilter, "'" + timezone + "'",
                          windowHours, windowHours);

        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, userId.toString());

        Map<String, Object> result;
        if (results.isEmpty()) {
            // No work sessions found, return default values
            result = new HashMap<>();
            result.put("start_hour", 9);
            result.put("end_hour", 11);
            result.put("total_sessions", 0);
        } else {
            result = new HashMap<>(results.get(0));
        }

        result.put("timezone", timezone);
        result.put("time_range", timeRange);
        result.put("window_hours", windowHours);

        log.info("getTopProductiveWindow start={}, end={}, sessions={}",
                 result.get("start_hour"), result.get("end_hour"), result.get("total_sessions"));

        return result;
    }

    // ============ Breakdown (Weekday or Monthly) ============

    /**
     * Get breakdown by weekday or month.
     * Single API supporting multiple breakdown types.
     */
    public Map<String, Object> getBreakdown(UUID userId, String timeRange,
                                             String breakdownType, String timezone) {
        log.debug("getBreakdown userId={}, timeRange={}, type={}", userId, timeRange, breakdownType);

        if (!breakdownType.equals("weekday") && !breakdownType.equals("month")) {
            throw new IllegalArgumentException("breakdown type must be 'weekday' or 'month'");
        }

        String dateFilter = getDateFilter("sr.started_at", timeRange, timezone);
        String groupBy;
        String label;

        if ("weekday".equals(breakdownType)) {
            groupBy = "TO_CHAR(sr.started_at AT TIME ZONE '" + timezone + "', 'Day')";
            label = "day_of_week";
        } else {
            groupBy = "TO_CHAR(sr.started_at AT TIME ZONE '" + timezone + "', 'YYYY-MM')";
            label = "month";
        }

        String sql = """
            SELECT 
                %s as breakdown_label,
                COUNT(CASE WHEN sr.kind = 'WORK' THEN 1 END) as work_session_count,
                COUNT(DISTINCT DATE(sr.started_at AT TIME ZONE %s)) as day_count,
                COALESCE(SUM(CASE WHEN sr.kind = 'WORK' THEN sr.duration_seconds / 60 ELSE 0 END), 0) as total_minutes,
                ROUND(COALESCE(SUM(CASE WHEN sr.kind = 'WORK' THEN sr.duration_seconds / 60 ELSE 0 END)::NUMERIC / 
                       NULLIF(COUNT(DISTINCT DATE(sr.started_at AT TIME ZONE %s)), 0), 0), 2) as average_minutes_per_day
            FROM session_records sr
            WHERE sr.user_id = ?::uuid
              AND sr.kind = 'WORK'
              AND %s
            GROUP BY %s
            ORDER BY breakdown_label ASC
            """.formatted(groupBy, "'" + timezone + "'", "'" + timezone + "'",
                          dateFilter, groupBy);

        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, userId.toString());

        log.info("getBreakdown returned {} breakdown entries", results.size());

        return Map.of(
            "data", results,
            "breakdown_type", breakdownType,
            "time_range", timeRange,
            "timezone", timezone
        );
    }

    // ============ Sessions ============

    /**
     * Get paginated session records with optional filtering.
     * Supports pagination and kind filtering.
     */
    public Map<String, Object> getSessions(UUID userId, String timeRange,
                                            Optional<String> sessionKind, int page, int pageSize) {
        log.debug("getSessions userId={}, timeRange={}, page={}, pageSize={}",
                  userId, timeRange, page, pageSize);

        String dateFilter = getDateFilter("sr.started_at", timeRange, "UTC");
        String kindFilter = sessionKind.map(k -> " AND sr.kind = '" + k + "'").orElse("");

        int offset = page * pageSize;

        String sql = """
            SELECT 
                sr.id,
                sr.user_id,
                sr.started_at AT TIME ZONE 'UTC' as started_at,
                sr.duration_seconds,
                sr.kind,
                sr.created_at
            FROM session_records sr
            WHERE sr.user_id = ?::uuid
              AND %s
              %s
            ORDER BY sr.started_at DESC
            LIMIT %d OFFSET %d
            """.formatted(dateFilter, kindFilter, pageSize, offset);

        String countSql = """
            SELECT COUNT(*) FROM session_records sr
            WHERE sr.user_id = ?::uuid
              AND %s
              %s
            """.formatted(dateFilter, kindFilter);

        List<Map<String, Object>> sessions = jdbcTemplate.queryForList(sql, userId.toString());
        Integer totalCount = jdbcTemplate.queryForObject(countSql, Integer.class, userId.toString());

        log.info("getSessions returned {} sessions (total: {})", sessions.size(), totalCount);

        return Map.of(
            "data", sessions,
            "pagination", Map.of(
                "page", page,
                "pageSize", pageSize,
                "total", totalCount != null ? totalCount : 0,
                "totalPages", (totalCount != null ? (totalCount + pageSize - 1) / pageSize : 0)
            ),
            "time_range", timeRange,
            "kind_filter", sessionKind.orElse("all")
        );
    }

    // ============ Dashboard (Composite) ============

    /**
     * Get all dashboard metrics in a structured response.
     * Returns daily totals, streak, top window, and breakdown.
     */
    public AnalyticsDashboardResponse getDashboardMetrics(UUID userId, String timeRange,
                                                          String breakdownType) {
        log.debug("getDashboardMetrics userId={}, timeRange={}, breakdown={}",
                  userId, timeRange, breakdownType);

        String timezone = "UTC";

        // Get raw data from existing methods
        Map<String, Object> dailyTotalsRaw = getDailyTotals(userId, getDaysFromRange(timeRange), timezone);
        int streakValue = getProductiveStreak(userId, timezone);
        Map<String, Object> productiveWindowRaw = getTopProductiveWindow(userId, timeRange, 2, timezone);
        Map<String, Object> breakdownRaw = getBreakdown(userId, timeRange, breakdownType, timezone);

        // Debug logging
        log.info("DEBUG: Daily totals data size: {}", ((List<?>) dailyTotalsRaw.get("data")).size());
        log.info("DEBUG: Streak value: {}", streakValue);
        log.info("DEBUG: Productive window: {} sessions", productiveWindowRaw.get("total_sessions"));
        log.info("DEBUG: Breakdown data size: {}", ((List<?>) breakdownRaw.get("data")).size());

        // Convert to structured DTO
        AnalyticsDashboardResponse.DailyTotalsData dailyTotals = new AnalyticsDashboardResponse.DailyTotalsData(
            (List<Map<String, Object>>) dailyTotalsRaw.get("data"),
            (Integer) dailyTotalsRaw.get("period"),
            (String) dailyTotalsRaw.get("timezone"),
            (String) dailyTotalsRaw.get("unit")
        );

        AnalyticsDashboardResponse.StreakData streak = new AnalyticsDashboardResponse.StreakData(
            streakValue, "days"
        );

        AnalyticsDashboardResponse.ProductiveWindowData productiveWindow = new AnalyticsDashboardResponse.ProductiveWindowData(
            ((Number) productiveWindowRaw.get("start_hour")).intValue(),
            ((Number) productiveWindowRaw.get("end_hour")).intValue(),
            ((Number) productiveWindowRaw.get("total_sessions")).intValue(),
            (String) productiveWindowRaw.get("timezone"),
            (String) productiveWindowRaw.get("time_range"),
            ((Number) productiveWindowRaw.get("window_hours")).intValue()
        );

        AnalyticsDashboardResponse.BreakdownData breakdown = new AnalyticsDashboardResponse.BreakdownData(
            (List<Map<String, Object>>) breakdownRaw.get("data"),
            (String) breakdownRaw.get("breakdown_type"),
            (String) breakdownRaw.get("time_range"),
            (String) breakdownRaw.get("timezone")
        );

        AnalyticsDashboardResponse.MetadataData metadata = new AnalyticsDashboardResponse.MetadataData(
            System.currentTimeMillis(),
            timeRange,
            breakdownType,
            timezone
        );

        return new AnalyticsDashboardResponse(dailyTotals, streak, productiveWindow, breakdown, metadata);
    }

    // ============ Helpers ============

    private String getDateFilter(String column, String timeRange, String timezone) {
        return switch (timeRange) {
            case "week" -> column + " >= CURRENT_DATE AT TIME ZONE '" + timezone + "' - INTERVAL '7 days'";
            case "month" -> column + " >= DATE_TRUNC('month', CURRENT_DATE AT TIME ZONE '" + timezone + "')";
            case "quarter" -> column + " >= DATE_TRUNC('quarter', CURRENT_DATE AT TIME ZONE '" + timezone + "')";
            case "year" -> column + " >= DATE_TRUNC('year', CURRENT_DATE AT TIME ZONE '" + timezone + "')";
            case "all" -> "1=1";
            default -> throw new IllegalArgumentException("Invalid time range: " + timeRange);
        };
    }

    private int getDaysFromRange(String timeRange) {
        return switch (timeRange) {
            case "week" -> 7;
            case "month" -> 30;
            case "quarter" -> 90;
            case "year" -> 365;
            case "all" -> 10000;
            default -> 7;
        };
    }
}
