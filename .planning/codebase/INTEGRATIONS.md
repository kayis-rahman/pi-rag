# TimeBeam Integrations

## Database

### PostgreSQL

**Connection:** `jdbc:postgresql://localhost:5432/timebeam`

**Usage:**
- User authentication and profile data
- Session records (work sessions, breaks)
- Task management
- Timer state synchronization
- Device registration

**Tables:**
- `users` - User accounts
- `session_records` - Work session history
- `tasks` - User tasks
- `timer_states` - Current timer state per user
- `user_devices` - Registered devices
- `refresh_tokens` - Token management
- `timer_events` - Event history

## Authentication

### Google Sign-In (OAuth 2.0)

**Endpoint:** `POST /api/auth/login`
**Flow:** Email → Google token → JWT generation
**Token Storage:** Keychain Services (iOS/macOS)

### JWT Authentication

**Library:** jjwt 0.11.5
**Format:** Bearer token in Authorization header
**Refresh:** Separate refresh token mechanism

## Push Notifications

### Apple Push Notification Service (APNs)

**Library:** Pushy 0.15.4
**Usage:** Device registration, token updates
**Endpoint:** `POST /api/sessions/devices/apns-token`

## External APIs

### Backend API Endpoints

**Base URL:** Configured via `API_BASE_URL` in Info.plist

**Authenticated Routes:**
- `POST /api/sessions/start` - Start work session
- `POST /api/sessions/{id}/stop` - Stop session
- `GET /api/sessions` - List sessions
- `POST /api/sessions/timer/state` - Push timer state
- `GET /api/sessions/timer/state` - Pull timer state
- `POST /api/sessions/timer/action` - Push timer action
- `POST /api/tasks` - Create task
- `GET /api/tasks` - List tasks
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task
- `GET /api/analytics/last7days` - Weekly analytics
- `GET /api/analytics/streak` - Productivity streak
- `GET /api/analytics/top-window` - Top productive window

### Unauthenticated Routes:
- `POST /api/auth/login` - Login (email only)

## Security Integrations

| Component | Integration |
|-----------|-------------|
| Password validation | Regex email validation |
| Token validation | JWT signature verification |
| CORS | Configured in SecurityConfig |
| HTTPS | App Transport Security (ATS) enforced |

## Third-Party Dependencies

| Library | Purpose | Security Scan |
|---------|---------|---------------|
| spring-boot-starter-test | Unit testing | Verify CVEs |
| mockito-core | Mocking | Verify CVEs |
| h2database | In-memory test DB | Verify CVEs |
