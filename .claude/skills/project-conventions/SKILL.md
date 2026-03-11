---
name: project-conventions
description: Synapse project coding conventions - invoke before modifying Spring AI components, writing new services, or adding tests
user-invocable: false
---

# Synapse Project Conventions

## Package Structure
- `llm/` — LLM routing, model config, chat services
- `memory/` — episodic, semantic, knowledgegraph sub-packages
- `agent/` — developer assistant and tools
- `embedding/` — embedding services and configuration
- `workflow/` — task continuity and session management
- `config/` — cross-cutting configuration (Netty, etc.)

## Spring Style
- All services use `@Service` + constructor injection via Lombok `@RequiredArgsConstructor`
- Configuration properties use `@ConfigurationProperties` with Lombok `@Data` or `@Getter`
- Never use field injection (`@Autowired` on fields)

## Reactive Patterns
- Service methods return `Mono<T>` or `Flux<T>` — never use `.block()` in production code
- Use `WebClient` for HTTP, never `RestTemplate`
- Chain operators (`.map()`, `.flatMap()`, `.switchIfEmpty()`) — avoid imperative style

## Spring AI 1.0.0 API (CRITICAL — repeated source of compilation errors)
- `ChatModel.call(Prompt)` returns `ChatResponse` (not `String`)
- `ChatModel.stream(Prompt)` returns `Flux<ChatResponse>` (not `Flux<String>`)
- Extract messages from `Prompt` via `prompt.getInstructions()` which returns `List<Message>`
- Build `ChatResponse` using `new ChatResponse(List.of(new Generation(new AssistantMessage(content))))`
- `ChatOptions` is set via `Prompt` constructor: `new Prompt(messages, options)`
- Never call `prompt.getMetadata()`, `prompt.getValue()`, or `prompt.getText()` — these don't exist

## Testing
- Unit tests: plain JUnit 5, no Spring context unless integration
- Integration tests: `@SpringBootTest` with `@ActiveProfiles("test")`
- Use `StepVerifier` for reactive streams in tests
- Test files mirror `src/main/java` package structure under `src/test/java`

## Build
- Gradle wrapper lives in `app/` — always run from `app/` directory: `cd app && ./gradlew <task>`
- Do NOT run `./gradlew` from the project root
