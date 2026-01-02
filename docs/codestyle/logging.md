# Logging Rules

Comprehensive logging standards for TimeBeam across all platforms and technologies.

## Apple's Unified Logging System (iOS/macOS)

TimeBeam uses Apple's Unified Logging System for all iOS and macOS logging, providing high-performance, privacy-compliant, and structured logging capabilities.

### Framework Requirements
- **ALWAYS use AppLogger** instead of `print()`, `NSLog()`, or `os_log` directly
- **NEVER use LoggerStore** or any other custom logging utilities
- **ALWAYS specify category** for proper organization and filtering
- **ONLY use DEBUG level in development** - automatically disabled in production builds

### Log Categories
- `auth` - Authentication events, login/logout, token operations, user sessions
- `sync` - Timer synchronization, backend communication, state merging, conflict resolution
- `timer` - Pomodoro timer events, phase changes, session tracking, duration updates
- `api` - HTTP requests, responses, network operations, error handling
- `lifecycle` - App lifecycle, view appearances, background tasks, memory management
- `ui` - User interactions, button taps, navigation, gesture recognition
- `general` - Everything else, utility functions, configuration changes

### Log Levels
- `DEBUG` - Detailed development information, method entry/exit, variable values (disabled in production)
- `INFO` - General operational information, successful operations, state changes
- `WARNING` - Potential issues that don't stop execution but require attention
- `ERROR` - Actual errors requiring immediate action, failed operations
- `FAULT` - Critical errors that may cause system instability or crashes

### Privacy Controls
- **ALWAYS use `privacy: .public`** for non-sensitive information
- **ALWAYS use `privacy: .private`** for emails, tokens, user IDs, personal information
- **NEVER log passwords, API keys, or other secrets** even with privacy controls
- **AUTO-REDACTION**: Apple's logging system automatically scrubs sensitive data in production logs

### Structured Logging
Use helper methods for consistent, structured logging:

```swift
// ✅ Good: Structured auth logging
AppLogger.logAuthEvent("login_successful", userId: "user123")

// ✅ Good: Structured sync logging
AppLogger.logSyncEvent("timer_state_merged", details: "local_newer_by_5min")

// ✅ Good: Structured timer logging
AppLogger.logTimerEvent("phase_changed", phase: "work")

// ✅ Good: Privacy-aware logging
AppLogger.infoWithPrivate("Token refreshed", privateData: "token_abc123", category: .auth)
```

### Best Practices
- **Context-rich messages**: Include relevant IDs, states, and timestamps
- **Consistent formatting**: Use standard patterns across similar operations
- **Performance aware**: Avoid logging in tight loops or performance-critical code
- **Search friendly**: Use descriptive messages that are easy to grep
- **Correlation IDs**: Include request IDs or session IDs for tracing
- **Error context**: Always include stack traces and contextual information for errors

### Examples

#### ✅ CORRECT USAGE
```swift
// Authentication logging
AppLogger.logAuthEvent("google_login_initiated")
AppLogger.info("Backend login API call initiated", category: .api)
AppLogger.logAuthEvent("login_successful", userId: "user123")

// Timer synchronization
AppLogger.logSyncEvent("smart_sync_started")
AppLogger.debug("Local timestamp: 2025-01-15T10:30:00Z", category: .sync)
AppLogger.logSyncEvent("backend_state_newer", details: "applying_remote_changes")

// Timer operations
AppLogger.logTimerEvent("timer_started", phase: "work")
AppLogger.logTimerEvent("phase_transition", phase: "break")

// API operations
AppLogger.logAPIEvent("timer_state_pull_requested", url: "/api/sessions/timer/state")
AppLogger.error("API request failed: timeout", category: .api)

// Privacy-aware logging
AppLogger.infoWithPrivate("User session created", privateData: "session_id_abc123", category: .auth)
```

#### ❌ INCORRECT USAGE
```swift
// Bad: Missing category
print("User logged in successfully")

// Bad: Using LoggerStore
LoggerStore.timer.info("Timer started")

// Bad: Direct os_log usage
os_log(.info, "Timer synced")

// Bad: Exposing sensitive data
AppLogger.info("User \(email) logged in", category: .auth)

// Bad: Unstructured messages
AppLogger.info("Something happened", category: .general)
```

### Performance Guidelines
- **DEBUG logs**: Only active in DEBUG builds, zero production overhead
- **INFO/WARN/ERROR**: Minimal performance impact, suitable for production
- **Avoid string interpolation in tight loops**: Use conditional logging
- **Batch similar logs**: Group related operations into single log entries

## SLF4J Logging (Java Backend)

TimeBeam backend uses SLF4J (Simple Logging Facade for Java) as the logging abstraction layer, with Logback as the implementation.

### Framework Requirements
- **ALWAYS use SLF4J** instead of direct framework logging (Log4j, java.util.logging)
- **NEVER use System.out.println()** or System.err.println() in production code
- **ALWAYS use parameterized logging** to avoid string concatenation overhead
- **ALWAYS use logger instances** per class, not static loggers

### Logger Declaration
```java
// ✅ Correct: Private static final logger per class
private static final Logger logger = LoggerFactory.getLogger(MyClass.class);

// ❌ Wrong: Direct instantiation
private Logger logger = LoggerFactory.getLogger("com.example.MyClass");
```

### Log Levels
- `TRACE` - Most detailed, method entry/exit, variable dumps
- `DEBUG` - Development debugging, detailed operation information
- `INFO` - General operational information, successful operations
- `WARN` - Potential issues that don't stop execution
- `ERROR` - Actual errors requiring immediate attention

### Parameterized Logging
```java
// ✅ Good: Parameterized logging (efficient)
logger.info("User {} logged in from IP {}", userId, ipAddress);

// ❌ Bad: String concatenation (inefficient)
logger.info("User " + userId + " logged in from IP " + ipAddress);
```

### Exception Logging
```java
// ✅ Good: Include exception with context
try {
    processUserData(userData);
} catch (ValidationException e) {
    logger.error("Failed to process user data for user {}", userId, e);
}

// ✅ Good: Warn level for expected exceptions
catch (TimeoutException e) {
    logger.warn("Timeout occurred while processing user {}, retrying", userId, e);
}
```

### Security Considerations
- **NEVER log sensitive data**: passwords, API keys, credit card numbers, PII
- **ALWAYS mask sensitive information** before logging
- **IMPLEMENT proper log rotation** and retention policies
- **AVOID logging complete objects** that may contain sensitive data

### MDC (Mapped Diagnostic Context)
Use MDC for request tracing and contextual information:

```java
// Set context at request start
MDC.put("requestId", UUID.randomUUID().toString());
MDC.put("userId", userId);

// Log with automatic context inclusion
logger.info("Processing user request");

// Clear context at request end
MDC.clear();
```

### Configuration (logback-spring.xml)
```xml
<configuration>
  <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>logs/timebeam.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <fileNamePattern>logs/timebeam.%d{yyyy-MM-dd}.log</fileNamePattern>
      <maxHistory>30</maxHistory>
    </rollingPolicy>
    <encoder>
      <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <root level="INFO">
    <appender-ref ref="CONSOLE"/>
    <appender-ref ref="FILE"/>
  </root>

  <!-- Package-specific levels -->
  <logger name="com.sparkage.timebeam" level="DEBUG"/>
  <logger name="org.springframework.security" level="WARN"/>
</configuration>
```

### Best Practices
- **Use appropriate log levels**: Don't log everything as INFO
- **Include context**: Add user IDs, request IDs, operation details
- **Log exceptions properly**: Include stack traces for ERROR level
- **Avoid performance impact**: Use conditional logging for expensive operations
- **Structured logging**: Use consistent message formats
- **Log rotation**: Implement proper log file management
- **Monitoring integration**: Ensure logs work with your monitoring stack

## Cross-Platform Consistency

### Message Format Standards
- **English only**: All log messages in English for consistency
- **Descriptive**: Clear, actionable messages
- **Contextual**: Include relevant IDs and states
- **Consistent tense**: Use present tense for ongoing actions

### Correlation and Tracing
- **Request IDs**: Include correlation IDs across service boundaries
- **Session tracking**: Maintain session context in logs
- **User context**: Include user IDs for user-specific operations
- **Operation chaining**: Link related operations across services

### Production vs Development
- **Development**: DEBUG enabled, detailed logging
- **Production**: INFO+, privacy enforced, performance optimized
- **Testing**: Appropriate levels for CI/CD pipelines

## Compliance and Security

### GDPR/CCPA Compliance
- **Data minimization**: Only log necessary information
- **Retention policies**: Implement automatic log deletion
- **Access controls**: Restrict log access to authorized personnel
- **Audit trails**: Maintain immutable logs for compliance

### Security Best Practices
- **No sensitive data**: Never log passwords, tokens, keys
- **Encryption**: Encrypt logs at rest and in transit
- **Integrity**: Implement log tampering detection
- **Monitoring**: Alert on suspicious logging patterns

## Performance Optimization

### Async Logging
- **Enable async appenders** for high-throughput scenarios
- **Buffer management**: Configure appropriate buffer sizes
- **Thread safety**: Ensure thread-safe logging operations

### Log Level Management
- **Runtime adjustment**: Support dynamic log level changes
- **Conditional logging**: Avoid expensive operations in disabled levels
- **Sampling**: Implement log sampling for high-frequency operations

### Resource Management
- **File rotation**: Implement size and time-based rotation
- **Compression**: Enable log compression for storage efficiency
- **Cleanup**: Automatic deletion of old log files

## Integration with Monitoring Tools

### ELK Stack Integration
- **Structured JSON**: Output logs in JSON format for Elasticsearch
- **Index patterns**: Use consistent field naming
- **Mapping templates**: Define field types for efficient querying

### Alerting Integration
- **Error patterns**: Define alerts for specific error conditions
- **Threshold monitoring**: Alert on unusual log volumes
- **Performance metrics**: Extract performance data from logs

This logging framework ensures TimeBeam has professional-grade observability, security compliance, and debugging capabilities across all platforms.
