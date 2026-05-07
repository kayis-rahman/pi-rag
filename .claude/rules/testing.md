# Testing Standards

> Extends [rules/common/testing.md](../../rules/common/testing.md) with TimeBeam test conventions.

## Coverage Targets
- Unit tests: 80%+ line coverage
- Service layer: 100% of public methods
- Repository layer: all custom queries
- Controller layer: happy path + error cases

## Test Structure (AAA)
1. Arrange — setup test data, mocks
2. Act — invoke method under test
3. Assert — verify outcomes

## Swift Tests
- Location: `Tests/` parallel to source
- Naming: `ClassNameTests.swift`
- Methods: `test_scenario_expectedResult()`
- Framework: XCTest
- Async: `async/await` with `@MainActor`
- Mocks: protocol-based, no external libraries

## Java Tests
- Location: `src/test/java/` parallel to source
- Naming: `ClassNameTest.java`
- Methods: `test_scenario_expectedResult()`
- Framework: JUnit 5 + Mockito
- Annotations: `@Mock`, `@InjectMocks`, `@ExtendWith(MockitoExtension.class)`
- Integration: `@SpringBootTest`, `@DataJpaTest`, `@WebMvcTest`

## Test Data
- Use factories/builder pattern for test data
- Never reuse mutable test data between tests
- Use `@BeforeEach` for fresh state
- Constants for magic values

## Mocking Rules
- Mock only external dependencies (DB, API, Keychain)
- Don't mock the class under test
- Verify mock interactions: `verify(mock, times(1)).method()`
- Use `lenient()` for stubs that may not be called in all tests

## Timer Sync Testing Conventions
- Mock `KeychainStore` in tests — never hit real Keychain in unit tests
- Verify `TimerActionDto` round-trips: iOS `action` → backend `actionType`
- Verify `TimerSyncManager.deviceId` is Keychain-backed (same value across instances)
- Test `setupApp()` auth restore flow before API calls

## CI Testing
- `mvn test` — unit tests
- `mvn verify` — integration + E2E tests
- Xcode test scheme for iOS/macOS
- Coverage report: `mvn jacoco:report`
