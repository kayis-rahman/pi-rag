---
name: code-simplify
description: Review and simplify changed code for reuse, quality, and efficiency
user-invocable: true
---

# Code Simplify

Review changed code for reuse, quality, and efficiency, then fix issues.

## When to Use

- After implementing a feature
- Before committing changes
- When code review identifies complexity issues
- After refactoring work

## Review Checklist

### Code Reuse
- [ ] No duplicated code blocks
- [ ] Common logic extracted to helpers
- [ ] Services follow single responsibility
- [ ] No code that should be utility methods

### Quality
- [ ] Clear variable/method names
- [ ] Methods are small (< 20 lines ideal)
- [ ] No deep nesting (> 3 levels)
- [ ] Error handling appropriate
- [ ] Comments explain "why", not "what"

### Efficiency
- [ ] No unnecessary object creation
- [ ] Proper use of streams vs loops
- [ ] Database queries optimized
- [ ] No N+1 query problems
- [ ] Reactive patterns used correctly

### Spring AI Compliance
- [ ] `ChatModel.call()` returns `ChatResponse`
- [ ] `ChatModel.stream()` returns `Flux<ChatResponse>`
- [ ] No `.block()` calls in production
- [ ] Proper reactive error handling

### Testing
- [ ] New code has tests
- [ ] Edge cases covered
- [ ] Error paths tested
- [ ] Tests are readable

## Output Format

```
## Code Simplification Review

### Changes Reviewed
- File: path/to/File.java
- Lines: X-Y

### Issues Found

#### High Priority
1. [issue] - [suggestion]
2. ...

#### Medium Priority
1. [issue] - [suggestion]
2. ...

#### Low Priority
1. [issue] - [suggestion]
2. ...

### Recommendations
- [ ] Fix high priority issues
- [ ] Consider medium priority
- [ ] Low priority optional

### Auto-Fix Available
Yes/No - Can skill auto-fix issues
```

## Common Simplification Opportunities

1. **Duplicate logic** - Extract to shared method
2. **Long methods** - Split into smaller methods
3. **Deep nesting** - Use early returns or guard clauses
4. **Magic numbers** - Extract to constants
5. **Unnecessary complexity** - Simplify conditional logic
6. **Poor naming** - Rename for clarity

## Integration with GSD

Use after:
- `/gsd:execute-phase` - Review phase implementation
- `/gsd:verify-work` - Before marking complete

Use with:
- `/simplify` - Auto-invoked version for changed code
- Code review workflow

## Auto-Invoked Version

The `/simplify` skill is auto-invoked when you edit files. It reviews changed code automatically.
