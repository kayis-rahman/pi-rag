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
