# Synapse — Project Roadmap

**Defined:** 2026-06-08
**Status:** Draft for approval

## Executive Summary

**Phases:** 6
**v1 Requirements:** 16
**Granularity:** Standard

This roadmap delivers the core value: daily GTD briefing + adaptive focus sessions, all local on Pi 5.

## Phases

- [ ] **Phase 1: Foundation** — Python orchestrator scaffolding + Pi deployment automation
- [ ] **Phase 2: LLM Infrastructure** — llama.cpp service with systemd socket activation
- [ ] **Phase 3: Data Sources** — Gmail + GitHub Projects + iCal integration
- [ ] **Phase 4: GTD Briefing** — Prompt pipeline + Qdrant RAG + Redis sessions
- [ ] **Phase 5: TimeBeam Integration** — Session sync API + voice pipeline + adaptive Pomodoro
- [ ] **Phase 6: Polish** — Open WebUI fallback + deployment hardening

## Phase Details

### Phase 1: Foundation
**Goal**: Python orchestrator running on Pi 5 with basic API endpoints

**Depends on**: Nothing

**Requirements**: SYN-01, SYN-12

**Success Criteria**:
1. FastAPI application starts and responds to health check
2. Pydantic settings loaded from .env
3. docker-compose brings up Qdrant + Redis + Open WebUI
4. systemd service for orchestrator configured
5. Tailscale connectivity verified from iPhone

**Plans**: 1 plan
- [x] 01-foundation-01-PLAN.md — FastAPI scaffolding + docker-compose + systemd

---

### Phase 2: LLM Infrastructure
**Goal**: Gemma 4 E4B running via llama.cpp with auto-sleep

**Depends on**: Phase 1

**Requirements**: SYN-08

**Success Criteria**:
1. llama.cpp server starts with Gemma 4 E4B Q4 model
2. systemd socket activation loads model on first request
3. Model unloads after idle timeout (configurable)
4. API endpoint proxies to llama.cpp completion
5. Fallback to GPUHub Qwen3-27B configured

**Plans**: 1 plan
- [x] 02-llm-infrastructure-01-PLAN.md — llama.cpp service + socket activation + fallback

---

### Phase 3: Data Sources
**Goal**: Pull tasks, email, and calendar data for briefing

**Depends on**: Phase 1

**Requirements**: SYN-02, SYN-03, SYN-04

**Success Criteria**:
1. Gmail API fetches unread + today's emails
2. GitHub Projects polls active tasks from Kayis HQ
3. iCal polls .ics URLs for today's events
4. Data normalized into common briefing context format
5. Cached in Redis with TTL to avoid excessive polling

**Plans**: 3 plans
- [ ] 03-data-sources-01-PLAN.md — Gmail API integration
- [ ] 03-data-sources-02-PLAN.md — GitHub Projects integration
- [ ] 03-data-sources-03-PLAN.md — iCal integration

---

### Phase 4: GTD Briefing
**Goal**: AI-generated daily briefing with memory continuity

**Depends on**: Phase 2, Phase 3

**Requirements**: SYN-05, SYN-06, SYN-07

**Success Criteria**:
1. Briefing prompt assembles context from all data sources
2. LLM generates formatted briefing (priorities, email summary, schedule)
3. Past briefings stored in Qdrant for continuity
4. Session state tracked in Redis (current session, preferences)
5. Briefing API endpoint returns structured response

**Plans**: 2 plans
- [ ] 04-gtd-briefing-01-PLAN.md — Prompt pipeline + LLM orchestration
- [ ] 04-gtd-briefing-02-PLAN.md — Qdrant RAG + Redis session state

---

### Phase 5: TimeBeam Integration
**Goal**: iOS app sync + voice + adaptive Pomodoro

**Depends on**: Phase 4

**Requirements**: SYN-09, SYN-10, SESS-01, SESS-02, SESS-03, SESS-04

**Success Criteria**:
1. TimeBeam can start/stop/pause sessions via API
2. Session state synchronized in real-time
3. IndicWhisper ASR processes voice input
4. Parler-TTS generates voice output
5. LLM detects burnout patterns and adjusts intervals
6. Session history persisted for analytics

**Plans**: 3 plans
- [ ] 05-timebeam-01-PLAN.md — Session sync API contract
- [ ] 05-timebeam-02-PLAN.md — Voice pipeline (ASR + TTS)
- [ ] 05-timebeam-03-PLAN.md — Adaptive Pomodoro + burnout detection

---

### Phase 6: Polish
**Goal**: Fallback interface + deployment hardening

**Depends on**: Phase 5

**Requirements**: SYN-11

**Success Criteria**:
1. Open WebUI configured as fallback interface
2. PWA accessible from any browser on Tailscale
3. Graceful degradation when LLM is unavailable
4. Health monitoring for all services
5. Automated recovery on service failure

**Plans**: 1 plan
- [ ] 06-polish-01-PLAN.md — Open WebUI config + monitoring + recovery

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1 - Foundation | 1/1 | In Progress | 2026-07-18 |
| 2 - LLM Infrastructure | 1/1 | In Progress | 2026-07-19 |
| 3 - Data Sources | 0/3 | Planned | - |
| 4 - GTD Briefing | 0/2 | Planned | - |
| 5 - TimeBeam Integration | 0/3 | Planned | - |
| 6 - Polish | 0/1 | Planned | - |

## Coverage

| Category | Requirements | Mapped |
|----------|--------------|--------|
| Orchestrator Core | SYN-01, SYN-12 | 2/2 |
| Data Sources | SYN-02, SYN-03, SYN-04 | 3/3 |
| GTD Briefing | SYN-05, SYN-06, SYN-07 | 3/3 |
| LLM Infrastructure | SYN-08 | 1/1 |
| TimeBeam Integration | SYN-09, SYN-10 | 2/2 |
| Session Management | SESS-01-04 | 4/4 |
| Polish | SYN-11 | 1/1 |
| **Total** | **16** | **16/16** |

✓ All v1 requirements mapped
✓ No orphaned requirements

## Awaiting

Approve roadmap or provide feedback for revision.
