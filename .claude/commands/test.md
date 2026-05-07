# /test — Run all tests

Run unit tests, integration tests, and E2E tests for backend and iOS/macOS.

## Backend Tests
```
cd back-end && mvn test
cd back-end && mvn test -Dspring.profiles.active=e2e
```

## iOS/macOS Tests
```
xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam iOS" test -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam macOS" test
```

## E2E Tests
```
# Start backend + postgres
docker compose -f back-end/docker-compose.dev.yml up -d postgres

# Run backend with E2E profile
cd back-end && SPRING_PROFILES_ACTIVE=e2e mvn spring-boot:run

# Run E2E test suite
cd back-end && mvn verify -Dspring.profiles.active=e2e
```

## Timer Sync Test Suite
- `TimerSyncManagerUnitTests.swift` — deviceId persistence, action sync, incoming actions
- `TimerSyncIntegrationTests.swift` — end-to-end sync flow, WatchConnectivity integration
- Mock `KeychainStore` in tests to avoid Keychain dependency
- Verify `TimerActionDto` round-trips `action` → `actionType` correctly

## Test Coverage
- Backend: `mvn jacoco:report` (target/site/jacoco/index.html)
- iOS/macOS: Xcode coverage (Product → Test with Coverage)
