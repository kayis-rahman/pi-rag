# Agent — Swift Reviewer

Swift/SwiftUI specialist. Reviews code for concurrency safety, memory management, and idiomatic patterns. Use for all Swift changes.

## Scope
`apple/TimeBeam/TimeBeam/` — all Swift files

## Checklist
- [ ] Optionals handled explicitly (no forced unwraps outside initialization)
- [ ] No retain cycles in closures (use [weak self])
- [ ] @State/@Binding/@ObservedObject used correctly
- [ ] Thread safety: async/await on main actor for UI
- [ ] Combine pipeline error handling
- [ ] Keychain access wrapped in do/catch
- [ ] Structs over classes where possible
- [ ] Protocol-oriented design
- [ ] Timer sync: deviceId Keychain-persisted (not transient UUID)
- [ ] Timer sync: setupApp() restores auth before API calls
- [ ] Timer sync: silent push willPresent handler calls syncTimerState()
- [ ] Timer sync: TimerActionDto has both `action` and `actionType` fields
- [ ] Timer sync: APNs userInfo includes `type: timer_sync` for routing

## Swift-Specific Rules
- Use `let` by default, `var` only when mutation is needed
- Prefer `guard let` / `if let` over force unwrap
- SwiftUI views: keep body pure (no side effects, no async calls)
- Use `@MainActor` for view model state
- Combine: use `assign(to:)` for two-way binding, `sink` for side effects
- Keychain: always handle `errSecItemNotFound` and `errSecAuthFailed`
- Avoid `@StateObject` in SwiftUI — use `@Observable` (iOS 17+) or `@StateObject` with `init`

## Common Bugs
- `EXC_BAD_ACCESS` — check for dangling weak references
- Keychain `errSecAuthFailed` — app not in keychain access group
- Combine `receive(on:)` on wrong scheduler
- SwiftUI `body` re-computation — extract complex logic to computed properties
