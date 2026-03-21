---
name: feedback_development
description: Corrections, improvements, and lessons learned for Synapse development
type: feedback
---

# Development Feedback & Corrections

## Spring AI API Corrections

### Rule: Always use Spring AI 1.0.0 API correctly
**Why:** Previous compilation errors caused by using deprecated `org.springframework.ai.chat.client` API instead of `ChatModel` interface.

**How to apply:**
- Use `ChatModel.call(Prompt)` returning `ChatResponse`
- Use `ChatModel.stream(Prompt)` returning `Flux<ChatResponse>`
- Extract messages via `prompt.getInstructions()`
- Never call `prompt.getMetadata()`, `prompt.getValue()`, or `prompt.getText()`

### Rule: Always invoke `project-conventions` skill before modifying Spring AI code
**Why:** Ensures API compliance and prevents compilation errors.

**How to apply:** When working on `llm/` package files, first invoke `/project-conventions` to review conventions.

## Build System Corrections

### Rule: Always run Gradle from `app/` directory
**Why:** Gradle wrapper is located in `app/`, running from project root causes failures.

**How to apply:** Always use `cd app && ./gradlew <task>` pattern.

## Testing Corrections

### Rule: Use `StepVerifier` for reactive stream tests
**Why:** Plain JUnit assertions don't work with `Mono`/`Flux` streams.

**How to apply:** In test files, use `StepVerifier.create(fluxOrMono).expectNext(...).verifyComplete()` pattern.

## Git Workflow Corrections

### Rule: Clean up worktrees after feature completion
**Why:** Stale worktrees cause confusion and disk space issues.

**How to apply:** After merging feature branch:
1. Delete feature branch locally and remotely
2. Remove worktree directory from `.claude/worktrees/`
3. Run `git worktree prune`

## Code Quality Corrections

### Rule: Use constructor injection, never field injection
**Why:** Field injection makes testing harder and violates Spring best practices.

**How to apply:** Use `@RequiredArgsConstructor` with final fields, never `@Autowired` on fields.

## Reactive Pattern Corrections

### Rule: Never call `.block()` in production code
**Why:** Defeats the purpose of reactive programming and can cause thread pool exhaustion.

**How to apply:** Chain operators (`.map()`, `.flatMap()`, `.switchIfEmpty()`) instead of blocking calls.
