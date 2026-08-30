# Synapse App Features

Synapse is a privacy-first, on-device Getting Things Done (GTD) task manager
for iOS, macOS, and watchOS. The app keeps everyday task data local to the
user's Apple devices and uses CloudKit private database sync when available.

## Core GTD Structure

- **Inbox** — a fast capture point for unprocessed thoughts and tasks.
- **Next Actions** — concrete tasks that are ready to do.
- **Waiting For** — delegated or blocked tasks, including what the user is
  waiting on.
- **Someday/Maybe** — ideas and tasks that are not currently actionable.
- **Projects** — multi-step outcomes linked to their next actions; archived
  outcomes preserve their linked tasks and can be restored later.
- **Areas** — cross-cutting context tags such as Work, Personal, Health, and
  Finance.
- **Weekly Review** — a structured checklist and workflow for maintaining the
  system.

Each task supports a title, notes, creation date, optional due date, optional
project, area/context tags, GTD status, and completion state.

## App Navigation

The primary iOS workspace uses five tabs:

1. **Today** — daily briefing, due Next Actions, overdue Waiting For items,
   and calendar context.
2. **Inbox** — unprocessed captures, search, quick capture, and triage.
3. **Projects** — active outcomes and their linked actions, with a reversible
   archive for projects that are set aside.
4. **Focus** — Pomodoro timer connected to the task being worked on.
5. **Review** — Weekly Review, Someday/Maybe, Areas overview, and review
   streaks.

Areas are available as filters across Today, Inbox, and Projects rather than
as a separate workflow tab. Settings and integrations are accessed from the
navigation bar.

## Quick Capture

Quick Capture is designed to remove friction. A user can save a thought to
Inbox without deciding its category first.

- Capture is available from the app and through Siri/Shortcuts.
- New captures are saved as **Inbox** items until explicitly triaged.
- The save path is local-first and does not wait for Foundation Models.
- Empty titles are rejected and blank items cannot be saved.
- Duplicate text is allowed; each capture remains a separate item.
- Very long text is preserved in full in SwiftData.
- Foundation Models input is bounded to 4,000 characters during triage to
  protect prompt limits; the stored capture is not truncated.
- Captures may include notes, due dates, projects, areas, and context tags.

The shared capture service is `CaptureService`. In-app capture and the
`AddCaptureIntent` use the same Inbox capture workflow and persistence service.

## Triage and On-Device Intelligence

When the user starts triage, Synapse attempts to use Foundation Models on
supported devices to suggest:

- GTD status: Inbox, Next Action, Waiting For, or Someday/Maybe.
- An Area tag.
- A due date when the capture explicitly mentions one.

If Foundation Models is unavailable, Synapse falls back to local heuristics
for action verbs, waiting language, area names, and simple dates. Triage does
not require a server or remote AI service. The in-app capture flow persists the
raw item in Inbox first, then presents an editable confirmation screen with
status, Area, due date, project, and tags pre-filled from the best available
classification. Users can manually override every suggestion before confirming.

Confirmation is immediate: users may confirm without editing, or cancel/back
out and leave the item as an uncategorized Inbox capture. Foundation Models
timeouts and failures fall back to heuristics without blocking the screen.
Single captures always show confirmation; batch-import bypass remains intended
for large imports.

## Daily Briefing

The Today view is intended as the default landing surface and can summarize:

- Next Actions due today.
- Overdue Waiting For items.
- Relevant calendar overlap when EventKit access is enabled.
- A short AI-generated framing of the day's work when on-device inference is
  available.

## Weekly Review

Weekly Review is a guided workflow rather than a reminder. It walks through a
structured checklist covering collection, processing, project review, and
planning. On-device intelligence can surface stale items and generate prompts
to promote, defer, archive, or clarify tasks.

The app also tracks review completion and streak information as lightweight
habit feedback.

## Siri, Shortcuts, and Spotlight

Synapse exposes App Intents through `AppShortcutsProvider`:

- **Capture an item** — save text directly to Inbox.
- **Add a next action** — save a task directly to Next Actions.
- **Start weekly review** — create and open a structured review flow.
- **Complete task** — planned task-management intent.
- **Show next actions** — planned task-discovery intent.

The capture intent shares the same capture service as the in-app path, so both
entry points create consistently structured SwiftData records.

## Persistence and Sync

- SwiftData is the source of truth for task, project, area, and review models.
- CloudKit uses the private database for per-user synchronization.
- Captures remain available from the local store while offline.
- CloudKit synchronizes local changes when connectivity returns.
- Keychain is reserved for local secrets and credentials.
- UI tests use an isolated local SwiftData store with CloudKit disabled.

## Authentication and Privacy

- Sign in with Apple is the supported authentication flow.
- No Spring Boot backend, PostgreSQL database, custom JWT service, or REST
  task API is required for the GTD workflow.
- AI classification and summaries are designed to run on-device.
- Private CloudKit data belongs to the signed-in user's private database.

## Integrations

Planned or available integration surfaces include:

- **EventKit** — calendar awareness for the Daily Briefing.
- **Gmail** — on-device OAuth and actionable email capture.
- **GitHub Projects** — map issues/cards to Next Actions or Waiting For.
- **Apple Reminders** — one-time import for migration.

Integrations should be opt-in and should not prevent core local capture,
triage, or review workflows from working offline.

## Voice Capture Boundary

Voice capture is intentionally deferred. The current design leaves a clean
voice-capture interface so native English dictation can be connected first and
the later Raspberry Pi IndicWhisper bridge can be added without changing the
capture or persistence workflow.

## Supported Apple Platforms

- iOS 17+
- macOS 14+
- watchOS 10+
- Foundation Models enhancements on supported iOS/macOS releases

## Verification Coverage

Quick Capture is covered at multiple levels:

- Unit tests for classification, Inbox preservation, long text, dates, and
  notes.
- Persistence tests for App Intent and in-app parity.
- Duplicate-capture tests confirming separate records.
- UI tests for empty-submit prevention, capture-to-Inbox navigation, editable
  confirmation, visible category choices, and cancel/back preservation.
- Physical-device verification on an iPhone 15 Pro.

Physical UI test instructions are documented in
[`ios-ui-tests-on-iphone-15-pro.md`](ios-ui-tests-on-iphone-15-pro.md).

### Latest Test Run Status

Verified on the connected iPhone 15 Pro:

- Quick-capture unit and persistence tests: **13 passed, 0 failed**.
- Capture App Intent tests: **3 passed, 0 failed**.
- Focused physical-device confirmation UI test: **1 passed, 0 failed**.
- Focused physical-device cancel/back preservation UI test: **1 passed, 0 failed**.
- App target `build-for-testing`: **passed**.

The complete `GTDWorkspaceUITests` suite remains pending. The focused tests
passed on the physical device; the full suite should be run later to cover
batch import, voice capture, timeout, and offline scenarios. Xcode previously
stalled while resolving DeviceSupport/LLDB snapshot support, which is an
environment limitation rather than a reported application test failure.
