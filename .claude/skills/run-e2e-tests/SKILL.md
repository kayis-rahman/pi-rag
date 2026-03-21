---
name: run-e2e-tests
description: Run E2E tests specifically - separate from unit tests
user-invocable: true
---

# Run E2E Tests

Run end-to-end tests that require external services (Redis, Qdrant, database).

## When to Use

- After unit tests pass
- Before deployment
- When testing full integration
- After enabling external services

## Prerequisites

External services must be running:
- [ ] Redis server on configured host/port
- [ ] Qdrant vector database on configured host/port
- [ ] PostgreSQL database (if used)
- [ ] SQLite database file writable

## Test Command

```bash
cd app && ./gradlew test --tests "*E2E*" --tests "*Integration*"
```

Or use tagged tests:
```bash
cd app && ./gradlew test --tests "*E2ETests*"
```

## Checklist

### Service Status
- [ ] Redis connected and responding
- [ ] Qdrant connected and responding
- [ ] Database connections working
- [ ] API endpoints accessible

### Test Configuration
- [ ] Test profile active (`@ActiveProfiles("test")`)
- [ ] Test containers or local services running
- [ ] Test data cleaned between tests
- [ ] Test isolation maintained

### Test Execution
- [ ] Tests start without errors
- [ ] Tests complete within timeout
- [ ] No test flakiness
- [ ] Proper cleanup after tests

## Output Format

```
## E2E Test Results

### Summary
- Total: X
- Passed: X
- Failed: X
- Skipped: X

### Failures
| Test | Error | Status |
|------|-------|--------|
| TestName | [error] | FAILED |

### Service Health
- Redis: CONNECTED/FAILED
- Qdrant: CONNECTED/FAILED
- Database: CONNECTED/FAILED

### Recommendations
1. Start Redis: `redis-server`
2. Start Qdrant: `docker run -p 6379:6379 qdrant/qdrant`
3. Check test configuration in `application-test.yml`
```

## Common E2E Issues

1. **Service not running** - External services not available
   - Fix: Start Redis, Qdrant, or database services

2. **Connection refused** - Wrong host/port configuration
   - Fix: Check `application-test.yml` for correct endpoints

3. **Test data pollution** - Tests interfering with each other
   - Fix: Use test containers or cleanup between tests

4. **Timeout errors** - Services slow or network issues
   - Fix: Increase timeouts or check network

## Integration with Unit Tests

```
1. verify-build → compile
2. run-tests → unit tests (no external services)
3. run-e2e-tests → integration tests (with services)
```

## Tagging E2E Tests

Mark E2E tests with JUnit 5 tags:
```java
@Tag("E2E")
class MyE2ETests { ... }

@Tag("Integration")
class MyIntegrationTests { ... }
```

Then run: `./gradlew test --tests "*@E2E*"`
