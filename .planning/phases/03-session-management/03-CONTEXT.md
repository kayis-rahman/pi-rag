# Phase 3: Session Management - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Track conversations across requests with session state persistence and automatic cleanup. Users can resume conversations after application restart. Each unique conversation detected by monitoring message array patterns gets a session ID and persistent storage via episodic memory.

</domain>

<decisions>
## Implementation Decisions

### Session Creation & Identification
- Session ID auto-generated as UUID on first request (no client header required)
- Sessions identified implicitly by monitoring message array patterns:
  - New session detected when messages array "resets" (fewer total messages than previous request)
  - Or when earliest message content changes (new conversation topic)
  - Timestamp of earliest message marks session boundary
- Works with Claude Code as-is (no client modifications needed)

### Session ID Transport & Response
- Accept optional `X-Session-ID` header from clients for explicit session tracking
- Return generated session ID in response (custom header or body) for reference
- If X-Session-ID provided, use it; otherwise use implicit detection

### Session State Storage
- Store messages array + metadata per session:
  - All messages in conversation
  - Timestamp of each request
  - Model name used (from request)
  - Request parameters (stream flag, temperature, etc.)
  - Authorization header hash (for user identification)
- Store as Episode in episodic memory with sessionId field

### Session Persistence & Recovery
- Store episodes with `sessionId` in Redis (episodic memory)
- Recovery after app restart: query episodic memory by sessionId
- Reconstruct conversation by retrieving all episodes for that sessionId
- Fallback to knowledge graph if semantic relationships needed

### Session Expiration & Cleanup
- Use Redis TTL (time-to-live) for automatic expiration
- Configurable TTL (default: 7 days or based on REQUIREMENTS)
- No explicit cleanup task needed — Redis handles expiration
- Expired session data auto-removed from Redis

### Claude's Discretion
- Exact TTL value (days/hours) — configurable in application.yml
- Message filtering strategy for recovery (all vs recent)
- Metadata fields beyond the core set (model, params, timestamp)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- **SessionManager.java** (workflow/) — skeleton exists, commented out. Ready for implementation with session creation/tracking logic.
- **Episode.java** (memory/) — already has `sessionId` field defined. Perfect for storing session state.
- **EpisodicMemoryService.java** (memory/episodic/) — available for storing/retrieving episodes by sessionId.
- **ChatController.java** (llm/api/) — handles `/api/chat` requests. Pattern: accepts ChatRequest, returns Mono<Map>.

### Established Patterns
- Reactive streaming (WebFlux) — all controllers use Mono/Flux, not blocking. Session tracking must be async.
- Request routing via AnthropicCompatibleController — `/v1/messages` endpoint receives all chat requests.
- Authorization header present in all Claude Code requests — can be used for user identification.

### Integration Points
- **RequestInspectorFilter.java** (newly added) — logs all incoming headers. Can detect X-Session-ID if provided by client.
- **Episode storage** — episodes already have sessionId field; implement querying by sessionId in EpisodicMemoryService.
- **Response headers** — ChatController's response can include session ID in custom header (e.g., `X-Session-ID-Generated`).

### Claude Code Integration
- Claude Code sends:
  - User-Agent: `claude-cli/2.1.81 (external, cli)`
  - Authorization header: [API key/token]
  - X-Stainless-* headers: SDK metadata (arch, OS, package version, etc.)
  - NO explicit session ID header
- Each request includes full message history (conversation continuity maintained by client)
- Session boundary detection must work with this stateless request pattern

</code_context>

<specifics>
## Specific Ideas

- Session detection via message array comparison: if `messages.length < previous_request.length`, likely a new conversation
- Store each request's messages as a single Episode with the detected sessionId
- Return session ID in response so external tools can track and explicitly send it back
- Consider hashing Authorization header for privacy (user identification without exposing API key)

</specifics>

<deferred>
## Deferred Ideas

- Real-time session synchronization across multiple servers (load balancing concern) — Phase 7 or later
- Session analytics/reporting — future enhancement
- Session pause/resume UI/API — future enhancement
- Multi-device session sharing — out of scope for v1

</deferred>

---

*Phase: 03-session-management*
*Context gathered: 2026-03-21*
