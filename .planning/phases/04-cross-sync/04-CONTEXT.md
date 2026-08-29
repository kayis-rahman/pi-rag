# Phase 4: Cross Sync - Context

**Gathered:** 2026-05-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Harden and complete event-driven cross-device timer synchronization between iOS and macOS. The sync system already has partial implementation (APNs push, 30s polling, deviceId tracking, @JsonAlias DTO mapping). This phase delivers robust conflict resolution, offline action queuing, push-based delta sync, and proper state restoration on app relaunch. Covers SYNC-01 through SYNC-06.

</domain>

<decisions>
## Implementation Decisions

### Conflict Resolution
- **D-01:** Primary: timestamp comparison — newer timestamp wins (existing behavior from Phase 3)
- **D-02:** Tiebreaker for identical timestamps: last received change wins (backend arrival order). Simple, deterministic, no platform bias
- **D-03:** Both devices can start/pause/stop simultaneously — no ownership model. Timestamp-based resolution handles merges

### Offline Behavior
- **D-04:** Buffer timer actions locally in a queue when network is unavailable
- **D-05:** On network reconnect, replay queued actions in order to backend
- **D-06:** Exponential backoff on sync failures (30s → 60s → 120s → cap 300s). Show user alert after 3 consecutive failures, allow manual retry

### Push Notification Strategy
- **D-07:** APNs silent push carries timer state delta in payload — apply directly without network round-trip
- **D-08:** Push payload must include `lastModifiedTimestamp` for proper timestamp-based conflict resolution (learned from fix session 2026-05-10)
- **D-09:** Event-driven primary sync path: each timer action (start/stop/pause) pushes to server → APN to active devices → apply delta. Polling is fallback only

### State Persistence
- **D-10:** On app relaunch, pull timer state from backend API (not local cache). Most accurate — includes changes made on other devices while app was closed
- **D-11:** `setupApp()` flow: restore auth → pull timer state → configure sync manager → set `isAppReady = true` (existing pattern from CLAUDE.md)

### Sync Architecture
- **D-12:** 30s polling interval as fallback/safety net only. Primary sync is event-driven via APNs
- **D-13:** `TimerSyncManager` singleton handles all sync logic; `PomodoroTimer` remains single source of truth in memory

### Claude's Discretion
- Exact queue data structure (array, circular buffer, persisted vs in-memory)
- Push retry logic and batching strategy
- Alert UI design for sync failures
- Queue size limits and overflow behavior

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Timer Sync Architecture
- `apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift` — Sync singleton, 30s polling, deviceId Keychain
- `apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift` — In-memory timer state, single source of truth
- `apple/TimeBeam/TimeBeam/TimeBeamApp.swift` — `setupApp()` launch flow (auth → pull state → sync config)
- `apple/TimeBeam/TimeBeam/Infrastructure/Networking/DTOs/TimerActionDto.swift` — iOS DTO with `action` field
- `back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TimerActionDto.java` — Backend DTO with `@JsonAlias({"action","actionType"})`
- `back-end/src/main/java/com/sparkage/timebeam/presentation/controller/SessionController.java` — `convertActionToState()` logic
- `back-end/src/main/java/com/sparkage/timebeam/application/service/TimerSyncService.java` — Backend sync service

### Push Notifications
- `back-end/src/main/java/com/sparkage/timebeam/infrastructure/external/PushNotificationService.java` — APNs push, `lastModifiedTimestamp` in payload (fix session)

### Platform App Delegates
- `apple/TimeBeam/TimeBeam/Infrastructure/External/MacAppDelegate.swift` — `@MainActor` registerApnsTokenWhenReady
- `apple/TimeBeam/TimeBeam/Infrastructure/External/iOSAppDelegate.swift` — `@MainActor` registerApnsTokenWhenReady

### Keychain
- `apple/TimeBeam/TimeBeam/Helper/KeychainStore.swift` — Token + deviceId storage, access group `425MSY8FLG.com.sparkage.time-beam`

### Requirements
- `.planning/REQUIREMENTS.md` — SYNC-01 through SYNC-06 requirement definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TimerSyncManager.swift` — Existing sync infrastructure (polling, deviceId, conflict resolution). Extend for event-driven sync and offline queue
- `PushNotificationService.java` — APNs push already wired with `lastModifiedTimestamp`. Add delta payload support
- `TimerActionDto.swift` / `TimerActionDto.java` — DTO round-trip working with `@JsonAlias`. Reuse for queued action serialization
- `KeychainStore.swift` — deviceId persistence already working. Reuse for action queue persistence if needed

### Established Patterns
- Event-driven sync: `PomodoroTimer` action → `TimerSyncManager.pushTimerAction()` → `ApiClient` → backend → APNs → other device
- State polling: 30s `TimerSyncManager.startPeriodicPolling()` → `pullTimerState()` → timestamp comparison
- `@MainActor` for UI state access (learned from fix session)
- `setupApp()` ordered initialization: auth → state → sync → ready

### Integration Points
- `TimeBeamApp.swift` `setupApp()` — add offline queue drain on launch
- `MacAppDelegate.swift` / `iOSAppDelegate.swift` notification handlers — apply delta from push payload
- `TimerSyncManager.swift` — add action queue, network monitoring, backoff logic
- `SessionController.java` — enhance to support delta push payload generation

</code_context>

<specifics>
## Specific Ideas

- "Event-driven approach — each start/stop pushes an event to server, then APN to active devices to apply those events"
- Timer should survive app relaunch with state from backend, not stale local cache
- User should be notified when sync is broken, not left unaware

</specifics>

<deferred>
## Deferred Ideas

- Advanced conflict resolution strategies (V2, REQUIREMENTS.md) — multiple resolution policies
- Smart sync intervals / adaptive polling (V2) — interval tuning based on activity
- End-to-end encryption for timer data (V2)
- Support for additional device types beyond iOS/macOS (Future Enhancements)
- iCloud/CloudKit as secondary sync path

</deferred>

---

*Phase: 04-cross-sync*
*Context gathered: 2026-05-10*
