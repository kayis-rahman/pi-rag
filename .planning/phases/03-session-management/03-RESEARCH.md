# Phase 3: Session Management - Research

**Researched:** 2026-03-21
**Domain:** Session tracking and persistence for conversation continuity
**Confidence:** HIGH

## Summary

Phase 3 implements session management to track conversations across requests with transparent session ID generation and persistence through episodic memory. The implementation leverages existing infrastructure (Redis for TTL-based cache, PostgreSQL for durable storage, episodic memory pattern already established) and requires minimal new components beyond a SessionManager service and controller integration points.

Key insight: The phase uses **implicit session detection** (monitoring message array changes) rather than explicit client tracking, making it compatible with Claude Code as-is without requiring header modifications. This dramatically simplifies adoption while reducing coupling.

**Primary recommendation:** Implement SessionManager as a @Service that (1) detects session boundaries via message array inspection, (2) generates UUID session IDs, (3) stores conversation state in episodic memory with Redis TTL, (4) returns session ID in response headers for client reference.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Session ID auto-generated as UUID on first request (no client header required)
- Sessions identified implicitly by monitoring message array patterns (fewer messages or changed earliest message indicates new session)
- Session ID returned in response for client reference
- Store messages array + metadata per session in episodic memory with sessionId field
- Store episodes with sessionId in Redis (episodic memory) using Redis TTL for automatic expiration
- Configurable TTL (default: 7 days or based on REQUIREMENTS)
- No explicit cleanup task needed — Redis handles expiration automatically

### Claude's Discretion
- Exact TTL value (days/hours) — configurable in application.yml
- Message filtering strategy for recovery (all vs recent)
- Metadata fields beyond core set (model, params, timestamp)

### Deferred Ideas (OUT OF SCOPE)
- Real-time session synchronization across multiple servers (load balancing concern) — Phase 7 or later
- Session analytics/reporting — future enhancement
- Session pause/resume UI/API — future enhancement
- Multi-device session sharing — out of scope for v1

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SESS-01 | Implement SessionManager for conversation tracking | SessionManager skeleton exists in codebase, needs activation and session creation logic; implicit detection strategy documented in CONTEXT.md |
| SESS-02 | Store session state across requests | EpisodicMemoryService fully implemented with Redis + PostgreSQL dual storage, Episode model has sessionId field ready; storeEpisode() and getRecentEpisodes() methods support sessionId |
| SESS-03 | Support session persistence via episodic memory | EpisodicMemoryService handles Redis HSET/ZSET storage with automatic TTL; PostgreSQL fallback ensures durability; episode recovery by sessionId implemented |
| SESS-04 | Implement session cleanup for expired sessions | Redis TTL management already built into EpisodicMemoryService (jedis.expire() with configurable TTL); PostgreSQL cleanup via clearExpiredEpisodes() method exists |

</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Redis (Jedis client) | 4.4.6 | In-memory cache with TTL-based expiration | Built-in to project, already integrated for episodic memory; TTL semantics match session cleanup requirements perfectly |
| PostgreSQL | 42.7.3 | Durable episode storage (backup to Redis) | Enables recovery after Redis flush; dual-layer storage (Redis fast-path, PostgreSQL durable fallback) is industry standard for session persistence |
| Spring WebFlux | 3.3.5 | Reactive request handling | Project uses Reactor Mono/Flux throughout; all controllers return Mono<T>, session tracking must be async-compatible |
| Spring Boot | 3.3.5 | Application framework | Base framework; SessionManager integrates as @Service with constructor injection per project conventions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Lombock | 1.18.34 | Reduce boilerplate (constructors, getters) | Project standard; SessionManager should use @RequiredArgsConstructor for constructor injection |
| UUID (Java stdlib) | Java 21 | Generate session IDs | Built-in, no dependency needed; cryptographically strong randomness sufficient for session identifiers |
| Jackson ObjectMapper | Spring-bundled | JSON serialization for storing message arrays | Already available in controllers; use for episode content serialization |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Redis + PostgreSQL dual-layer | Cache-aside with lazy loading | Simpler initially, but loses durability if Redis fails mid-session; dual-layer is safer for production |
| UUID for session ID | Sequential/timestamp-based IDs | UUIDs are collision-safe and don't reveal session count; sequential IDs cheaper but worse for privacy/security |
| Implicit detection | Explicit X-Session-ID header | Implicit detection requires no client changes; explicit header requires Claude Code modification (out of scope) |
| Manual cleanup tasks | Redis TTL + scheduled purge | Redis TTL is zero-ops; manual cleanup adds operational burden and clock-sync issues across replicas |

**Installation:** Already complete in build.gradle — redis.clients:jedis:4.4.6, postgresql:42.7.3 are present

---

## Architecture Patterns

### Recommended Project Structure
```
src/main/java/com/synapse/
├── workflow/
│   ├── SessionManager.java         # New: Session creation, tracking, boundary detection
│   ├── SessionDetectionStrategy.java # New: Implicit message array comparison
│   └── ...
├── llm/api/
│   ├── AnthropicCompatibleController.java  # Existing: Intercept messages, invoke SessionManager
│   └── ...
├── memory/
│   ├── Episode.java                # Existing: sessionId field already present
│   └── episodic/EpisodicMemoryService.java # Existing: storeEpisode(sessionId), getRecentEpisodes(sessionId)
└── ...
```

### Pattern 1: Implicit Session Detection via Message Array Inspection
**What:** Detect new sessions by comparing incoming message array with previous request's stored messages. A new session occurs when:
1. Total message count decreases (conversation reset)
2. Earliest message's content changes (new conversation topic)
3. Timestamp of earliest message changed (session boundary)

**When to use:** Works with stateless clients (Claude Code) that send full conversation history on each request; automatically detects user-initiated conversation resets without explicit API signaling.

**Example:**
```java
// Source: CONTEXT.md Phase 3 design
public class SessionDetectionStrategy {

    /**
     * Detect if incoming request represents a new session.
     * Returns true if messages suggest a conversation boundary.
     */
    public SessionBoundary detectSessionBoundary(
            List<Map<String, Object>> currentMessages,
            List<Map<String, Object>> previousMessages,
            String previousSessionId) {

        // Case 1: Fewer total messages than before → new conversation
        if (currentMessages.size() < previousMessages.size()) {
            return new SessionBoundary(
                true,
                "Message count decreased (" + previousMessages.size() + " → " + currentMessages.size() + ")",
                currentMessages.isEmpty() ? null : extractEarliestMessageTimestamp(currentMessages)
            );
        }

        // Case 2: Earliest message content changed → new topic
        if (!previousMessages.isEmpty() && !currentMessages.isEmpty()) {
            String prevEarliest = extractMessageContent(previousMessages.get(0));
            String currEarliest = extractMessageContent(currentMessages.get(0));

            if (!prevEarliest.equals(currEarliest)) {
                return new SessionBoundary(
                    true,
                    "Earliest message content changed (new topic)",
                    extractEarliestMessageTimestamp(currentMessages)
                );
            }
        }

        // Case 3: No change → same session
        return new SessionBoundary(false, "Session continuation", null);
    }
}
```

### Pattern 2: Session Storage via Episodic Memory
**What:** Store entire conversation snapshot as a single Episode per request, with sessionId field indexing episodes by session. Episode contains:
- Full messages array from request
- Metadata: model name, request parameters (temperature, stream flag), timestamp
- User identification: hash of Authorization header (for privacy)

**When to use:** Every incoming request that's part of a conversation; persists conversation history across application restarts via PostgreSQL + Redis TTL.

**Example:**
```java
// Source: Established pattern in EpisodicMemoryService
@Service
@RequiredArgsConstructor
public class SessionManager {

    private final EpisodicMemoryService episodicMemoryService;

    /**
     * Capture current request as an episode for session persistence.
     * Called by controller after request is validated.
     */
    public void recordSessionInteraction(
            String sessionId,
            List<Map<String, Object>> messages,
            Map<String, Object> requestParams,
            String model) {

        // Serialize messages as JSON content
        String content = objectMapper.writeValueAsString(Map.of(
            "messages", messages,
            "model", model,
            "temperature", requestParams.get("temperature"),
            "max_tokens", requestParams.get("max_tokens"),
            "timestamp", LocalDateTime.now()
        ));

        Episode episode = new Episode(sessionId, content);
        episode.setTtlDays(7); // Default: 7 days per REQUIREMENTS

        episodicMemoryService.storeEpisode(episode);
    }

    /**
     * Recover conversation history for a session.
     * Used when client reconnects or app restarts.
     */
    public List<Episode> recoverSessionHistory(String sessionId, int maxMessages) {
        return episodicMemoryService.getRecentEpisodes(sessionId, maxMessages);
    }
}
```

### Pattern 3: Session ID Transport in Response Headers
**What:** Return generated or validated session ID in HTTP response headers (e.g., `X-Session-ID-Generated: <uuid>` or via response body field) so clients can track and optionally send it back on next request.

**When to use:** Every response to `/v1/messages` endpoint; enables external tools to correlate requests to sessions if desired (optional feature for clients).

**Example:**
```java
// Source: Spring WebFlux ResponseEntity pattern
@PostMapping("/v1/messages")
public Mono<ResponseEntity<?>> messages(@RequestBody String rawBody) {
    // ... request processing ...

    String sessionId = sessionManager.detectOrCreateSession(messages);

    // Store episode
    sessionManager.recordSessionInteraction(sessionId, messages, params, model);

    // Build response with session ID header
    return buildResponse(responseBody)
        .map(body -> ResponseEntity.ok()
            .header("X-Session-ID", sessionId)  // For client reference
            .header("X-Session-ID-Generated", sessionId)  // Redundant for clarity
            .body(body));
}
```

### Anti-Patterns to Avoid
- **Storing full message arrays as separate rows:** Fragmenting messages across multiple database rows complicates recovery and pagination. Instead, store entire conversation snapshot as single Episode with sessionId index.
- **Client-managed session IDs only:** Without implicit detection, stateless clients (Claude Code) can't track sessions automatically. Always support implicit detection; explicit header support is optional.
- **Permanent session storage:** Setting infinite TTL defeats purpose of automatic cleanup. Use Redis TTL (7 days default per REQUIREMENTS) to prevent database bloat.
- **Synchronous session detection:** Don't use `.block()` in reactive context. Use `Mono<SessionBoundary>` to keep pipeline non-blocking.
- **Storing raw Authorization headers:** Hash or obfuscate for privacy. Never persist API keys or tokens in plaintext (already handled by RequestInspectorFilter which redacts auth headers).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| TTL-based cache expiration | Manual cleanup scheduler with cron jobs or timer threads | Redis EXPIRE command via jedis.expire() | Redis TTL is atomic, handles distributed clock skew, zero-ops, built into EpisodicMemoryService |
| Session ID generation | Custom UUID builders or hash-based algorithms | java.util.UUID.randomUUID() | Cryptographically strong, collision-proof, ~2^128 namespace, standard in Java since 1.5 |
| Message persistence across restarts | Custom session file formats or in-memory maps | EpisodicMemoryService with Episode model and Redis + PostgreSQL | Dual-layer storage (fast + durable) is proven pattern; Episode model already exists with sessionId field |
| Session boundary detection algorithm | Custom string diffing or complex heuristics | Simple message array length/content comparison per CONTEXT.md | CONTEXT.md documents the exact detection strategy; complex algorithms add maintenance burden without benefit |

**Key insight:** EpisodicMemoryService already handles all low-level session storage concerns. SessionManager's job is **not** to reimplement storage but to orchestrate when and what to store.

---

## Common Pitfalls

### Pitfall 1: Confusing "Session" with "Episode"
**What goes wrong:** Treating Session and Episode as synonymous leads to incorrect cardinality assumptions. If a session has multiple requests, you either duplicate messages across episodes or lose request history.

**Why it happens:** Both involve persistence and involve timing; terminology can blur them.

**How to avoid:** Session = continuous conversation identifier (single UUID for lifetime of chat). Episode = single request/response snapshot within a session (one episode per request, many episodes per session). Store one episode per incoming request, indexed by sessionId.

**Warning signs:**
- Code that stores "the" episode for a session (implies 1:1 mapping)
- Missing episode IDs in logs (each episode should be individually traceable)
- Recovery logic that expects single episode per session instead of querying all episodes for sessionId

### Pitfall 2: Message Array Comparison Performance on Large Conversations
**What goes wrong:** For long conversations (500+ messages), comparing entire message arrays on every request becomes O(n) work. Clients like Claude Code might send 10KB+ message arrays frequently.

**Why it happens:** Implicit detection requires inspecting messages; naive implementation compares full arrays without optimization.

**How to avoid:**
1. **Hash earliest message:** Instead of comparing full content, hash first message object and cache hash in Redis. If hash matches, skip full comparison.
2. **Short-circuit on length:** First check message count; if it decreased, you know it's a new session. Only do content comparison if count is same or increased.
3. **Cache previous state:** Store previous message count + earliest message hash in SessionBoundary cache (5-min TTL) to skip repeated comparisons.

**Warning signs:**
- Detected latency spike when conversation reaches 200+ messages
- CPU spike during request processing proportional to message count
- Redis hit rate drops as conversations grow

### Pitfall 3: Redis Connection Pool Exhaustion with SessionManager
**What goes wrong:** SessionManager creates additional Redis operations (detecting session boundaries, storing episodes, checking TTL). Shared Jedis connection pool (20 max from EpisodicMemoryService) can be exhausted if SessionManager doesn't respect async patterns.

**Why it happens:** If SessionManager makes synchronous `.getConnection()` calls in hot path, or if episode storage isn't batched, pool contention occurs.

**How to avoid:**
1. **Use Mono-based operations:** Return Mono<SessionBoundary> from detection, use flatMap to chain to storage operations.
2. **Batch episode storage:** Don't store episode immediately on every operation. Batch multiple interactions into single database write if possible (but CONTEXT.md says one episode per request, so single write is acceptable; just ensure it's async).
3. **Monitor pool metrics:** Set up Micrometer metrics on Jedis pool usage; alert if active connections > 15 (out of 20 max).

**Warning signs:**
- `Redis connection timeout` errors in logs
- Increasing latency under high load
- Pool starvation reported by Jedis metrics

### Pitfall 4: Implicit Detection Breaks with Tool Use Responses
**What goes wrong:** When Claude sends tool_use blocks (e.g., "I'm calling function X"), the message content structure includes nested tool_use objects. Comparing string content on these complex structures can produce false positives for "new session" detection.

**Why it happens:** CONTEXT.md says "compare message content," but doesn't specify how to handle tool_use blocks, which have different structure than plain text messages.

**How to avoid:**
1. **Normalize before comparison:** Extract only plain text content (recursively walk content arrays, collect text fields). Ignore tool_use/tool_result blocks.
2. **Compare message roles, not content:** Use message role sequence (user→assistant→user→...) as proxy for conversation continuity. New session has different role pattern.
3. **Store fingerprint, not full content:** Hash (role + minimal text) to reduce comparison work.

**Warning signs:**
- False session boundaries detected when using tool calls
- Session ID changing mid-conversation after tool responses
- Logs show "Earliest message content changed" when only tool_use block differed

### Pitfall 5: Session TTL Too Short Causes Premature Expiration
**What goes wrong:** If TTL is set to 1 hour but user takes 2-hour break, next request arrives to find session expired. Episode storage is gone, conversation context is lost.

**Why it happens:** REQUIREMENTS specify "7 days or based on REQUIREMENTS" but default might be misconfigured, or application.yml TTL value gets accidentally lowered.

**How to avoid:**
1. **Set TTL conservatively:** Default to 7 days (604800 seconds) per REQUIREMENTS.md line 46; make configurable via environment variable.
2. **Refresh TTL on each request:** When storing new episode for existing session, call jedis.expire() again to reset TTL counter (extends expiration for active sessions).
3. **Alert on expiration:** Log WARN when session expires; track in metrics.

**Warning signs:**
- Users report "session lost" after breaks
- Application.yml shows very short TTL values
- Logs show episodes being stored but not retrieved on next request

### Pitfall 6: Not Handling Concurrent Requests for Same Session
**What goes wrong:** Two simultaneous requests with same sessionId race to detect boundaries and store episodes. Detection logic compares to "previous" messages, but concurrent requests see stale state.

**Why it happens:** Session boundary detection compares current messages to "last seen" state; with concurrency, "last seen" is undefined/racy.

**How to avoid:**
1. **Use Redis GETSET for atomic operations:** Store and retrieve previous message hash atomically to prevent race conditions.
2. **Versioning:** Include request sequence number; if two requests have same version, one is retry; if one has higher version, it supersedes older one.
3. **Accept duplicates:** If concurrency is low, allow duplicate episodes; recovery logic can deduplicate by sessionId + timestamp + content hash.

**Warning signs:**
- Duplicate episodes appearing in logs for same timestamp
- Session boundary detected incorrectly when requests are concurrent
- Redis transaction errors in logs

---

## Code Examples

Verified patterns from project codebase and official sources:

### Session Manager Service (Main Orchestrator)
```java
// Source: CONTEXT.md + project patterns from EpisodicMemoryService
package com.synapse.workflow;

import com.synapse.memory.Episode;
import com.synapse.memory.episodic.EpisodicMemoryService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class SessionManager {

    private final EpisodicMemoryService episodicMemoryService;
    private final SessionDetectionStrategy detectionStrategy;
    private final ObjectMapper objectMapper;

    /**
     * Detect existing session or create new one based on message array patterns.
     * Implicit detection: no client header required.
     */
    public Mono<String> detectOrCreateSession(
            List<Map<String, Object>> currentMessages,
            String previousSessionId,
            List<Map<String, Object>> previousMessages) {

        return Mono.fromCallable(() -> {
            // Check if this is a session boundary (new conversation)
            SessionBoundary boundary = detectionStrategy.detectSessionBoundary(
                currentMessages,
                previousMessages,
                previousSessionId
            );

            if (boundary.isNewSession()) {
                String newSessionId = UUID.randomUUID().toString();
                log.info("🎫 New session detected: {} | Reason: {}", newSessionId, boundary.getReason());
                return newSessionId;
            } else {
                log.debug("🎫 Session continuation: {}", previousSessionId);
                return previousSessionId;
            }
        });
    }

    /**
     * Record current request as an episode for session persistence.
     * Called after request is validated and before forwarding to LLM.
     */
    public Mono<Void> recordSessionInteraction(
            String sessionId,
            List<Map<String, Object>> messages,
            Map<String, Object> requestParams,
            String model,
            String authorizationHeaderHash) {

        return Mono.fromRunnable(() -> {
            try {
                // Build episode content: messages + metadata
                Map<String, Object> episodeContent = Map.of(
                    "messages", messages,
                    "model", model,
                    "temperature", requestParams.getOrDefault("temperature", 0.7),
                    "max_tokens", requestParams.getOrDefault("max_tokens", 2048),
                    "stream", requestParams.getOrDefault("stream", false),
                    "requestTimestamp", LocalDateTime.now(),
                    "userHash", authorizationHeaderHash  // For user tracking without exposing API key
                );

                String content = objectMapper.writeValueAsString(episodeContent);

                // Create episode with sessionId
                Episode episode = new Episode(sessionId, content);
                episode.setTtlDays(7);  // Default from REQUIREMENTS

                // Store to Redis + PostgreSQL
                episodicMemoryService.storeEpisode(episode);

                log.debug("📝 Recorded episode for session: {} | Messages: {} | Model: {}",
                    sessionId, messages.size(), model);

            } catch (Exception e) {
                log.error("Failed to record session interaction: {}", e.getMessage(), e);
                throw new RuntimeException("Session recording failed", e);
            }
        });
    }

    /**
     * Recover conversation history for a session.
     * Used when client explicitly requests session recovery (future feature).
     */
    public Mono<List<Episode>> recoverSessionHistory(String sessionId, int maxMessages) {
        return Mono.fromCallable(() ->
            episodicMemoryService.getRecentEpisodes(sessionId, maxMessages)
        ).doOnNext(episodes ->
            log.info("📂 Recovered {} episodes for session: {}", episodes.size(), sessionId)
        );
    }
}
```

### Session Detection Strategy (Boundary Detection Logic)
```java
// Source: CONTEXT.md implicit detection requirements
package com.synapse.workflow;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class SessionDetectionStrategy {

    /**
     * Detect if incoming request represents session boundary.
     * Returns true if:
     * 1. Message count decreased (conversation reset)
     * 2. Earliest message content changed (new topic)
     * 3. No previous session (first request)
     */
    public SessionBoundary detectSessionBoundary(
            List<Map<String, Object>> currentMessages,
            List<Map<String, Object>> previousMessages,
            String previousSessionId) {

        // No previous session → definitely new
        if (previousSessionId == null || previousMessages == null || previousMessages.isEmpty()) {
            return SessionBoundary.newSession("First request or no previous session");
        }

        // Case 1: Fewer messages → user reset conversation
        if (currentMessages.size() < previousMessages.size()) {
            return SessionBoundary.newSession(
                String.format("Message count decreased (%d → %d)",
                    previousMessages.size(), currentMessages.size())
            );
        }

        // Case 2: Empty current messages (edge case)
        if (currentMessages.isEmpty()) {
            return SessionBoundary.newSession("Empty message array");
        }

        // Case 3: Compare earliest message content
        String prevEarliest = extractNormalizedContent(previousMessages.get(0));
        String currEarliest = extractNormalizedContent(currentMessages.get(0));

        if (!prevEarliest.equals(currEarliest)) {
            return SessionBoundary.newSession(
                "Earliest message content changed (new topic or reset)"
            );
        }

        // Case 4: No change → session continuation
        return SessionBoundary.continuation(previousSessionId);
    }

    /**
     * Extract normalized text content from message (handles tool_use blocks).
     * Ignores tool_use/tool_result blocks, focuses on plain text.
     */
    private String extractNormalizedContent(Map<String, Object> message) {
        Object content = message.get("content");

        // Simple string content
        if (content instanceof String) {
            return (String) content;
        }

        // Array of content blocks (text, tool_use, tool_result)
        if (content instanceof List) {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> blocks = (List<Map<String, Object>>) content;

            StringBuilder sb = new StringBuilder();
            for (Map<String, Object> block : blocks) {
                String type = (String) block.get("type");
                if ("text".equals(type)) {
                    Object text = block.get("text");
                    if (text != null) {
                        sb.append(text);
                    }
                }
            }
            return sb.toString();
        }

        return "";
    }

    @Data
    @AllArgsConstructor
    public static class SessionBoundary {
        private boolean newSession;
        private String reason;
        private String sessionId;  // For continuation, the session ID to use

        public static SessionBoundary newSession(String reason) {
            return new SessionBoundary(true, reason, null);
        }

        public static SessionBoundary continuation(String sessionId) {
            return new SessionBoundary(false, "Session continuation", sessionId);
        }
    }
}
```

### Controller Integration (AnthropicCompatibleController)
```java
// Source: Existing AnthropicCompatibleController pattern + session integration
// In /v1/messages POST handler:

@PostMapping("/v1/messages")
public Mono<ResponseEntity<?>> messages(@RequestBody String rawBody,
                                        ServerWebExchange exchange) {
    long startTime = System.currentTimeMillis();

    try {
        // ... existing request parsing ...
        Map<String, Object> anthropicRequest = objectMapper.readValue(rawBody, Map.class);
        @SuppressWarnings("unchecked")
        List<Object> messages = (List<Object>) anthropicRequest.get("messages");
        String model = (String) anthropicRequest.get("model");

        // Extract Authorization header for user identification (hash it)
        String authHeader = exchange.getRequest().getHeaders().getFirst("Authorization");
        String authHash = hashAuthorizationHeader(authHeader);

        // Extract previous session ID from header (if client provided one)
        String providedSessionId = exchange.getRequest().getHeaders().getFirst("X-Session-ID");

        // NEW: Detect or create session
        return sessionManager.detectOrCreateSession(
            messages,  // current messages
            providedSessionId,  // previous session (from header or cache)
            loadPreviousMessages(providedSessionId)  // cached messages from previous request
        ).flatMap(sessionId -> {

            // NEW: Record this interaction as an episode
            Map<String, Object> requestParams = Map.of(
                "temperature", anthropicRequest.getOrDefault("temperature", 0.7),
                "max_tokens", anthropicRequest.getOrDefault("max_tokens", 2048),
                "stream", anthropicRequest.getOrDefault("stream", false)
            );

            return sessionManager.recordSessionInteraction(
                sessionId,
                messages,
                requestParams,
                model,
                authHash
            ).then(
                // Existing LLM forwarding logic
                forwardToVllm(openaiRequest, model, messageCount, startTime)
            ).map(openaiResponse -> {
                try {
                    Map<String, Object> openaiResponseMap = objectMapper.readValue(openaiResponse, Map.class);
                    Map<String, Object> anthropicResponse = translateOpenAIToAnthropic(
                        openaiResponseMap, model
                    );

                    // NEW: Include session ID in response
                    return (ResponseEntity<?>) ResponseEntity.ok()
                        .header("X-Session-ID", sessionId)
                        .header("X-Session-ID-Generated", sessionId)
                        .body(anthropicResponse);

                } catch (Exception e) {
                    return (ResponseEntity<?>) ResponseEntity.status(400)
                        .body(anthropicError("api_error", "Response translation failed"));
                }
            });
        });

    } catch (Exception e) {
        return Mono.just(ResponseEntity.status(400)
            .body(anthropicError("invalid_request_error", e.getMessage())));
    }
}

private String hashAuthorizationHeader(String authHeader) {
    // Hash for privacy; don't store raw API keys
    if (authHeader == null) return "anonymous";
    try {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest(authHeader.getBytes());
        return Base64.getEncoder().encodeToString(hash).substring(0, 16);
    } catch (Exception e) {
        return "hash_error";
    }
}

private List<Map<String, Object>> loadPreviousMessages(String sessionId) {
    // TODO: Cache mechanism to store previous request's message array
    // For now, return empty list; real implementation would query Redis cache
    // or session store for last request's messages
    return List.of();
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| File-based session storage (Java serialization) | Redis + PostgreSQL dual-layer | Java EE → Spring Boot (2010s) | Scalability: can now handle concurrent sessions without file locks; cloud-friendly (externalized state) |
| Sticky sessions on load balancer | Stateless app + external session store | Microservices era (2015+) | Enables horizontal scaling; session not tied to single server |
| Client-managed session tokens | Server-generated session IDs + Redis TTL | HTTP/2 standard patterns | Reduces client complexity; automatic expiration prevents session bloat |
| Full conversation in session cookie | External persistent storage (episodic memory) | Data protection regulations (GDPR, 2018) | User data not exposed in HTTP headers; persistent recovery after restarts |

**Deprecated/outdated:**
- **Servlet HttpSession API:** Old approach stored sessions in memory or file. Spring Session modernizes this by externalizing to Redis. Not used in this project (uses Spring WebFlux, not MVC).
- **Manual connection pooling:** Jedis 4.x handles pool management internally. Old approach of manual pool creation (Jedis 2.x) is obsolete.

---

## Validation Architecture

Test framework and requirements mapping for Phase 3.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | JUnit 5 (Spring Boot Test) + Mockito |
| Config file | None — tests are standalone; project uses `@SpringBootTest` for integration tests |
| Quick run command | `cd app && ./gradlew test -i --include-build-cache 2>&1 \| grep -E "SessionManager\|EpisodicMemory"` |
| Full suite command | `cd app && ./gradlew test --parallel` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SESS-01 | SessionManager created with UUID on first request | Unit | `./gradlew test --tests "*SessionManagerTest" -x` | ❌ Wave 0 |
| SESS-01 | Implicit detection: new session when message count decreases | Unit | `./gradlew test --tests "*SessionDetectionTest" -x` | ❌ Wave 0 |
| SESS-01 | Implicit detection: new session when earliest message content changes | Unit | `./gradlew test --tests "*SessionDetectionTest" -x` | ❌ Wave 0 |
| SESS-02 | Session state stored via episodic memory | Integration | `./gradlew test --tests "*SessionManagerIntegrationTest" -x` | ❌ Wave 0 |
| SESS-02 | Session ID returned in response header (X-Session-ID) | Integration | `./gradlew test --tests "*AnthropicControllerSessionTest" -x` | ❌ Wave 0 |
| SESS-03 | Episodes retrieved by sessionId from episodic memory | Unit | `./gradlew test --tests "*EpisodicMemoryServiceTest*getRecentEpisodes" -x` | ✅ Partial (covers generic retrieval, not sessionId-specific) |
| SESS-04 | Expired sessions cleaned up via Redis TTL | Integration | `./gradlew test --tests "*SessionExpirationTest" -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Run quick test: `cd app && ./gradlew test --tests "*Session*" -i`
- **Per wave merge:** Run full test suite: `cd app && ./gradlew test --parallel && cd app && ./gradlew check`
- **Phase gate:** Full suite green + metrics show no Redis pool exhaustion before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `app/src/test/java/com/synapse/workflow/SessionManagerTest.java` — covers SESS-01 (UUID generation, session creation)
- [ ] `app/src/test/java/com/synapse/workflow/SessionDetectionTest.java` — covers SESS-01 (implicit boundary detection)
- [ ] `app/src/test/java/com/synapse/workflow/SessionManagerIntegrationTest.java` — covers SESS-02, SESS-03 (episodic storage)
- [ ] `app/src/test/java/com/synapse/llm/api/AnthropicControllerSessionTest.java` — covers SESS-02 (controller integration, header response)
- [ ] `app/src/test/java/com/synapse/workflow/SessionExpirationTest.java` — covers SESS-04 (TTL and cleanup)
- [ ] Configuration: Ensure `application-test.yml` sets realistic TTL for testing (60 seconds instead of 7 days)

---

## Sources

### Primary (HIGH confidence)
- **Code inspection** — EpisodicMemoryService.java, Episode.java, AnthropicCompatibleController.java (patterns verified in codebase)
- **CONTEXT.md** — Phase 3 decisions on implicit detection, Redis TTL, episodic storage (locked design)
- **REQUIREMENTS.md** — SESS-01 through SESS-04 requirements (source of truth for phase scope)
- **Project Conventions (SKILL.md)** — Spring patterns, reactive style (@RequiredArgsConstructor, Mono<T>)
- **build.gradle** — Dependencies confirmed: jedis 4.4.6, postgresql 42.7.3, spring-boot-starter-webflux 3.3.5

### Secondary (MEDIUM confidence)
- **Spring Data Redis Documentation** — https://spring.io/projects/spring-data-redis (best practices for TTL, template patterns)
- **Jedis Documentation** — https://github.com/redis/jedis (HSET/ZSET patterns, expire() semantics verified)
- **Spring WebFlux Patterns** — https://spring.io/projects/spring-webflux (Mono/Flux reactive chains; non-blocking I/O confirmed in codebase)

### Tertiary (patterns inferred from codebase)
- RequestInspectorFilter.java — Demonstrates WebFilter integration and header inspection
- EpisodicMemoryServiceTest.java — Shows testing patterns for Redis/PostgreSQL dual-layer storage
- ChatControllerIntegrationTest.java — Shows Spring WebFlux @SpringBootTest + WebTestClient patterns

---

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — All libraries already in build.gradle; Jedis and PostgreSQL drivers confirmed present
- Architecture: **HIGH** — EpisodicMemoryService fully implemented; SessionManager skeleton commented out; implicit detection strategy locked in CONTEXT.md
- Pitfalls: **MEDIUM** — Message array comparison performance, Redis pool contention, and TTL edge cases are common pitfalls from experience; specific to project's scale unknown

**Research date:** 2026-03-21
**Valid until:** 2026-04-21 (30 days — Redis/Spring Boot stable, no major updates expected)
**Assumptions:**
- Redis TTL semantics remain atomic and reliable (industry standard)
- EpisodicMemoryService Redis connection pool size (20 max) is sufficient for session operations
- Claude Code continues to send full message history on each request (established pattern)
