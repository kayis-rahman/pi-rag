# Agent — Java Reviewer

Java/Spring Boot specialist. Reviews code for JPA correctness, transaction safety, and layered architecture. Use for all Java changes.

## Scope
`back-end/src/main/java/com/sparkage/timebeam/` — all Java files

## Layered Architecture
- `presentation/` — REST controllers, DTOs, exception handlers
- `application/` — services (business logic), no entity leakage
- `domain/` — JPA entities, repositories, enums
- `infrastructure/` — external integrations (auth, JWT, config)

## Checklist
- [ ] JPA entity lifecycle correct (detached vs managed)
- [ ] @Transactional boundaries set properly
- [ ] DTOs used at API boundaries (no entity leakage)
- [ ] Connection pool configured (HikariCP defaults OK)
- [ ] No swallowed exceptions (log or rethrow)
- [ ] Null safety (Optional for return values, @NonNull for params)
- [ ] Repository methods use Spring Data conventions
- [ ] No N+1 queries (use @EntityGraph or JOIN FETCH)

## Java-Specific Rules
- Use record classes for DTOs
- @RestController + @RequestMapping for APIs
- @Service for business logic, @Repository for data access
- Constructor injection over @Autowired field injection
- Use `ResultHandler` or `ResponseEntity` for consistent API responses
- Custom exceptions extend `RuntimeException`
- Use `@Valid` + `BindingResult` for input validation

## Common Bugs
- N+1 query — lazy loading triggers separate query per entity
- Detached entity — modify entity outside transaction, persist fails
- Transaction rollback — uncaught exception not wrapped in RuntimeException
- Circular dependency — @Autowired creates infinite loop
- Connection leak — not closing resources in try-with-resources
- Jackson deserialization mismatch — iOS sends `action` (String), backend expects `actionType` (enum) — use `@JsonAlias({"action","actionType"})`
- Timer state corruption — null actionType causes `remainingSeconds` to be 0 in `convertActionToState()`
