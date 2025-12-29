# Event-Based Timer Synchronization Implementation

## Overview
This document describes the implementation of event-based timer synchronization for TimeBeam. The goal is to send timer actions only when meaningful user actions occur (start, pause, reset, stop, advance) instead of continuously sending state updates every second.

## Problem Statement
The previous implementation sent the full timer state (including `remainingSeconds`) with every sync action. This meant:
- If sync was triggered frequently (e.g., on timer ticks), the server received updates every second
- Network bandwidth was wasted on continuously changing values
- True event-based sync was not achieved

## Solution
Implement true event-based synchronization where:
1. **TimerActionDto contains only action + static metadata** (no `remainingSeconds`, `startTimestamp`, `pauseTimestamp`)
2. **Actions are sent only when user performs meaningful actions** (start, pause, reset, stop, advance)
3. **Server broadcasts action via APN to other devices**
4. **Receiving devices interpret and apply the action** based on action type
5. **Full state sync occurs on app load/refresh** via `pullTimerState()`

## Frontend Changes

### 1. ApiClient.swift
**File:** `apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift`

#### Added TimerActionDto Structure
```swift
struct TimerActionDto: Codable {
    let action: String              // "start", "pause", "reset", "stop", "advance"
    let phase: String               // "work", "break", "long_break"
    let isRunning: Bool            // Current running state
    let workDuration: Int          // Work duration in minutes
    let breakDuration: Int         // Break duration in minutes
    let longBreakDuration: Int     // Long break duration in minutes
    let autoStartNextSession: Bool // Auto-start setting
    let shortBreaksCompleted: Int  // Counter for breaks
    let deviceId: String           // Source device ID
    let timestamp: Double          // Action timestamp
}
```

**Key changes:**
- Removed `remainingSeconds`, `startTimestamp`, `pauseTimestamp`
- Only includes static metadata that doesn't change continuously

#### Added pushTimerAction Method
```swift
func pushTimerAction(_ action: TimerActionDto, accessToken: String) async throws
```
- Sends action to `/sessions/timer/action` endpoint
- Used for event-based sync

### 2. TimerSyncManager.swift
**File:** `apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift`

#### Updated performActionSync Method
**Before:**
```swift
let actionDto = ApiClient.TimerActionDto(
    action: action.rawValue,
    phase: timer.phase.rawValue,
    remainingSeconds: Int(timer.remainingSeconds),  // ❌ Changes every second
    isRunning: timer.isRunning,
    workDuration: timer.workDuration,
    breakDuration: timer.breakDuration,
    longBreakDuration: timer.longBreakDuration,
    autoStartNextSession: timer.autoStartNextSession,
    shortBreaksCompleted: timer.shortBreaksCompleted,
    startTimestamp: timer.startTimestamp,          // ❌ Changes on start
    pauseTimestamp: timer.pauseTimestamp,          // ❌ Changes on pause
    lastModifiedTimestamp: timer.lastModifiedTimestamp,
    deviceId: deviceId
)
```

**After:**
```swift
let actionDto = ApiClient.TimerActionDto(
    action: action.rawValue,
    phase: timer.phase.rawValue,
    isRunning: timer.isRunning,
    workDuration: timer.workDuration,
    breakDuration: timer.breakDuration,
    longBreakDuration: timer.longBreakDuration,
    autoStartNextSession: timer.autoStartNextSession,
    shortBreaksCompleted: timer.shortBreaksCompleted,
    deviceId: deviceId,
    timestamp: Date().timeIntervalSince1970
)
```

#### Added applyIncomingAction Method
**Purpose:** Handles incoming timer actions from other devices (event-based sync)

```swift
func applyIncomingAction(
    _ action: String,
    phase: String,
    isRunning: Bool,
    workDuration: Int,
    breakDuration: Int,
    longBreakDuration: Int,
    autoStartNextSession: Bool,
    shortBreaksCompleted: Int,
    sourceDeviceId: String,
    timestamp: Double
)
```

**Action Logic:**

| Action | Behavior |
|--------|----------|
| **start** | Set `isRunning=true`, calculate `remainingSeconds` from phase and duration, update timestamps |
| **pause** | Set `isRunning=false`, keep current `remainingSeconds` |
| **reset** | Set `isRunning=false`, reset `remainingSeconds` to phase duration, reset break counter |
| **stop** | Set `isRunning=false` |
| **advance** | Move to next phase, set `remainingSeconds` to new phase duration, reset break counter if returning to work |

#### Added calculateRemainingSecondsForPhase Helper
```swift
private func calculateRemainingSecondsForPhase(
    _ phase: String,
    workDuration: Int,
    breakDuration: Int,
    longBreakDuration: Int
) -> Int
```
- Returns duration in seconds based on phase
- Work: `workDuration * 60`
- Break: `breakDuration * 60`
- Long Break: `longBreakDuration * 60`

### 3. TimeBeamApp.swift
**File:** `apple/TimeBeam/TimeBeam/TimeBeamApp.swift`

#### Updated APN Notification Handling (macOS)
**Before:**
```swift
if let type = userInfo["type"] as? String, type == "timer_sync" {
    AppLogger.info("Received timer sync APN message on macOS", category: .sync)

    // Always trigger full timer sync
    _Concurrency.Task {
        await TimerSyncManager.shared.syncTimerState()
    }

    completionHandler([])
    return
}
```

**After:**
```swift
if let type = userInfo["type"] as? String, type == "timer_sync" {
    AppLogger.info("Received timer sync APN message on macOS", category: .sync)

    // Parse action from notification and apply event-based sync
    if let actionDict = userInfo["action"] as? [String: Any],
       let actionType = actionDict["action"] as? String,
       let sourceDeviceId = actionDict["deviceId"] as? String,
       let timestampString = actionDict["timestamp"] as? String,
       let timestamp = Double(timestampString) {

        AppLogger.info("Processing timer action from notification: \(actionType), device: \(sourceDeviceId)", category: .sync)

        // Apply incoming action (event-based sync)
        _Concurrency.Task {
            let currentPhase = timer.phase.rawValue
            let workDuration = timer.workDuration
            let breakDuration = timer.breakDuration
            let longBreakDuration = timer.longBreakDuration
            let autoStartNext = timer.autoStartNextSession
            let shortBreaksCompleted = timer.shortBreaksCompleted

            TimerSyncManager.shared.applyIncomingAction(
                actionType,
                phase: currentPhase,
                isRunning: timer.isRunning,
                workDuration: workDuration,
                breakDuration: breakDuration,
                longBreakDuration: longBreakDuration,
                autoStartNextSession: autoStartNext,
                shortBreaksCompleted: shortBreaksCompleted,
                sourceDeviceId: sourceDeviceId,
                timestamp: timestamp
            )
        }
    } else {
        // Fallback to full state sync if parsing fails
        AppLogger.warning("Could not parse action from timer sync notification, falling back to full sync", category: .sync)
        _Concurrency.Task {
            await TimerSyncManager.shared.syncTimerState()
        }
    }

    completionHandler([])
    return
}
```

#### Updated APN Notification Handling (iOS)
Same logic applied to iOS notification handler (around line 1814).

## Expected Behavior

### When User Performs Timer Action
1. User taps **Start** on Device A
2. `TimerSyncManager.syncTimerAction(.start)` is called
3. `TimerActionDto` is created with:
   - action: "start"
   - phase: "work"
   - isRunning: true
   - workDuration: 25
   - breakDuration: 5
   - longBreakDuration: 15
   - autoStartNextSession: false
   - shortBreaksCompleted: 0
   - deviceId: "device-uuid"
   - timestamp: current time
4. Action is sent to backend via `/sessions/timer/action`
5. Backend processes action and sends APN to Device B
6. Device B receives APN, parses action, calls `applyIncomingAction(.start, ...)`
7. Device B starts timer with 25 minutes (calculated from phase + duration)

### When App Loads or Refreshes
1. App calls `TimerSyncManager.syncTimerState()`
2. Full state is pulled from backend via `/sessions/timer/state`
3. `remainingSeconds` and all state are synchronized

## Benefits

### Reduced Network Traffic
- **Before:** Potentially 60+ updates per minute if sync triggered on timer ticks
- **After:** Only 1 update per meaningful user action

### True Event-Based Sync
- Actions are sent only when user performs them
- Server broadcasts action to other devices
- Other devices interpret and apply action intelligently

### Efficient Conflict Resolution
- Full state sync available via `pullTimerState()` when needed
- Action-based sync for real-time updates
- Timestamp-based conflict resolution on backend

## APN Notification Payload Format

Backend sends silent APN with this structure:
```json
{
  "aps": {
    "content-available": 1,
    "sound": ""
  },
  "type": "timer_sync",
  "action": {
    "action": "start",
    "deviceId": "device-uuid",
    "timestamp": "1703908800.123"
  }
}
```

## Testing Checklist

- [ ] Start timer on Device A → Verify Device B receives and starts timer
- [ ] Pause timer on Device A → Verify Device B pauses timer
- [ ] Reset timer on Device A → Verify Device B resets to phase duration
- [ ] Stop timer on Device A → Verify Device B stops timer
- [ ] Advance phase on Device A → Verify Device B advances and calculates correct duration
- [ ] Open app on Device B → Verify full state sync on load
- [ ] Ignore own actions → Verify Device A doesn't react to its own actions

## Backend Changes Required

Note: Backend implementation needs to match frontend changes:
1. Update `TimerActionDto` to match frontend structure (remove nested TimerState)
2. Implement `applyActionToTimerState` method in `TimerSyncService`
3. Update `pushTimerAction` to use action-based logic instead of full state replacement

## Migration Notes

- Existing `pushTimerState` and `pullTimerState` methods unchanged
- New `pushTimerAction` method added for event-based sync
- Backward compatible with full state sync when needed
- Fallback to full state sync if action parsing fails

## Future Enhancements

1. **WebSocket Support:** Add WebSocket channel for real-time action broadcast
2. **Batch Actions:** Combine multiple rapid actions (e.g., quick start-stop) into single event
3. **Action Queue:** Implement local queue for offline mode
4. **Conflict UI:** Show conflict resolution dialog when multiple devices act simultaneously
