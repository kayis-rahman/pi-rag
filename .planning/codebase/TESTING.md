# TimeBeam Testing Patterns

**Analysis Date:** 2026-04-20

## Test Framework

### Backend (Java/Spring Boot)

| Component | Tool |
|-----------|------|
| **Test Runner** | JUnit 5 (`@Test`, `@ParameterizedTest`, `@Nested`, `@DisplayName`) |
| **Assertion Library** | AssertJ (fluent assertions with `assertThat()`) |
| **Mocking** | Mockito 5.3.1 (`@Mock`, `@InjectMocks`, `when()`, `verify()`) |
| **Integration Testing** | SpringBootTest, Testcontainers |
| **Coverage** | JaCoCo (target: 80% line, 75% branch) |

**Run Commands:**
```bash
cd back-end
mvn test                          # Run all tests
mvn test -Dtest=AuthServiceTest   # Run specific test class
mvn clean test                    # Clean and test
mvn verify                        # Run tests with coverage report
```

**Coverage View:**
```bash
mvn jacoco:report                 # View coverage report
# Report located at: target/site/jacoco/index.html
```

### Mobile (Swift)

| Component | Tool |
|-----------|------|
| **Unit Tests** | XCTest (`XCTestCase`, `XCTAssert*`, `measure`) |
| **UI/E2E Tests** | XCTest (`XCUIApplication`, `XCUIElement`) |
| **Test Organization** | Separated into UnitTests/ and UITests/ directories |

**Run Commands:**
```bash
# iOS Simulator
xcodebuild test -project TimeBeam.xcodeproj \
    -scheme TimeBeam \
    -destination 'platform=iOS Simulator,name=iPhone 15'

# All platforms
xcodebuild test -project TimeBeam.xcodeproj \
    -scheme TimeBeam \
    -destination 'platform=macOS,arch=arm64'
```

---

## Test File Organization

### Backend Structure

```
back-end/src/test/java/com/sparkage/timebeam/
├── application/service/      # Service layer unit tests
│   ├── AuthServiceTest.java
│   ├── SessionServiceTest.java
│   ├── TimerSyncServiceTest.java
│   ├── TimerSyncServiceComprehensiveTest.java
│   ├── TaskServiceTest.java
│   ├── AnalyticsServiceTest.java
│   ├── DeviceManagementServiceTest.java
│   └── TimerEventServiceTest.java
├── controller/                # Web layer tests (MockMvc)
│   └── AuthControllerTest.java
├── persistence/               # Repository tests (JPA)
│   ├── SessionRecordRepositoryIT.java
│   ├── TimerStateRepositoryIT.java
│   └── UserDeviceRepositoryIT.java
├── presentation/              # DTO and mapping tests
│   └── dto/TimerStateDtoTest.java
├── E2ETestDataSeeder.java     # E2E test data setup
├── TestDataSetup.java         # Common test data fixtures
└── TestSecurityConfig.java    # Test-specific security config
```

### Mobile Structure

```
apple/TimeBeam/TimeBeamTests/
├── UnitTests/
│   ├── PomodoroTimerUnitTests.swift          # Timer logic
│   ├── MacAppDelegateUnitTests.swift
│   ├── Models/
│   │   └── TaskModelUnitTests.swift
│   └── Services/
│       ├── TaskServiceUnitTests.swift
│       └── TimerSyncManagerUnitTests.swift
├── IntegrationTests/
│   ├── TimerSyncIntegrationTests.swift
│   └── TaskAPIIntegrationTests.swift
├── TestData/
│   ├── TestDataFixtures.swift                # Comprehensive test data factory
│   └── TestCoverage/
│       └── TestCoverageAnalyzer.swift
└── TestExecution/
    └── TestExecutionOrchestrator.swift

apple/TimeBeam/TimeBeamUITests/
├── E2ETimerSyncTests.swift
├── E2ETaskManagementTests.swift
├── E2EAuthenticationTests.swift
├── CrossPlatformTimerSyncE2ETest.swift
├── iOS/
│   ├── iOSTimerUITests.swift
│   ├── iOSTaskUITests.swift
│   ├── iOSSettingsUITests.swift
│   └── iOSAnalyticsUITests.swift
├── macOS/
│   └── macOSTimerUITests.swift
└── watchOS/
    └── watchOSTimerUITests.swift
```

---

## Backend Testing Patterns

### Unit Test Pattern (JUnit 5 + Mockito)

```java
@ExtendWith(MockitoExtension.class)
class TimerSyncServiceTest {

    @Mock
    private TimerStateRepository timerStateRepository;

    @Mock
    private UserDeviceRepository userDeviceRepository;

    @Mock
    private PushNotificationService pushNotificationService;

    @InjectMocks
    private TimerSyncService timerSyncService;

    @BeforeEach
    void setUp() {
        // Setup common test data
    }

    @Test
    @DisplayName("pushTimerState saves state when none exists")
    void pushTimerState_ShouldCreateNewTimerState_WhenNoneExists() {
        // Given
        UUID userId = UUID.randomUUID();
        TimerStateDto state = createTestState();
        when(timerStateRepository.findByUserId(userId)).thenReturn(Optional.empty());
        when(timerStateRepository.save(any(TimerState.class))).thenAnswer(i -> i.getArgument(0));

        // When
        timerSyncService.pushTimerState(userId, state, "device123");

        // Then
        verify(timerStateRepository).findByUserId(userId);
        verify(timerStateRepository).save(any(TimerState.class));
    }

    @Test
    @DisplayName("pushTimerState updates existing state if newer")
    void pushTimerState_ShouldUpdateExistingTimerState_WhenNewerTimestamp() {
        // Given
        TimerState existing = createExistingState(Instant.now().minusSeconds(60));
        when(timerStateRepository.findByUserId(any())).thenReturn(Optional.of(existing));
        when(timerStateRepository.save(existing)).thenReturn(existing);

        // When
        timerSyncService.pushTimerState(userId, newTestState, "device123");

        // Then
        verify(timerStateRepository).save(existing);
        assertThat(existing.getPhase()).isEqualTo("work");
    }

    @Test
    void cleanupOldStates_ShouldDeleteOldStates() {
        // Given
        when(timerStateRepository.findStaleTimerStates(any())).thenReturn(List.of(timerState));
        doNothing().when(timerStateRepository).delete(timerState);

        // When
        timerSyncService.cleanupOldStates();

        // Then
        verify(timerStateRepository).findStaleTimerStates(any());
        verify(timerStateRepository).delete(timerState);
    }
}
```

### Integration Test Pattern (SpringBootTest + Testcontainers)

```java
@DataJpaTest
class SessionRecordRepositoryIT {
    @Autowired
    private SessionRecordRepository repo;

    @Test
    void saveAndFindByUser() {
        UUID userId = UUID.randomUUID();
        SessionRecord record = new SessionRecord(
            UUID.randomUUID(), userId, Instant.now(), 1500, SessionRecord.Kind.WORK
        );
        repo.save(record);

        List<SessionRecord> list = repo.findByUserIdOrderByStartedAtDesc(userId);
        assertThat(list).isNotEmpty();
        assertThat(list.get(0).getUserId()).isEqualTo(userId);
    }
}

// For tests requiring full Spring context and database
@Testcontainers
class TimerSyncIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    private TimerSyncService timerSyncService;

    @BeforeEach
    void setUp() {
        var dataSource = new PGSimpleDataSource();
        dataSource.setUrl(postgres.getJdbcUrl());
        dataSource.setUser(postgres.getUsername());
        // Configure repository with dataSource
    }
}
```

### MockMvc Pattern (Controller Tests)

```java
@WebMvcTest(controllers = AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
class AuthControllerTest {
    @Autowired
    private MockMvc mvc;

    @MockBean
    private UserService userService;

    @MockBean
    private AuthService authService;

    private ObjectMapper om = new ObjectMapper();

    @Test
    void register_returnsUserDto() throws Exception {
        AuthRequests.Register request = new AuthRequests.Register("test@example.com", "Test");
        UserDto response = new UserDto(UUID.randomUUID(), "test@example.com", "Test");
        when(userService.createUser(anyString(), anyString())).thenReturn(response);

        mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(request)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.email").value("test@example.com"));
    }

    @Test
    void login_invalidCredentials_returns401() throws Exception {
        AuthRequests.Login request = new AuthRequests.Login("noone@example.com");
        when(authService.login(anyString())).thenReturn(Optional.empty());

        mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(request)))
            .andExpect(status().isUnauthorized());
    }
}
```

### Test Data Fixtures

```java
public class TestDataSetup {
    public static User createTestUser() {
        return new User(UUID.randomUUID(), "test@example.com", "Test User", false);
    }

    public static User createTestUser(UUID userId) {
        return new User(userId, "test@example.com", "Test User", false);
    }

    public static SessionRecord createTestSession(User user) {
        return new SessionRecord(
            UUID.randomUUID(), user.getId(), Instant.now(), 1500, SessionRecord.Kind.WORK
        );
    }

    public static TimerState createTestTimerState(UUID userId, UUID deviceId) {
        TimerState state = new TimerState();
        state.setUserId(userId);
        state.setPhase("work");
        state.setRemainingSeconds(1500);
        state.setRunning(false);
        state.setWorkDurationMinutes(25);
        state.setBreakDurationMinutes(5);
        state.setLongBreakDurationMinutes(15);
        state.setAutoStartNext(false);
        state.setShortBreaksCompleted(0);
        state.setLastUpdatedAt(Instant.now());
        state.setUpdatedByDeviceId(deviceId);
        state.setVersion(1L);
        return state;
    }
}
```

---

## Mobile Testing Patterns

### Unit Test Pattern (XCTest)

```swift
import XCTest
@testable import TimeBeam

final class PomodoroTimerUnitTests: XCTestCase {

    private var timer: PomodoroTimer!

    override func setUp() {
        super.setUp()
        timer = PomodoroTimer()
    }

    override func tearDown() {
        timer = nil
        super.tearDown()
    }

    func testStartSetsTimestamps() {
        // Given
        let before = Date().timeIntervalSince1970

        // When
        timer.start()

        // Then
        XCTAssertNotNil(timer.startTimestamp)
        XCTAssertNil(timer.pauseTimestamp)
        XCTAssertGreaterThan(timer.startTimestamp!, before)
        XCTAssertGreaterThan(timer.lastModifiedTimestamp, before)
    }

    func testPauseSetsTimestamps() {
        timer.start()
        let beforePause = Date().timeIntervalSince1970
        timer.pause()

        XCTAssertNotNil(timer.pauseTimestamp)
        XCTAssertGreaterThan(timer.pauseTimestamp!, beforePause)
        XCTAssertGreaterThan(timer.lastModifiedTimestamp, beforePause)
    }

    func testProgressCalculation() {
        timer.remainingSeconds = 750 // Half of 1500
        let progress = timer.progress
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }
}
```

### Service Unit Tests with Mocking

```swift
final class TaskServiceUnitTests: XCTestCase {

    private var taskService: TaskService!
    private var mockApiClient: MockApiClient!
    private var mockKeychainStore: MockKeychainStore!

    override func setUpWithError() throws {
        mockApiClient = MockApiClient()
        mockKeychainStore = MockKeychainStore()
        taskService = TaskService(apiClient: mockApiClient, keychainStore: mockKeychainStore)
    }

    override func tearDownWithError() throws {
        taskService = nil
        mockApiClient = nil
        mockKeychainStore = nil
    }

    func testCreateTaskSuccess() async throws {
        let taskData = TestDataFactory.createValidTask()
        let expectedTask = MockDataProvider.createMockTask(
            title: taskData.title, description: taskData.description
        )
        mockApiClient.mockResponse = .success(expectedTask)

        let result = try await taskService.createTask(
            title: taskData.title, description: taskData.description
        )

        XCTAssertEqual(result.id, expectedTask.id)
        XCTAssertEqual(result.title, expectedTask.title)
        XCTAssertEqual(result.status, .todo)
    }

    func testCreateTaskWithEmptyTitleFails() async throws {
        do {
            _ = try await taskService.createTask(title: "", description: "Valid description")
            XCTFail("Should throw validation error for empty title")
        } catch TaskServiceError.validationError(let message) {
            XCTAssertTrue(message.contains("title"))
        } catch {
            XCTFail("Should throw TaskServiceError.validationError")
        }
    }
}

// Mock classes
private class MockApiClient: ApiClientProtocol {
    var mockResponse: Result<Any, Error>?
    var mockResponses: [Result<Any, Error>] = []
    var callCount = 0

    func performRequest<T>(_ request: APIRequest) async throws -> T {
        callCount += 1
        let response = mockResponses.isEmpty ? mockResponse : mockResponses.removeFirst()
        // Handle response...
    }
}

private class MockKeychainStore: KeychainStoreProtocol {
    var shouldReturnNilToken = false
    var mockToken = "mock-jwt-token"

    func loadString(_ key: String) -> String? {
        return shouldReturnNilToken ? nil : mockToken
    }

    func saveString(_ value: String, forKey key: String) -> Bool {
        return true
    }

    func deleteString(_ key: String) -> Bool {
        return true
    }
}
```

### UI/E2E Test Pattern (XCUIApplication)

```swift
final class E2ETimerWorkflowTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-testing"]
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testTimerStartAndPause() {
        let startButton = app.buttons["Start Timer"]
        startButton.waitForExistence(timeout: 5)
        startButton.tap()

        // Verify timer is running
        XCTAssertTrue(app.staticTexts["Running"].waitForExistence(timeout: 2))

        let pauseButton = app.buttons["Pause Timer"]
        pauseButton.tap()

        // Verify timer is paused
        XCTAssertFalse(app.staticTexts["Running"].exists)
    }

    func testTimerDurationConfiguration() {
        app.buttons["Settings"].tap()
        let workDurationSlider = app.sliders["Work Duration"]
        workDurationSlider.adjust(toValue: 30)

        // Save and verify
        app.buttons["Save"].tap()
        XCTAssertEqual(workDurationSlider.value as? String, "30")
    }
}

// Test utility extensions
extension XCUIElement {
    @discardableResult
    func waitForExistence(timeout: TimeInterval = 5, description: String = "") -> Bool {
        let exists = waitForExistence(timeout: timeout)
        if !exists {
            XCTFail("Element not found: \(description)")
        }
        return exists
    }
}
```

---

## Mocking Patterns

### Backend (Mockito)

```java
// Basic mocking
@Mock
private TaskRepository taskRepository;

// Mock behavior
when(taskRepository.findById(any())).thenReturn(Optional.of(testTask));
when(taskRepository.save(any(Task.class))).thenAnswer(i -> i.getArgument(0));

// Argument matchers
when(taskRepository.findByUserIdOrderByCreatedAtDesc(eq(userId)))
    .thenReturn(List.of(task1, task2));

// Verification
verify(taskRepository, times(1)).save(any(Task.class));
verify(taskRepository, never()).deleteById(any());
```

### Mobile (Manual Mocks)

```swift
protocol ApiClientProtocol {
    func performRequest<T: Decodable>(_ request: APIRequest) async throws -> T
}

// Production implementation
extension ApiClient: ApiClientProtocol {
    func performRequest<T>(_ request: APIRequest) async throws -> T {
        // Actual network call
    }
}

// Mock for tests
class MockApiClient: ApiClientProtocol {
    var mockResponse: Result<Any, Error>?
    var callCount = 0

    func performRequest<T>(_ request: APIRequest) async throws -> T {
        callCount += 1
        switch mockResponse {
        case .success(let data):
            return data as! T
        case .failure(let error):
            throw error
        case .none:
            return () as! T
        }
    }
}
```

---

## Test Data Patterns

### Swift Test Data Factory

```swift
struct TestDataFactory {

    // MARK: - User Data
    static func createTestUser(
        id: UUID = UUID(),
        email: String = "test@example.com",
        displayName: String = "Test User"
    ) -> [String: Any] {
        return [
            "id": id.uuidString,
            "email": email,
            "displayName": displayName,
            "timezone": "UTC",
            "isAdmin": false
        ]
    }

    // MARK: - Task Data
    static func createTestTask(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        title: String = "Test Task",
        description: String? = nil,
        status: TaskStatus = .todo
    ) -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId.uuidString,
            "title": title,
            "description": description as Any,
            "status": status.rawValue,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // MARK: - Session Data
    static func createTestSession(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        taskId: UUID? = nil,
        startedAt: Date = Date(),
        durationSeconds: Int = 1500,
        kind: String = "work"
    ) -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId.uuidString,
            "taskId": taskId?.uuidString as Any,
            "startedAt": ISO8601DateFormatter().string(from: startedAt),
            "durationSeconds": durationSeconds,
            "kind": kind,
            "wasCompleted": true
        ]
    }

    // MARK: - Bulk Data Generators
    static func createMultipleTasks(count: Int, userId: UUID = UUID()) -> [[String: Any]] {
        return (0..<count).map { index in
            let status: TaskStatus = index % 3 == 0 ? .completed : (index % 3 == 1 ? .inProgress : .todo)
            createTestTask(title: "Task \(index + 1)", status: status)
        }
    }

    // MARK: - Edge Cases
    static func createInvalidTaskData() -> [[String: Any]] {
        return [
            ["id": UUID().uuidString, "title": "", "status": "todo"],
            ["id": UUID().uuidString, "title": String(repeating: "A", count: 256), "status": "todo"],
            ["id": UUID().uuidString, "title": "Valid Title", "status": "invalid_status"]
        ]
    }
}
```

### Backend Test Data Fixture

```java
public class TestDataSetup {
    public static User createTestUser() {
        return new User(UUID.randomUUID(), "test@example.com", "Test User", false);
    }

    public static User createTestUser(UUID userId) {
        return new User(userId, "test@example.com", "Test User", false);
    }

    public static Task createTestTask(UUID userId) {
        Task task = new Task();
        task.setId(UUID.randomUUID());
        task.setUserId(userId);
        task.setTitle("Test Task");
        task.setDescription("Test Description");
        task.setStatus(Task.Status.TODO);
        task.setCreatedAt(Instant.now());
        task.setUpdatedAt(Instant.now());
        return task;
    }

    public static SessionRecord createTestSession(User user) {
        return new SessionRecord(
            UUID.randomUUID(), user.getId(), Instant.now(), 1500, SessionRecord.Kind.WORK
        );
    }

    public static TimerState createTestTimerState(UUID userId, UUID deviceId) {
        TimerState state = new TimerState();
        state.setUserId(userId);
        state.setPhase("work");
        state.setRemainingSeconds(1500);
        state.setRunning(false);
        state.setWorkDurationMinutes(25);
        state.setBreakDurationMinutes(5);
        state.setLongBreakDurationMinutes(15);
        state.setAutoStartNext(false);
        state.setShortBreaksCompleted(0);
        state.setLastUpdatedAt(Instant.now());
        state.setUpdatedByDeviceId(deviceId);
        state.setVersion(1L);
        return state;
    }
}
```

---

## Test Coverage

### Backend Coverage Requirements

**Coverage Thresholds:**
- Line coverage: **80% minimum** (enforced by JaCoCo)
- Branch coverage: **75% minimum** (enforced by JaCoCo)

**Exclusions (per pom.xml):**
```xml
<excludes>
    <exclude>**/model/*</exclude>
    <exclude>**/dto/*</exclude>
    <exclude>**/config/*</exclude>
    <exclude>**/Application.class</exclude>
</excludes>
```

**Coverage Areas:**
- Service layer business logic
- Controller request/response handling
- Repository data access
- JWT token validation
- Conflict resolution logic

### Mobile Coverage Areas

**Test Types:**
1. **Unit Tests** - Logic without UI (PomodoroTimer, TaskService)
2. **Integration Tests** - API client integration (TimerSyncIntegrationTests)
3. **UI/E2E Tests** - Full workflow testing (E2ETimerWorkflowTests)

**Coverage Areas:**
- Timer state transitions
- Session record creation
- API client error handling
- Keychain store operations
- Cross-device conflict resolution
- Authentication flows
- Task management workflows

---

## Common Test Patterns

### Backend - Exception Testing

```java
@Test
void getById_shouldThrowExceptionWhenNotFound() {
    UUID nonExistentId = UUID.randomUUID();
    when(taskRepository.findById(nonExistentId)).thenReturn(Optional.empty());

    assertThrows(ResourceNotFoundException.class, () -> {
        taskService.getById(nonExistentId, userId);
    });

    verify(taskRepository, times(1)).findById(nonExistentId);
    verifyNoMoreInteractions(taskMapper);
}
```

### Backend - Parameterized Tests

```java
@ParameterizedTest
@CsvSource({
    "100.00, 10, 90.00",
    "50.00, 0, 50.00",
    "200.00, 25, 150.00"
})
@DisplayName("discount applied correctly")
void applyDiscount(BigDecimal price, int pct, BigDecimal expected) {
    assertThat(PricingUtils.discount(price, pct)).isEqualByComparingTo(expected);
}
```

### Mobile - Async Testing

```swift
func testFetchTasksSuccess() async throws {
    let mockTasks = MockDataProvider.mockTasks()
    mockApiClient.mockResponse = .success(mockTasks)

    let tasks = try await taskService.fetchTasks()

    XCTAssertEqual(tasks.count, mockTasks.count)
    for (index, task) in tasks.enumerated() {
        XCTAssertEqual(task.id, mockTasks[index]["id"] as? String)
    }
}

func testConcurrentTaskOperations() async throws {
    let mockTask = MockDataProvider.createMockTask()
    mockApiClient.mockResponse = .success(mockTask)

    async let task1 = taskService.fetchTask(byId: mockTask.id)
    async let task2 = taskService.fetchTask(byId: mockTask.id)
    async let task3 = taskService.fetchTask(byId: mockTask.id)

    let results = try await [task1, task2, task3]
    XCTAssertEqual(results.count, 3)
}
```

### Mobile - Performance Testing

```swift
func testFetchTasksPerformance() async throws {
    let largeTaskList = (0..<1000).map { _ in MockDataProvider.createMockTask() }
    mockApiClient.mockResponse = .success(largeTaskList)

    measure {
        let expectation = expectation(description: "Fetch tasks")
        Task {
            do {
                _ = try await taskService.fetchTasks()
                expectation.fulfill()
            } catch {
                XCTFail("Performance test should not fail")
            }
        }
        wait(for: [expectation], timeout: 5.0)
    }
}
```

---

## E2E Test Utilities

### Mobile Test Utilities

```swift
extension XCUIElement {
    func waitForHittable(timeout: TimeInterval = 5) -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if isHittable {
                return true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return false
    }

    func scrollToVisible(in scrollView: XCUIElement? = nil) {
        let scrollElement = scrollView ?? XCUIApplication().scrollViews.firstMatch
        scrollElement.swipeUp()
        if exists && isHittable { return }
        scrollElement.swipeDown()
    }
}

extension XCUIApplication {
    func launchForTesting() {
        launchArguments = ["-testing"]
        launchEnvironment = [
            "TESTING": "1",
            "DISABLE_ANIMATIONS": "1"
        ]
        launch()
    }
}

struct TestAssertions {
    static func assertElementExists(_ element: XCUIElement, _ message: String = "") {
        XCTAssertTrue(element.exists, message.isEmpty ? "Element should exist" : message)
    }

    static func assertTextEqual(_ element: XCUIElement, _ expectedText: String) {
        XCTAssertEqual(element.label, expectedText)
    }
}
```

---

## Test Configuration

### Backend Test Profile

```java
@Configuration
@Profile("test")
public class TestSecurityConfig {
    @Bean
    @Primary
    public SecurityFilterChain testFilterChain(HttpSecurity http) throws Exception {
        http.csrf().disable()
            .authorizeHttpRequests().anyRequest().permitAll();
        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails user = User.builder()
            .username("88475a64-7bd3-45ff-a33e-d1617c1e349e")
            .password("password")
            .roles("USER")
            .build();
        return new InMemoryUserDetailsManager(user);
    }
}
```

### Mobile Test Configuration

```swift
struct TestConfiguration {
    static let defaultTimeout: TimeInterval = 10
    static let extendedTimeout: TimeInterval = 30
    static let shortTimeout: TimeInterval = 2
}

extension XCUIApplication {
    func launchForTesting() {
        launchArguments = ["-testing"]
        launchEnvironment = [
            "TESTING": "1",
            "DISABLE_ANIMATIONS": "1"
        ]
        launch()
    }
}
```

---

## Best Practices

### Backend

1. **Always use constructor injection** - Never use `@Autowired` on fields
2. **Use `@BeforeEach` for setup** - Ensure test isolation
3. **Verify exact interactions** - Use `verify()` to confirm expected calls
4. **Test edge cases** - Empty inputs, null values, boundary conditions
5. **Use descriptive test names** - `methodName_scenario_expectedBehavior`

### Mobile

1. **Use `@MainActor` for testable async code** - Swift Concurrency patterns
2. **Mock protocols, not classes** - `ApiClientProtocol`, not `ApiClient`
3. **Reset state between tests** - Use `tearDown()` for cleanup
4. **Use measurement for performance tests** - `measure {}` block
5. **Test user-facing behavior** - Focus on UI interactions, not implementation details

---

## Test-Driven Development Process

1. **Write test first (RED)** - Define expected behavior
2. **Run test and watch it fail** - Verify test is correct
3. **Write minimal implementation (GREEN)** - Make test pass
4. **Run test and verify it passes** - Confirm correctness
5. **Refactor (IMPROVE)** - Clean up code while keeping tests green
6. **Verify coverage (80%+)** - Ensure adequate coverage

---

*Testing analysis: 2026-04-20*
