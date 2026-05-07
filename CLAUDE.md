# CLAUDE.md — TimeBeam Project

## Who I Am
You're a developer working on TimeBeam, a cross-platform productivity application with iOS/macOS SwiftUI apps and a Spring Boot backend.

## My Vault Structure
```
.obsidian/
├── inbox/          Drop zone — bugs, fixes, tasks, quick notes (use YYYY-MM-DD prefix)
├── daily/          Daily brain dumps and quick captures
├── research/       Technical research, docs, API references
├── projects/       Active work with status and next actions
├── archive/        Completed work — never deleted, just moved
└── memory.md       Session memory and preferences

clients/          Client/project context (outside vault)
apple/            iOS/macOS SwiftUI code
back-end/         Spring Boot backend
docs/             Documentation
.planning/        Phase plans and requirements
```

## How I Work
- **Capture first, organize later** — dump ideas in inbox/, sort later
- **Technical focus** — deep notes on Swift, SwiftUI, Spring Boot, PostgreSQL
- **AI as co-pilot** — use `/project` to load context, `/tldr` to save session

## Context Rules
When I mention TimeBeam → check `.obsidian/projects/timebeam/` and `clients/timebeam/`
When I ask to write code → read relevant project/ folder for context

## Obsidian Vault
The main Obsidian vault is at `.obsidian/`. Notes are organized as:
- `.obsidian/inbox/` — Drop zone for quick captures
- `.obsidian/daily/` — Daily brain dumps
- `.obsidian/projects/` — Active work with status
- `.obsidian/research/` — Technical research
- `.obsidian/archive/` — Completed work
- `.obsidian/memory.md` — Session memory

## Inbox Organization
When something lands in inbox/, organize it based on type:
- **Bugs/Fixes** → `.obsidian/inbox/YYYY-MM-DD-description-bugs-fixes.md`
- **E2E Testing** → `.obsidian/inbox/YYYY-MM-DD-e2e-testing.md`
- **Performance** → `.obsidian/inbox/YYYY-MM-DD-performance.md`
- **Architecture** → `.obsidian/inbox/YYYY-MM-DD-architecture.md`
- **General Notes** → `.obsidian/inbox/YYYY-MM-DD-notes.md`

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health

## Docker Context — pi-node

When Docker context is set to `pi-node`, `localhost` becomes `piworm.local` for all service URLs (Postgres, backend, etc.).

Example:
- Normal (local): `localhost:5432`, `localhost:8080`
- pi-node context: `piworm.local:5432`, `piworm.local:8080`

## Timer Sync Architecture (Learned 2026-04-28)

### Cross-device timer sync flow
1. `PomodoroTimer` is the in-memory timer (`Domain/Models/PomodoroTimer.swift`)
2. `TimerSyncManager` (singleton) handles sync — `deviceId` persists to Keychain (key: `com.timebeam.app.deviceId`)
3. iOS sends `TimerActionDto` with `action` field (String) → backend `TimerActionDto.java` has `actionType` (enum) with `@JsonAlias({"action","actionType"})`
4. Backend `SessionController.convertActionToState()` uses `actionDto.getActionType()` — must not be null or `remainingSeconds` becomes 0
5. `TimerState` entity is one-per-user in `timer_states` table — conflict resolution by `lastModifiedTimestamp`
6. 30-second periodic polling in `TimerSyncManager.startPeriodicPolling()`
7. Silent APNs push triggers `syncTimerState()` on both iOS and macOS

### Key sync files
- `apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift`
- `apple/TimeBeam/TimeBeam/Domain/Models/PomodoroTimer.swift`
- `apple/TimeBeam/TimeBeam/TimeBeamApp.swift` — `setupApp()` pulls timer state on launch
- `apple/TimeBeam/TimeBeam/Infrastructure/Networking/DTOs/TimerActionDto.swift` — has both `action` and `actionType` fields
- `back-end/src/main/java/com/sparkage/timebeam/presentation/dto/TimerActionDto.java` — `@JsonAlias({"action","actionType"})` on `actionType`
- `back-end/src/main/java/com/sparkage/timebeam/presentation/controller/SessionController.java`
- `back-end/src/main/java/com/sparkage/timebeam/application/service/TimerSyncService.java`

### Common sync pitfalls
- **Keychain error -34018**: macOS entitlements must have `com.apple.security.keychain.access-groups` with `425MSY8FLG.com.sparkage.time-beam`
- **`actionType` is null**: iOS sends `action` string, backend needs `@JsonAlias` to map it
- **API_BASE_URL**: Check `project.pbxproj` for hardcoded URL — not `Info.plist` (which uses `$(API_BASE_URL)`)
- **Auth not restored**: `AuthManager.restoreSession()` must be called before any API calls
- **Silent push must sync**: `willPresent` notification handler must call `syncTimerState()`, not just discard

## Back End Development (Spring Boot)

When working on the backend (`back-end/`):
- Run tests: `cd back-end && mvn test`
- Build: `cd back-end && mvn clean package`
- Start with Docker Compose: `cd back-end && docker compose -f docker-compose.dev.yml up -d`
- Backend runs on port 8080 by default (8081 in e2e profile)
- Health check (local): `curl http://localhost:8080/api/auth/health`
- Health check (pi-node): `curl http://piworm.local:8080/api/auth/health`
