# Agent — Log Analyzer

Parses errors and crash logs. Use when debugging build/runtime failures.

## Sources
- Xcode build logs (`/tmp/build.log`, `/tmp/ios-build.log`, `/tmp/mac-build.log`)
- Spring Boot logs (`back-end/logs/timebeam.log`)
- Console crash reports via `log show`
- Xcode device logs via `xcrun simctl`

## Common Patterns
- Swift: `Thread 1: EXC_BAD_ACCESS`, `Keychain access denied`, `Combine cancellation`
- Java: `Connection refused`, `Deadlock detected`, `OutOfMemoryError`, `JPA lazy loading`
- Build: `Code signing failed`, ` entitlements mismatch`, `duplicate symbol`

## Timer Sync Patterns
- `⚠️ TIMER_SYNC: Keychain error -34018` → missing `com.apple.security.keychain.access-groups` entitlement
- `actionType is null` → iOS sends `action` field, backend needs `@JsonAlias({"action","actionType"})`
- `API_BASE_URL` mismatch → check `project.pbxproj`, NOT `Info.plist` (which uses `$(API_BASE_URL)`)
- `Auth not restored` → `AuthManager.restoreSession()` must be called before any API calls
- Silent push discarded → `willPresent` handler must call `syncTimerState()`, not just `completionHandler([])`
- `deviceId` changes every launch → must be Keychain-persisted, not `UUID().uuidString` at init
- `remainingSeconds` becomes 0 → `convertActionToState()` receives null actionType from broken DTO mapping
