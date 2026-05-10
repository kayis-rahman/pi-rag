# /debug — Debug session

Extract logs, check container health, and diagnose failures.

## Quick Debug
```
# Backend logs
tail -100 back-end/logs/timebeam.log

# Docker logs
docker compose -f back-end/docker-compose.dev.yml logs --tail=50

# Health check
curl -s http://localhost:8080/api/auth/health
```

## iOS/macOS Debug
```
# System log for TimeBeam
log show --predicate 'eventMessage contains "TimeBeam"' --last 1h

# Simulator log
xcrun simctl spawn booted log show --last 1h
```

## Database Debug
```
# Check connections
docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_dev -c "SELECT count(*) FROM pg_stat_activity;"

# Check schema
docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_dev -c "\dt"
```

## Timer Sync Debug
```
# Device Keychain — verify deviceId persists
security find-generic-password -s "com.timebeam.app.deviceId"

# Check Keychain entitlement (macOS)
grep -A2 "keychain.access-groups" apple/TimeBeam/TimeBeam\ macOS.entitlements

# API_BASE_URL in project file (NOT Info.plist)
grep "API_BASE_URL" apple/TimeBeam/TimeBeam.xcodeproj/project.pbxproj

# Backend deserialization — actionType must not be null
tail -50 back-end/logs/timebeam.log | grep -i "actionType\|remainingSeconds\|convertActionToState"

# TimerSyncManager logs
log show --predicate 'eventMessage contains "TIMER_SYNC" || eventMessage contains "TimerSyncManager"' --last 1h

# APNs silent push delivery
log show --predicate 'eventMessage contains "timer_sync" || eventMessage contains "silent"' --last 1h

# WatchConnectivity session state
log show --predicate 'eventMessage contains "WatchSyncManager" || eventMessage contains "WCSession"' --last 1h
```

## Common Debug Commands
- `pkill -f "TimeBeam"` — kill running TimeBeam processes
- `pkill -f "spring-boot"` — kill running backend
- `lsof -i :8080` — check port 8080 usage
- `lsof -i :5432` — check port 5432 usage

## Quick Checks (Timer Sync)
```bash
# 1. Backend running?
curl -s http://localhost:8080/api/auth/health

# 2. PostgreSQL running?
lsof -i:5432

# 3. Check timer state in DB:
SELECT * FROM timer_states ORDER BY last_updated_at DESC LIMIT 5;

# 4. Check APNs tokens registered:
SELECT device_id, device_type, active FROM user_devices WHERE active = true;
```

## Debug Reference
See `agents/debug-session.md` for comprehensive debug workflows and checklists.
