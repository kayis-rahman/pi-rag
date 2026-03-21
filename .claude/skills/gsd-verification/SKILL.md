---
name: gsd-verification
description: Verify phase goals are met after completion
user-invocable: true
---

# GSD Phase Verification

Verify phase goals are met after completion before marking phase complete.

## When to Use

- After `/gsd:execute-phase` completes a phase
- Before marking phase as complete in ROADMAP.md
- When claiming phase completion

## Verification Checklist

### Goal Achievement
- [ ] Phase goal from ROADMAP.md achieved
- [ ] All success criteria verified
- [ ] No critical issues remaining

### Requirements Implementation
- [ ] All mapped requirements implemented
- [ ] Requirements testable/verifiable
- [ ] No partial implementations

### Code Quality
- [ ] Code compiles without errors
- [ ] Unit tests pass
- [ ] Integration tests pass (if applicable)
- [ ] No critical warnings

### Documentation
- [ ] Phase PLAN.md exists
- [ ] Implementation matches plan
- [ ] Success criteria documented
- [ ] ROADMAP.md updated

### Testing
- [ ] Tests cover new functionality
- [ ] Edge cases handled
- [ ] Error paths tested
- [ ] StepVerifier used for reactive streams

### Integration
- [ ] Phase integrates with completed phases
- [ ] No breaking changes to existing code
- [ ] Dependencies satisfied

## Output Format

```
## Phase Verification Report

**Phase:** [number] - [name]
**Status:** [VERIFIED/NOT VERIFIED]

### Success Criteria
| Criterion | Status | Evidence |
|-----------|--------|----------|
| Criterion 1 | PASS | [proof] |
| Criterion 2 | PASS | [proof] |

### Requirements
- Implemented: X/Y
- Verified: X/Y
- Missing: [list]

### Test Results
- Unit tests: PASS/FAIL
- Integration tests: PASS/FAIL
- Coverage: X%

### Issues Found
1. [issue] - [severity] - [action]
2. ...

### Verification Decision
APPROVED - Phase goals met
OR
NOT APPROVED - [reasons]
```

## Verification Commands

Run these before verification:
```bash
cd app && ./gradlew test
cd app && ./gradlew compileJava
git status
git diff --stat
```

## Common Verification Failures

1. **Tests failing** - Must fix before approval
2. **Compilation errors** - Must fix before approval
3. **Missing requirements** - All must be implemented
4. **No documentation** - PLAN.md required
5. **Breaking changes** - Must maintain compatibility

## Integration with GSD Commands

Use with:
- `/gsd:execute-phase` - Execute phase to verify
- `/gsd:verify-work` - Conversational UAT verification
- `/gsd:add-tests` - Generate tests if missing
- `/gsd:complete-milestone` - After all phases verified
