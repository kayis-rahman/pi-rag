# Common Patterns

> Shared patterns and conventions for TimeBeam project.

## File Organization

- 200-400 lines typical, 800 max
- Organize by feature/domain, not by type
- One public type per file
- Internal helpers in extension files

## Naming Conventions

- Types: PascalCase (`TimerSyncManager`, `SessionRecordDto`)
- Variables/functions: camelCase (`syncTimerState()`, `userPreferences`)
- Constants: camelCase (Swift 5.1+) or UPPER_SNAKE_CASE (Java)
- Enums: PascalCase, cases: camelCase (`TimerState.running`)
- Protocols: PascalCase, describe capability (`Syncable`, `Loggable`)

## Architecture Layers

### Backend (Spring Boot)
- `presentation/` — REST controllers, DTOs, exception handlers. No business logic.
- `application/` — Services. Business logic only. No direct DB access.
- `domain/` — JPA entities, repositories, enums. No HTTP dependencies.
- `infrastructure/` — External integrations (auth, JWT, config).

### iOS/macOS (Swift)
- `Application/Services/` — Business logic services
- `Domain/Models/` — Core domain models
- `Infrastructure/` — External integrations (networking, Keychain)
- `Presentation/Views/` — UI components

## Error Handling

- Use `do/catch` for recoverable errors
- Never catch-all without handling
- Log error context for debugging

## Concurrency

- Use `async/await` for async operations
- `@MainActor` for UI state
- `Task.detached` for background work

## Testing

- Unit tests: 80%+ line coverage
- Integration tests: cover critical user flows
- Mock external dependencies only
