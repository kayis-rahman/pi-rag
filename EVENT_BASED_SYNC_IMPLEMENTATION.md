# Event-Based Timer Synchronization - Implementation Plan

## Problem
The current implementation syncs timer state with the backend every second, which is inefficient. Users want an event-based system where only meaningful actions (start, pause, reset) trigger synchronization events.

## Solution Overview

### Backend Changes (Java)
1. **Create TimerActionDto** - New DTO for action-based events with minimal fields
2. **Add pushTimerAction method** to TimerSyncService - Handle action events without full state synchronization
3. **Enhance PushNotificationService** - Broadcast action events to other devices via APNs
4. **Add API endpoint** - Create `/api/sessions/timer/action` for action-based sync

### Frontend Changes (Swift)
1. **Add TimerAction enum** - Define action types (start, pause, reset, etc.)
2. **Modify TimerSyncManager** - Only sync on meaningful actions, not every second
3. **Update PomodoroTimer** - Call action sync methods instead of state sync on timer events
4. **Implement APN handling** - Process incoming timer sync notifications from other devices

## Detailed Implementation Steps

### Backend Implementation
1. Create `TimerActionDto.java` in `presentation/dto/` package:
   - Fields: action (String), phase (String), remainingSeconds (Integer), isRunning (Boolean)
   - Additional fields: workDuration, breakDuration, longBreakDuration, autoStartNextSession, shortBreaksCompleted
   - startTimestamp, pauseTimestamp, lastModifiedTimestamp, deviceId

2. Update `TimerSyncService.java`:
   - Add `pushTimerAction(UUID userId, TimerActionDto action, String deviceIdString)` method
   - This method should send the action to backend and broadcast via APNs
   - Call `pushNotificationService.sendTimerSyncPush()` with action data
   - Remove full state synchronization from action handling

3. Update `PushNotificationService.java`:
   - Modify payload to include action information
   - Ensure proper APNs message structure for timer actions

### Frontend Implementation
1. Add TimerAction enum to `TimerSyncManager.swift`:
   ```swift
   enum TimerAction: String, Codable {
       case start = "start"
       case pause = "pause"
       case reset = "reset"
       case stop = "stop"
       case advance = "advance"
   }
   ```

2. Modify `TimerSyncManager` methods:
   - Add `syncTimerAction(_ action: TimerAction)` method
   - Remove timer tick sync logic (no more sync every second)
   - Only call this method on meaningful actions
   - Add method to handle APN notifications

3. Update `PomodoroTimer` methods:
   - `start()` → call `syncTimerAction(.start)` instead of full sync
   - `pause()` → call `syncTimerAction(.pause)` instead of full sync  
   - `reset()` → call `syncTimerAction(.reset)` instead of full sync
   - Implement APN handling for incoming events

## Benefits
- **Reduced Network Traffic**: Only send events on meaningful actions
- **Real-time Synchronization**: Immediate updates across devices
- **Better Performance**: Less battery drain and data usage
- **Improved User Experience**: More responsive synchronization
- **Scalability**: Backend handles fewer unnecessary requests

The system will transform from a polling-based architecture to an event-driven architecture that's much more efficient while maintaining all existing functionality.