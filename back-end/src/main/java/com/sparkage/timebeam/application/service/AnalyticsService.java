package com.sparkage.timebeam.application.service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import com.sparkage.timebeam.presentation.dto.AnalyticsDashboardResponse;

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
     * Optimized: Pre-calculated date ranges, single timezone conversion.
     */
    public Map<String, Object> getDailyTotals(UUID userId, int days, String timezone) {
        log.debug("getDailyTotals userId={}, days={}, timezone={}", userId, days, timezone);

        // Pre-calculate date range for better performance
        Instant now = Instant.now();
        Instant startInstant = now.minus(days, ChronoUnit.DAYS);

        String sql = """
            SELECT
                work_date as date,
                SUM(duration_seconds / 60) as total_minutes,
                COUNT(*) as session_count
            FROM (
                SELECT
                    DATE(sr.started_at AT TIME ZONE ?) as work_date,
                    sr.duration_seconds
                FROM session_records sr
                WHERE sr.user_id = ?::uuid
                  AND sr.kind = 'WORK'
                  AND sr.started_at >= ?::timestamptz
                  AND sr.started_at < ?::timestamptz
            ) daily_work
            GROUP BY work_date
            ORDER BY work_date ASC
            """;

        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql,
            timezone, userId.toString(), startInstant.toString(), now.toString());

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
     * Optimized: Fixed logic to properly calculate consecutive days.
     */
    public int getProductiveStreak(UUID userId, String timezone) {
        log.debug("getProductiveStreak userId={}, timezone={}", userId, timezone);

        String sql = """
            WITH productive_days AS (
                SELECT DISTINCT DATE(sr.started_at AT TIME ZONE ?) as work_date
                FROM session_records sr
                WHERE sr.user_id = ?::uuid
                  AND sr.kind = 'WORK'
                  AND sr.started_at <= CURRENT_TIMESTAMP AT TIME ZONE ?
                ORDER BY work_date DESC
            ),
            ranked_days AS (
                SELECT work_date,
                       ROW_NUMBER() OVER (ORDER BY work_date DESC) as day_rank
                FROM productive_days
            )
            SELECT COUNT(*) as current_streak
            FROM ranked_days
            WHERE work_date = (DATE(CURRENT_TIMESTAMP AT TIME ZONE ?) - (day_rank - 1) * INTERVAL '1 day')
            """;

        Integer streak = jdbcTemplate.queryForObject(sql, Integer.class,
            timezone, userId.toString(), timezone, timezone);

        log.info("getProductiveStreak userId={} streak={} days", userId, streak);
        return streak != null ? streak : 0;
    }

    // ============ Top Productive Window ============

    /**
     * Find the N-hour window with the most WORK sessions.
     * Optimized: Pre-calculated date ranges, efficient window calculation.
     */
    public Map<String, Object> getTopProductiveWindow(UUID userId, String timeRange,
                                                       int windowHours, String timezone) {
        log.debug("getTopProductiveWindow userId={}, timeRange={}, windowHours={}",
                  userId, timeRange, windowHours);

        // Pre-calculate date range
        Instant now = Instant.now();
        Instant startInstant = getStartInstantForRange(timeRange, now);

        String sql = """
            WITH hourly_counts AS (
                SELECT
                    EXTRACT(HOUR FROM sr.started_at AT TIME ZONE ?) as hour,
                    COUNT(*) as session_count
                FROM session_records sr
                WHERE sr.user_id = ?::uuid
                  AND sr.kind = 'WORK'
                  AND sr.started_at >= ?::timestamptz
                  AND sr.started_at < ?::timestamptz
                GROUP BY 1
            ),
            window_sums AS (
                SELECT
                    h1.hour as start_hour,
                    SUM(h2.session_count) as total_sessions
                FROM hourly_counts h1
                JOIN hourly_counts h2 ON h2.hour >= h1.hour AND h2.hour < h1.hour + ?
                GROUP BY h1.hour
                ORDER BY total_sessions DESC
                LIMIT 1
            )
            SELECT
                start_hour,
                (start_hour + ?) as end_hour,
                total_sessions
            FROM window_sums
            """;

        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql,
            timezone, userId.toString(), startInstant.toString(), now.toString(),
            windowHours, windowHours);

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

        // Pre-calculate date range
        Instant now = Instant.now();
        Instant startInstant = getStartInstantForRange(timeRange, now);
        String formatString;

        if ("weekday".equals(breakdownType)) {
            formatString = "Day";
        } else {
            formatString = "YYYY-MM";
        }

        String sql = String.format("""
            SELECT
                breakdown_label,
                COUNT(*) as work_session_count,
                COUNT(DISTINCT work_date) as day_count,
                COALESCE(SUM(duration_seconds / 60), 0) as total_minutes,
                ROUND(COALESCE(SUM(duration_seconds / 60)::NUMERIC /
                       NULLIF(COUNT(DISTINCT work_date), 0), 0), 2) as average_minutes_per_day
            FROM (
                SELECT
                    TO_CHAR(sr.started_at AT TIME ZONE ?, '%s') as breakdown_label,
                    DATE(sr.started_at AT TIME ZONE ?) as work_date,
                    sr.duration_seconds
                FROM session_records sr
                WHERE sr.user_id = ?::uuid
                  AND sr.kind = 'WORK'
                  AND sr.started_at >= ?::timestamptz
                  AND sr.started_at < ?::timestamptz
            ) breakdown_data
            GROUP BY breakdown_label
            ORDER BY breakdown_label ASC
            """, formatString, formatString);

        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql,
            timezone, timezone, userId.toString(),
            startInstant.toString(), now.toString());

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

        // Pre-calculate date range for better performance and security
        Instant now = Instant.now();
        Instant startInstant = getStartInstantForRange(timeRange, now);

        int offset = page * pageSize;

        String sql;
        String countSql;

        if (sessionKind.isPresent()) {
            sql = """
                SELECT
                    sr.id,
                    sr.user_id,
                    sr.started_at,
                    sr.duration_seconds,
                    sr.kind,
                    sr.created_at
                FROM session_records sr
                WHERE sr.user_id = ?
                  AND sr.started_at >= ?
                  AND sr.started_at < ?
                  AND sr.kind = ?
                ORDER BY sr.started_at DESC
                LIMIT ? OFFSET ?
                """;

            countSql = """
                SELECT COUNT(*) FROM session_records sr
                WHERE sr.user_id = ?
                  AND sr.started_at >= ?
                  AND sr.started_at < ?
                  AND sr.kind = ?
                """;
        } else {
            sql = """
                SELECT
                    sr.id,
                    sr.user_id,
                    sr.started_at,
                    sr.duration_seconds,
                    sr.kind,
                    sr.created_at
                FROM session_records sr
                WHERE sr.user_id = ?
                  AND sr.started_at >= ?
                  AND sr.started_at < ?
                ORDER BY sr.started_at DESC
                LIMIT ? OFFSET ?
                """;

            countSql = """
                SELECT COUNT(*) FROM session_records sr
                WHERE sr.user_id = ?
                  AND sr.started_at >= ?
                  AND sr.started_at < ?
                """;
        }

        // Build parameter list
        List<Object> params = new ArrayList<>();
        params.add(userId);
        params.add(startInstant);
        params.add(now);
        sessionKind.ifPresent(k -> params.add(k));
        params.add(pageSize);
        params.add(offset);

        List<Object> countParams = new ArrayList<>();
        countParams.add(userId);
        countParams.add(startInstant);
        countParams.add(now);
        sessionKind.ifPresent(k -> countParams.add(k));

        List<Map<String, Object>> sessions = jdbcTemplate.queryForList(sql, params.toArray());
        Integer totalCount = jdbcTemplate.queryForObject(countSql, Integer.class, countParams.toArray());

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

    // ============ Weekly Analytics ============

    /**
     * Get comprehensive weekly analytics dashboard data.
     * Includes chart data, summary stats, and recent session history.
     */
    public Map<String, Object> getWeeklyAnalytics(UUID userId) {
        log.debug("getWeeklyAnalytics userId={}", userId);

        String timezone = "UTC";

        // Get weekly chart data
        Map<String, Object> dailyTotalsRaw = getDailyTotals(userId, 7, timezone);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> rawData = (List<Map<String, Object>>) dailyTotalsRaw.get("data");
        List<Map<String, Object>> weeklyData = transformToWeeklyFormat(rawData);

        // Get today's focus time
        Map<String, Object> todayFocus = getTodayFocus(userId, timezone);

        // Get weekly total
        Map<String, Object> weeklyTotal = getWeeklyTotal(userId, timezone);

        // Get best streak
        int bestStreak = getProductiveStreak(userId, timezone);

        // Get recent session history
        List<Map<String, Object>> recentSessions = getRecentSessions(userId, 20);

        log.info("getWeeklyAnalytics returned {} days of weekly data, {} recent sessions",
                 weeklyData.size(), recentSessions.size());

        return Map.of(
            "weekly_chart", Map.of(
                "data", weeklyData,
                "period", 7,
                "timezone", timezone,
                "unit", "minutes"
            ),
            "today_focus", todayFocus,
            "weekly_total", weeklyTotal,
            "best_streak", Map.of(
                "days", bestStreak,
                "unit", "days"
            ),
            "recent_sessions", recentSessions,
            "requested_at", System.currentTimeMillis()
        );
    }

    /**
     * Transform daily data to weekly format (Mon-Sun).
     */
    private List<Map<String, Object>> transformToWeeklyFormat(List<Map<String, Object>> dailyData) {
        List<Map<String, Object>> weeklyData = new ArrayList<>();

        // Create entries for last 7 days (today back to 6 days ago)
        Instant now = Instant.now();
        for (int i = 6; i >= 0; i--) {
            Instant targetDate = now.minus(i, ChronoUnit.DAYS);
            String dateString = targetDate.toString().substring(0, 10); // YYYY-MM-DD format

            // Find matching data or create zero entry
            Map<String, Object> entry = dailyData.stream()
                .filter(d -> dateString.equals(d.get("date")))
                .findFirst()
                .orElse(Map.of(
                    "date", dateString,
                    "total_minutes", 0,
                    "session_count", 0
                ));

            // Add weekday information
            Map<String, Object> weeklyEntry = new HashMap<>(entry);
            weeklyEntry.put("weekday", getWeekdayName(targetDate));
            weeklyEntry.put("is_today", i == 0);

            weeklyData.add(weeklyEntry);
        }

        return weeklyData;
    }

    /**
     * Get weekday name from Instant.
     */
    private String getWeekdayName(Instant instant) {
        java.time.LocalDate date = instant.atZone(java.time.ZoneId.of("UTC")).toLocalDate();
        java.time.DayOfWeek dayOfWeek = date.getDayOfWeek();

        return switch (dayOfWeek) {
            case MONDAY -> "Mon";
            case TUESDAY -> "Tue";
            case WEDNESDAY -> "Wed";
            case THURSDAY -> "Thu";
            case FRIDAY -> "Fri";
            case SATURDAY -> "Sat";
            case SUNDAY -> "Sun";
        };
    }

    /**
     * Get today's focus time summary.
     */
    private Map<String, Object> getTodayFocus(UUID userId, String timezone) {
        String sql = """
            SELECT
                COALESCE(SUM(duration_seconds / 60), 0) as minutes,
                COUNT(*) as sessions
            FROM session_records sr
            WHERE sr.user_id = ?::uuid
              AND sr.kind = 'WORK'
              AND DATE(sr.started_at AT TIME ZONE ?) = CURRENT_DATE AT TIME ZONE ?
            """;

        Map<String, Object> result = jdbcTemplate.queryForMap(sql,
            userId.toString(), timezone, timezone);

        return Map.of(
            "minutes", ((Number) result.get("minutes")).intValue(),
            "sessions", ((Number) result.get("sessions")).intValue()
        );
    }

    /**
     * Get weekly total summary.
     */
    private Map<String, Object> getWeeklyTotal(UUID userId, String timezone) {
        String sql = """
            SELECT
                COALESCE(SUM(duration_seconds / 60), 0) as minutes,
                COUNT(*) as sessions
            FROM session_records sr
            WHERE sr.user_id = ?::uuid
              AND sr.kind = 'WORK'
              AND sr.started_at >= (CURRENT_TIMESTAMP AT TIME ZONE ? - INTERVAL '7 days')
              AND sr.started_at < CURRENT_TIMESTAMP AT TIME ZONE ?
            """;

        Map<String, Object> result = jdbcTemplate.queryForMap(sql,
            userId.toString(), timezone, timezone);

        return Map.of(
            "minutes", ((Number) result.get("minutes")).intValue(),
            "sessions", ((Number) result.get("sessions")).intValue()
        );
    }

    /**
     * Get recent session history.
     */
    private List<Map<String, Object>> getRecentSessions(UUID userId, int limit) {
        String sql = """
            SELECT
                sr.kind as type,
                (sr.duration_seconds / 60) as duration_minutes,
                sr.started_at as timestamp
            FROM session_records sr
            WHERE sr.user_id = ?::uuid
            ORDER BY sr.started_at DESC
            LIMIT ?
            """;

        return jdbcTemplate.queryForList(sql, userId.toString(), limit);
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

    private Instant getStartInstantForRange(String timeRange, Instant now) {
        return switch (timeRange) {
            case "week" -> now.minus(7, ChronoUnit.DAYS);
            case "month" -> now.minus(30, ChronoUnit.DAYS);
            case "quarter" -> now.minus(90, ChronoUnit.DAYS);
            case "year" -> now.minus(365, ChronoUnit.DAYS);
            case "all" -> now.minus(10000, ChronoUnit.DAYS);
            default -> now.minus(7, ChronoUnit.DAYS);
        };
    }
}
