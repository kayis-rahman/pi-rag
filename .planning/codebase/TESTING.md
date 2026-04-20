# TimeBeam Testing

## Test Structure

```
back-end/src/test/java/com/sparkage/timebeam/
├── application/service/      # Service layer tests
│   ├── AuthServiceTest.java
│   ├── SessionServiceTest.java
│   ├── TimerSyncServiceTest.java
│   ├── AnalyticsServiceTest.java
│   └── DeviceManagementServiceTest.java
├── controller/                # Web layer tests
│   └── AuthControllerTest.java
├── integration/               # Integration tests
│   └── TimerSyncIntegrationTest.java
└── persistence/               # Repository tests
    └── SessionRecordRepositoryIT.java

apple/TimeBeam/TimeBeamTests/
├── UnitTests/
│   ├── PomodoroTimerUnitTests.swift
│   └── Services/
│       └── TimerSyncManagerUnitTests.swift
├── IntegrationTests/
│   ├── TimerSyncIntegrationTests.swift
│   └── TaskAPIIntegrationTests.swift
└── TestData/
    └── TestDataFixtures.swift

apple/TimeBeam/TimeBeamUITests/
├── E2ETimerSyncTests.swift
├── E2ETaskManagementTests.swift
├── E2EAuthenticationTests.swift
├── iOS/
│   ├── iOSSettingsUITests.swift
│   ├── iOSAnalyticsUITests.swift
│   └── iOSTimerUITests.swift
└── macOS/
    └── macOSTimerUITests.swift
```

## Backend Testing

### Unit Tests (JUnit 5 + Mockito)

```java
@ExtendWith(MockitoExtension.class)
class TimerSyncServiceTest {

    @Mock
    private TimerStateRepository timerStateRepository;

    @Mock
    private PushNotificationService pushNotificationService;

    private TimerSyncService timerSyncService;

    @BeforeEach
    void setUp() {
        timerSyncService = new TimerSyncService(timerStateRepository, pushNotificationService);
    }

    @Test
    @DisplayName("pushTimerState saves state and notifies devices")
    void pushTimerState_savesAndNotifies() {
        var state = new TimerStateDto(...);
        
        timerSyncService.pushTimerState(state, "user123");
        
        verify(timerStateRepository).save(argThat(s -> s.getUserId().equals("user123")));
        verify(pushNotificationService).notifyDevices(...);
    }
}
```

### Integration Tests (SpringBootTest)

```java
@Testcontainers
class SessionRecordRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = 
        new PostgreSQLContainer<>("postgres:16");

    private SessionRecordRepository repository;

    @BeforeEach
    void setUp() {
        var dataSource = new PGSimpleDataSource();
        dataSource.setUrl(postgres.getJdbcUrl());
        dataSource.setUser(postgres.getUsername());
        repository = new JpaSessionRecordRepository(dataSource);
    }

    @Test
    void save_and_findById() {
        var saved = repository.save(new SessionRecord(...));
        var found = repository.findById(saved.getId());
        assertThat(found).isPresent();
    }
}
```

### Coverage Thresholds
- Line coverage: 80% minimum
- Branch coverage: 75% minimum
- JaCoCo for reporting

## Mobile Testing

### Unit Tests (Swift Testing)

```swift
@Test("Timer state change event serialization")
func timerStateChangeEventSerialization() async throws {
    let event = TimerStateChangeEvent(
        phase: .work,
        remainingSeconds: 2500,
        running: true,
        timestamp: Date()
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(event)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TimerStateChangeEvent.self, from: data)
    
    #expect(decoded.phase == event.phase)
    #expect(decoded.remainingSeconds == event.remainingSeconds)
}
```

### Integration Tests

```swift
@Test("Timer sync manager state conflict resolution")
func timerSyncManagerConflictResolution() async throws {
    let localState = TimerState(phase: .work, remaining: 2500)
    let remoteState = TimerState(
        phase: .work, 
        remaining: 2400,
        timestamp: Date().addingTimeInterval(100)  // Newer
    )
    
    let result = TimerSyncManager.resolveConflict(local: localState, remote: remoteState)
    
    #expect(result == remoteState)  // Remote wins (newer timestamp)
}
```

### UI/E2E Tests (XCTest)

```swift
func testTimerStartFlow() {
    let app = XCUIApplication()
    app.launch()
    
    app.buttons["Start Timer"].tap()
    
    XCTAssert(app.staticTexts["Running"].exists)
}
```

## Test Data

### Test Fixtures
```java
public class TestDataSetup {
    public static User createTestUser() {
        return new User(UUID.randomUUID(), "test@example.com", "Test User", false);
    }
    
    public static SessionRecord createTestSession(User user) {
        return new SessionRecord(...);
    }
}
```

## Test Coverage

### Backend Coverage Areas
- Service layer business logic
- Controller request/response handling
- Repository data access
- JWT token validation
- Conflict resolution logic

### Mobile Coverage Areas
- Timer state transitions
- Session record creation
- API client error handling
- Keychain store operations
- Cross-device conflict resolution
