# Common Testing Patterns

> Shared testing patterns for TimeBeam project.

## Test Structure (AAA Pattern)

1. **Arrange** — setup test data, mocks
2. **Act** — invoke method under test
3. **Assert** — verify expected outcomes

## Coverage Targets

- Unit tests: 80%+ line coverage
- Service layer: 100% of public methods tested
- Repository layer: CRUD operations + custom queries
- Controller layer: happy path + error cases

## Swift Testing

- Framework: XCTest (unit), XCUITest (UI)
- Location: `Tests/` parallel to source
- Naming: `ClassNameTests.swift`
- Methods: `test_scenario_expectedResult()`
- Async: Use `async/await` with `@MainActor`
- Mock: Protocol-based mocking, no external libraries

## Java Testing

- Framework: JUnit 5 + Mockito + Spring Boot Test
- Location: `src/test/java/` parallel to source
- Naming: `ClassNameTest.java`
- Methods: `test_scenario_expectedResult()`
- Mock: Mockito `@Mock`, `@InjectMocks`, `lenient()` for stubbing
- Integration: `@SpringBootTest`, `@DataJpaTest`, `@WebMvcTest`

## Mocking Rules

- Mock only external dependencies (DB, API, Keychain)
- Don't mock the class under test
- Verify mock interactions: `verify(mock, times(1)).method()`
- Use `lenient()` for stubs that may not be called in all tests
- Never hit real Keychain in unit tests

## Common Assertions

**Swift**: `XCTAssertEqual`, `XCTAssertThrowsError`, `XCTAssertTrue`, `XCTAssertNil`

**Java**: `assertEquals`, `assertThrows`, `assertTrue`, `assertNull`

## CI Testing

- `mvn test` — unit tests
- `mvn verify` — integration + E2E tests
- Xcode test scheme for iOS/macOS
- Coverage report: `mvn jacoco:report`
