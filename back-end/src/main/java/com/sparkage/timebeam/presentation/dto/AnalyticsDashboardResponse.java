package com.sparkage.timebeam.presentation.dto;

import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonProperty;

public class AnalyticsDashboardResponse {
    @JsonProperty("daily_totals")
    private DailyTotalsData dailyTotals;

    private StreakData streak;

    @JsonProperty("productive_window")
    private ProductiveWindowData productiveWindow;

    private BreakdownData breakdown;
    private MetadataData metadata;

    public AnalyticsDashboardResponse() {}

    public AnalyticsDashboardResponse(DailyTotalsData dailyTotals, StreakData streak,
                                    ProductiveWindowData productiveWindow, BreakdownData breakdown,
                                    MetadataData metadata) {
        this.dailyTotals = dailyTotals;
        this.streak = streak;
        this.productiveWindow = productiveWindow;
        this.breakdown = breakdown;
        this.metadata = metadata;
    }

    // Nested classes for structured data
    public static class DailyTotalsData {
        private List<Map<String, Object>> data;
        private int period;
        private String timezone;
        private String unit;

        public DailyTotalsData() {}

        public DailyTotalsData(List<Map<String, Object>> data, int period, String timezone, String unit) {
            this.data = data;
            this.period = period;
            this.timezone = timezone;
            this.unit = unit;
        }

        // Getters and setters
        public List<Map<String, Object>> getData() { return data; }
        public void setData(List<Map<String, Object>> data) { this.data = data; }

        public int getPeriod() { return period; }
        public void setPeriod(int period) { this.period = period; }

        public String getTimezone() { return timezone; }
        public void setTimezone(String timezone) { this.timezone = timezone; }

        public String getUnit() { return unit; }
        public void setUnit(String unit) { this.unit = unit; }
    }

    public static class StreakData {
        private int current;
        private String unit;

        public StreakData() {}

        public StreakData(int current, String unit) {
            this.current = current;
            this.unit = unit;
        }

        // Getters and setters
        public int getCurrent() { return current; }
        public void setCurrent(int current) { this.current = current; }

        public String getUnit() { return unit; }
        public void setUnit(String unit) { this.unit = unit; }
    }

    public static class ProductiveWindowData {
        @JsonProperty("start_hour")
        private int startHour;

        @JsonProperty("end_hour")
        private int endHour;

        @JsonProperty("total_sessions")
        private int totalSessions;

        private String timezone;

        @JsonProperty("time_range")
        private String timeRange;

        @JsonProperty("window_hours")
        private int windowHours;

        public ProductiveWindowData() {}

        public ProductiveWindowData(int startHour, int endHour, int totalSessions,
                                  String timezone, String timeRange, int windowHours) {
            this.startHour = startHour;
            this.endHour = endHour;
            this.totalSessions = totalSessions;
            this.timezone = timezone;
            this.timeRange = timeRange;
            this.windowHours = windowHours;
        }

        // Getters and setters
        public int getStartHour() { return startHour; }
        public void setStartHour(int startHour) { this.startHour = startHour; }

        public int getEndHour() { return endHour; }
        public void setEndHour(int endHour) { this.endHour = endHour; }

        public int getTotalSessions() { return totalSessions; }
        public void setTotalSessions(int totalSessions) { this.totalSessions = totalSessions; }

        public String getTimezone() { return timezone; }
        public void setTimezone(String timezone) { this.timezone = timezone; }

        public String getTimeRange() { return timeRange; }
        public void setTimeRange(String timeRange) { this.timeRange = timeRange; }

        public int getWindowHours() { return windowHours; }
        public void setWindowHours(int windowHours) { this.windowHours = windowHours; }
    }

    public static class BreakdownData {
        private List<Map<String, Object>> data;

        @JsonProperty("breakdown_type")
        private String breakdownType;

        @JsonProperty("time_range")
        private String timeRange;

        private String timezone;

        public BreakdownData() {}

        public BreakdownData(List<Map<String, Object>> data, String breakdownType,
                           String timeRange, String timezone) {
            this.data = data;
            this.breakdownType = breakdownType;
            this.timeRange = timeRange;
            this.timezone = timezone;
        }

        // Getters and setters
        public List<Map<String, Object>> getData() { return data; }
        public void setData(List<Map<String, Object>> data) { this.data = data; }

        public String getBreakdownType() { return breakdownType; }
        public void setBreakdownType(String breakdownType) { this.breakdownType = breakdownType; }

        public String getTimeRange() { return timeRange; }
        public void setTimeRange(String timeRange) { this.timeRange = timeRange; }

        public String getTimezone() { return timezone; }
        public void setTimezone(String timezone) { this.timezone = timezone; }
    }

    public static class MetadataData {
        @JsonProperty("requested_at")
        private long requestedAt;

        @JsonProperty("time_range")
        private String timeRange;

        @JsonProperty("breakdown_type")
        private String breakdownType;

        private String timezone;

        public MetadataData() {}

        public MetadataData(long requestedAt, String timeRange, String breakdownType, String timezone) {
            this.requestedAt = requestedAt;
            this.timeRange = timeRange;
            this.breakdownType = breakdownType;
            this.timezone = timezone;
        }

        // Getters and setters
        public long getRequestedAt() { return requestedAt; }
        public void setRequestedAt(long requestedAt) { this.requestedAt = requestedAt; }

        public String getTimeRange() { return timeRange; }
        public void setTimeRange(String timeRange) { this.timeRange = timeRange; }

        public String getBreakdownType() { return breakdownType; }
        public void setBreakdownType(String breakdownType) { this.breakdownType = breakdownType; }

        public String getTimezone() { return timezone; }
        public void setTimezone(String timezone) { this.timezone = timezone; }
    }

    // Getters and setters for main class
    public DailyTotalsData getDailyTotals() { return dailyTotals; }
    public void setDailyTotals(DailyTotalsData dailyTotals) { this.dailyTotals = dailyTotals; }

    public StreakData getStreak() { return streak; }
    public void setStreak(StreakData streak) { this.streak = streak; }

    public ProductiveWindowData getProductiveWindow() { return productiveWindow; }
    public void setProductiveWindow(ProductiveWindowData productiveWindow) { this.productiveWindow = productiveWindow; }

    public BreakdownData getBreakdown() { return breakdown; }
    public void setBreakdown(BreakdownData breakdown) { this.breakdown = breakdown; }

    public MetadataData getMetadata() { return metadata; }
    public void setMetadata(MetadataData metadata) { this.metadata = metadata; }
}
