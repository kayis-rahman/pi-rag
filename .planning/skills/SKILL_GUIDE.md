# Synapse Skills Guide

Complete guide to all available skills in the Synapse project.

## Quick Reference

### User-Invocable Skills

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/run-tests` | Run Gradle unit tests | Before committing, after changes |
| `/verify-build` | Verify compilation | Before running tests |
| `/run-e2e-tests` | Run E2E tests | Before deployment |
| `/integration-test` | Run integration tests | After feature implementation |
| `/code-simplify` | Review code quality | Before committing |
| `/gsd-audit` | Audit milestone completion | Before archiving milestone |
| `/gsd-progress` | Check project progress | Starting new session |
| `/gsd-plan-review` | Review phase plans | Before execution |
| `/gsd-verification` | Verify phase completion | After phase execution |

### Auto-Invoked Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `project-conventions` | Before Spring AI work | Ensure API compliance |
| `spring-ai-reviewer` | Before committing to `llm/` | Review ChatModel usage |
| `code-simplify` | On file edit | Review changed code |

### GSD Commands

| Command | Description |
|---------|-------------|
| `/gsd:plan-phase` | Create detailed phase plan |
| `/gsd:execute-phase` | Execute all plans in phase |
| `/gsd:audit-milestone` | Audit milestone completion |
| `/gsd:complete-milestone` | Archive completed milestone |
| `/gsd:progress` | Check project progress |
| `/gsd:verify-work` | Conversational UAT |
| `/gsd:add-tests` | Generate tests for phase |

## Skill Categories

### 1. Build & Testing

#### `/verify-build`
Verifies Gradle build compiles successfully.

```bash
cd app && ./gradlew compileJava
```

**Use when:** Before running tests, after code changes.

#### `/run-tests`
Runs unit tests from `app/` directory.

```bash
cd app && ./gradlew test
```

**Use when:** Before committing, after implementing features.

#### `/integration-test`
Runs integration tests with external services.

```bash
cd app && ./gradlew test --tests "*Integration*"
```

**Use when:** Testing component interaction, requires Redis/Qdrant.

#### `/run-e2e-tests`
Runs end-to-end tests.

```bash
cd app && ./gradlew test --tests "*E2E*"
```

**Use when:** Full system testing, before deployment.

### 2. Code Quality

#### `/code-simplify`
Reviews code for reuse, quality, and efficiency.

**Use when:** Before committing, after feature implementation.

**Reviews:**
- Code duplication
- Method complexity
- Naming clarity
- Error handling
- Spring AI compliance

#### `project-conventions` (Auto)
Ensures Spring AI 1.0.0 API compliance.

**Triggers:** Before modifying Spring AI components.

**Enforces:**
- Constructor injection
- Reactive patterns
- Spring AI 1.0.0 API usage
- Testing conventions

#### `spring-ai-reviewer` (Auto)
Specialist reviewer for Spring AI API.

**Triggers:** Before committing to `llm/` package.

**Checks:**
- `ChatModel.call()` return types
- `ChatModel.stream()` return types
- Prompt API correctness
- Response construction

### 3. GSD Integration

#### `/gsd-progress`
Check project progress and route to next action.

**Shows:**
- Current milestone status
- Phase progress
- Active requirements
- Recommended next steps

**Use when:** Starting new session, deciding next action.

#### `/gsd-plan-review`
Review phase plans before execution.

**Reviews:**
- Plan completeness
- Feasibility
- Dependencies
- Verification steps
- GSD alignment

**Use when:** After `/gsd:plan-phase`, before `/gsd:execute-phase`.

#### `/gsd-verification`
Verify phase goals after completion.

**Verifies:**
- Success criteria met
- Requirements implemented
- Tests passing
- Documentation complete

**Use when:** After `/gsd:execute-phase`, before marking complete.

#### `/gsd-audit`
Audit milestone completion before archiving.

**Audits:**
- Phase completion
- Requirements coverage
- Code quality
- Documentation
- Testing

**Use when:** Before archiving milestone, before new milestone.

### 4. Existing GSD Commands

Full GSD command reference: `/gsd:help`

## Skill Workflows

### Feature Development Workflow

```
1. /gsd:progress → Check current phase
2. /gsd:plan-phase → Plan new phase (if needed)
3. /gsd:execute-phase → Implement features
4. /verify-build → Verify compilation
5. /run-tests → Run unit tests
6. /code-simplify → Review code quality
7. /gsd:verification → Verify phase complete
```

### Testing Workflow

```
1. /verify-build → Compile
2. /run-tests → Unit tests
3. /integration-test → Integration tests (if needed)
4. /run-e2e-tests → E2E tests (if needed)
```

### Code Review Workflow

```
1. Edit files (auto: code-simplify)
2. /code-simplify → Manual review
3. /project-conventions → If Spring AI changes
4. /spring-ai-reviewer → If llm/ changes
5. Commit
```

### Milestone Completion Workflow

```
1. Complete all phases
2. /gsd-verification → Verify each phase
3. /gsd-audit → Audit milestone
4. /gsd:complete-milestone → Archive milestone
```

## Best Practices

### Always
- Run `/verify-build` before `/run-tests`
- Use `/gsd:progress` to understand current state
- Review with `/code-simplify` before committing
- Follow `project-conventions` for Spring AI work

### Never
- Run tests before build compiles
- Skip verification before marking complete
- Ignore compilation warnings
- Commit without running tests

## Memory System

Skills reference memory at `.claude/projects/`:

- `user_preferences.md` - Coding style, workflow preferences
- `project_context.md` - Current milestone, active phases
- `feedback_development.md` - Corrections, lessons learned
- `MEMORY.md` - Index file

## Integration Points

### With GSD
- GSD skills use `/gsd:*` prefix
- Standard skills use `/name` prefix
- Both can be used together

### With Git
- Skills verify before commits
- Skills check compilation before testing
- Skills ensure quality before merging

### With CI/CD
- Skills mirror CI steps locally
- Run `/verify-build` and `/run-tests` before PR
- Use `/integration-test` for full verification

## Troubleshooting

### Skill Not Found
- Check skill name spelling
- Verify skill file exists in `.claude/skills/`
- Restart Claude Code session

### Tests Failing
- Run `/verify-build` first
- Check external services (Redis, Qdrant)
- Review error output from `/run-tests`

### Build Errors
- Check Spring AI API usage
- Review `project-conventions` skill
- Verify Gradle wrapper in `app/`

## Contributing New Skills

To add a new skill:

1. Create `.claude/skills/<name>/SKILL.md`
2. Follow existing skill format
3. Define `user-invocable: true/false`
4. Add to `SKILL_GUIDE.md`
5. Test the skill

See existing skills for examples.
