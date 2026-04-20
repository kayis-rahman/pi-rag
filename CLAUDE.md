# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a cross-platform productivity application called TimeBeam, featuring:
- Mobile frontend applications for iOS and macOS (SwiftUI)
- Backend server (Spring Boot Java 17)
- Synchronized timer functionality across devices

## Architecture

The application follows a modern layered architecture with clear separation of concerns:

### Frontend (iOS/macOS)
1. **Domain Layer**: Core data models (SessionRecord, TimerState)
2. **Infrastructure Layer**: Networking, logging, synchronization managers
3. **Presentation Layer**: SwiftUI views organized by platform
4. **Services Layer**: Business logic services (Auth, Timer, Task)

### Backend (Spring Boot Java)
1. **Presentation Layer**: REST controllers exposing API endpoints
2. **Application Layer**: Business logic services
3. **Domain Layer**: Core business entities and value objects
4. **Infrastructure Layer**: Repositories, external integrations, persistence
5. **Configuration Layer**: Security, logging, and application setup

## Key Features

### Cross-Device Synchronization
- Real-time timer state synchronization between iOS and macOS devices
- Event-based synchronization for actions (start, pause, reset)
- Timestamp-based conflict resolution
- Device identification and tracking
- Robust error handling and retry mechanisms

### Authentication
- Google Sign-In integration
- JWT-based authentication
- Secure token storage and management

### Analytics & Tracking
- Session recording and tracking
- Productivity analytics (streaks, window analysis)
- Usage insights dashboard

## Development Environment

### Frontend (iOS/macOS)
- Xcode project structure
- Swift 5+ with SwiftUI
- iOS 14+/macOS 12+ deployment targets
- CocoaPods/Maven dependencies

### Backend (Spring Boot)
- Java 17+ with Spring Boot 3.x
- PostgreSQL database (H2 for testing)
- Maven build system
- Docker support for containerization

### Build Commands
Frontend:
- `xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam iOS" build` - Build iOS version
- `xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam macOS" build` - Build macOS version

Backend:
- `cd back-end && mvn clean package -DskipTests` - Build backend
- `cd back-end && mvn -DskipTests spring-boot:run` - Run backend
- `cd back-end && docker-compose up --build` - Run with Docker

### Testing
- Frontend: Unit tests, integration tests, UI tests
- Backend: Unit tests, integration tests with H2 in-memory DB

## Backend API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user and return JWT

### Sessions
- `POST /api/sessions` - Create session record
- `GET /api/sessions` - List session records
- `DELETE /api/sessions/{id}` - Delete session record

### Analytics
- `POST /api/analytics/last7days` - Get last 7 days analytics
- `POST /api/analytics/streak` - Get productivity streak
- `POST /api/analytics/top-window` - Get top productive window

### Timer Synchronization
- `POST /api/timer/state` - Push timer state from device
- `GET /api/timer/state` - Pull latest timer state
- `POST /api/timer/action` - Push timer action from device

## Database Schema

### Users Table
- `id` UUID PRIMARY KEY
- `email` VARCHAR UNIQUE NOT NULL
- `display_name` VARCHAR NOT NULL
- `is_admin` BOOLEAN NOT NULL

### Session Records Table
- `id` UUID PRIMARY KEY
- `user_id` UUID NOT NULL (FK to users.id)
- `started_at` TIMESTAMP
- `duration_seconds` BIGINT
- `kind` VARCHAR (WORK/SHORT_BREAK/LONG_BREAK)

### Timer States Table
- `user_id` UUID PRIMARY KEY
- `phase` VARCHAR
- `remaining_seconds` INTEGER
- `running` BOOLEAN
- `work_duration_minutes` INTEGER
- `break_duration_minutes` INTEGER
- `long_break_duration_minutes` INTEGER
- `auto_start_next` BOOLEAN
- `short_breaks_completed` INTEGER
- `total_duration` INTEGER
- `start_timestamp` TIMESTAMP
- `pause_timestamp` TIMESTAMP
- `last_updated_at` TIMESTAMP
- `updated_by_device_id` UUID

## Platform-Specific Considerations

### iOS Client
- UIKit integration via `@UIApplicationDelegateAdaptor`
- Tab-based navigation structure
- Notification permission handling
- Audio playback for chime sounds

### macOS Client
- Native SwiftUI implementation
- Menu-based configuration controls
- Material design elements
- Full window support

### Backend Services
- RESTful API with JSON responses
- JWT-based authentication
- PostgreSQL persistence
- WebSocket support for real-time notifications

## File Structure Highlights

### Frontend
- `apple/TimeBeam/TimeBeam/`: Main application directory
- `Domain/Models/`: Core data models
- `Infrastructure/`: Networking, logging, and system utilities
- `Presentation/Views/`: UI components organized by platform
- `Application/Services/`: Business logic services

### Backend
- `back-end/src/main/java/com/sparkage/timebeam/`: Main backend package
- `presentation/controller/`: REST API endpoints
- `application/service/`: Business logic services
- `domain/model/`: Business entities
- `infrastructure/persistence/`: Database entities and repositories
- `infrastructure/config/`: Spring configuration files

## Key Technical Details

### Timer Synchronization Flow (Backend)
1. Devices push timer state updates to backend
2. State conflicts resolved via timestamp-based approach
3. Real-time notifications sent to connected devices
4. Optimistic locking prevents race conditions

### Enhanced Timer Synchronization Features
- Improved error handling with retry logic
- State validation to prevent data corruption
- Network resilience with timeout protections
- Comprehensive logging for debugging synchronization issues
- Timestamp-based conflict resolution for collaborative control

### Authentication Flow
1. Google Sign-In handled in frontend
2. Email sent to backend for registration/login
3. JWT tokens issued for API access
4. Secure token storage on devices

### Logging and Monitoring
- Centralized logging using SLF4J
- Structured logging with categories
- Debug/Info/Warning/Error/Fault levels
- File logging capability for debugging

### Testing Strategy
- Frontend: Comprehensive test suites for all layers
- Backend: Unit tests, integration tests, and API validation
- End-to-end testing with Docker Compose

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health