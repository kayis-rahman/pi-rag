# API Rules

> Extends [rules/common/patterns.md](../../rules/common/patterns.md) with TimeBeam API specifics.

## API Response Format
Use consistent envelope: success indicator, data payload, error message, metadata for pagination.

## Backend
- Spring Boot REST under `back-end/src/main/java/com/sparkage/timebeam/`
- Layered architecture: `application/` (services) → `domain/` (entities) → `infrastructure/` (external) → `presentation/` (controllers)
- Health check: `/api/auth/health`
- Port 8080 (dev), 8081 (e2e)
- DTOs never leak entities to API layer

## iOS/macOS Clients
- Swift package: `apple/TimeBeam/`
- Xcode project: `apple/TimeBeam/TimeBeam.xcodeproj`
- Layered architecture: `Application/Services/` → `Domain/Models/` → `Infrastructure/` → `Presentation/Views/`
- Schemes: "TimeBeam iOS", "TimeBeam macOS", "TimeBeam"
- Keychain for token storage (Security.framework)
- Timer sync: `TimerActionDto` sends `action` (String) — backend must accept via `@JsonAlias`

## Timer Sync API Contract
- `POST /api/timer/actions` — submit timer action with `action` field (String)
- Backend `TimerActionDto` accepts both `action` and `actionType` via `@JsonAlias`
- `GET /api/timer/state` — pull current timer state
- `POST /api/devices/register` — register device for push notifications
- Silent APNs push carries `{"type": "timer_sync"}` in userInfo

## Docker (pi-node context)
- localhost → piworm.local when Docker context is pi-node
- Postgres: `piworm.local:5432`
- Backend: `piworm.local:8080`
- E2E DB: `postgresql://timebeam:timebeam@piworm.local:5432/timebeam_e2e`
