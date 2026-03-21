---
name: verify-build
description: Verify Gradle build compiles successfully before testing
user-invocable: true
---

# Verify Build

Verify Gradle build compiles successfully before running tests.

## When to Use

- Before running tests (`/run-tests`)
- After modifying source code
- Before committing changes
- When tests fail due to compilation errors

## Build Command

```bash
cd app && ./gradlew compileJava
```

## Checklist

### Compilation
- [ ] No compilation errors in `app/src/main/java`
- [ ] No compilation warnings (critical only)
- [ ] All dependencies resolve correctly
- [ ] Spring AI API usage correct

### Dependencies
- [ ] All Gradle dependencies downloaded
- [ ] No version conflicts
- [ ] Spring AI 1.0.0 API used correctly

### Spring AI Compliance
- [ ] `ChatModel.call()` returns `ChatResponse`
- [ ] `ChatModel.stream()` returns `Flux<ChatResponse>`
- [ ] No deprecated `org.springframework.ai.chat.client` imports
- [ ] `prompt.getInstructions()` used (not `getValue()`, `getText()`, `getMetadata()`)

## Output Format

```
## Build Verification

### Compilation Status
[SUCCESS] or [FAILED]

### Errors
If failed:
- File: path/to/File.java
- Line: 42
- Error: [full error message]

### Warnings
- File: path/to/File.java
- Line: 15
- Warning: [warning message]

### Dependencies
- Status: RESOLVED/FAILED
- Issues: [list or "None"]

### Recommendation
BUILD PASSES - Ready for testing
OR
BUILD FAILED - Fix errors before testing
```

## Common Compilation Errors

1. **Spring AI API mismatch** - Using old `org.springframework.ai.chat.client` API
   - Fix: Use `ChatModel` interface instead
   - See: `/project-conventions` skill

2. **Missing dependencies** - Gradle can't resolve dependencies
   - Fix: `./gradlew build --refresh-dependencies`

3. **Package not found** - Import errors
   - Fix: Check package names and imports

4. **Method not found** - API method doesn't exist
   - Fix: Verify Spring AI 1.0.0 API documentation

## Integration with Test Workflow

```
1. verify-build → compileJava
2. run-tests → test (only if build passes)
3. fix errors → repeat
```

## Integration with GSD

Use after:
- `/gsd:execute-phase` - Verify phase compiles
- `/gsd:verify-work` - Before marking complete

Use before:
- `/run-tests` - Ensure tests can run
- `/gsd:verification` - Phase verification starts with build
