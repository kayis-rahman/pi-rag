# Agents Configuration

## 🧠 RAG Memory System (MANDATORY - ALWAYS LOAD FIRST)

**CRITICAL**: Before ANY task, ALWAYS query the RAG memory system for TimeBeam context. This reduces repetitive prompts and eliminates hallucinations.

### RAG Memory Access

Use the RAG MCP tools to access comprehensive project knowledge:

```
# Query authoritative facts (tech stack, architecture, code standards)
rag_get_context project_id="timebeam" context_type="symbolic" max_results=10 query="<your query>"

# Query lessons learned (development patterns, mistakes, best practices)
rag_get_context project_id="timebeam" context_type="episodic" max_results=5 query="<your query>"

# Query documentation (reference material, guides, specifications)
rag_get_context project_id="timebeam" context_type="semantic" max_results=10 query="<your query>"

# Full context retrieval (all memory types)
rag_get_context project_id="timebeam" context_type="all" max_results=15 query="<your query>"
```

### Common RAG Queries

**Before starting ANY work, query:**
- Tech stack: `rag_get_context project_id="timebeam" query="tech stack frameworks languages"`
- Architecture: `rag_get_context project_id="timebeam" query="DDD layers SOLID principles"`
- Code standards: `rag_get_context project_id="timebeam" query="code style standards Java Swift"`
- Build commands: `rag_get_context project_id="timebeam" query="build test lint commands"`
- Project structure: `rag_get_context project_id="timebeam" query="project structure file locations"`
- API endpoints: `rag_get_context project_id="timebeam" query="API endpoints authentication timer"`
- Testing: `rag_get_context project_id="timebeam" query="testing requirements coverage frameworks"`
- Logging: `rag_get_context project_id="timebeam" query="logging AppLogger SLF4J categories"`
- Security: `rag_get_context project_id="timebeam" query="security validation authentication storage"`

### Memory Types in RAG System

**Symbolic Memory (Authoritative Facts - 100% Trusted)**
- Technology stack: Spring Boot 3.2.0, Java 17, SwiftUI, PostgreSQL 15+
- Project structure: Backend layers (domain/application/infrastructure/presentation), iOS layers
- Code standards: NO null returns (Java), NO force unwrapping (Swift), 80% test coverage
- Build commands: Maven for backend, Xcode for frontend
- Architecture: DDD with 4 layers, SOLID principles, DRY/KISS/YAGNI
- Logging: AppLogger (iOS), SLF4J (Java), privacy controls
- Security: JWT tokens, Keychain storage, input validation, no hardcoded secrets
- Test frameworks: JUnit 5 (Java), XCTest (Swift), 80% coverage minimum

**Episodic Memory (Lessons Learned - Highly Trusted)**
- Event-based timer sync (NOT continuous polling)
- Xcode build cache issues requiring manual refresh
- Null-safety patterns in Java
- No force unwrapping in Swift
- Task management NOT implemented in MVP
- Web support NOT implemented in MVP
- JWT tokens stored in Keychain
- AppLogger for iOS logging
- 80% test coverage requirement
- Git push mandatory for completion

**Semantic Memory (Documentation - Reference Material)**
- AGENTS.md - Development workflows and tool configuration
- docs/codestyle/ - Comprehensive code style standards
- docs/architecture/ - System architecture and design decisions
- docs/features/mvp-checklist.md - Feature implementation status
- docs/event-based-sync/ - Timer synchronization system
- docs/testing/ - Testing strategies and frameworks
- docs/getting-started/ - Setup and onboarding guides
- Source code - Java services (TimerSyncService, AuthService, etc.)
- Source code - Swift models and networking (PomodoroTimer, ApiClient, AuthManager)

### Hallucination Prevention

The RAG system eliminates common LLM hallucinations:
- ❌ Wrong tech stack (e.g., React, Python)
- ❌ Wrong project structure (e.g., non-DDD folders)
- ❌ Wrong API endpoints
- ❌ Wrong method signatures
- ❌ Incorrect code standards
- ❌ Missing features (task management, web support exist)
- ❌ Wrong sync mechanism (continuous polling vs event-based)
- ❌ Wrong logging frameworks
- ❌ Wrong test frameworks
- ❌ Incorrect build commands

### Usage Pattern

**ALWAYS** start by querying RAG:
```
# Example: Starting backend feature development
rag_get_context project_id="timebeam" context_type="all" query="backend feature development workflow Spring Boot Java JUnit"
# Then proceed with the task using retrieved context
```

**ALWAYS** verify information against RAG facts before implementing.

**NEVER** rely on training data - use RAG for TimeBeam-specific context.

---

## Issue Tracking

Use **bd (beads)** for persistent issue tracking. Run `bd prime` for workflow context.

**Commands:**
- `bd ready` - Find unblocked work
- `bd create "Title" --type task --priority 2` - Create issue
- `bd update <id> --status closed` - Update status
- `bd sync` - Sync with git (run at session end)

## Build, Lint, and Test Commands

### Backend (Spring Boot/Java)
```bash
cd back-end
# Build
mvn clean compile

# Run all tests
mvn test

# Run single test class
mvn test -Dtest=TimerSyncServiceTest

# Run single test method
mvn test -Dtest=TimerSyncServiceTest#pushTimerState_ShouldCreateNewTimerState_WhenNoneExists

# Integration tests
mvn verify -Dtest="*IT"

# Code quality checks
mvn spotbugs:check pmd:check checkstyle:check

# Coverage report
mvn test jacoco:report
```

### iOS/macOS/watchOS (Swift/Xcode)
```bash
cd apple/TimeBeam
# Build
xcodebuild clean build -scheme "TimeBeam iOS" -configuration Debug

# Run all tests
xcodebuild test -scheme "TimeBeam iOS" -destination "platform=iOS Simulator,name=iPhone 15"

# Run single test class
xcodebuild test -scheme "TimeBeam iOS" -only-testing:TimeBeamTests/TimerSyncManagerUnitTests

# Run single test method
xcodebuild test -scheme "TimeBeam iOS" -only-testing:TimeBeamTests/TimerSyncManagerUnitTests/testSyncTimerState

# Lint
swiftlint --strict
```

### CI/CD Integration
- Backend: `.github/workflows/backend.yml`
- Frontend: `.github/workflows/frontend.yml`
- Testing: `.github/workflows/testing.yml`
- All workflows enforce code quality gates before merge

## Code Style Standards Reference

**For comprehensive standards, see `docs/codestyle/` directory.**

| Category | Document | Key Points |
|----------|-----------|------------|
| Architecture | docs/architecture/ | DDD layered architecture, SOLID, DRY/KISS/YAGNI |
| Java | java.md | Import rules, naming, exception handling, no null returns |
| Swift | swift.md | No force unwrapping, safe optionals, memory management |
| Logging | logging.md | AppLogger (iOS), SLF4J (Java), privacy controls |
| Security | security.md | Input validation, no hardcoded secrets, data protection |
| MCP Servers | mcp-servers.md | When to use sequential-thinking, postgres, sonarlint, etc. |
| Testing (Backend) | testing-backend.md | JUnit 5, 80% coverage, arrange/act/assert |
| Testing (Frontend) | testing-frontend.md | XCTest, UI tests, accessibility testing |
| Workflows | workflows/ | Backend/frontend features, refactoring, security updates |
| Related Docs | docs/getting-started/ | Developer onboarding and setup |
| Related Docs | docs/architecture/ | System architecture and design decisions |
| Related Docs | docs/features/ | Feature documentation and checklists |
| Related Docs | docs/implementation-guides/ | How-to guides for implementations |
| Related Docs | docs/event-based-sync/ | Timer synchronization system |
| Related Docs | docs/ci-cd/ | CI/CD documentation |
| Related Docs | docs/testing/ | Testing strategies and frameworks |
| Related Docs | docs/tools/ | Tool-specific guides |
| Related Docs | docs/project-management/ | Project tracking and reporting |
| Related Docs | docs/contributing/ | Contributor guidelines |

## Architecture Principles

**Full details: docs/codestyle/architecture.md**

### DDD Layers
1. **Domain Layer**: Business logic, entities, value objects
2. **Application Layer**: Use cases, orchestration, DTOs
3. **Infrastructure Layer**: Technical implementations (DB, APIs)
4. **Presentation Layer**: External interfaces (controllers, views)

### SOLID Principles
- **SRP**: Single Responsibility - one reason to change
- **OCP**: Open/Closed - open for extension, closed for modification
- **LSP**: Liskov Substitution - subtypes must be substitutable
- **ISP**: Interface Segregation - focused interfaces
- **DIP**: Dependency Inversion - depend on abstractions

### Code Quality
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It

## Code Style Guidelines (Key Points)

**Full details: docs/codestyle/java.md and docs/codestyle/swift.md**

### Java
- Imports: Standard → third-party → project (alphabetical)
- Naming: PascalCase classes, camelCase methods, UPPER_SNAKE_CASE constants
- Formatting: 4-space, K&R braces, 120 char max
- **Error Handling (CRITICAL)**: NEVER return null, ALWAYS throw exceptions
- Architecture: domain.model, application.service, infrastructure.persistence, presentation.controller
- Testing: JUnit 5 + Mockito, Arrange-Act-Then, AssertJ

```java
// ❌ BAD
public User findUser(String id) {
    return null;
}

// ✅ GOOD
public User findUser(String id) {
    return userRepository.findById(id)
        .orElseThrow(() -> new UserNotFoundException("User not found: " + id));
}
```

### Swift
- Imports: System frameworks first, then project (alphabetical)
- Naming: PascalCase types, camelCase variables
- Formatting: 4-space, braces same line, 120 char max
- **Error Handling (CRITICAL)**: NEVER use ! force unwrap
- Architecture: Domain/Models, Application/Services, Infrastructure/Networking, Presentation/Views
- Testing: XCTest, UnitTests/, IntegrationTests/, UITests/

```swift
// ❌ BAD
let value = optionalValue!

// ✅ GOOD
guard let value = optionalValue else {
    throw SomeError.valueMissing
}
```

**SwiftLint**: No force operations, avoid singletons, max 600 lines/file

## Testing Standards

**Full details: docs/codestyle/testing-backend.md and docs/codestyle/testing-frontend.md**

### Core Principles
1. Test Early, Test Often
2. Write Tests for All Code
3. Use Meaningful Test Names (`test[Feature][Action][ExpectedResult]`)
4. Keep Tests Focused (one responsibility)
5. Use Code Coverage Tools (80% minimum)
6. Automate Tests
7. Test with Real Data
8. Test on Multiple Environments

### Coverage Requirements
- **80% minimum** for all production code
- **100%** for critical paths (authentication, data processing)
- Regular reports in CI/CD
- Monitoring for drops below thresholds

## Logging Standards

**Full details: docs/codestyle/logging.md**

### iOS/macOS
- **ALWAYS use AppLogger** (not print, NSLog, os_log)
- **ALWAYS specify category** (auth, sync, timer, api, lifecycle, ui, general)
- **Privacy**: .public for non-sensitive, .private for emails/tokens

```swift
// ✅ Good
AppLogger.logAuthEvent("login_successful", userId: "user123")

// ❌ Bad
print("User logged in")
```

### Java Backend
- **ALWAYS use SLF4J** (not System.out.println)
- **ALWAYS use parameterized logging** (not string concatenation)
- **Log Levels**: TRACE, DEBUG, INFO, WARN, ERROR

```java
// ✅ Good
logger.info("User {} logged in from IP {}", userId, ipAddress);

// ❌ Bad
logger.info("User " + userId + " logged in from IP " + ipAddress);
```

## Security Guidelines

**Full details: docs/codestyle/security.md**

### Core Rules
- **ALWAYS validate inputs** - Never trust user input
- **NEVER hardcode credentials** - Use secure storage
- **ENCRYPT sensitive data at rest**
- **USE HTTPS for all communications**
- **MASK sensitive data in logs** - Never log passwords, tokens, PII
- **USE parameterized queries** - Prevent SQL injection

```java
// ❌ BAD: SQL injection
String query = "SELECT * FROM users WHERE id = " + userId;

// ✅ GOOD: Parameterized
String query = "SELECT * FROM users WHERE id = ?";
```

## MCP Tools Usage

**Full details: docs/codestyle/mcp-servers.md**

### When to Use Each

**sequential-thinking** 🔄 - Complex planning, architecture decisions, problem decomposition

**filesystem** 📁 - File operations, directory analysis, bulk operations

**postgres** 🐘 - Database schema, query optimization, migration planning

**sonarlint** 🔍 - Code quality, security scanning, code smells

**context7** 📚 - API documentation, framework docs, code examples

**pg-aiguide** 🗄️ - SQL optimization, database design, PostgreSQL best practices

**Usage pattern:** For most tasks, use:
```
use all mcp servers "sequential-thinking", "context7", "pg-aiguide"
```

## Development Workflows

**Full details: docs/codestyle/workflows/**

### Backend Feature
**File:** workflows/backend-feature.md (72 lines)
- 5 phases: Planning → Implementation → Testing → Review → Deployment
- DDD layers, 80% coverage, security review
- MCP usage: postgres, pg-aiguide, sonarlint, curl

### Frontend Feature
**File:** workflows/frontend-feature.md (72 lines)
- 5 phases: Planning → Implementation → Testing → Review → Deployment
- DDD layers, accessibility support, platform compatibility
- MCP usage: playwright, filesystem, memory

### Code Refactoring
**File:** workflows/refactoring.md (70 lines)
- 5 phases: Analysis → Planning → Implementation → Testing → Review
- SOLID principles, incremental approach
- MCP usage: sonarlint, filesystem

### Security Update
**File:** workflows/security-update.md (71 lines)
- Critical priority, 5 phases
- Vulnerability analysis (vuldb.com), emergency procedures
- MCP usage: sonarlint, context7 (vulnerability research)

### General Task
**File:** workflows/task.md (74 lines)
- Universal workflow for any development task
- 5 phases: Analysis → Planning → Execution → Validation → Completion
- Appropriate MCP servers per task type

## Error Fixing Workflow

**For runtime/logic errors (not compilation):**

1. **Check logs first:**
   - See [Device Log Access Guide](#device-log-access-guide) below for detailed instructions
   - Quick reference:
     - Backend: `back-end/logs/timebeam.log`
     - macOS: `~/Documents/TimeBeamLogs/timebeam_macos.log`
     - iOS: Use Xcode Devices window (see guide)

2. **Analyze root cause:**
   - Review error context and stack traces
   - Check recent changes
   - Identify affected components

3. **Implement fix:**
   - Follow security guidelines
   - Apply architecture principles
   - Write tests for fix

4. **Verify solution:**
   - Run relevant test commands
   - Check logs for resolution
   - Validate no regressions

## Session Completion (MANDATORY)

**Before ending work:**

1. **File Beads issues for remaining work**

2. **Run quality gates:**
   ```bash
   # Backend
   cd back-end && mvn test && mvn spotbugs:check pmd:check

   # Frontend
   cd apple/TimeBeam && swiftlint --strict
   ```

3. **Update Beads issue statuses**

4. **PUSH TO REMOTE** (MANDATORY - work NOT complete until succeeds):
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```

5. **Clean up**
   - Clear stashes
   - Prune remote branches

**CRITICAL:** Work is NOT complete until `git push` succeeds.

## Device Log Access Guide

### macOS
**File Location:** `~/Documents/TimeBeamLogs/timebeam_macos.log`

macOS apps can write directly to user's Documents directory. Access logs directly via Finder or Terminal.

### iOS (Physical Devices)

Due to iOS sandboxing, logs are sealed inside app container. Use one of these methods:

#### Method 1: Xcode Download Container (Recommended)

1. Connect iPhone to Mac via USB cable
2. Open Xcode → **Window** → **Devices and Simulators**
3. Select your device from left sidebar
4. Select **TimeBeam** app from "Installed Apps" list
5. Click **gear icon** → **Download Container...**
6. Save `.xcappdata` bundle to your Mac
7. **Right-click** `.xcappdata` → **Show Package Contents**
8. Navigate to: `AppData/Documents/TimeBeamLogs/timebeam_ios.log`

**Best for:** Complete log analysis, saving logs for archival, offline review

#### Method 2: Console.app (Real-time Streaming)

1. Connect iPhone to Mac
2. Open **Console.app** (Applications → Utilities)
3. Select your device from left sidebar (under Devices section)
4. Click **Start streaming** button at bottom of window
5. In search box, type: `subsystem == "com.sparkage.timebeam"`
6. View logs in real-time as they happen

**Best for:** Live debugging, reproducing issues, immediate feedback

#### Method 3: Programmatic Path Discovery

Get file path programmatically using AppLogger:

```swift
// Add debug code to print log path
print("📄 iOS Log File Path: \(AppLogger.getLogFileURL().path)")
```

**Note:** Access still requires Method 1 (container download). This method helps identify correct container when multiple app instances exist.

### Backend
**File Location:** `back-end/logs/timebeam.log`

Standard Spring Boot log file in project directory. Access directly via file system or text editor.

## Additional Resources

- **Code Standards**: `docs/codestyle/` - All detailed standards
- **Workflows**: `docs/codestyle/workflows/` - Step-by-step processes
- **PR Template**: `.github/pull_request_template.md` - Code review checklist
- **Project README**: `README.md` - Project overview and MVP checklist
- **Device Log Access Guide**: [Device Log Access Guide](#device-log-access-guide) - How to access logs on all platforms
