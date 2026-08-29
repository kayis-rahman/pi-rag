# Phase 4: Cross Sync - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-10
**Phase:** 04-cross-sync
**Areas discussed:** Conflict resolution strategy, Offline behavior, Push notification strategy, Device coordination, Sync interval tuning, State persistence across restarts, Sync failure handling

---

## Conflict Resolution Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Device priority (iOS wins) | Always prefer iOS device's state when timestamps match | |
| Last-write-wins (higher deviceId) | Use deviceId as tiebreaker | |
| Merge semantics | Try to merge both states | |
| Latest change wins | Backend uses arrival order as tiebreaker | ✓ |

**User's choice:** Latest change win (arrival order)
**Notes:** Simple, deterministic, no platform bias.

## Offline Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Queue + replay on reconnect | Buffer actions locally, replay in order | ✓ |
| Next poll catches up | Let 30s poll handle catch-up | |

**User's choice:** Queue + replay on reconnect
**Notes:** Ensures no action is lost during network outages.

## Push Notification Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Full state pull | Push triggers complete state pull from backend | |
| Delta apply from payload | Push carries timer state delta, apply directly | ✓ |

**User's choice:** Delta apply from payload
**Notes:** Faster, no extra network round-trip.

## Device Coordination

| Option | Description | Selected |
|--------|-------------|----------|
| Simultaneous control allowed | Both devices can act, timestamp resolution handles merges | ✓ |
| Active device ownership | One device owns timer at a time | |

**User's choice:** Simultaneous control allowed
**Notes:** Most flexible approach, conflict resolution handles edge cases.

## Sync Interval Tuning

| Option | Description | Selected |
|--------|-------------|----------|
| Adaptive interval | Fast when running, slow when idle | |
| Fixed 30s | Always 30 seconds | |
| Event-driven primary | Each action pushes event → APN → apply. Polling as fallback only. | ✓ |

**User's choice:** Event-driven approach
**Notes:** "Each start/stop an event should be pushed to server then apn to active devices to apply those events." Polling is safety net only.

## State Persistence Across Restarts

| Option | Description | Selected |
|--------|-------------|----------|
| Pull from backend | Fetch timer state from backend on launch | ✓ |
| Local cache + backend merge | Read local AND pull from backend, merge | |

**User's choice:** Pull from backend
**Notes:** Most accurate — includes changes made on other devices while app was closed.

## Sync Failure Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Exponential backoff + user alert | Double interval, alert after 3 failures, manual retry | ✓ |
| Silent backoff, no alert | Back off silently, never bother user | |

**User's choice:** Exponential backoff + user alert
**Notes:** 30s → 60s → 120s → cap 300s. Alert after 3 consecutive failures.

---

## Claude's Discretion
- Exact queue data structure (array, circular buffer, persisted vs in-memory)
- Push retry logic and batching strategy
- Alert UI design for sync failures
- Queue size limits and overflow behavior

## Deferred Ideas
- Advanced conflict resolution strategies (V2)
- Smart sync intervals / adaptive polling (V2)
- End-to-end encryption for timer data (V2)
- Support for additional device types beyond iOS/macOS
- iCloud/CloudKit as secondary sync path
