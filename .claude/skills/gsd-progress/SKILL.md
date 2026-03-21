---
name: gsd-progress
description: Check project progress and route to next action
user-invocable: true
---

# GSD Progress Check

Check project progress, show current context, and route to next action.

## When to Use

- Starting a new work session
- Wanting to understand current state
- Deciding between planning vs execution

## Context Display

Show:
1. Current milestone status
2. Active phases (in-progress)
3. Completed phases
4. Roadmap progress table
5. Active requirements (not yet implemented)

## Routing Logic

### If No Phases Started
Route to: `/gsd:new-milestone` or `/gsd:plan-phase`

### If Milestone Has Incomplete Phases
Route to: `/gsd:progress` shows next phase options:
- Execute: `/gsd:execute-phase` for current phase
- Plan: `/gsd:plan-phase` for detailed planning
- Discuss: `/gsd:discuss-phase` for approach questions

### If All Phases Complete
Route to: `/gsd:audit-milestone` to verify completion

### If Stuck on Phase
Route to: `/gsd:pause-work` to create handoff or `/gsd:debug` for systematic debugging

## Output Format

```
## Current Progress

**Milestone:** [name/version]
**Status:** [active/completed]

### Phase Progress
| Phase | Status | Requirements |
|-------|--------|--------------|
| 1 | Complete | 5/5 |
| 2 | In Progress | 3/8 |
| 3 | Not Started | 0/4 |

### Active Requirements
- [ ] REQ-XX: Description
- [ ] REQ-YY: Description

### Next Actions
1. [ ] Complete remaining requirements in Phase 2
2. [ ] Plan Phase 3 requirements

### Recommended Command
`/gsd:execute-phase` - Continue current phase work
OR
`/gsd:plan-phase` - Plan next phase
```

## Integration with GSD Commands

Use with:
- `/gsd:execute-phase` - Execute current phase after progress check
- `/gsd:plan-phase` - Plan next phase
- `/gsd:pause-work` - Handoff when pausing mid-phase
- `/gsd:resume-work` - Resume from previous session

## Session Continuity

This skill reads from:
- `.planning/ROADMAP.md` - Phase status
- `.planning/PROJECT.md` - Active requirements
- Memory system (`.claude/projects/`) - Session context
