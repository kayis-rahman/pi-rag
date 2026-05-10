---
phase: 05-tasks-tab
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java
  - back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java
  - back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskDto.java
  - back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskProgressResponseDto.java
  - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecordRepository.java
  - apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift
autonomous: true
requirements:
  - TBD
user_setup: []

must_haves:
  truths:
    - TaskService.listForUser excludes soft-deleted tasks by using findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc
    - TaskService.listActiveTasksForUser excludes soft-deleted tasks by using findActiveNonDeletedTasksByUserId
    - TaskService.delete performs soft delete via task.softDelete() + repository.save(task) instead of hard delete
    - TaskService provides softDelete, restore, and listDeletedTasks methods that verify user ownership
    - TaskService provides getTaskProgress method that counts completed WORK sessions and sums durationSeconds
    - TaskController exposes POST /api/tasks/{id}/soft-delete, POST /api/tasks/{id}/restore, GET /api/tasks/deleted, GET /api/tasks/{id}/progress
    - TaskDto includes deletedAt field (Instant) with getter and setter
    - TaskProgressResponseDto contains completedSessions (Integer), totalTimeSpentSeconds (Long), progressPercentage (Double)
    - SessionRecordRepository provides findByTaskIdAndKindAndCompletedTrue query method
    - ApiClient.fetchTask, updateTask, deleteTask use "api/tasks/{id}" path (not "tasks/{id}")
  artifacts:
    - path: "back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java"
      provides: "Fixed CRUD + soft-delete + restore + progress service methods"
      exports: ["listForUser", "listActiveTasksForUser", "delete", "softDelete", "restore", "listDeletedTasks", "getTaskProgress"]
    - path: "back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java"
      provides: "Task CRUD + soft-delete + restore + deleted + progress endpoints"
      exports: ["POST /api/tasks/{id}/soft-delete", "POST /api/tasks/{id}/restore", "GET /api/tasks/deleted", "GET /api/tasks/{id}/progress"]
    - path: "back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskDto.java"
      provides: "Task DTO with deletedAt field"
      contains: "id, userId, title, description, status, createdAt, updatedAt, deletedAt"
    - path: "back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskProgressResponseDto.java"
      provides: "Task progress response DTO"
      contains: "completedSessions, totalTimeSpentSeconds, progressPercentage"
    - path: "back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecordRepository.java"
      provides: "SessionRecord query by taskId for progress tracking"
      exports: ["findByTaskIdAndKindAndCompletedTrue"]
    - path: "apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift"
      provides: "Fixed task API paths with api/ prefix"
      contains: "api/tasks/{id} path in fetchTask, updateTask, deleteTask"
  key_links:
    - from: "back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java"
      to: "back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java"
      via: "dependency injection"
      pattern: "Autowired.*TaskService"
    - from: "back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java"
      to: "back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/TaskRepository.java"
      via: "task persistence"
      pattern: "repository.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc"
    - from: "back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java"
      to: "back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecordRepository.java"
      via: "progress queries"
      pattern: "sessionRecordRepository.findByTaskIdAndKindAndCompletedTrue"
    - from: "back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java"
      to: "back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskProgressResponseDto.java"
      via: "response body"
      pattern: "new TaskProgressResponseDto"
---

<objective>
Fix existing backend bugs (soft-delete visibility, hard-delete behavior, API path prefix) and add new endpoints (soft-delete, restore, deleted-list, task-progress) to unblock Wave 2+ client work.
</objective>

<execution_context>
@/Users/kayisrahman/.claude/get-shit-done/workflows/execute-plan.md
@/Users/kayisrahman/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/05-tasks-tab/05-CONTEXT.md
@.planning/phases/05-tasks-tab/05-RESEARCH.md

# Backend Stack
- Spring Boot 3.x
- Java 17+
- PostgreSQL database (H2 for testing)
- Maven build system
- MapStruct for DTO mapping

# Existing Code State
- Task entity has `deletedAt` field, `softDelete()`, `restore()`, `isSoftDeleted()` domain methods (fully implemented)
- TaskRepository has soft-delete aware queries (`findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc`, `findActiveNonDeletedTasksByUserId`, `findByUserIdAndDeletedAtIsNotNullOrderByDeletedAtDesc`)
- TaskService uses wrong repository methods (includes soft-deleted), does hard delete, missing softDelete/restore/listDeletedTasks/getTaskProgress
- TaskController missing soft-delete, restore, deleted, progress endpoints
- TaskDto missing `deletedAt` field
- SessionRecordRepository has only `findByUserIdOrderByStartedAtDesc` — missing taskId query
- ApiClient.swift has path bugs: `fetchTask`, `updateTask`, `deleteTask` use `"tasks/{id}"` instead of `"api/tasks/{id}"`

# Coding Conventions
- Java: constructor injection, `@Transactional` on service methods, `@RestControllerAdvice` for errors
- Swift: paths use `api/` prefix (e.g., `"api/tasks"`, `"api/tasks/{id}"`)
- All endpoints verify user owns the task via `principal.getName()` resolved to UUID

# Threat Model
## Authorization
- All new endpoints (`POST /{id}/soft-delete`, `POST /{id}/restore`, `GET /tasks/deleted`, `GET /{id}/progress`) must verify the authenticated user owns the task being modified.
- The existing `resolveUserId(Principal)` pattern in TaskController extracts user UUID from the principal. All new methods must use this pattern.
- `GET /tasks/deleted` must only return the current user's own soft-deleted tasks — never another user's.

## Soft-Delete Visibility
- `listForUser` must exclude tasks where `deletedAt IS NOT NULL`.
- `listActiveTasksForUser` must exclude tasks where `deletedAt IS NOT NULL`.
- `listDeletedTasks` must only return tasks where `deletedAt IS NOT NULL` for the requesting user.
- Cross-user soft-delete visibility is a data leak — enforce user ownership on every query.

## Input Validation
- Path variable `{id}` must be a valid UUID (Spring MVC binding handles this, but 400 on malformed input is expected).
- All endpoints require authentication (`@PreAuthorize("isAuthenticated()")` is set on the controller class).
- `TaskProgressResponseDto` should not expose any sensitive user data beyond progress metrics.

</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix existing TaskService bugs</name>
  <files>back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java</files>
  <read_first>
    - back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java (file being modified)
    - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/TaskRepository.java (source of truth — available query method signatures)
    - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/Task.java (source of truth — softDelete() domain method)
  </read_first>
  <action>
    1. In `listForUser` (line 50-54): Replace `repository.findByUserIdOrderByCreatedAtDesc(userId)` with `repository.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(userId)`.
    2. In `listActiveTasksForUser` (line 57-61): Replace `repository.findActiveTasksByUserId(userId)` with `repository.findActiveNonDeletedTasksByUserId(userId)`.
    3. In `delete` (line 102-113): Replace `repository.deleteById(id)` with `task.softDelete(); repository.save(task);`. Keep the ownership check (line 108-110). Update the log message from "Task deleted" to "Task soft-deleted".
  </action>
  <acceptance_criteria>
    - The string `findByUserIdOrderByCreatedAtDesc` does NOT appear in TaskService.java (it has been replaced).
    - The string `findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc` appears in the `listForUser` method body.
    - The string `findActiveNonDeletedTasksByUserId` appears in the `listActiveTasksForUser` method body.
    - The string `repository.deleteById` does NOT appear anywhere in TaskService.java.
    - The string `task.softDelete()` appears in the `delete` method body.
    - The string `repository.save(task)` appears in the `delete` method body after `task.softDelete()`.
    - `cd back-end && mvn test` passes all existing tests (no regressions).
    - `cd back-end && mvn compile` succeeds with zero errors.
  </acceptance_criteria>
  <verify>TaskService.java contains updated repository calls; mvn compile succeeds; mvn test passes</verify>
  <done>listForUser excludes soft-deleted, listActiveTasksForUser excludes soft-deleted, delete performs soft delete</done>
</task>

<task type="auto">
  <name>Task 2: Add soft-delete endpoints to TaskService and TaskController</name>
  <files>
    back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java
    back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java
    back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskDto.java
  </files>
  <read_first>
    - back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java (file being modified — read after Task 1 changes)
    - back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java (file being modified — existing endpoint patterns)
    - back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskDto.java (file being modified — add deletedAt field)
    - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/Task.java (source of truth — softDelete(), restore() domain methods)
    - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/TaskRepository.java (source of truth — findByUserIdAndDeletedAtIsNotNullOrderByDeletedAtDesc query)
    - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/TaskMapper.java (source of truth — MapStruct auto-maps deletedAt)
  </read_first>
  <action>
    1. In `TaskDto.java`: Add `private Instant deletedAt` field. Add `getDeletedAt()` and `setDeletedAt(Instant deletedAt)` methods. The MapStruct mapper will auto-map this from `Task.deletedAt`.
    2. In `TaskService.java`: Add three new methods:
       - `public TaskDto softDelete(UUID id, UUID userId)` — find task by id, throw `ResourceNotFoundException.taskNotFound(id.toString())` if not found, verify `!task.getUserId().equals(userId)` throws `IllegalArgumentException("Task does not belong to user")`, call `task.softDelete()`, `repository.save(task)`, return `mapper.toDto(saved)`.
       - `public TaskDto restore(UUID id, UUID userId)` — same ownership check pattern, call `task.restore()`, `repository.save(task)`, return `mapper.toDto(saved)`.
       - `public List<TaskDto> listDeletedTasks(UUID userId)` — call `repository.findByUserIdAndDeletedAtIsNotNullOrderByDeletedAtDesc(userId)`, map to DTOs with `mapper.toDto`.
    3. In `TaskController.java`: Add three new endpoints:
       - `@PostMapping("/{id}/soft-delete")` — `softDelete(@PathVariable("id") UUID id, Principal principal)`. Resolve userId via `resolveUserId(principal)`, return 401 if null, call `taskService.softDelete(id, uid)`, return `ResponseEntity.ok(dto)`.
       - `@PostMapping("/{id}/restore")` — `restore(@PathVariable("id") UUID id, Principal principal)`. Same pattern, call `taskService.restore(id, uid)`, return `ResponseEntity.ok(dto)`.
       - `@GetMapping("/deleted")` — `listDeleted(Principal principal)`. Resolve userId, return `ResponseEntity.ok(taskService.listDeletedTasks(uid))`.
  </action>
  <acceptance_criteria>
    - `TaskDto.java` contains `private Instant deletedAt` field declaration.
    - `TaskDto.java` contains `getDeletedAt()` method returning `Instant`.
    - `TaskDto.java` contains `setDeletedAt(Instant deletedAt)` method.
    - `TaskService.java` contains `public TaskDto softDelete(UUID id, UUID userId)` method signature.
    - `TaskService.java` contains `public TaskDto restore(UUID id, UUID userId)` method signature.
    - `TaskService.java` contains `public List<TaskDto> listDeletedTasks(UUID userId)` method signature.
    - Both `softDelete` and `restore` methods in TaskService contain `task.getUserId().equals(userId)` ownership check.
    - `softDelete` method calls `task.softDelete()` and `repository.save`.
    - `restore` method calls `task.restore()` and `repository.save`.
    - `listDeletedTasks` method calls `findByUserIdAndDeletedAtIsNotNullOrderByDeletedAtDesc`.
    - `TaskController.java` contains `@PostMapping("/{id}/soft-delete")` annotation.
    - `TaskController.java` contains `@PostMapping("/{id}/restore")` annotation.
    - `TaskController.java` contains `@GetMapping("/deleted")` annotation.
    - `cd back-end && mvn compile` succeeds with zero errors.
    - `cd back-end && mvn test` passes all tests.
  </acceptance_criteria>
  <verify>TaskDto has deletedAt field; TaskService has softDelete/restore/listDeletedTasks; TaskController has 3 new endpoints; mvn compile + test pass</verify>
  <done>Soft-delete, restore, and deleted-list endpoints return correct responses with user ownership verification</done>
</task>

<task type="auto">
  <name>Task 3: Add task progress endpoint</name>
  <files>
    back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecordRepository.java
    back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskProgressResponseDto.java
    back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java
    back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java
  </files>
  <read_first>
    - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecordRepository.java (file being modified — add query)
    - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecord.java (source of truth — taskId, kind, completed, durationSeconds fields)
    - back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java (file being modified — add getTaskProgress)
    - back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java (file being modified — add endpoint)
    - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/Task.java (source of truth — Status enum)
  </read_first>
  <action>
    1. In `SessionRecordRepository.java`: Add query method `List<SessionRecord> findByTaskIdAndKindAndCompletedTrue(UUID taskId, SessionRecord.Kind kind);` to count completed WORK sessions per task.
    2. Create `TaskProgressResponseDto.java` in `back-end/src/main/java/com/sparkage/timebeam/presentation/dto/` package with:
       - `private int completedSessions` (with getter/setter)
       - `private long totalTimeSpentSeconds` (with getter/setter)
       - `private double progressPercentage` (with getter/setter)
       - No-arg constructor and all-args constructor.
    3. In `TaskService.java`: Add `private final SessionRecordRepository sessionRecordRepository` field. Update constructor to accept `SessionRecordRepository`. Add method:
       - `public TaskProgressResponseDto getTaskProgress(UUID taskId, UUID userId)` — First verify task exists and belongs to user by calling `getById(taskId, userId)` (reuse existing method). Then query `sessionRecordRepository.findByTaskIdAndKindAndCompletedTrue(taskId, SessionRecord.Kind.WORK)`. Calculate `completedSessions` as `sessions.size()`. Calculate `totalTimeSpentSeconds` by summing `session.getDurationSeconds()` for all sessions. Calculate `progressPercentage` as `(completedSessions / 4.0) * 100.0` (default 4 estimated sessions) capped at 100.0. Return `new TaskProgressResponseDto(completedSessions, totalTimeSpentSeconds, Math.min(progressPercentage, 100.0))`.
    4. In `TaskController.java`: Add endpoint:
       - `@GetMapping("/{id}/progress")` — `getProgress(@PathVariable("id") UUID id, Principal principal)`. Resolve userId via `resolveUserId(principal)`, return 401 if null, call `taskService.getTaskProgress(id, uid)`, return `ResponseEntity.ok(response)`.
  </action>
  <acceptance_criteria>
    - `SessionRecordRepository.java` contains `findByTaskIdAndKindAndCompletedTrue` method signature accepting `(UUID taskId, SessionRecord.Kind kind)`.
    - `TaskProgressResponseDto.java` exists in `com.sparkage.timebeam.presentation.dto` package.
    - `TaskProgressResponseDto.java` contains `completedSessions` (int), `totalTimeSpentSeconds` (long), `progressPercentage` (double) fields with getters and setters.
    - `TaskService.java` constructor includes `SessionRecordRepository` parameter.
    - `TaskService.java` contains `public TaskProgressResponseDto getTaskProgress(UUID taskId, UUID userId)` method signature.
    - `getTaskProgress` method calls `getById(taskId, userId)` for ownership verification.
    - `getTaskProgress` method calls `sessionRecordRepository.findByTaskIdAndKindAndCompletedTrue` with `SessionRecord.Kind.WORK`.
    - `getTaskProgress` method calculates `totalTimeSpentSeconds` by summing `durationSeconds` across sessions.
    - `getTaskProgress` method caps `progressPercentage` at `100.0` using `Math.min`.
    - `TaskController.java` contains `@GetMapping("/{id}/progress")` annotation.
    - `cd back-end && mvn compile` succeeds with zero errors.
    - `cd back-end && mvn test` passes all tests.
  </acceptance_criteria>
  <verify>SessionRecordRepository has taskId query; TaskProgressResponseDto exists; TaskService.getTaskProgress computes correct values; TaskController has progress endpoint; mvn compile + test pass</verify>
  <done>GET /api/tasks/{id}/progress returns completedSessions, totalTimeSpentSeconds, progressPercentage for user's completed WORK sessions</done>
</task>

<task type="auto">
  <name>Task 4: Fix ApiClient path bugs</name>
  <files>apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift</files>
  <read_first>
    - apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift (file being modified)
    - back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java (source of truth — backend paths are /api/tasks/{id})
  </read_first>
  <action>
    1. In `fetchTask` (line 437): Change `baseURL.appendingPathComponent("tasks/\(id)")` to `baseURL.appendingPathComponent("api/tasks/\(id)")`.
    2. In `updateTask` (line 456): Change `createBaseRequest(path: "tasks/\(id)"` to `createBaseRequest(path: "api/tasks/\(id)"`.
    3. In `deleteTask` (line 472): Change `baseURL.appendingPathComponent("tasks/\(id)")` to `baseURL.appendingPathComponent("api/tasks/\(id)")`.
  </action>
  <acceptance_criteria>
    - `fetchTask` method body contains the string `"api/tasks/\(id)"` (not `"tasks/\(id)"`).
    - `updateTask` method body contains the string `"api/tasks/\(id)"` (not `"tasks/\(id)"`).
    - `deleteTask` method body contains the string `"api/tasks/\(id)"` (not `"tasks/\(id)"`).
    - No occurrence of `appendingPathComponent("tasks/` exists in the file (all task paths include `api/` prefix).
    - `cd apple/TimeBeam && xcodebuild -scheme "TimeBeam iOS" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` succeeds.
    - `cd apple/TimeBeam && xcodebuild -scheme "TimeBeam" -destination 'platform=macOS' build` succeeds.
  </acceptance_criteria>
  <verify>ApiClient.swift contains "api/tasks/{id}" in all three methods; both iOS and macOS builds succeed</verify>
  <done>fetchTask, updateTask, deleteTask all use correct "api/tasks/{id}" path prefix</done>
</task>

</tasks>

<verification>
[Overall phase checks]
1. `cd back-end && mvn compile` succeeds with zero errors — all new code compiles.
2. `cd back-end && mvn test` passes all tests — no regressions from existing code, new methods have test coverage.
3. `cd apple/TimeBeam && xcodebuild -scheme "TimeBeam iOS" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` succeeds — iOS build passes after path fix.
4. `cd apple/TimeBeam && xcodebuild -scheme "TimeBeam" -destination 'platform=macOS' build` succeeds — macOS build passes after path fix.
5. `grep -n "findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc" back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java` returns a match in `listForUser`.
6. `grep -n "findActiveNonDeletedTasksByUserId" back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java` returns a match in `listActiveTasksForUser`.
7. `grep -n "deletedAt" back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskDto.java` returns field, getter, and setter matches.
8. `grep -n "api/tasks/" apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift` returns matches in `fetchTask`, `updateTask`, `deleteTask` (and existing `createTask`, `fetchTasks`).
9. `grep -n "tasks/\$" apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift` returns no matches (no bare "tasks/" paths without "api/" prefix).
</verification>

<success_criteria>
[Measurable completion]
1. TaskService.listForUser uses `findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc` — soft-deleted tasks excluded from default list.
2. TaskService.listActiveTasksForUser uses `findActiveNonDeletedTasksByUserId` — soft-deleted tasks excluded from active list.
3. TaskService.delete calls `task.softDelete()` + `repository.save(task)` — existing delete endpoint now performs soft delete.
4. TaskService.softDelete, restore, listDeletedTasks methods exist with user ownership verification — throw `IllegalArgumentException` on cross-user access.
5. TaskController has `POST /api/tasks/{id}/soft-delete` returning 200 with updated TaskDto.
6. TaskController has `POST /api/tasks/{id}/restore` returning 200 with restored TaskDto.
7. TaskController has `GET /api/tasks/deleted` returning 200 with list of user's soft-deleted tasks.
8. TaskDto contains `deletedAt` field of type `Instant` with getter and setter.
9. TaskController has `GET /api/tasks/{id}/progress` returning 200 with `TaskProgressResponseDto` containing `completedSessions`, `totalTimeSpentSeconds`, `progressPercentage`.
10. TaskProgressResponseDto exists with `completedSessions` (int), `totalTimeSpentSeconds` (long), `progressPercentage` (double capped at 100.0).
11. SessionRecordRepository has `findByTaskIdAndKindAndCompletedTrue` query method.
12. ApiClient.fetchTask uses path `"api/tasks/\(id)"` — fixed from `"tasks/\(id)"`.
13. ApiClient.updateTask uses path `"api/tasks/\(id)"` — fixed from `"tasks/\(id)"`.
14. ApiClient.deleteTask uses path `"api/tasks/\(id)"` — fixed from `"tasks/\(id)"`.
15. `cd back-end && mvn test` passes all tests.
16. `xcodebuild` builds succeed for both iOS and macOS schemes.
</success_criteria>

<output>
After completion, create `.planning/phases/05-tasks-tab/05-01-Backend-Fixes-And-Endpoints-SUMMARY.md`
</output>
