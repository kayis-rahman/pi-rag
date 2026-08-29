---
phase: 04
plan: 02
subsystem: cross-device-sync
tags: [offline-queue, timestamp-resolution, push-payload-fields]
duration: 45 minutes
completed_date: 2026-05-11
dependency_graph:
  requires: [SYNC-01 (Phase 01), async/await infrastructure]
  provides: [action-queue-model, offline-buffering, timestamp-comparison, payload-field-reading]
  affects: [Plan 03 (NWPathMonitor drain), Plan 04 (device tracking), Timer sync flow]
tech_stack:
  added: [QueuedTimerAction model, Codable+Sendable, Keychain persistence]
  patterns: [action queue, timestamp-based conflict resolution, push payload parsing]
key_files:
  created:
    - apple/TimeBeam/TimeBeam/Domain/Models/QueuedTimerAction.swift
    - apple/TimeBeam/TimeBeamTests/UnitTests/Models/QueuedTimerActionUnitTests.swift
    - apple/TimeBeam/TimeBeamTests/UnitTests/TimerSyncManagerActionQueueTests.swift
    - apple/TimeBeam/TimeBeamTests/UnitTests/ApplyEventStateTests.swift
  modified:
    - apple/TimeBeam/TimeBeam/Helper/KeychainStore.swift (added .actionQueue case)
    - apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift (action queue + applyEventState fixes)
decisions:
  - Enqueue API: instance method on shared TimerSyncManager (not static) to support testing
  - Max queue size: 50 actions (configured constant, droppable on overflow)
  - Keychain persistence: JSON encoding, loaded on configure(), drain trigger in Plan 03
  - Payload field reading: Direct from userInfo, no local timer fallback for auto-start/breaks
  - Timestamp guard: <= (not <) to handle edge case of equal timestamps (newer wins)
---

# Phase 4 Plan 2: Offline Action Queuing and Timestamp-Based Conflict Resolution

## Summary

Built offline action queuing infrastructure and fixed applyEventState to perform timestamp-based conflict resolution per D-01. When the network is unavailable, timer actions now buffer locally in a persistent queue (max 50 actions, Keychain-backed). On reconnect or app relaunch, queued actions are ready to replay to the backend (drain logic added in Plan 03). Additionally, applyEventState now compares push timestamps against local state — a delayed push will not overwrite newer local state. After Plan 01 adds autoStartNextSession and shortBreaksCompleted to the push payload, applyEventState reads these fields directly from the payload instead of falling back to local values.

## Tasks Completed

### Task 1: Create QueuedTimerAction model and add .actionQueue to KeychainStore

**Status:** Complete

- Created `QueuedTimerAction.swift` with Codable, Sendable conformance
- All 10 fields present: action, timestamp, phase, remainingSeconds, isRunning, workDuration, breakDuration, longBreakDuration, autoStartNextSession, shortBreaksCompleted
- Extended `KeychainStore.Item` enum with `case actionQueue = "com.timebeam.app.actionQueue"` following naming convention
- Added comprehensive unit tests:
  - Test 1: QueuedTimerAction encodes to JSON with all fields
  - Test 2: QueuedTimerAction decodes from JSON preserving all values
  - Test 3: KeychainStore .actionQueue round-trips save/load correctly
- macOS build succeeds

**Commits:**
- `45ed58b`: test(04-02): add QueuedTimerAction model and actionQueue case to KeychainStore

### Task 2: Add action queue infrastructure to TimerSyncManager

**Status:** Complete

- Added `actionQueue: [QueuedTimerAction]` property and `maxQueueSize = 50` constant
- Implemented `enqueueAction()`: appends to array, drops oldest if queue exceeds max (50), persists to Keychain
- Implemented `persistActionQueue()`: JSON encodes actionQueue, saves to KeychainStore with error handling
- Implemented `loadActionQueue()`: reads from Keychain, JSONDecodes, returns empty array on failure
- Implemented `clearActionQueue()`: removes from memory and Keychain
- Modified `configure()` to load persisted queue on startup (drain trigger will be added in Plan 03)
- Added comprehensive unit tests:
  - Test 1: enqueueAction adds to array and persists
  - Test 2: persistActionQueue encodes and saves
  - Test 3: loadActionQueue reads and decodes
  - Test 4: Queue respects maxQueueSize, drops oldest when exceeded
  - Test 5: configure() loads persisted queue on startup
  - Test 6: clearActionQueue removes from Keychain
- macOS build succeeds

**Commits:**
- `c579ebb`: feat(04-02): add action queue infrastructure to TimerSyncManager

### Task 3: Fix applyEventState with timestamp comparison and complete field reading

**Status:** Complete

- Added timestamp comparison guard: **skip apply if pushTimestamp <= timer.lastModifiedTimestamp** (D-01 — newer wins)
- Changed `autoStartNextSession` to read from userInfo payload: `let autoStartNextSession = userInfo["autoStartNextSession"] as? Bool ?? false`
- Changed `shortBreaksCompleted` to read from userInfo payload: `let shortBreaksCompleted = userInfo["shortBreaksCompleted"] as? Int ?? 0`
- Updated `applySyncedState()` call to use payload values instead of local timer fallback
- Added diagnostic logging: "⏭️ TIMER_SYNC_EVENT: Push timestamp X <= local Y — skipping"
- Added comprehensive unit tests:
  - Test 1: Skip apply when push timestamp is stale
  - Test 2: Apply when push timestamp is newer
  - Test 3: Read autoStartNextSession from payload (not timer fallback)
  - Test 4: Read shortBreaksCompleted from payload (not timer fallback)
  - Test 5: Skip apply when timestamps are equal
  - Test 6: Handle NSNumber types for numeric fields
- macOS build succeeds

**Commits:**
- `fa52b2d`: fix(04-02): implement timestamp comparison and payload field reading in applyEventState

### Task 4: Verify SYNC-06 — state restoration on relaunch via existing setupApp()

**Status:** Complete ✓ Verified

- Verified `TimeBeamApp.setupApp()` calls `authManager.restoreSession()` first (line 96)
- Verified `setupApp()` calls `ApiClient.shared.pullTimerState()` after auth restore (line 102)
- Verified `setupApp()` sets `isAppReady = true` as final step (line 130)
- SYNC-06 requirement is already satisfied by existing implementation
- No code changes needed — verification only

**Commits:**
- `400c951`: docs(04-02): verify SYNC-06 state restoration on relaunch

## Deviations from Plan

None — plan executed exactly as written. All requirements from must_haves truths and artifacts satisfied.

## Threat Mitigation Compliance

| Threat ID | Category | Component | Mitigation | Status |
|-----------|----------|-----------|-----------|--------|
| T-04-04 | Repudiation | applyEventState push apply | Timestamp comparison guard: pushTimestamp must exceed local lastModifiedTimestamp (D-01). Device exclusion via deviceId check prevents feedback loops. | ✓ Implemented |
| T-04-05 | Information Disclosure | actionQueue in Keychain | KeychainStore uses Security.framework with access group `425MSY8FLG.com.sparkage.time-beam`. iOS: kSecAttrAccessibleAfterFirstUnlock. Data is timer state (no PII, no credentials). | ✓ Verified |
| T-04-06 | Tampering | Delayed push overwriting newer state | Timestamp comparison in applyEventState rejects stale pushes. Even if a push is delayed or replayed, it cannot overwrite newer local state. | ✓ Implemented |

## Known Stubs

None — all features fully implemented with data sources wired.

## Architecture Notes

### Action Queue Flow (Offline Buffering)
1. When network unavailable, actions enqueued via `enqueueAction(QueuedTimerAction)` (called by UI or sync manager on network failure)
2. Queue persisted to Keychain (JSON array) on each enqueue
3. On app relaunch or network reconnect, `configure()` loads persisted queue into memory
4. **Plan 03 (NWPathMonitor)** will implement `drainActionQueue()` to replay queued actions to backend when network reconnects
5. Max queue size: 50 actions (FIFO drop oldest on overflow)

### Timestamp-Based Conflict Resolution (D-01)
1. **Local state** has `lastModifiedTimestamp` (Double, Unix epoch)
2. **Push payload** includes `lastModifiedTimestamp`
3. **applyEventState** compares: **if pushTimestamp <= local, skip apply** (local is newer or equal, keep it)
4. Only apply if push is strictly newer: `pushTimestamp > local`
5. Prevents delayed/replayed pushes from reverting to older state

### Payload Field Reading (D-07, D-08)
1. After Plan 01 adds `autoStartNextSession` and `shortBreaksCompleted` to push payload
2. **Before (Task 3)**: applyEventState read from local timer as fallback: `timer.autoStartNextSession`, `timer.shortBreaksCompleted`
3. **After (Task 3)**: applyEventState reads from userInfo payload: `userInfo["autoStartNextSession"]`, `userInfo["shortBreaksCompleted"]`
4. This ensures push payload is the source of truth for these fields, not local state

## Verification Checklist

- [x] QueuedTimerAction.swift exists as Codable, Sendable struct with all 10 fields
- [x] KeychainStore.Item enum includes .actionQueue case
- [x] TimerSyncManager has actionQueue array with enqueue, persist, load, clear methods
- [x] TimerSyncManager.configure() loads persisted queue from Keychain on startup
- [x] applyEventState compares push timestamp vs local lastModifiedTimestamp before applying
- [x] applyEventState reads autoStartNextSession and shortBreaksCompleted from push userInfo (not local timer)
- [x] macOS build succeeds: `xcodebuild -scheme "TimeBeam" -destination 'platform=macOS' build`
- [x] All grep-based artifact verification passing
- [x] SYNC-06 requirement verified satisfied by existing TimeBeamApp.setupApp() implementation

## Self-Check

- [x] QueuedTimerAction.swift exists (verified file creation)
- [x] KeychainStore.swift contains .actionQueue case (verified grep)
- [x] TimerSyncManager.swift contains action queue methods (verified grep)
- [x] applyEventState timestamp comparison present (verified grep)
- [x] applyEventState payload field reading present (verified grep)
- [x] All commits present in git log (verified 5 commits created/verified)

**Self-Check: PASSED** — All artifacts exist, all methods implemented, all tests defined, all commits in history, macOS build succeeds.

## Impact on Downstream Plans

### Plan 03: NWPathMonitor Integration (Drain Trigger)
- Action queue is now loaded and ready in `TimerSyncManager.actionQueue`
- Plan 03 will implement `drainActionQueue()` method that:
  - Iterates over `actionQueue`
  - Replays each action to backend via API
  - Clears queue on success
  - Handles partial success (some replay, some fail)

### Plan 04: Device Tracking (No Impact)
- Action queue is device-agnostic
- Device ID already tracked via `TimerSyncManager.deviceId`
- Queued actions will inherit device ID when replayed

### Timer Sync Flow
- `applyEventState()` now safe from stale push overwrites
- Payload fields autoStartNextSession, shortBreaksCompleted respected from source (backend)
- Cross-device sync conflict resolution working correctly

## References

- D-01: Timestamp comparison — newer wins
- D-04: Buffer actions locally when offline
- D-07: APNs delta apply with timestamp comparison
- D-08: Push payload includes lastModifiedTimestamp, autoStartNextSession, shortBreaksCompleted
- D-10: Pull timer state from backend on relaunch
- D-11: setupApp flow: restoreSession → pullTimerState → configure → isAppReady
- SYNC-01: Cross-device sync infrastructure (Phase 01)
- SYNC-02: APNs push notification handling (Phase 01)
- SYNC-06: State restoration on relaunch (verified in TimeBeamApp.setupApp)
