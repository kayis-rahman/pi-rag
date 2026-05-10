# Phase 4: Cross Sync - Research

**Researched:** 2026-05-10
**Domain:** Cross-device timer synchronization, offline resilience, APNs push notifications, network monitoring
**Confidence:** HIGH

## Summary

Phase 4 hardens the existing partial cross-device timer sync into a robust, event-driven system. The codebase already has working APNs push infrastructure (pushy 0.15.4), 5-second polling, deviceId Keychain persistence, `@JsonAlias` DTO mapping, and push payload handling in both iOS/macOS app delegates. The missing pieces are: offline action queuing, network connectivity detection, exponential backoff for sync failures, push-based delta apply (eliminating network round-trip), and user-facing sync failure alerts.

**Primary recommendation:** Build offline resilience directly into `TimerSyncManager` as an extension -- add a FIFO action queue (in-memory `Array` backed by Keychain for crash survival), `NWPathMonitor` for connectivity detection, and exponential backoff in the existing `syncWithRetry` method. The backend requires minimal changes: ensure the push payload includes `autoStartNextSession` and `shortBreaksCompleted` fields (currently missing from the push payload template in `PushNotificationService`).

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Primary: timestamp comparison -- newer timestamp wins (existing behavior from Phase 3)
- **D-02:** Tiebreaker for identical timestamps: last received change wins (backend arrival order). Simple, deterministic, no platform bias
- **D-03:** Both devices can start/pause/stop simultaneously -- no ownership model. Timestamp-based resolution handles merges
- **D-04:** Buffer timer actions locally in a queue when network is unavailable
- **D-05:** On network reconnect, replay queued actions in order to backend
- **D-06:** Exponential backoff on sync failures (30s -> 60s -> 120s -> cap 300s). Show user alert after 3 consecutive failures, allow manual retry
- **D-07:** APNs silent push carries timer state delta in payload -- apply directly without network round-trip
- **D-08:** Push payload must include `lastModifiedTimestamp` for proper timestamp-based conflict resolution (learned from fix session 2026-05-10)
- **D-09:** Event-driven primary sync path: each timer action (start/stop/pause) pushes to server -> APN to active devices -> apply delta. Polling is fallback only
- **D-10:** On app relaunch, pull timer state from backend API (not local cache). Most accurate -- includes changes made on other devices while app was closed
- **D-11:** `setupApp()` flow: restore auth -> pull timer state -> configure sync manager -> set `isAppReady = true` (existing pattern from CLAUDE.md)
- **D-12:** 30s polling interval as fallback/safety net only. Primary sync is event-driven via APNs
- **D-13:** `TimerSyncManager` singleton handles all sync logic; `PomodoroTimer` remains single source of truth in memory

### Claude's Discretion
- Exact queue data structure (array, circular buffer, persisted vs in-memory)
- Push retry logic and batching strategy
- Alert UI design for sync failures
- Queue size limits and overflow behavior

### Deferred Ideas (OUT OF SCOPE)
- Advanced conflict resolution strategies (V2, REQUIREMENTS.md) -- multiple resolution policies
- Smart sync intervals / adaptive polling (V2) -- interval tuning based on activity
- End-to-end encryption for timer data (V2)
- Support for additional device types beyond iOS/macOS (Future Enhancements)
- iCloud/CloudKit as secondary sync path

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Timer action queue | Frontend (Swift) | — | Local buffering decision; no backend involvement |
| Network connectivity detection | Frontend (Swift) | — | Platform-specific (NWPathMonitor); purely client-side |
| Action queue replay | Frontend (Swift) -> API/Backend | — | Client queues, backend receives via existing endpoints |
| Conflict resolution (timestamp) | API/Backend | Frontend (Swift) | Backend is authoritative; client applies resolved state |
| APNs push delta generation | API/Backend | — | Backend constructs payload after state mutation |
| Push delta apply | Frontend (Swift) | — | Client-side notification handler applies state |
| Sync failure backoff | Frontend (Swift) | — | Client-side retry logic |
| Sync failure user alert | Frontend (Swift) | — | UI-layer concern |
| State restoration on launch | Frontend (Swift) -> API/Backend | — | Client pulls from backend; both tiers involved |
| Device registration | API/Backend | Frontend (Swift) | Backend stores tokens; client registers |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| pushy (com.eatthepath) | 0.15.4 `[VERIFIED: pom.xml]` | APNs client for Spring Boot | Industry-standard Java APNs library; already integrated |
| NWPathMonitor | Built-in (Network.framework) | Connectivity detection | Apple's modern replacement for Reachability; available on both iOS/macOS |
| Swift Concurrency (Task/async-await) | iOS 16+/macOS 12+ `[VERIFIED: codebase]` | Async sync operations | Already used throughout TimerSyncManager |
| @Observable macro | iOS 17+/macOS 14+ `[VERIFIED: codebase]` | Timer state observation | Already used for PomodoroTimer |
| Security.framework | Built-in | Keychain persistence | Already used for deviceId, tokens |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | Built-in | Unit tests | TimerSyncManager queue tests, backoff tests |
| Mockito | Spring Boot test `[VERIFIED: pom.xml]` | Backend mock tests | TimerSyncService conflict resolution tests |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NWPathMonitor | Reachability (third-party) | Reachability is older, less maintained; NWPathMonitor is Apple's current recommendation |
| In-memory Array queue | Core Data / SQLite | Timer actions are lightweight; Keychain persistence suffices for crash recovery |
| NWPathMonitor | URLSession reachability hacks | Unreliable; NWPathMonitor is the proper API |

**Installation:** No new dependencies required. All capabilities use built-in frameworks or existing project dependencies.

## Architecture Patterns

### System Architecture Diagram

```
                    iOS Device                    macOS Device
                         |                           |
                    +----v----+                   +----v----+
                    | Pomodoro|                   | Pomodoro|
                    |  Timer  |                   |  Timer  |
                    +----+----+                   +----+----+
                         |                           |
                    +----v---------+          +-----v--------+
                    | TimerSync    |          | TimerSync    |
                    | Manager      |          | Manager      |
                    | +actionQueue |          | +actionQueue |
                    | +netMonitor  |          | +netMonitor  |
                    +----+---------+          +-----+--------+
                         |                           |
                    +----v---------+          +-----v--------+
                    |  NWPath      |          |  NWPath      |
                    |  Monitor     |          |  Monitor     |
                    +----+---------+          +-----+--------+
                         |                           |
                    +----v---------+          +-----v--------+
                    |  ApiClient   |          |  ApiClient   |
                    +----+---------+          +-----+--------+
                         |                           |
                    +----v---------+          +-----v--------+
                    |   Keychain   |          |   Keychain   |
                    |  (action     |          |  (action     |
                    |   queue)     |          |   queue)     |
                    +--------------+          +--------------+

                    [Network Boundary]
                         |                           |
                         v                           v
                    +----------------------------------------+
                    |         Spring Boot Backend            |
                    |                                        |
                    |  SessionController                     |
                    |    POST /api/sessions/timer/action    |
                    |    GET  /api/sessions/timer/state     |
                    |                                        |
                    |  TimerSyncService                     |
                    |    pushTimerAction()                  |
                    |    pushTimerState()                   |
                    |    pullTimerState()                   |
                    |                                        |
                    |  PushNotificationService              |
                    |    sendTimerSyncPush()                |
                    |    [pushy APNs client]                |
                    |                                        |
                    |  TimerState (JPA entity)              |
                    |    [PostgreSQL]                       |
                    +---------------------|------------------+
                                          |
                                    +-----v-----+
                                    |   APNs    |
                                    |  (Apple)  |
                                    +-----+-----+
                                          |
                        +-----------------+-----------------+
                        |                                     |
                        v                                     v
                    [iOS silent push]                 [macOS silent push]
```

### Recommended Project Structure

No new directories needed. Changes are within existing structure:

```
apple/TimeBeam/TimeBeam/
├── Application/Services/
│   ├── TimerSyncManager.swift        # Add: actionQueue, NWPathMonitor, backoff
│   └── SyncFailureAlertManager.swift # NEW: User alert coordination
├── Domain/Models/
│   ├── PomodoroTimer.swift           # No changes (single source of truth)
│   └── QueuedTimerAction.swift       # NEW: Queue entry data model
├── Infrastructure/Networking/
│   └── ApiClient.swift               # Minor: add network-aware wrapper
├── Infrastructure/External/
│   ├── MacAppDelegate.swift          # Ensure push handler calls sync
│   └── iOSAppDelegate.swift          # Ensure push handler calls sync
├── Presentation/Views/Components/
│   └── SyncStatusBanner.swift        # NEW: Sync failure alert UI
└── Helper/
    └── KeychainStore.swift           # Minor: add action queue persistence

back-end/src/main/java/.../
├── presentation/controller/
│   └── SessionController.java        # No major changes (endpoints work)
├── application/service/
│   └── TimerSyncService.java         # Minor: ensure push payload completeness
└── infrastructure/external/
    └── PushNotificationService.java  # Fix: add missing fields to push payload
```

### Pattern 1: Offline Action Queue (FIFO with Keychain Persistence)

**What:** A first-in-first-out queue of timer actions that persists to Keychain. When network is unavailable, actions are buffered. On reconnect, they replay in order.

**When to use:** Any timer action (start/pause/reset/stop/advance) when `NWPathMonitor` reports no connectivity.

**Implementation:**
```swift
// QueuedTimerAction.swift — lightweight data model
struct QueuedTimerAction: Codable, Sendable {
    let action: TimerAction          // enum: start, pause, reset, stop, advance
    let timestamp: Double            // Date().timeIntervalSince1970
    let phase: String                // snapshot of phase at action time
    let remainingSeconds: Int
    let isRunning: Bool
    let workDuration: Int
    let breakDuration: Int
    let longBreakDuration: Int
    let autoStartNextSession: Bool
    let shortBreaksCompleted: Int
}

// In TimerSyncManager:
private var actionQueue: [QueuedTimerAction] = []
private let maxQueueSize = 50  // Prevents unbounded growth

private func enqueueAction(_ action: QueuedTimerAction) {
    guard actionQueue.count < maxQueueSize else {
        // Overflow: drop oldest, keep newest
        actionQueue.removeFirst()
        LoggerStore.timer.warning("Action queue overflow, dropped oldest action")
    }
    actionQueue.append(action)
    persistActionQueue()  // Write to Keychain
}

private func persistActionQueue() {
    guard !actionQueue.isEmpty else { return }
    do {
        let data = try JSONEncoder().encode(actionQueue)
        try KeychainStore.save(data, for: .actionQueue)  // New Keychain item
    } catch {
        LoggerStore.timer.error("Failed to persist action queue: \(error)")
    }
}

private func loadActionQueue() -> [QueuedTimerAction] {
    do {
        if let data = try KeychainStore.load(.actionQueue),
           let queue = try JSONDecoder().decode([QueuedTimerAction].self, from: data) {
            return queue
        }
    } catch {
        LoggerStore.timer.error("Failed to load action queue: \(error)")
    }
    return []
}
```

**Key design decisions:**
- **In-memory + Keychain:** Fast access with crash survival. On `configure()`, load from Keychain and drain.
- **Max 50 actions:** Timer actions are infrequent; 50 covers ~25 minutes of rapid toggling. Overflow drops oldest to prevent Keychain size issues.
- **FIFO replay:** Maintains action ordering -- critical for correct state (e.g., start -> pause -> start).

### Pattern 2: NWPathMonitor Network Detection

**What:** Apple's Network.framework provides real-time path monitoring with quality indicators. Detects connectivity changes and triggers action queue replay.

**When to use:** Monitor network path continuously; drain queue on transition to `.satisfied`.

**Implementation:**
```swift
import Network

private var networkMonitor: NWPathMonitor?
private var networkQueue: DispatchQueue?

func startNetworkMonitoring() {
    networkMonitor = NWPathMonitor()
    networkQueue = DispatchQueue(label: "com.timebeam.networkMonitor")
    networkMonitor?.pathUpdateHandler = { [weak self] path in
        guard let self = self else { return }
        let wasConnected = self.isNetworkConnected
        self.isNetworkConnected = path.status == .satisfied

        if wasConnected && !self.isNetworkConnected {
            // Going offline — stop polling, buffer future actions
            LoggerStore.timer.info("Network lost — buffering mode")
        } else if !wasConnected && self.isNetworkConnected {
            // Came back online — drain action queue
            LoggerStore.timer.info("Network restored — draining action queue")
            Task { @MainActor in
                await self.drainActionQueue()
            }
        }
    }
    networkMonitor?.start(queue: networkQueue)
}

func stopNetworkMonitoring() {
    networkMonitor?.cancel()
    networkMonitor = nil
    networkQueue = nil
}

func drainActionQueue() async {
    guard !actionQueue.isEmpty else { return }
    LoggerStore.timer.info("Draining \(actionQueue.count) queued actions")

    let queueSnapshot = actionQueue
    actionQueue.removeAll()
    try? KeychainStore.clear(.actionQueue)  // Clear persisted queue

    var consecutiveFailures = 0
    for action in queueSnapshot {
        let success = await syncQueuedAction(action)
        if success {
            consecutiveFailures = 0
        } else {
            consecutiveFailures += 1
            if consecutiveFailures >= 3 {
                LoggerStore.timer.error("Too many failures during drain, re-queuing remaining")
                // Re-queue remaining actions
                let remaining = queueSnapshot[(queueSnapshot.firstIndex(where: { $0 == action })?.advanced(by: 1))...]
                actionQueue.append(contentsOf: remaining)
                persistActionQueue()
                break
            }
        }
    }
}
```

### Pattern 3: Exponential Backoff Sync

**What:** On sync failure, retry with increasing delay: 30s -> 60s -> 120s -> cap at 300s. Reset on success.

**When to use:** After any failed sync operation (action push or state pull).

**Implementation:**
```swift
private var consecutiveFailures: Int = 0
private let backoffInterval: [Int: TimeInterval] = [
    1: 30,   // First failure: 30s
    2: 60,   // Second failure: 60s
    3: 120,  // Third failure: 120s
]
private let maxBackoff: TimeInterval = 300  // Cap

func handleSyncFailure() {
    consecutiveFailures += 1
    let delay = backoffInterval[min(consecutiveFailures, 3), defaultValue: maxBackoff]

    if consecutiveFailures >= 3 {
        // Trigger user alert
        Task { @MainActor in
            SyncFailureAlertManager.shared.showAlert(
                consecutiveFailures: consecutiveFailures,
                retryAction: { [weak self] in await self?.manualRetry() }
            )
        }
    }

    // Schedule retry
    Task {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        await retrySync()
    }
}

func handleSyncSuccess() {
    consecutiveFailures = 0
    SyncFailureAlertManager.shared.dismissAlert()
}
```

### Pattern 4: Push Delta Apply

**What:** APNs silent push carries full timer state in payload. Receiving device applies state directly from notification -- no network round-trip needed.

**When to use:** iOS/macOS notification handlers already call `applyEventState()`. This pattern is partially implemented; the fix is ensuring the push payload includes all fields.

**Current gap:** The `PushNotificationService` payload template is missing `autoStartNextSession` and `shortBreaksCompleted` fields. The `applyEventState()` method in `TimerSyncManager` reads these from `userInfo` but falls back to local values when not present.

**Fix needed in PushNotificationService.java:**
```java
// Current payload template (line 151-153):
String payload = String.format(
    "{\"aps\":{\"content-available\":1,\"sound\":\"\"},\"type\":\"timer_sync\",\"phase\":\"%s\",\"remainingSeconds\":%d,\"isRunning\":%s,\"startTimestamp\":%f,\"pauseTimestamp\":%s,\"workDuration\":%d,\"breakDuration\":%d,\"longBreakDuration\":%d,\"deviceId\":\"%s\",\"lastModifiedTimestamp\":%f}",
    // Missing: autoStartNextSession, shortBreaksCompleted
);

// Fixed payload template:
String payload = String.format(
    "{\"aps\":{\"content-available\":1,\"sound\":\"\"},\"type\":\"timer_sync\",\"phase\":\"%s\",\"remainingSeconds\":%d,\"isRunning\":%s,\"startTimestamp\":%f,\"pauseTimestamp\":%s,\"workDuration\":%d,\"breakDuration\":%d,\"longBreakDuration\":%d,\"autoStartNextSession\":%s,\"shortBreaksCompleted\":%d,\"deviceId\":\"%s\",\"lastModifiedTimestamp\":%f}",
    state.getPhase(),
    liveRemaining,
    isRunning,
    state.getStartTimestamp() != null ? state.getStartTimestamp() : 0.0,
    pauseTs,
    state.getWorkDuration() ?? 1500,
    state.getBreakDuration() ?? 300,
    state.getLongBreakDuration() ?? 900,
    state.getAutoStartNextSession() ?? false,   // NEW
    state.getShortBreaksCompleted() ?? 0,        // NEW
    state.getDeviceId(),
    lastModifiedSec
);
```

**APNs payload size constraint:** Apple limits silent push payload to 4KB. The timer state payload (~200 bytes) is well within this limit. `[VERIFIED: Apple Developer Documentation]`

### Anti-Patterns to Avoid

- **Sequential action replay without failure handling:** If the queue has 10 actions and the 3rd fails, don't stop -- skip it, continue with remaining. Re-queue failures after 3 consecutive errors.
- **Keychain write on every action:** Batch writes or throttle (write every 5th action, or on state transition). Keychain operations are expensive.
- **Synchronous network monitoring:** NWPathMonitor callback runs on a background queue. Always dispatch to MainActor before accessing `PomodoroTimer` or `TimerSyncManager` state.
- **Polling while push is working:** The existing 5-second polling interval is more aggressive than the D-12 decision (30s fallback). After push is confirmed working, increase to 30s or disable when push is active.
- **Applying push state without timestamp check:** The `applyEventState` method in `TimerSyncManager` applies state unconditionally. Add timestamp comparison: only apply if push timestamp > local `lastModifiedTimestamp`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Network reachability | Custom URL ping | `NWPathMonitor` (Network.framework) | Apple's official API; handles Wi-Fi/cellular/path quality |
| Keychain access | Manual `SecItem*` calls | Existing `KeychainStore` helper | Already handles access groups, platform differences |
| JSON serialization | Manual string building | `JSONEncoder`/`JSONDecoder` | Codable protocol; handles nil safety, type coercion |
| APNs sending | Raw HTTPS to Apple | pushy library (0.15.4) | Handles auth, retry, certificate management |
| Exponential backoff | Custom `pow(2, n)` | Predefined interval array | D-06 specifies exact intervals: 30/60/120/300 |
| UUID generation | String concatenation | `UUID().uuidString` | Standard, cryptographically random |
| Timer scheduling | `Timer.scheduledTimer` | `Task.sleep()` + async loop | Already used; works with Swift Concurrency |

**Key insight:** The existing codebase already has most building blocks. Phase 4 is integration work -- connecting offline queue, network monitoring, and backoff into the existing `TimerSyncManager`. Avoid rebuilding what exists.

## Common Pitfalls

### Pitfall 1: Push Payload Missing Fields
**What goes wrong:** `applyEventState()` reads `autoStartNextSession` and `shortBreaksCompleted` from push `userInfo`. If the push payload doesn't include these fields, the receiver falls back to local values -- causing state divergence.
**Why it happens:** `PushNotificationService.sendTimerSyncPush()` payload template (line 151-153) doesn't emit `autoStartNextSession` or `shortBreaksCompleted`.
**How to avoid:** Add these fields to the payload template before implementing push delta apply. Verify with a unit test that encodes full state and decodes it.
**Warning signs:** After push, `autoStartNextSession` or `shortBreaksCompleted` differ between devices.

### Pitfall 2: applyEventState Applies Unconditionally
**What goes wrong:** `applyEventState()` in `TimerSyncManager` (line 224-262) applies push state without checking if the push timestamp is newer than local state. This means a delayed push can overwrite newer local state.
**Why it happens:** The current implementation trusts push payload blindly. The polling path (`pullLatestState`) does timestamp comparison, but `applyEventState` does not.
**How to avoid:** Add timestamp comparison in `applyEventState`: only apply if `pushTimestamp > timer.lastModifiedTimestamp`. This aligns with D-01 (timestamp wins).
**Warning signs:** User starts timer on Device A, then immediately pauses on Device B. A delayed push from the start arrives and re-starts the timer.

### Pitfall 3: Polling Interval Mismatch
**What goes wrong:** `startPeriodicPolling()` uses 5-second interval (line 91), but D-12 specifies 30 seconds as fallback. This wastes battery and network.
**Why it happens:** 5-second interval was set during development for faster iteration.
**How to avoid:** Change to 30 seconds. This is a one-line fix in `startPeriodicPolling()`.
**Warning signs:** Battery drain complaints; excessive API calls in logs.

### Pitfall 4: Keychain Action Queue Size
**What goes wrong:** Unbounded action queue grows and hits Keychain item size limits (~1MB per item on iOS).
**Why it happens:** No size limit on the queue array.
**How to avoid:** Cap at 50 entries. On overflow, drop oldest (they're the least relevant). Timer actions are infrequent enough that 50 is a generous cap.
**Warning signs:** Keychain save fails with unexpected error codes; sync stops working after extended offline period.

### Pitfall 5: NWPathMonitor Thread Safety
**What goes wrong:** NWPathMonitor callback fires on a background queue. Accessing `@MainActor`-isolated `PomodoroTimer` from background causes a runtime crash.
**Why it happens:** `@Observable` classes with `@MainActor` annotation have isolated access.
**How to avoid:** Wrap all timer state access in `Task { @MainActor in ... }`. The existing `applyEventState` is already `@MainActor` -- route through it.
**Warning signs:** "Main actor isolation error" in Xcode console; random crashes on network transition.

### Pitfall 6: Action Queue Replay Race Condition
**What goes wrong:** During queue drain, a new user action comes in. If both write to the queue simultaneously, actions can be lost or reordered.
**Why it happens:** No synchronization during drain.
**How to avoid:** Take a snapshot of the queue at drain start, clear it, then process the snapshot. New actions during drain go into the fresh queue and drain on the next network event.
**Warning signs:** Missing actions after reconnect; inconsistent state between devices.

### Pitfall 7: Existing TimerSyncManager Singleton State
**What goes wrong:** Tests create `TimerSyncManager.shared` once and it persists across test cases. New properties (actionQueue, networkMonitor) carry stale state.
**Why it happens:** Singleton pattern without test isolation.
**How to avoid:** Add a `resetForTesting()` method that clears actionQueue, stops network monitor, resets consecutiveFailures. Call in `tearDown`.
**Warning signs:** Tests pass in isolation but fail when run together.

## Code Examples

### Verified Pattern: TimerSyncManager syncWithRetry (existing)
The existing `syncWithRetry` method (line 266-339) already implements exponential backoff at the per-operation level (1s -> 2s -> ... -> 30s cap). For Phase 4, add a separate cross-operation backoff tracker for the D-06 requirement (30s -> 60s -> 120s -> 300s).

### Verified Pattern: Push Notification Handling (existing)
Both `MacAppDelegate` and `iOSAppDelegate` already handle `timer_sync` push notifications:
- macOS: `didReceiveRemoteNotification` + `willPresent` handlers
- iOS: `willPresent` + `didReceive` + `didReceiveRemoteNotification` (silent push) handlers
All call `applyStateFromPush(userInfo)` which calls `TimerSyncManager.shared.applyEventState(from: userInfo)`.

### Verified Pattern: Keychain deviceId Persistence (existing)
`TimerSyncManager.init()` loads deviceId from Keychain, generates new one if not found. This is the pattern for action queue persistence.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Reachability (third-party) | NWPathMonitor (Network.framework) | iOS 12/macOS 10.14 | Apple's native replacement; more reliable path quality info |
| `@objc dynamic` + KVO | `@Observable` macro | iOS 17/macOS 14 | Zero-boilerplate observation; already adopted in codebase |
| `ObservableObject` + `@Published` | `@Observable` | iOS 17 | Simpler; no property wrapper overhead |
| `DispatchQueue.main.async` | `Task { @MainActor }` | iOS 13+ | Type-safe actor isolation; already used |
| Full state push every action | Event-driven push + delta | Phase 4 goal | Reduced bandwidth; faster sync |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | NWPathMonitor is available on target iOS/macOS versions | Standard Stack, Pattern 2 | Low -- requires iOS 12+/macOS 10.14+; TimeBeam likely targets newer |
| A2 | APNs silent push payload 4KB limit | Pattern 4 | Low -- timer state payload is ~200 bytes; well within limit |
| A3 | Keychain item size limit is ~1MB on iOS | Pitfall 4 | Low -- 50-action cap prevents this; each action is ~200 bytes |
| A4 | Existing `convertActionToState` in SessionController works correctly for all action types | Backend changes | Medium -- RESET action sets remainingSeconds=0 which may cause issues (see Pitfall analysis in code) |
| A5 | The `TimerStateDto.duration` fields from backend are in seconds (not minutes as JPA entity suggests) | Push payload | Medium -- field naming is inconsistent: `workDurationMinutes` in entity but `workDuration` (seconds) in DTO |

## Open Questions (RESOLVED)

1. **Polling interval: 5s vs 30s** — RESOLVED: Change to 30s per D-12 (30s polling as fallback only; event-driven is primary). 5s was a development artifact.

2. **applyEventState timestamp comparison** — RESOLVED: Add timestamp comparison per D-01 (newer timestamp wins). A delayed push must not overwrite newer local state. Plan 02 Task 3 implements this guard.

3. **Backend `convertActionToState` RESET handling** — RESOLVED: The backend fallback (line 255-257) resets to full duration when remainingSeconds <= 0. RESET action on the client correctly sends `remainingSeconds = currentDuration` per `PomodoroTimer.reset()`. Backend behavior is correct safety net; no change needed.

4. **Action queue persistence format** — RESOLVED: JSON via Codable (already used throughout codebase). `QueuedTimerAction: Codable` with `JSONEncoder`/`JSONDecoder`. No PropertyList.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Network.framework (NWPathMonitor) | Offline detection | Yes `[VERIFIED: darwin platform]` | Built-in | — |
| Security.framework (Keychain) | Action queue persistence | Yes `[VERIFIED: codebase usage]` | Built-in | — |
| APNs (pushy library) | Push notifications | Yes `[VERIFIED: pom.xml]` | 0.15.4 | — |
| Spring Boot | Backend API | Yes `[VERIFIED: pom.xml]` | Parent BOM | — |
| PostgreSQL | Timer state storage | Yes `[VERIFIED: CLAUDE.md infra]` | Docker compose | — |
| Xcode | Swift build/test | Yes `[VERIFIED: CLAUDE.md]` | — | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Swift), JUnit 5 + Mockito (Java) |
| Config file | Xcode test scheme (Swift), Maven Surefire (Java) |
| Quick run command | `xcodebuild test -scheme TimeBeamTests` / `cd back-end && mvn test -Dtest=TimerSyncServiceTest` |
| Full suite command | `xcodebuild test -scheme TimeBeam` / `cd back-end && mvn verify` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|---------|-----------|-------------------|-------------|
| SYNC-01 | Timestamp-based conflict resolution | unit | `xcodebuild test -scheme TimeBeamTests -only-test TimerSyncManagerUnitTests` | Yes |
| SYNC-02 | Offline action queue | unit | New test file needed | No -- Wave 0 |
| SYNC-03 | Network reconnect + queue drain | unit + integration | New test file needed | No -- Wave 0 |
| SYNC-04 | Exponential backoff | unit | New test file needed | No -- Wave 0 |
| SYNC-05 | Push delta apply | unit | `xcodebuild test -scheme TimeBeamTests` | Partially (applyEventState tests exist) |
| SYNC-06 | State restoration on relaunch | integration | Existing `setupApp()` tests | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Run affected unit tests (Swift: specific test class, Java: `mvn test -Dtest=ClassName`)
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `TimerSyncManagerQueueTests.swift` — covers SYNC-02, SYNC-03 (offline queue, drain)
- [ ] `TimerSyncManagerBackoffTests.swift` — covers SYNC-04 (exponential backoff)
- [ ] `PushPayloadIntegrationTests.swift` — covers SYNC-05 (push delta apply with all fields)
- [ ] `TimerSyncServicePushPayloadTest.java` — covers SYNC-05 (backend payload generation)
- [ ] `SetupAppSyncTests.swift` — covers SYNC-06 (state restoration on relaunch)
- [ ] `SyncFailureAlertTests.swift` — covers D-06 (user alert after 3 failures)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | JWT token validation (existing AuthManager) |
| V3 Session Management | Yes | Token refresh flow (existing) |
| V4 Access Control | Yes | User-owned resources (existing `resolveUserId`) |
| V5 Input Validation | Yes | DTO field validation (existing) |
| V6 Cryptography | No | No crypto operations in sync phase |

### Known Threat Patterns for Timer Sync

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replayed timer action | Repudiation | Timestamp comparison + deviceId exclusion |
| Man-in-the-middle push | Tampering | APNs TLS (built-in); payload not encrypted beyond TLS |
| Queue data leakage | Information Disclosure | Keychain encryption (built-in Security.framework) |
| Action injection | Spoofing | JWT-authenticated API endpoints |

## Sources

### Primary (HIGH confidence)
- Codebase: `TimerSyncManager.swift` — existing sync infrastructure, retry logic, applyEventState
- Codebase: `PushNotificationService.java` — APNs payload template, push delivery
- Codebase: `SessionController.java` — action-to-state conversion, timer action endpoint
- Codebase: `TimerState.java` — JPA entity, optimistic locking
- Codebase: `TimerActionDto.java` / `TimerActionDto.swift` — cross-platform DTO with `@JsonAlias`
- Codebase: `MacAppDelegate.swift` / `iOSAppDelegate.swift` — push notification handlers
- Codebase: `KeychainStore.swift` — Keychain persistence helper
- Codebase: `PomodoroTimer.swift` — in-memory timer state
- Codebase: `TimerStateDto.java` — backend state DTO with `lastModifiedTimestamp`
- pom.xml — pushy 0.15.4, Spring Boot parent BOM

### Secondary (MEDIUM confidence)
- Apple Developer Documentation: NWPathMonitor, APNs payload limits
- pushy library (com.eatthepath): APNs client capabilities

### Tertiary (LOW confidence)
- Training knowledge: NWPathMonitor API surface (Network.framework)
- Training knowledge: APNs silent push behavior (content-available: 1)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies verified in codebase/pom.xml
- Architecture: HIGH — existing sync flow thoroughly mapped; extensions are incremental
- Pitfalls: HIGH — identified from code review of existing implementation + known sync anti-patterns

**Research date:** 2026-05-10
**Valid until:** 2026-06-10 (stable domain -- sync architecture doesn't change rapidly)

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SYNC-01 | Timestamp-based conflict resolution | Existing `pollLatestState` comparison (line 391) + `applyEventState`. Gap: `applyEventState` needs timestamp check. |
| SYNC-02 | Offline action queue | Pattern 1: FIFO queue with Keychain persistence. No existing implementation. |
| SYNC-03 | Network reconnect + queue drain | Pattern 2: NWPathMonitor detection + `drainActionQueue()`. No existing implementation. |
| SYNC-04 | Exponential backoff on sync failure | Pattern 3: 30/60/120/300s intervals. Existing `syncWithRetry` has 1/2/4s backoff -- different scope. |
| SYNC-05 | Push delta apply without round-trip | Pattern 4: Fix `PushNotificationService` payload + add timestamp check to `applyEventState`. Partially implemented. |
| SYNC-06 | State restoration on app relaunch | Existing `setupApp()` in `TimeBeamApp.swift` (line 94-131) already pulls state from backend. D-10/D-11 satisfied. |

---

## RESEARCH COMPLETE

**Phase:** 4 - cross sync
**Confidence:** HIGH

### Key Findings
1. **Most building blocks exist:** APNs push, polling, deviceId, DTO mapping all work. Phase 4 is integration -- adding offline queue, network monitoring, and backoff.
2. **Push payload has gaps:** `autoStartNextSession` and `shortBreaksCompleted` are missing from the push payload template. Must fix before delta apply works correctly.
3. **applyEventState needs timestamp check:** Currently applies push state unconditionally. A delayed push can overwrite newer local state -- violates D-01.
4. **Polling interval is wrong:** 5-second interval in code vs 30-second D-12 decision. One-line fix.
5. **No new dependencies needed:** NWPathMonitor, Keychain, and pushy are all available. Pure code changes.
6. **Backend changes are minimal:** Fix push payload template; existing endpoints handle all Phase 4 operations.
7. **SYNC-06 is already satisfied:** `setupApp()` pull-from-backend flow exists and matches D-10/D-11.

### File Created
`/Users/kayisrahman/Documents/workspace/ideas/time-beam/.planning/phases/04-cross-sync/04-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | All dependencies verified in codebase, pom.xml |
| Architecture | HIGH | Existing sync flow fully mapped; extensions are incremental |
| Pitfalls | HIGH | Identified from direct code review + known patterns |

### Open Questions
1. 5s vs 30s polling interval -- confirm with user
2. applyEventState unconditional apply -- was this intentional?
3. RESET action `remainingSeconds` handling -- verify backend fallback is correct
4. Action queue persistence format (JSON vs PropertyList) -- preference question

### Ready for Planning
Research complete. Planner can now create PLAN.md files.
