# TimeBeam Stack

## Languages & Runtimes

| Component | Language | Version | Notes |
|-----------|----------|---------|-------|
| Backend | Java | 17 | Spring Boot 3.2.0 |
| iOS/macOS App | Swift | 5.9+ | SwiftUI, Swift Concurrency |
| Tests | Java | 17 | JUnit 5, Mockito |

## Backend Frameworks & Libraries

| Library | Purpose | Version |
|---------|---------|---------|
| Spring Boot | Web framework | 3.2.0 |
| Spring Web | REST API | Built-in |
| Spring WebSocket | Real-time sync | Built-in |
| Spring Data JPA | Database access | Built-in |
| Spring Security | Auth | Built-in |
| JWT (jjwt) | Token auth | 0.11.5 |
| MapStruct | DTO mapping | 1.5.5.Final |
| Lombok | Boilerplate reduction | 1.18.32 |
| PostgreSQL Driver | Database | Runtime |
| Pushy | APNs push | 0.15.4 |
| SpringDoc | OpenAPI/Swagger | 2.1.0 |

## Mobile App Dependencies

| Framework | Purpose | Notes |
|-----------|---------|-------|
| SwiftUI | UI framework | Native iOS/macOS |
| Swift Concurrency | Async/await | Modern concurrency |
| URLSession | HTTP client | Network layer |
| Keychain Services | Secret storage | Secure token storage |
| UserNotifications | Push notifications | iOS/macOS |

## Testing Frameworks

| Component | Framework | Purpose |
|-----------|-----------|---------|
| Backend Unit Tests | JUnit 5 + Mockito | Service/controller tests |
| Backend Integration Tests | SpringBootTest + Testcontainers | DB integration |
| iOS Unit Tests | XCTest | Unit tests |
| iOS Integration Tests | XCTest | Integration tests |
| E2E Tests | Playwright (inferred) | Cross-platform flows |

## Build Tools

| Tool | Purpose |
|------|---------|
| Maven | Backend build/dependency management |
| Xcode | iOS/macOS build |
| Swift Package Manager | Optional Swift dependencies |

## Configuration Files

| File | Purpose |
|------|---------|
| `back-end/pom.xml` | Maven build config |
| `apple/TimeBeam/TimeBeam/Info.plist` | iOS app config |
| `back-end/src/main/resources/application.yml` | Spring config |

## External Services

| Service | Purpose |
|---------|---------|
| PostgreSQL | Primary database |
| Apple Push Notification Service (APNs) | Push notifications |
| Google Sign-In | OAuth authentication |
