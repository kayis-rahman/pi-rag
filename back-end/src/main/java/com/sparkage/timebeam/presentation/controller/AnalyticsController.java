package com.sparkage.timebeam.presentation.controller;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.sparkage.timebeam.application.service.AnalyticsService;
import com.sparkage.timebeam.presentation.dto.AnalyticsDashboardResponse;
import com.sparkage.timebeam.presentation.dto.SessionsResponseDto;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {
    private static final Logger log = LoggerFactory.getLogger(AnalyticsController.class);

    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/dashboard")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getDashboard(
            Authentication auth,
            @RequestParam Optional<String> timeRange,
            @RequestParam Optional<String> breakdown) {

        String username = auth.getName(); // Get username from authentication
        UUID userId = UUID.fromString(username);
        String range = timeRange.orElse("week");
        String breakdownType = breakdown.orElse("weekday");

        log.info("getDashboard userId={}, timeRange={}, breakdown={}", userId, range, breakdownType);

        try {
            AnalyticsDashboardResponse response = analyticsService.getDashboardMetrics(userId, range, breakdownType);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.warn("Invalid parameter: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Error fetching dashboard metrics", e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch dashboard metrics"));
        }
    }

    @GetMapping("/weekly")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getWeeklyAnalytics(Authentication auth) {
        String username = auth.getName();
        UUID userId = UUID.fromString(username);

        log.info("getWeeklyAnalytics userId={}", userId);

        try {
            Map<String, Object> response = analyticsService.getWeeklyAnalytics(userId);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error fetching weekly analytics", e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch weekly analytics"));
        }
    }

    @GetMapping("/sessions")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getSessions(
            Authentication auth,
            @RequestParam Optional<String> timeRange,
            @RequestParam Optional<String> kind,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int pageSize) {

        String username = auth.getName();
        UUID userId = UUID.fromString(username);
        String range = timeRange.orElse("week");

        log.info("getSessions userId={}, timeRange={}, kind={}, page={}, pageSize={}",
                 userId, range, kind.orElse("all"), page, pageSize);

        try {
            Map<String, Object> rawResponse = analyticsService.getSessions(userId, range, kind, page, pageSize);

            // Convert to proper DTO
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> data = (List<Map<String, Object>>) rawResponse.get("data");
            @SuppressWarnings("unchecked")
            Map<String, Object> paginationMap = (Map<String, Object>) rawResponse.get("pagination");

            SessionsResponseDto.PaginationInfo pagination = new SessionsResponseDto.PaginationInfo(
                (Integer) paginationMap.get("page"),
                (Integer) paginationMap.get("pageSize"),
                (Integer) paginationMap.get("total"),
                (Integer) paginationMap.get("totalPages")
            );

            SessionsResponseDto response = new SessionsResponseDto(
                data,
                pagination,
                (String) rawResponse.get("time_range"),
                (String) rawResponse.get("kind_filter")
            );

            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.warn("Invalid parameter: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Error fetching sessions", e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to fetch sessions"));
        }
    }

    // Temporary test endpoint without authentication
    @GetMapping("/test")
    public ResponseEntity<?> testAnalytics() {
        try {
            UUID testUserId = UUID.fromString("67546cba-5ba0-4b83-84bf-5906af7b2708");
            Map<String, Object> dailyTotals = analyticsService.getDailyTotals(testUserId, 7, "UTC");
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "dailyTotals", dailyTotals,
                "message", "Analytics queries are working!"
            ));
        } catch (Exception e) {
            log.error("Test endpoint error", e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage(), "status", "failed"));
        }
    }

    // Temporary test endpoint for sessions without authentication
    @GetMapping("/test-sessions")
    public ResponseEntity<?> testSessions() {
        try {
            UUID testUserId = UUID.fromString("67546cba-5ba0-4b83-84bf-5906af7b2708");
            Map<String, Object> sessions = analyticsService.getSessions(testUserId, "week", Optional.empty(), 0, 5);

            // Convert to proper DTO
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> data = (List<Map<String, Object>>) sessions.get("data");
            @SuppressWarnings("unchecked")
            Map<String, Object> paginationMap = (Map<String, Object>) sessions.get("pagination");

            SessionsResponseDto.PaginationInfo pagination = new SessionsResponseDto.PaginationInfo(
                (Integer) paginationMap.get("page"),
                (Integer) paginationMap.get("pageSize"),
                (Integer) paginationMap.get("total"),
                (Integer) paginationMap.get("totalPages")
            );

            SessionsResponseDto response = new SessionsResponseDto(
                data,
                pagination,
                (String) sessions.get("time_range"),
                (String) sessions.get("kind_filter")
            );

            return ResponseEntity.ok(Map.of(
                "status", "success",
                "sessions", response,
                "message", "Sessions API is working!"
            ));
        } catch (Exception e) {
            log.error("Test sessions endpoint error", e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage(), "status", "failed"));
        }
    }
}
