---
name: user_preferences
description: Coding style, workflow preferences, and tool usage patterns for Synapse project
type: user
---

# Synapse User Preferences

## Coding Style

### Java/Spring Boot
- Use constructor injection with `@RequiredArgsConstructor` (Lombok)
- Never use field injection (`@Autowired` on fields)
- All services return `Mono<T>` or `Flux<T>` - reactive patterns only
- Never call `.block()` in production code
- Use `WebClient` for HTTP, never `RestTemplate`

### Spring AI 1.0.0 API (Critical)
- `ChatModel.call(Prompt)` returns `ChatResponse` (not `String`)
- `ChatModel.stream(Prompt)` returns `Flux<ChatResponse>` (not `Flux<String>`)
- Extract messages via `prompt.getInstructions()` (returns `List<Message>`)
- Build responses: `new ChatResponse(List.of(new Generation(new AssistantMessage(content))))`
- Set options via `Prompt` constructor: `new Prompt(messages, options)`
- Never call `prompt.getMetadata()`, `prompt.getValue()`, or `prompt.getText()`

### Testing
- Unit tests: plain JUnit 5, no Spring context
- Integration tests: `@SpringBootTest` with `@ActiveProfiles("test")`
- Use `StepVerifier` for reactive streams
- Test files mirror `src/main/java` package structure

## Build System
- Gradle wrapper in `app/` directory
- Always run from `app/`: `cd app && ./gradlew <task>`
- Do NOT run `./gradlew` from project root

## Git Workflow
- Use git worktrees for feature isolation
- Branch structure: `main` (production), `develop` (active dev), `feature/*` (features)
- Clean up worktrees after feature completion
- Run `git worktree prune` to remove stale references

## Model Selection
- **Cheap model**: Single file edits, test fixes, simple refactors
- **Standard model**: Multi-file features, integration work, bug fixes
- **Most capable**: Architecture changes, phase planning, code reviews

## Logging
- Logs stored in `app/logs/`
- Log files ignored by git
- Use trace logs for debugging GSD phases
