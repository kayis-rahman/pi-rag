# Claude Code Configuration for Synapse

## GitFlow Strategy

### Branch Structure
- `main` = production releases
- `develop` = active development branch
- `feature/*` = feature branches (use git worktrees for isolation)
- `synapse-archive` = archived branches (marked with "archived" commit)
- `worktree/*` = worktree-based feature branches

### Worktree Workflow
All feature development should use git worktrees for isolation:
```bash
# Create a new worktree for a feature
git worktree add -b feature/my-feature ../my-feature-worktree

# Or use the .claude/worktrees directory for isolated worktrees
# Features are automatically cleaned up after completion
```

### Branch Cleanup Best Practices
After completing feature work:
1. Merge feature branch to active development branch
2. Delete feature branch locally and remotely
3. Clean up worktree directories in `.claude/worktrees/`
4. Run `git worktree prune` to remove stale references

### Preserved Branches
- Development branch (active development) - always preserved
- Production branch (releases) - always preserved
- Archived branch - preserved with "archived" marker commit

### Common Git Commands
```bash
# Fetch latest changes
git fetch --all

# List all branches (local and remote)
git branch -a

# Clean up stale worktree references
git worktree prune

# Check worktree status
git worktree list

# Delete a feature branch locally
git branch -D feature/branch-name

# Delete a feature branch remotely
git push origin --delete feature/branch-name
```

## Project Conventions

### Build System
- Gradle 9.3.1 with Kotlin DSL
- GraalVM Native Image support
- Spring AI integration

### Code Quality
- Java compilation verified on every Edit/Write to `app/src/main/java`
- Pre-commit hooks available (Husky)

### Logging
- Logs stored in `app/logs/`
- Log files ignored by git

## Claude Code Skills

### Available Skills
- `run-tests` - Run Synapse Gradle tests
- `project-conventions` - Project coding conventions for Spring AI
- `simplify` - Review and simplify code

## Memory System

This project uses a memory system at `.claude/projects/` for:
- User preferences
- Feedback and corrections
- Project context
- References to external systems

## Important Notes

- API keys in `application.yml` require verification before modification
- GPUHUB_API_KEY, ANTHROPIC_API_KEY, Redis, Qdrant, SQLite configurations
- Worktrees stored in `.claude/worktrees/` are automatically cleaned up
