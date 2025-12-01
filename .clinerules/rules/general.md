# General Clean Code Rules

Universal clean code principles applied across all languages and frameworks in TimeBeam.

## Domain-Driven Design (DDD) Architecture

### DDD Layered Architecture
All technologies in TimeBeam should follow DDD principles with clear separation of concerns:

#### 1. Domain Layer
- **Purpose**: Contains business logic and domain knowledge
- **Contents**: Entities, Value Objects, Domain Services, Business Rules
- **Principles**: Pure business logic, no external dependencies

#### 2. Application Layer
- **Purpose**: Orchestrates domain objects for use cases
- **Contents**: Application Services, Commands, Queries, DTOs
- **Principles**: Thin layer coordinating domain objects

#### 3. Infrastructure Layer
- **Purpose**: Technical implementations and external concerns
- **Contents**: Repositories, External APIs, Persistence, Configuration
- **Principles**: Implements interfaces defined in domain/application layers

#### 4. Presentation Layer
- **Purpose**: External interfaces and user interaction
- **Contents**: Controllers, Views, APIs, UI Components
- **Principles**: Thin adapters to application layer

### DDD Benefits in TimeBeam
- **Business Focus**: Code organized around business domains
- **Testability**: Clear boundaries between layers
- **Maintainability**: Changes isolated to appropriate layers
- **Scalability**: Independent deployment of layers
- **Consistency**: Unified architecture across technologies

## SOLID Principles

### Single Responsibility Principle (SRP)
- Each class/service should have one reason to change
- Example: `AuthService` handles only authentication logic, not user management

### Open/Closed Principle (OCP)
- Classes should be open for extension, closed for modification
- Use interfaces and abstract classes for extensibility

### Liskov Substitution Principle (LSP)
- Subtypes must be substitutable for their base types
- Ensure inheritance hierarchies maintain contract compatibility

### Interface Segregation Principle (ISP)
- Clients should not be forced to depend on interfaces they don't use
- Prefer small, focused interfaces over large ones

### Dependency Inversion Principle (DIP)
- Depend on abstractions, not concretions
- Use dependency injection for loose coupling

## DRY, KISS, YAGNI

- **DRY**: Don't Repeat Yourself - eliminate code duplication
- **KISS**: Keep It Simple, Stupid - prefer simple solutions
- **YAGNI**: You Aren't Gonna Need It - don't implement unnecessary features

## Code Quality Standards

### Naming Conventions
- Use descriptive, meaningful names
- Avoid generic names like `temp`, `data`, `value`
- Use consistent casing (camelCase, PascalCase, UPPER_SNAKE_CASE)

### Function/Method Length
- Keep functions focused and concise
- Maximum 50 lines per function
- Break down complex functions into smaller, focused methods

### Class/File Length
- Classes should follow single responsibility principle
- Maximum 300 lines per class file
- Consider splitting large classes into smaller components

### Documentation
- Code should be self-documenting with clear naming
- Add comments for complex business logic
- Document public APIs and complex algorithms

## Testing Standards

### Test Coverage
- Maintain minimum 80% test coverage
- Test all critical paths and edge cases
- Include integration tests for API endpoints

### Test Quality
- Write descriptive test names
- Test one thing per test method
- Use appropriate mocking for dependencies
- Include both positive and negative test cases

## Performance Considerations

### Efficiency
- Write efficient algorithms (avoid O(n²) complexity)
- Consider memory usage and CPU overhead
- Profile performance-critical code paths

### Resource Management
- Properly close resources (database connections, file handles)
- Use connection pooling for database access
- Implement proper caching strategies

## Error Handling

### Consistent Error Patterns
- Use consistent error handling across the application
- Provide meaningful error messages
- Log errors appropriately without exposing sensitive information

### Exception Safety
- Ensure resources are properly cleaned up on errors
- Use try-with-resources or similar patterns
- Handle errors at appropriate levels in the call stack

## Logging Standards

### Log Levels
- DEBUG: Detailed information for debugging
- INFO: General information about application operation
- WARN: Warning messages about potential issues
- ERROR: Error conditions that don't stop execution
- FATAL: Critical errors that may stop the application

### Log Content
- Include contextual information in log messages
- Never log sensitive data (passwords, tokens, personal information)
- Use structured logging where possible
- Include correlation IDs for request tracing

## Security Best Practices

### Input Validation
- Validate all user inputs
- Use allowlists rather than blocklists
- Sanitize data before processing

### Secure Coding
- Avoid hardcoding secrets
- Use secure random number generation
- Implement proper access controls
- Follow principle of least privilege

## Maintenance

### Technical Debt
- Address technical debt regularly
- Refactor code when complexity increases
- Keep dependencies up to date
- Monitor code quality metrics

### Code Reviews
- All code changes require review
- Review for adherence to these standards
- Check for security vulnerabilities
- Verify test coverage and quality
