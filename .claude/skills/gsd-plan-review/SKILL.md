---
name: gsd-plan-review
description: Review phase plans before execution - verify completeness and feasibility
user-invocable: true
---

# GSD Phase Plan Review

Review phase plans before execution to verify completeness and feasibility.

## When to Use

- After `/gsd:plan-phase` creates PLAN.md files
- Before `/gsd:execute-phase` starts implementation
- When phase has multiple plans (waves)

## Review Checklist

### Plan Completeness
- [ ] All requirements from ROADMAP.md have corresponding plans
- [ ] Each plan has clear goal statement
- [ ] Success criteria defined and verifiable
- [ ] Dependencies between plans documented

### Feasibility
- [ ] Plans are atomic (can complete independently)
- [ ] Technical approach is sound
- [ ] Required files and components identified
- [ ] Test strategy included

### Dependencies
- [ ] Phase dependencies respected (from ROADMAP.md)
- [ ] Plan dependencies ordered correctly
- [ ] Cross-phase dependencies identified

### Verification
- [ ] Each plan has verification steps
- [ ] Success criteria are testable
- [ ] Integration points defined

### GSD Alignment
- [ ] Plans follow GSD wave-based parallelization
- [ ] Atomic commits planned
- [ ] State tracking defined
- [ ] Checkpoint protocol established

## Output Format

```
## Plan Review Results

### Completeness
- All requirements mapped: X/Yes
- Goals clear: Yes/No
- Success criteria defined: Yes/No

### Feasibility
- Technical approach sound: Yes/No
- Files/components identified: Yes/No
- Test strategy included: Yes/No

### Dependencies
- Phase dependencies respected: Yes/No
- Plan dependencies ordered: Yes/No
- Cross-phase issues: [list or "None"]

### Verification
- Verification steps defined: Yes/No
- Criteria testable: Yes/No
- Integration points clear: Yes/No

### Issues Found
1. [issue] - [severity]
2. ...

### Recommendation
APPROVE - Plans ready for execution
OR
REVISION NEEDED - [specific changes required]
```

## Common Plan Issues

1. **Missing requirements** - Some requirements not mapped to plans
2. **Overly ambitious plans** - Plans too large, should be split
3. **Missing tests** - Plans don't include verification
4. **Unclear dependencies** - Plan order not justified
5. **No success criteria** - Can't verify completion

## Integration with GSD Commands

Use with:
- `/gsd:plan-phase` - Creates plans to review
- `/gsd:execute-phase` - Execute after approval
- `/gsd:plan-review` - This skill for review
- `/gsd:discussion` - Discuss unclear plans
