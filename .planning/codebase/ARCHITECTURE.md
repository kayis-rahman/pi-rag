# TimeBeam Architecture

## High-Level Pattern

**Layered Architecture** with clear separation of concerns:
- **Frontend (Swift):** Presentation → Services → Domain → Infrastructure
- **Backend (Java):** Controller → Service → Domain → Repository → Database

## Backend Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌──────────────┬──────────────┬────────────────────────┐   │
│  │ AuthController│SessionController│ TimerSyncController│   │
│  │ AnalyticsController │ TaskController │ NotificationController │   │
│  └──────────────┴──────────────┴────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│  ┌──────────────┬──────────────┬────────────────────────┐   │
│  │   AuthService│SessionService │ TimerSyncService     │   │
│  │ AnalyticsService │ TaskService │ DeviceManagementService │   │
│  └──────────────┴──────────────┴────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                              │
│  User │ SessionRecord │ Task │ TimerState │ TimerActionType │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                 Infrastructure Layer                         │
│  ┌──────────────┬──────────────┬────────────────────────┐   │
│  │ Repositories │ JPA Entities │ JWT Utils              │   │
│  │ SecurityConfig │ PushNotificationService │          │   │
│  └──────────────┴──────────────┴────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Mobile App Architecture (Swift)

```
┌─────────────────────────────────────────────────────────────┐
│                 Presentation Layer (SwiftUI)                 │
│  ┌──────────────┬──────────────┬────────────────────────┐   │
│  │ iOSContentView│ macOSContentView │ BottomTabView      │   │
│  │ SettingsView │ AnalyticsView │ StatsView              │   │
│  └──────────────┴──────────────┴────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                 Services Layer                               │
│  ┌──────────────┬──────────────┬────────────────────────┐   │
│  │ AuthManager  │ TimerService │ TaskService            │   │
│  │ SessionLogger│ AnalyticsManager│ TimerSyncManager    │   │
│  └──────────────┴──────────────┴────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                 Domain Layer                                 │
│  PomodoroTimer │ SessionRecord │ TimerStateChangeEvent    │
│  UserTask │ TimerAction │ TimerState                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Infrastructure Layer                            │
│  ┌──────────────┬──────────────┬────────────────────────┐   │
│  │ ApiClient    │ KeychainStore│ FileLogger             │   │
│  │ NotificationManager │ iCloudSyncManager              │   │
│  └──────────────┴──────────────┴────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Timer Synchronization Flow

1. **User Action** (Start/Pause/Stop timer)
   ↓
2. **Local Timer State Update** (PomodoroTimer)
   ↓
3. **Event-Based Sync** (TimerSyncManager)
   ↓
4. **API Call** (ApiClient.pushTimerAction)
   ↓
5. **Backend** (TimerEventService)
   ↓
6. **Broadcast** to all user devices via WebSocket

### State Polling Flow

1. **Background Timer Sync** (every 30+ seconds)
   ↓
2. **Pull State** (ApiClient.pullTimerState)
   ↓
3. **Conflict Resolution** (newer timestamp wins)
   ↓
4. **Local Update** (if remote state is newer)

## Entry Points

### Backend
- `back-end/src/main/java/com/sparkage/timebeam/TimeBeamBackendApplication.java`

### iOS/macOS
- `apple/TimeBeam/TimeBeam/TimeBeamApp.swift` (main app)
- `MacAppDelegate.swift` (macOS delegate)
- `iOSAppDelegate.swift` (iOS delegate)

## Key Abstractions

| Layer | Abstraction | Purpose |
|-------|-------------|---------|
| Backend Service | `TimerSyncService` | Cross-device timer sync |
| Backend Service | `AnalyticsService` | Productivity analytics |
| Backend Service | `AuthService` | User authentication |
| Mobile Service | `AuthManager` | Google Sign-In, token mgmt |
| Mobile Service | `TimerSyncManager` | Timer state sync |
| Mobile API | `ApiClient` | HTTP client, error handling |
| Domain Model | `SessionRecord` | Work session data |
| Domain Model | `TimerState` | Current timer state |

## State Management

### Mobile (Swift)
- **@StateObject** for timer, logger, authManager, taskService, analyticsManager
- **@EnvironmentObject** for sharing across views
- **KeychainStore** for secure token persistence

### Backend (Java)
- **JPA Repositories** for entity persistence
- **Service classes** for business logic
- **WebSocket** for real-time state broadcasts
