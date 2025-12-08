# End-to-End Testing with Live Backend

This document describes the E2E testing setup that connects the TimeBeam iOS app to a live backend for comprehensive integration testing.

## Overview

The E2E testing framework provides:
- **Live Backend Connection**: Tests run against a real Spring Boot backend instead of mocks
- **Seeded Test Data**: Pre-populated database with consistent test fixtures
- **Comprehensive Workflows**: Full user journeys from authentication to analytics
- **Cross-Platform Testing**: iOS and macOS support with device synchronization
- **CI/CD Ready**: Automated test execution with proper cleanup

## Architecture

### Backend Test Infrastructure
- **E2E Profile**: Dedicated Spring profile (`application-e2e.yml`) with test configuration
- **Test Database**: Isolated PostgreSQL database (`timebeam_e2e`) with seeded data
- **Data Seeder**: `E2ETestDataSeeder` component that populates test data on startup
- **Runner Script**: `run-e2e-backend.sh` for automated backend startup

### iOS Test Infrastructure
- **Test Configuration**: `TestConfiguration.swift` with environment-specific settings
- **Base Test Class**: `TimeBeamE2ETestBase` providing common setup and helpers
- **Authentication**: Automatic login flows using seeded test accounts
- **API Verification**: Direct API calls to verify backend state changes

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Maven 3.6+
- Xcode 15+ with iOS Simulator
- PostgreSQL client (optional, for debugging)

### 1. Start the E2E Backend

```bash
cd back-end
./run-e2e-backend.sh
```

This will:
- Start PostgreSQL in a container
- Build and run the Spring Boot app on port 8081
- Seed the database with test data
- Keep the backend running until interrupted

### 2. Run E2E Tests

In a new terminal:

```bash
cd apple/TimeBeam
xcodebuild test \
  -workspace TimeBeam.xcworkspace \
  -scheme "TimeBeam iOS" \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0" \
  -testPlan E2E \
  -resultBundlePath TestResults \
  E2E_BACKEND_URL=http://localhost:8081 \
  E2E_TESTING=true
```

### 3. View Results

Test results are available in:
- Xcode Test Navigator
- `TestResults.xcresult` bundle
- Console output with detailed failure information

## Test Categories

### Authentication Tests (`E2EAuthenticationTests`)
- Backend connectivity verification
- User login with seeded accounts
- Invalid credential handling
- Auto-registration for new users
- Test data availability verification

### Timer Workflow Tests (`E2ETimerWorkflowTests`)
- Timer state synchronization
- Session creation and completion
- Task association with timer sessions
- Pause/resume functionality
- Cross-device synchronization
- Analytics integration

### Comprehensive Test Categories

#### Authentication Tests (`E2EAuthenticationTests`)
- Backend connectivity verification
- User login with seeded accounts
- Invalid credential handling
- Auto-registration for new users
- Test data availability verification

#### Timer Workflow Tests (`E2ETimerWorkflowTests`)
- Timer state synchronization
- Session creation and completion
- Task association with timer sessions
- Pause/resume functionality
- Cross-device synchronization
- Analytics integration

#### macOS Tests (`E2EMacOSTests`)
- macOS-specific window management
- Menu bar integration
- Task management on macOS
- Analytics viewing on macOS
- Settings panel functionality
- Multi-window support
- Device registration

#### Task Management Tests (`E2ETaskManagementTests`)
- Full CRUD operations (Create, Read, Update, Delete)
- Task validation and error handling
- Status updates (TODO → In Progress → Completed)
- Task filtering and search
- Bulk operations
- Time tracking integration
- Analytics correlation

### Future Test Categories
- **Analytics Validation Tests**: Dashboard data accuracy, historical trends
- **Settings Tests**: Preference persistence, theme changes
- **Cross-Device Synchronization**: Multi-device timer state syncing
- **Performance Tests**: Load testing and response time validation

## Test Data

### Seeded Users
- **Primary Test User**: `test@example.com` / Auto-login
- **Secondary Test User**: `test2@example.com` / Auto-login

### Seeded Tasks
- "Complete project documentation" (TODO)
- "Implement user authentication" (IN_PROGRESS)
- "Set up CI/CD pipeline" (COMPLETED)
- "Design user interface" (TODO)

### Seeded Sessions
- Multiple historical sessions with different kinds (WORK, BREAK)
- Task associations
- Realistic timestamps and durations

### Seeded Device Registrations
- iOS simulator device
- macOS device
- User preferences and timer states

## Configuration

### Environment Variables

#### Backend Configuration
```bash
# Database
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/timebeam_e2e
SPRING_DATASOURCE_USERNAME=timebeam
SPRING_DATASOURCE_PASSWORD=timebeam

# JWT
JWT_SECRET=e2e-test-jwt-secret-key-for-testing-purposes-only-not-for-production

# Profile
SPRING_PROFILES_ACTIVE=e2e
```

#### iOS Test Configuration
```bash
# Backend URL
E2E_BACKEND_URL=http://localhost:8081

# Test mode flag
E2E_TESTING=true
```

### Test Database

The E2E tests use a separate PostgreSQL database that gets completely reset between test runs. The database is created with:

```sql
CREATE DATABASE timebeam_e2e;
```

### Backend Ports

- **Development**: `http://localhost:8080`
- **E2E Testing**: `http://localhost:8081`

## Test Execution Options

### Running Specific Tests

```bash
# Run only authentication tests
xcodebuild test \
  -workspace TimeBeam.xcworkspace \
  -scheme "TimeBeam iOS" \
  -only-testing TimeBeamUITests/E2EAuthenticationTests

# Run only timer tests
xcodebuild test \
  -workspace TimeBeam.xcworkspace \
  -scheme "TimeBeam iOS" \
  -only-testing TimeBeamUITests/E2ETimerWorkflowTests
```

### Different Destinations

```bash
# iPad testing
-destination "platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation),OS=17.0"

# macOS testing
-destination "platform=macOS"
```

### Parallel Execution

```bash
# Run tests in parallel on multiple simulators
xcodebuild test \
  -workspace TimeBeam.xcworkspace \
  -scheme "TimeBeam iOS" \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0" \
  -destination "platform=iOS Simulator,name=iPhone 14,OS=16.4" \
  -parallel-testing-enabled YES \
  -maximum-parallel-testing-workers 2
```

## Debugging Tests

### Backend Logs

```bash
# View backend logs
cd back-end
tail -f logs/timebeam.log
```

### Test Screenshots

Failed tests automatically capture screenshots saved to:
```
TestResults.xcresult/Attachments/
```

### Network Debugging

Enable network debugging in tests:

```swift
// In test setup
app.launchEnvironment["CFNETWORK_DIAGNOSTICS"] = "3"
```

### Database Inspection

Connect to the test database:

```bash
psql -h localhost -U timebeam -d timebeam_e2e
```

Useful queries:
```sql
-- View all users
SELECT * FROM users;

-- View recent sessions
SELECT * FROM session_records ORDER BY started_at DESC LIMIT 5;

-- View tasks
SELECT * FROM tasks;

-- View timer states
SELECT * FROM timer_states;
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e-test:
    runs-on: macos-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: timebeam_e2e
          POSTGRES_USER: timebeam
          POSTGRES_PASSWORD: timebeam
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
    - uses: actions/checkout@v4

    - name: Setup Java
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'

    - name: Start Backend
      run: |
        cd back-end
        ./mvnw spring-boot:run -Dspring-boot.run.profiles=e2e &
        BACKEND_PID=$!
        echo "BACKEND_PID=$BACKEND_PID" >> $GITHUB_ENV

    - name: Wait for Backend
      run: |
        for i in {1..30}; do
          if curl -f http://localhost:8081/api/auth/health; then
            break
          fi
          sleep 2
        done

    - name: Run E2E Tests
      run: |
        cd apple/TimeBeam
        xcodebuild test \
          -workspace TimeBeam.xcworkspace \
          -scheme "TimeBeam iOS" \
          -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0" \
          -resultBundlePath TestResults \
          E2E_BACKEND_URL=http://localhost:8081 \
          E2E_TESTING=true

    - name: Upload Test Results
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: e2e-test-results
        path: apple/TimeBeam/TestResults.xcresult
```

## Troubleshooting

### Common Issues

#### Backend Won't Start
```bash
# Check if port 8081 is available
lsof -i :8081

# Check Docker containers
docker ps

# View backend logs
cd back-end && tail -f logs/timebeam.log
```

#### Tests Fail with Network Errors
```bash
# Verify backend is running
curl http://localhost:8081/api/auth/health

# Check firewall settings
# Ensure no VPN interference
```

#### Database Connection Issues
```bash
# Test database connection
psql -h localhost -U timebeam -d timebeam_e2e -c "SELECT 1;"

# Check Docker network
docker network ls
```

#### iOS Simulator Issues
```bash
# Reset simulators
xcrun simctl erase all

# List available devices
xcodebuild -showdestinations -workspace TimeBeam.xcworkspace -scheme "TimeBeam iOS"
```

### Performance Optimization

#### Backend Performance
- Use H2 in-memory database for faster tests (when acceptable)
- Disable unnecessary logging in test profile
- Use connection pooling appropriately

#### Test Performance
- Run tests in parallel when possible
- Use appropriate timeouts (don't wait longer than necessary)
- Cache authentication tokens between tests

## Contributing

### Adding New E2E Tests

1. **Extend Base Class**: Inherit from `TimeBeamE2ETestBase`
2. **Use Test Configuration**: Leverage `TestConfiguration` for consistent settings
3. **Add Backend Verification**: Include API calls to verify backend state
4. **Handle Authentication**: Use `performAuthenticatedAction` for user-specific tests
5. **Add Test Data**: Update `E2ETestDataSeeder` if new test data is needed

### Test Naming Convention

```swift
func test[Feature][Action][ExpectedResult]() throws {
    // Test implementation
}
```

Examples:
- `testTimerStartAndSessionCreation()`
- `testTaskCreationWithValidation()`
- `testAnalyticsDataAccuracyAfterSession()`

### Best Practices

- **Isolation**: Each test should be independent
- **Cleanup**: Tests should not affect each other
- **Realism**: Use realistic test data and user flows
- **Performance**: Keep tests fast (under 30 seconds each)
- **Reliability**: Handle network delays and async operations
- **Documentation**: Comment complex test logic

## Future Enhancements

- **Visual Regression Testing**: Screenshot comparison for UI changes
- **Performance Testing**: Response time validation and memory leak detection
- **Load Testing**: Multiple concurrent users simulation
- **Real Device Testing**: Integration with physical iOS devices
- **Cross-Platform Sync**: iOS ↔ macOS ↔ watchOS synchronization tests
