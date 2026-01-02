# Stage 1: Test Infrastructure Foundation - Implementation Guide

**Status:** 🟢 In Progress
**Start Date:** 2025-01-XX
**Estimated Completion:** 2025-01-XX (1-2 weeks)

---

## Overview

Stage 1 establishes the foundation for comprehensive testing across all platforms. This stage focuses on:

1. **Coverage Setup:** Enable coverage reporting for backend (Jacoco) and iOS/macOS/watchOS
2. **Test Configuration:** Centralized test configuration and matrix management
3. **Result Aggregation:** Unified test reporting and dashboards
4. **CI/CD Integration:** Integrate all test workflows into the main CI pipeline

---

## Goals

- ✅ All tests run successfully on every PR
- ✅ Coverage reports generated for backend and iOS
- ✅ Test execution time < 15 minutes
- ✅ No flaky tests
- ✅ Coverage gates enforced (backend 80%, iOS 75%)

---

## Tasks Checklist

### Backend Coverage Setup

#### 1. Add Jacoco Maven Plugin
- [ ] Add JaCoCo plugin to `pom.xml`
- [ ] Configure agent for offline instrumentation
- [ ] Set coverage thresholds (80% line, 75% branch)
- [ ] Generate reports in XML, HTML, CSV formats

#### 2. Backend Coverage Configuration
- [ ] Create jacoco-agent-config.xml
- [ ] Configure excluded classes (DTOs, entities, config)
- [ ] Add custom JaCoCo rules
- [ ] Integrate with SonarCloud

#### 3. Test Execution
- [ ] Run unit tests with JaCoCo agent
- [ ] Run integration tests with JaCoCo
- [ ] Verify reports generate correctly
- [ ] Check coverage meets thresholds

---

### iOS/macOS/watchOS Coverage Setup

#### 1. Xcode Scheme Configuration
- [ ] Enable code coverage for iOS scheme
- [ ] Enable code coverage for macOS scheme
- [ ] Enable code coverage for watchOS scheme
- [ ] Configure coverage target directories

#### 2. Coverage Reporting
- [ ] Install xccov-to-sonarqube converter
- [ ] Generate .xccoverage reports
- [ ] Convert to SonarQube format
- [ ] Test locally to verify reports

#### 3. Codecov Integration
- [ ] Create .codecov.yml configuration
- [ ] Set up Codecov token in GitHub secrets
- [ ] Configure coverage thresholds
- [ ] Add PR comments with coverage changes

---

### Centralized Test Configuration

#### 1. Test Config Workflow
- [ ] Create test-config.yml
- [ ] Define test matrix variables
- [ ] Configure test environment variables
- [ ] Set up test timeouts
- [ ] Configure retry logic

#### 2. Backend Test Configuration
- [ ] Define Java version (17)
- [ ] Set Maven options (-Xmx1024m)
- [ ] Configure PostgreSQL service
- [ ] Set test profile variables
- [ ] Configure test database

#### 3. iOS Test Configuration
- [ ] Define Xcode versions matrix
- [ ] Define iOS simulator matrix
- [ ] Configure macOS versions
- [ ] Set up derived data caching
- [ ] Configure CocoaPods caching

---

### Test Result Aggregation

#### 1. Unified Report Workflow
- [ ] Create test-report.yml
- [ ] Download all test artifacts
- [ ] Parse test results (JUnit XML, XCTest results)
- [ ] Generate summary statistics
- [ ] Create markdown report

#### 2. PR Comments
- [ ] Add test summary to PR comments
- [ ] Include coverage changes
- [ ] Highlight failing tests
- [ ] Link to detailed reports
- [ ] Add pass/fail badges

#### 3. Test Dashboard
- [ ] Create GitHub Actions summary
- [ ] Include trend charts
- [ ] Show coverage trends
- [ ] List flaky tests
- [ ] Display execution times

---

## Implementation Steps

### Step 1: Backend Coverage (30 minutes)

```bash
cd back-end
# Add JaCoCo plugin to pom.xml
# Create jacoco-agent-config.xml
# Run tests with coverage
mvn clean test jacoco:report
# Verify reports
ls target/site/jacoco/index.html
```

### Step 2: iOS Coverage (1 hour)

```bash
cd apple/TimeBeam
# Modify schemes to enable coverage
xcodebuild -list
# Edit schemes in Xcode or with xcodebuild
# Run tests with coverage
xcodebuild test \
  -scheme "TimeBeam iOS" \
  -enableCodeCoverage YES \
  -derivedDataPath DerivedData
# Verify coverage reports
ls DerivedData/Logs/Test/*.xcresult
```

### Step 3: Create Test Config (30 minutes)

```bash
# Create .github/workflows/test-config.yml
# Define shared configuration
# Test locally with act
act -j test-config
```

### Step 4: Create Test Report (30 minutes)

```bash
# Create .github/workflows/test-report.yml
# Download artifacts
# Generate summary
# Post to PR
```

### Step 5: Integration (1 hour)

```bash
# Update ci.yml to use new workflows
# Test full pipeline
# Verify all reports
# Check execution time
```

---

## File Changes

### New Files

```
.github/workflows/
├── test-config.yml
├── test-unit.yml
├── test-integration.yml
└── test-report.yml

back-end/src/test/resources/
└── jacoco-agent-config.xml

apple/TimeBeam/
└── .codecov.yml
```

### Modified Files

```
back-end/pom.xml

apple/TimeBeam/TimeBeam.xcodeproj/xcshareddata/xcschemes/
├── TimeBeam iOS.xcscheme
└── TimeBeam macOS.xcscheme

.github/workflows/ci.yml
.github/workflows/backend.yml
```

---

## Configuration Details

### JaCoCo Plugin Configuration

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <executions>
        <execution>
            <id>prepare-agent</id>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
        <execution>
            <id>check</id>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <rules>
                    <rule>
                        <element>BUNDLE</element>
                        <limits>
                            <limit>
                                <counter>LINE</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.80</minimum>
                            </limit>
                            <limit>
                                <counter>BRANCH</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.75</minimum>
                            </limit>
                        </limits>
                    </rule>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
```

### Codecov Configuration

```yaml
codecov:
  require_ci_to_pass: yes
  coverage:
    precision: 2
    round: down
    range: "70...100"
    status:
      project:
        default:
          target: auto
          threshold: 1%
          informational: true
      patch:
        default:
          target: auto
          threshold: 1%
          informational: true

ignore:
  - "*/test/*"
  - "*/Test*.java"
  - "*/model/*"
  - "*/dto/*"

comment:
  layout: "reach,diff,flags,tree,reach,delta"
  behavior: default
  require_changes: false
```

### Test Configuration Variables

```yaml
env:
  # Java
  JAVA_VERSION: "17"
  MAVEN_OPTS: "-Xmx1024m"

  # Test execution
  TEST_TIMEOUT_MINUTES: 15
  TEST_RETRY_COUNT: 3

  # Coverage
  COVERAGE_THRESHOLD_LINE: 80
  COVERAGE_THRESHOLD_BRANCH: 75

  # iOS
  XCODE_VERSION: "15.2"
  IOS_DESTINATIONS: |
    iOS Simulator,name=iPhone 15,OS=17.2
    iOS Simulator,name=iPhone 14,OS=16.5

  # macOS
  MACOS_VERSION: "14.0"

  # WatchOS
  WATCHOS_DESTINATION: |
    watchOS Simulator,name=Apple Watch Series 9 (45mm),OS=10.0
```

---

## Test Matrix

### Backend Test Matrix

```yaml
strategy:
  matrix:
    java: ['17']
    os: ['ubuntu-latest', 'macos-latest']
  fail-fast: false
```

### iOS Test Matrix

```yaml
strategy:
  matrix:
    include:
      - xcode: "15.2"
        destination: "iOS Simulator,name=iPhone 15,OS=17.2"
        platform: iOS
      - xcode: "15.2"
        destination: "iOS Simulator,name=iPhone 14,OS=16.5"
        platform: iOS
      - xcode: "15.2"
        destination: "iOS Simulator,name=iPhone SE (3rd generation),OS=17.2"
        platform: iOS
  fail-fast: false
```

### macOS Test Matrix

```yaml
strategy:
  matrix:
    macos: ['13', '14']
  fail-fast: false
```

---

## Success Criteria Verification

### Automated Checks

```bash
# 1. Backend coverage
curl -s https://codecov.io/gh/owner/repo/branch/main | jq '.coverage.totals.line'

# 2. iOS coverage
xcodebuild test -enableCodeCoverage YES
xcrun xccov view --report --json DerivedData/Logs/Test/*.xcresult

# 3. Test execution time
grep "duration" .github/workflows/run-*.log | awk '{sum+=$2} END {print sum/60}'

# 4. Flaky test detection
# Analyze historical results from GitHub API
```

### Manual Checks

- [ ] Verify coverage reports are accessible
- [ ] Check test execution time is < 15 minutes
- [ ] Review test results in PR comments
- [ ] Confirm coverage gates enforce properly
- [ ] Validate no flaky tests (run 3 times)

---

## Troubleshooting

### Backend Coverage Issues

**Problem:** JaCoCo agent not instrumenting classes
**Solution:**
```xml
<argLine>${jacoco.agent.argLine}</argLine>
```

**Problem:** Coverage below threshold but tests pass
**Solution:** Check excluded classes, add more test cases

### iOS Coverage Issues

**Problem:** Coverage not generated
**Solution:**
```bash
# Enable coverage in scheme
xcodebuild -scheme "TimeBeam iOS" -showBuildSettings | grep -i coverage
# Should show: ENABLE_TESTABILITY = YES
```

**Problem:** Coverage reports missing files
**Solution:** Check scheme configuration includes all targets

### Test Execution Issues

**Problem:** Tests timeout
**Solution:** Increase timeout in test-config.yml
```yaml
env:
  TEST_TIMEOUT_MINUTES: 30
```

**Problem:** Flaky tests
**Solution:**
- Add retry logic
- Check test isolation
- Review timing-dependent tests

---

## Rollback Plan

If Stage 1 implementation causes issues:

1. **Revert specific file changes**
   ```bash
   git checkout HEAD~1 -- back-end/pom.xml
   git checkout HEAD~1 -- .github/workflows/*.yml
   ```

2. **Disable coverage enforcement temporarily**
   ```yaml
   # In ci.yml, comment out coverage check
   # - name: Check coverage thresholds
   #   run: ...
   ```

3. **Restore previous test workflow**
   ```bash
   git checkout HEAD~1 -- .github/workflows/backend.yml
   ```

---

## Next Stage

After Stage 1 completion, proceed to **Stage 2: Enhanced Unit & Integration Testing**

**Prerequisites met:**
- ✅ Coverage reporting operational
- ✅ Test infrastructure stable
- ✅ Test execution time acceptable
- ✅ No flaky tests

---

## References

- [JaCoCo Maven Plugin](https://www.jacoco.org/jacoco/trunk/doc/maven.html)
- [Codecov Documentation](https://docs.codecov.com/)
- [Xcode Coverage](https://developer.apple.com/documentation/xcode/code-coverage)
- [GitHub Actions Workflows](https://docs.github.com/en/actions/using-workflows)

---

## Progress Log

| Date | Task | Status | Notes |
|-------|-------|--------|-------|
| 2025-01-XX | Stage 1 planning | ✅ Complete | Documented all tasks |
| 2025-01-XX | Backend coverage setup | 🟢 In Progress | Adding Jacoco plugin |
| 2025-01-XX | iOS coverage setup | ⚪ Pending | |
| 2025-01-XX | Test config creation | ⚪ Pending | |
| 2025-01-XX | Test report workflow | ⚪ Pending | |
| 2025-01-XX | Integration testing | ⚪ Pending | |
