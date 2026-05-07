# Codebase Concerns

**Analysis Date:** 2026-04-20

## Tech Debt

### High Priority

| Issue | Location | Impact | Notes |
|-------|----------|--------|-------|
| Token revocation endpoint | `AuthManager.swift:134` | Security | OAuth token not revoked on sign-out |
| Access token from Keychain | `ApiClient.swift:138` | Security | TODO to implement actual token retrieval |
| Error alert in SettingsView | `SettingsView.swift:71` | UX | Error message only printed to console |
| Watch token transfer | `WatchConnectivityManager.swift:55` | Feature | Secure token transfer not implemented |
| Sign-in flow on Watch | `WatchConnectivityManager.swift:76` | Feature | Sign-in flow not implemented |

### Medium Priority

| Issue | Location | Impact | Notes |
|-------|----------|--------|-------|
| Token expiration check | `AuthManager.swift:285` | Security | Expiration not currently tracked |
| Debug logging in production | Multiple files | Performance | `#if DEBUG` guards present but some `print()` statements remain |
| Default JWT secret | `application.yml:22` | Security | Default `change-me-to-a-long-random-secret` |
| APNs key path hardcoded | `application.yml:55` | Security | Development key path may be committed |
| Broad exception handling | `AuthController.java:75`, `SessionController.java:185` | Debugging | Masks root causes, hard to debug |
| Large AnalyticsService | `AnalyticsService.java` (801 lines) | Maintainability | Multiple responsibilities in one service |

### Low Priority

| Issue | Location | Impact | Notes |
|-------|----------|--------|-------|
| Hardcoded API URL | `TaskService.swift:19`, `AnalyticsView.swift:229` | Deployment | Fallback URL `192.168.0.173:8080` may break in production |
| Timer sync polling interval | `TimerSyncManager.swift:421` | Performance | 30+ second polling may miss real-time updates |
| No pagination on sessions | `SessionController.java:82` | Scalability | Returns all sessions without limit |

## Known Issues

### Authentication
- **Google Sign-In flow may fail** if `API_BASE_URL` not configured in Info.plist
- **Debug print statements** expose token prefixes in development builds (`AuthManager.swift:162`, `:224`)
- **Token revocation not implemented** - refresh tokens remain valid after logout (`AuthManager.swift:115-142`)

### Timer Sync
- **State polling limited to 30+ seconds** - may miss real-time updates from other devices
- **Conflict resolution uses timestamp-only** - clock skew between devices may cause issues
- **Timer state not persisted** across app restarts (`PomodoroTimer.swift`) - users lose progress

### Analytics
- **Debug logging in AnalyticsService** may impact production performance with verbose SQL logging

### Task Management
- **Hard delete available** but no backend sync for recycle bin operations
- **Cache corruption handling** clears entire task cache without user notification

## Security Considerations

| Category | Issue | Recommendation |
|----------|-------|----------------|
| Secrets | API_BASE_URL in Info.plist | Move to .xcconfig or environment variables |
| JWT Secret | Default value in `application.yml:22` | Add startup validation; use secret manager |
| APNs Key | Hardcoded path `application.yml:55` | Add to .gitignore; use secret management |
| Token Storage | `kSecAttrAccessibleAfterFirstUnlock` | Consider `WhenUnlockedThisDeviceOnly` for better security |
| Logging | Debug prints with tokens in AuthManager, ApiClient | Remove all print statements before release; use unified logging |

## Performance Bottlenecks

| Area | Concern | Mitigation |
|------|---------|------------|
| N+1 Query Risk | `AnalyticsService` runs separate queries for each metric | Single joined query or caching layer |
| Session Lists | No pagination on `/api/sessions` | Add page/limit parameters |
| Timer Sync | Repeated JSON encoding/decoding | Use binary encoding or direct model sync |
| Background Sync | Frequency may impact battery | Optimize based on device activity |

## Fragile Areas

### Authentication Flow
- **Why fragile:** Multiple code paths for Google/Apple sign-in, PKCE state management
- **Files:** `apple/TimeBeam/TimeBeam/Infrastructure/External/AuthManager.swift:146-720`
- **Safe modification:** Ensure PKCE state is cleared after use; test callback URL parsing
- **Test coverage:** Limited E2E coverage for OAuth flows

### Timer State Persistence
- **Why fragile:** Multiple sync sources (local timer, backend, watch connectivity)
- **Files:** `apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift`, `WatchConnectivityManager.swift`
- **Safe modification:** Validate timestamps before applying synced state; log sync sources
- **Test coverage:** Some unit tests but limited integration tests

### Cross-Device Sync Conflict Resolution
- **Why fragile:** Timestamp-based resolution may fail with clock skew
- **Files:** `apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift:321-339`
- **Safe modification:** Use server timestamps; implement retry with exponential backoff
- **Test coverage:** Conflict resolution tests exist but may not cover clock skew scenarios

### Presentation Context Provider
- **Why fragile:** `fatalError()` thrown if window not found (`AuthManager.swift:740`)
- **Files:** `apple/TimeBeam/TimeBeam/Infrastructure/External/AuthManager.swift:740`
- **Safe modification:** Graceful fallback with user-facing error message
- **Test coverage:** No tests for edge case where window is unavailable

## Scaling Limits

### Single Timer State per User
- **Current capacity:** One timer state record per user in database
- **Limit:** No support for multiple concurrent timers
- **Scaling path:** Add timer ID to support multiple concurrent timers per user

### Push Notification Rate Limiting
- **Current capacity:** No rate limiting on push notifications
- **Limit:** Potential for spam if client misbehaves
- **Scaling path:** Implement rate limiting on push endpoints

### Database Connection Pool Size
- **Current capacity:** HikariCP max pool size 5 in `application-dev.yml:8`
- **Limit:** May bottleneck under high load
- **Scaling path:** Increase pool size; add read replicas

## Dependencies at Risk

| Dependency | Risk | Migration plan |
|------------|------|----------------|
| Swift CryptoKit | Only available on Apple platforms | Consider SwiftNIO for non-Apple platforms |
| Pushy Library | External dependency for APNs | Monitor updates; consider swift-apns |
| JWT Library | io.jsonwebtoken | Track security advisories |

## Missing Critical Features

| Feature | Problem | Priority |
|---------|---------|----------|
| Token Refresh | No automatic refresh before expiration | High |
| Session Recovery | Timer state not persisted across app restarts | High |
| Offline Mode | No support for offline operation with local queue | Medium |
| Task Deletion with Confirmation | No recycle bin sync to backend | Medium |
| E2E OAuth Tests | No complete sign-in flow tests | High |

## Test Coverage Gaps

| Area | Coverage | Priority |
|------|----------|----------|
| OAuth Flow | No E2E tests | High |
| Cross-Device Sync | Limited integration tests | High |
| Performance Benchmarks | No timer accuracy tests | Medium |
| Conflict Resolution | Clock skew scenarios not tested | High |

## Recommendation Summary

**Immediate Actions:**
1. Implement token revocation endpoint (`/api/auth/revoke`)
2. Add token expiration checking in `AuthManager`
3. Fix `ApiClient.getAccessToken()` to properly retrieve from Keychain
4. Add startup validation for JWT secret configuration

**Short-Term Improvements:**
1. Implement automatic token refresh before expiration
2. Add session state persistence across app restarts
3. Implement proper error presentation in SettingsView
4. Add E2E tests for OAuth flow

**Long-Term Enhancements:**
1. Split `AnalyticsService` into smaller focused services
2. Implement pagination for session listing
3. Add WebSocket for real-time timer sync
4. Implement comprehensive crash reporting

---

*Concerns audit: 2026-04-20*
