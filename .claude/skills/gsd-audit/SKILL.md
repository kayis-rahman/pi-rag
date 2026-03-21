---
name: gsd-audit
description: Audit milestone completion before archiving - verify all phases meet success criteria
user-invocable: true
---

# GSD Milestone Audit

Audit a milestone's completion against original intent before archiving.

## When to Use

- Before archiving a completed milestone
- Before starting a new milestone cycle
- To verify all phase requirements are met

## Checklist

### Phase Completion
- [ ] All phases in milestone marked complete in ROADMAP.md
- [ ] Each phase has at least one PLAN.md file
- [ ] All plans have corresponding implementation
- [ ] Success criteria verified for each phase

### Requirements Coverage
- [ ] All requirements mapped to phases
- [ ] No orphaned requirements (all checked in Coverage table)
- [ ] No unimplemented requirements

### Code Quality
- [ ] All code compiles without errors
- [ ] Unit tests pass (`./gradlew test`)
- [ ] Integration tests pass (if applicable)
- [ ] No critical warnings in build output

### Documentation
- [ ] Phase plans document approach
- [ ] Implementation matches plan intent
- [ ] ROADMAP.md progress table updated
- [ ] PROJECT.md reflects current state

### Testing
- [ ] Test coverage for new features
- [ ] Edge cases handled
- [ ] Error paths tested

## Output Format

Report findings in this structure:

```
## Audit Results

### Phases
- Phase X: COMPLETE - [brief summary]
- Phase Y: INCOMPLETE - [missing items]

### Requirements
- Implemented: X/Y
- Missing: [list]

### Issues Found
1. [issue description] - [severity: critical/high/medium/low]
2. ...

### Recommendations
- [actionable steps to address issues]
```

## Common Audit Failures

1. **Missing plan documentation** - Phase implemented without PLAN.md
2. **Incomplete success criteria** - Phase marked complete but criteria not verified
3. **Orphaned requirements** - Requirements not mapped to any phase
4. **Test failures** - Tests failing but milestone still archived

## Integration with GSD Commands

Use with:
- `/gsd:audit-milestone` - Official GSD milestone audit command
- `/gsd:complete-milestone` - Archive milestone after successful audit
- `/gsd:plan-milestone-gaps` - Create phases to address audit findings
