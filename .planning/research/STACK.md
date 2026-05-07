# Technology Stack

**Project:** TimeBeam Productivity Application
**Researched:** 2026-02-28

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| SwiftUI | Latest | UI Development | Modern declarative UI framework for iOS/macOS |
| Spring Boot | 3.x | Backend Framework | Mature, feature-rich Java framework with auto-configuration |
| Java | 17 | Runtime | LTS Java version with strong ecosystem support |
| Xcode | 15+ | iOS/macOS Development | Official IDE with comprehensive tooling |
| Swift | 5+ | iOS/macOS Language | Modern, safe, and performant language for Apple platforms |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | 15+ | Production Database | Reliable, ACID-compliant relational database |
| H2 | In-memory | Testing | Fast, in-memory database for unit/integration tests |
| Redis | Optional | Caching | Can be used for session caching or real-time notifications |

### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Docker | 24+ | Containerization | Consistent environments for dev, staging, prod |
| Docker Compose | 2+ | Multi-container orchestration | Simple setup for local development |
| GitHub Actions | Latest | CI/CD | Cloud-native automation with broad adoption |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Alamofire | 5.x | Networking | iOS client HTTP requests |
| Combine | Latest | Reactive programming | iOS client async operations |
| JWT | 4.x | Authentication | Backend JWT handling |
| Spring Data JPA | 3.x | ORM | Database abstraction layer |
| Lombok | 1.18+ | Code reduction | Java backend POJOs |
| Mockito | 5.x | Testing | Unit testing mocks |
| JUnit 5 | 5.x | Testing | Backend unit/integration tests |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Backend Framework | Spring Boot | Express.js | Less suitable for enterprise features |
| iOS Framework | SwiftUI | UIKit | SwiftUI is the modern standard, more maintainable |
| Database | PostgreSQL | MySQL | PostgreSQL offers superior features for this application |
| Authentication | JWT | OAuth 2.0 | JWT is simpler for this specific use case |

## Installation

```bash
# Frontend (iOS/macOS)
# No explicit installation needed - Xcode project structure already exists
# Build iOS: xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam iOS" build
# Build macOS: xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam macOS" build

# Backend
cd back-end
mvn clean install
# Or for running: mvn spring-boot:run
```

## Sources

- Official documentation from CLAUDE.md
- Spring Boot 3.x Release Notes
- Apple Developer Documentation (SwiftUI, Combine)