# External Integrations

**Analysis Date:** 2026-04-20

## APIs & External Services

**[Authentication Providers]:**
- **Google Sign-In (OAuth 2.0)**
  - SDK/Client: Custom implementation via URLScheme
  - Endpoint: `https://accounts.google.com/o/oauth2/v2/auth`
  - Token endpoint: `https://oauth2.googleapis.com/token`
  - Config: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI` in Info.plist

- **Apple Sign-In**
  - SDK/Client: AuthenticationServices framework
  - Endpoint: `https://appleid.apple.com/auth/authorize`
  - Token endpoint: `https://appleid.apple.com/auth/token`
  - Flow: PKCE-based OAuth 2.0

**[Backend API]:**
- **TimeBeam Backend**
  - Base URL: Configured via `API_BASE_URL` in Info.plist (default: `http://192.168.0.173:8080`)
  - Auth: Bearer JWT token in Authorization header
  - SDK/Client: Custom `ApiClient` in `apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift`

## Data Storage

**Databases:**
- **PostgreSQL**
  - Connection: `SPRING_DATASOURCE_URL` (env var, default: `jdbc:postgresql://localhost:5432/timebeam`)
  - Client: Spring Data JPA with Hibernate
  - Driver: PostgreSQL JDBC driver (runtime scope)
  - Schema: `ddl-auto: update`

**File Storage:**
- **Local filesystem only** - Log files stored in `back-end/logs/`

**Caching:**
- None detected

## Authentication & Identity

**Auth Provider:**
- Custom JWT-based authentication
- Implementation: `back-end/src/main/java/com/sparkage/timebeam/infrastructure/external/JwtUtils.java`
- Flow: Email login → JWT access token + refresh token
- Token Storage: iOS/macOS Keychain Services (`KeychainStore.swift`)

**Refresh Token Management:**
- `RefreshToken` entity: `back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/RefreshToken.java`
- 7-day expiration for refresh tokens
- Revocation via `revokeTokensForUser()` in `AuthService.java`

## Monitoring & Observability

**Error Tracking:**
- None detected (internal logging only)

**Logs:**
- Backend: SLF4J with Logback
  - Console pattern: `%d{yyyy-MM-dd HH:mm:ss} %-5level [%thread] %logger{36} - %msg%n`
  - File: `logs/timebeam.log` (max 10MB, 1 history)
  - Level: DEBUG for `com.sparkage.timebeam`, INFO for Spring

**Logging in iOS/macOS:**
- `AppLogger.swift` - Unified logging wrapper using os.log
- Categories: auth, sync, timer, api, lifecycle, ui, general
- File logging to `back-end/logs/` (DEBUG builds only)

## CI/CD & Deployment

**Hosting:**
- Development: Local (piworm.local:5432 for PostgreSQL, 8080 for backend)
- Production: Not yet configured

**CI Pipeline:**
- GitHub Actions workflows in `.github/workflows/`
- Backend CI: `.github/workflows/backend.yml`
  - Java 17 setup
  - Maven build and test
  - JaCoCo coverage reporting
  - SonarCloud analysis

## Environment Configuration

**Required env vars (backend `.env`):**
- `POSTGRES_DB` - Database name (default: `timebeam`)
- `POSTGRES_USER` - Database user (default: `timebeam`)
- `POSTGRES_PASSWORD` - Database password (default: `timebeam`)
- `SPRING_DATASOURCE_HOST` - Database host (default: `piworm.local`)
- `SPRING_DATASOURCE_PORT` - Database port (default: `5432`)
- `JWT_SECRET` - JWT signing secret

**iOS/macOS Config (Info.plist):**
- `API_BASE_URL` - Backend API base URL
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` - Google OAuth client secret
- `GOOGLE_REDIRECT_URI` - OAuth redirect URI

**Secrets location:**
- Backend: `back-end/.env` (gitignored)
- iOS/macOS: Keychain Services for tokens, Info.plist for app config

## Webhooks & Callbacks

**Incoming:**
- **Apple Sign-In Callback:** `com.sparkage.time-beam.ios://` (iOS), `com.sparkage.time-beam://` (macOS)
- **Google OAuth Callback:** Same redirect URIs as above

**Outgoing:**
- **APNs Push Notifications:** Apple Push Notification Service
  - Key file: `AuthKey_3UJ4UY4Q6Y.p8`
  - Key ID: `3UJ4UY4Q6Y`
  - Team ID: `425MSY8FLG`
  - Bundle IDs: `com.sparkage.timebeam.ios`, `com.sparkage.timebeam`
  - Service: `PushNotificationService.java`
  - Topic: Silent push notifications for timer sync across devices

## Apple Services

**Apple Push Notification Service (APNs):**
- Used for: Timer sync notifications across devices
- Library: `com.eatthepath:pushy` 0.15.4
- Endpoint: `sendTimerSyncPush()`, `sendTimerEventPush()`
- Development/Production: Configurable via `APNS_ENABLED`, `APNS_PRODUCTION`

**CloudKit (iCloud Sync):**
- Implementation: `iCloudSyncManager.swift`
- Usage: Sync timer settings across devices via `NSUbiquitousKeyValueStore`
- Features: Sync workDuration, breakDuration, longBreakDuration, autoStartNextSession

---

*Integration audit: 2026-04-20*