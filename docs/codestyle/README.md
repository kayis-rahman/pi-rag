# TimeBeam Code Style & Standards

Centralized location for all code style guidelines, testing standards, and development workflows.
These standards apply to all developers and AI assistants working on TimeBeam.

## Document Guide

### Architecture (architecture.md - 165 lines)
- Domain-Driven Design (DDD) layered architecture
- SOLID principles (SRP, OCP, LSP, ISP, DIP)
- DRY, KISS, YAGNI principles
- Code quality standards and metrics
- When and how to apply each principle

### Java Standards (java.md - 96 lines)
- Java-specific DDD folder structure
- Package organization by layer
- Exception handling patterns (no null returns)
- Import organization rules
- Service layer best practices
- Controller guidelines
- Input validation with Bean Validation
- Code examples (good/bad patterns)

### Swift Standards (swift.md - 98 lines)
- Swift/SwiftUI DDD structure
- iOS/macOS/watchOS folder organization
- Force unwrapping prohibitions (SwiftLint rules)
- Logging security rules
- Memory management guidelines
- SwiftUI best practices
- Accessibility support requirements
- Code examples

### Logging Standards (logging.md - 286 lines)

#### iOS/macOS (Apple Unified Logging)
- AppLogger framework requirements
- Log categories: auth, sync, timer, api, lifecycle, ui, general
- Log levels: DEBUG, INFO, WARNING, ERROR, FAULT
- Privacy controls: .public vs .private
- Structured logging patterns
- Best practices with examples
- Performance guidelines

#### Java Backend (SLF4J)
- Logger declaration patterns
- Log levels: TRACE, DEBUG, INFO, WARN, ERROR
- Parameterized logging (avoid string concatenation)
- Exception logging
- Security considerations (mask sensitive data)
- MDC for request tracing
- Configuration examples (logback-spring.xml)
- Best practices

### Security Standards (security.md - 49 lines)
- Input validation requirements
- Authentication & authorization rules
- Data protection guidelines
- Dependency security practices
- Code examples: SQL injection vulnerabilities vs parameterized queries
- Logging sensitive data (bad) vs masked logging (good)

### MCP Servers (mcp-servers.md - 185 lines)
Comprehensive guide to all available MCP servers:

**When to use each server:**
- sequential-thinking: Complex multi-step planning, architecture decisions, problem decomposition
- filesystem: File operations, directory analysis, bulk file operations
- playwright: Web UI testing, browser automation, end-to-end testing
- memory: Context management, conversation history, long-running sessions
- postgres: Database schema analysis, query optimization, migration planning
- curl: HTTP operations, API testing, network debugging
- sonarlint: Code quality analysis, security scanning, code smell detection
- pg-aiguide: Complex SQL optimization, database design, PostgreSQL best practices

**Usage patterns:**
- Explicit server mentions for complex tasks
- Multi-server operations guidance
- Best practices and emergency overrides

### Testing - Backend (testing-backend.md - 254 lines)

**8 Core Testing Principles:**
1. Test Early, Test Often
2. Write Tests for All Code
3. Use Meaningful Test Names
4. Keep Tests Focused and Straightforward
5. Use Code Coverage Tools (80% minimum)
6. Automate Tests
7. Test with Real Data
8. Test on Multiple Environments

**Test Implementation:**
- Test structure guidelines (arrange/act/assert)
- Test organization by type (unit/integration/e2e)
- Code coverage requirements
- CI/CD integration examples
- Unit testing with JUnit 5
- Integration testing patterns
- Performance testing approaches
- Maintenance best practices

### Testing - Frontend (testing-frontend.md - 247 lines)

**8 Core Testing Principles:** (same as backend)

**Test Implementation:**
- Test structure guidelines for UI tests
- Test organization by platform (iOS/macOS/watchOS)
- Platform-specific testing requirements
- UI testing with XCTest
- Unit testing patterns for business logic
- Performance testing metrics
- Accessibility testing
- CI/CD integration
- Maintenance practices

### Workflows (workflows/ directory)

#### Backend Feature Development (backend-feature.md - 72 lines)
5-phase workflow for Java features:
1. **Planning Phase** - Requirements, API design, database schema
2. **Implementation Phase** - DDD layers (Domain → Application → Infrastructure → Presentation)
3. **Testing Phase** - Unit tests (80% coverage), integration tests, security tests
4. **Review Phase** - Code quality checks, security review, peer review
5. **Deployment Phase** - Migration, gradual rollout, validation

**Rules:** SOLID principles, exception handling, input validation, comprehensive logging
**MCP Server Usage:** postgres, pg-aiguide, sonarlint, curl

**Checkpoints:** Feature requirements, 80%+ coverage, integration tests, security review, code review

#### Frontend Feature Development (frontend-feature.md - 72 lines)
5-phase workflow for Swift features:
1. **Planning Phase** - UI/UX review, component architecture, state management
2. **Implementation Phase** - DDD layers, accessibility support, SwiftUI views
3. **Testing Phase** - Unit tests, UI tests, accessibility testing
4. **Review Phase** - SwiftLint checks, UI/UX review, platform compatibility
5. **Deployment Phase** - TestFlight, App Store submission, user acceptance

**Rules:** No force unwrapping, proper error handling, secure logging, SwiftUI best practices
**MCP Server Usage:** playwright, filesystem, memory

**Checkpoints:** UI components, business logic, unit tests, UI tests, accessibility

#### Code Refactoring (refactoring.md - 70 lines)
5-phase workflow for code quality improvements:
1. **Analysis Phase** - Code quality assessment, technical debt identification
2. **Planning Phase** - Refactoring strategy, incremental approach, test coverage
3. **Implementation Phase** - SOLID principles, DRY/KISS/YAGNI, simplified logic
4. **Testing Phase** - Regression testing, performance validation, compatibility testing
5. **Review Phase** - Architecture review, performance impact, stakeholder approval

**Rules:** Incremental changes, backward compatibility, test-driven refactoring
**MCP Server Usage:** sonarlint, filesystem

**Checkpoints:** Code quality assessment, refactoring plan, 80%+ coverage, incremental changes, performance benchmarks

#### Security Update (security-update.md - 71 lines)
Critical priority workflow (5 phases):
1. **Assessment Phase** - Vulnerability analysis (vuldb.com), impact assessment, CVSS scoring
2. **Planning Phase** - Security fix strategy, communication plan, rollback planning
3. **Implementation Phase** - Apply fixes, update dependencies, security configurations
4. **Testing Phase** - Security regression testing, penetration testing, performance impact
5. **Deployment Phase** - Emergency procedures, stakeholder communication, monitoring

**Rules:** Security takes precedence, minimal changes, comprehensive testing, emergency communication
**MCP Server Usage:** sonarlint, context7 (for vulnerability research)

**Checkpoints:** Vulnerability confirmed, fix strategy approved, security testing completed, rollback plan ready, communication sent

#### General Development Task (task.md - 74 lines)
Universal workflow for any development task:
1. **Analysis Phase** - Read files, analyze requirements, check rules, determine approach
2. **Planning Phase** - Break down task, create todo list, identify tools, consider DDD
3. **Execution Phase** - Execute iteratively, apply clean code rules, maintain quality
4. **Validation Phase** - Test thoroughly, ensure adherence, validate criteria
5. **Completion Phase** - Update documentation, cleanup, confirm completion

**Rules:** Follow pre-prompt rules, use tools efficiently, maintain clear communication, test all modifications
**Checkpoints:** Requirements understood, appropriate mode selected, plan created, implementation completed, validation passed

## How to Use These Standards

### For New Development
1. Read relevant language standards (java.md or swift.md)
2. Follow architecture.md for DDD compliance
3. Use appropriate workflow (backend-feature or frontend-feature)
4. Apply testing standards during development
5. Follow logging.md for production-ready logging

### For Bug Fixes
1. Review security.md if security-related
2. Follow refactoring workflow if extensive changes needed
3. Apply testing standards (testing-backend or testing-frontend)
4. Update logging if behavior changes

### For Code Reviews
1. Check architecture compliance (DDD + SOLID)
2. Verify language-specific standards (java.md/swift.md)
3. Review test coverage and quality
4. Ensure security guidelines followed
5. Validate logging standards applied

### For AI Assistants
All AI assistants should:
1. Start with AGENTS.md for quick reference
2. Reference detailed standards in docs/codestyle/
3. Follow workflow checklists
4. Use MCP servers as guided in mcp-servers.md
5. Apply all security and logging rules

## Quick Reference

| Task | Document | Lines | Key Content |
|------|----------|--------|-------------|
| Architecture | architecture.md | 165 | DDD, SOLID, DRY/KISS/YAGNI |
| Java Code | java.md | 96 | Import rules, naming, error handling |
| Swift Code | swift.md | 98 | Force unwrap rules, SwiftUI, memory |
| Logging | logging.md | 286 | AppLogger, SLF4J, privacy controls |
| Security | security.md | 49 | Input validation, secrets, auth |
| MCP Servers | mcp-servers.md | 185 | When to use each server |
| Backend Tests | testing-backend.md | 254 | JUnit 5, coverage, patterns |
| Frontend Tests | testing-frontend.md | 247 | XCTest, UI tests, accessibility |
| Backend Features | workflows/backend-feature.md | 72 | DDD, 5-phase workflow, MCP usage |
| Frontend Features | workflows/frontend-feature.md | 72 | DDD, 5-phase workflow, MCP usage |
| Refactoring | workflows/refactoring.md | 70 | SOLID, incremental, MCP usage |
| Security Updates | workflows/security-update.md | 71 | Vulnerability, emergency, MCP usage |
| General Tasks | workflows/task.md | 74 | Universal workflow, all task types |

## Related Documentation

- **AGENTS.md** (root): Agent-specific commands and workflows
- **README.md** (root): Project overview and MVP checklist
- **.github/pull_request_template.md**: PR checklist with code quality requirements

## Maintenance

These standards should be updated when:
- New technologies or frameworks are adopted
- Security vulnerabilities are discovered
- Testing patterns evolve
- MCP servers are added/removed
- Best practices change in the industry

For questions or clarifications, refer to the specific document or consult with the development team.
