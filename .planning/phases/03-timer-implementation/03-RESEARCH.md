# Phase 3: Timer Implementation - Research

**Researched:** 2026-05-11
**Domain:** Pomodoro timer UI, state management, session lifecycle, cross-platform SwiftUI
**Confidence:** HIGH

## Summary

Phase 03 research reveals that the Pomodoro timer implementation is largely complete but has critical gaps in the session lifecycle flow. The core timer engine (`PomodoroTimer`), UI components (`CircularTimerView`, `iOSContentView`, `macOSContentView`), settings UI (`SettingsView`), and timer sync infrastructure (`TimerSyncManager`) all exist and compile. However, the session completion mechanism -- the bridge between timer expiry and session recording/notifications -- is disconnected. The `onSessionCompleted` callback is defined in `PomodoroTimer` but never wired to any consumer. The `startTimer()` method reaches zero and stops without triggering auto-advance, session recording, or notification delivery.

The existing unit tests (`PomodoroTimerUnitTests.swift`) reference methods that do not exist in the current source (`startFromSync()`) and assert types that mismatch (`remainingSeconds` is `Int` but tests treat it as `Double`). These tests will fail to compile.

**Primary recommendation:** Wire the session completion callback, implement auto-advance on timer expiry, connect notification delivery, fix the existing unit tests, and ensure the timer lifecycle is coherent from start through session completion to recording.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **UI/UX:** Circular progress indicator for timer visualization
- **UI/UX:** Digital display for remaining time with clear visual hierarchy
- **UI/UX:** Consistent styling across iOS and macOS platforms
- **UI/UX:** Responsive design that adapts to different screen sizes
- **Behavior:** Configurable timer durations (work, short break, long break)
- **Behavior:** Standard Pomodoro cycle with customizable lengths
- **Behavior:** Auto-start behavior for next timer phase
- **Behavior:** Support for manual timer control (start, pause, reset, advance)
- **Technical:** Hybrid approach: Local state management with periodic synchronization
- **Technical:** Timer state stored locally with immediate sync on timer actions
- **Technical:** Cross-platform consistency with platform-specific UI adaptations
- **Technical:** Performance optimizations for real-time updates
- **Integration:** Event-based synchronization: Sync timer actions (start, pause, reset) immediately
- **Integration:** State synchronization: Full state sync at regular intervals (30+ seconds)
- **Integration:** Conflict resolution: Timestamp-based approach for collaborative control
- **Integration:** Device identification: Prevent feedback loops with device ID tracking
- **Notifications:** Multi-modal approach: Audio alerts AND visual notifications
- **Notifications:** Audio chime sounds for timer completion
- **Notifications:** Visual indicators (screen flashes, pop-ups) for timer transitions
- **Notifications:** System notifications for timer completion events

### Deferred Ideas (OUT OF SCOPE)
- Advanced timer analytics and statistics - Phase 5
- Timer customization beyond duration settings - Phase 5
- Third-party integration for timer management - Phase 6

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Timer countdown engine | Frontend (Swift Domain) | — | In-memory `PomodoroTimer` is single source of truth |
| Timer UI rendering | Frontend (Swift Presentation) | — | Platform-specific SwiftUI views |
| Session recording | Frontend (Swift Application) | API/Backend | Local `SessionLogger` records; backend stores via sync |
| Session completion notification | Frontend (Swift Infrastructure) | — | `NotificationManager` handles platform-native notifications |
| Audio chime playback | Frontend (Swift Presentation) | — | `AVAudioPlayer` in view layer |
| Timer state configuration | Frontend (Swift Presentation) | — | SettingsView steppers, macOS menu pickers |
| Auto-advance to next phase | Frontend (Swift Domain) | — | `PomodoroTimer.advance()` logic |
| Timer action sync | Frontend (Swift Application) -> API/Backend | — | `TimerSyncManager` pushes to backend endpoints |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+/macOS 14+ `[VERIFIED: codebase]` | Timer UI | Cross-platform native UI framework |
| @Observable macro | iOS 17+ `[VERIFIED: codebase]` | Timer state observation | Modern Swift concurrency; already used for `PomodoroTimer` |
| Swift Concurrency (Task/async) | iOS 16+ `[VERIFIED: codebase]` | Timer countdown | `Task.sleep` for 1-second tick interval |
| UserNotifications | Built-in framework | System notifications | `UNUserNotificationCenter` for session completion alerts |
| AVFoundation | Built-in framework | Audio chime | `AVAudioPlayer` for timer completion sound |
| CoreGraphics | Built-in framework | Circular progress | `Circle().trim()` for progress ring rendering |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | Built-in | Unit tests | PomodoroTimer state transitions, progress calculation |
| Combine | Built-in | (Not needed) | @Observable replaces KVO patterns |
| CloudKit | Built-in | iCloud sync | `iCloudSyncManager` already used for settings sync |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Task.sleep (1s tick) | Timer.publish (Combine) | Combine adds complexity; Task.sleep is simpler and already used |
| @Observable | ObservableObject + @Published | @Observable is iOS 17+ standard; no KVO boilerplate |
| UserNotifications | AudioToolbox SystemSound | SystemSound is simpler but lacks rich notifications and scheduling |

**Installation:** No new dependencies required. All frameworks are built-in to Xcode toolchain.

## Architecture Patterns

### System Architecture Diagram

```
User Action (tap Start/Pause/Reset/Advance)
    |
    v
SwiftUI View (iOSContentView / macOSContentView)
    |
    ├──> @Environment(PomodoroTimer.self)     Direct state mutation
    |       .start() / .pause() / .reset() / .advance()
    |
    └──> TimerSyncManager.shared              Sync to backend
            .syncTimerAction(action)
                |
                v
            ApiClient.pushTimerAction()  --->  Backend SessionController
                                                    .pushTimerAction()
                                                        |
                                                        v
                                                    TimerSyncService.pushTimerState()
                                                        |
                                                        v
                                                    PushNotificationService  --->  APNs ---> Other Devices
                                                                                       |
                                                                                       v
                                                           TimerSyncManager.applyEventState()
                                                           (on remote device)
```

### Recommended Project Structure

Existing structure (already in place, no reorganization needed):

```
apple/TimeBeam/TimeBeam/
├── Domain/Models/
│   ├── PomodoroTimer.swift        # Timer engine (state machine)
│   ├── SessionRecord.swift         # Domain model for completed sessions
│   ├── SessionRecordDto.swift      # API DTO for session records
│   ├── TimerStateDto.swift         # Sync DTO for timer state
│   ├── QueuedTimerAction.swift     # Offline action queue entry
│   └── TimerStateChangeEvent.swift # Domain event for phase transitions
├── Application/Services/
│   ├── TimerAction.swift           # Action enum (START/PAUSE/RESET/STOP/ADVANCE)
│   ├── TimerSyncManager.swift      # Sync coordination
│   └── SessionLogger.swift         # Session recording
├── Presentation/Views/
│   ├── Components/
│   │   ├── CircularTimerView.swift  # Timer display component
│   │   └── ...
│   ├── iOS/
│   │   ├── iOSContentView.swift     # iOS timer view
│   │   ├── CycleProgressView.swift  # Cycle dot indicators
│   │   └── SettingsView.swift       # Timer settings
│   └── macOS/
│       └── macOSContentView.swift   # macOS timer view
├── Infrastructure/External/
│   └── NotificationManager.swift    # System notifications
└── Extension/
    └── AppExtensions.swift          # Int.mmss formatter
```

### Pattern 1: Timer Countdown with Auto-Advance

**What:** The timer countdown tick loop that triggers `advance()` when remaining reaches zero, optionally auto-starting the next phase.

**When to use:** Every time `startTimer()` is called.

**Current code (GAP):** The existing `startTimer()` loop reaches zero and stops without calling `advance()` or handling `autoStartNextSession`.

```swift
// Source: Existing PomodoroTimer.swift startTimer() — needs gap fix
private func startTimer() {
    stopTimer()
    timerTask = Task {
        while self.isRunning && remainingSeconds > 0 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                if self.isRunning && remainingSeconds > 0 {
                    remainingSeconds -= 1
                    self.lastModifiedTimestamp = Date().timeIntervalSince1970
                }
            }
        }
        // GAP: Timer reaches 0 but does NOT call advance() or onSessionCompleted
        // FIX: On loop exit (remainingSeconds == 0), trigger session completion
        guard self.isRunning else { return }
        await MainActor.run {
            handleTimerCompletion()
        }
    }
}

private func handleTimerCompletion() {
    // Record session completion (bridge to SessionLogger)
    onSessionCompleted?(phase, currentDuration)

    // Auto-advance to next phase if enabled
    if autoStartNextSession {
        advance()
        start() // Auto-start the next phase
    } else {
        advance() // Advance phase but don't auto-start
    }
}
```

### Pattern 2: Session Completion Callback Wiring

**What:** Connect `PomodoroTimer.onSessionCompleted` to session recording and notification delivery in the views that create the timer.

**When to use:** On app launch in `TimeBeamApp.setupApp()` or in the content views' `onAppear`.

**Current code (GAP):** `onSessionCompleted` is never assigned.

```swift
// Source: Pattern from TimeBeamApp.swift / iOSContentView.swift
// In TimeBeamApp.setupApp() or iOSContentView.onAppear:
timer.onSessionCompleted = { [weak logger, weak timer] completedPhase, duration in
    // Record the completed session
    let record = SessionRecord(
        startedAt: timer?.startTimestamp.map(Date.init.timeIntervalSince1970) ?? .now,
        duration: TimeInterval(duration),
        kind: SessionRecord.Kind(fromPhase: completedPhase)
    )
    logger?.add(record: record)

    // Send system notification
    NotificationManager.shared.sendSessionDoneNotification(phase: completedPhase.rawValue)
}
```

### Pattern 3: Cross-Platform UI Composition

**What:** Shared `CircularTimerView` component with platform-specific wrapping views.

**When to use:** Always -- use `CircularTimerView` for timer display, wrap in platform-specific layout.

```swift
// iOS: Vertical stack with cycle progress and controls
// macOS: Compact card with inline cycle dots and gear menu
// Both use: @Environment(PomodoroTimer.self) var timer
```

### Anti-Patterns to Avoid

- **Double-counting elapsed time:** `applySyncedState` trusts backend's `remainingSeconds` directly. Do NOT subtract elapsed time again -- the backend already computed it. Documented in `PomodoroTimer.swift:144-147`.
- **Force-unwrapping optionals:** `startTimestamp` and `pauseTimestamp` are optional. Use `guard let` or `??` with sensible defaults.
- **Creating multiple `PomodoroTimer` instances:** The timer is created once in `TimeBeamApp` and injected via `@Environment`. Never create a local instance for display purposes.
- **Syncing on every tick:** Timer action sync only on user actions (start/pause/reset/advance), NOT on every 1-second countdown tick. The existing 30-second polling handles state reconciliation.
- **Blocking MainActor during countdown:** The `startTimer()` task runs off-main but updates state via `MainActor.run`. Never await heavy operations inside the tick loop.

## Runtime State Inventory

> This phase involves connecting existing code, not renaming. However, the `onSessionCompleted` callback wiring and auto-advance logic represent stateful changes.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Timer callback wiring | `onSessionCompleted` is nil at runtime | Code edit — assign callback in view setup |
| Auto-advance state | `autoStartNextSession` property exists but is never read during countdown | Code edit — check in `handleTimerCompletion` |
| Session recording | `SessionLogger` exists but receives no timer completion events | Code edit — wire `onSessionCompleted` to `logger.add()` |
| Notification delivery | `NotificationManager.sendSessionDoneNotification` exists but is never called on timer expiry | Code edit — call from session completion handler |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timer countdown | Custom RunLoop/NSTimer | `Task.sleep` + async | Already working; no need to switch to Combine or Foundation.Timer |
| Audio chime | AVAudioSession configuration | `AVAudioPlayer` | Simple enough; don't add audio engine dependencies |
| Notifications | Custom push service | `UNUserNotificationCenter` | Built-in framework; handles scheduling, permissions, sounds |
| Haptics | Core Haptics engine | `UIImpactFeedbackGenerator` | Lightweight; sufficient for timer completion |
| Time formatting | Custom formatter | `Int.mmss` extension | Already exists in `AppExtensions.swift` |

**Key insight:** The timer domain is a well-understood problem with clean platform-native solutions. Every infrastructure need (countdown, sound, notifications, haptics) has a built-in framework. The real work is wiring them together coherently.

## Common Pitfalls

### Pitfall 1: Session Completion Never Fires
**What goes wrong:** Timer reaches zero, `onSessionCompleted` callback is nil, no session recorded, no notification shown. User sees "00:00" forever.
**Why it happens:** The `onSessionCompleted` callback is declared but never assigned. The countdown loop exits without calling it.
**How to avoid:** Assign `onSessionCompleted` in the view that owns the timer. Add a `handleTimerCompletion()` call at loop exit.
**Warning signs:** Timer displays "00:00" but no session appears in the session list; no notification sound plays.

### Pitfall 2: Auto-Advance Infinite Loop
**What goes wrong:** Timer advances to next phase and auto-starts. But `advance()` also calls `onSessionCompleted`, which could trigger another `advance()`, causing a loop.
**Why it happens:** `advance()` calls `onSessionCompleted?(previousPhase, currentDuration)` at line 128. If the callback also calls `advance()`, recursion occurs.
**How to avoid:** The callback should record/notify, NOT call `advance()`. The `handleTimerCompletion()` method in the timer itself should handle the advance decision.
**Warning signs:** App crashes with stack overflow or timer rapidly cycling through phases.

### Pitfall 3: Remaining Seconds Shows Negative
**What goes wrong:** After timer reaches zero, the display shows negative numbers because `remainingSeconds` keeps decrementing.
**Why it happens:** The loop condition `remainingSeconds > 0` prevents decrementing to negative, but `isRunning` must also be set to `false` to prevent re-entry.
**How to avoid:** Ensure `handleTimerCompletion()` sets `isRunning = false` if auto-advance is disabled. Use `max(0, remainingSeconds)` in display.
**Warning signs:** "-00:01" or "-00:02" displayed after timer expiry.

### Pitfall 4: Unit Tests Reference Missing Methods
**What goes wrong:** `PomodoroTimerUnitTests.swift` references `startFromSync()` which does not exist in the current `PomodoroTimer` class.
**Why it happens:** The test was written for a previous version of the code; `startFromSync()` was likely removed or renamed.
**How to avoid:** Fix tests to match current API. Either add `startFromSync()` as an alias or update test methods.
**Warning signs:** Test compilation failure: "Value of type 'PomodoroTimer' has no member 'startFromSync'".

### Pitfall 5: Type Mismatch in Tests
**What goes wrong:** Tests assert `timer.remainingSeconds = 1234.5` but `remainingSeconds` is declared as `Int`.
**Why it happens:** A previous version may have used `Double` for `remainingSeconds`; the current code uses `Int`.
**How to avoid:** Fix test to use `Int` values: `timer.remainingSeconds = 1234`.
**Warning signs:** Test compilation failure: "Cannot assign value of type 'Double' to type 'Int'".

### Pitfall 6: Haptics Toggle Has No Implementation
**What goes wrong:** SettingsView has `@AppStorage("hapticsEnabled")` toggle but no code checks it before triggering haptics.
**Why it happens:** The toggle was added as UI but the consumer code was never written.
**How to avoid:** Check `UserDefaults.standard.bool(forKey: "hapticsEnabled")` in the session completion handler before triggering haptics. On iOS, use `UIImpactFeedbackGenerator`. On macOS, haptics are not available.
**Warning signs:** Toggle changes but behavior is the same.

## Code Examples

### Timer State Transition (Complete Flow)
```swift
// Source: CLAUDE.md Timer Sync Architecture section
// User taps Start:
// 1. View calls TimerSyncManager.syncTimerAction(.start)
// 2. TimerSyncManager calls timer.start() — sets isRunning=true, startTimestamp
// 3. TimerSyncManager pushes TimerActionDto to backend
// 4. Backend stores state, sends APNs to other devices
// 5. Remote devices apply state via TimerSyncManager.applyEventState()

// Timer reaches zero:
// 1. startTimer() loop exits (remainingSeconds == 0)
// 2. handleTimerCompletion() called
// 3. onSessionCompleted?(phase, duration) — records session, sends notification
// 4. If autoStartNextSession: advance() + start()
// 5. advance() increments shortBreaksCompleted, switches phase
```

### Session Recording
```swift
// Source: SessionLogger.swift — existing add() method
func add(record: SessionRecord) {
    let dto = SessionRecordDto(
        id: record.id,
        startedAt: record.startedAt,
        duration: record.duration,
        kind: record.kind.rawValue
    )
    records.append(dto)
    save()
}

// SessionRecord.Kind mapping from Phase:
extension SessionRecord.Kind {
    static func fromPhase(_ phase: Phase) -> SessionRecord.Kind {
        switch phase {
        case .work: return .work
        case .break: return .shortBreak
        case .longBreak: return .longBreak
        }
    }
}
```

### Notification on Session Completion
```swift
// Source: NotificationManager.swift — existing sendSessionDoneNotification
func sendSessionDoneNotification(phase: String) {
    let content = UNMutableNotificationContent()
    content.title = "Time Beam"
    if phase == "work" {
        content.body = "Work session done! Time for a break."
    } else {
        content.body = "Break session done! Time to focus."
    }
    content.sound = .default
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSTimer / DispatchSourceTimer | Task.sleep + async/await | iOS 13+ / Swift 5.5+ | No timer retention issues; automatic cleanup on deinit |
| ObservableObject + @Published | @Observable macro | iOS 17+ / Swift 5.9+ | No KVO boilerplate; compiler-generated observation |
| @EnvironmentObject | @Environment with custom keys | iOS 17+ | Type-safe injection; no need for wrapper properties |
| Reachability | NWPathMonitor | iOS 12+ / macOS 10.14+ | Modern path monitoring; already used in TimerSyncManager |
| Core Haptics engine | UIFeedbackGenerator | iOS 10+ | Simpler haptics for simple interactions |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `chime-sound.mp3` exists in app bundle | Notifications, Code Examples | If missing, `AVAudioPlayer` init fails silently (existing code has `else { return }` guard) |
| A2 | Session recording should happen on the client side | Architecture Patterns | If backend should record sessions, the flow changes — but existing code has `SessionLogger` for client-side recording |
| A3 | `advance()` should NOT be called from `onSessionCompleted` callback | Common Pitfalls | If this assumption is wrong, auto-advance could loop — but this is the safer pattern |
| A4 | Backend `convertActionToState` uses `actionType` enum with `@JsonAlias` | Architecture Patterns | Verified in CLAUDE.md Timer Sync Architecture; `SessionController.java` line 253 confirms `actionDto.getActionType()` |
| A5 | iOS haptics via `UIImpactFeedbackGenerator` are sufficient | Don't Hand-Roll | If richer haptics needed (e.g., UINotificationFeedbackGenerator), the pattern is the same |
| A6 | `iCloudSyncManager` exists and works for settings sync | Standard Stack | The file exists at `Infrastructure/iCloudSyncManager.swift` — assumed functional from existing SettingsView usage |

## Open Questions

1. **Should timer expiry trigger a synced action to the backend?**
   - What we know: User actions (start/pause/reset/advance) sync via `TimerSyncManager.syncTimerAction()`. The timer reaching zero is a local event, not a user action.
   - What's unclear: Whether the backend should know about automatic session completion, or if local recording + periodic poll is sufficient.
   - Recommendation: Local recording only. The periodic 30-second poll will sync the updated state. No need to sync every session completion — it's a derived state change.

2. **What should happen when timer reaches zero with auto-start disabled?**
   - What we know: `autoStartNextSession` defaults to `false` in the constructor (line 51) but `true` in the class property (line 30).
   - What's unclear: Whether the timer should advance the phase silently or stay at "00:00" until user taps start.
   - Recommendation: Advance phase but display "00:00" with "Start" button. Don't auto-start. This matches the CONTEXT.md locked decision "Auto-start behavior for next timer phase" as an opt-in feature.

3. **Is `startFromSync()` needed for the test's 2-second pause protection pattern?**
   - What we know: Tests reference `startFromSync()` which doesn't exist. This method likely started the timer without setting `startTimestamp`, allowing a grace period before pause.
   - What's unclear: Whether this is a deliberate feature or leftover from an earlier implementation.
   - Recommendation: Investigate whether a 2-second pause protection is needed. If so, implement it; if not, update tests to match current behavior.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / Swift 5.9+ | Timer UI, @Observable | ✓ | Verified via codebase | — |
| iOS 17 simulator | Testing @Observable | ✓ | iPhone 17 Pro available per rules/launch.md | iPhone 17 |
| macOS 14+ | Timer UI | ✓ | macOS native build | — |
| AVFoundation | Audio chime | ✓ | Built-in framework | — |
| UserNotifications | Session notifications | ✓ | Built-in framework | — |
| CoreHaptics (iOS only) | Haptic feedback | ✓ | Built-in framework | Visual feedback only |
| PostgreSQL (Docker) | Backend tests | ✓ | docker-compose.dev.yml | Skip backend tests |
| chime-sound.mp3 | Audio playback | ? | Not found in source tree | `UNNotificationSound.default` fallback |

**Missing dependencies with no fallback:**
- `chime-sound.mp3` in app bundle — may be excluded from git (binary asset). Needs verification.

**Missing dependencies with fallback:**
- None

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Swift), JUnit 5 + Mockito (Java) |
| Config file | Xcode test scheme (iOS/macOS), `mvn test` (backend) |
| Quick run command | `xcodebuild -scheme TimeBeamTest -destination 'platform=macOS' test` |
| Full suite command | `xcodebuild test` for all destinations; `mvn verify` for backend |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TIMER-01 | Timer countdown (start/pause/reset) | unit | `xcodebuild test -scheme TimeBeam -destination 'platform=macOS' -only-testing:TimeBeamTests/PomodoroTimerUnitTests` | ✅ Exists (needs fix) |
| TIMER-02 | Session completion and recording | unit | New: `PomodoroTimerSessionTests` | ❌ Wave 0 |
| TIMER-03 | Timer UI rendering | visual/manual | Build + Preview inspection | ✅ Exists (CircularTimerView preview) |
| TIMER-04 | Configurable durations | unit | `SettingsView` stepper -> `updateDurations()` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Run `PomodoroTimerUnitTests` (fixed) — < 5 seconds
- **Per wave merge:** Full test suite — `xcodebuild test` + `mvn test`
- **Phase gate:** All unit tests green + manual UI verification via Preview

### Wave 0 Gaps
- [ ] `PomodoroTimerSessionTests.swift` — covers TIMER-02 (session completion, `onSessionCompleted` callback, auto-advance)
- [ ] `PomodoroTimerDurationTests.swift` — covers TIMER-04 (duration configuration, `updateDurations()`)
- [ ] Fix `PomodoroTimerUnitTests.swift` — remove `startFromSync()` references, fix Double/Int mismatch
- [ ] `SessionLoggerTests.swift` — covers session recording integration
- [ ] Xcode test scheme configuration — verify test targets are set up correctly

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A — timer is local; sync uses existing auth |
| V3 Session Management | No | N/A — timer sessions are not auth sessions |
| V4 Access Control | No | N/A — local timer; sync access controlled by backend auth |
| V5 Input Validation | Yes | Duration ranges: work 15-60min, break 3-15min, long break 10-30min |
| V6 Cryptography | No | N/A — no crypto operations in timer domain |

### Known Threat Patterns for SwiftUI Timer

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Duration set to extreme value | Spoofing | Input validation: range-bounded steppers/pickers (15-60 min work, 3-15 min break) |
| Timer state replay attack | Repudiation | Timestamp-based conflict resolution (existing); backend authoritative clock |
| Notification spam | Denial of Service | NotificationManager sends one notification per session completion; no user-controlled loop |

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `PomodoroTimer.swift` — verified timer engine, identified gaps
- Codebase analysis: `CircularTimerView.swift` — verified UI component
- Codebase analysis: `iOSContentView.swift` / `macOSContentView.swift` — verified platform views
- Codebase analysis: `TimerSyncManager.swift` — verified sync integration
- Codebase analysis: `SessionLogger.swift` — verified session recording
- Codebase analysis: `NotificationManager.swift` — verified notification delivery
- Codebase analysis: `SettingsView.swift` — verified duration configuration
- Codebase analysis: `SessionController.java` — verified backend timer endpoints
- CLAUDE.md Timer Sync Architecture section — verified sync flow
- `.claude/rules/swift-coding.md` — Swift conventions

### Secondary (MEDIUM confidence)
- `PomodoroTimerUnitTests.swift` — existing tests (need fixing)
- `iCloudSyncManager.swift` — referenced by SettingsView (assumed functional)
- Phase 04 RESEARCH.md — confirms timer exists as foundation for sync

### Tertiary (LOW confidence)
- `chime-sound.mp3` existence — not found in source tree; may be in Xcode project resources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all frameworks are built-in; verified against existing codebase
- Architecture: HIGH — existing code provides clear architecture; gaps identified through code analysis
- Pitfalls: HIGH — derived from actual code gaps (onSessionCompleted not wired, test compilation issues)

**Research date:** 2026-05-11
**Valid until:** 2026-06-11 (stable domain; timer patterns change rarely)

---

## RESEARCH COMPLETE

**Phase:** 3 - Timer Implementation
**Confidence:** HIGH

### Key Findings

1. **Timer engine is functionally complete** — `PomodoroTimer` has all core methods (start, pause, reset, advance) and tracks state correctly with timestamps for sync
2. **Timer UI exists for both platforms** — `CircularTimerView` component + `iOSContentView` + `macOSContentView` with settings
3. **Critical gap: Session completion bridge** — `onSessionCompleted` callback is declared but never wired; no code connects timer expiry to session recording or notifications
4. **Critical gap: Auto-advance logic** — `startTimer()` loop exits at zero without calling `advance()` or `onSessionCompleted`; the timer just stops at "00:00"
5. **Unit tests are broken** — `PomodoroTimerUnitTests.swift` references a non-existent `startFromSync()` method and asserts `Double` on an `Int` field
6. **Haptics toggle is disconnected** — SettingsView has `hapticsEnabled` but no code checks it
7. **Audio chime depends on a binary asset** — `chime-sound.mp3` not found in source tree; may need to be added to Xcode resources

### File Created
`.planning/phases/03-timer-implementation/03-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | All built-in frameworks; verified against existing code |
| Architecture | HIGH | Code analysis reveals clear gaps and integration points |
| Pitfalls | HIGH | Based on actual code gaps (nil callback, broken tests) |

### Open Questions
1. Should timer expiry (auto-advance) sync to backend or stay local?
2. What should timer display show when at "00:00" with auto-start disabled?
3. Is `startFromSync()` (referenced in broken tests) a needed feature?

### Ready for Planning
Research complete. The timer domain is well-understood with specific, actionable gaps identified. Planner can create tasks to wire the session completion flow, fix tests, and implement the remaining UI polish.
