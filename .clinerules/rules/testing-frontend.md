# Frontend Testing Rules (Cline)

Comprehensive testing guidelines for iOS, macOS, and watchOS development in TimeBeam.

## 🎯 Core Testing Principles

### 1. Test Early, Test Often
- **Start testing during development**, not after feature completion
- **Run tests frequently** with each code change
- **Integrate testing into CI/CD** pipelines for continuous validation
- **Catch issues early** when they're easier to fix

### 2. Write Tests for All Code
- **Comprehensive coverage** ensures all app components work as expected
- **Test all UI components** and user interactions
- **Test all navigation flows** and state transitions
- **Test all device-specific features** (iOS, macOS, watchOS)
- **Test all accessibility features** (VoiceOver, Dynamic Type, etc.)
- **Test all code paths** including edge cases and error conditions

### 3. Use Meaningful Test Names
- **Descriptive naming**: `testLoginSuccess()`, `testTimerStartPauseFunctionality()`
- **Clear intent**: Names should explain what the test validates
- **Consistent convention**: `test[Feature][Action][ExpectedResult]`
- **Avoid generic names** like `test1()`, `testButton()`

### 4. Keep Tests Focused and Straightforward
- **One responsibility per test** - test single functionality
- **Simple, readable tests** that are easy to maintain
- **Independent tests** with no dependencies between them
- **Clear arrange/act/assert** structure
- **Avoid complex setup** - use helper methods

### 5. Use Code Coverage Tools
- **Track tested code** to identify gaps in coverage
- **Minimum 80% coverage** for production code
- **100% coverage** for critical paths (authentication, data processing)
- **Regular coverage reports** in CI/CD pipelines
- **Monitor coverage trends** and set up alerts for drops

### 6. Automate Tests
- **Automate as many tests as possible** using Xcode or third-party tools
- **Reduce human error** through automation
- **Save time** with automated test suites
- **Enable continuous integration** workflows

### 7. Test with Real Data
- **Use realistic data** whenever possible
- **Test with actual user data** to catch real-world issues
- **Include edge cases** and boundary conditions
- **Validate data processing** with various input types

### 8. Test on Multiple Devices and Simulators
- **Test across device types** (iPhone, iPad, Mac, Watch)
- **Validate different screen sizes** and resolutions
- **Test orientation changes** (portrait/landscape)
- **Verify performance** on various hardware configurations

## 🧪 Test Implementation Guidelines

### Test Structure
```swift
// ✅ GOOD: Focused test with clear name
func testTimerStartPauseFunctionality() throws {
    // Arrange
    let startButton = app.buttons["Start"]
    let pauseButton = app.buttons["Pause"]

    // Act
    startButton.tap()

    // Assert
    XCTAssertTrue(pauseButton.waitForExistence(timeout: 2),
                 "Pause button should appear after starting")
}

// ❌ BAD: Too broad, unclear naming
func testTimer() throws {
    // Tests multiple things at once
    app.buttons["Start"].tap()
    app.buttons["Pause"].tap()
    app.buttons["Reset"].tap()
    // Multiple assertions make failure diagnosis harder
}
```

### Test Organization
```
TimeBeamUITests/
├── iOS/              # iOS-specific tests
│   ├── Timer/        # Timer functionality
│   ├── Analytics/    # Analytics views
│   ├── Settings/     # Settings interface
│   └── Navigation/  # App navigation
├── macOS/            # macOS-specific tests
├── watchOS/          # watchOS-specific tests
└── Shared/           # Cross-platform utilities
```

## 📱 Platform-Specific Testing

### iOS Testing
- **Tab Bar Navigation**: Test all tab switching
- **Full Analytics Interface**: Test charts, loading states, error handling
- **Complete Settings**: Test all preference controls
- **Device Rotation**: Test portrait and landscape modes
- **Multiple Screen Sizes**: Test iPhone and iPad layouts

### macOS Testing
- **Window Management**: Test resizing, fullscreen, multi-window
- **Menu Options**: Test all menu items and keyboard shortcuts
- **Mouse/Hover Interactions**: Test button states and tooltips
- **Keyboard Navigation**: Test focus management and shortcuts

### watchOS Testing
- **Compact Layout**: Test appropriate sizing for small screens
- **Simplified Controls**: Test minimal interface elements
- **Haptic Feedback**: Test timer completion notifications
- **Performance Optimization**: Test memory usage on limited devices

## 🔍 Test Types and Coverage

### UI Testing (XCTest)
```swift
// Example: Testing timer functionality
func testTimerStartPauseFunctionality() throws {
    let app = XCUIApplication()
    app.launch()

    // Test start functionality
    app.buttons["Start"].tap()
    XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))

    // Test pause functionality
    app.buttons["Pause"].tap()
    XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 2))
}
```

### Unit Testing
```swift
// Example: Testing business logic
func testTimerPhaseTransitionLogic() {
    let timer = PomodoroTimer()
    timer.start()

    // Test phase transition after work duration
    timer.remainingSeconds = 0
    timer.checkPhaseTransition()

    XCTAssertEqual(timer.phase, .break, "Should transition to break phase")
}
```

### Performance Testing
```swift
func testAnalyticsLoadingPerformance() throws {
    measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["Weekly?"].waitForExistence(timeout: 5))
    }
}
```

### Accessibility Testing
```swift
func testVoiceOverCompatibility() throws {
    let startButton = app.buttons["Start"]
    XCTAssertTrue(startButton.exists, "Start button should be accessible")

    // Test dynamic type support
    let timeDisplay = app.staticTexts["TimeDisplay"]
    XCTAssertTrue(timeDisplay.exists, "Should support dynamic type")
}
```

## 📊 Code Coverage Requirements

- **Minimum 80% coverage** for all production code
- **100% coverage** for critical paths (authentication, data processing)
- **Regular coverage reports** in CI/CD pipelines
- **Coverage monitoring** with alerts for drops below thresholds

## 🚀 Test Automation

### CI/CD Integration
```yaml
# GitHub Actions example
name: UI Testing CI/CD

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - uses: maxim-lobanov/setup-xcode@v1
    - run: xcodebuild test -workspace TimeBeam.xcworkspace
      -scheme TimeBeam
      -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Local Automation
```bash
# Run all tests
xcodebuild test -workspace TimeBeam.xcworkspace -scheme TimeBeam

# Run specific test class
xcodebuild test -workspace TimeBeam.xcworkspace
  -scheme TimeBeam
  -only-testing:TimeBeamUITests/iOSTimerUITests

# Run with coverage
xcodebuild test -workspace TimeBeam.xcworkspace
  -scheme TimeBeam
  -enableCodeCoverage YES
```

## 🔧 Test Maintenance Best Practices

### Test Refactoring
- **Update tests with feature changes**
- **Improve test reliability** - fix flaky tests promptly
- **Optimize test performance** - reduce test execution time
- **Enhance test readability** - clear assertions and comments

### Test Documentation
- **Document test purpose** in header comments
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
