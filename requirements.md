# TimeBeam Requirements Specification

## Project Overview

TimeBeam is a cross-platform productivity application featuring synchronized timer functionality across iOS and macOS devices. The system provides real-time synchronization of timer states with sophisticated conflict resolution, secure authentication, and comprehensive analytics capabilities.

## V1 Features

### Authentication
- Google Sign-In integration for user authentication
- JWT-based authentication system with secure token management
- Secure token storage and management on client devices
- User registration and login functionality

### Timer Synchronization
- **Cross-device synchronization**: Real-time timer state synchronization between iOS and macOS devices
- **Event-based synchronization**: Immediate propagation of timer actions (start, pause, reset, stop, advance)
- **State-based synchronization**: Periodic full state synchronization with conflict resolution
- **Timestamp-based conflict resolution**: Newer timestamps always win for collaborative control
- **Device identification and tracking**: Prevention of feedback loops with device ID tracking
- **Network resilience**: Timeout protection and graceful degradation during network failures

### Core Functionality
- **Pomodoro timer implementation**: Standard work/break cycles with configurable durations
- **Cross-platform support**: iOS and macOS native implementations with shared logic
- **State management**: Complete timer state tracking including phases, remaining time, and session counts
- **Action handling**: Support for all timer control actions (start, pause, reset, stop, advance)
- **Background synchronization**: Continuous synchronization even when apps are in background

### Analytics and Tracking
- **Session recording**: Comprehensive logging of work sessions and breaks
- **Productivity analytics**: Streak tracking, window analysis, and usage insights
- **Data visualization**: Dashboard presentation of productivity metrics
- **Historical data**: Storage and retrieval of historical session data

## V2 Features

### Enhanced Synchronization
- **Advanced conflict resolution**: Multiple strategies for handling synchronization conflicts
- **Offline queueing**: Support for disconnected scenarios with local queueing
- **Smart sync intervals**: Adaptive polling based on device activity and network conditions
- **State validation improvements**: Enhanced data integrity checks for remote state applications
- **Push notification enhancements**: More sophisticated real-time update mechanisms

### Advanced Analytics
- **Task-based analytics**: Productivity tracking by task completion
- **Time allocation insights**: Detailed breakdown of time spent on various activities
- **Performance trends**: Historical analysis of productivity patterns over time
- **Customizable dashboards**: Flexible visualization options for different user preferences

### Enhanced Security
- **End-to-end encryption**: Secure transmission of sensitive timer data
- **Multi-factor authentication**: Enhanced security options for user accounts
- **Audit logging**: Comprehensive logging of all timer synchronization events for security monitoring

### Device Management
- **Multi-device support**: Seamless handling of multiple devices per user
- **Device pairing**: Secure device registration and management
- **Activity monitoring**: Real-time visibility of device activity and synchronization status

### User Experience Improvements
- **Intelligent recommendations**: Context-aware suggestions for timer usage
- **Customizable interfaces**: Personalized UI elements for different user preferences
- **Accessibility features**: Enhanced support for users with disabilities
- **Offline functionality**: Core timer functionality available when disconnected

## System Architecture

### Frontend (iOS/macOS)
- **Domain Layer**: Core data models (SessionRecord, TimerState)
- **Infrastructure Layer**: Networking, logging, synchronization managers
- **Presentation Layer**: SwiftUI views organized by platform
- **Services Layer**: Business logic services (Auth, Timer, Task)

### Backend (Spring Boot Java)
- **Presentation Layer**: REST controllers exposing API endpoints
- **Application Layer**: Business logic services
- **Domain Layer**: Core business entities and value objects
- **Infrastructure Layer**: Repositories, external integrations, persistence
- **Configuration Layer**: Security, logging, and application setup

## API Endpoints

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

## Data Model

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

## Quality Assurance

### Testing Strategy
- **Unit Tests**: TimerSyncManager state transitions, ApiClient error handling scenarios, State validation logic, Retry mechanism behavior
- **Integration Tests**: End-to-end synchronization flows, Network failure simulation, Conflict resolution scenarios, Authentication failure handling
- **Performance Testing**: Network efficiency verification, Memory management validation, Synchronization speed benchmarks

### Performance Requirements
- Network efficiency through event-based synchronization
- State polling limited to 30+ second intervals
- Minimal memory footprint for synchronization operations
- Efficient state validation without copying

### Security Requirements
- JWT token-based authentication
- Secure token storage and management
- State validation prevents malformed data
- Timestamp-based conflict resolution prevents manipulation
- Device identification prevents feedback loops

## Future Enhancements

1. Offline queueing for disconnected scenarios
2. Advanced conflict resolution strategies
3. Enhanced push notification system
4. Performance monitoring and analytics
5. Support for additional device types
6. Machine learning-based productivity insights
7. Integration with third-party productivity tools