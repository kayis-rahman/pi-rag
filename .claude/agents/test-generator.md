# Agent — Test Generator

Generates tests for Swift and Java code. Use when adding new features or fixing bugs.

## Swift Testing
- Framework: XCTest (unit), XCUITest (UI)
- Location: parallel to source files in `Tests/`
- Naming: `ClassNameTests.swift`, methods: `test_scenario_expectedResult()`
- Mock: Use protocol-based mocking, no external mock libraries
- Async: Use `async/await` with `@MainActor` for UI tests

## Java Testing
- Framework: JUnit 5 + Mockito + Spring Boot Test
- Location: `back-end/src/test/java/` parallel to source
- Naming: `ClassNameTest.java`, methods: `test_scenario_expectedResult()`
- Mock: Mockito `@Mock`, `@InjectMocks`, `lenient()` for stubbing
- Integration: `@SpringBootTest`, `@DataJpaTest`, `@WebMvcTest`

## Test Coverage Targets
- Unit tests: 80%+ line coverage
- Service layer: all public methods tested
- Repository layer: CRUD operations + custom queries
- Controller layer: happy path + error cases
- View models: state changes, computed properties

## Test Structure (AAA Pattern)
1. Arrange — setup test data, mocks
2. Act — invoke method under test
3. Assert — verify expected outcomes

## Common Patterns
- Swift: `XCTAssertEqual`, `XCTAssertThrowsError`, `XCTAssertTrue`
- Java: `assertEquals`, `assertThrows`, `assertTrue`
- Swift async: `await`, `Task { @MainActor in ... }`
- Java async: `CompletableFuture`, `@Async`, `WebTestClient`

## Timer Sync Testing
- Verify `deviceId` persists across `TimerSyncManager` instances (Keychain-backed)
- Verify `TimerActionDto` serializes both `action` and `actionType` fields
- Verify `setupApp()` calls `authManager.restoreSession()` before API calls
- Verify silent push `willPresent` handler routes to `syncTimerState()`
- Verify 30-second periodic polling triggers `pollForRemoteChanges()`
- Verify conflict resolution uses `lastModifiedTimestamp` correctly
- Mock `KeychainStore` in tests to avoid Keychain dependency
