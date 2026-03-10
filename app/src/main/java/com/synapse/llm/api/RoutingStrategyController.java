package com.synapse.llm.api;

import com.synapse.llm.routing.StrategyRegistry;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

/**
 * REST API controller for managing routing strategies at runtime.
 *
 * Endpoints:
 * - GET /api/routing/strategy — Get current active strategy and list available strategies
 * - PUT /api/routing/strategy/{name} — Switch to a different routing strategy
 *
 * Example usage:
 * <pre>
 *   # Get status
 *   curl http://localhost:8080/api/routing/strategy
 *
 *   # Switch to tiered-claude strategy
 *   curl -X PUT http://localhost:8080/api/routing/strategy/tiered-claude
 *
 *   # Switch back to adaptive strategy
 *   curl -X PUT http://localhost:8080/api/routing/strategy/adaptive
 * </pre>
 */
@RestController
@RequestMapping("/api/routing/strategy")
public class RoutingStrategyController {
    private static final Logger logger = LoggerFactory.getLogger(RoutingStrategyController.class);

    private final StrategyRegistry strategyRegistry;

    public RoutingStrategyController(StrategyRegistry strategyRegistry) {
        this.strategyRegistry = strategyRegistry;
    }

    /**
     * Get the current active routing strategy and list available strategies.
     *
     * @return Response with active strategy name and list of available strategies
     */
    @GetMapping
    public Mono<ResponseEntity<StrategyStatusResponse>> getStatus() {
        StrategyStatusResponse response = new StrategyStatusResponse(
                strategyRegistry.getActiveName(),
                strategyRegistry.getAvailableNames()
        );
        return Mono.just(ResponseEntity.ok(response));
    }

    /**
     * Switch the active routing strategy at runtime.
     *
     * @param name the name of the strategy to switch to
     * @return 200 OK if successful, 400 BAD REQUEST if strategy not found
     */
    @PutMapping("/{name}")
    public Mono<ResponseEntity<Object>> switchStrategy(@PathVariable String name) {
        try {
            strategyRegistry.switchTo(name);
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Routing strategy switched successfully");
            response.put("active", strategyRegistry.getActiveName());
            return Mono.just(ResponseEntity.ok(response));
        } catch (IllegalArgumentException e) {
            logger.warn("Failed to switch to strategy '{}': {}", name, e.getMessage());
            Map<String, Object> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("available", strategyRegistry.getAvailableNames());
            return Mono.just(ResponseEntity.badRequest().body(error));
        }
    }

    /**
     * Response DTO for strategy status.
     */
    public static class StrategyStatusResponse {
        public final String active;
        public final java.util.Set<String> available;

        public StrategyStatusResponse(String active, java.util.Set<String> available) {
            this.active = active;
            this.available = available;
        }

        public String getActive() {
            return active;
        }

        public java.util.Set<String> getAvailable() {
            return available;
        }
    }
}
