# Swift Coding Standards

> Extends [rules/common/patterns.md](../../rules/common/patterns.md) with Swift-specific conventions.

## File Organization
- 200-400 lines typical, 800 max
- Organize by feature/domain, not by type
- One public type per file
- Internal helpers in extension files

## Naming Conventions
- Types: PascalCase (`TimerSyncManager`, `SessionRecordDto`)
- Variables/functions: camelCase (`syncTimerState()`, `userPreferences`)
- Constants: camelCase (Swift 5.1+ — `let maxRetries = 3`)
- Enums: PascalCase, cases: camelCase (`TimerState.running`)
- Protocols: PascalCase, describe capability (`Syncable`, `Loggable`)

## Optionals
- Prefer `guard let` / `if let` over force unwrap
- Use `??` for default values sparingly
- Never force unwrap in production code
- Use `if let` for single value, `guard let` for early return

## Struct vs Class
- Use `struct` by default (value semantics, thread-safe)
- Use `class` only when reference semantics needed (singletons, delegates)
- ViewModels: `class` with `@MainActor`
- Data models: `struct` with `Codable`

## Concurrency
- Use `async/await` for async operations
- `@MainActor` for UI state
- `Task.detached` for background work
- `asyncSequence` for streaming data
- Avoid `DispatchQueue.main.async` — use `await MainActor.run()`

## SwiftUI
- Views: `struct` conforming to `View`
- Keep `body` pure (no side effects)
- Use `@Observable` (iOS 17+) or `@ObservableObject` for state
- Custom modifiers for reusable UI logic
- Previews for common states

## Error Handling
- Use `Error` protocol for custom errors
- `do/catch` for recoverable errors
- `throw` for domain-specific errors
- Never catch-all without handling: `catch { ... }`

## Keychain
- Always wrap in `do/catch`
- Handle `errSecItemNotFound` gracefully
- Handle `errSecAuthFailed` / `-34018` (FaceID/TouchID denied or missing entitlements)
- Use access group from entitlements (`425MSY8FLG.com.sparkage.time-beam`)
- Persist critical identity (deviceId, tokens) — never use transient `UUID()` for values that must survive launches
- Keychain error -34018 means entitlements are missing: `com.apple.security.keychain.access-groups` must include the access group
- macOS and iOS share the same Keychain group — same keychain key works on both platforms

## Timer Sync Architecture
- `PomodoroTimer` (Domain) is the single source of truth in memory
- `TimerSyncManager` (singleton) handles all sync — deviceId is Keychain-persisted
- iOS sends `TimerActionDto.action` (String) → backend `TimerActionDto.actionType` (enum) with `@JsonAlias({"action","actionType"})`
- Backend `SessionController.convertActionToState()` uses `actionDto.getActionType()` — must not be null
- `TimerState` entity is one-per-user in `timer_states` table — conflict resolution by `lastModifiedTimestamp`
- 30-second periodic polling + silent APNs push trigger `syncTimerState()` on both platforms
- `setupApp()` must: restore auth → pull timer state → configure sync manager → set `isAppReady = true`
- Silent push `willPresent` handler MUST call `syncTimerState()`, never discard
