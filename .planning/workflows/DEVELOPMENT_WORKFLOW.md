# Development Workflow

Complete development workflow using Synapse skills and GSD.

## Overview

This workflow integrates:
- GSD (Giant Step Development) phase planning
- Skills for testing and code quality
- Git worktrees for isolation
- Memory system for context

## Prerequisites

- Git worktrees configured (`.claude/worktrees/`)
- Gradle wrapper in `app/` directory
- External services (Redis, Qdrant) available for integration tests
- Memory system at `.claude/projects/`

## Feature Development Workflow

### Step 1: Start Session

```bash
/gsd:progress
```

Shows:
- Current milestone status
- Active phases
- Next recommended actions

### Step 2: Plan Phase (If Needed)

```bash
/gsd:plan-phase
```

Creates PLAN.md files for current phase.

**Review plans:**
```bash
/gsd-plan-review
```

### Step 3: Create Worktree

```bash
# Create isolated worktree for feature
git worktree add -b feature/my-feature ../my-feature-worktree
cd ../my-feature-worktree
```

Or use skill:
```bash
/superpowers:using-git-worktrees
```

### Step 4: Implement Features

Implement requirements from PLAN.md.

**During implementation:**
- Auto-invoked `code-simplify` reviews changes
- Auto-invoked `project-conventions` ensures Spring AI compliance
- Auto-invoked `spring-ai-reviewer` checks llm/ changes

### Step 5: Verify Build

```bash
/verify-build
```

Runs:
```bash
cd app && ./gradlew compileJava
```

### Step 6: Run Tests

```bash
/run-tests
```

Runs:
```bash
cd app && ./gradlew test
```

### Step 7: Integration Tests (If Needed)

```bash
/integration-test
```

Requires:
- Redis running
- Qdrant running
- Database configured

### Step 8: Code Review

```bash
/code-simplify
```

Reviews:
- Code duplication
- Complexity
- Naming
- Spring AI compliance

### Step 9: Verify Phase

```bash
/gsd:verification
```

Verifies:
- Success criteria met
- Tests passing
- Documentation complete

### Step 10: Commit and Push

```bash
git add .
git commit -m "feat: implement [feature]"
git push origin feature/my-feature
```

### Step 11: Create PR

Create pull request to `develop` branch.

### Step 12: Cleanup Worktree

```bash
# Return to main workspace
cd /Users/kayisrahman/Documents/workspace/ideas/synapse

# Delete worktree
git worktree delete ../my-feature-worktree
git branch -D feature/my-feature
git push origin --delete feature/my-feature

# Prune stale references
git worktree prune
```

## Phase Completion Workflow

### Step 1: Complete All Plans

Execute all PLAN.md files in phase.

```bash
/gsd:execute-phase
```

### Step 2: Verify Each Phase

```bash
/gsd:verification
```

For each phase in milestone.

### Step 3: Audit Milestone

```bash
/gsd-audit
```

Audits:
- All phases complete
- Requirements covered
- Tests passing
- Documentation complete

### Step 4: Archive Milestone

```bash
/gsd:complete-milestone
```

Updates:
- ROADMAP.md progress table
- PROJECT.md current state
- Creates archive commit

## Testing Workflow

### Unit Tests Only

```bash
/verify-build
/run-tests
```

### With Integration Tests

```bash
/verify-build
/run-tests
/integration-test
```

### With E2E Tests

```bash
/verify-build
/run-tests
/integration-test
/run-e2e-tests
```

## Code Review Workflow

### Automated Reviews

Auto-invoked on:
- File edit: `code-simplify`
- Spring AI changes: `project-conventions`
- llm/ changes: `spring-ai-reviewer`

### Manual Review

```bash
/code-simplify
```

Reviews changed code for:
- Duplication
- Complexity
- Quality
- Efficiency

### Before Commit

```bash
/verify-build
/run-tests
/code-simplify
```

## Git Workflow

### Branch Strategy

- `main` - Production releases
- `develop` - Active development
- `feature/*` - Feature work (use worktrees)
- `synapse-archive` - Archived branches

### Worktree Commands

```bash
# List worktrees
git worktree list

# Create worktree
git worktree add -b feature/name ../worktree-name

# Delete worktree
git worktree delete ../worktree-name

# Prune stale references
git worktree prune
```

### Cleanup After Feature

```bash
# Delete branch locally
git branch -D feature/name

# Delete branch remotely
git push origin --delete feature/name

# Prune references
git worktree prune
```

## Memory System Workflow

### Reading Context

Memory files at `.claude/projects/`:

- `user_preferences.md` - Coding style, preferences
- `project_context.md` - Current milestone, phases
- `feedback_development.md` - Corrections, lessons
- `MEMORY.md` - Index file

### Updating Context

Update memory when:
- Learning user preferences
- Completing milestone
- Finding important patterns
- Making key decisions

### Memory Format

```markdown
---
name: <memory name>
description: <one-line description>
type: <user, feedback, project, reference>
---

<content>

**Why:** <reason>

**How to apply:** <when to use>
```

## GSD Workflow

### Planning

```bash
/gsd:plan-phase
```

Creates PLAN.md with:
- Wave-based parallelization
- Atomic commits
- Verification steps

### Execution

```bash
/gsd:execute-phase
```

Executes all plans with:
- Wave-based parallelization
- State tracking
- Checkpoint protocol

### Progress

```bash
/gsd:progress
```

Shows:
- Current state
- Next actions
- Routing recommendations

### Debugging

```bash
/gsd:debug
```

Systematic debugging with:
- Persistent state
- Checkpoint management
- Scientific method

## Common Scenarios

### Starting New Work

```bash
1. /gsd:progress
2. /gsd:plan-phase (if needed)
3. /superpowers:using-git-worktrees
4. Start implementation
```

### Fixing Bug

```bash
1. /gsd:progress
2. /gsd:debug
3. Implement fix
4. /verify-build
5. /run-tests
6. /code-simplify
```

### Pre-PR Checklist

```bash
1. /verify-build
2. /run-tests
3. /code-simplify
4. Git status clean
5. Create PR
```

### Pre-Deployment

```bash
1. /verify-build
2. /run-tests
3. /integration-test
4. /run-e2e-tests
5. /gsd:verification
```

## Troubleshooting

### Tests Failing

1. Run `/verify-build` first
2. Check compilation errors
3. Review test output
4. Check external services
5. Run `/integration-test` for more details

### Build Errors

1. Check Spring AI API usage
2. Review `project-conventions` skill
3. Verify Gradle wrapper location
4. Check dependencies resolve

### Worktree Issues

1. Run `git worktree prune`
2. Check worktree list
3. Delete stale worktrees
4. Clean `.claude/worktrees/` directory

### Memory Issues

1. Check `.claude/projects/` exists
2. Verify MEMORY.md format
3. Check file permissions
4. Review memory content

## Best Practices

### Always
- Use worktrees for feature isolation
- Run `/verify-build` before `/run-tests`
- Review with `/code-simplify` before committing
- Check `/gsd:progress` at session start
- Update memory with important learnings

### Never
- Commit without running tests
- Skip build verification
- Ignore compilation warnings
- Work directly on develop branch
- Forget to cleanup worktrees

## Integration with CI/CD

Skills mirror CI steps:

```bash
# Local (skills)
/verify-build
/run-tests
/integration-test

# CI (same commands)
cd app && ./gradlew compileJava
cd app && ./gradlew test
cd app && ./gradlew test --tests "*Integration*"
```

Consistency between local and CI ensures reliability.
