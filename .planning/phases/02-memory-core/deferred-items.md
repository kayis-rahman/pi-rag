# Deferred Items - Phase 02 Memory Core

## Pre-existing Test Compilation Errors

### Scope
These are pre-existing failures in other test files, not caused by this plan's changes.

### Affected Tests
- `CircuitBreakerIntegrationTest.java` - ChatResponse class not found
- `RoutingSystemE2EIntegrationTest.java` - Multiple symbol resolution errors (lastDecision, tier methods)
- `AdaptiveRoutingStrategyTest.java` - Type incompatibility in RoutingDecision.decide() method
- Other test files with LangChain4j integration issues

### Root Cause
These tests appear to have been written against an older API version of LangChain4j or Spring AI. The interfaces they reference (ChatResponse, RoutingDecision methods) no longer exist or have changed signatures.

### Impact
- Cannot run test suite with `gradle test` command
- Must run specific test classes individually
- Main code (non-test) compiles successfully

### Recommended Fix
- Update affected test files to match current LangChain4j/Spring AI API
- Or disable broken tests with `@Disabled` annotation temporarily
- This should be addressed in a separate "Fix Test Suite" task

### Not Fixed In This Plan
Per deviation rules (scope boundary): Only fix issues directly caused by current task changes. Pre-existing test failures are out of scope.
