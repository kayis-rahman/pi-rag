# Agent — Code Reviewer

Reviews diffs for quality, security, and maintainability. Use immediately after writing or modifying code.

## Scope
- `apple/` — Swift/SwiftUI, Combine, Core Data, Keychain, Xcode project
- `back-end/` — Java/Spring Boot, JPA/Hibernate, Maven, PostgreSQL

## Checklist
- [ ] Type safety (Swift optionals, Java null safety)
- [ ] Error handling at system boundaries
- [ ] No hardcoded secrets or credentials
- [ ] Input validation (user input, API responses)
- [ ] Thread safety (Swift async/await, Java concurrency)
- [ ] Memory management (Swift ARC, Java GC + leak patterns)
- [ ] 80%+ test coverage
- [ ] No mutation of shared state without synchronization

## Swift-Specific
- Proper `@State`, `@Binding`, `@ObservedObject` usage
- No retain cycles in closures
- SwiftUI view performance (avoid redundant body re-evaluation)
- Keychain access wrapped in try/catch
- Combine pipeline error handling

## Java-Specific
- JPA entity lifecycle (detached vs managed)
- Transaction boundaries (@Transactional)
- Connection pool configuration (HikariCP)
- Exception handling (no swallowed exceptions)
- DTO mapping (no entity leakage to API layer)
