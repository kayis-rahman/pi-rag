---
name: integration-test
description: Run integration tests with external services
user-invocable: true
---

# Integration Tests

Run integration tests that verify component interaction with external services.

## When to Use

- After implementing new features
- Before merging to develop branch
- When testing multi-component interactions
- After database configuration changes

## Test Types

### Unit Integration Tests
- Test single component with mocked dependencies
- Fast execution
- No external services required

### Component Integration Tests
- Test component with real dependencies (mocked or testcontainers)
- Medium execution time
- May require testcontainers

### Full Integration Tests
- Test full stack with external services
- Slow execution
- Requires Redis, Qdrant, database running

## Test Command

```bash
cd app && ./gradlew test --tests "*IntegrationTests*" --tests "*ComponentTests*" --tests "*RepositoryTests*"
```

## Checklist

### Test Setup
- [ ] Test profile configured (`application-test.yml`)
- [ ] Test data isolated from production
- [ ] Test cleanup after execution
- [ ] Test containers configured (if used)

### External Services
- [ ] Redis available for test
- [ ] Qdrant available for test
- [ ] Database available for test
- [ ] API endpoints accessible

### Test Execution
- [ ] Tests run in correct order
- [ ] No test interference
- [ ] Proper transaction rollback
- [ ] Resources cleaned up

### Test Coverage
- [ ] Repository layer tested
- [ ] Service layer tested
- [ ] Controller layer tested (if applicable)
- [ ] Integration points tested

## Output Format

```
## Integration Test Results

### Summary
- Total: X
- Passed: X
- Failed: X
- Skipped: X

### By Type
- Unit Integration: X/X passed
- Component Tests: X/X passed
- Full Integration: X/X passed

### Failures
| Test | Component | Error |
|------|-----------|-------|
| TestName | Service | [error] |

### Service Connections
- Redis: OK/FAILED
- Qdrant: OK/FAILED
- Database: OK/FAILED

### Recommendations
1. Check service health
2. Review test configuration
3. Verify test data setup
4. Check transaction rollback
```

## Test Annotations

Use appropriate Spring test annotations:

```java
// Unit integration (mocked dependencies)
@ExtendWith(MockitoExtension.class)
class ServiceTest { ... }

// Component test (real dependencies)
@SpringBootTest
@AutoConfigureTestDatabase
class RepositoryTest { ... }

// Full integration (external services)
@SpringBootTest
@ActiveProfiles("test")
class IntegrationTest { ... }
```

## Testcontainers Example

```java
@Testcontainers
@SpringBootTest
class RedisIntegrationTest {

    @Container
    static RedisContainer redis = new RedisContainer("redis:7");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.redis.host", redis::getHost);
        registry.add("spring.redis.port", redis::getFirstMappedPort);
    }
}
```

## Common Integration Issues

1. **Transaction not rolled back** - Tests affect each other
   - Fix: Use `@Transactional` with rollback

2. **Bean not found** - Test context incomplete
   - Fix: Add `@TestConfiguration` or correct annotations

3. **Connection refused** - Services not available
   - Fix: Start services or use testcontainers

4. **Test order dependency** - Tests fail in certain order
   - Fix: Remove dependencies, use isolation

## Integration with Test Workflow

```
1. verify-build → compile
2. run-tests → unit tests
3. integration-test → integration tests
4. run-e2e-tests → end-to-end tests
```
