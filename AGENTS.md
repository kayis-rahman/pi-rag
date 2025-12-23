# Agents Configuration

## Issue Tracking

This project uses **bd (beads)** for issue tracking.
Run `bd prime` for workflow context, or install hooks (`bd hooks install`) for auto-injection.

**Quick reference:**
- `bd ready` - Find unblocked work
- `bd create "Title" --type task --priority 2` - Create issue
- `bd close <id>` - Complete work
- `bd sync` - Sync with git (run at session end)

For full workflow details: `bd prime`

## General Instructions

Always use available MCP tools for every task:

- Use `sequential-thinking` for all tasks requiring planning, analysis, or step-by-step reasoning
- Use `memory-bank` for all tasks to maintain context and remember previous decisions
- Use `sonarlint` for any code modification or quality analysis
- Use `postgres` and `pg-aiguide` for any database-related thinking or modifications
- Use `perplexity_search` for web searches and current information
- Use `perplexity_ask` for quick questions with web context
- Use `perplexity_research` for deep research and analysis
- Use `perplexity_reason` for reasoning and problem-solving
- Use `filesystem` for file operations
- Use `context7` for API documentation search
- Use `grep-vercel` for GitHub code search

### MCP Server Prepending Requirement
**For every user prompt to opencode, prepend the following:**
```
use all mcp servers "sequential-thinking", "context7", "pg-aiguide"
```

This applies to ALL prompts to ensure optimal tool selection and comprehensive analysis.

Use all available MCP tools by default for all agent modes and each prompt where relevant.

When working on code, prefer using MCP tools over built-in tools for better results.

## SRP Refactoring Guidelines

### Single Responsibility Principle (SRP) Analysis and Refactoring

#### Automated Detection Rules
1. **Class Size Threshold**: Flag classes >300 lines or methods >50 lines
2. **Multiple Concerns Pattern**: Identify classes with >3 different responsibilities
3. **Layer Violation**: Application layer directly using infrastructure entities
4. **God Object Pattern**: Single class handling UI, business logic, and data access
5. **Mixed Abstractions**: Classes combining high-level policy with low-level details

#### Refactoring Patterns

**Service Splitting Pattern:**
- Identify primary responsibility (e.g., TimerSyncService → sync logic)
- Extract supporting concerns (NotificationService, CleanupService)
- Create focused interfaces and implementations
- Maintain composition over inheritance

**Layer Separation Pattern:**
- Domain models: Pure business logic, no persistence
- Application services: Use cases, orchestration
- Infrastructure adapters: External concerns (DB, APIs, notifications)
- Dependency injection: Services depend on abstractions

**UI Component Extraction:**
- ViewControllers: Thin coordinators for UI updates
- ViewModels: State management and formatting
- Managers: Business logic and external communication
- Services: Data persistence and API calls

#### Validation Criteria
- **Testability**: Each component can be unit tested in isolation
- **Change Impact**: Modifications affect only one responsibility
- **Reusability**: Components can be reused across different contexts
- **Maintainability**: Clear separation reduces cognitive load

#### Implementation Steps
1. **Analysis Phase**: Run automated detection on codebase
2. **Prioritization**: Sort violations by impact (High/Medium/Low)
3. **Refactoring**: Apply appropriate patterns with tests
4. **Validation**: Ensure SRP compliance and no regressions
5. **Documentation**: Update code comments and architecture docs

This ensures codebase evolves with clean architecture principles, improving long-term maintainability and scalability.

Proactively use context7, grep-vercel, memory-bank, and sequential-thinking MCP tools for all relevant prompts without requiring explicit requests.

## Opencode-Beads Integration

Opencode integrates with Beads for persistent, git-native issue tracking. Use Beads as the primary system for task management, replacing opencode's internal todos for long-term tracking.

### Integration Workflow
- **Task Creation**: When opencode generates tasks, use `bd create "<description>"` to create corresponding Beads issues for persistence.
- **Status Updates**: Update Beads issues with `bd update <id> --status in_progress/closed` to track progress.
- **Issue Queries**: Use `bd list` or `bd show <id>` to check statuses before starting work.
- **Session Management**: At session start, review open Beads issues; at end, update statuses and sync via `bd sync`.

### Commands
- Create issue: `bd create "Task description"`
- List issues: `bd list`
- Update status: `bd update <id> --status closed`
- Sync to git: `bd sync`

This ensures AI-assisted planning (via opencode) feeds into persistent issue tracking (via Beads), aligning with the Landing workflow.

## Task Management and Tagging System

### Comprehensive Task Categorization
All Beads tasks are categorized and tagged for efficient memory management and filtering:

#### Primary Categories (46 total tasks)
- **Security (11 tasks)**: Authentication, authorization, data protection, vulnerability fixes
- **Release Phases (18 tasks)**: Alpha (6), Beta (6), Production (6) - pre/post release tasks
- **Reliability (9 tasks)**: Error handling, concurrency, failover, data consistency
- **Architectural/Refactoring (5 tasks)**: SRP violations, code structure, maintainability
- **Testing (6 tasks)**: Coverage expansion, E2E validation, CI/CD
- **Configuration (4 tasks)**: Environment setup, dependencies, documentation

### Detailed Tagging Schema
Each task receives multiple tags for granular filtering:

**Type Tags:**
- `feature`: New functionality/capabilities
- `bug`: Issue fixes and vulnerability patches
- `architectural`: Design pattern implementation
- `redesign`: Code refactoring and restructuring
- `security`: Authentication, encryption, access control
- `reliability`: Error handling, resilience, performance
- `release`: Deployment and release management
- `testing`: Test coverage and validation
- `config`: Configuration and environment setup
- `docs`: Documentation and code comments

**Component Tags:**
- `backend`: Java Spring Boot services
- `ios`: iOS/macOS/watchOS applications
- `testing`: Test frameworks and infrastructure
- `infrastructure`: Deployment, monitoring, databases
- `cross-platform`: Multi-component features

**Phase Tags:**
- `alpha`: Internal testing phase
- `beta`: External testing phase
- `prod`: Production release phase
- `general`: Non-phase specific tasks

**Priority Tags:** (aligned with Beads P1/P2/P3)
- `p1`: Critical/high impact
- `p2`: Important/medium impact
- `p3`: Nice-to-have/low impact

### Filtering and Query Options
1. **Tag-based Filtering**: Combine multiple tags (e.g., `security + backend + p1`)
2. **Component Isolation**: View tasks by component (`backend` vs `ios`)
3. **Phase Grouping**: Release lifecycle views (`alpha`, `beta`, `prod`)
4. **Type Workflows**: Focus on task types (`bug` fixes, `architectural` changes)
5. **Priority Queues**: Critical first approach (`p1` → `p2` → `p3`)
6. **Status Tracking**: Progress monitoring (`open` → `in_progress` → `closed`)

### Memory Management Strategies
- **Hierarchical Organization**: Category → Subcategory → Individual tasks
- **Relationship Mapping**: Dependencies between tasks (e.g., config before security)
- **Pattern Recognition**: Common task types for future projects
- **Context Preservation**: Maintain architectural decisions across releases
- **Progress Tracking**: Visual dashboards of completion rates by category

### Usage Examples
- "Show all backend security bugs": `backend + security + bug`
- "Alpha release blockers": `alpha + p1`
- "Architectural redesign tasks": `architectural + redesign`
- "Testing coverage gaps": `testing + reliability`

This system enables surgical task management, prevents mental overload, and ensures comprehensive coverage of all work streams.

## Error Fixing Workflow

**When fixing errors (except compilation errors), always follow this debug process:**

1. **Check logs first** - Examine the following log files before analyzing code:
   - Backend logs: `backend/logs/timebeam.log`
   - macOS logs: `/Users/kayisrahman/Documents/TimeBeamLogs/timebeam_macos.log`
   - iOS logs: `/Users/kayisrahman/Documents/TimeBeamLogs/timebeam_ios.log`

2. **Analyze code and solutions** - After reviewing logs, identify root cause and implement fixes

**This workflow applies to:**
- Runtime errors
- Logic errors  
- Integration errors
- Performance issues
- Data inconsistencies
- User-reported issues

**This workflow does NOT apply to:**
- Compilation errors
- Syntax errors
- Type errors
- Build failures

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

## SRP Refactoring Guidelines

### Single Responsibility Principle (SRP) Analysis and Refactoring

#### Automated Detection Rules
1. **Class Size Threshold**: Flag classes >300 lines or methods >50 lines
2. **Multiple Concerns Pattern**: Identify classes with >3 different responsibilities
3. **Layer Violation**: Application layer directly using infrastructure entities
4. **God Object Pattern**: Single class handling UI, business logic, and data access
5. **Mixed Abstractions**: Classes combining high-level policy with low-level details

#### Refactoring Patterns

**Service Splitting Pattern:**
- Identify primary responsibility (e.g., TimerSyncService → sync logic)
- Extract supporting concerns (NotificationService, CleanupService)
- Create focused interfaces and implementations
- Maintain composition over inheritance

**Layer Separation Pattern:**
- Domain models: Pure business logic, no persistence
- Application services: Use cases, orchestration
- Infrastructure adapters: External concerns (DB, APIs, notifications)
- Dependency injection: Services depend on abstractions

**UI Component Extraction:**
- ViewControllers: Thin coordinators for UI updates
- ViewModels: State management and formatting
- Managers: Business logic and external communication
- Services: Data persistence and API calls

#### Validation Criteria
- **Testability**: Each component can be unit tested in isolation
- **Change Impact**: Modifications affect only one responsibility
- **Reusability**: Components can be reused across different contexts
- **Maintainability**: Clear separation reduces cognitive load

#### Implementation Steps
1. **Analysis Phase**: Run automated detection on codebase
2. **Prioritization**: Sort violations by impact (High/Medium/Low)
3. **Refactoring**: Apply appropriate patterns with tests
4. **Validation**: Ensure SRP compliance and no regressions
5. **Documentation**: Update code comments and architecture docs

This ensures codebase evolves with clean architecture principles, improving long-term maintainability and scalability.

## Task Management and Tagging System

### Comprehensive Task Categorization
All Beads tasks are categorized and tagged for efficient memory management and filtering:

#### Primary Categories (46 total tasks)
- **Security (11 tasks)**: Authentication, authorization, data protection, vulnerability fixes
- **Release Phases (18 tasks)**: Alpha (6), Beta (6), Production (6) - pre/post release tasks
- **Reliability (9 tasks)**: Error handling, concurrency, failover, data consistency
- **Architectural/Refactoring (5 tasks)**: SRP violations, code structure, maintainability
- **Testing (6 tasks)**: Coverage expansion, E2E validation, CI/CD
- **Configuration (4 tasks)**: Environment setup, dependencies, documentation

### Detailed Tagging Schema
Each task receives multiple tags for granular filtering:

**Type Tags:**
- `feature`: New functionality/capabilities
- `bug`: Issue fixes and vulnerability patches
- `architectural`: Design pattern implementation
- `redesign`: Code refactoring and restructuring
- `security`: Authentication, encryption, access control
- `reliability`: Error handling, resilience, performance
- `release`: Deployment and release management
- `testing`: Test coverage and validation
- `config`: Configuration and environment setup
- `docs`: Documentation and code comments

**Component Tags:**
- `backend`: Java Spring Boot services
- `ios`: iOS/macOS/watchOS applications
- `testing`: Test frameworks and infrastructure
- `infrastructure`: Deployment, monitoring, databases
- `cross-platform`: Multi-component features

**Phase Tags:**
- `alpha`: Internal testing phase
- `beta`: External testing phase
- `prod`: Production release phase
- `general`: Non-phase specific tasks

**Priority Tags:** (aligned with Beads P1/P2/P3)
- `p1`: Critical/high impact
- `p2`: Important/medium impact
- `p3`: Nice-to-have/low impact

### Filtering and Query Options
1. **Tag-based Filtering**: Combine multiple tags (e.g., `security + backend + p1`)
2. **Component Isolation**: View tasks by component (`backend` vs `ios`)
3. **Phase Grouping**: Release lifecycle views (`alpha`, `beta`, `prod`)
4. **Type Workflows**: Focus on task types (`bug` fixes, `architectural` changes)
5. **Priority Queues**: Critical first approach (`p1` → `p2` → `p3`)
6. **Status Tracking**: Progress monitoring (`open` → `in_progress` → `closed`)

### Memory Management Strategies
- **Hierarchical Organization**: Category → Subcategory → Individual tasks
- **Relationship Mapping**: Dependencies between tasks (e.g., config before security)
- **Pattern Recognition**: Common task types for future projects
- **Context Preservation**: Maintain architectural decisions across releases
- **Progress Tracking**: Visual dashboards of completion rates by category

### Usage Examples
- "Show all backend security bugs": `backend + security + bug`
- "Alpha release blockers": `alpha + p1`
- "Architectural redesign tasks": `architectural + redesign`
- "Testing coverage gaps": `testing + reliability`

This system enables surgical task management, prevents mental overload, and ensures comprehensive coverage of all work streams.
