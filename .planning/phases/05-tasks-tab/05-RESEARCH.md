# Phase 5: Tasks Tab - Research

**Gathered:** 2026-05-10

## Current Code State

### Backend

#### Task Entity (`Task.java`, line 1-125)
- **Fully implemented.** Has `deletedAt` field (line 39), `isSoftDeleted()` (line 112), `softDelete()` (line 116), `restore()` (line 121) domain methods.
- Index on `user_id, deleted_at` already declared (line 13).
- Migration `V3__add_deleted_at_to_tasks.sql` already exists — adds `deleted_at TIMESTAMPTZ` column + index.

#### TaskRepository (`TaskRepository.java`, line 1-35)
- **Fully implemented.** Has soft-delete aware queries:
  - `findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc` (line 17) — excludes soft-deleted
  - `findActiveNonDeletedTasksByUserId` (line 23) — active AND non-deleted
  - `findByUserIdAndDeletedAtIsNotNullOrderByDeletedAtDesc` (line 29) — soft-deleted tasks only
- Missing: No `findByTaskIdAndKindAndCompleted` query for progress tracking.

#### TaskService (`TaskService.java`, line 1-124)
- **Partially implemented.** CRUD works (create/list/get/update/delete).
- `listForUser` (line 51) uses `findByUserIdOrderByCreatedAtDesc` — **includes soft-deleted tasks** (line 52). Should use `findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc` instead.
- `listActiveTasksForUser` (line 57) uses `findActiveTasksByUserId` — **includes soft-deleted tasks** (line 59). Should use `findActiveNonDeletedTasksByUserId`.
- `delete` (line 102) does **hard delete** via `repository.deleteById`. Should use `task.softDelete()` + `repository.save(task)` for soft delete.
- **Missing methods:**
  - `softDelete(id, userId)` — calls `task.softDelete()` and saves
  - `restore(id, userId)` — calls `task.restore()` and saves
  - `listDeletedTasks(userId)` — returns soft-deleted tasks
  - `getTaskProgress(taskId, userId)` — queries `SessionRecord` for completed WORK sessions by task

#### TaskController (`TaskController.java`, line 1-117)
- **Needs additions.** Has full CRUD (POST, GET, GET/{id}, PUT/{id}, DELETE/{id}).
- `GET /active` endpoint exists (line 61).
- **Missing endpoints:**
  - `POST /api/tasks/{id}/soft-delete` — soft delete
  - `POST /api/tasks/{id}/restore` — restore from soft delete
  - `GET /api/tasks/deleted` — list soft-deleted tasks
  - `GET /api/tasks/{id}/progress` — task progress (completed sessions, total time)

#### TaskDto (`TaskDto.java`, line 1-47)
- **Missing `deletedAt` field.** The entity has it, the mapper handles it via MapStruct auto-mapping, but the DTO class only declares `id, userId, title, description, status, createdAt, updatedAt`. Must add `private Instant deletedAt` + getter/setter.

#### TaskMapper (`TaskMapper.java`, line 1-45)
- MapStruct with `stringToStatus` / `statusToString` helpers. Converts camelCase (client) to snake_case (backend). Should auto-map `deletedAt` once added to DTO.

#### SessionRecord (`SessionRecord.java`, line 1-138)
- **Has `taskId` field** (line 27) with index (line 13). Has `kind` enum (WORK/SHORT_BREAK/LONG_BREAK) and `completed` boolean. Has `getDurationMinutes()` helper (line 129). Everything needed for progress tracking exists.

#### SessionRecordRepository (`SessionRecordRepository.java`, line 1-12)
- **Only one query** — `findByUserIdOrderByStartedAtDesc`.
- **Missing for progress:**
  - `findByTaskIdAndKindAndCompletedTrue(UUID taskId, Kind kind)` — count completed WORK sessions for a task
  - Or a custom `@Query` that sums `durationSeconds` for completed WORK sessions by taskId

### iOS

#### UserTask (`UserTask.swift`, line 1-172)
- **Complete.** Has `Status` enum with `isActive`/`isCompleted` computed properties. Has `withStatus()`, `withTitle()`, `withDescription()` copy methods. Has `validate()` method.
- **Missing:** No `deletedAt` property. Will need for soft-delete support.

#### TaskService (`TaskService.swift`, line 1-556)
- **Full CRUD implemented** via API calls. `createTask`, `fetchTasks`, `fetchActiveTasks`, `fetchTask(byId:)`, `updateTask`, `deleteTask` all work.
- **`softDeleteTask` (line 174):** Currently **local-only**. Creates a `RecycleBinItem` and stores in `UserDefaults`. Does NOT call backend.
- **`restoreTask` (line 197):** Currently **local-only**. Reads from UserDefaults, adds back to local `tasks` array. Does NOT call backend.
- **`getTaskProgress` (line 266):** Returns **mock data** (hardcoded 2 sessions, 25 minutes). Does NOT call backend.
- **`startTimerWithTask` (line 317):** **Placeholder** — only prints a log message.
- **`undoTaskCompletion` (line 231):** Calls `updateTask(task, status: .inProgress)` — real API call, functional.
- Local caching via `UserDefaults` (lines 238-258).

#### TaskListView (`TaskListView.swift`, line 1-480)
- **Functional with stubs.** Has search, filter pills, pull-to-refresh, empty state, toolbar menu (analytics, recycle bin, export).
- `TaskRowView` nested inside (line 247):
  - Checkbox button calls `toggleCompletion()` (line 365) — updates local `isCompleted` state, calls `completeTask()` stub (line 386 — just prints)
  - Play button on `.inProgress` tasks calls `startTimerWithTask()` stub (line 418 — just prints)
  - `loadProgress()` (line 400) — creates `TaskService()` directly (not injected) — calls mock `getTaskProgress`
  - Undo button with 5-second auto-hide timer (line 373)
  - Drag gesture for swipe-complete (line 354) — also calls `toggleCompletion`
- **Real methods wired:**
  - `completeTask(_:)` (line 182) — calls `taskService.updateTask(task, status: .completed)` — real API
  - `deleteTask(_:)` (line 192) — calls `taskService.softDeleteTask(task)` — local-only

#### ApiClient (`ApiClient.swift`, line 1-533)
- **Has task CRUD methods:** `createTask`, `fetchTasks`, `fetchActiveTasks`, `fetchTask(id:)`, `updateTask`, `deleteTask`
- **`fetchTask` (line 437):** Uses path `"tasks/\(id)"` — **missing `api/` prefix**. Should be `"api/tasks/\(id)"`. This is a **bug**.
- **`updateTask` (line 456):** Uses path `"tasks/\(id)"` — **same missing `api/` prefix bug**.
- **`deleteTask` (line 472):** Uses path `"tasks/\(id)"` — **same missing `api/` prefix bug**.
- **`startSession` (line 189):** Already supports `taskId` query parameter — works for timer-task linking.
- **Missing methods:**
  - `softDeleteTask(id:accessToken:)` — `POST /api/tasks/{id}/soft-delete`
  - `restoreTask(id:accessToken:)` — `POST /api/tasks/{id}/restore`
  - `fetchDeletedTasks(accessToken:)` — `GET /api/tasks/deleted`
  - `fetchTaskProgress(taskId:accessToken:)` — `GET /api/tasks/{id}/progress`

#### PomodoroTimer (`PomodoroTimer.swift`, line 1-211)
- **Has `currentTaskId: UUID?`** (line 31). Already exists, no changes needed.
- **Has `start()`** method (line 80) — just starts the timer.
- **Missing:** `startWithTask(_ task: UUID)` — sets `currentTaskId` then calls `start()`. Or the integration can happen in `TaskService.startTimerWithTask` by setting `timer.currentTaskId = task.id` then calling `timer.start()`.

#### RecycleBinView (`RecycleBinView.swift`, line 1-190)
- **Exists, functional, local-only.** Pulls from `TaskService.getRecycleBinItems()` which reads UserDefaults.
- Has restore + permanent delete actions per item. Shows expiration countdown.
- **Needs refactoring** to pull from `GET /api/tasks/deleted` backend endpoint.

### macOS

#### macOSContentView (`macOSContentView.swift`, line 1-354)
- **Timer-only view.** Shows circular timer ring, play/pause, reset, options menu.
- **No task list.** The Tasks tab (index 1) in the sidebar currently has no macOS content view.
- The app entry (`TimeBeamApp.swift` line 74) renders `macOSContentView` directly — no tab-based routing for content.
- **Needs:** HSplitView refactor with sidebar navigation + tab-based content area, including a macOS-specific task list view.

#### EnhancedTaskRow (`EnhancedTaskRow.swift`, line 1-57)
- **iOS-only** (wrapped in `#if os(iOS)`). Simple task row with status indicator, title, description, chevron.
- No checkbox, no play button, no progress bar, no completion actions.
- Currently not used in the task list (TaskListView uses its own nested `TaskRowView`).

#### SidebarTabView (`SidebarTabView.swift`, line 1-117)
- **Functional.** 4 tabs (Home, Tasks, Status, Profile). Tasks tab (index 1) shows active task count badge.
- Uses `taskService.activeTasks.count` for badge (line 97).
- Active indicator based on `taskService.activeTasks.contains { $0.status == .inProgress }` (line 111).

## Technical Findings

### Task Completion (Haptics + Undo)

**Haptic feedback patterns:**
- iOS: `UINotificationFeedbackGenerator` (UIKit). Create instance, call `.notificationType = .success`, then `.notify()`. Must be on `@MainActor` or `DispatchQueue.main`.
- macOS: No built-in haptic feedback. Use `UNHapticNotification` (UserNotifications framework) on Apple Silicon Macs with Taptic Engine, or `NSSound` as fallback. Check `ProcessInfo().isAppleSilicon` or check for available notification feedback.
- The `TaskListView` already has `import UIKit` (line 3) for haptic support.

**Current state:** `completeTask()` in `TaskRowView` (line 386) is a stub — just prints. `toggleCompletion()` (line 365) handles local state, shows undo button with 5-second timer. The `completeTask(_ task:)` in `TaskListView` (line 182) calls real `taskService.updateTask(task, status: .completed)`.

**Implementation approach:**
1. Wire `TaskRowView.completeTask()` to call `taskService.updateTask(task, status: .completed)` (like the parent's `completeTask` does)
2. Add `UINotificationFeedbackGenerator().notify()` before API call for immediate haptic feedback
3. Keep the 5-second undo button pattern (already implemented in `toggleCompletion`)
4. Wire `undoCompletion()` to call `taskService.updateTask(task, status: .inProgress)` (or `taskService.undoTaskCompletion`)

**Pitfall:** The `TaskRowView` creates its own local `isCompleted` state, then has an undo button. The parent `TaskListView.completeTask(_:)` also updates via API. There's **duplicated completion logic** — the row's `toggleCompletion` and the parent's `completeTask` both trigger on swipe. Need to consolidate to avoid double API calls.

### Timer-Task Integration

**How `currentTaskId` works:**
- `PomodoroTimer.currentTaskId` (line 31) is a simple `UUID?` property
- `ApiClient.startSession(kind:taskId:accessToken:)` (line 189) already sends `taskId` as query parameter
- Backend `SessionController` accepts `taskId` query param and sets it on `SessionRecord`
- `SessionRecord.taskId` (line 27) is persisted to the `session_records` table

**Integration flow:**
1. User taps play button on task row
2. Set `timer.currentTaskId = task.id`
3. If timer is not running, call `timer.start()` (which triggers `TimerSyncManager.shared.syncTimerAction(.start)`)
4. The `startSession` API call already includes `taskId` via `PomodoroTimer.currentTaskId`

**Current state:** `startTimerWithTask()` in `TaskRowView` (line 418) is a print-only stub. `TaskService.startTimerWithTask` (line 317) is also a print-only placeholder.

**Implementation approach:**
1. In `TaskService.startTimerWithTask(_ task:)`, set `timer.currentTaskId = task.id` and call `timer.start()` if not running
2. In `TaskRowView.startTimerWithTask()`, access `timer` via `@Environment(PomodoroTimer.self)` and call `timer.currentTaskId = task.id` then `timer.start()` directly
3. The existing `startSession` API already supports `taskId` — no backend changes needed for basic linking

**Gotcha:** The `TaskRowView` is nested inside `TaskListView` and doesn't have access to `@Environment(PomodoroTimer.self)`. It needs to receive the timer as a parameter, or the play button action should bubble up to the parent via a closure.

### Progress Tracking

**Backend endpoint needed:** `GET /api/tasks/{id}/progress`

**Required backend changes:**
1. Add `getTaskProgress(taskId, userId)` to `TaskService.java` — queries `SessionRecordRepository` for completed WORK sessions by `taskId`
2. Add `findByTaskIdAndKindAndCompletedTrue` or custom `@Query` to `SessionRecordRepository`
3. Create `TaskProgressResponseDto` (or reuse `TaskProgress` struct pattern): `{ completedSessions: Int, totalTimeSpent: Long, progressPercentage: Double }`
4. Add `GET /api/tasks/{id}/progress` endpoint to `TaskController`

**SwiftUI progress bar pattern:**
- `ProgressView(value: progressPercentage, total: 1.0)` with `.progressViewStyle(.linear)`
- Already implemented in `TaskRowView` (line 298): `ProgressView(value: progress.progressPercentage)` with `.frame(width: 60, height: 4).tint(.blue)`
- The `TaskProgress` struct (line 411) has `progressPercentage` and `formattedTimeSpent` computed properties

**Current state:** `getTaskProgress` returns mock data (2 sessions, 25 min). The progress bar UI is built and functional.

**Decision from CONTEXT.md:** D-09 calls for new backend endpoint. D-10 says progress only counts completed WORK sessions.

### Soft Delete & Recycle Bin

**Backend:**
- `Task.softDelete()` and `Task.restore()` domain methods exist
- `V3__add_deleted_at_to_tasks.sql` migration exists
- `TaskRepository` has soft-delete aware queries
- **But `TaskService` and `TaskController` don't use them** — `listForUser` includes soft-deleted, `delete` does hard delete, no soft-delete/restore/progress endpoints

**Client:**
- `TaskService.softDeleteTask` is local-only (UserDefaults recycle bin)
- `TaskService.restoreTask` is local-only
- `RecycleBinView` pulls from local UserDefaults
- `UserTask` domain model has no `deletedAt` property

**Sync implications:**
- Currently each device has its own recycle bin (UserDefaults-only)
- After backend soft-delete endpoints, both devices sync to the same recycle bin
- When Device A soft-deletes a task, Device B's next `fetchTasks` won't see it (because `listForUser` will exclude soft-deleted)
- When Device A restores a task, Device B's next `fetchTasks` will see it again
- RecycleBinView needs to pull from `GET /api/tasks/deleted` instead of UserDefaults

**Changes needed:**
1. Backend: Fix `listForUser` to exclude soft-deleted, add `softDelete`/`restore`/`listDeletedTasks` service methods, add corresponding controller endpoints
2. Backend: Change `delete` endpoint to do soft delete (or add separate `POST /soft-delete` endpoint)
3. Client: Add `deletedAt` to `UserTask` model
4. Client: Add `deletedAt` to `TaskDto` Swift DTO
5. Client: Add `softDeleteTask`, `restoreTask`, `fetchDeletedTasks` to `ApiClient`
6. Client: Refactor `TaskService.softDeleteTask` to call backend, not UserDefaults
7. Client: Refactor `RecycleBinView` to pull from backend
8. Fix `ApiClient.fetchTask` / `updateTask` / `deleteTask` — missing `api/` prefix in path

### macOS Feature Parity

**Current state:** macOS renders `macOSContentView` directly — a timer-only view. No task list, no tab-based routing.

**What's needed:**
1. Refactor `TimeBeamApp` macOS body to use `HSplitView`:
   ```swift
   HSplitView {
       SidebarTabView(selectedTab: $selectedTab)
           .frame(minWidth: 180)
       if selectedTab == 1 {
           macOSTaskListView()  // New component
       } else {
           macOSContentView()   // Existing, for Home tab
       }
   }
   ```
2. Create `macOSTaskListView` — macOS-specific task list with:
   - `List` with selection (native macOS pattern)
   - Search bar
   - Filter pills (same as iOS)
   - Task rows with trailing buttons (completion, timer, delete) instead of swipe
   - Recycle bin link in toolbar
3. macOS task row: `HStack` with checkbox, title, description, progress bar, and trailing buttons (play, complete, delete)
4. macOS haptic: `UNHapticNotification` on Apple Silicon, silent on Intel

**Key differences from iOS:**
- `List` in macOS supports `.selection()` and click-to-select
- No `.swipeActions` on macOS — use trailing buttons
- `HSplitView` for sidebar layout (vs `TabView` on iOS)
- macOS `ToolbarItem` uses different placements

## Validation Architecture

### Backend Tests
```bash
cd back-end && mvn test -Dtest=TaskServiceTest        # Service layer
cd back-end && mvn test -Dtest=TaskControllerTest     # Controller layer
cd back-end && mvn test -Dtest=TaskRepositoryTest     # Repository queries
```
- Test `softDelete` sets `deletedAt` and `listForUser` excludes it
- Test `restore` clears `deletedAt` and task reappears in `listForUser`
- Test `getTaskProgress` returns correct session count and time
- Test `listDeletedTasks` only returns soft-deleted tasks

### iOS Tests
```bash
cd apple/TimeBeam && xcodebuild -scheme "TimeBeam iOS" test
```
- Test `softDeleteTask` calls backend and removes from local list
- Test `restoreTask` calls backend and adds to local list
- Test `getTaskProgress` returns real data from backend
- Test `startTimerWithTask` sets `currentTaskId` and starts timer
- Test `completeTask` fires haptic + calls API + shows undo

### Manual Verification
- **Haptics:** Tap checkbox on iOS device/simulator — feel success feedback
- **Swipe:** Swipe task row right — complete. Swipe left — delete
- **Undo:** Complete task → "Undo" button appears → disappears after 5s
- **Timer:** Tap play button on in-progress task → timer starts with task linked
- **Progress:** In-progress task shows progress bar with session count + time
- **Recycle bin:** Deleted task appears in recycle bin → restore → back in main list
- **Cross-device:** Delete on iOS → disappears from macOS task list; restore on macOS → appears on iOS

## Dependencies & Order

### Recommended Implementation Order
1. **Backend soft-delete fix** (blocking)
   - Fix `listForUser` to exclude soft-deleted
   - Change `delete` to soft delete (or add `/soft-delete` endpoint)
   - Add `restore` endpoint
   - Add `/deleted` endpoint
   - Add `deletedAt` to `TaskDto`
2. **Backend progress endpoint** (independent)
   - Add `SessionRecordRepository` query by taskId
   - Add `getTaskProgress` to `TaskService`
   - Add `GET /{id}/progress` to `TaskController`
   - Create `TaskProgressResponseDto`
3. **Fix ApiClient path bugs** (blocking)
   - `fetchTask`, `updateTask`, `deleteTask` missing `api/` prefix
4. **Add `deletedAt` to client models** (depends on #1)
   - `UserTask` domain model
   - `TaskDto` Swift DTO
5. **Wire up API client methods** (depends on #1, #2)
   - Add `softDeleteTask`, `restoreTask`, `fetchDeletedTasks`, `fetchTaskProgress`
   - Add corresponding `APIRequest` cases
6. **Refactor TaskService** (depends on #5)
   - `softDeleteTask` → call backend
   - `restoreTask` → call backend
   - `getTaskProgress` → call backend
   - `startTimerWithTask` → wire to `PomodoroTimer`
7. **Wire TaskRowView** (depends on #6)
   - `completeTask` → real API call + haptic
   - `undoCompletion` → real API call
   - `startTimerWithTask` → set `currentTaskId` + start timer
   - Add haptic feedback generator
8. **Refactor RecycleBinView** (depends on #5)
   - Pull from backend `GET /api/tasks/deleted`
   - Use backend `restore`/`delete` endpoints
9. **macOS task list** (depends on #7)
   - Create `macOSTaskListView`
   - Refactor `TimeBeamApp` to `HSplitView`
   - Create macOS task row with trailing buttons

## Risks & Gotchas

1. **ApiClient path bug** — `fetchTask`, `updateTask`, `deleteTask` use `"tasks/{id}"` instead of `"api/tasks/{id}"`. This means these endpoints are currently **broken**. Must fix before any features that rely on them.

2. **Duplicated completion logic** — `TaskRowView` has its own `toggleCompletion()` and `completeTask()` (stub), while `TaskListView` also has `completeTask(_:)` (real). The `.swipeActions` calls the parent's real method, but the checkbox calls the row's stub. This inconsistency must be unified.

3. **TaskRowView Environment access** — `TaskRowView` is nested inside `TaskListView` and cannot inject `@Environment(TaskService.self)` or `@Environment(PomodoroTimer.self)` directly. Must receive closures or `@Observable` references as parameters.

4. **Recycle bin sync** — After switching to backend-based soft delete, the local `UserDefaults` recycle bin becomes obsolete. Old local-only deleted items will not sync to backend. Migration strategy needed if there are existing local recycle bin items.

5. **TaskRowView `loadProgress` anti-pattern** — Line 409 creates `TaskService()` directly instead of using injected environment. This creates a new `ApiClient` instance, may fail to authenticate, and bypasses the shared service instance.

6. **Haptic on macOS** — `UNHapticNotification` only works on Apple Silicon Macs with Taptic Engine. Must gracefully handle Intel Macs (no haptics, no crash).

7. **HSplitView state** — The current `TimeBeamApp` uses `@State var selectedTab` for iOS `TabView`. macOS doesn't use this. Adding `HSplitView` requires separate macOS tab state management, or careful `#if os(macOS)` branching.

8. **Backend `listForUser` includes deleted** — Currently `listForUser` (line 51) returns all tasks including soft-deleted ones. The client filters them locally. This means after soft-delete on one device, the other device still sees the deleted task in its list until local cache is updated.

9. **Backend `delete` is hard delete** — `DELETE /api/tasks/{id}` permanently deletes the row. If the client's `softDeleteTask` currently calls the backend `deleteTask` endpoint, it's doing permanent deletion. Must add `POST /soft-delete` endpoint and wire client to it.

10. **`getTaskProgress` mock data** — The current mock returns `completedSessions: 2, totalTimeSpent: 1500`. The UI shows `2/4 sessions` and `25m`. Once wired to backend, actual values will differ — ensure the progress bar UI handles edge cases (0 sessions, 100% progress).

## RESEARCH COMPLETE
