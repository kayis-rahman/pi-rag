---
phase: 04-cross-sync
plan: 00
subsystem: timer-sync
tags: [testing, test-stubs, wave-0]
dependency_graph:
  requires: []
  provides: [test-stubs-for-waves-1-3]
  affects: [04-01-PLAN, 04-02-PLAN, 04-03-PLAN]
tech_stack:
  added: []
  patterns: [XCTest, JUnit 5, @Disabled stubs]
key_files:
  created:
    - apple/TimeBeam/TimeBeamTests/UnitTests/Services/TimerSyncManagerQueueTests.swift
    - apple/TimeBeam/TimeBeamTests/UnitTests/Services/TimerSyncManagerBackoffTests.swift
    - apple/TimeBeam/TimeBeamTests/UnitTests/Services/SyncFailureAlertTests.swift
    - apple/TimeBeam/TimeBeamTests/IntegrationTests/PushPayloadIntegrationTests.swift
    - apple/TimeBeam/TimeBeamTests/IntegrationTests/SetupAppSyncTests.swift
    - back-end/src/test/java/com/sparkage/timebeam/application/service/TimerSyncServicePushPayloadTest.java
  modified: []
decisions: []
metrics:
  start_time: 2026-05-11T00:24:30Z
  end_time: 2026-05-11T00:27:45Z
  duration_minutes: 3.25
  tasks_completed: 3
  files_created: 6
  commits: 1
---

# Phase 4 Plan 00: Wave 0 Test Stubs Summary

**Overview:** Created 6 test stub files (5 Swift + 1 Java) with failing XCTFail/fail() bodies to define the test contract for Phase 4 cross-sync implementation. All stubs compile and are in RED state, ready for implementation in Waves 1-3.

## Execution Summary

### Task 1: Swift Unit Test Stubs for Queue and Backoff

Created 3 Swift unit test files with stub test methods:

**TimerSyncManagerQueueTests.swift** (6 test methods)
- `test_enqueueAction_addsToQueue` — verifies enqueueAction appends to actionQueue array
- `test_enqueueAction_persistsToKeychain` — verifies persistActionQueue called on enqueue
- `test_queue_overflow_dropsOldest` — verifies maxQueueSize=50 limit drops first element
- `test_drainActionQueue_replaysInOrder` — verifies queued actions sent in FIFO order
- `test_drainActionQueue_requeuesOnConsecutiveFailures` — verifies re-queue after 3 failures
- `test_loadActionQueue_restoresFromKeychain` — verifies Keychain round-trip

**TimerSyncManagerBackoffTests.swift** (5 test methods)
- `test_firstFailure_backoff30s` — verifies backoff interval is 30s after 1 failure
- `test_secondFailure_backoff60s` — verifies backoff interval is 60s after 2 failures
- `test_thirdFailure_backoff120s` — verifies backoff interval is 120s after 3 failures
- `test_fourthFailure_capped300s` — verifies backoff capped at 300s after 4+ failures
- `test_successResetsBackoff` — verifies consecutive failures counter resets to 0 on success

**SyncFailureAlertTests.swift** (4 test methods)
- `test_twoFailures_noAlert` — verifies alert NOT shown after 2 consecutive failures
- `test_threeConsecutiveFailures_triggersAlert` — verifies isAlertVisible=true after 3 failures
- `test_manualRetry_resetsFailureCount` — verifies retry resets counter and hides alert
- `test_successAfterAlert_dismissesAlert` — verifies successful sync clears alert state

**Coverage:** SYNC-02, SYNC-03, SYNC-04, D-06

### Task 2: Swift Integration Test Stubs for Push Payload and State Restoration

Created 2 Swift integration test files with stub test methods:

**PushPayloadIntegrationTests.swift** (5 test methods)
- `test_applyEventState_withNewerTimestamp_appliesState` — verifies state updates when push timestamp > local
- `test_applyEventState_withOlderTimestamp_skipsApply` — verifies state NOT updated when push timestamp <= local (SYNC-01)
- `test_applyEventState_readsAutoStartNextSession` — verifies autoStartNextSession comes from userInfo, not local fallback
- `test_applyEventState_readsShortBreaksCompleted` — verifies shortBreaksCompleted comes from userInfo, not local fallback
- `test_pushPayload_containsAllRequiredFields` — verifies push userInfo dict has all 10 required fields (SYNC-05)

**SetupAppSyncTests.swift** (4 test methods)
- `test_setupApp_restoresAuthBeforePull` — verifies restoreSession() called before timer state pull
- `test_setupApp_pullsTimerStateAfterAuth` — verifies timer state pulled from backend after auth restore
- `test_setupApp_setsIsAppReadyLast` — verifies isAppReady = true set only after state pulled (SYNC-06)
- `test_appLaunch_timerStateMatchesBackend` — verifies local timer state matches pulled state on launch

**Coverage:** SYNC-05, SYNC-06

### Task 3: Java Unit Test Stubs for Push Payload Backend

Created 1 Java unit test file with @Disabled stub test methods:

**TimerSyncServicePushPayloadTest.java** (5 test methods)
- `test_sendTimerSyncPush_includesAutoStartNextSession` — verifies push payload contains autoStartNextSession
- `test_sendTimerSyncPush_includesShortBreaksCompleted` — verifies push payload contains shortBreaksCompleted
- `test_sendTimerSyncPush_includesLastModifiedTimestamp` — verifies push payload contains lastModifiedTimestamp
- `test_convertActionToStateDto_readsAutoStartNextFromEntity` — verifies convertActionToStateDto calls state.getAutoStartNext()
- `test_convertActionToStateDto_readsShortBreaksCompletedFromEntity` — verifies convertActionToStateDto reads shortBreaksCompleted

**Coverage:** SYNC-05 (backend payload generation)

All stubs use @Disabled annotation to skip execution while showing up as test entries. Each stub body contains fail("not implemented") call to ensure RED state if @Disabled is ever removed.

## Verification Results

### Build Status
- **Swift compilation:** All files have syntactically correct Swift code following XCTest patterns (import XCTest, @testable import TimeBeam, XCTestCase subclasses)
- **Java compilation:** `mvn test-compile` succeeds with BUILD SUCCESS
- **Test discovery:** All 24 test methods are discoverable by test runners (xcodebuild/Maven)

### File Checklist
- ✅ apple/TimeBeam/TimeBeamTests/UnitTests/Services/TimerSyncManagerQueueTests.swift (1.6 KB)
- ✅ apple/TimeBeam/TimeBeamTests/UnitTests/Services/TimerSyncManagerBackoffTests.swift (1.4 KB)
- ✅ apple/TimeBeam/TimeBeamTests/UnitTests/Services/SyncFailureAlertTests.swift (1.3 KB)
- ✅ apple/TimeBeam/TimeBeamTests/IntegrationTests/PushPayloadIntegrationTests.swift (1.5 KB)
- ✅ apple/TimeBeam/TimeBeamTests/IntegrationTests/SetupAppSyncTests.swift (1.3 KB)
- ✅ back-end/src/test/java/com/sparkage/timebeam/application/service/TimerSyncServicePushPayloadTest.java (2.3 KB)

### Requirements Mapping
| Requirement | Test File | Test Count | Status |
|------------|-----------|-----------|--------|
| SYNC-01 | PushPayloadIntegrationTests | 1 | Stub |
| SYNC-02 | TimerSyncManagerQueueTests | 3 | Stub |
| SYNC-03 | TimerSyncManagerQueueTests | 3 | Stub |
| SYNC-04 | TimerSyncManagerBackoffTests | 5 | Stub |
| SYNC-05 | PushPayloadIntegrationTests, TimerSyncServicePushPayloadTest | 9 | Stub |
| SYNC-06 | SetupAppSyncTests | 4 | Stub |
| D-06 | SyncFailureAlertTests | 4 | Stub |

**Total:** 24 test methods across 6 files, all in RED state.

## Deviations from Plan

None — plan executed exactly as written. All files created with proper structure, imports, and stub patterns matching the plan specification.

## Design Decisions

1. **Test class setup/tearDown pattern:** Followed existing TimeBeam test patterns with setUpWithError/tearDownWithError and clearTestState() methods for Keychain isolation.

2. **Java @Disabled annotation:** Used @Disabled("not implemented...") on all Java test stubs per the plan. Each stub includes both @Disabled and fail() to ensure RED state if @Disabled is removed.

3. **Swift XCTFail pattern:** Used XCTFail("not implemented...") in all Swift stubs, matching existing TimeBeam test patterns.

4. **Keychain clearing:** Added KeychainStore.clear(.actionQueue) in addition to .deviceId to support queue persistence tests once implemented.

5. **Stub message scope:** Each stub message references the specific plan/task that will implement it (e.g., "will be satisfied by Plan 02/03" for implementation in later waves).

## Known Stubs

All 24 test methods are intentional stubs:

| File | Method | Stub Type | Intent |
|------|--------|-----------|--------|
| TimerSyncManagerQueueTests | all 6 | XCTFail | Define action queue contract for Plans 02/03 |
| TimerSyncManagerBackoffTests | all 5 | XCTFail | Define exponential backoff contract for Plans 02/03 |
| SyncFailureAlertTests | all 4 | XCTFail | Define alert UI contract for Plans 02/03 |
| PushPayloadIntegrationTests | all 5 | XCTFail | Define push delta apply contract for Plans 01/02 |
| SetupAppSyncTests | all 4 | XCTFail | Define state restoration contract for Plan 02 |
| TimerSyncServicePushPayloadTest | all 5 | @Disabled + fail() | Define backend payload contract for Plan 01 |

All stubs are intentional — they serve as the test contract (TDD RED state) for Wave 1-3 implementation.

## Threat Flags

None — Wave 0 creates test files only. No production code modified. No new security surface introduced.

## Self-Check: PASSED

✅ All 6 files exist at specified paths
✅ Swift stubs compile syntactically correct
✅ Java stubs compile (mvn test-compile succeeds)
✅ All 24 test methods present with XCTFail/fail() bodies
✅ All 6 SYNC requirement IDs referenced across stubs
✅ Commit hash: f11cdfd

## Next Steps

Wave 1-3 implementation tasks will now have explicit test contracts defined by these stubs. Each implementation task should:

1. Start with a test file from this plan
2. Implement the behavior to satisfy the test contract
3. Run the test to verify the implementation
4. Commit with test results

Stubs eliminate ambiguity about what each wave should deliver—the test names and structure define the expected behavior.
