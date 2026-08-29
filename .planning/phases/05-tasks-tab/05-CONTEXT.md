# Phase 5: Tasks Tab - Work & Complete - Context

**Gathered:** 2026-05-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a fully functional "work and complete tasks" tab across iOS and macOS. Make task completion satisfying (checkbox + swipe, haptic feedback, undo), wire timer-task integration (play button on task row), show real progress tracking (inline progress bar), and enable cross-device recycle bin with soft delete. Covers the entire task workflow: create, work on, complete, undo, delete, restore, and link to timer sessions.

**Not in scope:** Task creation UI redesign (existing TaskCreationView is functional), task editing, task priority/due dates, task search algorithm improvements, analytics dashboard.

</domain>

<decisions>
## Implementation Decisions

### Task Completion Experience
- **D-01:** Dual completion methods — checkbox toggle for quick complete, swipe for secondary actions (complete, delete, edit). Most flexible approach
- **D-02:** Visual feedback on completion — success haptic (UINotificationFeedbackGenerator) + strikethrough on title. Clean, satisfying, no extra UI
- **D-03:** 5-second inline undo button after completion. Tap "Undo" to restore task to in_progress status

### Timer-Task Integration
- **D-04:** Play button (▶) on in-progress task rows. Tap to set `PomodoroTimer.currentTaskId` and start a WORK session linked to that task
- **D-05:** Uses existing `ApiClient.startSession(kind:taskId:accessToken:)` which already supports `taskId` parameter
- **D-06:** Backend `POST /api/sessions/start?kind=WORK&taskId=...` already creates SessionRecord with `task_id` set — no backend changes needed for linking

### Task Progress Tracking
- **D-07:** Inline progress bar in task row — shows sessions completed and total time spent. Compact, always visible
- **D-08:** Format: `[████░░░░] 3/4 · 45min` — progress bar + session count + time
- **D-09:** New backend endpoint `GET /api/tasks/{id}/progress` returns completed WORK session count, total time spent, progress percentage
- **D-10:** Progress only counts completed WORK sessions (not breaks)

### Recycle Bin & Soft Delete
- **D-11:** Swipe to delete with 5-second inline undo. Deleted tasks go to recycle bin accessible from tasks tab
- **D-12:** Backend soft delete — `deleted_at` column on tasks table. `GET /api/tasks` excludes soft-deleted tasks
- **D-13:** New endpoints: `POST /api/tasks/{id}/soft-delete`, `POST /api/tasks/{id}/restore`, `GET /api/tasks/deleted`
- **D-14:** Cross-device sync of soft-deleted tasks via backend (replaces current UserDefaults-only recycle bin)
- **D-15:** Auto-expire soft-deleted tasks after 30 days (backend cleanup job)

### macOS Task UI
- **D-16:** Full macOS task list view with feature parity to iOS — search, filter pills, completion, timer link, progress, recycle bin
- **D-17:** macOS uses `HSplitView` with sidebar + content area. Content switches based on selected tab
- **D-18:** macOS task list uses `List` with selection (native macOS pattern) instead of iOS swipe gestures
- **D-19:** macOS task row trailing buttons instead of swipe actions (macOS convention)

### Claude's Discretion
- Exact progress bar width and visual styling
- Estimated session count (default 4 per task) vs. user-configurable
- Recycle bin UI layout (separate view vs. inline section)
- Batch complete implementation details
- Exact haptic feedback timing and intensity

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Task System (Backend)
- `back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/Task.java` — JPA entity, add `deletedAt` field
- `back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/TaskRepository.java` — queries, add soft-delete variants
- `back-end/src/main/java/com/sparkage/timebeam/application/service/TaskService.java` — CRUD service, add softDelete/restore/getTaskProgress
- `back-end/src/main/java/com/sparkage/timebeam/presentation/controller/TaskController.java` — REST endpoints, add soft-delete/restore/progress
- `back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TaskDto.java` — DTO, add `deletedAt`
- `back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/TaskMapper.java` — MapStruct mapper, handles new field
- `back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecord.java` — has `taskId` column, existing
- `back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/SessionRecordRepository.java` — add queries by taskId

### Task System (iOS)
- `apple/TimeBeam/TimeBeam/Domain/Models/UserTask.swift` — domain model with status enum
- `apple/TimeBeam/TimeBeam/Application/Services/TaskService.swift` — full CRUD, has stubbed methods (getTaskProgress, startTimerWithTask)
- `apple/TimeBeam/TimeBeam/Presentation/Views/iOS/TaskListView.swift` — functional list with TaskRowView (checkbox stubbed)
- `apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift` — API client, add fetchTaskProgress method
- `apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift` — has `currentTaskId` property, add startTimerWithTask method

### Task System (macOS)
- `apple/TimeBeam/TimeBeam/Presentation/Views/macOS/macOSContentView.swift` — current home view, keep for tab 0
- `apple/TimeBeam/TimeBeam/TimeBeamApp.swift` — app entry, refactor to HSplitView
- `apple/TimeBeam/TimeBeam/Presentation/Views/Navigation/SidebarTabView.swift` — has Tasks tab (index 1)

### Existing Patterns
- `.planning/codebase/STACK.md` — tech stack, deployment targets
- `.planning/codebase/ARCHITECTURE.md` — layered architecture for both platforms
- `.planning/codebase/CONVENTIONS.md` — Swift/Java coding conventions

### Requirements
- `.planning/REQUIREMENTS.md` — no specific TASK requirements (tasks added as V2 feature), use decisions above

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TaskService.swift` — full CRUD already working. Wire up stubbed methods (getTaskProgress returns mock, startTimerWithTask is placeholder)
- `TaskListView.swift` — functional iOS list with search, filters, swipe actions. TaskRowView checkbox needs wiring
- `TaskRowView` inside `TaskListView.swift` — has completeTask/undoCompletion/startTimerWithTask stubs (just print)
- `ApiClient.swift` — has `startSession(kind:taskId:accessToken:)` method (line 189) that supports taskId
- `PomodoroTimer.swift` — has `currentTaskId: UUID?` property, timer already links to tasks conceptually
- `BottomTabView.swift` / `SidebarTabView.swift` — Tasks tab (index 1) with active task count badge already wired
- `RecycleBinView.swift` — exists, currently uses UserDefaults-only data

### Established Patterns
- `@Observable` + `@Environment` for dependency injection (iOS 17+)
- `@MainActor` for UI state access
- Immutable domain models with `withXxx()` copy methods (UserTask)
- Liquid Glass conditional modifiers for UI
- Backend: constructor injection, MapStruct for DTO mapping, JPA entities with domain methods

### Integration Points
- `TaskRowView` checkbox → `TaskService.updateTask(status: .completed)` + haptic
- `TaskRowView` play button → `PomodoroTimer.currentTaskId = task.id` + `TaskService.startTimerWithTask()`
- `TimeBeamApp.swift` macOS body → `HSplitView` with sidebar + tab-based content
- `RecycleBinView` → pull from backend `GET /api/tasks/deleted` instead of UserDefaults
- Backend `SessionRecord.taskId` → already exists, query for progress tracking

</code_context>

<specifics>
## Specific Ideas

- "Checkbox + swipe — checkbox for quick complete, swipe for secondary actions"
- "Haptic + strikethrough — clean, satisfying, no extra UI"
- "Play button on task row — tap to start timer with task linked"
- "Inline progress bar — [████░░░░] 3/4 · 45min — always visible"
- "Swipe delete with 5-second undo + recycle bin with 30-day retention"
- "macOS should have full feature parity — sidebar layout, trailing buttons instead of swipe"

</specifics>

<deferred>
## Deferred Ideas

- Task editing UI (currently only creation is built) — future phase
- Task priority and due dates — future phase
- Batch complete all visible tasks — future phase
- 30-day auto-expire backend cleanup job — future phase (soft delete works without it)
- Task analytics in dedicated tab — Phase 6 (PERF) or future
- Task search algorithm improvements — future phase
- User-configurable estimated sessions per task — future phase

</deferred>

---

*Phase: 05-tasks-tab*
*Context gathered: 2026-05-10*
