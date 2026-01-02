# Architecture Overview

This document provides a high-level overview of TimeBeam's system architecture, technology stack, and design principles.

## System Overview

TimeBeam is a cross-platform Pomodoro timer application with client-server architecture:

```
┌─────────────────────────────────────────────────────────┐
│                   User Interface Layer                  │
├─────────────────────────────────────────────────────────┤
│  iOS App │  macOS App │  watchOS App    │
├─────────────────────────────────────────────────────────┤
│                   REST API Layer                      │
├─────────────────────────────────────────────────────────┤
│              Spring Boot Backend                     │
├─────────────────────────────────────────────────────────┤
│                 Data Layer                            │
├─────────────────────────────────────────────────────────┤
│            PostgreSQL Database                         │
└─────────────────────────────────────────────────────────┘
```

## Technology Stack

### Frontend (Client Applications)

#### iOS/macOS/watchOS
- **Language**: Swift 5.9+
- **Framework**: SwiftUI (declarative UI)
- **Architectural Pattern**: MVVM with Domain-Driven Design
- **Authentication**: Google Sign-In SDK
- **Data Persistence**:   - UserDefaults (settings, session state)
  - Keychain (JWT tokens, secure data)
  - Core Data (session history, local cache)

#### Web (Future)
- **Framework**: To be determined (React/Vue/Svelte options)
- **Authentication**: Google Sign-In Web SDK
- **Status**: Not implemented (MVP focuses on Apple platforms)

### Backend (Server)

#### Spring Boot 3.x
- **Language**: Java 17
- **Framework**: Spring Boot 3.x
- **Build Tool**: Maven 3.8+
- **Architecture Layer**:   - Presentation: REST Controllers (Spring MVC)
  - Application: Business Services, Use Cases
  - Domain: Entities, Value Objects, Domain Services
  - Infrastructure: JPA Repositories, External Services

#### Database
- **Database**: PostgreSQL 15+
- **ORM**: Spring Data JPA (Hibernate)
- **Connection Pooling**: HikariCP (built into Spring Boot)
- **Migration Strategy**: Manual (future: Flyway or Liquibase)
- **Schema**: Users, SessionRecords, RefreshTokens

#### Security
- **Authentication**: JWT (JSON Web Tokens)
- **Authorization**: Role-based access control (prepared for future)
- **CORS**: Configured for frontend origins
- **Validation**: Jakarta Bean Validation
- **Secrets Management**: Environment variables (not hardcoded)

## Architecture Layers

### 1. Domain Layer (Business Logic)
**Purpose**: Core business logic and domain rules

**Contents**:
- **Entities**: JPA entity mappings (User, SessionRecord)
- **Value Objects**: Timer configuration, Session durations
- **Domain Services**: Complex business operations
- **Repository Interfaces**: Contracts for data access

**Responsibilities**:
- Define business entities and their relationships
- Enforce business rules and invariants
- Provide domain-specific services
- Define repository contracts

### 2. Application Layer (Orchestration)
**Purpose**: Coordinate domain objects for use cases

**Contents**:
- **Application Services**: Orchestrate domain operations
- **DTOs (Data Transfer Objects)**: API request/response models
- **Mappers**: Map between entities and DTOs (MapStruct)

**Responsibilities**:
- Implement use cases and workflows
- Coordinate multiple domain services
- Validate business rules
- Transform data for different layers

### 3. Infrastructure Layer (Technical Implementation)
**Purpose**: Implement technical concerns and external integrations

**Contents**:
- **Persistence**: JPA repository implementations
- **External Services**: Google Sign-In API integration (backend accepts email only)
- **Configuration**: Spring Boot configuration
- **Security**: JWT utilities, authentication filters
- **Exception Handling**: Global exception handlers

**Responsibilities**:
- Provide data access implementations
- Integrate with external services
- Handle cross-cutting concerns (logging, security)
- Manage technical configurations

### 4. Presentation Layer (External Interfaces)
**Purpose**: Expose functionality to external systems and users

**Contents**:
- **REST Controllers**: API endpoints
- **DTOs**: API request/response models
- **OpenAPI/Swagger**: API documentation
- **Filters**: JWT authentication filter, CORS filter

**Responsibilities**:
- Expose RESTful API endpoints
- Validate incoming requests
- Return appropriate HTTP responses
- Handle authentication and authorization

## Data Flow

### Timer Session Flow

```
1. User starts timer (iOS/macOS/watchOS App)
   ↓
2. Create local session record
   ↓
3. Start timer countdown
   ↓
4. Periodically sync state to backend (via REST API)
   ↓
5. Backend stores session record in PostgreSQL
   ↓
6. Backend aggregates session data for analytics
   ↓
7. Frontend fetches analytics (daily/weekly totals, streaks)
   ↓
8. Display statistics in Analytics view
```

### Authentication Flow

```
1. User taps Google Sign-In button (iOS/macOS/watchOS)
   ↓
2. Google Sign-In SDK handles authentication
   ↓
3. App receives ID token and user info
   ↓
4. App sends ID token to backend (via POST /api/auth/login)
   ↓
5. Backend validates with Google (if configured) or creates/updates user
   ↓
6. Backend generates and returns JWT access token
   ↓
7. App stores JWT token in Keychain (secure storage)
   ↓
8. App uses JWT in Authorization header for subsequent requests
   ↓
9. Backend validates JWT on each request
   ↓
10. Request proceeds if token is valid
```

## Key Design Principles

### Domain-Driven Design (DDD)
- Bounded contexts for business domains (Users, Sessions, Analytics)
- Rich domain models with behavior
- Domain events for cross-context communication
- Repository pattern for data access

### SOLID Principles
- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension via interfaces/inheritance
- **Liskov Substitution**: Subtypes are substitutable for base types
- **Interface Segregation**: Small, focused interfaces
- **Dependency Inversion**: Depend on abstractions, not concretions

### Clean Code
- **DRY** (Don't Repeat Yourself): Eliminate code duplication
- **KISS** (Keep It Simple, Stupid): Prefer simple solutions
- **YAGNI** (You Aren't Gonna Need It): Don't implement unnecessary features

### Security First
- Input validation on all endpoints
- Secure storage of sensitive data (Keychain)
- HTTPS for all communications
- Proper error handling without exposing sensitive information

## Scalability Considerations

### Backend
- Stateless REST API (JWT-based authentication)
- Connection pooling for database efficiency
- Caching strategy (for frequently accessed data)
- Horizontal scaling support (multiple instances)

### Frontend
- Efficient data fetching and caching
- Optimized SwiftUI view updates
- Background sync to avoid blocking UI
- Lazy loading of large datasets

## Performance Targets

### Backend
- API response time: < 500ms for p95
- Database query time: < 100ms for p95
- Support 100+ concurrent users
- Database connection pool: 10-20 connections

### Frontend
- App launch time: < 3 seconds
- Timer update frequency: 60 FPS (smooth animations)
- API call time: < 2 seconds (network dependent)
- Memory usage: < 150MB on iOS/macOS

## Security Architecture

### Authentication & Authorization
- JWT-based stateless authentication
- Token expiration: 24 hours (configurable)
- Refresh token flow (prepared for future)
- Role-based access control (infrastructure in place)

### Data Protection
- Encryption at rest (PostgreSQL)
- HTTPS in transit (SSL/TLS)
- Secure key storage (Keychain for tokens)
- No sensitive data in logs

### Input Validation
- Jakarta Bean Validation on all DTOs
- SQL injection prevention (parameterized queries)
- XSS prevention (input sanitization)
- CSRF protection (token-based for state-changing operations)

## Monitoring & Observability

### Logging
- **Backend**: SLF4J with Logback
- **Frontend**: AppLogger (Apple Unified Logging)
- Structured logging with correlation IDs
- Log levels: TRACE, DEBUG, INFO, WARN, ERROR

### Metrics
- Spring Boot Actuator for health checks
- Application performance metrics
- Database query performance monitoring
- API endpoint performance tracking

## Deployment Architecture

### Backend
- Docker containerization
- Docker Compose for local development
- Ready for cloud deployment (Elastic Beanstalk, Render, GCP App Engine)
- Environment-based configuration

### Frontend
- App Store distribution (iOS/macOS)
- TestFlight for beta testing
- Side-loading for development
- Watch App Store for watchOS

## Related Documentation

- [Design Decisions](design-decisions.md) - Detailed design choices and tradeoffs
- [Backend API Reference](../implementation-guides/backend/api-reference.md) - Complete API documentation
- [Code Style & Standards](../codestyle/) - Detailed coding standards

---

**Last Updated**: January 2026
