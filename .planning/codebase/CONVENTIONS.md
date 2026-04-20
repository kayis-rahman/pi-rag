# TimeBeam Coding Conventions

**Analysis Date:** 2026-04-20

## Swift Coding Conventions (iOS/macOS/watchOS)

**Reference:** See `swift-patterns` skill for detailed patterns and `swift-coding-standards` skill.

### Code Style

**Formatting:**
- SwiftFormat for auto-formatting, SwiftLint for style enforcement
- 4 spaces for indentation
- Line length: 120 characters max

**Naming (Apple API Design Guidelines):**
- Types (structs, classes, enums): `PascalCase` - e.g., `TimerSyncManager`, `PomodoroTimer`
- Properties and methods: `camelCase` - e.g., `remainingSeconds`, `startTimer()`
- Constants: `camelCase` (modern Swift, no `k` prefix) - e.g., `defaultTimeout`
- Protocol names: `PascalCase` ending with `Protocol` or `-able` suffix - e.g., `ApiClientProtocol`, `KeychainStoreProtocol`
- Enums with associated values: case names use `lowerCamelCase` - e.g., `.success(data)`, `.failure(error)`

### Swift Language Patterns

**Immutability (CRITICAL):**
```swift
// GOOD - immutable by default
struct SessionRecord: Codable {
    let id: UUID
    let startedAt: Date
    let duration: TimeInterval
}

// PREFERRED - use struct with value semantics
struct TimerState {
    let phase: Phase
    let remainingSeconds: Int
    let isRunning: Bool
}

// AVOID - mutable classes unless identity/reference semantics needed
class OldTimerClass {
    var phase: Phase
    var remainingSeconds: Int
}
```

**Protocol-Oriented Design:**
```swift
// Define small, focused protocols
protocol ApiClientProtocol {
    func performRequest<T: Decodable>(_ request: APIRequest) async throws -> T
}

protocol KeychainStoreProtocol {
    func loadString(_ key: String) -> String?
    func saveString(_ value: String, forKey key: String) -> Bool
}

// Use protocol extensions for defaults
protocol Identifiable {
    var id: UUID { get }
}
```

**Dependency Injection:**
```swift
// Constructor injection with default parameters
struct TaskService: ObservableObject {
    private let apiClient: ApiClientProtocol
    private let keychainStore: KeychainStoreProtocol

    init(
        apiClient: ApiClientProtocol? = nil,
        keychainStore: KeychainStoreProtocol = KeychainStore()
    ) {
        if let apiClient = apiClient {
            self.apiClient = apiClient
        } else {
            self.apiClient = ApiClient(baseURL: ...)
        }
        self.keychainStore = keychainStore
    }
}
```

**Error Handling (Typed Throws - Swift 6+):**
```swift
enum TaskServiceError: LocalizedError {
    case validationError(String)
    case networkError(Error)
    case notFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .validationError(let message): return message
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .notFound: return "Task not found"
        case .unauthorized: return "Authentication required"
        }
    }
}

func createTask(title: String) async throws -> UserTask {
    guard !title.isEmpty else {
        throw TaskServiceError.validationError("Title cannot be empty")
    }
    // ...
}
```

**Concurrency (Swift Concurrency):**
```swift
// Use async/await for asynchronous operations
@MainActor
final class TimerSyncManager: ObservableObject {
    func syncTimerState() async {
        await performSync()
    }

    private func performSync() async {
        do {
            let state = try await ApiClient.shared.pullTimerState(accessToken: token)
            // Update UI on MainActor
        } catch {
            handleSyncFailure(error)
        }
    }
}

// Use actors for shared mutable state
actor TimerStateCache {
    private var state: TimerState?
    
    func getState() -> TimerState? { state }
    func setState(_ newState: TimerState) { state = newState }
}
```

**Sendable Types:**
```swift
// Prefer Sendable value types for data crossing isolation boundaries
struct TimerState: Codable, Sendable {
    let phase: Phase
    let remainingSeconds: Int
}

// Use @MainActor for UI-related state
@MainActor
final class TimerSyncManager: ObservableObject {
    @Published private(set) var timer: PomodoroTimer?
}
```

---

## Java Coding Conventions (Backend)

**Reference:** See `java-coding-standards` skill for detailed patterns.

### Code Style

**Formatting:**
- google-java-format (Google style)
- 4 spaces for indentation
- One public top-level class per file

**Naming:**
- Classes, Interfaces, Records, Enums: `PascalCase` - e.g., `TimerSyncService`, `SessionRecord`
- Methods, Fields, Parameters, Local Variables: `camelCase` - e.g., `getTimer()`, `userId`
- Constants (`static final`): `SCREAMING_SNAKE_CASE` - e.g., `WORK_DURATION`
- Packages: all lowercase - e.g., `com.sparkage.timebeam.application.service`

### Java Language Patterns

**Immutability:**
```java
// GOOD - immutable domain model
public class Task {
    private final UUID id;
    private final UUID userId;
    private final String title;
    private final Status status;

    public Task(UUID id, UUID userId, String title, Status status) {
        this.id = validateId(id);
        this.userId = validateUserId(userId);
        this.title = validateTitle(title);
        this.status = validateStatus(status);
    }

    // Getters only, no setters
    public UUID getId() { return id; }
    public String getTitle() { return title; }
}

// GOOD - record for DTOs (Java 16+)
public record SessionRecordDto(
    UUID id,
    UUID userId,
    Instant startedAt,
    long durationSeconds,
    String kind,
    UUID taskId
) {}
```

**Modern Java Features:**
```java
// Records for DTOs
public record ApiResponse<T>(boolean success, T data, String error) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, null, message);
    }
}

// Pattern matching with instanceof (Java 16+)
if (result instanceof Success s) {
    handleSuccess(s.data());
}

// Switch expressions (Java 14+)
String label = switch (status) {
    case TODO -> "To Do";
    case IN_PROGRESS -> "In Progress";
    case COMPLETED -> "Completed";
};

// Sealed interfaces (Java 17+)
public sealed interface PaymentResult permits PaymentSuccess, PaymentFailure {
    record PaymentSuccess(String transactionId, BigDecimal amount) implements PaymentResult {}
    record PaymentFailure(String errorCode, String message) implements PaymentResult {}
}
```

**Optional Usage:**
```java
// Return Optional from finder methods
public Optional<TimerState> findTimerState(UUID userId) {
    return timerStateRepository.findByUserId(userId);
}

// Use map/flatMap/orElseThrow - never get() without isPresent()
public TimerStateDto getTimerState(UUID userId) {
    return timerStateRepository.findByUserId(userId)
        .map(TimerStateDto::from)
        .orElseThrow(() -> new ResourceNotFoundException(userId));
}

// BAD - Optional as field or parameter
private Optional<User> user;  // Don't do this
```

**Error Handling:**
```java
// Domain-specific exceptions extending RuntimeException
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
    public static ResourceNotFoundException userNotFound(String userId) {
        return new ResourceNotFoundException("User not found: " + userId);
    }
}

public class AccessDeniedException extends RuntimeException {
    public AccessDeniedException(String message) {
        super(message);
    }
    public static AccessDeniedException sessionAccessDenied(String sessionId, String userId) {
        return new AccessDeniedException("Access denied: Session " + sessionId + " belongs to user " + userId);
    }
}

public class UserNotAuthenticatedException extends RuntimeException {
    public UserNotAuthenticatedException(String message) {
        super(message);
    }
}

// Global exception handler
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(Exception ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(Map.of("error", "resource_not_found"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneral(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(Map.of("error", "internal_server_error"));
    }
}
```

**Constructor Injection (Mandatory):**
```java
// GOOD - constructor injection (testable, immutable)
@Service
public class TimerSyncService {
    private final TimerStateRepository timerStateRepository;
    private final PushNotificationService pushNotificationService;

    public TimerSyncService(
        TimerStateRepository timerStateRepository,
        PushNotificationService pushNotificationService
    ) {
        this.timerStateRepository = timerStateRepository;
        this.pushNotificationService = pushNotificationService;
    }
}

// BAD - field injection (untestable without reflection)
@Service
public class BadService {
    @Autowired  // Don't do this
    private TimerStateRepository repository;
}
```

### Spring Boot Patterns

**Controller Layer:**
```java
@RestController
@RequestMapping("/api/sessions")
@PreAuthorize("isAuthenticated()")
public class SessionController {
    private final SessionService sessionService;

    public SessionController(SessionService sessionService) {
        this.sessionService = sessionService;
    }

    @PostMapping
    public ResponseEntity<SessionRecordDto> create(
        @RequestBody SessionRecordDto dto,
        Principal principal
    ) {
        UUID userId = resolveUserId(principal);
        if (userId == null) return ResponseEntity.status(401).build();
        return ResponseEntity.status(201).body(sessionService.create(dto, userId));
    }

    private UUID resolveUserId(Principal principal) {
        if (principal == null || principal.getName() == null) return null;
        try {
            return UUID.fromString(principal.getName());
        } catch (Exception ex) {
            return null;
        }
    }
}
```

**Service Layer:**
```java
@Service
public class SessionService {
    private final SessionRecordRepository repository;
    private final SessionRecordMapper mapper;

    public SessionService(SessionRecordRepository repository, SessionRecordMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    public SessionRecordDto create(SessionRecordDto dto) {
        if (dto.getId() == null) dto.setId(UUID.randomUUID());
        SessionRecord entity = mapper.toEntity(dto);
        repository.save(entity);
        return mapper.toDto(entity);
    }

    public List<SessionRecordDto> listForUser(UUID userId) {
        return repository.findByUserIdOrderByStartedAtDesc(userId)
            .stream().map(mapper::toDto).collect(Collectors.toList());
    }
}
```

**Repository Layer (JPA):**
```java
@Repository
public interface SessionRecordRepository extends JpaRepository<SessionRecord, UUID> {
    List<SessionRecord> findByUserIdOrderByStartedAtDesc(UUID userId);
    List<SessionRecord> findByUserIdAndKindOrderByStartedAtDesc(UUID userId, String kind);
}

@Entity
@Table(name = "session_records", indexes = {
    @Index(columnList = "user_id, started_at DESC"),
    @Index(columnList = "user_id, kind, started_at DESC")
})
public class SessionRecord {
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", columnDefinition = "uuid", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "kind", nullable = false)
    private Kind kind;

    public enum Kind { WORK, SHORT_BREAK, LONG_BREAK }
}
```

**Validation:**
```java
// Bean Validation on DTOs
public record TaskCreateRequest(
    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title cannot exceed 255 characters")
    String title,
    @Size(max = 1000, message = "Description cannot exceed 1000 characters")
    String description
) {}

// Manual validation in domain objects
public class User {
    public User(UUID id, String email, String displayName, boolean admin) {
        this.id = id;
        this.email = validateEmail(email);
        this.displayName = validateDisplayName(displayName);
    }

    private String validateEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            throw new IllegalArgumentException("Email cannot be null or empty");
        }
        if (!email.contains("@")) {
            throw new IllegalArgumentException("Invalid email format");
        }
        return email.trim().toLowerCase();
    }
}
```

---

## Architecture Patterns

### Repository Pattern

**Backend (JPA):**
```java
// Interface
public interface TaskRepository {
    Optional<Task> findById(UUID id);
    List<Task> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Task save(Task task);
    void deleteById(UUID id);
}

// Implementation
@Repository
public interface JpaTaskRepository extends JpaRepository<Task, UUID> {
    @Query("SELECT t FROM Task t WHERE t.userId = :userId ORDER BY t.createdAt DESC")
    List<Task> findByUserIdOrderByCreatedAtDesc(@Param("userId") UUID userId);
}
```

**Mobile (Protocol):**
```swift
protocol TaskRepository {
    func findById(_ id: UUID) async throws -> Task?
    func findByUserId(_ userId: UUID) async throws -> [Task]
    func save(_ task: Task) async throws
}

struct DefaultTaskRepository: TaskRepository {
    private let apiClient: ApiClientProtocol

    func findById(_ id: UUID) async throws -> Task {
        return try await apiClient.performRequest(APIRequest.fetchTask(id: id.uuidString))
    }
}
```

### Service Layer

Keep controllers thin; business logic lives in service classes.

**Backend:**
```java
@Service
public class TaskService {
    private final TaskRepository taskRepository;
    private final TaskMapper taskMapper;

    public TaskDto create(TaskCreateRequest request, UUID userId) {
        // Validation
        if (request.title() == null || request.title().isBlank()) {
            throw new IllegalArgumentException("Title is required");
        }
        if (request.title().length() > 255) {
            throw new IllegalArgumentException("Title cannot exceed 255 characters");
        }

        // Business logic
        Task task = new Task();
        task.setUserId(userId);
        task.setTitle(request.title().trim());
        task.setDescription(request.description());
        task.setStatus(Task.Status.TODO);

        // Persistence
        Task saved = taskRepository.save(task);
        return taskMapper.toDto(saved);
    }

    public TaskDto update(UUID taskId, TaskUpdateRequest request, UUID userId) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> ResourceNotFoundException.taskNotFound(taskId.toString()));

        // Authorization check
        if (!task.getUserId().equals(userId)) {
            throw AccessDeniedException.taskAccessDenied(taskId, userId);
        }

        // Update only provided fields
        if (request.title() != null) task.setTitle(request.title().trim());
        if (request.description() != null) task.setDescription(request.description());
        if (request.status() != null) task.setStatus(Task.Status.fromString(request.status()));

        Task updated = taskRepository.save(task);
        return taskMapper.toDto(updated);
    }
}
```

### DTO Mapping with MapStruct

```java
@Mapper(componentModel = "spring")
public interface SessionRecordMapper {
    SessionRecordDto toDto(SessionRecord entity);
    SessionRecord toEntity(SessionRecordDto dto);
}

// Usage
SessionRecord entity = mapper.toEntity(dto);
SessionRecordDto dto = mapper.toDto(entity);
```

---

## Error Handling Conventions

### Swift

**Custom Error Types:**
```swift
enum ApiError: Error, LocalizedError {
    case invalidURL
    case encodingFailed(Error)
    case networkError(String)
    case authenticationFailure
    case timeoutError(String)
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .encodingFailed(let error): return "Encoding failed: \(error.localizedDescription)"
        case .networkError(let message): return "Network error: \(message)"
        case .authenticationFailure: return "Authentication failure"
        case .timeoutError(let message): return "Request timeout: \(message)"
        case .serverError(let statusCode, let message): return "Server error \(statusCode): \(message)"
        }
    }
}

// Usage
func fetchTasks() async throws -> [TaskDto] {
    let (data, response) = try await urlSession.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw ApiError.networkError("Invalid response type")
    }
    guard httpResponse.statusCode == 200 else {
        throw ApiError.networkError("Request failed with status: \(httpResponse.statusCode)")
    }
    return try JSONDecoder().decode([TaskDto].self, from: data)
}
```

**Domain Errors:**
```swift
enum TaskServiceError: LocalizedError {
    case validationError(String)
    case networkError(Error)
    case notFound
    case unauthorized
    case serverError(String)
}

// Custom validation errors
enum TaskValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong
    case descriptionTooLong
}
```

### Java

**Domain Exceptions:**
```java
// Resource not found
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
    public static ResourceNotFoundException userNotFound(String userId) {
        return new ResourceNotFoundException("User not found: " + userId);
    }
    public static ResourceNotFoundException taskNotFound(String taskId) {
        return new ResourceNotFoundException("Task not found: " + taskId);
    }
}

// Access control
public class AccessDeniedException extends RuntimeException {
    public AccessDeniedException(String message) {
        super(message);
    }
    public static AccessDeniedException sessionAccessDenied(String sessionId, String userId) {
        return new AccessDeniedException("Access denied: Session " + sessionId + " belongs to user " + userId);
    }
}

// Authentication
public class UserNotAuthenticatedException extends RuntimeException {
    public UserNotAuthenticatedException(String message) {
        super(message);
    }
}
```

**Global Exception Handler:**
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(ResourceNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(Map.of("error", "resource_not_found"));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        return ResponseEntity.badRequest()
            .body(Map.of("error", "validation_failed"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneral(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(Map.of("error", "internal_server_error"));
    }
}
```

---

## Logging Conventions

### Swift (Apple Unified Logging)

```swift
import os.log

final class AppLogger {
    enum Category: String {
        case auth
        case sync
        case timer
        case api
        case lifecycle
        case ui
        case general
    }

    private static let subsystem = "com.sparkage.timebeam"

    private static func logger(for category: Category) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    static func debug(_ message: String, category: Category = .general) {
        #if DEBUG
        logger(for: category).debug("\(message, privacy: .public)")
        FileLogger.writeToFile(level: "DEBUG", category: category.rawValue, message: message)
        #endif
    }

    static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message, privacy: .public)")
        #if DEBUG
        FileLogger.writeToFile(level: "INFO", category: category.rawValue, message: message)
        #endif
    }

    static func warning(_ message: String, category: Category = .general) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    static func error(_ message: String, category: Category = .general) {
        logger(for: category).error("\(message, privacy: .public)")
    }

    // Privacy-aware logging
    static func infoWithPrivate(_ message: String, privateData: String, category: Category = .general) {
        logger(for: category).info("\(message, privacy: .public) - \(privateData, privacy: .private)")
    }
}

// Usage
AppLogger.info("Timer started", category: .timer)
AppLogger.infoWithPrivate("User logged in", privateData: "userId: \(userId)", category: .auth)
```

### Java (SLF4J)

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class TimerSyncService {
    private static final Logger log = LoggerFactory.getLogger(TimerSyncService.class);

    public void pushTimerState(UUID userId, TimerStateDto state, String deviceId) {
        log.debug("pushTimerState called: user={}, device={}", userId, deviceId);
        // ...
        log.info("Timer state pushed for user={}, device={}", userId, deviceId);
    }

    // Request logging filter
    @Component
    public class RequestLoggingFilter extends OncePerRequestFilter {
        @Override
        protected void doFilterInternal(...) {
            log.debug("Request: {} {}", request.getMethod(), request.getRequestURI());
            // ...
        }
    }
}
```

---

## Security Conventions

**CRITICAL - Never:**
- Hardcode secrets in source code
- Log passwords, tokens, or PII
- Use string concatenation for SQL queries
- Trust user input without validation
- Store sensitive data in UserDefaults/SharedPreferences without encryption

**Always:**
- Use environment variables for API keys and secrets
- Validate all user input at system boundaries
- Use parameterized queries (PreparedStatement/JPA)
- Hash passwords with bcrypt/Argon2
- Validate JWT signatures before processing
- Use Keychain (iOS) / EncryptedSharedPreferences (Android) for sensitive data

**Swift - Keychain Usage:**
```swift
// Use Keychain for sensitive data
KeychainStore.saveString(accessToken, for: .accessToken)
KeychainStore.saveString(refreshToken, for: .refreshToken)

// NEVER use UserDefaults for:
// - API tokens
// - User credentials
// - Session data
UserDefaults.standard.set(token, forKey: "token")  // BAD!
```

**Java - Validation:**
```java
// Bean Validation on DTOs
public record LoginRequest(
    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    String email
) {}

// Manual validation in domain
private String validateEmail(String email) {
    if (email == null || email.trim().isEmpty()) {
        throw new IllegalArgumentException("Email cannot be null or empty");
    }
    if (!email.contains("@")) {
        throw new IllegalArgumentException("Invalid email format");
    }
    return email.trim().toLowerCase();
}
```

---

## API Design

### Response Format

**Consistent Envelope:**
```java
public record ApiResponse<T>(boolean success, T data, String error) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, null, message);
    }
}
```

### RESTful Endpoints

**Nouns, not verbs:**
```
GET    /api/tasks          # List tasks
POST   /api/tasks          # Create task
GET    /api/tasks/{id}     # Get task
PUT    /api/tasks/{id}     # Update task
DELETE /api/tasks/{id}     # Delete task

GET    /api/sessions        # List sessions
POST   /api/sessions        # Create session
POST   /api/sessions/start  # Start new session
POST   /api/sessions/{id}/stop  # Stop session
```

**Status Codes:**
- `200 OK` - Successful GET, PUT, PATCH
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing/invalid authentication
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Concurrent update
- `500 Internal Server Error` - Unexpected error

---

## File Organization

### Swift

```
TimeBeam/
├── Domain/
│   └── Models/          # Core domain models
│       ├── UserTask.swift
│       ├── SessionRecord.swift
│       └── PomodoroTimer.swift
├── Application/
│   ├── Services/        # Business logic services
│   │   ├── TaskService.swift
│   │   ├── TimerSyncManager.swift
│   │   └── SessionLogger.swift
│   └── DTOs/            # Data transfer objects
│       └── Analytics/
├── Infrastructure/
│   ├── External/        # External integrations
│   │   ├── AuthManager.swift
│   │   ├── NotificationManager.swift
│   │   └── AppLogger.swift
│   ├── Networking/      # API clients
│   │   ├── ApiClient.swift
│   │   └── AnalyticsApiClient.swift
│   └── Config/          # Configuration
│       ├── KeychainHelper.swift
│       └── ThemeColors.swift
├── Presentation/
│   ├── Views/           # SwiftUI views
│   │   ├── Components/
│   │   ├── iOS/
│   │   └── macOS/
│   └── ViewModels/      # View models (if needed)
└── Extension/           # Swift extensions
    └── AppExtensions.swift
```

### Java

```
back-end/src/main/java/com/sparkage/timebeam/
├── application/
│   └── service/         # Business logic services
│       ├── AuthService.java
│       ├── TaskService.java
│       └── TimerSyncService.java
├── domain/
│   ├── model/           # Domain models
│   │   ├── User.java
│   │   ├── Task.java
│   │   └── SessionRecord.java
│   └── repository/      # Repository interfaces
│       ├── UserRepository.java
│       └── TaskRepository.java
├── infrastructure/
│   ├── persistence/     # JPA entities and repositories
│   │   ├── User.java
│   │   ├── Task.java
│   │   ├── SessionRecord.java
│   │   ├── UserJpaRepository.java
│   │   └── TaskRepository.java
│   ├── external/        # External integrations
│   │   ├── JwtUtils.java
│   │   ├── PushNotificationService.java
│   │   └── GlobalExceptionHandler.java
│   └── config/          # Configuration
│       ├── SecurityConfig.java
│       └── RequestLoggingFilter.java
├── presentation/
│   ├── controller/      # REST controllers
│   │   ├── AuthController.java
│   │   ├── TaskController.java
│   │   └── SessionController.java
│   ├── dto/             # DTOs (requests/responses)
│   │   ├── AuthRequests.java
│   │   ├── TaskDto.java
│   │   └── SessionRecordDto.java
│   └── mapper/          # DTO mappers (MapStruct)
│       ├── UserMapper.java
│       └── TaskMapper.java
└── TimeBeamBackendApplication.java  # Main entry point
```

---

## Comments and Documentation

### Swift

- Use `///` for JSDoc-style comments
- Document public APIs
- Explain *why*, not *what*
- Use `// MARK:` for section organization

```swift
/// Manages synchronization of Pomodoro timer state across devices.
@MainActor
final class TimerSyncManager: ObservableObject {
    /// Syncs timer state with backend server.
    ///
    /// Performs push of local state and pulls latest state from server
    /// for conflict resolution.
    func syncTimerState() async {
        // Implementation
    }

    // MARK: - Private Helpers

    private func performSync() async {
        // Implementation
    }
}
```

### Java

- Use Javadoc (`/** ... */`) for public APIs
- Document parameters, return values, and exceptions
- Use `//` for inline comments

```java
/**
 * Service for managing timer state synchronization across devices.
 * Handles push of local state and pull for conflict resolution.
 */
@Service
public class TimerSyncService {

    /**
     * Pushes timer state from a device to the server.
     *
     * @param userId the user ID
     * @param state the timer state DTO
     * @param deviceId the source device ID
     */
    public void pushTimerState(UUID userId, TimerStateDto state, String deviceId) {
        // Implementation
    }

    /**
     * Retrieves the latest timer state for a user.
     *
     * @param userId the user ID
     * @return Optional containing the timer state, or empty if none exists
     */
    public Optional<TimerStateDto> pullTimerState(UUID userId) {
        // Implementation
    }
}
```

---

*Convention analysis: 2026-04-20*
