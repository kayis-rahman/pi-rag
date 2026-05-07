# Agent — Debug Session Manager

Manages debug sessions across Xcode, Spring Boot, and Docker. Use when debugging failures.

## Debug Sources
- Xcode console output
- Spring Boot logs: `back-end/logs/timebeam.log`
- Docker container logs: `docker compose logs`
- macOS system logs: `log show --predicate`
- Xcode device logs: `xcrun simctl`

## Common Debug Workflows

### iOS/macOS App Crash
1. `log show --predicate 'eventMessage contains "TimeBeam"' --last 1h`
2. Check Xcode debug navigator for thread states
3. Inspect keychain access: `security find-generic-password -s TimeBeam`
4. Check console for `EXC_BAD_ACCESS` or `SIGABRT`

### Backend 500 Error
1. `tail -100 back-end/logs/timebeam.log`
2. Check Docker logs: `docker compose logs back-end`
3. Verify DB connection: `docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_dev -c "SELECT 1"`
4. Check HikariCP pool: `curl http://localhost:8080/actuator/metrics/hikaricp.connections.active`

### Timer Sync Issue
1. Check device logs for `TIMER_SYNC` or `TimerSyncManager` messages
2. Verify `deviceId` persists: `security find-generic-password -s "com.timebeam.app.deviceId"`
3. Check API_BASE_URL in `project.pbxproj` (not Info.plist)
4. Verify backend receives `action` field → `actionType` deserialization (check `@JsonAlias`)
5. Check `TimerState` in DB: `docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_dev -c "SELECT * FROM timer_states;"`
6. Verify silent push handler in `iOSAppDelegate.swift` / `MacAppDelegate.swift` calls `syncTimerState()`
7. Check Keychain entitlements: `com.apple.security.keychain.access-groups` with `425MSY8FLG.com.sparkage.time-beam`
8. Verify `AuthManager.restoreSession()` is called in `TimeBeamApp.setupApp()`
9. Check 30-second periodic polling is active: look for `startPeriodicPolling()` in logs
10. Cross-device: sign in with same account on both platforms, compare `timer_states.lastModifiedTimestamp`

### Timer Sync — Backend Deserialization Failure
Symptom: `remainingSeconds` is 0, timer state corrupted after sync.
1. `grep -i "actionType" back-end/logs/timebeam.log` — check for null deserialization
2. Verify `TimerActionDto.java` has `@JsonAlias({"action","actionType"})` on `actionType` field
3. Check iOS sends `TimerActionDto` with `action` field: `apple/TimeBeam/TimeBeam/Infrastructure/Networking/DTOs/TimerActionDto.swift`
4. Backend `SessionController.convertActionToState()` uses `actionDto.getActionType()` — must not be null

## Log Extraction Commands
```
# macOS system log
log show --predicate 'process == "TimeBeam" || process contains "TimeBeam"' --last 1h

# Xcode simulator log
xcrun simctl spawn booted log show --last 1h

# Spring Boot debug
tail -f back-end/logs/timebeam.log

# Docker container log
docker compose logs -f back-end
```
