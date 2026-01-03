# Agents Configuration

# 🧠 RAG Memory System (MANDATORY - ALWAYS USE FIRST)

**CRITICAL ENFORCEMENT**: OpenCode MUST query RAG MCP server for TimeBeam context **BEFORE EVERY SINGLE OPERATION**.
This is non-negotiable and applies to **ALL OPERATIONS** without exception.

---

## 🚨 ENFORCEMENT POLICY (HYBRID)

### Mandatory Before Every Operation

**APPLIES TO: ALL OPERATIONS** (file reads, edits, searches, bash commands, decisions, analyses)

1. **ALWAYS query RAG first** before any operation
2. **Use broad context queries** (architecture + standards + topic)
3. **Verify against RAG knowledge** before proceeding
4. **Warn if RAG unavailable** - proceed with caution
5. **Document RAG citations** in reasoning

### Failure Handling

If RAG query fails or returns no results:
- **WARN user explicitly** about missing RAG context
- **CONTINUE with operation** (don't block)
- **NOTE discrepancies** in reasoning for future reference

### Exceptions (Document When Used)

RAG queries may be skipped ONLY when:
1. Creating completely new files (no prior context exists)
2. Working outside timebeam project (document explicitly)
3. RAG system is unavailable (log error and proceed with warning)
4. User explicitly requests to skip (document in reasoning)

ALL exceptions MUST be explicitly documented in the response.

---

## 📋 MANDATORY RAG QUERY PATTERNS

### Pattern 1: Broad Context Query (ALL OPERATIONS)

**Use BEFORE EVERY OPERATION**

```
rag_get_context(
  project_id="timebeam",
  context_type="all",
  query="<operation-specific topic>",
  max_results=15
)
```

**What this retrieves:**
- Symbolic memory: Tech stack, architecture, code standards
- Episodic memory: Development patterns, lessons learned
- Semantic memory: Documentation, code examples, implementations

**Required topics to query:**
- For ANY operation: "architecture code standards"
- For file operations: "architecture code standards <filename>"
- For decisions: "architecture code standards <decision topic>"
- For searches: "architecture code standards <search terms>"

### Pattern 2: File-Specific Search (FILE OPERATIONS)

**Use BEFORE READING OR EDITING FILES**

```
rag_search(
  project_id="timebeam",
  query="<filename or component name>",
  memory_type="semantic",
  top_k=10
)
```

**What this retrieves:**
- Files matching query
- Related code implementations
- Documentation about file/component

### Pattern 3: Code Style Verification (CODE EDITS)

**Use BEFORE MAKING CODE CHANGES**

```
rag_get_context(
  project_id="timebeam",
  query="code style standards Java Swift",
  context_type="symbolic",
  max_results=10
)
```

**What this retrieves:**
- Code style standards from symbolic memory
- Java and Swift formatting rules
- Import patterns and naming conventions

### Pattern 4: API Endpoint Search (API USAGE)

**Use BEFORE USING BACKEND APIs**

```
rag_search(
  project_id="timebeam",
  query="API endpoints authentication timer <specific endpoint>",
  memory_type="semantic",
  top_k=15
)
```

**What this retrieves:**
- API endpoint definitions
- Authentication requirements
- Request/response formats

---

## 🧠 RAG MEMORY TYPES AND USAGE

### Symbolic Memory (100% Trusted - Authoritative Facts)

**When to Use:**
- Verifying tech stack information
- Understanding architecture patterns
- Checking code standards and requirements
- Learning build/test commands
- Understanding security requirements

**Contains:**
- Technology stack (Spring Boot 3.2.0, Java 17, SwiftUI, etc.)
- Architecture (DDD layers, SOLID principles)
- Code standards (no null returns, no force unwrapping, 80% coverage)
- Build commands (Maven, Xcode, SwiftLint)
- Security requirements (JWT tokens, Keychain storage)

**Query Template:**
```
rag_get_context(
  project_id="timebeam",
  context_type="symbolic",
  query="<authoritative fact needed>",
  max_results=10
)
```

### Episodic Memory (Highly Trusted - Lessons Learned)

**When to Use:**
- Understanding development patterns
- Learning from previous issues/solutions
- Applying migration/refactoring experiences
- Avoiding common mistakes

**Contains:**
- Development patterns and best practices
- Common issues and their solutions
- Migration and refactoring experiences
- Bug fixes and their root causes

**Query Template:**
```
rag_get_context(
  project_id="timebeam",
  context_type="episodic",
  query="<problem or pattern>",
  max_results=10
)
```

### Semantic Memory (Reference Material - Documentation)

**When to Use:**
- Finding specific files or components
- Searching for code examples
- Locating documentation
- Understanding existing implementations

**Contains:**
- Documentation (AGENTS.md, docs/codestyle/, etc.)
- Source code (Swift, Java)
- API definitions and examples
- Configuration files

**Query Template:**
```
rag_search(
  project_id="timebeam",
  context_type="semantic",
  query="<file, topic, or component>",
  top_k=15
)
```

---

## ✅ ENFORCEMENT CHECKLIST (.opencode/rag-checklist.md)

**CHECKLIST LOCATION**: `.opencode/rag-checklist.md`

**MANDATORY**: Complete checklist for EVERY operation.

**Pre-Operation Checklist** (ALL OPERATIONS):
- [ ] Query RAG for broad context (architecture + standards + topic)
- [ ] Review code standards from RAG results
- [ ] Identify applicable patterns from RAG
- [ ] Document RAG sources used in reasoning

**Pre-Read Checklist** (FILE OPERATIONS):
- [ ] Query RAG for file-specific context
- [ ] Review existing implementations from RAG
- [ ] Understand file purpose from documentation
- [ ] Identify related files/components

**Pre-Edit Checklist** (FILE EDITS):
- [ ] Query RAG for file-specific context
- [ ] Review existing implementations in RAG
- [ ] Match coding style from RAG standards
- [ ] Verify patterns align with project standards

**Pre-Decision Checklist** (DECISIONS):
- [ ] Query RAG for decision-related context
- [ ] Verify against authoritative facts (symbolic memory)
- [ ] Check episodic memory for relevant lessons
- [ ] Document reasoning with RAG citations

**Post-Operation Checklist** (ALL OPERATIONS):
- [ ] Validate results against RAG code standards
- [ ] Verify alignment with RAG knowledge
- [ ] Note any discrepancies
- [ ] Add lessons learned to episodic memory (if applicable)

---

## 🧠 RAG MEMORY TYPES IN RAG SYSTEM

### Symbolic Memory (100% Trusted - Authoritative Facts)

**When to Use:**
- Verifying tech stack information
- Understanding architecture patterns
- Checking code standards and requirements
- Learning build/test commands
- Understanding security requirements

**Contains:**
- Technology stack (Spring Boot 3.2.0, Java 17, SwiftUI, PostgreSQL 15+)
- Architecture (DDD layers, SOLID principles)
- Code standards (no null returns, no force unwrapping, 80% test coverage)
- Build commands (Maven for backend, Xcode for frontend)
- Security requirements (JWT tokens, Keychain storage)

### Episodic Memory (Highly Trusted - Lessons Learned)

**When to Use:**
- Understanding development patterns
- Learning from previous issues/solutions
- Applying migration/refactoring experiences
- Avoiding common mistakes

**Contains:**
- Development patterns and best practices
- Common issues and their solutions
- Migration and refactoring experiences
- Bug fixes and their root causes

### Semantic Memory (Reference Material - Documentation)

**When to Use:**
- Finding specific files or components
- Searching for code examples
- Locating documentation
- Understanding existing implementations

**Contains:**
- Documentation (AGENTS.md, docs/codestyle/, etc.)
- Source code (Swift, Java)
- API definitions and examples
- Configuration files

---

## ❌ HALLUCINATION PREVENTION

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

---

## 📝 USAGE PATTERN

**ALWAYS** start by querying RAG:
```
# Example: Starting backend feature development
rag_get_context(
  project_id="timebeam",
  context_type="all",
  query="backend feature development workflow Spring Boot Java JUnit"
  max_results=15
)

# Then proceed with the task using retrieved context
```

**ALWAYS** verify information against RAG facts before implementing.

**NEVER** rely on training data - use RAG for TimeBeam-specific context.

---

## 🔍 COMMON RAG QUERIES

**Before starting ANY work, query:**

**For architecture decisions:**
```
rag_get_context(
  project_id="timebeam",
  query="DDD layers SOLID principles architecture",
  context_type="symbolic",
  max_results=10
)
```

**For Java code:**
```
rag_get_context(
  project_id="timebeam",
  query="Java code style no null returns SLF4J",
  context_type="symbolic",
  max_results=10
)
```

**For Swift code:**
```
rag_get_context(
  project_id="timebeam",
  query="Swift code style no force unwrap AppLogger",
  context_type="symbolic",
  max_results=10
)
```

**For testing:**
```
rag_get_context(
  project_id="timebeam",
  query="testing requirements JUnit5 XCTest 80% coverage",
  context_type="symbolic",
  max_results=10
)
```

**For API usage:**
```
rag_search(
  project_id="timebeam",
  query="API endpoints authentication <service name>",
  memory_type="semantic",
  top_k=15
)
```

**For file searches:**
```
rag_search(
  project_id="timebeam",
  query="<filename>",
  memory_type="semantic",
  top_k=10
)
```

---

## 🔧 RAG TOOLS REFERENCE

### Core Tools

**rag_get_context**
- Purpose: Retrieve comprehensive project context
- Usage: Get authoritative facts, episodic lessons, semantic docs
- Parameters: project_id, context_type (all/symbolic/episodic/semantic), query, max_results

**rag_search**
- Purpose: Search across all memory types
- Usage: Find specific code patterns, files, or topics
- Parameters: project_id, query, memory_type (all/symbolic/episodic/semantic), top_k

**rag_add_fact**
- Purpose: Add authoritative fact to symbolic memory
- Usage: Record tech stack, architecture decisions, constraints
- Parameters: project_id, fact_key, fact_value, confidence, category

**rag_add_episode**
- Purpose: Add lesson learned to episodic memory
- Usage: Record development patterns, mistakes, best practices
- Parameters: project_id, title, content, lesson_type, quality

**rag_list_sources**
- Purpose: List all ingested sources
- Usage: Verify what's available in knowledge base
- Parameters: project_id, source_type

**rag_ingest_file**
- Purpose: Add new file to semantic memory
- Usage: Ingest documentation, code changes after completion
- Parameters: project_id, file_path, filename, source_type, metadata

### When to Use Each Tool

**rag_get_context** - When:
- Starting any new task
- Making architectural decisions
- Understanding project structure
- Learning tech stack or standards

**rag_search** - When:
- Finding specific files or components
- Searching for code patterns
- Looking for API implementations

**rag_add_fact** - When:
- Recording new tech stack decisions
- Documenting architecture patterns
- Adding project constraints

**rag_add_episode** - When:
- Completing a feature or fix
- Learning a new pattern
- Encountering a bug or issue
- Discovering a best practice

**rag_list_sources** - When:
- Verifying RAG ingestion status
- Checking what's available
- Debugging missing information

**rag_ingest_file** - When:
- Adding new documentation
- Ingesting completed code changes
- Updating project context after major changes

---

## 🔍 QUICK RAG QUERY TEMPLATES

### For All Operations (MANDATORY)
```
# Always start with broad context query
rag_get_context(
  project_id="timebeam",
  context_type="all",
  query="architecture code standards <operation-specific topic>",
  max_results=15
)
```

### For File Operations
```
rag_search(
  project_id="timebeam",
  query="<filename or component name>",
  memory_type="semantic",
  top_k=10
)
```

### For Code Style Verification
```
rag_get_context(
  project_id="timebeam",
  query="code style standards Java Swift",
  context_type="symbolic",
  max_results=10
)
```

### For API Usage
```
rag_search(
  project_id="timebeam",
  query="API endpoints authentication timer <specific endpoint>",
  memory_type="semantic",
  top_k=15
)
```

### For Architecture Decisions
```
rag_get_context(
  project_id="timebeam",
  query="DDD layers SOLID principles architecture",
  context_type="symbolic",
  max_results=10
)
```

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

### Phase 0: RAG Context Query (MANDATORY)

**Before ANY work:**
1. Query RAG for broad context:
   ```
   rag_get_context(
     project_id="timebeam",
     context_type="all",
     query="architecture code standards backend feature",
     max_results=15
   )
   ```

2. Query RAG for specific topic:
   ```
   rag_search(
     project_id="timebeam",
     query="<feature name> API endpoints services",
     memory_type="semantic",
     top_k=10
   )
   ```

3. **Document RAG citations** in reasoning

**After RAG queries:**
- Review tech stack from symbolic memory
- Understand architecture patterns
- Review code standards (no null returns, 80% coverage)
- Check for existing similar implementations

- 5 phases: Phase 0 (RAG) → Phase 1 (Planning) → Phase 2 (Implementation) → Phase 3 (Testing) → Phase 4 (Review) → Phase 5 (Deployment)
- DDD layers, 80% coverage, security review
- MCP usage: postgres, pg-aiguide, sonarlint, curl

### Frontend Feature
**File:** workflows/frontend-feature.md (72 lines)

### Phase 0: RAG Context Query (MANDATORY)

**Before ANY work:**
1. Query RAG for broad context:
   ```markdown
   rag_get_context(
     project_id="timebeam",
     context_type="all",
     query="architecture code standards SwiftUI frontend feature",
     max_results=15
   )
   ```

2. Query RAG for specific topic:
   ```markdown
   rag_search(
     project_id="timebeam",
     query="<feature name> SwiftUI view component",
     memory_type="semantic",
     top_k=10
   )
   ```

3. **Document RAG citations** in reasoning

**After RAG queries:**
- Review Swift code standards (no force unwrapping, 80% coverage)
- Understand SwiftUI patterns from RAG
- Review DDD presentation layer structure
- Check for existing similar UI components

- 5 phases: Planning → Implementation → Testing → Review → Deployment
- DDD layers, accessibility support, platform compatibility
- MCP usage: playwright, filesystem, memory

### Code Refactoring
**File:** workflows/refactoring.md (70 lines)

### Phase 0: RAG Context Query (MANDATORY)

**Before ANY refactoring:**
1. Query RAG for broad context:
   ```markdown
   rag_get_context(
     project_id="timebeam",
     context_type="all",
     query="architecture code standards SOLID refactoring",
     max_results=15
   )
   ```

2. Query RAG for specific code:
   ```markdown
   rag_search(
     project_id="timebeam",
     query="<file or component>",
     memory_type="semantic",
     top_k=10
   )
   ```

3. **Document RAG citations** in reasoning

**After RAG queries:**
- Review SOLID principles from RAG symbolic memory
- Understand code architecture patterns
- Review code standards from RAG
- Check for existing similar code patterns

- 5 phases: Analysis → Planning → Implementation → Testing → Review
- SOLID principles, incremental approach
- MCP usage: sonarlint, filesystem

### Security Update
**File:** workflows/security-update.md (71 lines)
- Critical priority, 5 phases
- Vulnerability analysis (vuldb.com), emergency procedures
- MCP usage: sonarlint, context7 (vulnerability research)

### Phase 0: RAG Context Query (MANDATORY)

**Before ANY security work:**
1. Query RAG for broad context:
   ```markdown
   rag_get_context(
     project_id="timebeam",
     context_type="all",
     query="security validation authentication storage",
     max_results=15
   )
   ```

2. Query RAG for specific topic:
   ```markdown
   rag_search(
     project_id="timebeam",
     query="<security issue or vulnerability>",
     memory_type="semantic",
     top_k=10
   )
   ```

3. **Document RAG citations** in reasoning

**After RAG queries:**
- Review security requirements from RAG symbolic memory
- Check for known vulnerabilities (from episodic memory)
- Review security best practices (from RAG)

### General Task
**File:** workflows/task.md (74 lines)

### Phase 0: RAG Context Query (MANDATORY)

**Before ANY work:**
1. Query RAG for broad context:
   ```markdown
   rag_get_context(
     project_id="timebeam",
     context_type="all",
     query="architecture code standards <task type>",
     max_results=15
   )
   ```

2. **Document RAG citations** in reasoning

**After RAG queries:**
- Review tech stack from RAG
- Understand architecture patterns
- Review code standards from RAG
- Check for existing similar implementations

- 5 phases: Analysis → Planning → Execution → Validation → Completion
- Appropriate MCP servers per task type

## Error Fixing Workflow

**For runtime/logic errors (not compilation):**

### Step 0: RAG Context Query (MANDATORY)

**Before ANY error fixing:**
1. Query RAG for broad context:
   ```
   rag_get_context(
     project_id="timebeam",
     context_type="all",
     query="logging debugging error handling <file>",
     max_results=15
   )
   ```

2. Query RAG for specific file/component:
   ```
   rag_search(
     project_id="timebeam",
     query="<file or component>",
     memory_type="semantic",
     top_k=10
   )
   ```

3. Query RAG for error type:
   ```
   rag_search(
     project_id="timebeam",
     query="<error type or exception>",
     memory_type="episodic",
     top_k=10
   )
   ```

4. **Document RAG citations** in reasoning

**After RAG queries:**
- Review logging patterns from RAG (AppLogger, SLF4J)
- Check for similar error fixes in episodic memory
- Understand error context from RAG
- Identify relevant code patterns

**RAG Enforcement Check:** [ ] Completed

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

---

## 🛡️ SRP Prevention Commands

### OpenCLI Integration for SRP Enforcement

The codebase now includes CLI commands for quick SRP validation, integrated with the OpenCLI workflow.

### 🔔 Pre-commit Hook (Automatic)

**Location**: `.git/hooks/pre-commit`

Automatically checks all staged Swift files before each commit. No manual intervention needed.

**When it triggers**: On every `git commit`
**What it does**: Blocks commits containing SRP violations
**Output**: Clear error messages with line numbers and type definitions

### 🔍 Manual Validation Commands

Use these commands for manual checks, CI/CD integration, or pre-commit verification.

#### Command: `/check-srp [path]`

Check Swift files for SRP compliance.

**Usage**:
```bash
# Check all Swift files
/check-srp

# Check specific directory
/check-srp apple/TimeBeam/TimeBeam/Presentation/Views

# Check only staged files (pre-commit simulation)
/check-srp --staged
```

**Exit codes**:
- `0` = All files comply ✓
- `1` = Violations found ✗

**Example output**:
```
🔍 Validating Single Responsibility Principle in Swift files...

❌ SRP VIOLATION: AnalyticsService.swift contains 2 type definitions
     - class AnalyticsManager: ObservableObject
     - enum AnalyticsService

⚠️  Found 1 SRP violation(s)

💡 To fix:
   1. Split files with multiple types into separate files
   2. Each file should contain only ONE class, struct, enum, or protocol

❌ FAILED
```

#### Command: `/split-file <file.swift>`

**Interactive tool to split multi-type files automatically**

Use when pre-commit hook blocks a commit due to SRP violations.

**What it does**:
- Analyzes the file for multiple type definitions
- Creates separate files for each type
- Preserves original file as backup
- Updates imports if needed

**Usage**:
```bash
# Interactive mode - guides you through the split
/split-file apple/TimeBeam/TimeBeam/Application/Services/AnalyticsService.swift

# Auto-split mode - uses default naming
/split-file --auto apple/TimeBeam/TimeBeam/Presentation/Views/Task/TaskViews.swift
```

**Example interaction**:
```
Found 3 types in TaskViews.swift:
  1. struct TaskQuickActionsSheet (lines 1-72)
  2. struct QuickActionButton (lines 74-110)
  3. struct DeletedTasksView (lines 112-150)

Suggested file names:
  - TaskQuickActionsSheet.swift
  - QuickActionButton.swift
  - DeletedTasksView.swift

Proceed with split? (y/n): y

✓ Created: TaskQuickActionsSheet.swift
✓ Created: QuickActionButton.swift
✓ Created: DeletedTasksView.swift
✓ Moved original to: TaskViews.swift.bak
```

### 🔧 CI/CD Integration Commands

#### Command: `/validate-srp-ci`

**For CI/CD pipeline integration**

Run SRP validation with CI-friendly output (no colors, machine-readable).

**Usage in CI/CD**:
```yaml
# .github/workflows/srp-validation.yml
- name: Validate SRP compliance
  run: /validate-srp-ci
```

**Output format**:
```
CHECKED: 157 files
VIOLATIONS: 0
RESULT: PASSED
```

### 📚 Documentation Commands

#### Command: `/srp-docs`

**Open SRP prevention documentation**

Quick access to detailed SRP guidelines and troubleshooting.

**Usage**:
```bash
/srp-docs
# Opens: docs/codestyle/srp-prevention.md
```

### 🎯 Quick Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/check-srp` | Manual validation | Before committing, CI/CD pre-check |
| `/split-file` | Auto-split multi-type files | When pre-commit hook blocks commit |
| `/validate-srp-ci` | CI/CD validation | In automated pipelines |
| `/srp-docs` | Open documentation | When you need detailed guidance |

### 🚨 When Prevention Blocks You

If you get blocked by SRP enforcement:

1. **Don't use `--no-verify`** unless absolutely necessary
2. **Use `/split-file`** to automatically fix the issue
3. **Review `/srp-docs`** for guidelines and examples
4. **Ask for help** if you're unsure how to split properly

### ✅ Best Practices

1. **Before starting work**: Run `/check-srp` to ensure clean state
2. **When creating new files**: Always start with ONE type per file
3. **When tempted to add second type**: Create new file instead
4. **Before committing**: Let pre-commit hook validate automatically
5. **If blocked**: Use `/split-file` to fix, don't bypass

### 🔍 Under the Hood

All commands use the same validation logic:
- Regex pattern: `^\s*(public\s+|internal\s+|private\s+)?(class|struct|enum|protocol)\s+`
- Counts type definitions at file scope
- Excludes test files and generated files
- Returns exit code 1 for violations, 0 for compliance

### 📊 Effectiveness

**Multiple layers of protection**:
1. **IDE**: SwiftLint real-time warnings
2. **Pre-commit**: Automatic blocking on commit
3. **Manual**: `/check-srp` for self-validation
4. **Auto-fix**: `/split-file` to resolve violations
5. **CI/CD**: Pipeline validation
6. **Documentation**: `/srp-docs` for guidance

**Result**: SRP violations caught at multiple stages before reaching main branch

### 🔧 Customization

**Adding custom exclusions**:
Add patterns to `.git/hooks/pre-commit` and `validate-srp.sh`:
```bash
# Skip these patterns
if [[ $file == *"Generated/"* ]] || \
   [[ $file == *"Legacy/"* ]]; then
    continue
fi
```

### 📞 Support

For issues with SRP prevention commands:
- Check: `docs/codestyle/srp-prevention.md`
- Create issue: Tag with `srp-enforcement`
- CLI help: `/srp-help`

