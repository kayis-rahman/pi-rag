# Java Coding Standards

> Extends [rules/common/patterns.md](../../rules/common/patterns.md) with Java/Spring Boot conventions.

## File Organization
- 200-400 lines typical, 800 max
- Organize by feature/domain
- One public class per file
- Internal helpers as private methods

## Layered Architecture (strict)
- `presentation/` — Controllers, DTOs, exception handlers. No business logic.
- `application/` — Services. Business logic only. No direct DB access.
- `domain/` — Entities, repositories, enums. No HTTP dependencies.
- `infrastructure/` — External integrations, config, utilities.

## Naming Conventions
- Classes: PascalCase (`TimerSyncService`, `TimerActionDto`)
- Methods: camelCase (`syncTimerState()`, `findById()`)
- Variables: camelCase (`timerState`, `userId`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT`)
- Packages: lowercase with dots (`com.sparkage.timebeam.application.service`)

## DTOs
- Use `record` classes for immutable DTOs
- Never return entities from controllers
- Never accept entities in controller methods
- Map entities ↔ DTOs in service layer

## JPA/Hibernate
- Use `@Entity` for domain models
- `@Id` with `@GeneratedValue(strategy = GenerationType.IDENTITY)`
- `@ManyToOne` with `fetch = FetchType.LAZY`
- `@OneToMany` with `mappedBy` — avoid bidirectional unless needed
- Use `@EntityGraph` or `JOIN FETCH` to prevent N+1 queries
- Never access lazy-loaded entities outside transaction

## Transactions
- `@Transactional` on service methods
- Default: `rollbackFor = Exception.class`
- Read-only: `@Transactional(readOnly = true)` for queries
- Don't put `@Transactional` on controllers

## Exception Handling
- Custom exceptions extend `RuntimeException`
- `@RestControllerAdvice` for global exception handling
- Return `ResponseEntity` with appropriate HTTP status
- Log error context: `log.error("message", exception)`

## Dependency Injection
- Constructor injection (required in Spring Boot 3+)
- `@RequiredArgsConstructor` with `final` fields
- Inject interfaces, not implementations

## Cross-Platform DTO Compatibility
- iOS sends `action` (String), Java backend uses `actionType` (enum)
- Always use `@JsonAlias({"action","actionType"})` on enum fields that accept both platforms
- Without `@JsonAlias`, Jackson deserializes null → downstream `remainingSeconds` becomes 0
