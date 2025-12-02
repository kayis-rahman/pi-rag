# Java Clean Code Rules

Language-specific rules for Java development in TimeBeam.

## Domain-Driven Design (DDD) Structure

### Recommended Folder Structure
```
src/main/java/com/sparkage/timebeam/
├── domain/                    # Domain Layer
│   ├── model/                # Entities, Value Objects, Aggregates
│   ├── service/              # Domain Services
│   ├── event/                # Domain Events
│   └── repository/           # Domain Repository Interfaces
├── application/               # Application Layer
│   ├── service/              # Application Services
│   ├── command/              # Commands/Queries
│   └── dto/                  # Application DTOs
├── infrastructure/            # Infrastructure Layer
│   ├── persistence/          # Repository Implementations
│   ├── external/             # External Service Integrations
│   └── config/               # Configuration
└── presentation/              # Presentation Layer
    ├── controller/           # REST Controllers
    └── dto/                  # Presentation DTOs
```

### Layer Responsibilities
- **Domain**: Business logic, rules, and constraints
- **Application**: Orchestrates domain objects for use cases
- **Infrastructure**: Technical implementations (DB, external APIs)
- **Presentation**: External interfaces (REST APIs, web)

## Exception Handling
- **NEVER return `null`** from methods that can fail
- **ALWAYS throw custom exceptions** instead of generic ones
- **ALWAYS validate inputs** before processing
- **ALWAYS mask sensitive data** in logs (emails, tokens, passwords)

## Service Layer Rules
- **Use constructor injection** over field injection
- **Throw exceptions** instead of returning null
- **Validate all inputs** with Bean Validation
- **Log at appropriate levels** (DEBUG for sensitive operations)

## Import Rules
- **Use explicit imports** instead of fully qualified class names in extends and implements clauses
- **Import statements** should be placed at the top of the file, after package declaration
- **Group imports** logically (standard library, third-party, project-specific)

## Controller Rules
- **Delegate business logic** to services
- **Use ResponseEntity** for flexible responses
- **Validate inputs** with `@Valid`
- **Handle exceptions** through global exception handler

## Examples

### Bad: Returning null
```java
public User findUser(String id) {
    return null; // NEVER do this
}
```

### Good: Throwing exceptions
```java
public User findUser(String id) {
    return userRepository.findById(id)
        .orElseThrow(() -> new UserNotFoundException("User not found: " + id));
}
```

### Bad: Logging sensitive data
```java
log.info("User login: {}", email);
```

### Good: Masking sensitive data
```java
log.info("User login: {}", maskEmail(email));
```

### Good: Explicit imports
```java
import javax.swing.JFrame;
import java.util.List;

public class LineTest extends JFrame implements List {
```

### Bad: Fully qualified class names
```java
public class LineTest extends javax.swing.JFrame implements java.util.List {
```
