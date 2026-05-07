# SKILL.md — Sync Debug

> Structured checklist for diagnosing cross-device timer sync failures (iOS ↔ macOS ↔ backend).

**Trigger:** User reports timer not syncing, remainingSeconds=0 after sync, timer resets on launch, or one device doesn't reflect the other's state.

---

## Step 1 — Verify Auth Is Restored

Check `TimeBeamApp.setupApp()` calls `AuthManager.restoreSession()` before any sync:
```bash
grep -n "restoreSession" apple/TimeBeam/TimeBeam/TimeBeamApp.swift
```
Must appear before `TimerSyncManager` calls.

## Step 2 — Verify deviceId Persists

```bash
security find-generic-password -s "com.timebeam.app.deviceId" -w
```
If missing → deviceId uses `UUID()` at init; check `TimerSyncManager.init` — must read from Keychain.

## Step 3 — Check @JsonAlias on Backend DTO

```bash
grep -n "JsonAlias\|actionType" back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TimerActionDto.java
```
Must have: `@JsonAlias({"action","actionType"})` on the `actionType` field. Without it, iOS's `action` field deserializes as null → `remainingSeconds` = 0.

## Step 4 — Check convertActionToState Receives Non-null ActionType

```bash
grep -n "getActionType\|convertAction" back-end/src/main/java/com/sparkage/timebeam/presentation/controller/SessionController.java
```
Add logging if needed: `log.debug("actionType={}", actionDto.getActionType())`. Null here is the root cause of corrupted sync state.

## Step 5 — Check Silent Push Handler

```bash
grep -rn "willPresent\|syncTimerState" apple/TimeBeam/TimeBeam/
```
The `willPresent` handler for `timer_sync` push MUST call `syncTimerState()` before `completionHandler`.

## Step 6 — Verify Periodic Polling Is Active

```bash
grep -n "startPeriodicPolling\|stopPeriodicPolling" apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift
```
Then check device console for `startPeriodicPolling` log lines — polling should fire every 30s.

## Step 7 — Check Backend DB State

```bash
docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_dev -c "SELECT user_id, state, remaining_seconds, last_modified_timestamp FROM timer_states ORDER BY last_modified_timestamp DESC LIMIT 5;"
```
Look for: correct state, sane remainingSeconds, recent timestamp.

## Step 8 — Check Conflict Resolution

The row with the highest `last_modified_timestamp` wins. If two devices race, the later write wins.
Check `TimerSyncService.updateTimerState()` for the conflict check logic.

## Step 9 — Check Keychain Entitlement

```bash
grep -r "keychain-access-groups\|425MSY8FLG" apple/TimeBeam/TimeBeam/
```
Both `TimeBeam macOS.entitlements` and `TimeBeam iOS.entitlements` must contain:
`425MSY8FLG.com.sparkage.time-beam`
Missing → Keychain error -34018 at runtime.

## Step 10 — Verify API_BASE_URL

```bash
grep -n "API_BASE_URL" apple/TimeBeam/TimeBeam.xcodeproj/project.pbxproj | head -5
```
Value is in `project.pbxproj`, NOT `Info.plist`. `Info.plist` only has `$(API_BASE_URL)` placeholder.

---

## Outcome

After each step, either find the issue or confirm the step is healthy. Most sync failures trace back to steps 3, 4, or 9.
