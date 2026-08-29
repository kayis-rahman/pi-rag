# Technology Stack

**Analysis Date:** 2026-04-20

## Languages

**Primary:**
- **Swift** 5.9+ - iOS/macOS/watchOS application code
- **Java** 17 - Backend application code

**Secondary:**
- **SwiftUI** - iOS/macOS/watchOS user interface framework
- **Spring Boot** 3.2.0 - Backend framework

## Runtime

**Backend:**
- Java 17
- Spring Boot 3.2.0
- Maven 3.x (build/dependency management)
- Container: PostgreSQL 15 (Docker Compose)

**iOS/macOS/watchOS:**
- Swift 5.9+
- SwiftUI 5.0
- Swift Concurrency (async/await)
- Xcode 16.0+ (iOS/macOS), Xcode 26.0+ (watchOS)
- Deployment targets:
  - iOS: 18.0
  - macOS: 15.0
  - watchOS: 26.0
  - xrOS: 2.0

**Package Manager:**
- Maven (backend) - `back-end/pom.xml`
- Swift Package Manager / Xcode project - `apple/TimeBeam/TimeBeam.xcodeproj`

## Frameworks

**Backend (Spring Boot):**
- Spring Boot 3.2.0 - Core framework
- Spring Web - REST API endpoints
- Spring WebSocket - Real-time communication
- Spring Data JPA - Database persistence with Hibernate
- Spring Security - Authentication/authorization
- Spring Validation - Bean validation

**Testing (Backend):**
- Spring Boot Test - Integration testing
- JUnit 5 - Unit testing framework
- Mockito 5.3.1 - Mocking framework
- H2 Database - In-memory test database
- JaCoCo 0.8.11 - Code coverage (80% line, 75% branch target enforced)
- Testcontainers - Integration tests with real services

**iOS/macOS/watchOS:**
- SwiftUI 5.0 - User interface framework
- Combine - Reactive programming
- CloudKit - iCloud synchronization (iCloudSyncManager)
- UserNotifications - Push notifications
- WatchConnectivity - Apple Watch communication
- AuthenticationServices - Apple Sign-In
- CryptoKit - PKCE implementation for OAuth

**Testing (iOS/macOS/watchOS):**
- XCTest - Unit and UI testing framework
- Swift Testing - Modern testing framework

**Build/Dev:**
- Xcode 16.0+ - iOS/macOS build
- Maven - Backend build
- SwiftLint - Code style enforcement (configured in `.swiftlint.yml`)
- SwiftFormat - Auto-formatting
- Docker Compose - PostgreSQL management

## Key Dependencies

**Backend (`back-end/pom.xml`):**
- `spring-boot-starter-web` 3.2.0 - REST API framework
- `spring-boot-starter-data-jpa` - JPA/Hibernate ORM
- `spring-boot-starter-security` - Security framework
- `spring-boot-starter-validation` - Bean validation
- `spring-boot-starter-actuator` - Production monitoring
- `spring-boot-starter-websocket` - WebSocket support
- `io.jsonwebtoken:jjwt` 0.11.5 - JWT token handling
- `org.postgresql:postgresql` - PostgreSQL JDBC driver
- `com.eatthepath:pushy` 0.15.4 - Apple Push Notification Service
- `org.mapstruct:mapstruct` 1.5.5.Final - Object mapping
- `org.projectlombok:lombok` 1.18.32 - Code generation
- `org.springdoc:springdoc-openapi-starter-webmvc-ui` 2.1.0 - OpenAPI/Swagger UI

**iOS/macOS (`apple/TimeBeam/TimeBeam/Info.plist`):**
- Firebase Analytics (GoogleService-Info.plist)
- Apple Sign-In (ASAuthorizationAppleIDProvider)
- Google OAuth 2.0
- Keychain Services for secure storage
- CloudKit for iCloud sync

## Configuration

**Environment:**
- Backend: Spring Boot with `application.yml`, `application-dev.yml`, `application-e2e.yml`
- iOS/macOS: Info.plist with `API_BASE_URL`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- Environment variable file: `back-end/.env` (not in git)
- API Base URL: `http://192.168.0.173:8080` (configured in Xcode project)

**Key Configurations:**
- Backend runs on port 8080 (8081 for e2e tests)
- JWT expiration: 86400000ms (1 day)
- APNs configured with key path: `/Users/kayisrahman/Documents/workspace/ideas/time-beam-firebase/AuthKey_3UJ4UY4Q6Y.p8`
- Key ID: `3UJ4UY4Q6Y`, Team ID: `425MSY8FLG`
- PostgreSQL connection via environment variables

## Platform Requirements

**Development:**
- Xcode 16.0+ for iOS/macOS development
- Java 17 JDK for backend development
- PostgreSQL 15 for database
- Swift 5.9+ for Swift code
- Maven 3.x for backend build

**Production:**
- iOS 18.0+ devices
- macOS 15.0+ devices
- watchOS 26.0+ devices
- Backend: Java 17 runtime, PostgreSQL 15

## Database Schema

**Tables:**
- `users` - User accounts (id, email, displayName, isAdmin)
- `session_records` - Work session history (id, userId, deviceId, taskId, startedAt, durationSeconds, kind, completed, interrupted, interruptionReason, createdAt)
- `tasks` - User tasks (id, userId, title, description, status, createdAt, updatedAt)
- `timer_states` - Current timer state per user (userId, phase, remainingSeconds, running, durations, timestamps)
- `user_devices` - Registered devices (id, userId, deviceId, deviceName, deviceType, platform, active, apnsToken)
- `refresh_tokens` - Token management (id, userId, token, expiresAt)
- `timer_events` - Event history

---

*Stack analysis: 2026-04-20*