# TimeBeam Structure

## Directory Layout

```
time-beam/
├── apple/                           # iOS/macOS app
│   └── TimeBeam/
│       ├── TimeBeam/
│       │   ├── Application/         # App-wide services
│       │   │   └── Services/
│       │   │       ├── AuthManager.swift
│       │   │       ├── SessionLogger.swift
│       │   │       ├── TimerSyncManager.swift
│       │   │       ├── TaskService.swift
│       │   │       └── AnalyticsManager.swift
│       │   │
│       │   ├── Domain/              # Core models
│       │   │   └── Models/
│       │   │       ├── SessionRecord.swift
│       │   │       ├── PomodoroTimer.swift
│       │   │       ├── UserTask.swift
│       │   │       └── TimerStateChangeEvent.swift
│       │   │
│       │   ├── Infrastructure/      # External integration
│       │   │   ├── External/
│       │   │   │   ├── AuthManager.swift
│       │   │   │   ├── NotificationManager.swift
│       │   │   │   └── AppLogger.swift
│       │   │   ├── Config/
│       │   │   │   └── KeychainHelper.swift
│       │   │   ├── Networking/
│       │   │   │   ├── ApiClient.swift
│       │   │   │   ├── AnalyticsApiClient.swift
│       │   │   │   └── DTOs/          # Request/Response types
│       │   │   └── Utilities/
│       │   │       ├── ServerTimeManager.swift
│       │   │       └── ServerTimeOffsetManager.swift
│       │   │
│       │   ├── Presentation/        # UI layer
│       │   │   ├── Views/
│       │   │   │   ├── iOS/          # iOS-specific views
│       │   │   │   │   ├── iOSContentView.swift
│       │   │   │   │   ├── AnalyticsView.swift
│       │   │   │   │   ├── StatsView.swift
│       │   │   │   │   ├── SettingsView.swift
│       │   │   │   │   └── Components/
│       │   │   │   └── macOS/        # macOS-specific views
│       │   │   │       └── macOSContentView.swift
│       │   │   └── Navigation/
│       │   │       └── BottomTabView.swift
│       │   │
│       │   ├── Helper/
│       │   │   └── KeychainStore.swift
│       │   │
│       │   ├── Extension/
│       │   │   └── AppExtensions.swift
│       │   │
│       │   └── TimeBeamApp.swift    # Main app entry point
│       │
│       ├── TimeBeamTests/
│       │   ├── UnitTests/
│       │   │   ├── PomodoroTimerUnitTests.swift
│       │   │   └── Services/
│       │   │       └── TimerSyncManagerUnitTests.swift
│       │   ├── IntegrationTests/
│       │   │   ├── TimerSyncIntegrationTests.swift
│       │   │   └── TaskAPIIntegrationTests.swift
│       │   └── TestData/
│       │       └── TestDataFixtures.swift
│       │
│       └── TimeBeamUITests/
│           ├── E2ETimerSyncTests.swift
│           ├── E2ETaskManagementTests.swift
│           ├── E2EAuthenticationTests.swift
│           ├── iOS/
│           │   ├── iOSSettingsUITests.swift
│           │   ├── iOSAnalyticsUITests.swift
│           │   └── iOSTimerUITests.swift
│           └── macOS/
│               └── macOSTimerUITests.swift
│
├── back-end/                        # Spring Boot backend
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/sparkage/timebeam/
│   │   │   │   ├── TimeBeamBackendApplication.java  # Main entry
│   │   │   │   │
│   │   │   │   ├── presentation/        # Controllers
│   │   │   │   │   ├── controller/
│   │   │   │   │   │   ├── AuthController.java
│   │   │   │   │   │   ├── SessionController.java
│   │   │   │   │   │   ├── TimerSyncController.java
│   │   │   │   │   │   ├── TaskController.java
│   │   │   │   │   │   ├── AnalyticsController.java
│   │   │   │   │   │   └── NotificationController.java
│   │   │   │   │   └── dto/            # Request/Response DTOs
│   │   │   │   │
│   │   │   │   ├── application/        # Service layer
│   │   │   │   │   ├── service/
│   │   │   │   │   │   ├── AuthService.java
│   │   │   │   │   │   ├── SessionService.java
│   │   │   │   │   │   ├── TimerSyncService.java
│   │   │   │   │   │   ├── TaskService.java
│   │   │   │   │   │   ├── AnalyticsService.java
│   │   │   │   │   │   └── DeviceManagementService.java
│   │   │   │   │   └── dto/            # Application DTOs
│   │   │   │   │
│   │   │   │   ├── domain/            # Domain models
│   │   │   │   │   ├── model/
│   │   │   │   │   │   ├── User.java
│   │   │   │   │   │   ├── SessionRecord.java
│   │   │   │   │   │   ├── Task.java
│   │   │   │   │   │   ├── TimerState.java
│   │   │   │   │   │   └── TimerActionType.java
│   │   │   │   │   └── repository/
│   │   │   │   │       └── SessionRecordRepository.java
│   │   │   │   │
│   │   │   │   └── infrastructure/    # External integration
│   │   │   │       ├── config/
│   │   │   │       │   ├── SecurityConfig.java
│   │   │   │       │   ├── WebSecurityConfig.java
│   │   │   │       │   └── AppLogger.java
│   │   │   │       ├── external/
│   │   │   │       │   ├── JwtUtils.java
│   │   │   │       │   ├── PushNotificationService.java
│   │   │   │       │   └── GlobalExceptionHandler.java
│   │   │   │       └── persistence/
│   │   │   │           ├── JpaUserRepository.java
│   │   │   │           ├── SessionRecordRepository.java
│   │   │   │           ├── TimerStateRepository.java
│   │   │   │           └── UserDeviceRepository.java
│   │   │   │
│   │   │   └── resources/
│   │   │       └── application.yml
│   │   │
│   │   └── test/
│   │       └── java/com/sparkage/timebeam/
│   │           ├── application/service/
│   │           │   ├── AuthServiceTest.java
│   │           │   ├── SessionServiceTest.java
│   │           │   └── TimerSyncServiceTest.java
│   │           ├── controller/
│   │           │   └── AuthControllerTest.java
│   │           ├── integration/
│   │           │   └── TimerSyncIntegrationTest.java
│   │           └── persistence/
│   │               └── SessionRecordRepositoryIT.java
│   │
│   └── pom.xml                       # Maven config
│
├── docs/                            # Documentation
├── .planning/                       # Project planning (GSD)
├── .claude/                         # Claude AI config
└── CLAUDE.md                        # Project instructions
```

## Key Naming Conventions

### Backend (Java)
- **Classes:** PascalCase (e.g., `TimerSyncService`)
- **Interfaces:** PascalCase with `I` prefix or no prefix (e.g., `SessionRecordRepository`)
- **Methods:** camelCase (e.g., `pushTimerState`)
- **Constants:** SCREAMING_SNAKE_CASE (e.g., `MAX_WORK_DURATION`)
- **Packages:** all lowercase, reverse domain (`com.sparkage.timebeam`)

### Mobile (Swift)
- **Types:** PascalCase (e.g., `SessionRecord`, `TimerState`)
- **Properties/Methods:** camelCase (e.g., `startedAt`, `fetchTasks`)
- **Constants:** camelCase with `k` prefix (e.g., `kAPIBaseUrl`)
- **Structs:** used for value types, `class` only for reference semantics

## File Organization Rules

1. **Domain models** - Core business entities, no framework dependencies
2. **Infrastructure** - External integrations (APIs, DB, push notifications)
3. **Presentation** - UI layer (SwiftUI views, controllers)
4. **Services** - Business logic, coordinate domain objects
