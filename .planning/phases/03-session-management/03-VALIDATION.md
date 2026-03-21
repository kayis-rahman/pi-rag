---
phase: 3
slug: session-management
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | JUnit 5 with Spring Boot Test |
| **Config file** | `app/build.gradle` (test dependencies) |
| **Quick run command** | `./gradlew test -k SessionManager` |
| **Full suite command** | `./gradlew test` |
| **Estimated runtime** | ~45 seconds (unit) + ~120 seconds (integration) |

---

## Sampling Rate

- **After every task commit:** Run `./gradlew test -k SessionManager`
- **After every plan wave:** Run `./gradlew test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SESS-01 | unit | `./gradlew test -k SessionManagerTest` | ✅ | ⬜ pending |
| 03-01-02 | 01 | 1 | SESS-02 | unit | `./gradlew test -k SessionDetectionStrategyTest` | ✅ | ⬜ pending |
| 03-01-03 | 01 | 1 | SESS-01 | integration | `./gradlew test -k SessionFilterTest` | ✅ | ⬜ pending |
| 03-02-01 | 02 | 1 | SESS-03 | integration | `./gradlew test -k EpisodicMemoryServiceTest -k sessionId` | ✅ | ⬜ pending |
| 03-03-01 | 03 | 2 | SESS-04 | unit | `./gradlew test -k SessionCleanupTaskTest` | ✅ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | SESS-04 | integration | `./gradlew test -k SessionExpirationTest` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `app/src/test/java/com/synapse/workflow/SessionManagerTest.java` — unit tests for session creation, detection, and retrieval (SESS-01, SESS-02)
- [ ] `app/src/test/java/com/synapse/llm/logging/SessionFilterTest.java` — integration test for WebFilter behavior and header propagation (SESS-01)
- [ ] `app/src/test/java/com/synapse/memory/episodic/SessionEpisodicPersistenceTest.java` — integration test for session state storage and recovery via EpisodicMemoryService (SESS-03)
- [ ] `app/src/test/java/com/synapse/workflow/SessionCleanupTaskTest.java` — unit test for @Scheduled cleanup task (SESS-04)
- [ ] `application-test.yml` — test Redis/PostgreSQL configuration (already exists for Phase 2)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Session recovery after application restart | SESS-03 | Requires application restart which breaks automation | 1. Send request to /v1/messages with messages array; note session ID in response 2. Stop application 3. Start application 4. Send same request with same session ID header 5. Verify /api/session/status returns previous episode history in Redis |
| Expired session cleanup does not reappear | SESS-04 | Requires waiting for Redis TTL expiration (7 days default) | 1. Create session with short TTL (test config: 10 seconds) 2. Wait 11 seconds 3. Query episodes by sessionId 4. Verify no episodes returned 5. Verify PostgreSQL row also deleted by cleanup task |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---

*Validation strategy created: 2026-03-21*
*Phase: 03-session-management*
