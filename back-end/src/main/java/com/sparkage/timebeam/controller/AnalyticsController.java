package com.sparkage.timebeam.controller;

import com.sparkage.timebeam.dto.AnalyticsDashboardResponse;
import com.sparkage.timebeam.service.AnalyticsService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

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
}
