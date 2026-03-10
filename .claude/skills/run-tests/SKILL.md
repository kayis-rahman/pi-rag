---
name: run-tests
description: Run Synapse Gradle tests - use when asked to run, check, or verify tests pass
user-invocable: true
---

# Run Synapse Tests

Run tests from the `app/` subdirectory (NOT the project root):

```bash
cd /Users/kayisrahman/Documents/workspace/ideas/synapse/app && ./gradlew test
```

## Reporting

After the run, report:
1. **Pass/fail counts** — total tests, passed, failed, skipped
2. **Compilation errors** — if build fails before tests run, show the full error with file and line number
3. **Failing tests** — for each failure: test class, method name, and the relevant stack trace lines

## Common Issues

- If tests fail to compile, check for Spring AI API mismatches (see project-conventions skill)
- If a test requires Redis/Qdrant/SQLite, it may need external services running; note this clearly
- Run `./gradlew compileJava` first to isolate compilation errors from test failures
