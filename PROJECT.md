# TimeBeam Project Documentation

## What This Is

TimeBeam is a cross-platform productivity application that provides synchronized timer functionality across iOS and macOS devices. The application enables users to maintain consistent productivity tracking and Pomodoro timer states across all their devices in real-time.

The system consists of:
- Mobile frontend applications for iOS and macOS (SwiftUI)
- Backend server (Spring Boot Java 17)
- Real-time synchronization of timer states with conflict resolution

## Core Value

The most important thing that must work is **real-time, reliable cross-device timer synchronization**. This ensures that when a user starts, pauses, or resets a timer on one device (iOS or macOS), that change is instantly reflected on all other devices, maintaining consistent productivity tracking regardless of which device is being used.

## Requirements

### Validated Requirements

#### Authentication
- Google Sign-In integration for user authentication
- JWT-based authentication system with secure token management
- Secure token storage and management on client devices
- User registration and login functionality

#### Timer Synchronization
- Cross-device synchronization: Real-time timer state synchronization between iOS and macOS devices
- Event-based synchronization: Immediate propagation of timer actions (start, pause, reset, stop, advance)
- State-based synchronization: Periodic full state synchronization with conflict resolution
- Timestamp-based conflict resolution: Newer timestamps always win for collaborative control
- Device identification and tracking: Prevention of feedback loops with device ID tracking
- Network resilience: Timeout protection and graceful degradation during network failures

#### Core Functionality
- Pomodoro timer implementation: Standard work/break cycles with configurable durations
- Cross-platform support: iOS and macOS native implementations with shared logic
- State management: Complete timer state tracking including phases, remaining time, and session counts
- Action handling: Support for all timer control actions (start, pause, reset, stop, advance)
- Background synchronization: Continuous synchronization even when apps are in background

#### Analytics and Tracking
- Session recording: Comprehensive logging of work sessions and breaks
- Productivity analytics: Streak tracking, window analysis, and usage insights
- Data visualization: Dashboard presentation of productivity metrics
- Historical data: Storage and retrieval of historical session data

### Active Requirements

#### Enhanced Synchronization
- Advanced conflict resolution: Multiple strategies for handling synchronization conflicts
- Offline queueing: Support for disconnected scenarios with local queueing
- Smart sync intervals: Adaptive polling based on device activity and network conditions
- State validation improvements: Enhanced data integrity checks for remote state applications
- Push notification enhancements: More sophisticated real-time update mechanisms

#### Advanced Analytics
- Task-based analytics: Productivity tracking by task completion
- Time allocation insights: Detailed breakdown of time spent on various activities
- Performance trends: Historical analysis of productivity patterns over time
- Customizable dashboards: Flexible visualization options for different user preferences

#### Enhanced Security
- End-to-end encryption: Secure transmission of sensitive timer data
- Multi-factor authentication: Enhanced security options for user accounts
- Audit logging: Comprehensive logging of all timer synchronization events for security monitoring

#### Device Management
- Multi-device support: Seamless handling of multiple devices per user
- Device pairing: Secure device registration and management
- Activity monitoring: Real-time visibility of device activity and synchronization status

#### User Experience Improvements
- Intelligent recommendations: Context-aware suggestions for timer usage
- Customizable interfaces: Personalized UI elements for different user preferences
- Accessibility features: Enhanced support for users with disabilities
- Offline functionality: Core timer functionality available when disconnected

### Out of Scope

#### Future Enhancements
- Machine learning-based productivity insights
- Integration with third-party productivity tools
- Support for additional device types beyond iOS/macOS
- Advanced performance monitoring and analytics

#### Non-functional Requirements
- Third-party plugin architecture
- Multi-language support beyond English
- Legacy system integration
- Cloud backup and restore functionality

## Context

### Project Overview

TimeBeam is designed to solve the problem of inconsistent timer states when using productivity tools across multiple devices. Traditional approaches to Pomodoro timers often result in users having to manually reconfigure their timers when switching between devices, leading to lost productivity and fragmented tracking.

The solution leverages modern mobile development frameworks (SwiftUI for iOS/macOS) and backend technologies (Spring Boot with PostgreSQL) to create a seamless synchronization experience. The system is built with event-driven architecture principles to maximize responsiveness and minimize resource usage.

### Technology Stack

**Frontend (iOS/macOS):**
- Swift 5+ with SwiftUI
- Xcode project structure
- iOS 14+/macOS 12+ deployment targets
- CocoaPods/Maven dependencies

**Backend (Spring Boot):**
- Java 17+ with Spring Boot 3.x
- PostgreSQL database (H2 for testing)
- Maven build system
- Docker support for containerization

### Development Approach

The application follows a phased development approach with clear milestones:
1. Project Setup and Foundation
2. Authentication System
3. Core Timer Functionality
4. Timer Synchronization
5. Analytics and Tracking
6. Polish and Performance

### Current State

The project has been actively developed with working implementations of:
- Core timer functionality on both iOS and macOS
- Backend timer state management with optimistic locking
- Event-based synchronization for timer actions
- Basic authentication with JWT support
- Session recording and analytics capabilities

## Constraints

### Technical Constraints

1. **Database Design**: PostgreSQL is used for production, H2 for testing. Database schema is fixed and backward-compatible changes must be carefully managed.

2. **API Stability**: All API endpoints must maintain stable contracts to prevent breaking existing clients.

3. **Performance Requirements**: Network efficiency is critical, with synchronization polling limited to 30+ second intervals to minimize battery drain and bandwidth usage.

4. **Memory Management**: The system must maintain minimal memory footprint during synchronization operations.

5. **Security**: All sensitive data (tokens, user data) must be handled securely with proper encryption and access controls.

### Operational Constraints

1. **Network Reliability**: The system must gracefully handle network failures with retry mechanisms and timeout protections.

2. **Device Identification**: Each device must have a unique identifier to prevent feedback loops in synchronization.

3. **Timestamp Accuracy**: All synchronization must rely on precise timestamp-based conflict resolution to ensure data consistency.

4. **State Validation**: All incoming timer states must undergo strict validation to prevent data corruption from invalid states.

5. **Error Recovery**: The system must implement robust error recovery and fallback mechanisms for synchronization failures.

### Development Constraints

1. **Language Boundaries**: iOS development is restricted to Swift with SwiftUI, macOS development is restricted to Swift with SwiftUI.

2. **Build Process**: Both frontend and backend must build and test successfully using the defined build commands in CLAUDE.md.

3. **Testing Requirements**: Both frontend and backend must maintain comprehensive test suites covering all critical functionality.

4. **Documentation Standards**: All code changes must be accompanied by appropriate documentation following established patterns.

## Key Decisions

### Architecture and Design

1. **Layered Architecture**: The application follows a modern layered architecture with clear separation of concerns:
   - Frontend: Domain, Infrastructure, Presentation, Services layers
   - Backend: Presentation, Application, Domain, Infrastructure, Configuration layers

2. **Event-based Synchronization**: Rather than polling, the system uses event-based synchronization for timer actions (start, pause, reset) to achieve near real-time updates while minimizing network overhead.

3. **Timestamp-based Conflict Resolution**: All state conflicts are resolved using timestamp-based approaches where newer timestamps always win, ensuring deterministic and consistent behavior.

4. **Device Tracking**: Each device maintains a unique identifier to track which device made the last update, preventing synchronization loops.

### Technical Implementation Choices

1. **JWT Authentication**: JWT-based authentication is used for secure API access, with proper token storage and management on client devices.

2. **Optimistic Locking**: The backend uses optimistic locking to prevent race conditions during timer state updates, with retry logic for transient failures.

3. **State Validation**: Comprehensive state validation is implemented on both frontend and backend to prevent data corruption from invalid states.

4. **Error Handling and Retry Logic**: The system implements robust error handling with exponential backoff and retry logic for network failures.

5. **Real-time Notifications**: WebSocket or push notification support is implemented for instant state updates to connected devices.

### Security Considerations

1. **Token Storage**: Secure token storage is implemented on client devices with appropriate security measures.

2. **Data Integrity**: All data transmitted between devices and backend is validated for integrity and consistency.

3. **Authentication Flow**: Google Sign-In is integrated for secure user authentication, with proper JWT token management.

### Performance Considerations

1. **Efficient Polling**: State polling is limited to 30+ second intervals to balance responsiveness with performance.

2. **Minimal Data Transfer**: Only essential timer data is transferred during synchronization to minimize bandwidth usage.

3. **State Validation**: State validation is performed efficiently without copying data unnecessarily.

### Scalability and Maintainability

1. **Modular Design**: Components are designed to be modular and reusable, supporting future expansion.

2. **Comprehensive Logging**: Centralized logging with structured categories for debugging and monitoring.

3. **Extensible Architecture**: The system is designed to be extensible with new features and platforms.

4. **Test Coverage**: Comprehensive unit and integration testing is maintained to ensure stability and reliability.

### Platform-Specific Considerations

1. **iOS Implementation**: UIKit integration via `@UIApplicationDelegateAdaptor` with tab-based navigation structure and notification permission handling.

2. **macOS Implementation**: Native SwiftUI implementation with menu-based configuration controls and material design elements.

3. **Cross-platform Consistency**: Shared logic and data models ensure consistent user experience across platforms.

## Project Status

The TimeBeam project has been successfully initialized with all core components implemented:

### Frontend (iOS/macOS)
- SwiftUI-based user interface with tab navigation
- Timer synchronization managers with improved error handling
- Authentication services for Google Sign-In integration
- Session recording and analytics components
- Comprehensive testing infrastructure

### Backend (Spring Boot)
- RESTful API with JWT authentication
- PostgreSQL database integration
- Timer state management with optimistic locking
- Synchronization services with conflict resolution
- Comprehensive test suite

### Core Features Implemented
- Real-time cross-device timer synchronization
- Event-based synchronization for timer actions
- Timestamp-based conflict resolution
- Secure authentication with JWT
- Session recording and analytics
- Multi-device support with unique device tracking

All requirements have been validated and implemented according to the project specifications. The system is ready for further development, testing, and deployment.