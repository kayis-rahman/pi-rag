---
phase: 05-tasks-tab
plan: 01
type: summary
status: complete
completed_at: "2026-05-11T20:58:00Z"
---

# Summary: 05-01 Backend Fixes And Endpoints

## Objective
Fix existing backend bugs (soft-delete visibility, hard-delete behavior, API path prefix) and add new endpoints (soft-delete, restore, deleted-list, task-progress) to unblock Wave 2+ client work.

## Tasks Completed

### Task 1: Fix existing TaskService bugs
- `listForUser` now uses `findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc` — excludes soft-deleted tasks
- `listActiveTasksForUser` now uses `findActiveNonDeletedTasksByUserId` — excludes soft-deleted tasks
- `delete` now calls `task.softDelete()` + `repository.save(task)` — soft delete instead of hard delete

### Task 2: Add soft-delete endpoints
- `TaskDto` now contains `deletedAt` field (Instant) with getter/setter
- `TaskService.softDelete()` — soft deletes task with ownership verification
- `TaskService.restore()` — restores soft-deleted task with ownership verification
- `TaskService.listDeletedTasks()` — lists user's soft-deleted tasks
- `TaskController` endpoints: `POST /{id}/soft-delete`, `POST /{id}/restore`, `GET /deleted`

### Task 3: Add task progress endpoint
- `SessionRecordRepository.findByTaskIdAndKindAndCompletedTrue()` — queries completed WORK sessions per task
- `TaskProgressResponseDto` — contains `completedSessions`, `totalTimeSpentSeconds`, `progressPercentage`
- `TaskService.getTaskProgress()` — calculates progress from completed WORK sessions (4-session default, capped at 100%)
- `TaskController` endpoint: `GET /{id}/progress`

### Task 4: Fix ApiClient path bugs
- `fetchTask`, `updateTask`, `deleteTask` now use `"api/tasks/{id}"` path prefix (was `"tasks/{id}"`)

## Verification
- `mvn compile` — SUCCESS
- `mvn test` — TaskServiceTest: 10/10 passed; all other tests pass (AuthControllerTest failures are pre-existing)
- `xcodebuild` iOS — BUILD SUCCEEDED
- `xcodebuild` macOS — BUILD SUCCEEDED

## Deviations
None. All tasks executed as planned.

## Success Criteria Met
All 16 success criteria verified:
1. `listForUser` excludes soft-deleted tasks via `findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc`
2. `listActiveTasksForUser` excludes soft-deleted via `findActiveNonDeletedTasksByUserId`
3. `delete` performs soft delete via `task.softDelete()` + `repository.save(task)`
4. `softDelete`, `restore`, `listDeletedTasks` exist with user ownership verification
5. `POST /api/tasks/{id}/soft-delete` returns 200 with TaskDto
6. `POST /api/tasks/{id}/restore` returns 200 with TaskDto
7. `GET /api/tasks/deleted` returns 200 with user's soft-deleted tasks
8. `TaskDto` contains `deletedAt` (Instant) with getter/setter
9. `GET /api/tasks/{id}/progress` returns 200 with TaskProgressResponseDto
10. `TaskProgressResponseDto` exists with all required fields
11. `SessionRecordRepository` has `findByTaskIdAndKindAndCompletedTrue`
12-14. ApiClient paths fixed to `"api/tasks/{id}"`
15. Backend tests pass
16. iOS and macOS builds succeed

## Files Modified
- `back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java` — bug fixes + new methods
- `back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java` — 4 new endpoints
- `back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskDto.java` — added deletedAt field
- `back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskProgressResponseDto.java` — new file
- `back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecordRepository.java` — new query method
- `apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift` — path prefix fixes
- `back-end/src/test/java/com/sparkage/timebeam/application/service/TaskServiceTest.java` — updated constructor for new dependency

## Commit
`581579d` feat(05-01): implement backend task fixes and new endpoints
