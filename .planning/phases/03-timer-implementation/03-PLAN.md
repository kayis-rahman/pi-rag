---
phase: 03
wave: 0
title: Timer Implementation - Phase Plan
depends_on:
  - 01-01
  - 01-02
  - 01-03
  - 02-01
requirements_addressed:
  - TIMER-01
  - TIMER-02
  - TIMER-03
  - TIMER-04
files_modified:
  - apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift
  - apple/TimeBeam/TimeBeam/TimeBeamApp.swift
  - apple/TimeBeam/TimeBeam/Infrastructure/External/NotificationManager.swift
  - apple/TimeBeam/TimeBeamTests/UnitTests/PomodoroTimerUnitTests.swift
  - apple/TimeBeam/TimeBeam/Domain/Models/SessionRecord.swift
  - back-end/src/main/resources/db/migration/V1__create_initial_tables.sql
autonomous: true
---

# Phase 03: Timer Implementation

## Goal

Complete the Pomodoro timer by wiring the session completion flow, fixing broken tests, implementing notification preferences, creating new test coverage, and adding the missing Flyway migration.

## Must-Haves

- [ ] Timer countdown reaches zero and triggers session completion (phase advance, onSessionCompleted callback fires)
- [ ] onSessionCompleted callback wired in TimeBeamApp to record session and send notification
- [ ] Auto-advance to next phase works when autoStartNextSession is true
- [ ] NotificationManager respects soundEnabled and hapticsEnabled preferences
- [ ] All existing unit tests compile and pass (PomodoroTimerUnitTests fixed)
- [ ] New test coverage: session completion, duration config, session logger
- [ ] Flyway V1 migration creates all tables (users, sessions, timer_states, user_devices, tasks)
- [ ] PomodoroTimer 2-second pause guard prevents accidental immediate pause

## Tasks

### Wave 0: Fix Broken Tests

#### Task 0.1: Fix PomodoroTimerUnitTests — replace startFromSync and fix type mismatch

<action>
1. Replace `timer.startFromSync()` with `timer.start()` on lines 54 and 70 of PomodoroTimerUnitTests.swift
2. Fix line 87: change `timer.remainingSeconds = 1234.5` to `timer.remainingSeconds = 1234`
3. Fix line 90: change `XCTAssertEqual(timer.remainingSeconds, 1234.5)` to `XCTAssertEqual(timer.remainingSeconds, 1234)`
4. Add 2-second pause guard to PomodoroTimer.pause(): track `lastStartTime` and skip pause if less than 2 seconds elapsed since start
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeamTests/UnitTests/PomodoroTimerUnitTests.swift
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift (lines 80-94 for start() and pause() methods)
</read_first>

<acceptance_criteria>
- PomodoroTimerUnitTests.swift compiles with zero errors
- testPauseIgnoreWithin2Seconds passes: after start() + 0.5s pause, isRunning remains true
- testPauseExecuteAfter2Seconds passes: after start() + 2.5s pause, isRunning is false
- testRemainingSecondsDouble passes with integer value 1234
- testStartSetsTimestamps passes
- testPauseSetsTimestamps passes
- testProgressCalculation passes
</acceptance_criteria>

#### Task 0.2: Add 2-second pause guard to PomodoroTimer.pause()

<action>
1. Add a private property `private var lastStartTime: Double?` to PomodoroTimer
2. In start() at line 83, set `lastStartTime = Date().timeIntervalSince1970` after setting startTimestamp
3. In pause() at line 88, add guard: if `lastStartTime` is set and `Date().timeIntervalSince1970 - lastStartTime < 2.0`, return early (don't pause)
4. In reset(), set `lastStartTime = nil`
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift (lines 23-208)
</read_first>

<acceptance_criteria>
- PomodoroTimer.swift compiles
- pause() called within 2 seconds of start() returns without changing state
- pause() called after 2+ seconds of start() works normally (isRunning = false)
- reset() clears lastStartTime so new start() gets fresh guard window
</acceptance_criteria>

### Wave 1: Wire Session Completion

#### Task 1.1: Add handleTimerCompletion() to PomodoroTimer

<action>
1. After the while loop in startTimer() (line 178), add: `if remainingSeconds <= 0 { self.handleTimerCompletion() }`
2. Implement `handleTimerCompletion()` method after stopTimer() (after line 185):
   - Set `isRunning = false`
   - Set `pauseTimestamp = Date().timeIntervalSince1970`
   - Set `lastModifiedTimestamp = pauseTimestamp!`
   - Call `advance()` (which fires onSessionCompleted callback at line 128)
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift (lines 167-200)
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/SessionRecord.swift
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Application/Services/SessionLogger.swift
</read_first>

<acceptance_criteria>
- PomodoroTimer.swift compiles
- When countdown reaches zero, handleTimerCompletion() is called
- Phase advances: work -> break, break -> work, work (4th cycle) -> longBreak, longBreak -> work
- onSessionCompleted callback fires with correct previous phase and duration
- isRunning is false after completion
</acceptance_criteria>

#### Task 1.2: Wire onSessionCompleted callback in TimeBeamApp

<action>
1. In TimeBeamApp.swift, after timer and logger are declared (around line 23-24), add an onAppear modifier to the main content group that assigns the callback:
   - timer.onSessionCompleted = { completedPhase, duration in
     - Create SessionRecord with startedAt = Date().addingTimeInterval(-duration), duration = TimeInterval(duration), kind mapped from Phase
     - logger.add(record: record)
     - NotificationManager.shared.sendSessionDoneNotification(phase: completedPhase.rawValue)
   }
2. The callback is assigned in the iOS branch (around line 62) and macOS branch (around line 85) where .environment(timer) and .environment(logger) are set
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/TimeBeamApp.swift
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/SessionRecord.swift
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Application/Services/SessionLogger.swift
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Infrastructure/External/NotificationManager.swift
</read_first>

<acceptance_criteria>
- TimeBeamApp.swift compiles
- When timer completes, SessionLogger.records gets a new entry with correct kind (work/short_break/long_break)
- System notification fires with phase-appropriate message
- NotificationManager.sendSessionDoneNotification is called with correct phase string
</acceptance_criteria>

### Wave 2: Notification Preferences

#### Task 2.1: Respect soundEnabled and hapticsEnabled in NotificationManager

<action>
1. In sendSessionDoneNotification() (line 29), read preferences at top:
   - `let soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")`
   - `let hapticsEnabled = UserDefaults.standard.bool(forKey: "hapticsEnabled")`
2. Only set content.sound if `soundEnabled` is true
3. Only call triggerHapticIfNeeded() if `hapticsEnabled` is true
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Infrastructure/External/NotificationManager.swift
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Presentation/Views/iOS/SettingsView.swift (lines 8-9 for AppStorage keys)
</read_first>

<acceptance_criteria>
- NotificationManager.swift compiles
- With soundEnabled = false: notification fires without sound
- With hapticsEnabled = false: triggerHapticIfNeeded() is not called
- With both true: behavior unchanged (sound + haptics fire)
- UserDefaults keys match SettingsView @AppStorage keys ("soundEnabled", "hapticsEnabled")
</acceptance_criteria>

### Wave 3: New Test Files

#### Task 3.1: Create PomodoroTimerSessionTests

<action>
Create `/Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeamTests/UnitTests/PomodoroTimerSessionTests.swift` with:
1. test_advance_fromWork_toBreak() — verify phase work->break, shortBreaksCompleted increments, remainingSeconds = breakDuration
2. test_advance_fromBreak_toWork() — verify break->work, remainingSeconds = workDuration
3. test_advance_fromWork_toLongBreak_afterFourCycles() — verify 4th completion triggers longBreak
4. test_onSessionCompleted_fires_with_correct_phase_and_duration() — set callback, advance, verify callback received values
5. test_advance_fromLongBreak_toWork() — verify longBreak->work, resets shortBreaksCompleted
6. test_autoStartNextSession_property_exists_and_defaults() — verify default value
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeamTests/UnitTests/PomodoroTimerUnitTests.swift (existing test pattern)
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/SessionRecord.swift
</read_first>

<acceptance_criteria>
- PomodoroTimerSessionTests.swift compiles
- All 6 tests pass
- Covers all 3 phase transitions (work->break, break->work, work->longBreak)
- Tests the onSessionCompleted callback mechanism end-to-end
</acceptance_criteria>

#### Task 3.2: Create PomodoroTimerDurationTests

<action>
Create `/Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeamTests/UnitTests/PomodoroTimerDurationTests.swift` with:
1. test_default_workDuration_is_25_minutes() — verify 1500
2. test_default_breakDuration_is_5_minutes() — verify 300
3. test_default_longBreakDuration_is_15_minutes() — verify 900
4. test_updateDurations_sets_correct_seconds() — call updateDurations(workMinutes:30), verify workDuration = 1800
5. test_currentDuration_returns_correct_value_for_phase() — switch phase, verify currentDuration matches
6. test_progress_is_zero_when_full_remaining() — remainingSeconds = currentDuration -> progress = 0.0
7. test_progress_is_one_when_zero_remaining() — remainingSeconds = 0 -> progress = 1.0
8. test_cycleSize_is_four() — verify constant
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift (lines 33-36, 66-78, 187-200)
</read_first>

<acceptance_criteria>
- PomodoroTimerDurationTests.swift compiles
- All 8 tests pass
- Validates configurable durations map correctly to seconds
- Tests progress calculation edge cases
</acceptance_criteria>

#### Task 3.3: Create SessionLoggerTests

<action>
Create `/Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeamTests/UnitTests/SessionLoggerTests.swift` with:
1. test_add_createsRecord_and_storesInUserDefaults() — add record, verify records array has 1 entry
2. test_add_converts_to_correct_kind() — SessionRecord.Kind.work maps to "work" in DTO
3. test_clear_removes_all_records() — add 3, clear, verify count = 0
4. test_persistence_loads_fromUserDefaults_on_init() — pre-populate UserDefaults, verify records loaded
5. test_add_preserves_record_id() — verify UUID is preserved
6. test_add_preserves_started_at_timestamp() — verify Date is preserved
7. test_add_preserves_duration() — verify TimeInterval is preserved
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Application/Services/SessionLogger.swift
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam/TimeBeam/Domain/Models/SessionRecord.swift
</read_first>

<acceptance_criteria>
- SessionLoggerTests.swift compiles
- All 7 tests pass
- Tests local persistence and DTO conversion
- Tests clear() removes all records
</acceptance_criteria>

### Wave 4: Missing Flyway Migration

#### Task 4.1: Create V1 Flyway migration for initial tables

<action>
Create `/Users/kayisrahman/Documents/workspace/ideas/time-beam/back-end/src/main/resources/db/migration/V1__create_initial_tables.sql` with:
1. CREATE TABLE users (id UUID PK, email VARCHAR UNIQUE NOT NULL, display_name VARCHAR NOT NULL, is_admin BOOLEAN NOT NULL DEFAULT FALSE, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ)
2. CREATE TABLE sessions (id UUID PK, user_id UUID NOT NULL FK->users, started_at TIMESTAMPTZ, duration_seconds BIGINT, kind VARCHAR CHECK IN (work, short_break, long_break), created_at TIMESTAMPTZ)
3. CREATE TABLE timer_states (user_id UUID PK FK->users, phase VARCHAR, remaining_seconds INTEGER, running BOOLEAN DEFAULT FALSE, work/break/long_break_duration_minutes INTEGER, auto_start_next BOOLEAN DEFAULT FALSE, short_breaks_completed INTEGER, total_duration INTEGER, start_timestamp DOUBLE PRECISION, pause_timestamp DOUBLE PRECISION, last_updated_at TIMESTAMPTZ, updated_by_device_id UUID, version BIGINT DEFAULT 1)
4. CREATE TABLE user_devices (device_id UUID PK, user_id UUID NOT NULL FK->users, device_name VARCHAR, device_type VARCHAR, platform_version VARCHAR, app_version VARCHAR, fcm_token TEXT, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ)
5. CREATE TABLE tasks (id UUID PK, user_id UUID NOT NULL FK->users, title VARCHAR(255), description TEXT, status VARCHAR CHECK IN (todo, in_progress, completed), created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ)
6. Add indexes: idx_timer_states_last_updated, idx_tasks_user_deleted
7. Use IF NOT EXISTS for all CREATE TABLE statements (compatibility with ddl-auto: update)
</action>

<read_first>
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/back-end/src/main/resources/db/migration/V2__add_updated_at_to_user_devices.sql (existing migration pattern)
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/TimerState.java (JPA entity for column reference)
- /Users/kayisrahman/Documents/workspace/ideas/time-beam/back-end/src/main/resources/db/migration/V3__add_deleted_at_to_tasks.sql
</read_first>

<acceptance_criteria>
- V1 migration runs successfully on fresh database
- All 5 tables created: users, sessions, timer_states, user_devices, tasks
- Column names and types match JPA entity definitions
- V2 and V3 migrations still apply on top of V1 without conflict
- IF NOT EXISTS used on all CREATE TABLE for ddl-auto compatibility
- Migration runs: flyway migrate exits 0
</acceptance_criteria>

## Verification

1. **Unit tests**: Run `xcodebuild test -project apple/TimeBeam/TimeBeam.xcodeproj -scheme TimeBeam -destination 'platform=macOS' -only-testing:TimeBeamTests/PomodoroTimerUnitTests` — all pass
2. **New tests**: Run `xcodebuild test ... -only-testing:TimeBeamTests/PomodoroTimerSessionTests` — all pass
3. **New tests**: Run `xcodebuild test ... -only-testing:TimeBeamTests/PomodoroTimerDurationTests` — all pass
4. **New tests**: Run `xcodebuild test ... -only-testing:TimeBeamTests/SessionLoggerTests` — all pass
5. **Full suite**: Run `xcodebuild test -project apple/TimeBeam/TimeBeam.xcodeproj -scheme TimeBeam -destination 'platform=macOS'` — all tests pass
6. **Backend migration**: Run `cd back-end && docker compose -f docker-compose.dev.yml up -d postgres && mvn flyway:migrate` — exits 0
7. **Manual**: Start timer in iOS simulator, wait for completion, verify session appears in stats tab, notification fires
