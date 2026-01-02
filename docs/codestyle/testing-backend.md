# Backend Testing Rules (Cline)

Comprehensive testing guidelines for Java/Spring Boot development in TimeBeam.

## 🎯 Core Testing Principles

### 1. Test Early, Test Often
- **Start testing during development**, not after feature completion
- **Run tests frequently** with each code change
- **Integrate testing into CI/CD** pipelines for continuous validation
- **Catch issues early** when they're easier to fix

### 2. Write Tests for All Code
- **Comprehensive coverage** ensures all app components work as expected
- **Test all code paths** including edge cases and error conditions
- **Unit tests** for business logic and utilities
- **Integration tests** for component interactions
- **API tests** for endpoint functionality

### 3. Use Meaningful Test Names
- **Descriptive naming**: `testUserAuthenticationSuccess()`, `testTaskCreationValidation()`
- **Clear intent**: Names should explain what the test validates
- **Consistent convention**: `test[Feature][Action][ExpectedResult]`
- **Avoid generic names** like `test1()` or `testMethod()`

### 4. Keep Tests Focused and Straightforward
- **One responsibility per test** - test single functionality
- **Simple, readable tests** that are easy to maintain
- **Independent tests** with no dependencies between them
- **Clear arrange/act/assert** structure

### 5. Use Code Coverage Tools
- **Track tested code** to identify gaps in coverage
- **Minimum 80% coverage** for production code
- **100% coverage** for critical paths (authentication, data processing)
- **Regular coverage reports** in CI/CD pipelines
- **Monitor coverage trends** and set up alerts for drops

### 6. Automate Tests
- **Automate as many tests as possible** using Maven/Gradle or third-party tools
- **Reduce human error** through automation
- **Save time** with automated test suites
- **Enable continuous integration** workflows

### 7. Test with Real Data
- **Use realistic data** whenever possible
- **Test with actual user data** to catch real-world issues
- **Include edge cases** and boundary conditions
- **Validate data processing** with various input types

### 8. Test on Multiple Environments
- **Test across environments** (dev, staging, production-like)
- **Validate different configurations** and database setups
- **Test performance** under various load conditions
- **Verify compatibility** with different data sources

## 🧪 Test Implementation Guidelines

### Test Structure
```java
// ✅ GOOD: Focused test with clear name
@Test
void testUserAuthenticationSuccess() {
    // Arrange
    UserCredentials credentials = new UserCredentials("user@example.com", "password");

    // Act
    AuthenticationResult result = authService.authenticate(credentials);

    // Assert
    assertTrue(result.isSuccessful());
    assertNotNull(result.getToken());
}

// ❌ BAD: Too broad, unclear naming
@Test
void testAuth() {
    // Tests multiple things at once
    // Multiple assertions make failure diagnosis harder
}
```

### Test Organization
```
src/test/java/
├── unit/              # Unit tests
│   ├── service/       # Service layer tests
│   ├── repository/    # Repository tests
│   └── util/          # Utility tests
├── integration/       # Integration tests
│   ├── api/           # API endpoint tests
│   └── database/      # Database integration tests
└── e2e/               # End-to-end tests
```

## 📊 Code Coverage Requirements

- **Minimum 80% coverage** for all production code
- **100% coverage** for critical paths (authentication, data processing, payment flows)
- **Regular coverage reports** in CI/CD pipelines
- **Coverage monitoring** with alerts for drops below thresholds

## 🚀 Test Automation

### CI/CD Integration
```yaml
# GitHub Actions example for backend
name: Backend Testing CI/CD

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
    - name: Run Tests
      run: mvn test
    - name: Generate Coverage Report
      run: mvn jacoco:report
```

### Local Automation
```bash
# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=UserServiceTest

# Run with coverage
mvn clean test jacoco:report

# Run integration tests only
mvn verify -Pintegration-test
```

## 🔍 Test Types and Coverage

### Unit Testing (JUnit 5)
```java
@SpringBootTest
class UserServiceTest {

    @MockBean
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    @Test
    void testUserCreationSuccess() {
        // Arrange
        UserCreateRequest request = new UserCreateRequest("user@example.com", "password");
        when(userRepository.save(any(User.class))).thenReturn(new User());

        // Act
        UserDto result = userService.createUser(request);

        // Assert
        assertNotNull(result);
        verify(userRepository).save(any(User.class));
    }
}
```

### Integration Testing
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class UserControllerIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void testCreateUserEndpoint() {
        // Arrange
        UserCreateRequest request = new UserCreateRequest("user@example.com", "password");

        // Act
        ResponseEntity<UserDto> response = restTemplate.postForEntity(
            "/api/users", request, UserDto.class);

        // Assert
        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
    }
}
```

### Performance Testing
```java
@Test
void testUserSearchPerformance() {
    // Create test data
    for (int i = 0; i < 1000; i++) {
        userService.createUser(new UserCreateRequest("user" + i + "@example.com", "password"));
    }

    // Measure performance
    long startTime = System.nanoTime();
    List<UserDto> results = userService.searchUsers("user");
    long endTime = System.nanoTime();

    // Assert performance requirements
    long durationMs = (endTime - startTime) / 1_000_000;
    assertTrue(durationMs < 100, "Search should complete within 100ms");
    assertFalse(results.isEmpty());
}
```

## 🔧 Test Maintenance Best Practices

### Test Refactoring
- **Update tests with feature changes**
- **Improve test reliability** - fix flaky tests promptly
- **Optimize test performance** - reduce test execution time
- **Enhance test readability** - clear assertions and comments

### Test Documentation
- **Document test purpose** in class/method Javadoc
- **Explain complex test logic** with inline comments
- **Maintain test README** with setup instructions
- **Document test data requirements**

## 🎓 Training and Adoption

### Team Practices
- **Code reviews include test review**
- **Pair programming on complex tests**
- **Test-driven development workshops**
- **Regular test coverage reviews**

### Knowledge Sharing
- **Document testing patterns** and anti-patterns
- **Share test optimization techniques**
- **Conduct test failure analysis** sessions
- **Maintain testing best practices** documentation
