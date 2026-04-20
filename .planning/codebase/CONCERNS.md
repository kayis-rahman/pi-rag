# TimeBeam Concerns

## Technical Debt

### High Priority

| Issue | Location | Impact | Notes |
|-------|----------|--------|-------|
| Token revocation endpoint | AuthManager.swift:134 | Security | OAuth token not revoked on sign-out |
| Access token from Keychain | ApiClient.swift:138 | Security | TODO to implement actual token retrieval |
| Error alert in SettingsView | SettingsView.swift:71 | UX | Error message only printed to console |
| Watch token transfer | WatchConnectivityManager.swift:55 | Feature | Secure token transfer not implemented |
| Sign-in flow on Watch | WatchConnectivityManager.swift:76 | Feature | Sign-in flow not implemented |

### Medium Priority

| Issue | Location | Impact | Notes |
|-------|----------|--------|-------|
| Token expiration check | AuthManager.swift:285 | Security | Expiration not currently tracked |
| Debug logging in production | Multiple files | Performance | #if DEBUG guards present but some print() statements remain |

## Known Issues

### Authentication
- Google Sign-In flow may fail if API_BASE_URL not configured
- Debug print statements expose sensitive data in development builds
- Token revocation not implemented (security gap)

### Timer Sync
- State polling limited to 30+ seconds (performance constraint)
- Conflict resolution uses timestamp-only (may need strategy options)

### Analytics
- Debug logging in AnalyticsService may impact production performance

## Security Concerns

| Category | Issue | Recommendation |
|----------|-------|----------------|
| Secrets | API_BASE_URL in Info.plist | Move to .xcconfig or environment |
| Tokens | No token refresh mechanism | Implement refresh token rotation |
| Logging | Debug prints with tokens | Ensure all sensitive data redacted |
| Network | URLSession.shared | Consider custom session with timeout policies |

## Performance Considerations

| Area | Concern | Mitigation |
|------|---------|------------|
| Network | State polling every 30+ seconds | Consider WebSocket for real-time sync |
| Memory | Session data duplication | Implement pagination for large datasets |
| Battery | Background sync frequency | Optimize based on device activity |

## Fragile Areas

### Authentication Flow
- Heavy reliance on Google Sign-In integration
- PKCE implementation must be perfect for Apple Sign-In
- Token storage in Keychain requires proper access group configuration for iCloud sync

### Cross-Device Sync
- Timestamp-based conflict resolution may have edge cases
- Network partition handling not fully tested
- Device identification must be robust to prevent feedback loops

## Observability Gaps

| Component | Missing |
|-----------|---------|
| Backend | No structured logging |
| Mobile | No crash reporting integration |
| Analytics | No performance metrics collection |

## Testing Gaps

| Area | Coverage |
|------|----------|
| Backend | Missing integration tests for WebSocket |
| Mobile | No UI tests for timer state conflict resolution |
| E2E | No test for offline queueing scenarios |

## Migration Risks

| Scenario | Risk | Mitigation |
|----------|------|------------|
| Database schema changes | Data loss | Use Flyway/Liquibase migrations |
| API breaking changes | Client breakage | Version API endpoints |
| Token format changes | Auth failure | Implement token migration strategy |
